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
    final charBlock = _buildCharacterBlock(characters, story.cast);
    final storyTitle = story.title;
    final storyFoundation = _buildFoundation(story, characters);

    final parts = <VideoPartPrompt>[];
    String previousEndingState = 'still in the middle of it';

    final beats = _buildStoryBeats(story, partsCount);

    for (int i = 0; i < partsCount; i++) {
      final partNumber = i + 1;
      final beat = beats[i];
      final isLast = i == partsCount - 1;

      final purpose = isLast
          ? 'Closing image only. Hold the frame. No lesson, no summary, no card text.'
          : (i == 0
              ? 'The moment itself, mid-action. No setup, no "one day", no context.'
              : 'Escalation — the situation gets worse and stays worse.');

      final setting = _buildSetting(story, partNumber);

      final startingState = i == 0
          ? 'Action already in progress as the shot opens, nobody posed, '
              'characters caught mid-movement'
          : previousEndingState;

      final action04 = _buildActionForBeat(story, beat, 1, isLast, characters);
      final action48 = _buildActionForBeat(story, beat, 2, isLast, characters);
      final action810 = isLast
          ? _buildEndingAction(story, characters)
          : _buildActionForBeat(story, beat, 3, isLast, characters);

      final dialogue = _buildDialogue(story, partNumber, partsCount, beat, characters);
      final endingState = _buildEndingState(story, isLast, characters);
      final continuityFrom = i == 0
          ? 'Opening scene'
          : 'Direct cut from Part $i, characters and setting in same positions as ending state';
      final continuityInto = isLast
          ? 'Hold on the closing image for the final beat. No card, no text, no lesson.'
          : 'Characters and setting hand off seamlessly to Part ${partNumber + 1}';

      final fullPrompt = _buildFullPrompt(
        story,
        storyTitle,
        storyFoundation,
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
        _buildSpecificNote(story, partNumber, isLast),
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
    if (partsCount <= 2) return ['problem', 'solution'];
    if (partsCount == 3) return ['problem', 'worse', 'solution'];
    if (partsCount == 4) return ['problem', 'twist', 'worse', 'solution'];
    return ['problem', 'twist', 'worse', 'worse', 'solution', 'solution'];
  }

  String _buildSpecificNote(GeneratedStory story, int partNumber, bool isLast) {
    final lines = <String>[];
    if (story.setting.trim().isNotEmpty) {
      lines.add('This happens here, not in a generic room: ${story.setting}');
    }
    if (story.sceneDetail.trim().isNotEmpty) {
      lines.add('Keep this visible throughout: ${story.sceneDetail}');
    }
    if (partNumber == 1 && story.dialogue.trim().isNotEmpty) {
      lines.add('The only spoken line in this part is: ${story.dialogue}');
    }
    if (story.innerThought.trim().isNotEmpty && !isLast) {
      lines.add('Parent voiceover, one line, not lip-synced: '
          '"${story.innerThought}" (leave a 1.5s gap in the mix for it)');
    }
    if (isLast && story.endingBeat.trim().isNotEmpty) {
      lines.add('End on exactly this image and hold it: ${story.endingBeat}');
    }
    if (isLast) {
      lines.add('Do NOT add a closing card, quote, moral or on-screen lesson text.');
    }
    return lines.isEmpty ? '' : '- ${lines.join('\n- ')}';
  }

  String _buildCharacterBlock(List<String> characters, List<String> castForStory) {
    final buffer = StringBuffer();
    for (final name in characters) {
      final desc = characterDescription(name);
      final voice = characterVoice(name);
      buffer.writeln('- $name: $desc');
      if (voice.isNotEmpty) {
        buffer.writeln('  Voice: $voice');
      }
    }
    return buffer.toString().trim();
  }

  String _buildFoundation(GeneratedStory story, List<String> characters) {
    var chars = characters.join(' and ');
    if (characters.length == 1) chars = characters.first;
    if (characters.length > 2) {
      chars =
          '${characters.sublist(0, characters.length - 1).join(', ')} and ${characters.last}';
    }

    final buffer = StringBuffer()
      ..write('$chars go through one small everyday moment. The story starts '
          'mid-action and does not tidy itself up by the end.\n\n')
      ..write('Story: ${story.problem}\n')
      ..write('Twist: ${story.twist}\n')
      ..write('What goes wrong: ${story.mess.trim().isNotEmpty ? story.mess : story.worse}\n');
    if (story.endingBeat.trim().isNotEmpty) {
      buffer.write('Closing image: ${story.endingBeat}\n');
    }
    if (!story.moralHidden && story.moral.trim().isNotEmpty) {
      buffer.write('Lesson (final end card only): ${story.moral}');
    }
    return buffer.toString();
  }

  String _buildSetting(GeneratedStory story, int partNumber) {
    if (story.setting.trim().isNotEmpty) {
      final detail = story.sceneDetail.trim().isNotEmpty
          ? ' Keep this visible throughout: ${story.sceneDetail}'
          : '';
      return '${story.setting}.$detail';
    }
    return 'Indian home interior, warm natural light, soft textures';
  }

  String _buildActionForBeat(GeneratedStory story, String beat, int segment,
      bool isLast, List<String> characters) {
    final a = characters.isNotEmpty ? characters.first : 'Ria';
    final b = characters.length > 1 ? characters[1] : a;

    switch (beat) {
      case 'problem':
        switch (segment) {
          case 1:
            return '$a begins mid-action, already in it: ${story.problem}';
          case 2:
            return '$b reacts physically. Nothing is said here.';
          case 3:
            return 'The situation escalates on its own. Still unresolved.';
        }
        break;
      case 'twist':
        switch (segment) {
          case 1:
            return 'The obvious solution appears — $b brings it.';
          case 2:
            return '$a tries it. It does not work as expected.';
          case 3:
            return 'The attempt leaves them worse off than before they tried.';
        }
        break;
      case 'worse':
        switch (segment) {
          case 1:
            return 'Another attempt. It also fails.';
          case 2:
            final mess = story.mess.trim().isNotEmpty ? story.mess : story.worse;
            return 'The situation gets worse and stays worse: $mess';
          case 3:
            return 'Tension builds through action, not dialogue. Nothing is fixed.';
        }
        break;
      case 'solution':
        switch (segment) {
          case 1:
            return isLast
                ? '$a and $b do the one small thing that works — shown, not explained.'
                : '$a tries one small thing. It is not enough yet.';
          case 2:
            return isLast
                ? 'Both of them end up in the same frame, physically close, quiet.'
                : '$b copies $a. It half-works, then slips again.';
          case 3:
            return isLast
                ? 'Hold the final image. No new action, no realisation, no reaction shot.'
                : 'Something small goes wrong again. No lesson attached.';
        }
        break;
    }
    return 'Scene continues with real physical action, no narration.';
  }

  String _buildEndingAction(GeneratedStory story, List<String> characters) {
    final beat = story.endingBeat.trim().isNotEmpty
        ? story.endingBeat.trim()
        : (story.solution.trim().isNotEmpty ? story.solution.trim() : 'the room as it now is');
    return 'End on exactly this image and hold it for the final beat: $beat. '
        'Nobody explains it. Nobody looks at camera. No on-screen text.';
  }

  String _buildDialogue(GeneratedStory story, int partNumber, int totalParts,
      String beat, List<String> characters) {
    final a = characters.isNotEmpty ? characters.first : 'Ria';

    if (partNumber == 1 && story.dialogue.trim().isNotEmpty) {
      final speaker = _speakerFor(story.dialogue, characters);
      return '$speaker: "${story.dialogue.trim()}"';
    }
    if (partNumber == totalParts) {
      return 'No dialogue. Ambient room sound only.';
    }
    if (partNumber == 1) {
      return '$a: "${_voiceHint(a)}"';
    }
    return '';
  }

  String _speakerFor(String line, List<String> characters) {
    for (final c in characters) {
      if (line.toLowerCase().contains(c.toLowerCase())) return c;
    }
    return characters.isNotEmpty ? characters.first : 'Ria';
  }

  String _voiceHint(String name) {
    final v = characterVoice(name);
    if (v.isEmpty) return 'Abhi nahi.';
    final m = RegExp(r'Example:\s*"([^"]+)"').firstMatch(v);
    return m?.group(1) ?? 'Abhi nahi.';
  }

  String _buildEndingState(
      GeneratedStory story, bool isLast, List<String> characters) {
    final names = characters.isEmpty ? <String>['Ria'] : characters;
    final joined = names.length == 1
        ? names.first
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';

    if (isLast) {
      final frame = story.endingBeat.trim().isNotEmpty
          ? story.endingBeat.trim()
          : 'the room as it now is';
      return 'Camera holds on $frame, $joined in frame, nobody posed';
    }
    return '$joined still in the middle of it, expressions unresolved, same room as before';
  }

   String _buildFullPrompt(
    GeneratedStory story,
    String title,
    String foundation,
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
    final overlay = generateOnScreenText(story,
        partNumber: partNumber, totalParts: totalParts);
    final problems = overlayProblems(overlay, story);
    assert(problems.isEmpty,
        'Overlay problems for part $partNumber: ${problems.join(', ')}');

    final buffer = StringBuffer();
    buffer.writeln('TITLE: $title');
    buffer.writeln('PART $partNumber of $totalParts');
    buffer.writeln('DURATION: exactly 10 seconds');
    buffer.writeln('FORMAT: vertical 9:16');
    buffer.writeln();
    buffer.writeln('STORY CONTEXT: $foundation');
    buffer.writeln();
    buffer.writeln('ON-SCREEN TEXT OVERLAYS: ${overlayInstruction(overlay)}');
    buffer.writeln();
    buffer.writeln('THIS PART\'S PURPOSE: $purpose');
    buffer.writeln();
    buffer.writeln('CHARACTER LOCK:');
    buffer.writeln(charBlock);
    buffer.writeln();
    buffer.writeln(kStoryStructureRules);
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
    String detail(String label) =>
        StoryGenerator.extractLine(hook.storyDetail, '$label:');
    final resolution = detail('Resolution');

    return GeneratedStory(
      title: hook.cover,
      hook: hook.opening.trim().isNotEmpty ? hook.opening.trim() : hook.cover,
      who: characters.join(', '),
      where: hook.setting.trim().isNotEmpty
          ? hook.setting
          : (detail('Where').isNotEmpty ? detail('Where') : 'at home'),
      problem: hook.problem.trim().isNotEmpty ? hook.problem : detail('Story'),
      twist: detail('Twist'),
      worse: hook.mess.trim().isNotEmpty
          ? hook.mess
          : (detail('Worse').isNotEmpty ? detail('Worse') : detail('Worse')),
      solution: resolution.isNotEmpty
          ? resolution
          : (hook.endingBeat.isNotEmpty ? hook.endingBeat : hook.lesson),
      endingLine: hook.endingBeat.trim().isNotEmpty
          ? hook.endingBeat.trim()
          : (detail('Ending').isNotEmpty ? detail('Ending') : resolution),
      moral: hook.keepMoralOffScreen
          ? ''
          : (detail('Moral').isNotEmpty ? detail('Moral') : hook.lesson),
      hookOptions: const [],
      setting: hook.setting,
      sceneDetail: hook.sceneDetail,
      dialogue: hook.dialogue,
      mess: hook.mess,
      innerThought: hook.innerThought,
      endingBeat: hook.endingBeat,
      cast: hook.defaultCast,
      moralHidden: hook.keepMoralOffScreen,
    );
  }
}
