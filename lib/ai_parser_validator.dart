// AI response parser validation layer.
//
// Sits between raw AI JSON output and the GeneratedContent conversion.
// Validates structure, extracts narration/dialogue, and reports typed
// errors instead of letting malformed output produce silent empty results.
//
// Pure Dart — no Flutter dependencies.

import 'dart:convert';

import 'ai_content_service.dart';

/// Severity of a validation problem.
enum ParseSeverity { ok, warning, error }

/// A single validation finding.
class ParseFinding {
  final ParseSeverity severity;
  final String code;
  final String message;
  final String? field;
  final Object? value;

  const ParseFinding({
    required this.severity,
    required this.code,
    required this.message,
    this.field,
    this.value,
  });

  bool get isError => severity == ParseSeverity.error;
  bool get isWarning => severity == ParseSeverity.warning;

  @override
  String toString() => '[${severity.name}] $code: $message${field != null ? ' ($field)' : ''}';
}

/// Validated AI response ready for conversion to GeneratedContent.
class ValidatedResponse {
  /// The decoded JSON map (already verified to be a Map).
  final Map<String, dynamic> data;

  /// All findings from validation.
  final List<ParseFinding> findings;

  /// Whether validation found no errors.
  bool get isValid => !findings.any((f) => f.isError);

  /// Whether validation found at least one requirement failure.
  bool get hasErrors => findings.any((f) => f.isError);

  /// Whether validation found at least one warning.
  bool get hasWarnings => findings.any((f) => f.isWarning);

  const ValidatedResponse._(this.data, this.findings);

  /// Creates a valid response from already-validated data.
  static ValidatedResponse valid(Map<String, dynamic> data) =>
      ValidatedResponse._(data, []);

  /// Creates a response with findings.
  static ValidatedResponse withFindings(
    Map<String, dynamic> data,
    List<ParseFinding> findings,
  ) =>
      ValidatedResponse._(data, findings);

  /// Convenience: throw if invalid, returning data.
  Map<String, dynamic> requireValid() {
    if (!isValid) {
      final errors = findings.where((f) => f.isError).join('; ');
      throw AiContentFailure('AI response validation failed: $errors');
    }
    return data;
  }
}

/// Validates raw AI JSON responses before they are converted to
/// GeneratedContent.
///
/// This is the single place where the contract between "what the AI returns"
/// and "what we need to generate content" is checked. A parser failure here
/// is the only thing that should produce an [AiContentFailure] — everything
/// downstream assumes the response is valid.
class AiParserValidator {
  /// Required top-level fields in a valid AI response.
  static const requiredFields = <String>['hook', 'slides'];

  /// Required fields in each slide.
  static const requiredSlideFields = <String>['headline', 'body'];

  /// Fields that must be strings when present.
  static const stringFields = <String>[
    'hook', 'topic', 'bucket', 'caption', 'script', 'pinnedComment',
  ];

  /// Fields that must be lists when present.
  static const listFields = <String>[
    'hashtags', 'replyComments', 'slides',
  ];

