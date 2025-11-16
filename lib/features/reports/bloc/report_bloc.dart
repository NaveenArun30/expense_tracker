import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:excel/excel.dart';
import '../../../model/report_model.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc() : super(ReportInitial()) {
    on<UploadFile>(_handleFileUpload);
  }

  Future<void> _handleFileUpload(UploadFile event, Emitter emit) async {
    emit(ReportLoading());

    try {
      final file = File(event.filePath);
      final extension = event.filePath.split('.').last.toLowerCase();

      List<ExpenseEntry> entries = [];

      if (extension == "csv") {
        entries = await _parseCSV(file);
      } else if (extension == "xlsx") {
        entries = await _parseExcel(file);
      } else if (extension == "pdf") {
        entries = await _parsePDF(file);
      } else {
        emit(ReportError("Unsupported file type"));
        return;
      }

      // Calculate stats
      double income = 0;
      double expense = 0;
      Map<String, double> categorySummary = {};

      for (var e in entries) {
        if (e.type == "income") {
          income += e.amount;
        } else {
          expense += e.amount;
        }

        categorySummary[e.category] =
            (categorySummary[e.category] ?? 0) + e.amount;
      }

      emit(
        ReportLoaded(
          totalIncome: income,
          totalExpense: expense,
          categoryBreakdown: categorySummary,
        ),
      );
    } catch (e) {
      emit(ReportError("Failed to read file: $e"));
    }
  }

  // ---------------- CSV Parsing ----------------
  Future<List<ExpenseEntry>> _parseCSV(File file) async {
    final lines = await file.readAsLines();
    List<ExpenseEntry> entries = [];

    for (var line in lines.skip(1)) {
      // Format: category,amount,type
      final parts = line.split(',');
      if (parts.length < 3) continue;

      entries.add(
        ExpenseEntry(
          category: parts[0],
          amount: double.tryParse(parts[1]) ?? 0,
          type: parts[2].toLowerCase(),
        ),
      );
    }

    return entries;
  }

  // ---------------- Excel Parsing ----------------
  Future<List<ExpenseEntry>> _parseExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    List<ExpenseEntry> entries = [];

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows.skip(1)) {
        entries.add(
          ExpenseEntry(
            category: row[0]!.value.toString(),
            amount: double.tryParse(row[1]!.value.toString()) ?? 0,
            type: row[2]!.value.toString().toLowerCase(),
          ),
        );
      }
    }
    return entries;
  }

  // ---------------- PDF Parsing ----------------
  Future<List<ExpenseEntry>> _parsePDF(File file) async {
    // Note: PDF parsing requires a dedicated package like 'pdfx' or 'pdf'
    // For now, returning empty list as pdf package doesn't provide text extraction
    List<ExpenseEntry> entries = [];

    // TODO: Implement PDF text extraction using 'pdfx' package
    // Add 'pdfx' to pubspec.yaml and uncomment below:
    // final document = await PdfDocument.openFile(event.filePath);
    // Extract and parse text from document

    return entries;
  }
}
