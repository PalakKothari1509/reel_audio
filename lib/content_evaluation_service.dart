/// Browser Content Rating Tool evaluation service.
///
/// This service is the single source of truth for creative/content-quality
/// evaluation in the Flutter app. It communicates with the browser Content
/// Rating Tool backend via `POST /api/evaluate`.
///
/// The browser evaluates the exact content submitted — including edited
/// built-in ideas and custom Flutter-created ideas. Flutter does NOT maintain
/// a duplicate scoring system. All creative/editorial scoring, verdict
/// calculation, and critical finding detection happens in the browser.
///
/// Flutter retains operational validation only:
///   - Video file validation
///   - Duration validation
///   - Aspect-ratio validation
///   - Production pipeline availability
///   - Content-format compatibility
///
/// If the browser service is unavailable, this throws an explicit exception.
/// It does NOT silently fall back to a local Dart evaluator.
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'browser_evaluation_result.dart';

/// Centralized service for content evaluation via the browser backend.
///
/// All content evaluation (scoring, verdicts, critical findings, improvement
/// suggestions) is delegated to the browser Content Rating Tool. Flutter does
/// not maintain an independent duplicate content-quality scoring system.
class ContentEvaluationService {
  static const String _apiBase = 'http://localhost:3001/api';

  /// Load built-in ideas from the browser backend's content_ideas.json.
  ///
  /// Returns the raw ideas list from the browser's authoritative content
  /// source.
  static Future<List<Map<String, dynamic>>> loadBuiltInIdeas() async {
    final response = await http.get(Uri.parse('$_apiBase/ideas'));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load built-in ideas: ${response.statusCode}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['ideas'] as List).cast<Map<String, dynamic>>();
  }

  /// Evaluate an idea via the browser Content Rating Tool.
  ///
  /// [content] is the complete HookIdea-like JSON object to evaluate. The
  /// browser evaluates exactly this content — it never substitutes a
  /// different version from its own database.
  ///
  /// [evaluationMode] is 'offline' (default) or 'online'. Online evaluation
  /// requires a Gemini API key configured on the browser backend.
  ///
  /// Throws [Exception] if the browser is unreachable or returns an error.
  static Future<BrowserEvaluationResult> evaluate({
    required Map<String, dynamic> content,
    String evaluationMode = 'offline',
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBase/evaluate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'workspaceId': 'flutter_app',
        'source': 'flutter_custom',
        'ideaId': content['id'] as String? ?? '',
        'content': content,
        'evaluationMode': evaluationMode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Browser evaluation failed: ${response.statusCode} ${response.body}',
      );
    }

    return BrowserEvaluationResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Get the current evaluation for an idea.
  static Future<BrowserEvaluationResult?> getCurrentEvaluation(
    String itemId,
  ) async {
    final response = await http.get(
      Uri.parse('$_apiBase/evaluations/$itemId/current'),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get current evaluation: ${response.statusCode}',
      );
    }
    return BrowserEvaluationResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Get the evaluation history for an idea.
  static Future<List<BrowserEvaluationResult>> getEvaluationHistory(
    String itemId,
  ) async {
    final response = await http.get(
      Uri.parse('$_apiBase/evaluations/$itemId/history'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get evaluation history: ${response.statusCode}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final history = data['history'] as List? ?? [];
    return history
        .map((e) => BrowserEvaluationResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Approve an evaluated idea.
  static Future<void> approveIdea({
    required String itemId,
    required String evaluationId,
    required String approvedBy,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBase/evaluations/$itemId/approve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'evaluationId': evaluationId,
        'approvedBy': approvedBy,
        'reason': reason,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to approve idea: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Reject an evaluated idea.
  static Future<void> rejectIdea({
    required String itemId,
    required String evaluationId,
    required String rejectedBy,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBase/evaluations/$itemId/reject'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'evaluationId': evaluationId,
        'rejectedBy': rejectedBy,
        'reason': reason,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to reject idea: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Revoke an approval.
  static Future<void> revokeIdea({
    required String itemId,
    required String revokedBy,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBase/evaluations/$itemId/revoke'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'revokedBy': revokedBy,
        'reason': reason,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to revoke idea: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Check approval validity for an idea.
  static Future<Map<String, dynamic>> checkApprovalStatus(
    String itemId,
  ) async {
    final response = await http.get(
      Uri.parse('$_apiBase/evaluations/$itemId/approval-status'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to check approval: ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get the content hash for an idea.
  static Future<Map<String, dynamic>> getContentHash(String itemId) async {
    final response = await http.get(
      Uri.parse('$_apiBase/content-hash/$itemId'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load content hash: ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get the production hash for an idea.
  static Future<Map<String, dynamic>> getProductionHash(
    String itemId,
  ) async {
    final response = await http.get(
      Uri.parse('$_apiBase/production-hash/$itemId'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load production hash: ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Batch sync evaluations from the browser.
  ///
  /// [since] is the changeSequence cursor (exclusive).
  /// [limit] is the maximum number of events per page.
  /// [itemId] optionally filters to a single idea.
  /// [eventType] optionally filters by event type.
  static Future<Map<String, dynamic>> batchSync({
    int since = 0,
    int limit = 100,
    String? itemId,
    String? eventType,
  }) async {
    final uri = Uri.parse('$_apiBase/evaluations/batch').replace(
      queryParameters: {
        'since': since.toString(),
        'limit': limit.toString(),
        if (itemId != null) 'itemId': itemId,
        if (eventType != null) 'eventType': eventType,
      },
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to sync evaluations: ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
