import 'dart:math';

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
      'Soft 3D Pixar/Disney-style render, warm natural lighting, semi-realistic quality. '
      'NOT flat 2D, NOT watercolor, NOT kawaii-chibi. Cream background.';

  static const String _negativeInstructions =
      'No duplicate characters, no identity changes, no outfit changes, '
      'no distorted anatomy, no random text, no floating objects.';

  static const Map<String, String> _characterDescriptions = {
    'Ria': 'toddler girl, light brown hair in two short pigtails tied with pink bows, '
        'soft fringe across the forehead, large round dark brown eyes with long lashes, '
        'fair skin with rosy cheeks and light freckles, pink short-sleeved tiered dress '
        'covered in small gold stars with pink lace trim on each tier, pink mary-jane shoes, '
        'chubby toddler body proportions',
    'Rio': 'toddler boy, tousled medium brown hair, large round amber-brown eyes with '
        'long lashes, fair skin with rosy cheeks, thick dark eyebrows, plain blue-grey '
        'short-sleeved t-shirt, matching blue-grey shorts with a side pocket, black '
        'lace-up sneakers with white soles, chubby toddler body proportions, slightly '
        'taller than Ria',
    'Cuty': 'fluffy white bunny, long upright ears with soft pink inner colouring, '
        'coral-pink fabric bow tied at the neck, very large round dark brown eyes with '
        'lashes, small pink nose, pink blush on both cheeks, chubby rounded body standing '
        'upright like a toddler',
    'Mumma': 'young Indian mother, medium brown hair in a high rounded bun with a few '
        'loose strands, fair-medium skin, large dark brown eyes, small red bindi, gold '
        'jhumka earrings, mustard-yellow three-quarter-sleeve kurta with white chikankari '
        'floral embroidery, blue jeans, brown flip-flop sandals',
  };

  static const List<String> _beatPurposes = [
    'Hook',
    'Problem',
    'Conflict',
    'Turn',
    'Solution',
    'Ending',
  ];

  static const List<String> _shotTypes = [
    'wide shot',
    'close-up on face',
    'medium shot',
    'from above',
    'looking up',
    'over the shoulder',
  ];

  GeminiVideoResult generateFromIdea({
    required String idea,
    required int totalSeconds,
    required List<String> characters,
    String additionalInstructions = '',
  }) {
    final partsCount = (totalSeconds / 10).round().clamp(2, 6);
    final charBlock = _buildCharacterBlock(characters);
    final storyTitle = _titleFromIdea(idea);
    final storyFoundation = _buildFoundation(idea, characters);

    final parts = <VideoPartPrompt>[];
    String previousEndingState = 'opening scene';

    for (int i = 0; i < partsCount; i++) {
      final beat = _beatPurposes[(i * _beatPurposes.length / partsCount).floor()
          .clamp(0, _beatPurposes.length - 1)];
      final partNumber = i + 1;

      final purpose = _buildPurpose(beat, partNumber, partsCount);
      final setting = _buildSetting(partNumber);
      final startingState = i == 0
          ? 'Ria and Rio in the center of the room, Cuty nearby, neutral expressions'
          : previousEndingState;

      final action04 = _buildAction(beat, '0-4s', partNumber);
      final action48 = _buildAction(beat, '4-8s', partNumber);
      final action810 = _buildEndingAction(beat, partNumber, partsCount, i == partsCount - 1);

      final dialogue = i == 0
          ? _buildHookDialogue(storyTitle)
          : i == partsCount - 1
              ? _buildResolutionDialogue()
              : _buildMiddleDialogue();

      final endingState = _buildEndingState(beat, characters);
      final continuityInto = 'Characters in same positions as ending state, '
          'setting transitions seamlessly to the next scene';

      final fullPrompt = _buildFullPrompt(
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
        previousEndingState,
        continuityInto,
        additionalInstructions,
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

  String _buildFullPrompt(
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
    String additionalInstructions,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('TITLE: $title');
    buffer.writeln('PART $partNumber of $totalParts');
    buffer.writeln('DURATION: exactly 10 seconds');
    buffer.writeln('FORMAT: vertical 9:16');
    buffer.writeln();
    buffer.writeln('STORY CONTEXT: $foundation');
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
    if (dialogue.isNotEmpty) {
      buffer.writeln('DIALOGUE AND AUDIO: $dialogue');
    } else {
      buffer.writeln('DIALOGUE AND AUDIO: (no dialogue)');
    }
    buffer.writeln();
    buffer.writeln('CONTINUITY FROM PREVIOUS PART: $continuityFrom');
    buffer.writeln();
    buffer.writeln('CONTINUITY INTO NEXT PART: $continuityInto');
    buffer.writeln();
    buffer.writeln('VISUAL STYLE: $_visualStyle 1.5-5 year old Indian children, '
        'warm family moments, cream backgrounds, gentle textures.');
    buffer.writeln();
    buffer
        .writeln('NEGATIVE INSTRUCTIONS: $_negativeInstructions');
    if (additionalInstructions.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('ADDITIONAL INSTRUCTIONS: $additionalInstructions');
    }

    return buffer.toString();
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

  String _titleFromIdea(String idea) {
    final words = idea.split(' ').where((w) => w.length > 2).toList();
    if (words.isEmpty) return 'Quick Story';
    return words.take(3).map((w) => _capitalize(w)).join(' ');
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _buildFoundation(String idea, List<String> characters) {
    final chars = characters.join(' and ');
    return '$chars go through a small everyday moment that every parent '
        'recognises. The story starts mid-action, builds gently, and ends '
        'with a warm lesson that parents can relate to. Based on: $idea';
  }

  String _buildPurpose(String beat, int partNumber, int totalParts) {
    if (partNumber == 1) return 'Hook: Show the situation that every parent recognises';
    if (partNumber == totalParts) {
      return 'Ending: Resolve the conflict with a warm moment and clear takeaway';
    }
    return '$beat: Develop the story naturally toward resolution';
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

  String _buildAction(String beat, String timeSlot, int partNumber) {
    final templates = <String>[];
    switch (beat) {
      case 'Hook':
        templates.addAll([
          'Ria and Rio are caught mid-action in a relatable moment',
          'Camera focuses on the messy scene, building curiosity',
          'A small moment unfolds that parents instantly recognise',
        ]);
        break;
      case 'Problem':
        templates.addAll([
          'The conflict or situation is clearly shown',
          'Character reacts with visible frustration or surprise',
          'The problem is obvious for any parent watching',
        ]);
        break;
      case 'Conflict':
        templates.addAll([
          'The situation escalates naturally',
          'Both characters are involved, each with their own reaction',
          'Tension builds through actions, not dialogue',
        ]);
        break;
      case 'Turn':
        templates.addAll([
          'A small realization or change of approach',
          'Cuty does something that shifts the direction',
          'The characters try a different angle',
        ]);
        break;
      case 'Solution':
        templates.addAll([
          'The resolution begins to take shape',
          'Characters work together on the solution',
          'A moment of teamwork and mutual understanding',
        ]);
        break;
      default:
        templates.addAll([
          'Final moment lands with warmth and connection',
          'Characters share a quiet conclusion',
          'The lesson is shown, not stated',
        ]);
    }
    return templates[_rng.nextInt(templates.length)];
  }

  String _buildEndingAction(
      String beat, int partNumber, int totalParts, bool isLast) {
    if (isLast) {
      return 'Characters resolve the situation with a warm moment '
          'that transitions to the closing card';
    }
    return 'Scene flows naturally into the next part, '
        'characters and setting hand off smoothly';
  }

  String _buildHookDialogue(String title) {
    final options = [
      'Ria says: "Mama ne kaha, bas thoda sa koshish karo!"',
      'Rio mutters: "Yeh baar toh pakka plan banega!"',
      'Off-screen grown-up voice: "Jab tak try karo gaye, tab tak problem thi!"',
    ];
    return options[_rng.nextInt(options.length)];
  }

  String _buildMiddleDialogue() {
    final options = [
      'Ria: "Rio, dekho yeh kya hua!"',
      'Rio: "Abhi nahi, thoda wait karo!"',
      '',
    ];
    return options[_rng.nextInt(options.length)];
  }

  String _buildResolutionDialogue() {
    final options = [
      'Ria: "Ho gaya! Theek hai na Mama?"',
      'Rio: "Next time, pehle maine kaha tha!"',
      '',
    ];
    return options[_rng.nextInt(options.length)];
  }

  String _buildEndingState(String beat, List<String> characters) {
    final char1 = characters.isNotEmpty ? characters[0] : 'Ria';
    final char2 = characters.length > 1 ? characters[1] : 'Rio';
    final char3 = characters.length > 2 ? characters[2] : 'Cuty';
    return '$char1 and $char2 together, $char3 nearby, '
        'expressions warm and resolved, scene settling';
  }
}
