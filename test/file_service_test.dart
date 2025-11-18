import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reins/Services/file_service.dart';

void main() {
  group('FileService', () {
    late FileService fileService;

    setUp(() {
      fileService = FileService();
    });

    test('should return correct file type icons', () {
      expect(fileService.getFileTypeIcon(File('test.pdf')), '📄');
      expect(fileService.getFileTypeIcon(File('test.md')), '📝');
      expect(fileService.getFileTypeIcon(File('test.markdown')), '📝');
      expect(fileService.getFileTypeIcon(File('test.txt')), '📄');
      expect(fileService.getFileTypeIcon(File('test.unknown')), '📎');
    });

    test('should validate supported extensions', () {
      expect(FileService.supportedExtensions, contains('pdf'));
      expect(FileService.supportedExtensions, contains('md'));
      expect(FileService.supportedExtensions, contains('markdown'));
      expect(FileService.supportedExtensions, contains('txt'));
    });

    test('should have reasonable file size limit', () {
      expect(FileService.maxFileSizeBytes, equals(10 * 1024 * 1024)); // 10MB
    });
  });
}