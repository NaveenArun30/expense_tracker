import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/expense_model.dart';

class PdfExportHelper {
  static Future<String?> generateExpenseReport(
    List<ExpenseModel> expenses,
    String dateRange,
  ) async {
    final pdf = pw.Document();

    final totalAmount = expenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final totalTransactions = expenses.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Expense Tracker',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'STATEMENT OF EXPENSES',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Statement Period Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Statement Period',
                      style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      dateRange,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated On',
                      style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Account Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Transactions',
                        style: const pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '$totalTransactions',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 20,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(width: 1, height: 40, color: PdfColors.grey400),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Amount',
                        style: const pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 20,
                          color: PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Transactions Title
            pw.Text(
              'Transaction Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),

            // Transactions Table
            _buildTransactionsTable(expenses),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
            ),
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final fileName =
        'Expense_Statement_${DateFormat('yyyyMMdd').format(DateTime.now())}';

    final resultPath = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      mimeType: MimeType.pdf,
      fileExtension: 'pdf',
    );

    return resultPath;
  }

  static pw.Widget _buildTransactionsTable(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Center(
          child: pw.Text(
            'No transactions in this period.',
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
        ),
      );
    }

    // Sort expenses by date descending
    final sortedExpenses = List<ExpenseModel>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Title', 'Category', 'Amount'],
      data: sortedExpenses.map((expense) {
        return [
          DateFormat('MMM dd, yyyy').format(expense.date),
          expense.title,
          expense.category,
          '\$${expense.amount.toStringAsFixed(2)}',
        ];
      }).toList(),
      border: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(4),
          topRight: pw.Radius.circular(4),
        ),
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerHeight: 40,
    );
  }
}
