import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/extracted_transaction.dart';
import 'pdf_statement_parser.dart';

class ExcelStatementParser {
  static Future<List<ExtractedTransaction>> parseFile(PlatformFile file) async {
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) return [];

    String extension = (file.extension ?? '').toLowerCase();

    if (extension == 'csv') {
      return _parseCsvBytes(bytes);
    }

    try {
      var excel = Excel.decodeBytes(bytes);
      List<ExtractedTransaction> transactions = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null || sheet.maxRows == 0) continue;

        // 1. Identify header row & column mapping
        int dateCol = -1;
        int descCol = -1;
        int creditCol = -1;
        int debitCol = -1;
        int amountCol = -1;
        int typeCol = -1;
        int headerRowIndex = -1;

        for (int r = 0; r < sheet.rows.length && r < 15; r++) {
          var row = sheet.rows[r];
          for (int c = 0; c < row.length; c++) {
            String cellVal = _getCellValueString(row[c]).toLowerCase().trim();
            if (cellVal.isEmpty) continue;

            bool isBalanceOrLimitHeader = cellVal.contains('limit') ||
                cellVal.contains('balance') ||
                cellVal.contains('available') ||
                cellVal.contains('opening') ||
                cellVal.contains('closing') ||
                cellVal.contains('summary') ||
                cellVal.contains('due') ||
                cellVal.contains('period');

            if (isBalanceOrLimitHeader) continue;

            if (dateCol == -1 && (cellVal.contains('date') || cellVal.contains('time'))) {
              dateCol = c;
            } else if (descCol == -1 &&
                (cellVal.contains('desc') ||
                    cellVal.contains('particular') ||
                    cellVal.contains('narration') ||
                    cellVal.contains('remark') ||
                    cellVal.contains('detail') ||
                    cellVal.contains('payee') ||
                    cellVal.contains('title'))) {
              descCol = c;
            } else if (creditCol == -1 &&
                (cellVal == 'credit' ||
                    cellVal.contains('credit amount') ||
                    cellVal.contains('deposit') ||
                    cellVal.contains('cr amount') ||
                    cellVal == 'cr' ||
                    cellVal.contains('inflow') ||
                    cellVal.contains('credit(rs)') ||
                    cellVal.contains('credit (rs)'))) {
              creditCol = c;
            } else if (debitCol == -1 &&
                (cellVal == 'debit' ||
                    cellVal.contains('debit amount') ||
                    cellVal.contains('withdrawal') ||
                    cellVal.contains('dr amount') ||
                    cellVal == 'dr' ||
                    cellVal.contains('outflow') ||
                    cellVal.contains('debit(rs)') ||
                    cellVal.contains('debit (rs)'))) {
              debitCol = c;
            } else if (amountCol == -1 &&
                (cellVal == 'amount' ||
                    cellVal.contains('txn amount') ||
                    cellVal.contains('trans amount') ||
                    cellVal.contains('amount(rs)') ||
                    cellVal.contains('amount (rs)'))) {
              amountCol = c;
            } else if (typeCol == -1 &&
                (cellVal.contains('type') || cellVal.contains('cr/dr') || cellVal.contains('dr/cr'))) {
              typeCol = c;
            }
          }

          if (dateCol != -1 && (descCol != -1 || amountCol != -1 || creditCol != -1 || debitCol != -1)) {
            headerRowIndex = r;
            break;
          }
        }

        // If no header found, assume default column layout
        if (headerRowIndex == -1) {
          headerRowIndex = 0;
          if (dateCol == -1) dateCol = 0;
          if (descCol == -1) descCol = 1;
        }

