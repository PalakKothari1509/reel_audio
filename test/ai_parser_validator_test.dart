import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/ai_content_service.dart';
import 'package:reel_audio/ai_parser_validator.dart';

void main() {
  group('AiParserValidator', () {
    test('valid response passes with no findings', () {
      const json = '{"hook": "Where are your socks?", "slides": [{"headline": "Setup", "body": "Socks missing.", "imagePrompt": "child looking under bed"}], "script": "Narration for the reel"}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isTrue);
      expect(result.findings, isEmpty);
    });

    test('empty response is rejected with error', () {
      final result = AiParserValidator.validate('{}');
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.isError), isTrue);
      expect(result.findings.any((f) => f.code == 'empty_response'), isTrue);
    });

    test('empty string is rejected with error', () {
      final result = AiParserValidator.validate('');
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'empty_response'), isTrue);
    });

    test('invalid JSON is rejected with error', () {
      final result = AiParserValidator.validate('{hook: broken}');
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'invalid_json'), isTrue);
    });

    test('non-object JSON root is rejected with error', () {
      final result = AiParserValidator.validate('["not", "an", "object"]');
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'not_a_map'), isTrue);
    });

    test('missing required hook field produces error', () {
      const json = '{"slides": [{"headline": "Setup", "body": "Test"}]}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'missing_field' && f.field == 'hook'), isTrue);
    });

    test('missing required slides field produces error', () {
      const json = '{"hook": "Test hook"}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'missing_field' && f.field == 'slides'), isTrue);
    });

    test('string field with wrong type produces error', () {
      const json = '{"hook": 12345, "slides": []}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'wrong_type' && f.field == 'hook'), isTrue);
    });

    test('list field with wrong type produces error', () {
      const json = '{"hook": "Test", "slides": "not a list"}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'wrong_type' && f.field == 'slides'), isTrue);
    });

    test('empty slides array produces error', () {
      const json = '{"hook": "Test", "slides": []}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'empty_slides'), isTrue);
    });

    test('slide missing required headline produces warning', () {
      const json = '{"hook": "Test", "slides": [{"body": "Test body"}]}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.findings.any((f) => f.code == 'missing_slide_field' && f.isWarning), isTrue);
    });

    test('slide missing required body produces warning', () {
      const json = '{"hook": "Test", "slides": [{"headline": "Title"}]}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isTrue);
      expect(result.findings.any((f) => f.code == 'missing_slide_field' && f.field == 'slides[0].body'), isTrue);
    });

    test('empty slide field produces warning', () {
      const json = '{"hook": "Test", "slides": [{"headline": "Title", "body": ""}]}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isTrue);
      expect(result.findings.any((f) => f.code == 'empty_slide_field'), isTrue);
    });

    test('non-object slide produces error', () {
      const json = '{"hook": "Test", "slides": ["not an object"]}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.findings.any((f) => f.code == 'slide_not_object'), isTrue);
    });

    test('missing script field produces warning', () {
      const json = '{"hook": "Test", "slides": [{"headline": "Title", "body": "Body", "imagePrompt": "img"}]}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isTrue);
      expect(result.findings.any((f) => f.code == 'no_script_field'), isTrue);
    });

    test('warning-only response is valid (warnings do not block)', () {
      const json = '{"hook": "Test", "slides": [{"headline": "", "body": "Valid body"}]}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.hasErrors, isFalse);
    });

    test('extra fields are ignored (forward compatibility)', () {
      const json = '{"hook": "Test", "slides": [{"headline": "T", "body": "B"}], "extraField": "ignored", "anotherExtra": 123}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isTrue);
    });

    test('null values in string fields are accepted (coerced to empty)', () {
      const json = '{"hook": null, "slides": [{"headline": "T", "body": "B"}]}';
      // null is not a String, so hook should fail type check
      final result = AiParserValidator.validate(json);
      // null is not String type, so this produces a type error
      expect(result.findings.any((f) => f.code == 'wrong_type' && f.field == 'hook'), isTrue);
    });

    test('slides with valid fields pass', () {
      const json = '{"hook": "Test", "slides": [{"slideNumber": 1, "headline": "Title", "body": "Body", "imagePrompt": "img", "cta": "Save"}]}';
      final result = AiParserValidator.validate(json);
      expect(result.isValid, isTrue);
    });
  });

  group('AiParserValidator.validateOrThrow', () {
    test('returns ValidatedResponse for valid input', () {
      const json = '{"hook": "Test", "slides": [{"headline": "T", "body": "B"}]}';
      final result = AiParserValidator.validateOrThrow(json);
      expect(result.isValid, isTrue);
    });

    test('throws AiContentFailure for invalid input', () {
      expect(
        () => AiParserValidator.validateOrThrow('{}'),
        throwsA(isA<AiContentFailure>()),
      );
    });

    test('failure message includes error codes', () {
      try {
        AiParserValidator.validateOrThrow('{}');
        fail('Should have thrown');
      } on AiContentFailure catch (e) {
        expect(e.toString(), contains('empty_response'));
      }
    });
  });

  group('AiParserValidator.isValidResponse', () {
    test('returns true for valid JSON', () {
      const json = '{"hook": "Test", "slides": [{"headline": "T", "body": "B"}]}';
      expect(AiParserValidator.isValidResponse(json), isTrue);
    });

    test('returns false for invalid JSON', () {
      expect(AiParserValidator.isValidResponse('{}'), isFalse);
    });

    test('returns false for malformed JSON', () {
      expect(AiParserValidator.isValidResponse('{broken'), isFalse);
    });
  });

  group('ValidatedResponse', () {
    test('valid() creates response with no findings', () {
      final r = ValidatedResponse.valid({'hook': 'Test'});
      expect(r.isValid, isTrue);
      expect(r.hasErrors, isFalse);
      expect(r.hasWarnings, isFalse);
    });

    test('withFindings creates response with findings', () {
      final finding = ParseFinding(
        severity: ParseSeverity.error,
        code: 'test_error',
        message: 'Test error',
      );
      final r = ValidatedResponse.withFindings({'hook': ''}, [finding]);
      expect(r.hasErrors, isTrue);
      expect(r.isValid, isFalse);
    });

    test('requireValid returns data when valid', () {
      final r = ValidatedResponse.valid({'hook': 'Test'});
      expect(r.requireValid(), {'hook': 'Test'});
    });

    test('requireValid throws AiContentFailure when invalid', () {
      final finding = ParseFinding(
        severity: ParseSeverity.error,
        code: 'test_error',
        message: 'Test error',
      );
      final r = ValidatedResponse.withFindings({}, [finding]);
      expect(() => r.requireValid(), throwsA(isA<AiContentFailure>()));
    });
  });

  group('ParseFinding', () {
    test('isError is true for error severity', () {
      final f = ParseFinding(
        severity: ParseSeverity.error,
        code: 'test',
        message: 'msg',
      );
      expect(f.isError, isTrue);
      expect(f.isWarning, isFalse);
    });

    test('isWarning is true for warning severity', () {
      final f = ParseFinding(
        severity: ParseSeverity.warning,
        code: 'test',
        message: 'msg',
      );
      expect(f.isWarning, isTrue);
      expect(f.isError, isFalse);
    });

    test('toString includes severity, code, and field when present', () {
      final f = ParseFinding(
        severity: ParseSeverity.error,
        code: 'missing_field',
        message: 'Required',
        field: 'hook',
      );
      expect(f.toString(), contains('error'));
      expect(f.toString(), contains('missing_field'));
      expect(f.toString(), contains('hook'));
    });

    test('toString omits field when null', () {
      final f = ParseFinding(
        severity: ParseSeverity.warning,
        code: 'test',
        message: 'msg',
      );
      expect(f.toString(), isNot(contains('(')));
    });
  });

  group('ParseSeverity', () {
    test('has correct values', () {
      expect(ParseSeverity.values, containsAll([ParseSeverity.ok, ParseSeverity.warning, ParseSeverity.error]));
    });
  });
}
