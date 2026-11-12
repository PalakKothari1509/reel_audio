import 'dart:io';
import 'dart:async';

Future<void> main() async {
  final result =
      await Process.run('git', ['show', 'HEAD:lib/content_library_service.dart']);
  final text = result.stdout as String;
  final lines = text.split('\n');
  for (var i = 359; i < 460 && i < lines.length; i++) {
    print('${i + 1}: ${lines[i]}');
  }
}