        // 2. Iterate data rows
        for (int r = headerRowIndex + 1; r < sheet.rows.length; r++) {
          var row = sheet.rows[r];
          if (row.isEmpty) continue;

          String dateStr = dateCol >= 0 && dateCol < row.length ? _getCellValueString(row[dateCol]) : '';
          String descStr = descCol >= 0 && descCol < row.length ? _getCellValueString(row[descCol]) : '';
          String creditStr = creditCol >= 0 && creditCol < row.length ? _getCellValueString(row[creditCol]) : '';
          String debitStr = debitCol >= 0 && debitCol < row.length ? _getCellValueString(row[debitCol]) : '';
          String amountStr = amountCol >= 0 && amountCol < row.length ? _getCellValueString(row[amountCol]) : '';
          String typeStr = typeCol >= 0 && typeCol < row.length ? _getCellValueString(row[typeCol]) : '';

          String fullRowText = '$dateStr $descStr $typeStr $creditStr $debitStr $amountStr';
          if (PdfStatementParser.isNonTransactionText(fullRowText)) continue;

          if (dateStr.trim().isEmpty && descStr.trim().isEmpty) continue;

          DateTime parsedDate = _parseDate(dateStr);
          double amount = 0.0;
          bool isCredit = false;

          double creditVal = _parseAmount(creditStr);
          double debitVal = _parseAmount(debitStr);
          double amountVal = _parseAmount(amountStr);

          if (creditVal > 0 && debitVal == 0) {
            amount = creditVal;
            isCredit = true;
          } else if (debitVal > 0 && creditVal == 0) {
            amount = debitVal;
            isCredit = false;
          } else if (creditVal > 0 && debitVal > 0) {
            if (typeStr.toUpperCase().contains('CR') || descStr.toLowerCase().contains('credit')) {
              amount = creditVal;
              isCredit = true;
            } else {
              amount = debitVal;
              isCredit = false;
            }
          } else if (amountVal > 0) {
            amount = amountVal.abs();
            if (amountStr.trim().startsWith('-')) {
              isCredit = false;
            } else if (typeStr.toUpperCase().contains('CR') ||
                typeStr.toUpperCase().contains('CREDIT') ||
                typeStr.toUpperCase().contains('DEP')) {
              isCredit = true;
            } else if (typeStr.toUpperCase().contains('DR') ||
                typeStr.toUpperCase().contains('DEBIT') ||
                typeStr.toUpperCase().contains('WDR')) {
              isCredit = false;
            } else if (PdfStatementParser.isCreditText('$descStr $typeStr')) {
              isCredit = true;
            } else if (PdfStatementParser.isDebitText('$descStr $typeStr')) {
              isCredit = false;
            } else {
              isCredit = false;
            }
          }

          if (amount <= 0 && descStr.trim().isEmpty) continue;

          transactions.add(ExtractedTransaction(
            id: 'ex_${r}_${DateTime.now().millisecondsSinceEpoch}',
            title: descStr.trim().isNotEmpty ? descStr.trim() : 'Transaction',
            amount: amount,
            date: parsedDate,
            category: _guessCategory(descStr, isCredit),
            isCredit: isCredit,
            rawDescription: descStr,
          ));
        }

