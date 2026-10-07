import 'dart:io';

import 'idea_decisions.dart';

void main() {
  final f = File('tool/idea_decisions.csv');
  print('exists: ${f.existsSync()}');
  final lines = f.readAsLinesSync();
  print('lines: ${lines.length}');
  var count = 0;
  for (var i = 1; i < lines.length; i++) {
    final l = lines[i];
    if (l.trim().isEmpty || l.trimLeft().startsWith('#')) continue;
    count++;
  }
  print('non-comment lines: $count');
  
  final out = readIdeaDecisions('tool/idea_decisions.csv');
  print('readIdeaDecisions returned ${out.length} entries');
  if (out.entries.isNotEmpty) {
    print('first entry key: ${out.entries.first.key}');
  }
}
