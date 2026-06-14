import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AudioCacheHelper {
  static Future<Directory> getCacheDirectory() async {
    Directory? baseDir;
    if (Platform.isAndroid) {
      baseDir = await getExternalStorageDirectory();
    }
    baseDir ??= await getApplicationDocumentsDirectory();

    final targetDir = Directory('${baseDir.path}/cached_songs');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  static Future<double> getCacheSizeMb() async {
    try {
      final dir = await getCacheDirectory();
      if (!await dir.exists()) return 0.0;
      
      int totalSize = 0;
      final List<FileSystemEntity> files = dir.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize / (1024 * 1024); // Convert bytes to MB
    } catch (_) {
      return 0.0;
    }
  }

  static Future<void> clearCache() async {
    try {
      final dir = await getCacheDirectory();
      if (await dir.exists()) {
        final List<FileSystemEntity> files = dir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (_) {}
  }
}
