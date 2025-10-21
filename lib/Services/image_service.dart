import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_compression/image_compression.dart' as img_compress;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Handles all image storage and compression operations
class ImageService {
  Future<Directory> getImagesDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final imagesPath = path.join(documentsDirectory.path, 'images');
    return await Directory(imagesPath).create(recursive: true);
  }

  Future<File?> compressAndSave(String sourcePath, {int quality = 10}) async {
    try {
      final imagesDir = await getImagesDirectory();
      final targetPath = path.join(
        imagesDir.path,
        '${DateTime.now().microsecondsSinceEpoch}.jpg',
      );

      return await _compressAndSaveImageForPlatform(
        sourcePath,
        targetPath,
        quality: quality,
      );
    } catch (e) {
      return null;
    }
  }

  Future<File?> _compressAndSaveImageForPlatform(
    String sourcePath,
    String targetPath, {
    int quality = 10,
  }) async {
    Function(String, String, {int quality}) function;

    if (Platform.isLinux) {
      function = _compressAndSaveImageLinux;
    } else {
      function = _compressAndSaveImage;
    }

    return function(
      sourcePath,
      targetPath,
      quality: quality,
    );
  }

  Future<File?> _compressAndSaveImage(
    String sourcePath,
    String targetPath, {
    int quality = 10,
  }) async {
    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: quality,
    );

    return compressed != null ? File(compressed.path) : null;
  }

  Future<File?> _compressAndSaveImageLinux(
    String sourcePath,
    String targetPath, {
    int quality = 10,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;

    final inputImage = img_compress.ImageFile(
      filePath: sourcePath,
      rawBytes: await sourceFile.readAsBytes(),
    );

    final compressedImage = await img_compress.compressInQueue(
      img_compress.ImageFileConfiguration(
        input: inputImage,
        config: img_compress.Configuration(jpgQuality: quality),
      ),
    );

    return await File(targetPath).writeAsBytes(compressedImage.rawBytes);
  }

  Future<void> deleteImage(File imageFile) async {
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

  Future<void> deleteImages(List<File> imageFiles) async {
    await Future.wait(imageFiles.map((file) => deleteImage(file)));
  }
}
