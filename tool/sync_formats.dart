// Regenerates lib/format_handbook.dart from content_formats.md.
//
//   dart run tool/sync_formats.dart
//
// content_formats.md is the source of truth for formats, the same way
// content_ideas.md is for ideas. This exists so the handbook is data you can edit,
// while prompt construction stays synchronous and every FormatSpec stays const.
//
// Two properties this buys, both of which matter:
//
//   1. A malformed line becomes a compile error, not a startup crash. A format whose
//      beats failed to parse would otherwise be discovered when a user generated a
//      Reel with an empty structure.
//   2. The prompt blocks are const. Prompt builders that read parsed runtime data
//      cannot be const, so every module that touches the handbook pays for it.
//
// Do not gitignore the generated file. The usual *.g.dart convention would mean a
// fresh clone fails to compile, and the app is built on a machine that will not run
// codegen before building.

import 'dart:io';

/// Reads content_formats.md and returns the raw Dart registry body.
String buildRegistry(String markdown) {
  final sections = parseFormatSections(markdown);
  if (sections.isEmpty) {
    throw FormatException('No format sections found in content_formats.md');
  }

  final buffer = StringBuffer();
  var index = 0;

  for (final s in sections) {
    index++;
    final id = require(s, 'ID');
    final name = require(s, 'Name');
    final definition = require(s, 'Definition');
    final structure = requireList(s, 'Structure');
    final bestFor = require(s, 'Best for');
    final contentTypes = requireEnumList(s, 'Best content types');
    final goals = requireEnumList(s, 'Best goals');
    final example = require(s, 'Example');
    final rules = requireList(s, 'Generation rules');

    // Optional. Only set on the format that is genuinely the answer when content
    // type and goal both tie, so it stays a tie-break and never a shortcut that
    // overrides a real score difference.
    final defaults = s['Default for'] == null
        ? const <String>[]
        : requireEnumList(s, 'Default for');

    // The Dart field name, derived from the id. Checked here rather than trusted,
    // because an id of "do this, not that" would silently emit an invalid identifier.
    final fieldName = dartIdentifierFor(id);

    buffer.writeln('  // -- ${pad2(index)} $name ${dashes(name.length + 7)}');
    buffer.writeln('  static const FormatSpec $fieldName = FormatSpec(');
    buffer.writeln("    id: '$id',");
    buffer.writeln("    name: '$name',");
    buffer.writeln('    definition:');
    buffer.writeln("        '${dartString(definition)}',");
    buffer.writeln('    structure: [');
    for (final beat in structure) {
      buffer.writeln("      '${dartString(beat)}',");
    }
    buffer.writeln('    ],');
    buffer.writeln('    bestFor:');
    buffer.writeln("        '${dartString(bestFor)}',");
    buffer.writeln('    bestContentTypes: [${contentTypes.map((t) => "'$t'").join(', ')}],');
    buffer.writeln('    bestGoals: [${goals.map((g) => "'$g'").join(', ')}],');
    if (defaults.isNotEmpty) {
      buffer.writeln(
          '    defaultFor: [${defaults.map((d) => "'$d'").join(', ')}],');
    }
    buffer.writeln('    example:');
    buffer.writeln("        '${dartString(example)}',");
    buffer.writeln('    generationRules: [');
    for (final r in rules) {
      buffer.writeln("      '${dartString(r)}',");
    }
    buffer.writeln('    ],');
    buffer.writeln('  );');
    buffer.writeln();
  }

  buffer.writeln('  static const List<FormatSpec> all = [');
  for (final s in sections) {
    buffer.writeln('    ${dartIdentifierFor(require(s, 'ID'))},');
  }
  buffer.writeln('  ];');

  return buffer.toString();
}

/// A parsed `##` section: the heading plus its field lines.
class FormatSection {
  final String heading;
  final Map<String, List<String>> fields = {};

  FormatSection(this.heading);

  List<String>? operator [](String key) => fields[key];
}

