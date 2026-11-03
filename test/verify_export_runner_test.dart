import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/verify_export.dart';

void main() {
  test('verify exported content ideas', () {
    Directory('assets/data').createSync(recursive: true);
    verifyExport();
  });
}
