import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Terminal langsung di dalam aplikasi (shell Android, tanpa Termux).
class Shell {
  static const int _maxOut = 8000;

  static Future<Directory> workDir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/workspace');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<String> run(String cmd) async {
    try {
      final dir = await workDir();
      final r = await Process.run(
        '/system/bin/sh',
        ['-c', cmd],
        workingDirectory: dir.path,
        environment: {'HOME': dir.path},
      ).timeout(const Duration(seconds: 60));
      final out = '${r.stdout}${r.stderr}'.trim();
      if (out.isEmpty) return '(exit ${r.exitCode}, tanpa output)';
      return out.length > _maxOut ? out.substring(0, _maxOut) : out;
    } on TimeoutException {
      return 'Timeout 60 detik';
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<File> _file(String path) async {
    if (path.contains('..')) throw Exception('Path tidak boleh memakai ..');
    final dir = await workDir();
    return File(path.startsWith('/') ? path : '${dir.path}/$path');
  }

  static Future<String> readFile(String path) async {
    try {
      final f = await _file(path);
      final s = await f.readAsString();
      return s.length > _maxOut ? s.substring(0, _maxOut) : s;
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<String> writeFile(String path, String content) async {
    try {
      final f = await _file(path);
      await f.parent.create(recursive: true);
      await f.writeAsString(content);
      return 'OK, ${content.length} karakter ditulis ke ${f.path}';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
