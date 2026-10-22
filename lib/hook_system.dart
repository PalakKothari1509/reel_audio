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
  if (story.dialogue.trim().isNotEmpty) {
    final words = story.dialogue.split(' ').take(5).join(' ');
    return '$words!';
  }
  if (story.mess.trim().isNotEmpty) {
    final words = story.mess.split(' ').take(5).join(' ');
    return '$words!';
  }
  if (story.hook.trim().isNotEmpty) {
    final words = story.hook.split(' ').take(5).join(' ');
    return '$words!';
  }
  final hooks = [
    "${characterName ?? 'Ria'} ka ye reaction dekho! 😲",
    "${story.hook.split(' ').firstOrNull ?? 'Ek baat'} — kya hua? 😮",
    "Jab ${characterName ?? 'Ria'} ne kaha — '${story.hook}'",
    "POV: ${story.where} mein ye sab dekhkar... 🤭",
    "${story.hook.split(' ').take(2).join(' ')} — starting soon! 👀",
  ];
  return _capOverlay(hooks[partNumberIndex()]);
}

String _hookForMiddlePart(GeneratedStory story, int partNumber, int totalParts) {
  if (story.mess.trim().isNotEmpty) {
    final words = story.mess.split(' ').take(5).join(' ');
    return '$words...';
  }
  if (story.sceneDetail.trim().isNotEmpty) {
    final words = story.sceneDetail.split(' ').take(5).join(' ');
    return '$words!';
  }
  final hooks = [
    "Toh phir kya hua? 🤔",
    "Middle mein twist aane wala hai... ✨",
    "Abhi tak theek tha... par ab? 😬",
    "Rio aur Ria dono soch rahe the — '${story.problem}'",
    "Scene badal raha hai... 🎭",
  ];
  return _capOverlay(hooks[partNumberIndex()]);
}

String _hookForLastPart(GeneratedStory story) {
  if (story.endingBeat.trim().isNotEmpty) {
    final words = story.endingBeat.split(' ').take(5).join(' ');
    return '$words ✨';
  }
  if (!story.moralHidden && story.moral.trim().isNotEmpty) {
    final words = story.moral.split(' ').take(5).join(' ');
    return '$words ❤️';
  }
  final hooks = [
    "Finally! ${story.endingLine} ✨",
    "Mission accomplished! 👏",
    "Theek hai na Mama? ✅",
    "${story.moral} ❤️",
    "Perfect ending! 🌟",
  ];
  return _capOverlay(hooks[partNumberIndex()]);
}

String _capOverlay(String text) {
  final words = text.split(' ');
  if (words.length <= 5) return text;
  return words.take(5).join(' ');
}

bool _isForbiddenSubstring(String text) {
  final forbidden = [
    'filler',
    'placeholder',
    'lorem ipsum',
    'TBD',
    'TODO',
    'generating',
    'randomly selected',
  ];
  final lower = text.toLowerCase();
  return forbidden.any((f) => lower.contains(f.toLowerCase()));
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
    final top = _isForbiddenSubstring(story.dialogue)
        ? _capOverlay(story.hook.split(' ').take(5).join(' '))
        : _capOverlay(story.dialogue.isNotEmpty ? story.dialogue : story.sceneDetail);
    return [
      top.isNotEmpty ? '$top!' : '${story.hook.split(' ').take(3).join(' ')}! 🤔',
      story.setting.isNotEmpty ? _capOverlay(story.setting) : 'Scene: ${story.where}',
      'Part $partNumber of $totalParts',
    ];
  }
  if (partNumber == totalParts) {
    final ending = _isForbiddenSubstring(story.endingBeat)
        ? 'The big resolution! ✨'
        : _capOverlay(story.endingBeat);
    return [
      ending.isNotEmpty ? ending : 'The big resolution! ✨',
      story.moralHidden ? '' : story.moral,
      'Part $partNumber of $totalParts — Done!',
    ];
  }
  return [
    _capOverlay(story.mess.isNotEmpty ? story.mess : 'What happens next? 👀'),
    'Part $partNumber of $totalParts',
    '',
  ];
}

enum TextPosition { top, middle, bottom }

int partNumberIndex() {
  return DateTime.now().millisecond % 5;
}
