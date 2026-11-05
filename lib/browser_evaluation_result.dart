/// Result of a browser Content Rating Tool evaluation.
///
/// The browser is the single authority for creative/content-quality evaluation.
/// Flutter consumes these results and does not maintain its own duplicate
/// scoring system.
class BrowserEvaluationResult {
  final String ideaId;
  final String contentHash;
  final String productionHash;
  final String hashVersion;
  final String evaluationId;
  final int overallScore;
  final int rawScore;
  final bool scoreCapped;
  final String verdict;
  final List<DimensionScore> dimensionScores;
  final List<EvaluationFinding> criticalFindings;
  final List<EvaluationFinding> majorFindings;
  final List<EvaluationFinding> minorFindings;
  final List<EvaluationSuggestion> suggestions;
  final String improvedHook;
  final String storyImprovements;
  final String improvedCaption;
  final String evaluationMode; // 'offline' or 'online'
  final String evaluatedAt;
  final String evaluationVersion;
  final bool isNewEval;
  final bool isApprovalValid;
  final EvaluationSource? currentApproval;

  const BrowserEvaluationResult({
    required this.ideaId,
    required this.contentHash,
    required this.productionHash,
    required this.hashVersion,
    required this.evaluationId,
    required this.overallScore,
    required this.rawScore,
    required this.scoreCapped,
    required this.verdict,
    required this.dimensionScores,
    required this.criticalFindings,
    required this.majorFindings,
    required this.minorFindings,
    required this.suggestions,
    required this.improvedHook,
    required this.storyImprovements,
    required this.improvedCaption,
    required this.evaluationMode,
    required this.evaluatedAt,
    required this.evaluationVersion,
    required this.isNewEval,
    required this.isApprovalValid,
    this.currentApproval,
  });