/// Splits the markdown into `##` sections and reads the canonical field names.
List<FormatSection> parseFormatSections(String markdown) {
  final sections = <FormatSection>[];
  FormatSection? current;
  var inFence = false;

  // Splits on the bullet marker too, so "- **ID**: `pov`" parses the same way as
  // "ID: pov". Both spellings appear in the file and accepting only one would make
  // the parser look broken for a formatting reason.
  final fieldLine = RegExp(r'^\s*-\s*\*\*(.+?)\*\*\s*:\s*(.*)$');
  final plainFieldLine = RegExp(r'^\s*([A-Za-z][A-Za-z ]*?)\s*:\s*(.*)$');

  // The field currently being read. Continuation lines belong to it. Held across
  // wrapped lines, which is why Structure and Generation rules survive intact.
  String? openField;

  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.replaceAll('\r', '').trimRight();

    // Code fences hold illustrative examples, not field values. A format entry has
    // no fenced content, but the document header does, and parsing one as a field
    // would produce garbage ids.
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    if (line.startsWith('## ')) {
      if (current != null) sections.add(current);
      current = FormatSection(line.substring(3).trim());
      openField = null;
      continue;
    }
    if (current == null) continue;

    if (line.trim().isEmpty) {
      openField = null;
      continue;
    }

    final match = fieldLine.firstMatch(line) ?? plainFieldLine.firstMatch(line);
    if (match != null && !line.startsWith(' ')) {
      final key = match.group(1)!.trim();
      final value = match.group(2)!.trim();
      openField = key;
      current.fields.putIfAbsent(key, () => <String>[]);
      if (value.isNotEmpty) {
        current.fields[key]!.add(value);
      }
      // Deliberately left open. A field written as "- **Definition**: One specific
      // problem, the reason it persists, the jugaad fix, the result." wraps onto the
      // next line indented under itself, and closing here truncated every wrapped
      // Definition and Best For to its first line. The next field bullet is
      // unindented, so it replaces this one correctly.
      continue;
    }

    // Distinguishes a new item from a wrapped line. `- Camera is the viewer's eyes`
    // starts an item; the unindented-looking wrap underneath it continues the same
    // one. Without this split, a rule wrapped across two markdown lines became two
    // rules, so the generated prompt asked for both halves independently.
    final itemStart = RegExp(r'^\s+(?:[-*]\s+|\d+[.)]\s+)(.+)$');
    final plainWrap = RegExp(r'^\s+(\S.*)$');

    final item = itemStart.firstMatch(line);
    if (item != null && openField != null) {
      current.fields[openField]!.add(stripLeadingLabel(item.group(1)!.trim()));
      continue;
    }

    final wrap = plainWrap.firstMatch(line);
    if (wrap != null && openField != null) {
      final list = current.fields[openField]!;
      if (list.isEmpty) {
        list.add(stripLeadingLabel(wrap.group(1)!.trim()));
      } else {
        list[list.length - 1] =
            '${list.last} ${stripLeadingLabel(wrap.group(1)!.trim())}';
      }
    }
  }
  if (current != null) sections.add(current);

  return sections.where((s) => s.fields.isNotEmpty).toList();
}

/// A field that must be present and hold exactly one line.
String require(FormatSection s, String key) {
  final values = s[key];
  if (values == null || values.isEmpty) {
    throw FormatException('${s.heading}: missing required field "$key"');
  }
  // Cleaned per line, never on the joined result. A field written across several
  // markdown lines ends with whatever the last line ends with, and a trailing lone
  // `*` from `*"Give her the job, not the order."* then paired with the leading `**`
  // of the next line's label, which stripped one asterisk from each end and produced
  // `*Idea**: ...`.
  final cleaned =
      values.map(cleanValue).map(stripLeadingLabel).join(' ');
  return cleaned;
}

