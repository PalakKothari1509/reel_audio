import 'dart:convert';
import 'dart:io';
import 'package:reel_audio/content_ideas.dart';

void main() {
  final jsonFile = File('assets/data/content_ideas.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln('MISSING: assets/data/content_ideas.json');
    exit(1);
  }
  final jsonData = jsonDecode(jsonFile.readAsStringSync());
  final List ideas = jsonData['ideas'] as List;
  if (ideas.length != 117) {
    stderr.writeln('COUNT_MISMATCH: expected 117');
    exit(1);
  }
  print('OK');
}
