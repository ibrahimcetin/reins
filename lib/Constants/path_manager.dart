import 'dart:io';

import 'package:path_provider/path_provider.dart';

class PathManager {
  static final PathManager _instance = PathManager._internal();
  late final Directory documentsDirectory;

  PathManager._internal();

  static Future<void> initialize() async {
    if (Platform.isLinux) {
      final directory = await getApplicationSupportDirectory();
      _instance.documentsDirectory = directory;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      _instance.documentsDirectory = directory;
    }
  }

  static PathManager get instance => _instance;
}