/// A field that must be present and hold one or more lines.
List<String> requireList(FormatSection s, String key) {
  final values = s[key];
  if (values == null || values.isEmpty) {
    throw FormatException('${s.heading}: missing required field "$key"');
  }
  return values.map(cleanValue).toList();
}

/// Removes a leading `**Something**:` from a continuation line.
///
/// `content_formats.md` writes examples as:
///
/// ```
/// - **Example**: **Idea**: "Ria refuses to brush her teeth." Mumma counts...
/// ```
///
/// The inner label is for the human reader and carries no meaning for the data, so it
/// stayed in the generated string and would have reached a prompt.
String stripLeadingLabel(String value) =>
    value.replaceFirst(RegExp(r'^\*\*[^*]+\*\*\s*:\s*'), '').trim();

/// Strips the markdown inline decoration off a field value.
///
/// `content_formats.md` writes ids and quotes as `**ID**: \`pov\`` and rules as
/// `- Never open with "save this post".` Emitting those markers into Dart would put
/// backticks and asterisks inside generated strings, which then reach a prompt and
/// eventually a caption.
///
/// Only leading and trailing decoration is stripped. A single `*` pair is deliberately
/// **not** handled: emphasis markers are ambiguous against a trailing `*` on a wrapped
/// line, and stripping the wrong end corrupts the text. An unbalanced `*` left in is
/// harmless to a prompt; a silently half-stripped label is not.
String cleanValue(String value) {
  var v = value.trim();
  while (true) {
    final before = v;
    if (v.startsWith('`') && v.endsWith('`') && v.length > 1) {
      v = v.substring(1, v.length - 1).trim();
    } else if (v.startsWith('**') && v.endsWith('**') && v.length > 3) {
      v = v.substring(2, v.length - 2).trim();
    }
    if (v == before) break;
  }
  return v;
}

/// A field holding a comma-separated list of known ids.
///
/// Split here rather than expecting one id per line, because `Best content types` and
/// `Best goals` are written inline as `` `Reel`, `Trial Reel` ``. Parsing them as a
/// single value produced the id `"Reel`, `Trial Reel`", which then failed the axis
/// validation for all twelve formats — a formatting difference in the markdown
/// presented as a data error in every entry.
List<String> requireEnumList(FormatSection s, String key) {
  final raw = requireList(s, key);
  final out = <String>[];
  for (final line in raw) {
    for (final part in line.split(',')) {
      // Every backtick removed, not just a balanced pair. Splitting on the comma
      // inside `` `Reel`, `Trial Reel` `` leaves "Reel`" and "`Trial Reel", and
      // cleanValue only strips a *balanced* pair, so the dangling backticks survived
      // into every one of the twelve entries.
      final cleaned = canonicalAxisId(part.replaceAll('`', '').trim());
      if (cleaned.isNotEmpty) out.add(cleaned);
    }
  }
  if (out.isEmpty) {
    throw FormatException('${s.heading}: field "$key" has no values');
  }
  return out;
}

/// The display labels `content_formats.md` uses, mapped to the ids Dart uses.
///
/// The markdown is written for a human ("Image Slideshow Reel", "Non-follower Reach")
/// and the ids are camelCase, so translating here means a readable file and a stable
/// key can both be true. Doing it in the generator rather than requiring the author to
/// write ids is the point: an id is a machine detail and nobody edits one by hand.
const Map<String, String> kAxisLabelToId = {
  'reel': 'reel',
  'trial reel': 'trialReel',
  'carousel': 'carousel',
  'static image': 'staticImage',
  'image slideshow reel': 'imageSlideshowReel',
  'story': 'story',
  'reach': 'reach',
  'non-follower reach': 'nonFollowerReach',
  'non follower reach': 'nonFollowerReach',
  'saves': 'saves',
  'shares': 'shares',
  'comments': 'comments',
  'relatability': 'relatability',
  'authority': 'authority',
  'follows': 'follows',
};

