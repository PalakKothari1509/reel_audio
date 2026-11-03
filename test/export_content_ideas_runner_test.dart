import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export content ideas', () async {
    Directory('assets/data').createSync(recursive: true);
    final result = await Process.run(
      'dart',
      ['run', 'scripts/export_content_ideas.dart'],
      workingDirectory: Directory.current.path,
    );
    if (result.exitCode != 0) {
      fail('Exporter failed with exit code ${result.exitCode}\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}');
    }
    expect(File('assets/data/content_ideas.json').existsSync(), isTrue);
  });
}
