import 'dart:math';

import 'characters.dart';
import 'content_ideas.dart';
import 'hook_system.dart';
import 'master_prompt.dart';
import 'story_generator_offline.dart';

class VideoPartPrompt {
  final int partNumber;
  final int totalParts;
  final String promptText;
  final String purpose;
  final String fullPrompt;

  VideoPartPrompt({
    required this.partNumber,
    required this.totalParts,
    required this.promptText,
    required this.purpose,
    required this.fullPrompt,
  });

  String get title => 'Part $partNumber of $totalParts';
}

class GeminiVideoResult {
  final String storyTitle;
  final String storyFoundation;
  final List<VideoPartPrompt> parts;

  GeminiVideoResult({
    required this.storyTitle,
    required this.storyFoundation,
    required this.parts,
  });
}

class OfflineVideoPromptGenerator {
  final Random _rng = Random();

  static const List<String> _shotTypes = [
    'wide shot',
    'medium shot',
    'close-up',
    'over-the-shoulder shot',
    'low-angle shot',
    'high-angle shot',
  ];

  GeminiVideoResult generateFromStory(
    GeneratedStory story, {
    required int totalSeconds,
    required List<String> characters,
  }) {
    final partsCount = (totalSeconds / 10).round().clamp(2, 6);
    final charBlock = _buildCharacterBlock(characters);
    final storyTitle = story.title;
    final storyFoundation = _buildFoundation(story, characters);

    final parts = <VideoPartPrompt>[];
    String previousEndingState = 'opening scene';

    final beats = _buildStoryBeats(story, partsCount);

    for (int i = 0; i < partsCount; i++) {
      final partNumber = i + 1;
      final beat = beats[i];
      final isLast = i == partsCount - 1;

      final purpose = isLast
          ? 'Ending: Resolve the conflict with a warm moment and clear takeaway'
          : 'Hook: Show the situation that every parent recognises';

      final setting = _buildSetting(partNumber);
      final startingState = i == 0
          ? 'Main characters in the center of the room, neutral expressions, ready to begin'
          : previousEndingState;

      final action04 = _buildActionForBeat(story, beat, 1);
      final action48 = _buildActionForBeat(story, beat, 2);
      final action810 = isLast
          ? _buildEndingActionFromBeat(beat, story, characters)
          : _buildActionForBeat(story, beat, 3);

      final dialogue = _buildDialogue(story, partNumber, partsCount, beat);
      final endingState = _buildEndingState(beat, characters);
      final textHook = generateHookText(story,
          partNumber: partNumber, totalParts: partsCount);
      final continuityFrom = i == 0
          ? 'Opening scene'
          : 'Direct cut from Part $i, characters and setting in same positions as ending state';
      final continuityInto = isLast
          ? 'Scene settles into closing card with lesson visible'
          : 'Characters and setting hand off seamlessly to Part ${partNumber + 1}';

      final fullPrompt = _buildFullPrompt(
        storyTitle,
        storyFoundation,
        textHook,
        partNumber,
        partsCount,
        purpose,
        charBlock,
        setting,
        startingState,
        action04,
        action48,
        action810,
        dialogue,
        continuityFrom,
        continuityInto,
        null,
      );

      assert(
        !_containsForbiddenSubstring(fullPrompt),
        'Generated prompt contains forbidden placeholder text for part $partNumber',
      );

      previousEndingState = endingState;

      parts.add(VideoPartPrompt(
        partNumber: partNumber,
        totalParts: partsCount,
        promptText: fullPrompt,
        purpose: purpose,
        fullPrompt: fullPrompt,
      ));
    }

    return GeminiVideoResult(
      storyTitle: storyTitle,
      storyFoundation: storyFoundation,
      parts: parts,
    );
  }

  List<String> _buildStoryBeats(GeneratedStory story, int partsCount) {
    final hasMoments = story.setting.trim().isNotEmpty ||
        story.sceneDetail.trim().isNotEmpty ||
        story.dialogue.trim().isNotEmpty ||
        story.mess.trim().isNotEmpty ||
        story.innerThought.trim().isNotEmpty;

    if (!hasMoments) {
      if (partsCount <= 2) {
        return ['problem', 'solution'];
      } else if (partsCount == 3) {
        return ['problem', 'twist', 'solution'];
      }
      return ['problem', 'twist', 'worse', 'solution', 'solution', 'solution']
          .sublist(0, partsCount);
    }

    if (partsCount <= 2) {
      return ['sceneDetail', 'endingBeat'];
    } else if (partsCount == 3) {
      return ['sceneDetail', 'dialogue', 'endingBeat'];
    } else if (partsCount == 4) {
      return ['sceneDetail', 'dialogue', 'mess', 'endingBeat'];
    }
    return ['sceneDetail', 'dialogue', 'mess', 'innerThought', 'endingBeat']
        .sublist(0, partsCount);
  }

