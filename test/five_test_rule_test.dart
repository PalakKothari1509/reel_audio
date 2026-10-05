import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/format_handbook.dart';

/// The five-test rule, as behaviour rather than as an intention.
///
/// "Don't test a format once and call it a failure" is easy to agree with and easy to
/// forget under deadline. The failure mode is concrete: one Reel underperforms, the
/// format gets retired, and nobody finds out it was actually the strongest shape on
/// the page.

void main() {
  group('five-test rule', () {
    test('the minimum is five', () {
      expect(FormatLibrary.minimumTests, 5);
    });

    test('an untested format permits no conclusion', () {
      final v = FormatLibrary.problemFix.verdict(0);
      expect(v.allowed, isFalse);
      expect(v.message, contains('Not tested yet'));
    });

    test('one test does not permit a conclusion', () {
      final v = FormatLibrary.problemFix.verdict(1);
      expect(v.allowed, isFalse,
          reason: 'the exact failure this rule exists to prevent');
      expect(v.message, contains('1/5'));
      expect(v.message, contains('4 more tests'));
    });

    test('a format is judged one test short', () {
      final v = FormatLibrary.problemFix.verdict(4);
      expect(v.allowed, isFalse);
      expect(v.message, contains('4/5'));
    });

    test('five tests permit a conclusion', () {
      final v = FormatLibrary.problemFix.verdict(5);
      expect(v.allowed, isTrue);
      expect(v.message, contains('5/5'));
    });

    test('more than five still permits a conclusion', () {
      expect(FormatLibrary.problemFix.verdict(9).allowed, isTrue);
    });

    test('the rule applies to every registered format', () {
      for (final f in FormatLibrary.all) {
        expect(f.verdict(1).allowed, isFalse, reason: '${f.id} allowed 1 test');
        expect(f.verdict(4).allowed, isFalse, reason: '${f.id} allowed 4 tests');
        expect(f.verdict(5).allowed, isTrue, reason: '${f.id} blocked 5 tests');
      }
    });

    test('the message says how many are left, not just that data is thin', () {
      // "Insufficient data" invites ignoring. A count does not.
      expect(FormatLibrary.problemFix.verdict(2).message, contains('3 more tests'));
      expect(FormatLibrary.problemFix.verdict(4).message, contains('1 more test'));
    });

    test('the minimum can be raised for a specific format', () {
      // Some shapes need more than five before they say anything.
      final v = FormatLibrary.problemFix.verdictAt(5, minTests: 8);
      expect(v.allowed, isFalse);
      expect(v.minTests, 8);
      expect(v.message, contains('3 more tests'));
    });
  });

  group('share trigger is generation logic, not metadata', () {
    test('the brand block asks the generator to name a specific parent', () {
      final source = File('lib/brand_system.dart').readAsStringSync();

      expect(source, contains('SHARE TRIGGER'));
      expect(
        source,
        contains('Why would one parent send this to another parent?'),
        reason: 'the trigger has to be reasoned about, not left implicit',
      );
      expect(
        source,
        contains('Name the specific parent'),
        reason: '"share with your friends" is not a share trigger',
      );
    });

    test('the share block rejects a post that cannot earn a share', () {
      final source = File('lib/brand_system.dart').readAsStringSync();
      expect(
        source,
        contains('the post is not ready'),
        reason: 'a share trigger must be able to fail, or it is decoration',
      );
    });
  });
}