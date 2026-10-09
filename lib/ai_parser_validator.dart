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
  /// Handles several common failure modes:
  /// - Markdown-wrapped JSON (Gemini often wraps in ```json blocks)
  /// - Truncated JSON (incomplete response due to token limits)
  /// - Empty or whitespace-only responses
  /// - Non-object roots
  /// - Missing required fields
  /// - Wrong field types
  ///
  /// Returns a [ValidatedResponse] with findings. The caller can choose
  /// to throw ([ValidatedResponse.requireValid]) or proceed with warnings.
  static ValidatedResponse validate(String jsonText) {
    final findings = <ParseFinding>[];

    // ── Strip markdown wrapping ───────────────────────────────────────
    // Gemini often wraps JSON in ```json ... ``` blocks.
    final stripped = _stripMarkdownCodeBlocks(jsonText);
    if (stripped != jsonText.trim()) {
      findings.add(ParseFinding(
        severity: ParseSeverity.warning,
        code: 'markdown_wrapped',
        message: 'AI response was wrapped in markdown code block — extracted inner JSON',
      ));
    }

    // ── Must be valid JSON ────────────────────────────────────────────
    final workText = stripped.trim();
    if (workText.isEmpty || workText == '{}') {
      return ValidatedResponse.withFindings({}, [
        if (workText.isEmpty)
          ParseFinding(
            severity: ParseSeverity.error,
            code: 'empty_response',
            message: 'AI response was empty or whitespace only',
          )
        else
          ParseFinding(
            severity: ParseSeverity.error,
            code: 'empty_response',
            message: 'AI response was empty or just "{}"',
          ),
        ...findings,
      ]);
    }

    late final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(workText);
      if (decoded is! Map<String, dynamic>) {
        return ValidatedResponse.withFindings({}, [
          ParseFinding(
            severity: ParseSeverity.error,
            code: 'not_a_map',
            message: 'AI response root is not a JSON object',
            value: decoded.runtimeType.toString(),
          ),
          ...findings,
        ]);
      }
      data = decoded;
    } on FormatException catch (e) {
      // Truncated JSON (e.g. '{"hook": "test", "slides": [{"headline": "H"')
      // produces a FormatException. Distinguish from general JSON errors.
      final isTruncated = _looksTruncated(workText);
      return ValidatedResponse.withFindings({}, [
        ParseFinding(
          severity: ParseSeverity.error,
          code: isTruncated ? 'truncated_json' : 'invalid_json',
          message: isTruncated
              ? 'AI response appears truncated (incomplete JSON): ${e.message}'
              : 'AI response is not valid JSON: ${e.message}',
        ),
        ...findings,
      ]);
    } catch (e) {
      return ValidatedResponse.withFindings({}, [
        ParseFinding(
          severity: ParseSeverity.error,
          code: 'parse_error',
          message: 'Failed to parse AI response: $e',
        ),
        ...findings,
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

  /// Strips markdown code fence wrapping (```json ... ```) from AI output.
  /// Returns the original string if no wrapping is detected.
  static String _stripMarkdownCodeBlocks(String text) {
    final trimmed = text.trim();
    // Match ```json, ```, or ```json followed by optional whitespace and content
    final match = RegExp(r'^```(?:\w+)?\s*([\s\S]*?)\s*```$').firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!;
    }
    // Also handle case where there's a leading ``` without trailing
    final startMatch = RegExp(r'^```(?:\w+)?\s*\n').firstMatch(trimmed);
    if (startMatch != null) {
      final rest = trimmed.substring(startMatch.end);
      final endIdx = rest.lastIndexOf('```');
      if (endIdx != -1) {
        return rest.substring(0, endIdx).trim();
      }
    }
    return text;
  }

  /// Heuristic: does the text look like truncated JSON?
  /// Truncated JSON typically has an unclosed string, bracket, or brace.
  static bool _looksTruncated(String text) {
    final trimmed = text.trim();

    // Count open vs close brackets/braces
    var openBraces = 0;
    var closeBraces = 0;
    var openBrackets = 0;
    var closeBrackets = 0;
    var openStrings = 0;
    var escaped = false;

    for (var i = 0; i < trimmed.length; i++) {
      final c = trimmed[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (c == '\\') {
        escaped = true;
        continue;
      }
      if (c == '"') {
        openStrings++;
        continue;
      }
      if (openStrings.isOdd) continue; // inside a string

      switch (c) {
        case '{':
          openBraces++;
        case '}':
          closeBraces++;
        case '[':
          openBrackets++;
        case ']':
          closeBrackets++;
      }
    }

    // Unbalanced brackets/braces or unclosed string suggest truncation
    final hasUnclosedString = openStrings.isOdd;
    final hasUnclosedBraces = openBraces > closeBraces;
    final hasUnclosedBrackets = openBrackets > closeBrackets;

    return hasUnclosedString || hasUnclosedBraces || hasUnclosedBrackets;
  }
}
