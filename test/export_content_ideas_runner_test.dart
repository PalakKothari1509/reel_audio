import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/export_content_ideas.dart' as exporter;

void main() {
  test('export content ideas', () async {
    Directory('assets/data').createSync(recursive: true);
    exporter.main();
    expect(File('assets/data/content_ideas.json').existsSync(), isTrue);
  });
}

