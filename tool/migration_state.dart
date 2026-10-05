import 'dart:io';

/// Migration vocabulary, shared by the format and pillar decision files.
///
/// ── These are NOT IdeaStatus values ──────────────────────────────────────────
///
/// Migration state describes a *classification decision in progress*. `IdeaStatus`
/// describes *where an idea is in production*. They share the word `approved` and
/// mean different things by it:
///
///   MigrationState.approved  Palak approved this classification
///   IdeaStatus.approved      this idea was approved for production
///
/// Collapsing them would let a machine guess write the word "approved" onto an idea,
/// which is the exact confusion this file exists to prevent. A classifier's opinion and
/// an editor's sign-off are different facts and are stored differently.

enum MigrationState {
  /// A human approved this classification. Safe to write.
  approved,

  /// A human proposed it; not yet signed off. Do not write.
  suggested,

  /// Deliberately undecided, pending evidence that does not exist yet.
  needsReview,

  /// No correct value derivable from the source material.
  invalid,

  /// The idea does not serve the core value proposition and should not be classified.
  ///
  /// Not writable, and deliberately not forced into an axis value. An idea that
  /// surveys the audience about the account rather than giving a parent something to
  /// save or send has no pillar, and inventing one to make the schema complete
  /// contaminates the dataset with a record nobody will use.
  archiveCandidate;

  /// Only an explicit human approval is ever written.
  bool get isWritable => this == MigrationState.approved;

  /// Accepts camelCase and snake_case, because `archive_candidate` and
  /// `archiveCandidate` are both natural to type and a silent mismatch would
  /// downgrade an approved decision to a missing one.
  static MigrationState? parse(String raw) {
    final flat = raw.trim().replaceAll('_', '').toLowerCase();
    for (final s in MigrationState.values) {
      if (s.name.toLowerCase() == flat) return s;
    }
    return null;
  }

  static List<String> get names => values.map((s) => s.name).toList();
}

/// One decided value for one idea on one axis.
class Decision {
  final String ideaId;
  final MigrationState state;

  /// The axis value. Empty when the state carries no value, which is required for
  /// `archiveCandidate`, `needsReview` and `invalid`.
  final String value;

  /// Free text: why, or what is still missing.
  final String note;

  /// Where the evidence came from. `beat_only` marks a decision resting on a beat
  /// description because the idea has no Topic, Lesson or Problem field, which is
  /// materially weaker evidence and should stay visible.
  final String evidence;

  Decision(this.ideaId, this.state, this.value, this.note, this.evidence);

  bool get isWritable => state.isWritable && value.isNotEmpty;
}

/// Reads a decisions CSV, failing loudly on anything malformed.
///
/// A malformed row is never skipped. A skipped row turns an approved decision into a
/// missing one, and the migration then quietly omits it — which is the failure mode
/// this whole toolchain exists to prevent.
Map<String, Decision> readDecisions(String path, {required bool requireEvidence}) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final out = <String, Decision>{};
  final lines = file.readAsLinesSync();

  for (var i = 1; i < lines.length; i++) {
    final l = lines[i];
    if (l.trim().isEmpty) continue;
    if (l.trimLeft().startsWith('#')) continue;

    // Header is idea_id,state,<axis>,note[,evidence]
    final m = RegExp(r'^([^,]+),([^,]+),([^,]*),(.*)$').firstMatch(l);
    if (m == null) {
      stderr.writeln('$path line ${i + 1}: cannot parse.');
      exitCode = 1;
      return {};
    }

    final id = m.group(1)!.trim();
    final state = MigrationState.parse(m.group(2)!);
    if (state == null) {
      stderr.writeln('$path line ${i + 1}: unknown state "${m.group(2)}". '
          'Expected one of ${MigrationState.names.join(', ')}.');
      exitCode = 1;
      return {};
    }

    var value = m.group(3)!.trim();
    var rest = m.group(4)!;
    var evidence = '';

    if (requireEvidence) {
      // The evidence field is last and quoted, so split on the final quoted pair.
      final e = RegExp(r',(?:"(.*)"|([^,]*))\s*$').firstMatch(rest);
      if (e != null) {
        evidence = (e.group(1) ?? e.group(2) ?? '').trim();
        rest = rest.substring(0, e.start);
      }
    }

    if (state.isWritable && value.isEmpty) {
      stderr.writeln('$path line ${i + 1}: state is approved but no value given.');
      exitCode = 1;
      return {};
    }
    if (!state.isWritable && value.isNotEmpty && state != MigrationState.suggested) {
      // suggested carries a value on purpose: it is a proposal not yet approved.
      stderr.writeln('$path line ${i + 1}: state ${state.name} must not carry a '
          'value, found "$value".');
      exitCode = 1;
      return {};
    }

    out[id] = Decision(id, state, value, rest.trim(), evidence);
  }
  return out;
}