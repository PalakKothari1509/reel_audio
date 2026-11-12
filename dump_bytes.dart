import 'dart:io';

void main() {
  final path = 'lib/review_idea_screen.dart';
  final bytes = File(path).readAsBytesSync();
  final text = String.fromCharCodes(bytes);
  final lines = text.split('\n');
  final line = lines[609]; // line 610
  print('LINE 610: |$line|');
  print('length: ${line.length}');
  for (var i = 0; i < line.length; i++) {
    final c = line.codeUnitAt(i);
    if (c < 32 || c > 126) {
      print('  pos $i: U+${c.toRadixString(16).padLeft(4, '0')}');
    }
  }
}