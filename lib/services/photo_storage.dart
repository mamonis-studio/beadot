import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoStorage {
  static const String _subDir = 'photos';

  static Future<Directory> _photosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _subDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> savePhoto(List<int> bytes, String fileName) async {
    final dir = await _photosDir();
    final file = File(p.join(dir.path, p.basename(fileName)));
    await file.writeAsBytes(bytes);
    return p.basename(fileName);
  }

  static Future<String> resolve(String stored) async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, _subDir, p.basename(stored));
  }

  static Future<bool> delete(String stored) async {
    try {
      final file = File(await resolve(stored));
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