  /// Validates raw JSON text from an AI provider.
  ///
  /// Returns a [ValidatedResponse] with findings. The caller can choose
  /// to throw ([ValidatedResponse.requireValid]) or proceed with warnings.
  static ValidatedResponse validate(String jsonText) {
    final findings = <ParseFinding>[];

    // ── Must be valid JSON ────────────────────────────────────────────
    if (jsonText.isEmpty || jsonText.trim() == '{}') {
      return ValidatedResponse.withFindings({}, [
        ParseFinding(
          severity: ParseSeverity.error,
          code: 'empty_response',
          message: 'AI response was empty or just "{}"',
        ),
      ]);
    }

    late final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        return ValidatedResponse.withFindings({}, [
          ParseFinding(
            severity: ParseSeverity.error,
            code: 'not_a_map',
            message: 'AI response root is not a JSON object',
            value: decoded.runtimeType.toString(),
          ),
        ]);
      }
      data = decoded;
    } on FormatException catch (e) {
      return ValidatedResponse.withFindings({}, [
        ParseFinding(
          severity: ParseSeverity.error,
          code: 'invalid_json',
          message: 'AI response is not valid JSON: ${e.message}',
        ),
      ]);
    }

    // ── Check required fields ─────────────────────────────────────────
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        findings.add(ParseFinding(
          severity: ParseSeverity.error,
          code: 'missing_field',
          message: 'Required field "$field" is missing',
          field: field,
        ));
      }
    }

    // ── Check type constraints ────────────────────────────────────────
    for (final field in stringFields) {
      if (data.containsKey(field) && data[field] is! String) {
        findings.add(ParseFinding(
          severity: ParseSeverity.error,
          code: 'wrong_type',
          message: 'Field "$field" must be a string',
          field: field,
          value: data[field],
        ));
      }
    }

    for (final field in listFields) {
      if (data.containsKey(field) && data[field] is! List) {
        findings.add(ParseFinding(
          severity: ParseSeverity.error,
          code: 'wrong_type',
          message: 'Field "$field" must be a list',
          field: field,
          value: data[field],
        ));
      }
    }

    // ── Validate slides ───────────────────────────────────────────────
    final slides = data['slides'];
    if (slides is List) {
      if (slides.isEmpty) {
        findings.add(ParseFinding(
          severity: ParseSeverity.error,
          code: 'empty_slides',
          message: 'Slides array is empty — no content was generated',
          field: 'slides',
        ));
      }

      for (int i = 0; i < slides.length; i++) {
        final slide = slides[i];
        if (slide is! Map<String, dynamic>) {
          findings.add(ParseFinding(
            severity: ParseSeverity.error,
            code: 'slide_not_object',
            message: 'Slide at index $i is not a JSON object',
            field: 'slides[$i]',
            value: slide,
          ));
          continue;
        }

        for (final req in requiredSlideFields) {
          if (!slide.containsKey(req)) {
            findings.add(ParseFinding(
              severity: ParseSeverity.warning,
              code: 'missing_slide_field',
              message: 'Slide $i is missing required field "$req"',
              field: 'slides[$i].$req',
            ));
          } else if (slide[req] is String && (slide[req] as String).trim().isEmpty) {
            findings.add(ParseFinding(
              severity: ParseSeverity.warning,
              code: 'empty_slide_field',
              message: 'Slide $i field "$req" is empty',
              field: 'slides[$i].$req',
            ));
          }
        }

        // Check imagePrompt on each slide
        if (slide['imagePrompt'] != null && slide['imagePrompt'] is! String) {
          findings.add(ParseFinding(
            severity: ParseSeverity.warning,
            code: 'wrong_type',
            message: 'Slide $i imagePrompt must be a string',
            field: 'slides[$i].imagePrompt',
            value: slide['imagePrompt'],
          ));
        }
      }
    }

    // ── Check for narration/dialogue extraction ───────────────────────
    // The schema includes 'script' as a top-level field. If present,
    // we can extract narration from it. If absent but slides exist,
    // we can build narration from slide bodies.
    if (data['script'] is String && (data['script'] as String).trim().isNotEmpty) {
      // Script is present — good, narration can be derived.
    } else {
      findings.add(ParseFinding(
        severity: ParseSeverity.warning,
        code: 'no_script_field',
        message: 'No "script" field in response — narration will be built from slide bodies',
        field: 'script',
      ));
    }

    // ── Check hook quality ────────────────────────────────────────────
    final hook = data['hook'];
    if (hook is String && hook.trim().isEmpty) {
      findings.add(ParseFinding(
        severity: ParseSeverity.warning,
        code: 'empty_hook',
        message: 'Hook field is present but empty',
        field: 'hook',
      ));
    }

    // ── Ensure at least some meaningful content ──────────────────────
    if (slides is List && slides.length == 1) {
      final slide = slides.first;
      if (slide is Map<String, dynamic>) {
        final body = slide['body'] as String? ?? '';
        if (body.length < 10) {
          findings.add(ParseFinding(
            severity: ParseSeverity.warning,
            code: 'insufficient_content',
            message: 'Only one slide with very short body — content may be incomplete',
            field: 'slides[0].body',
            value: body,
          ));
        }
      }
    }

    return ValidatedResponse.withFindings(data, findings);
  }

  /// Validates and throws [AiContentFailure] if the response is invalid
  /// (has errors, but not warnings).
  static ValidatedResponse validateOrThrow(String jsonText) {
    final result = validate(jsonText);
    if (!result.isValid) {
      final errors = result.findings.where((f) => f.isError).join('; ');
      throw AiContentFailure(
        'AI response validation failed: $errors',
      );
    }
    return result;
  }

  /// Validates and returns true if the response passes validation.
  static bool isValidResponse(String jsonText) {
    try {
      validateOrThrow(jsonText);
      return true;
    } on AiContentFailure {
      return false;
    }
  }
}
