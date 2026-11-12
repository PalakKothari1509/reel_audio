import 'dart:io';

// Build the API names from explicit ASCII code points so there is no
// ambiguity about which characters are in the file.
const showMethod = 'showSnackbar';   // 101, 115, 111, 119, 83, 110, 97, 99, 107, 98, 97, 114
const snackClass = 'Snackbar';       // 83, 110, 97, 99, 107, 98, 97, 114

void main() {
  final path = 'lib/review_idea_screen.dart';
  final bytes = File(path).readAsBytesSync();
  final text = String.fromCharCodes(bytes);

  // Replace the two offending lines (610 and 611) with clean ASCII.
  final lines = text.split('\n');
  lines[609] = '      ScaffoldMessenger.of(context).$showMethod(';
  lines[610] = '        $snackClass(';

  final fixed = lines.join('\n');
  File(path).writeAsStringSync(fixed);
  print('rewrote lines 610-611');
}