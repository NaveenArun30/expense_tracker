import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/features/statement_upload/services/pdf_statement_parser.dart';
import 'package:expense_tracker_app/features/statement_upload/models/extracted_transaction.dart';

void main() {
  group('PdfStatementParser & Non-Transaction Filtering Tests', () {
    test('Should filter out non-transaction balance and limit lines', () {
      expect(PdfStatementParser.isNonTransactionText('AVAILABLE CREDIT LIMIT : RS. 1,50,000.00'), true);
      expect(PdfStatementParser.isNonTransactionText('OPENING BALANCE AS ON 01-08-2026 : 25,000.00 CR'), true);
      expect(PdfStatementParser.isNonTransactionText('CLOSING BALANCE AS ON 31-08-2026 : 29,800.00 CR'), true);
      expect(PdfStatementParser.isNonTransactionText('TOTAL DEBIT: 45,200.00 TOTAL CREDIT: 50,000.00'), true);
      expect(PdfStatementParser.isNonTransactionText('MINIMUM AMOUNT DUE : 500.00 DUE DATE : 25-AUG-2026'), true);
      expect(PdfStatementParser.isNonTransactionText('Page 1 of 3'), true);
    });

    test('Should NOT filter out valid transaction lines', () {
      expect(PdfStatementParser.isNonTransactionText('19/08/2026 200.0 DR 1955.62 UPI/DR/623175131672/DURAIRAJ/KKBK/'), false);
      expect(PdfStatementParser.isNonTransactionText('18/08/2026 5000.0 CR 7175.62 UPI/CR/659611774755/SIDANAND/BARB/'), false);
      expect(PdfStatementParser.isNonTransactionText('15/08/2026 BY TRANSFER-UPI/CR/62345/SWAPNA 1200.00 25000.00'), false);
      expect(PdfStatementParser.isNonTransactionText('16/08/2026 TO SWIGGY BANGALORE 350.00 24650.00'), false);
    });

    test('Should accurately classify Credit vs Debit', () {
      // Credit cases
      expect(PdfStatementParser.isCreditText('UPI/CR/62345/SWAPNA'), true);
      expect(PdfStatementParser.isCreditText('BY TRANSFER-UPI'), true);
      expect(PdfStatementParser.isCreditText('SALARY CREDIT AUGUST'), true);
      expect(PdfStatementParser.isCreditText('REFUND FROM SWIGGY'), true);
      expect(PdfStatementParser.isCreditText('PAYMENT RECEIVED - THANK YOU'), true);

      // Debit cases
      expect(PdfStatementParser.isDebitText('UPI/DR/62346/PAYTM'), true);
      expect(PdfStatementParser.isDebitText('TO SWIGGY BANGALORE'), true);
      expect(PdfStatementParser.isDebitText('ATM WDR MUMBAI'), true);
      expect(PdfStatementParser.isDebitText('CREDIT CARD PAYMENT'), true);
    });

    test('Should parse raw text lines into transactions without including limits or balances', () {
      String sampleStatement = '''
      Statement of Account from 01/08/2026 to 31/08/2026
      AVAILABLE CREDIT LIMIT : RS. 1,50,000.00
      OPENING BALANCE AS ON 01-08-2026 : 25,000.00 CR
      19/08/2026 200.0 DR 1955.62 UPI/DR/623175131672/DURAIRAJ/KKBK/
      18/08/2026 5000.0 CR 7175.62 UPI/CR/659611774755/SIDANAND/BARB/
      16/08/2026 TO SWIGGY BANGALORE 350.00 24650.00
      TOTAL DEBIT: 550.00 TOTAL CREDIT: 5000.00
      CLOSING BALANCE AS ON 31-08-2026 : 29,450.00 CR
      ''';

      List<ExtractedTransaction> txs = PdfStatementParser.parseRawText(sampleStatement);

      expect(txs.length, 3);

      // Transaction 1: DURAIRAJ (Debit)
      expect(txs[0].amount, 200.0);
      expect(txs[0].isCredit, false);
      expect(txs[0].title, 'DURAIRAJ');

      // Transaction 2: SIDANAND (Credit)
      expect(txs[1].amount, 5000.0);
      expect(txs[1].isCredit, true);
      expect(txs[1].title, 'SIDANAND');

      // Transaction 3: SWIGGY (Debit)
      expect(txs[2].amount, 350.0);
      expect(txs[2].isCredit, false);
      expect(txs[2].title, 'SWIGGY BANGALORE');
    });
  });
}
