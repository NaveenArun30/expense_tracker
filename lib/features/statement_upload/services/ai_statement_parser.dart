import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/extracted_transaction.dart';
import 'pdf_statement_parser.dart';

class AiStatementParser {
  static Future<List<ExtractedTransaction>> parsePdfWithAi(
    PlatformFile file,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');

    if (apiKey == null || apiKey.trim().isEmpty) {
      // No AI key configured, use local regex parser
      return PdfStatementParser.parseFile(file);
    }

    try {
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        return PdfStatementParser.parseFile(file);
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      const prompt = '''
Analyze this bank or credit card statement document. Extract ONLY actual credit and debit transaction entries into a structured JSON list.

CRITICAL EXTRACTION RULES:
1. EXCLUDE all non-transaction entries, including:
   - Opening Balance / Closing Balance / Balance Brought Forward / Carried Forward
   - Available Limit / Credit Limit / Total Limit / Cash Limit / Overdraft Limit
   - Total Credits / Total Debits / Total Expenditure / Statement Summary / Account Summary
   - Minimum Amount Due / Total Amount Due / Due Date
   - Document headers, account numbers, branch info, page numbers, or footers.

2. Determine "isCredit" PRECISELY:
   - Set "isCredit": true for Credits, Incomes, Deposits, Salary, Refunds, Cashbacks, Payments received.
   - Set "isCredit": false for Debits, Expenses, Withdrawals, Card purchases, Transfers sent, Charges/Fees.
   - DO NOT mark all transactions as debit or all as credit. Differentiate carefully based on statement CR/DR indicators, columns, or narration.

3. Extract each transaction with fields:
   - "title": concise payee or narration name (clean up raw bank codes/reference numbers)
   - "amount": positive numeric amount (double)
   - "date": string in "YYYY-MM-DD" format
   - "category": choose one of ["Food", "Travel", "Shopping", "Bills", "Salary", "Investment", "Health", "Entertainment", "Income", "Expense"]
   - "isCredit": boolean (true for credit/income, false for debit/expense)

Return ONLY a valid JSON array of objects. No markdown wrappers or conversational text.
Example:
[
  {"title": "Swiggy Order", "amount": 350.0, "date": "2024-08-10", "category": "Food", "isCredit": false},
  {"title": "Salary Credit", "amount": 50000.0, "date": "2024-08-01", "category": "Salary", "isCredit": true}
]
''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart('application/pdf', bytes),
      ]);

      final response = await model.generateContent([content]);
      final responseText = response.text ?? '';

      // Clean response JSON
      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```json|^```|```$'), '').trim();
      }

      List<dynamic> jsonList = jsonDecode(cleanJson);
      List<ExtractedTransaction> result = [];

      for (int i = 0; i < jsonList.length; i++) {
        var item = jsonList[i];
        double amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
        if (amt <= 0) continue;

        String title = item['title']?.toString() ?? 'Transaction';
        if (PdfStatementParser.isNonTransactionText(title)) continue;

        DateTime date = DateTime.tryParse(item['date']?.toString() ?? '') ?? DateTime.now();
        bool isCredit = item['isCredit'] == true;

        result.add(ExtractedTransaction(
          id: 'ai_${i}_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          amount: amt,
          date: date,
          category: item['category']?.toString() ?? (isCredit ? 'Income' : 'Expense'),
          isCredit: isCredit,
        ));
      }

      if (result.isNotEmpty) return result;
    } catch (_) {
      // On any AI failure, fall back to local parser
    }

    return PdfStatementParser.parseFile(file);
  }
}
