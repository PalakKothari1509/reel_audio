import 'content_ideas.dart';
import 'master_prompt.dart';

/// Result of a single health check on a [HookIdea].
class HealthCheckResult {
  final String name;
  final bool passed;
  final String message;
  final HealthSeverity severity;

  const HealthCheckResult({
    required this.name,
    required this.passed,
    required this.message,
    this.severity = HealthSeverity.warning,
  });
}

/// Severity levels for health check findings.
enum HealthSeverity { pass, suggestion, warning, critical }

/// Overall health summary for a [HookIdea].
class HookHealth {
  final HookIdea idea;
  final List<HealthCheckResult> checks;
  final DateTime checkedAt;

  HookHealth(this.idea, this.checks, this.checkedAt);

  int get passCount => checks.where((c) => c.passed).length;
  int get failCount => checks.where((c) => !c.passed).length;

  /// 'Healthy', 'Needs Review', or 'At Risk'
  String get status {
    if (failCount == 0) return 'Healthy';
    final criticalCount =
        checks.where((c) => !c.passed && c.severity == HealthSeverity.critical).length;
    if (criticalCount > 0) return 'At Risk';
    return 'Needs Review';
  }

  /// A score from 0 to 100.
  int get score {
    if (checks.isEmpty) return 0;
    final weighted = checks.fold<double>(0, (sum, c) {
          final weight = switch (c.severity) {
            HealthSeverity.pass => 1.0,
            HealthSeverity.suggestion => 0.5,
            HealthSeverity.warning => 0.8,
            HealthSeverity.critical => 0.0,
          };
          return sum + (c.passed ? weight : 0);
        }) /
        checks.length;
    return (weighted * 100).round();
  }
}

/// Runs all built-in health checks on a [HookIdea].
List<HealthCheckResult> checkHookHealth(HookIdea idea) {
  final results = <HealthCheckResult>[];

  // 1. Core fields present
  final missingCore = <String>[];
  if (idea.id.trim().isEmpty) missingCore.add('id');
  if (idea.category.trim().isEmpty) missingCore.add('category');
  if (idea.cover.trim().isEmpty) missingCore.add('cover');
  if (idea.opening.trim().isEmpty) missingCore.add('opening');
  if (idea.problem.trim().isEmpty) missingCore.add('problem');
  if (idea.lesson.trim().isEmpty) missingCore.add('lesson');
  if (idea.storyDetail.trim().isEmpty) missingCore.add('storyDetail');
  results.add(HealthCheckResult(
    name: 'Core Fields',
    passed: missingCore.isEmpty,
    message: missingCore.isEmpty
        ? 'All core fields present.'
        : 'Missing: ${missingCore.join(', ')}',
    severity: missingCore.isEmpty ? HealthSeverity.pass : HealthSeverity.critical,
  ));

  // 2. Moment fields present
  final missingMoment = <String>[];
  if (idea.setting.trim().isEmpty) missingMoment.add('setting');
  if (idea.sceneDetail.trim().isEmpty) missingMoment.add('sceneDetail');
  if (idea.dialogue.trim().isEmpty) missingMoment.add('dialogue');
  if (idea.mess.trim().isEmpty) missingMoment.add('mess');
  if (idea.innerThought.trim().isEmpty) missingMoment.add('innerThought');
  if (idea.endingBeat.trim().isEmpty) missingMoment.add('endingBeat');
  results.add(HealthCheckResult(
    name: 'Moment Fields',
    passed: missingMoment.isEmpty,
    message: missingMoment.isEmpty
        ? 'All moment fields present.'
        : 'Missing: ${missingMoment.join(', ')}',
    severity: missingMoment.isEmpty ? HealthSeverity.pass : HealthSeverity.warning,
  ));

  // 3. Ready prompt present (for non-archived, forApp hooks)
  final needsReadyPrompt = !idea.archived && idea.forApp;
  results.add(HealthCheckResult(
    name: 'Ready Prompt',
    passed: !needsReadyPrompt || idea.readyPrompt.trim().isNotEmpty,
    message: !needsReadyPrompt
        ? 'Archived or not app-built — readyPrompt not required.'
        : idea.readyPrompt.trim().isNotEmpty
            ? 'Ready prompt present.'
            : 'Missing readyPrompt for app-built hook.',
    severity: !needsReadyPrompt
        ? HealthSeverity.pass
        : (idea.readyPrompt.trim().isNotEmpty
            ? HealthSeverity.pass
            : HealthSeverity.warning),
  ));

  // 4. Banned phrases check
  final textToCheck = [
    idea.storyDetail,
    idea.opening,
    idea.problem,
    idea.lesson,
    idea.dialogue,
    idea.endingBeat,
    idea.innerThought,
    idea.mess,
  ].join(' ');
  final foundBanned = <String>[];
  for (final phrase in kKnownBadTokens) {
    if (textToCheck.toLowerCase().contains(phrase.toLowerCase())) {
      foundBanned.add(phrase);
    }
  }
  results.add(HealthCheckResult(
    name: 'Banned Tokens',
    passed: foundBanned.isEmpty,
    message: foundBanned.isEmpty
        ? 'No known bad tokens found.'
        : 'Found tokens: ${foundBanned.join(', ')}',
    severity: foundBanned.isEmpty ? HealthSeverity.pass : HealthSeverity.critical,
  ));

  // 5. Character cast sanity
  final cast = idea.defaultCast;
  final hasInvalidCast = cast.isEmpty || cast.any((c) => c.trim().isEmpty);
  results.add(HealthCheckResult(
    name: 'Character Cast',
    passed: !hasInvalidCast,
    message: hasInvalidCast
        ? 'Cast is empty or has blank entries.'
        : 'Cast: ${cast.join(", ")}.',
    severity: hasInvalidCast ? HealthSeverity.warning : HealthSeverity.pass,
  ));

  // 6. Safety hooks need review flag (checked via code comment in source)
  // This is a static check — safety hooks should have expert review before posting.
  final isSafetyHook = idea.id == 'idea_1' || idea.id == 'idea_2' ||
      idea.id == 'idea_3' || idea.id == 'idea_4' ||
      idea.id == 'idea_5' || idea.id == 'idea_6';
  results.add(HealthCheckResult(
    name: 'Safety Review',
    passed: !isSafetyHook || idea.archived,
    message: isSafetyHook
        ? 'Safety hook — mark for expert review before posting.'
        : 'Not a safety hook.',
    severity: (isSafetyHook && !idea.archived)
        ? HealthSeverity.critical
        : HealthSeverity.pass,
  ));

  return results;
}

/// Convenience: run health checks and return a [HookHealth] summary.
HookHealth runHookHealthCheck(HookIdea idea) {
  return HookHealth(idea, checkHookHealth(idea), DateTime.now());
}
