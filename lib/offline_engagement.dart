import 'dart:convert';
import 'dart:math';

import 'characters.dart';
import 'master_prompt.dart';

class OfflineEngagementPackage {
  final String caption;
  final List<String> hashtags;
  final String pinnedComment;
  final List<Map<String, String>> suggestedReplies;
  final String followReason;

  OfflineEngagementPackage({
    required this.caption,
    required this.hashtags,
    required this.pinnedComment,
    required this.suggestedReplies,
    required this.followReason,
  });

  Map<String, dynamic> toJson() => {
    'caption': caption,
    'hashtags': hashtags,
    'pinnedComment': pinnedComment,
    'suggestedReplies': suggestedReplies,
    'followReason': followReason,
  };

  String get forInstagram => hashtags.isEmpty
      ? caption
      : '$caption\n\n${hashtags.join(' ')}';

  String get jsonString => jsonEncode(toJson());
}

String buildOfflineImagePrompt({
  required String idea,
  required List<String> characters,
  String additionalInstructions = '',
}) {
  final buffer = StringBuffer();
  buffer.writeln(kVisualStyle);
  buffer.writeln();
  buffer.writeln('CHARACTERS:');
  for (final name in characters) {
    final desc = characterDescription(name);
    buffer.writeln('- $name: $desc');
  }
  buffer.writeln();
  buffer.writeln('SCENE: $idea');
  buffer.writeln('Indian home interior, warm natural lighting.');
  if (additionalInstructions.trim().isNotEmpty) {
    buffer.writeln('ADDITIONAL INSTRUCTIONS: $additionalInstructions');
  }
  buffer.writeln();
  buffer.writeln(kStoryStructureRules);
  return buffer.toString();
}

List<Map<String, String>> buildOfflineCarouselSlides({
  required String idea,
  required List<String> characters,
  int slideCount = 5,
}) {
  final slides = <Map<String, String>>[];
  final titles = [
    'The Problem',
    'What Goes Wrong',
    'The Solution',
    'Why It Works',
    'Save This!'
  ];
  final captions = [
    'Sound familiar?',
    'Every parent knows this...',
    'Here is the fix',
    'Why it works',
    'Save for later',
  ];
  final charList = characters.join(', ');

  for (int i = 0; i < slideCount; i++) {
    slides.add({
      'slideNumber': (i + 1).toString(),
      'purpose': titles[i % titles.length],
      'textOverlay': '${captions[i % captions.length]}\n$idea',
      'prompt': 'Slide ${i + 1}: $idea. '
          '$charList in Soft 3D Pixar/Disney style, '
          'cream background, warm lighting. '
          'Visual storytelling, no text overlay needed.',
    });
  }
  return slides;
}

class OfflineEngagementGenerator {
  final Random _rng = Random();

  static const List<String> _captionTemplates = [
    'This is exactly what happened in our house this morning! Every parent will recognise this moment. ',
    'Save this for the next time your toddler says "no"! Every small win counts. ',
    'We tried this yesterday and it changed bedtime instantly. Try it tonight! ',
    'Every parent of a 3-year-old needs to see this. Bookmark it for tomorrow morning. ',
    'This took 2 minutes to set up and saved our sanity at dinner. You are welcome! ',
  ];

  static const List<List<String>> _hashtagSets = [
    ['#funlearningwithpalak', '#toddlerlife', '#parentingtips', '#screenfree', '#playbased'],
    ['#funlearningwithpalak', '#preschoolers', '#momlife', '#toddleractivities', '#learningthroughplay'],
    ['#funlearningwithpalak', '#indianmoms', '#parentinghacks', '#kidsactivities', '#mindfultoys'],
    ['#funlearningwithpalak', '#toddlertips', '#parentingwin', '#smallwins', '#dailymomlife'],
    ['#funlearningwithpalak', '#momsoftiktok', '#toddlermom', '#learningthroughplay', '#screenfree'],
  ];

  static const List<String> _pinnedCommentOptions = [
    'We do this every morning — tell us your morning routine tip below! 👇',
    'How many times today did you say "brush your teeth"? 😂',
    'This is why we keep toy bins in every room — what are your must-haves? 💡',
    'Sound familiar? Drop a ✅ if your house looks like this too!',
    'We\'ve been doing this for years — what is your kid\'s go-to protest move? 😂',
  ];

  static const List<Map<String, String>> _replyTemplates = [
    {'situation': 'similar experience', 'text': 'SAME in our house! How do you handle it? 🤣'},
    {'situation': 'tip shared', 'text': 'Great tip — trying this tomorrow!'},
    {'situation': 'question asked', 'text': 'Good question — we found that the timer helps!'},
    {'situation': 'disagreement', 'text': 'Different for us, but kids are all different 💙'},
    {'situation': 'emotional share', 'text': 'This made our day — thank you for sharing! ❤️'},
    {'situation': 'compliment', 'text': 'You are doing an amazing job — keep going! 💪'},
  ];

  static const List<String> _followReasons = [
    'Daily ideas that work in real Indian homes, no fancy toys needed.',
    'Screen-free activities tested by real parents with real toddlers.',
    'Simple solutions for the chaos of small children, every day.',
    'Stories that feel like they were written in your own living room.',
    'Parent-tested, toddler-approved, and actually doable.',
  ];

  OfflineEngagementPackage generate({required String storyMoral}) {
    final caption = _captionTemplates[_rng.nextInt(_captionTemplates.length)];
    final hashtags =
        _hashtagSets[_rng.nextInt(_hashtagSets.length)];
    final pinnedComment =
        _pinnedCommentOptions[_rng.nextInt(_pinnedCommentOptions.length)];

    final replies = <Map<String, String>>[];
    final indices = List<int>.generate(_replyTemplates.length, (i) => i)
      ..shuffle(_rng);
    for (final i in indices.take(6)) {
      replies.add(_replyTemplates[i]);
    }

    final followReason =
        _followReasons[_rng.nextInt(_followReasons.length)];

    final fullCaption = '$caption\n\n$storyMoral';

    return OfflineEngagementPackage(
      caption: fullCaption,
      hashtags: hashtags,
      pinnedComment: pinnedComment,
      suggestedReplies: replies,
      followReason: followReason,
    );
  }
}
