import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

void main() async {
  Uint8List bytes = Uint8List(0);
  await FileSaver.instance.saveFile(
    name: 'test',
    bytes: bytes,
    fileExtension: 'pdf',
    mimeType: MimeType.pdf,
  );
}
