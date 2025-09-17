abstract class ReportState {}

class ReportInitial extends ReportState {}

class ReportLoaded extends ReportState {
  final String reportSummary;
  ReportLoaded(this.reportSummary);
}
