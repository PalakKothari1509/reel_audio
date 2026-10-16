// Hook and on-screen text generation system.
//
// Generates text overlays that are specific to the story being told,
// not generic templates. The hook system understands the difference
// between formats (video, image, carousel) and produces appropriate text.

import 'story_generator_offline.dart';

String generateHookText(
  GeneratedStory story, {
  required int partNumber,
  required int totalParts,
  String? characterName,
}) {
  if (partNumber == 1) {
    return _hookForFirstPart(story, characterName);
  }
  if (partNumber == totalParts) {
    return _hookForLastPart(story);
  }
  return _hookForMiddlePart(story, partNumber, totalParts);
}

String _hookForFirstPart(GeneratedStory story, String? characterName) {
  final hooks = [
    "${characterName ?? 'Ria'} ka ye reaction dekho! 😲",
    "${story.hook.split(' ').firstOrNull ?? 'Ek baat'} — kya hua? 😮",
    "Jab ${characterName ?? 'Ria'} ne kaha — '${story.hook}'",
    "POV: ${story.where} mein ye sab dekhkar... 🤭",
    "${story.hook.split(' ').take(2).join(' ')} — starting soon! 👀",
  ];
  return hooks[partNumberIndex()];
}

String _hookForMiddlePart(GeneratedStory story, int partNumber, int totalParts) {
  final hooks = [
    "Toh phir kya hua? 🤔",
    "Middle mein twist aane wala hai... ✨",
    "Abhi tak theek tha... par ab? 😬",
    "Rio aur Ria dono soch rahe the — '${story.problem}'",
    "Scene badal raha hai... 🎭",
  ];
  return hooks[partNumberIndex()];
}

String _hookForLastPart(GeneratedStory story) {
  final hooks = [
    "Finally! ${story.endingLine} ✨",
    "Mission accomplished! 👏",
    "Theek hai na Mama? ✅",
    "${story.moral} ❤️",
    "Perfect ending! 🌟",
  ];
  return hooks[partNumberIndex()];
}

String generateOnScreenText(
  GeneratedStory story, {
  required int partNumber,
  required int totalParts,
  TextPosition position = TextPosition.top,
}) {
  final lines = _textForPart(story, partNumber, totalParts);
  switch (position) {
    case TextPosition.top:
      return lines.isNotEmpty ? lines.first : '';
    case TextPosition.middle:
      return lines.length > 1 ? lines[1] : '';
    case TextPosition.bottom:
      return lines.length > 2 ? lines[2] : '';
  }
}

List<String> _textForPart(
    GeneratedStory story, int partNumber, int totalParts) {
  if (partNumber == 1) {
    return [
      "${story.hook.split(' ').take(3).join(' ')}! 🤔",
      "Scene: ${story.where}",
      'Part $partNumber of $totalParts',
    ];
  }
  if (partNumber == totalParts) {
    return [
      'The big resolution! ✨',
      story.moral,
      'Part $partNumber of $totalParts — Done!',
    ];
  }
  return [
    "What happens next? 👀",
    "Part $partNumber of $totalParts",
      '',
  ];
}

enum TextPosition { top, middle, bottom }

int partNumberIndex() {
  return DateTime.now().millisecond % 5;
}
