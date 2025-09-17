abstract class ReportEvent {}

class GenerateReport extends ReportEvent {
  final int month;
  final int year;
  GenerateReport(this.month, this.year);
}
