import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:reins/Constants/constants.dart';

class FileService {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedExtensions = ['pdf', 'md', 'markdown', 'txt'];

  Future<Directory> getDocumentsDirectory() async {
    final documentsDirectory = PathManager.instance.documentsDirectory;
    final documentsPath = path.join(documentsDirectory.path, 'documents');
    return await Directory(documentsPath).create(recursive: true);
  }

  Future<List<File>> pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return [];

      final pickedFile = result.files.first;
      if (pickedFile.path == null) return [];

      final file = File(pickedFile.path!);
      
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) return [];

      // Copy to app documents directory
      final documentsDir = await getDocumentsDirectory();
      final fileName = '${DateTime.now().microsecondsSinceEpoch}_${pickedFile.name}';
      final targetPath = path.join(documentsDir.path, fileName);
      final copiedFile = await file.copy(targetPath);

      return [copiedFile];
    } catch (e) {
      return [];
    }
  }

  Future<String?> extractTextContent(File file) async {
    try {
      final extension = path.extension(file.path).toLowerCase();
      
      switch (extension) {
        case '.pdf':
          final bytes = await file.readAsBytes();
          final document = PdfDocument(inputBytes: bytes);
          final textExtractor = PdfTextExtractor(document);
          final text = textExtractor.extractText();
          document.dispose();
          return text;
        case '.md':
        case '.markdown':
        case '.txt':
          return await file.readAsString();
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteDocument(File documentFile) async {
    if (await documentFile.exists()) {
      await documentFile.delete();
    }
  }

  Future<void> deleteDocuments(List<File> documentFiles) async {
    await Future.wait(documentFiles.map((file) => deleteDocument(file)));
  }

  String getFileTypeIcon(File file) {
    final extension = path.extension(file.path).toLowerCase();
    switch (extension) {
      case '.pdf':
        return '📄';
      case '.md':
      case '.markdown':
        return '📝';
      case '.txt':
        return '📄';
      default:
        return '📎';
    }
  }
}