  factory BrowserEvaluationResult.fromJson(Map<String, dynamic> json) {
    return BrowserEvaluationResult(
      ideaId: (json['ideaId'] as String?) ?? '',
      contentHash: (json['contentHash'] as String?) ?? '',
      productionHash: (json['productionHash'] as String?) ?? '',
      hashVersion: (json['hashVersion'] as String?) ?? '',
      evaluationId: (json['evaluationId'] as String?) ?? '',
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      rawScore: (json['rawScore'] as num?)?.toInt() ?? 0,
      scoreCapped: (json['scoreCapped'] as bool?) ?? false,
      verdict: (json['verdict'] as String?) ?? '',
      dimensionScores: (json['dimensionScores'] as List?)
          ?.map((d) => DimensionScore.fromJson(d as Map<String, dynamic>))
          .toList() ?? [],
      criticalFindings: (json['criticalFindings'] as List?)
          ?.map((f) => EvaluationFinding.fromJson(f as Map<String, dynamic>))
          .toList() ?? [],
      majorFindings: (json['majorFindings'] as List?)
          ?.map((f) => EvaluationFinding.fromJson(f as Map<String, dynamic>))
          .toList() ?? [],
      minorFindings: (json['minorFindings'] as List?)
          ?.map((f) => EvaluationFinding.fromJson(f as Map<String, dynamic>))
          .toList() ?? [],
      suggestions: (json['suggestions'] as List?)
          ?.map((s) => EvaluationSuggestion.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      improvedHook: (json['improvedHook'] as String?) ?? '',
      storyImprovements: (json['storyImprovements'] as String?) ?? '',
      improvedCaption: (json['improvedCaption'] as String?) ?? '',
      evaluationMode: (json['evaluationMode'] as String?) ?? 'offline',
      evaluatedAt: (json['evaluatedAt'] as String?) ?? '',
      evaluationVersion: (json['evaluationVersion'] as String?) ?? '',
      isNewEval: (json['isNewEval'] as bool?) ?? true,
      isApprovalValid: (json['isApprovalValid'] as bool?) ?? false,
      currentApproval: json['currentApproval'] != null
          ? EvaluationSource.fromJson(json['currentApproval'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'ideaId': ideaId,
        'contentHash': contentHash,
        'productionHash': productionHash,
        'hashVersion': hashVersion,
        'evaluationId': evaluationId,
        'overallScore': overallScore,
        'rawScore': rawScore,
        'scoreCapped': scoreCapped,
        'verdict': verdict,
        'dimensionScores': dimensionScores.map((d) => d.toJson()).toList(),
        'criticalFindings': criticalFindings.map((f) => f.toJson()).toList(),
        'majorFindings': majorFindings.map((f) => f.toJson()).toList(),
        'minorFindings': minorFindings.map((f) => f.toJson()).toList(),
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        'improvedHook': improvedHook,
        'storyImprovements': storyImprovements,
        'improvedCaption': improvedCaption,
        'evaluationMode': evaluationMode,
        'evaluatedAt': evaluatedAt,
        'evaluationVersion': evaluationVersion,
        'isNewEval': isNewEval,
        'isApprovalValid': isApprovalValid,
        'currentApproval': currentApproval?.toJson(),
      };
}

/// A single dimension score from the browser evaluator.
class DimensionScore {
  final String id;
  final String name;
  final int weight;
  final int score;
  final String explanation;
  final String whatWorks;
  final String needsImprovement;

  const DimensionScore({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    required this.explanation,
    required this.whatWorks,
    required this.needsImprovement,
  });

  factory DimensionScore.fromJson(Map<String, dynamic> json) {
    return DimensionScore(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      explanation: (json['explanation'] as String?) ?? '',
      whatWorks: (json['whatWorks'] as String?) ?? '',
      needsImprovement: (json['needsImprovement'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weight': weight,
        'score': score,
        'explanation': explanation,
        'whatWorks': whatWorks,
        'needsImprovement': needsImprovement,
      };
}

/// A single finding (critical/major/minor) from the browser evaluator.
class EvaluationFinding {
  final String title;
  final String severity;
  final String explanation;
  final String evidence;
  final String suggestedFix;

  const EvaluationFinding({
    required this.title,
    required this.severity,
    required this.explanation,
    required this.evidence,
    required this.suggestedFix,
  });

  factory EvaluationFinding.fromJson(Map<String, dynamic> json) {
    return EvaluationFinding(
      title: (json['title'] as String?) ?? '',
      severity: (json['severity'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
      evidence: (json['evidence'] as String?) ?? '',
      suggestedFix: (json['suggestedFix'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'severity': severity,
        'explanation': explanation,
        'evidence': evidence,
        'suggestedFix': suggestedFix,
      };
}

/// A single improvement suggestion from the browser evaluator.
class EvaluationSuggestion {
  final String title;
  final String explanation;
  final String original;
  final String suggested;

  const EvaluationSuggestion({
    required this.title,
    required this.explanation,
    required this.original,
    required this.suggested,
  });

  factory EvaluationSuggestion.fromJson(Map<String, dynamic> json) {
    return EvaluationSuggestion(
      title: (json['title'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
      original: (json['original'] as String?) ?? '',
      suggested: (json['suggested'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'explanation': explanation,
        'original': original,
        'suggested': suggested,
      };
}

/// Current approval status for an idea.
class EvaluationSource {
  final String approvalStatus;
  final String approvedAt;

  const EvaluationSource({
    required this.approvalStatus,
    required this.approvedAt,
  });

  factory EvaluationSource.fromJson(Map<String, dynamic> json) {
    return EvaluationSource(
      approvalStatus: (json['approvalStatus'] as String?) ?? '',
      approvedAt: (json['approvedAt'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'approvalStatus': approvalStatus,
        'approvedAt': approvedAt,
      };
}

/// Verdict categories from the browser evaluator.
class BrowserVerdict {
  static const String readyToPost = 'Ready to Post';
  static const String needsMinorFixes = 'Needs Minor Fixes';
  static const String needsMajorRewrite = 'Needs Major Rewrite';
  static const String reject = 'Reject';

  static bool isReady(String verdict) => verdict == readyToPost;
  static bool isBlocking(String verdict) =>
      verdict == needsMajorRewrite || verdict == reject;
}
