import 'dart:math';

import 'content_ideas.dart';
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

  static const String _visualStyle =
      'Soft 3D Pixar-Disney animation style, vertical 9:16, '
      'warm natural lighting, semi-realistic quality, cream background';

  static const String _negativeInstructions =
      'No duplicate characters, no identity changes, no outfit changes throughout, '
      'no distorted anatomy, no random text, no floating objects, '
      'no glasses on Ria and Rio, Cuty always fluffy white bunny with coral-pink bow';

  static const String _riaDesc =
      "toddler girl, light brown hair in two short pigtails tied with pink bows, "
      "soft fringe across the forehead, large round dark brown eyes with long lashes, "
      "fair skin with rosy cheeks and light freckles, pink short-sleeved tiered dress "
      "covered in small gold stars with pink lace trim on each tier, pink mary-jane shoes, "
      "chubby toddler body proportions";

  static const String _rioDesc =
      "toddler boy, tousled medium brown hair, large round amber-brown eyes with "
      "long lashes, fair skin with rosy cheeks, thick dark eyebrows, plain blue-grey "
      "short-sleeved t-shirt, matching blue-grey shorts with a side pocket, black "
      "lace-up sneakers with white soles, chubby toddler body proportions, slightly "
      "taller than Ria";

  static const String _cutyDesc =
      "fluffy white bunny, long upright ears with soft pink inner colouring, "
      "coral-pink fabric bow tied at the neck, very large round dark brown eyes with "
      "lashes, small pink nose, pink blush on both cheeks, chubby rounded body standing "
      "upright like a toddler";

  static const String _mummaDesc =
      "young Indian mother, medium brown hair in a high bun with a few loose strands, "
      "fair-medium skin, large dark brown eyes, small red bindi, gold jhumka earrings, "
      "mustard-yellow three-quarter-sleeve kurta with white chikankari floral embroidery, "
      "blue jeans, comfortable smile";

  static const String _papaDesc =
      "young Indian father, short neat black hair, warm brown eyes, light stubble, "
      "fair skin, light blue full-sleeve kurta with subtle embroidery, "
      "matching pyjama trousers, brown juttis, friendly expression";

  static const String _daadiDesc =
      "Indian grandmother, silver-grey hair in a neat bun, warm tan skin with soft "
      "wrinkles, dark brown eyes behind round gold-rimmed glasses, small red bindi, "
      "gold jhumka earrings, cream saree with gold border, warm affectionate smile";

  static const String _teacherDesc =
      "Indian school teacher, dark hair in a low bun with small white gajra, "
      "warm tan skin, dark brown eyes, round gold-rimmed glasses, small red bindi, "
      "blue three-quarter-sleeve kurta, holding a book, encouraging smile";

  static const Map<String, String> _characterDescriptions = {
    'Ria': _riaDesc,
    'Rio': _rioDesc,
    'Cuty': _cutyDesc,
    'Mumma': _mummaDesc,
    'Papa': _papaDesc,
    'Daadi': _daadiDesc,
    'Teacher': _teacherDesc,
  };

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

      final action04 = _buildActionForBeat(beat, 1);
      final action48 = _buildActionForBeat(beat, 2);
      final action810 = isLast
          ? _buildEndingAction(beat, characters)
          : _buildActionForBeat(beat, 3);

      final dialogue = _buildDialogue(story, partNumber, partsCount, beat);
      final endingState = _buildEndingState(beat, characters);
      final textHook = _buildTextHook(partNumber, partsCount, story);
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
    final List<String> beats;
    if (partsCount <= 2) {
      beats = ['problem', 'solution'];
    } else if (partsCount == 3) {
      beats = ['problem', 'twist', 'solution'];
    } else {
      beats = [
        'problem',
        'twist',
        'worse',
        'solution',
        'solution',
        'solution',
      ];
    }

    if (beats.length > partsCount) {
      return beats.sublist(0, partsCount);
    }
    while (beats.length < partsCount) {
      beats.insert(beats.length ~/ 2, 'solution');
    }
    return beats;
  }

  String _buildCharacterBlock(List<String> characters) {
    final buffer = StringBuffer();
    for (final name in characters) {
      final desc = _characterDescriptions[name] ??
          'standard character appearance';
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

  String _buildActionForBeat(String beat, int segment) {
    switch (beat) {
      case 'problem':
        switch (segment) {
          case 1:
            return 'Ria and Rio encounter the problem mid-action';
          case 2:
            return 'The situation becomes clear, characters react visibly';
          case 3:
            return 'Problem escalates slightly, building natural tension';
        }
        break;
      case 'twist':
        switch (segment) {
          case 1:
            return 'Unexpected element enters the scene';
          case 2:
            return 'Characters notice and respond to the change';
          case 3:
            return 'Twist creates new dynamic, tension rises';
        }
        break;
      case 'worse':
        switch (segment) {
          case 1:
            return 'The problem gets worse, frustration shows';
          case 2:
            return 'Both characters are involved, each reacts differently';
          case 3:
            return 'Tension builds through actions, not dialogue';
        }
        break;
      case 'solution':
        switch (segment) {
          case 1:
            return 'Small realization or change of approach begins';
          case 2:
            return 'Cuty does something that shifts direction positively';
          case 3:
            return 'Characters start working together toward resolution';
        }
        break;
    }
    return 'Scene develops naturally with clear action and emotion';
  }

  String _buildEndingAction(String beat, List<String> characters) {
    final char1 = characters.isNotEmpty ? characters[0] : 'Ria';
    final char2 = characters.length > 1 ? characters[1] : 'Rio';
    return '$char1 and $char2 resolve the situation with a warm '
        'moment, scene settling toward the closing card with lesson visible';
  }

  String _buildTextHook(int partNumber, int totalParts, GeneratedStory story) {
    if (partNumber == 1) {
      return 'Top: "${story.hook.split(" ").take(3).join(" !")}!"';
    }
    if (partNumber == totalParts) {
      return 'Top: "Teamwork ho toh sab easy! ✨"';
    }
    return 'Top: "Phir kya hua? 🤔"';
  }

  String _buildDialogue(GeneratedStory story, int partNumber, int totalParts,
      String beat) {
    if (partNumber == 1) {
      final firstWord = story.problem.split(' ').where((w) => w.length > 3);
      final subject = firstWord.isNotEmpty
          ? firstWord.first
          : 'something';
      return 'Ria: "$subject dekho yeh kya hua!"\n'
          'Rio: "Abhi thoda wait karo!"';
    }
    if (partNumber == totalParts) {
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
    buffer.writeln('VISUAL STYLE: $_visualStyle');
    buffer.writeln();
    buffer.writeln('NEGATIVE INSTRUCTIONS: $_negativeInstructions');
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
}
