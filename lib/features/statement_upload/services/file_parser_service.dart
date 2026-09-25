import 'package:file_picker/file_picker.dart';
import '../models/extracted_transaction.dart';
import 'ai_statement_parser.dart';
import 'excel_statement_parser.dart';
import 'pdf_statement_parser.dart';

class FileParserService {
  static Future<List<ExtractedTransaction>> parseStatementFile(PlatformFile file) async {
    String ext = (file.extension ?? '').toLowerCase();
    
    if (ext == 'xlsx' || ext == 'xls' || ext == 'csv') {
      return ExcelStatementParser.parseFile(file);
    } else if (ext == 'pdf') {
      // Try AI Smart Parser first (falls back to local text parser automatically)
      return AiStatementParser.parsePdfWithAi(file);
    } else {
      // Try local PDF parser as fallback
      List<ExtractedTransaction> pdfResult = await PdfStatementParser.parseFile(file);
      if (pdfResult.isNotEmpty) return pdfResult;
      return ExcelStatementParser.parseFile(file);
    }
  }
}
