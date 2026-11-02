import 'dart:convert';
import 'dart:io';
import 'package:reel_audio/content_ideas.dart';

void main() {
  final List<HookIdea> all = [];
  final seen = <String>{};
  
  for (final h in kDefaultHooks) {
    if (seen.contains(h.id)) {
      stderr.writeln('DUPLICATE ID: ' + h.id);
      exit(1);
    }
    all.add(h);
    seen.add(h.id);
  }
  
  if (all.length != 117) {
    stderr.writeln('Expected 117 records, got ' + all.length.toString());
    exit(1);
  }
  
  if (seen.length != 117) {
    stderr.writeln('Expected 117 unique IDs, got ' + seen.length.toString());
    exit(1);
  }
  
  final out = {
    'version': '1.0.0',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'ideas': all.map((e) => e.toJson()).toList(),
  };
  
  Directory('assets/data').createSync(recursive: true);
  File('assets/data/content_ideas.json').writeAsStringSync(JsonEncoder.withIndent('  ').convert(out));
  
  print('Records: ' + all.length.toString());
  print('Unique IDs: ' + seen.length.toString());
  print('Written to assets/data/content_ideas.json');
}