  String _buildCharacterBlock(List<String> characters) {
    final buffer = StringBuffer();
    for (final name in characters) {
      final desc = characterDescription(name);
      buffer.writeln('- $name: $desc');
    }
    return buffer.toString().trim();
  }

  String _buildFoundation(GeneratedStory story, List<String> characters) {
    final who = characters.join(' and ');
    var chars = who;
    if (characters.length == 1) chars = characters.first;
    if (characters.length > 2) {
      chars =
          '${characters.sublist(0, characters.length - 1).join(', ')} and ${characters.last}';
    }

    return '$chars go through a small everyday moment that every parent '
        'recognises. The story starts mid-action, builds gently, and ends '
        'with a warm lesson that parents can relate to.\n\n'
        'Story: ${story.problem}\n'
        'Twist: ${story.twist}\n'
        'Resolution: ${story.solution}\n'
        'Lesson: ${story.moral}';
  }

  String _buildSetting(int partNumber) {
    final settings = [
      'Indian home interior, warm morning light, soft textures, cream background',
      'Living room corner with toys scattered, afternoon sunlight through window',
      'Kitchen counter area, morning light, family items within reach',
      'Bedroom doorway, soft evening glow, toys on the floor',
      'Dining area, golden hour light, family chairs around table',
    ];
    return settings[(partNumber - 1) % settings.length];
  }

  String _buildActionForBeat(GeneratedStory story, String beat, int segment) {
    switch (beat) {
      case 'sceneDetail':
        switch (segment) {
          case 1:
            return story.sceneDetail.trim().isNotEmpty
                ? story.sceneDetail
                : 'The scene is set, characters in neutral positions';
          case 2:
            return story.setting.trim().isNotEmpty
                ? '${story.setting} — the atmosphere is intimate'
                : 'Camera captures the domestic detail';
          case 3:
            return 'Scene detail is established, tension builds naturally';
        }
        break;
      case 'dialogue':
        switch (segment) {
          case 1:
            return story.dialogue.trim().isNotEmpty
                ? story.dialogue
                : 'A child speaks, the moment begins';
          case 2:
            return 'Characters respond to each other, dialogue flows';
          case 3:
            return 'Dialogue reveals the underlying tension';
        }
        break;
      case 'mess':
        switch (segment) {
          case 1:
            return story.mess.trim().isNotEmpty
                ? story.mess
                : 'The situation gets more complicated';
          case 2:
            return 'Both characters are involved, each reacts differently';
          case 3:
            return 'Tension builds through actions, not dialogue';
        }
        break;
      case 'innerThought':
        switch (segment) {
          case 1:
            return story.innerThought.trim().isNotEmpty
                ? story.innerThought
                : 'A parent thinks quietly';
          case 2:
            return 'The inner thought shows a shift in perspective';
          case 3:
            return 'Realization begins to take hold';
        }
        break;
    }
    return 'Scene develops naturally with clear action and emotion';
  }

  String _buildEndingActionFromBeat(String beat, GeneratedStory story,
      List<String> characters) {
    if (story.endingBeat.trim().isNotEmpty) {
      return story.endingBeat;
    }
    final char1 = characters.isNotEmpty ? characters[0] : 'Ria';
    final char2 = characters.length > 1 ? characters[1] : 'Rio';
    return '$char1 and $char2 resolve the situation with a warm '
        'moment, scene settling toward the closing card with lesson visible';
  }

  String _buildDialogue(GeneratedStory story, int partNumber, int totalParts,
      String beat) {
    if (story.dialogue.trim().isNotEmpty && beat == 'dialogue') {
      return story.dialogue;
    }
    if (partNumber == 1) {
      if (story.setting.trim().isNotEmpty) {
        return story.setting;
      }
      final firstWord = story.problem.split(' ').where((w) => w.length > 3);
      final subject = firstWord.isNotEmpty ? firstWord.first : 'something';
      return 'Ria: "$subject dekho yeh kya hua!"\n'
          'Rio: "Abhi thoda wait karo!"';
    }
    if (partNumber == totalParts) {
      if (story.endingBeat.trim().isNotEmpty) {
        return story.endingBeat;
      }
      return 'Ria: "${story.endingLine}"\n'
          'Rio: "Theek hai na Mama?"';
    }
    return 'Ria: "Rio, dekho yeh kya hua!"\n'
        'Rio: "Abhi nahi, thoda wait karo!"';
  }

