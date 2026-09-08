// The default Flutter template test referenced MyApp, which this app does not have,
// so it failed to compile. Replaced with a real check of the script parser — the part
// most likely to break, since Gemini's output is never quite the same twice.

import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/main.dart';

void main() {
  test('reads timestamped lines and puts them in order', () {
    final lines = parseScript('0:08 Rio bhi aa gaya\n0:00 Ek baar ki baat hai');

    expect(lines.length, 2);
    expect(lines.first.text, 'Ek baar ki baat hai');
    expect(lines.last.time, const Duration(seconds: 8));
  });

  test('ignores bullets and numbering that Gemini sometimes adds', () {
    final lines = parseScript('* 0:04 Ria ne dekha ek titli\nsome stray explanation');

    expect(lines.length, 1);
    expect(lines.first.text, 'Ria ne dekha ek titli');
  });
}
