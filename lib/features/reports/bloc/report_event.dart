abstract class ReportEvent {}

class UploadFile extends ReportEvent {
  final String filePath;
  UploadFile(this.filePath);
}
