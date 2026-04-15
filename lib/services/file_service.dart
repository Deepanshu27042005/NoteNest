import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileService {
  final _uuid = const Uuid();

  Future<Directory> get _localDir async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'NoteNest_Files');
    final dir = Directory(path);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> saveFile(File sourceFile) async {
    final dir = await _localDir;
    final extension = p.extension(sourceFile.path);
    final fileName = '${_uuid.v4()}$extension';
    final savedFile = await sourceFile.copy(p.join(dir.path, fileName));
    return savedFile.path;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