  String _buildEndingState(String beat, List<String> characters) {
    final char1 = characters.isNotEmpty ? characters[0] : 'Ria';
    final char2 = characters.length > 1 ? characters[1] : 'Rio';
    final char3 = characters.length > 2 ? characters[2] : 'Cuty';
    return '$char1 and $char2 together, $char3 nearby, '
        'expressions warm and resolved, scene settling';
  }

  String _buildFullPrompt(
    String title,
    String foundation,
    String textHook,
    int partNumber,
    int totalParts,
    String purpose,
    String charBlock,
    String setting,
    String startingState,
    String action04,
    String action48,
    String action810,
    String dialogue,
    String continuityFrom,
    String continuityInto,
    String? additionalInstructions,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('TITLE: $title');
    buffer.writeln('PART $partNumber of $totalParts');
    buffer.writeln('DURATION: exactly 10 seconds');
    buffer.writeln('FORMAT: vertical 9:16');
    buffer.writeln();
    buffer.writeln('STORY CONTEXT: $foundation');
    buffer.writeln();
    buffer.writeln('TEXT HOOK OVERLAY: $textHook');
    buffer.writeln();
    buffer.writeln('THIS PART\'S PURPOSE: $purpose');
    buffer.writeln();
    buffer.writeln('CHARACTER LOCK:');
    buffer.writeln(charBlock);
    buffer.writeln();
    buffer.writeln('STORY STRUCTURE RULES:');
    buffer.writeln('- Ria and Rio NEVER wear glasses.');
    buffer.writeln('- Cuty is ALWAYS a small white bunny with a pink bow.');
    buffer.writeln('- Use the exact descriptions above for every part.');
    buffer.writeln('- No duplicate characters, no identity changes.');
    buffer.writeln();
    buffer.writeln('SCENE AND SETTING: $setting');
    buffer.writeln();
    buffer.writeln('STARTING STATE: $startingState');
    buffer.writeln();
    buffer.writeln('CAMERA: ${_shotTypes[_rng.nextInt(_shotTypes.length)]} '
        'opening, smooth movement, ${_shotTypes[_rng.nextInt(_shotTypes.length)]} ending');
    buffer.writeln();
    buffer.writeln('ACTION TIMELINE:');
    buffer.writeln('0-4s: $action04');
    buffer.writeln('4-8s: $action48');
    buffer.writeln('8-10s: $action810');
    buffer.writeln();
    buffer.writeln('DIALOGUE AND AUDIO: $dialogue');
    buffer.writeln();
    buffer.writeln('CONTINUITY FROM PREVIOUS PART: $continuityFrom');
    buffer.writeln();
    buffer.writeln('CONTINUITY INTO NEXT PART: $continuityInto');
    buffer.writeln();
    buffer.writeln('VISUAL STYLE: $kVisualStyle');
    buffer.writeln();
    buffer.writeln('NEGATIVE INSTRUCTIONS: $kNegativeInstructions');
    if (additionalInstructions != null &&
        additionalInstructions.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('ADDITIONAL INSTRUCTIONS: $additionalInstructions');
    }

    return buffer.toString();
  }

  static GeneratedStory generateStoryFromHook(HookIdea hook,
      {required List<String> characters}) {
    return GeneratedStory(
      title: hook.cover,
      hook: hook.cover,
      who: characters.join(', '),
      where: 'at home',
      problem: hook.problem,
      twist: 'But then something unexpected happened.',
      worse: 'It seemed like nothing could fix it.',
      solution: hook.lesson,
      endingLine: 'Now everyone knows what to do!',
      moral: hook.lesson,
      hookOptions: [],
    );
  }

  static bool _containsForbiddenSubstring(String text) {
    final forbidden = [
      'filler',
      'placeholder',
      'lorem ipsum',
      'TBD',
      'TODO',
      'generating',
      'randomly selected',
      '\u2026',
    ];
    final lower = text.toLowerCase();
    return forbidden.any((f) => lower.contains(f.toLowerCase()));
  }
}
