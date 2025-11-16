abstract class ReportState {}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> categoryBreakdown;

  ReportLoaded({
    required this.totalIncome,
    required this.totalExpense,
    required this.categoryBreakdown,
  });
}

class ReportError extends ReportState {
  final String message;
  ReportError(this.message);
}