        if (transactions.isNotEmpty) break;
      }

      return transactions;
    } catch (e) {
      // Fallback CSV parsing
      return _parseCsvBytes(bytes);
    }
  }

  static List<ExtractedTransaction> _parseCsvBytes(Uint8List bytes) {
    List<ExtractedTransaction> result = [];
    try {
      String rawText = utf8.decode(bytes, allowMalformed: true);
      List<String> lines = const LineSplitter().convert(rawText);

      int dateCol = 0;
      int descCol = 1;
      int amountCol = 2;
      int creditCol = -1;
      int debitCol = -1;
      int typeCol = -1;

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;

        if (PdfStatementParser.isNonTransactionText(line)) continue;

        // Split by comma, tab, or semicolon
        List<String> cols = line.split(RegExp(r'[,;\t]')).map((e) => e.replaceAll('"', '').trim()).toList();
        if (cols.length < 2) continue;

        // Check header line
        if (i == 0) {
          for (int c = 0; c < cols.length; c++) {
            String header = cols[c].toLowerCase();
            if (header.contains('limit') || header.contains('balance')) continue;
            if (header.contains('date')) dateCol = c;
            if (header.contains('desc') || header.contains('particular') || header.contains('narration')) descCol = c;
            if (header.contains('credit') || header.contains('deposit')) creditCol = c;
            if (header.contains('debit') || header.contains('withdrawal')) debitCol = c;
            if (header.contains('amount')) amountCol = c;
            if (header.contains('type') || header.contains('cr/dr')) typeCol = c;
          }
          continue;
        }

        String dateStr = cols.length > dateCol ? cols[dateCol] : '';
        String descStr = cols.length > descCol ? cols[descCol] : '';
        String typeStr = typeCol != -1 && typeCol < cols.length ? cols[typeCol] : '';

        DateTime parsedDate = _parseDate(dateStr);
        double amount = 0.0;
        bool isCredit = false;

        double creditVal = creditCol != -1 && creditCol < cols.length ? _parseAmount(cols[creditCol]) : 0.0;
        double debitVal = debitCol != -1 && debitCol < cols.length ? _parseAmount(cols[debitCol]) : 0.0;
        double amountVal = amountCol < cols.length ? _parseAmount(cols[amountCol]) : 0.0;

        if (creditVal > 0 && debitVal == 0) {
          amount = creditVal;
          isCredit = true;
        } else if (debitVal > 0 && creditVal == 0) {
          amount = debitVal;
          isCredit = false;
        } else if (amountVal > 0) {
          amount = amountVal.abs();
          if (typeStr.toUpperCase().contains('CR') || PdfStatementParser.isCreditText('$descStr $typeStr')) {
            isCredit = true;
          } else {
            isCredit = false;
          }
        }

        if (amount > 0) {
          result.add(ExtractedTransaction(
            id: 'csv_${i}_${DateTime.now().millisecondsSinceEpoch}',
            title: descStr.isNotEmpty ? descStr : 'CSV Transaction',
            amount: amount,
            date: parsedDate,
            category: _guessCategory(descStr, isCredit),
            isCredit: isCredit,
            rawDescription: descStr,
          ));
        }
      }
    } catch (_) {}
    return result;
  }

  static String _getCellValueString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }

  static double _parseAmount(String val) {
    if (val.trim().isEmpty) return 0.0;
    String sanitized = val.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }

  static DateTime _parseDate(String val) {
    if (val.trim().isEmpty) return DateTime.now();
    List<String> formats = [
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'dd-MMM-yyyy',
      'yyyy/MM/dd',
      'dd MMM yyyy',
    ];
    for (String fmt in formats) {
      try {
        return DateFormat(fmt).parse(val.trim());
      } catch (_) {}
    }
    return DateTime.tryParse(val.trim()) ?? DateTime.now();
  }

  static String _guessCategory(String text, bool isCredit) {
    String lower = text.toLowerCase();
    if (isCredit) {
      if (lower.contains('salary') || lower.contains('payroll')) return 'Salary';
      if (lower.contains('interest') || lower.contains('dividend')) return 'Investment';
      if (lower.contains('refund') || lower.contains('cashback')) return 'Refund';
      return 'Income';
    } else {
      if (lower.contains('swiggy') || lower.contains('zomato') || lower.contains('restaurant') || lower.contains('food') || lower.contains('cafe') || lower.contains('starbucks')) return 'Food';
      if (lower.contains('uber') || lower.contains('ola') || lower.contains('petrol') || lower.contains('fuel') || lower.contains('irctc') || lower.contains('flight')) return 'Travel';
      if (lower.contains('amazon') || lower.contains('flipkart') || lower.contains('myntra') || lower.contains('store') || lower.contains('mart') || lower.contains('supermarket')) return 'Shopping';
      if (lower.contains('bill') || lower.contains('electricity') || lower.contains('recharge') || lower.contains('wifi') || lower.contains('broadband') || lower.contains('rent')) return 'Bills';
      if (lower.contains('netflix') || lower.contains('spotify') || lower.contains('movie') || lower.contains('cinema')) return 'Entertainment';
      if (lower.contains('hospital') || lower.contains('pharmacy') || lower.contains('doctor') || lower.contains('medical')) return 'Health';
      return 'Expense';
    }
  }
}
