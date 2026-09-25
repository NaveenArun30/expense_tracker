import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/extracted_transaction.dart';

class PdfStatementParser {
  static Future<List<ExtractedTransaction>> parseFile(PlatformFile file) async {
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) return [];

    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String fullText = extractor.extractText();
      document.dispose();

      return parseRawText(fullText);
    } catch (e) {
      return [];
    }
  }

  static List<ExtractedTransaction> parseRawText(String fullText) {
    List<ExtractedTransaction> transactions = [];
    List<String> lines = fullText.split('\n');

    // Pattern 1: PNB & Indian Bank tabular format
    // e.g., 19/08/2026 200.0 DR 1955.62 UPI/DR/623175131672/DURAIRAJ/KKBK/...
    // e.g., 18/08/2026 20.0 CR 2175.62 UPI/CR/659611774755/SIDANAND/BARB/...
    RegExp pnbRegex = RegExp(
      r'^(\d{1,2}[\/\.-][A-Za-z0-9]{1,3}[\/\.-]\d{2,4})\s+(?:(\S+)\s+)?(\d+(?:,\d+)*(?:\.\d+)?)\s+(DR|CR)\s+(\d+(?:,\d+)*(?:\.\d+)?)\s*(.*)$',
      caseSensitive: false,
    );

    // General Date Regex
    RegExp dateRegex = RegExp(
      r'(\d{1,2}[\/\.-]\d{1,2}[\/\.-]\d{2,4}|\d{1,2}[\s-][A-Za-z]{3,9}[\s-]\d{2,4}|\d{4}[\/\.-]\d{1,2}[\/\.-]\d{1,2})',
      caseSensitive: false,
    );

    // General Amount Regex
    RegExp amountRegex = RegExp(r'\b\d+(?:,\d+)*(?:\.\d+)?\b');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      // 1. Skip non-transaction lines (Opening/Closing balance, Credit limits, totals, summaries, headers)
      if (isNonTransactionText(line)) continue;

      // 2. Try PNB/Indian Bank tabular pattern first
      Match? pnbMatch = pnbRegex.firstMatch(line);
      if (pnbMatch != null) {
        String dateStr = pnbMatch.group(1)!;
        String amountStr = pnbMatch.group(3)!;
        String typeStr = pnbMatch.group(4)!.toUpperCase();
        String remarksStr = pnbMatch.group(6) ?? '';

        DateTime parsedDate = _parseDate(dateStr);
        double amount = double.tryParse(amountStr.replaceAll(',', '')) ?? 0.0;
        if (amount <= 0) continue;

        bool isCredit = (typeStr == 'CR');
        String cleanTitle = _extractSmartTitle(remarksStr.isNotEmpty ? remarksStr : line);

        transactions.add(ExtractedTransaction(
          id: 'pdf_pnb_${i}_${DateTime.now().millisecondsSinceEpoch}',
          title: cleanTitle,
          amount: amount,
          date: parsedDate,
          category: _guessCategory(cleanTitle, isCredit),
          isCredit: isCredit,
          rawDescription: line,
        ));
        continue;
      }

      // 3. Fallback parsing for other bank statements (HDFC, SBI, ICICI, Axis, Credit Cards, etc.)
      Match? dateMatch = dateRegex.firstMatch(line);
      if (dateMatch != null) {
        String dateStr = dateMatch.group(0)!;
        DateTime parsedDate = _parseDate(dateStr);

        String lineWithoutDate = line.replaceFirst(dateStr, '');
        Iterable<Match> amounts = amountRegex.allMatches(lineWithoutDate);
        if (amounts.isEmpty && i + 1 < lines.length) {
          String nextLine = lines[i + 1].trim();
          if (!isNonTransactionText(nextLine) && dateRegex.firstMatch(nextLine) == null) {
            amounts = amountRegex.allMatches(nextLine);
          }
        }

        if (amounts.isNotEmpty) {
          List<double> parsedAmounts = [];
          for (Match m in amounts) {
            String sanitized = m.group(0)!.replaceAll(',', '');
            double? val = double.tryParse(sanitized);
            if (val != null && val > 0) {
              parsedAmounts.add(val);
            }
          }

          if (parsedAmounts.isNotEmpty) {
            // Transaction amount is typically the first parsed amount
            double amount = parsedAmounts.first;

            bool isCredit = false;
            if (isCreditText(line)) {
              isCredit = true;
            } else if (isDebitText(line)) {
              isCredit = false;
            } else {
              String lowerLine = line.toLowerCase();
              if (lowerLine.contains(' cr') || lowerLine.contains('/cr') || lowerLine.endsWith('cr')) {
                isCredit = true;
              } else if (lowerLine.contains(' dr') || lowerLine.contains('/dr') || lowerLine.endsWith('dr')) {
                isCredit = false;
              } else {
                isCredit = false;
              }
            }

            String title = _extractSmartTitle(line);

            transactions.add(ExtractedTransaction(
              id: 'pdf_${i}_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              amount: amount,
              date: parsedDate,
              category: _guessCategory(title, isCredit),
              isCredit: isCredit,
              rawDescription: line,
            ));
          }
        }
      }
    }

    return transactions;
  }

  static bool isNonTransactionText(String rawText) {
    String lower = rawText.toLowerCase().trim();
    if (lower.isEmpty) return false;

    List<String> ignoredKeywords = [
      'opening balance',
      'closing balance',
      'opening bal',
      'closing bal',
      'bal b/f',
      'bal c/f',
      'balance b/f',
      'balance c/f',
      'brought forward',
      'carried forward',
      'balance brought forward',
      'balance carried forward',
      'net balance',
      'available balance',
      'total balance',
      'ending balance',
      'beginning balance',
      'current balance',
      'credit limit',
      'available limit',
      'total limit',
      'cash limit',
      'overdraft limit',
      'card limit',
      'limit available',
      'total credit',
      'total debit',
      'total debits',
      'total credits',
      'total expenditure',
      'total income',
      'total amount due',
      'minimum amount due',
      'min amount due',
      'account summary',
      'statement summary',
      'grand total',
      'subtotal',
      'previous balance',
      'statement period',
      'statement of account',
      'customer id',
      'account number',
      'ifsc code',
      'micr code',
      'branch code',
    ];

    for (String kw in ignoredKeywords) {
      if (lower.contains(kw)) {
        return true;
      }
    }

    if (RegExp(r'^page\s+\d+\s+of\s+\d+$', caseSensitive: false).hasMatch(lower)) {
      return true;
    }

    return false;
  }

  static bool isCreditText(String text) {
    String lower = text.toLowerCase();
    if (lower.contains('credit card payment') ||
        lower.contains('payment to credit card') ||
        lower.contains('credit card bill')) {
      return false;
    }

    RegExp crPattern = RegExp(
      r'\b(cr|credit|deposit|deposits|inflow|refund|cashback|salary|interest|income|bonus|received)\b',
      caseSensitive: false,
    );
    if (crPattern.hasMatch(lower) ||
        lower.contains('by transfer') ||
        lower.contains('by clg') ||
        lower.contains('by cash') ||
        lower.contains('by cheque') ||
        lower.contains('upi/cr/') ||
        lower.contains('neft cr') ||
        lower.contains('rtgs cr') ||
        lower.contains('imps cr') ||
        lower.contains('cr/') ||
        lower.contains('payment received')) {
      return true;
    }
    return false;
  }

  static bool isDebitText(String text) {
    String lower = text.toLowerCase();
    RegExp drPattern = RegExp(
      r'\b(dr|debit|withdrawal|withdrawals|outflow|paid|payment|charges|fee|expense)\b',
      caseSensitive: false,
    );
    if (drPattern.hasMatch(lower) ||
        lower.contains('to transfer') ||
        lower.contains('to clg') ||
        lower.contains('to cash') ||
        lower.contains('to cheque') ||
        lower.contains('upi/dr/') ||
        lower.contains('neft dr') ||
        lower.contains('rtgs dr') ||
        lower.contains('imps dr') ||
        lower.contains('dr/') ||
        lower.contains('atm wdr') ||
        lower.contains('credit card payment') ||
        lower.contains('swiggy') ||
        lower.contains('zomato') ||
        lower.contains('amazon') ||
        lower.contains('flipkart') ||
        lower.contains('uber') ||
        lower.contains('ola')) {
      return true;
    }
    return false;
  }

  static String _extractSmartTitle(String text) {
    if (text.trim().isEmpty) return 'Transaction';

    // 1. Check for UPI pattern: UPI/DR/.../PayeeName/... or UPI/CR/.../SenderName/...
    if (text.contains('UPI/')) {
      List<String> parts = text.split('/');
      if (parts.length >= 4) {
        String payee = parts[3].trim();
        if (payee.isNotEmpty && !RegExp(r'^\d+$').hasMatch(payee)) {
          return _cleanName(payee);
        }
      }
    }

    // 2. Check for NEFT
    if (text.contains('NEFT')) {
      List<String> parts = text.split('/');
      for (String p in parts.reversed) {
        String clean = p.trim();
        if (clean.isNotEmpty &&
            !clean.startsWith('NEFT') &&
            !RegExp(r'^\d+$').hasMatch(clean)) {
          return _cleanName(clean);
        }
      }
    }

    // 3. Check for ATM WDR
    if (text.contains('ATM') || text.contains('ATM WDR')) {
      int idx = text.indexOf('ATM');
      String sub = text.substring(idx).replaceAll('\\', '').trim();
      return _cleanName(sub);
    }

    // 4. Check for SMS CHRG
    if (text.contains('SMS CHRG')) {
      return 'Bank SMS Charges';
    }

    // 5. Fallback clean text
    String cleaned = text
        .replaceAll(RegExp(r'\d{1,2}[\/\.-][A-Za-z0-9]{1,3}[\/\.-]\d{2,4}'), '')
        .replaceAll(RegExp(r'\b(DR|CR)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\s*(TO|BY)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d+(?:,\d+)*(?:\.\d+)?\b'), '')
        .replaceAll(RegExp(r'[/_\\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.isNotEmpty ? _cleanName(cleaned) : 'Transaction';
  }

  static String _cleanName(String raw) {
    String res = raw.trim();
    if (res.length > 30) res = res.substring(0, 30).trim();
    return res;
  }

  static DateTime _parseDate(String val) {
    List<String> formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd/MM/yy',
      'dd-MM-yy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
      'dd MMM yyyy',
      'dd-MMM-yyyy',
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
      if (lower.contains('swiggy') ||
          lower.contains('zomato') ||
          lower.contains('restaurant') ||
          lower.contains('food') ||
          lower.contains('cafe')) return 'Food';
      if (lower.contains('uber') ||
          lower.contains('ola') ||
          lower.contains('petrol') ||
          lower.contains('fuel')) return 'Travel';
      if (lower.contains('amazon') ||
          lower.contains('flipkart') ||
          lower.contains('store') ||
          lower.contains('mart')) return 'Shopping';
      if (lower.contains('bill') ||
          lower.contains('electricity') ||
          lower.contains('recharge') ||
          lower.contains('rent') ||
          lower.contains('sms')) return 'Bills';
      if (lower.contains('netflix') ||
          lower.contains('spotify') ||
          lower.contains('movie')) return 'Entertainment';
      return 'Expense';
    }
  }
}