/// Normalises one axis label to its id, passing through anything already an id.
///
/// An unrecognised label is returned unchanged rather than dropped, so
/// `validateAxes` reports it as unknown. Silently discarding it would produce a
/// format that quietly scores zero and looks like a data gap rather than a typo.
String canonicalAxisId(String label) =>
    kAxisLabelToId[label.toLowerCase()] ?? label;

/// A valid Dart identifier.
///
/// "doThisNotThat" stays as it is. "Do This, Not That" becomes `doThisNotThat`.
/// Numbers and punctuation are stripped rather than escaped, because an id like
/// "3-step" has no sensible identifier and failing loudly is better than emitting
/// `_3step` and wondering later where that came from.
String dartIdentifierFor(String id) {
  final cleaned = id.replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ').trim();
  if (cleaned.isEmpty) {
    throw FormatException('Format id "$id" contains nothing identifier-like');
  }
  final parts = cleaned
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toLowerCase() + p.substring(1))
      .toList();
  if (RegExp(r'[0-9]').hasMatch(parts.first[0])) {
    throw FormatException('Format id "$id" starts with a digit');
  }
  return parts.join();
}

/// Escapes a value for a single-quoted Dart string literal.
///
/// Apostrophes matter more than they look: the handbook is full of parent-facing
/// lines like `Don\'t open with "save this post"`, and an unescaped one is a syntax
/// error in generated code rather than a wrong caption.
String dartString(String value) => value
    .replaceAll('\\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll('\n', r'\n');

String pad2(int n) => n.toString().padLeft(2, '0');

String dashes(int n) => '-' * (68 - n);

void main() {
  final root = Directory.current;
  final source = File('${root.path}${Platform.pathSeparator}content_formats.md');

  if (!source.existsSync()) {
    stderr.writeln('content_formats.md not found at ${source.path}');
    stderr.writeln('Run this from the project root: dart run tool/sync_formats.dart');
    exitCode = 1;
    return;
  }

  final markdown = source.readAsStringSync();
  String registry;
  try {
    registry = buildRegistry(markdown);
  } on FormatException catch (e) {
    stderr.writeln('Failed to parse content_formats.md: ${e.message}');
    exitCode = 1;
    return;
  }

  final sections = parseFormatSections(markdown);
  stdout.writeln('Parsed ${sections.length} formats.');
  for (final s in sections) {
    stdout.writeln('  ${require(s, 'ID')}  (${require(s, 'Name')})');
  }

  final target = File('${root.path}${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}format_handbook.dart');
  final existing = target.existsSync() ? target.readAsStringSync() : '';

  final marker = '  // -- 01 ';
  final start = registry.indexOf(marker);
  if (start < 0) {
    stderr.writeln('Generated registry has no section marker. Nothing written.');
    exitCode = 1;
    return;
  }

  // Everything from the first format to the end of the `all` list is generated.
  // The header, the FormatSpec class and the helpers below it are hand-written and
  // preserved, because they carry the reasoning that does not belong in data.
  final generated = registry.substring(start);
  final tailMarker = '  ];';
  final tailStart = generated.indexOf(tailMarker, start);
  if (tailStart < 0) {
    stderr.writeln('Generated registry has no "all" terminator. Nothing written.');
    exitCode = 1;
    return;
  }
  final generatedBlock = generated.substring(0, tailStart + tailMarker.length);

  final existingStart = existing.indexOf(marker);
  final existingTail = existing.indexOf(tailMarker, existingStart);
  if (existingStart < 0 || existingTail < 0) {
    stderr.writeln('lib/format_handbook.dart does not look generated.');
    stderr.writeln('Nothing written. Restore the section markers first.');
    exitCode = 1;
    return;
  }

  final merged = existing.substring(0, existingStart) +
      generatedBlock +
      existing.substring(existingTail + tailMarker.length);

  target.writeAsStringSync(merged);
  stdout.writeln('');
  stdout.writeln('Wrote ${target.path}');
  stdout.writeln('Run: flutter analyze lib  and  flutter test');
}