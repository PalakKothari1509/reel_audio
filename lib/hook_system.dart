// Overlay text for generated video prompts.
//
// The video model must NOT draw text: it garbles Hinglish and the result
// cannot be edited. Captions and the end card are drawn by the app
// (caption_renderer.dart). This file only decides what that overlay says.

import 'master_prompt.dart';
import 'story_generator_offline.dart';

/// Longest overlay, in words. Longer stops being a hook.
const int kMaxOverlayWords = 5;

enum OverlayPosition { top, middle, bottom }

int overlayWordCount(String s) {
  final t = s.trim();
  return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
}

final RegExp _pictographs =
    RegExp(r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{FE0F}]', unicode: true);

String _plain(String s) => s.replaceAll(_pictographs, '').trim();

/// The hook overlay: part 1 only, taken from the short cover title.
/// Returns '' when there is nothing safe to show. Deterministic.
String generateHookText(
  GeneratedStory story, {
  required int partNumber,
  required int totalParts,
  String? characterName,
}) {
  if (partNumber != 1) return '';
  final cover = _plain(story.title);
  if (cover.isEmpty || overlayWordCount(cover) > kMaxOverlayWords) return '';
  return cover;
}

/// Returns the on-screen text for a given position.
/// Only top is populated (part 1 cover); middle and bottom are always empty.
String generateOnScreenText(
  GeneratedStory story, {
  required int partNumber,
  required int totalParts,
  OverlayPosition position = OverlayPosition.top,
}) {
  if (position != OverlayPosition.top) return '';
  return generateHookText(story,
      partNumber: partNumber, totalParts: totalParts);
}

/// The line for the "ON-SCREEN TEXT OVERLAYS" section of every video prompt.
String overlayInstruction(String overlay) => overlay.isEmpty
    ? 'None. No text of any kind appears in the frame.'
    : 'Do NOT draw this in the video. The editor adds it later: "$overlay"';

/// Reasons an overlay is unsafe to use. Empty list means fine.
List<String> overlayProblems(String overlay, GeneratedStory story) {
  final problems = <String>[];
  final low = overlay.toLowerCase();
  if (overlayWordCount(overlay) > kMaxOverlayWords) {
    problems.add('longer than $kMaxOverlayWords words');
  }
  final moral = story.moral.trim().toLowerCase();
  if (moral.isNotEmpty && low.contains(moral)) {
    problems.add('contains the moral');
  }
  for (final p in kBannedOverlayPhrases) {
    if (low.contains(p.toLowerCase())) problems.add('contains "$p"');
  }
  return problems;
}
