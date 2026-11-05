// -- Every Content Idea, In One Place --------------------------------------------
//
// The hook library, the ready-made post packages, and the bulk paste parser all
// live here now. They used to sit in two files (plan_data.dart and
// day14_posts.dart) and between them they had drifted apart: the posts carried
// their own ContentBucket class and their own bucket ids, four of which did not
// exist in the library the rest of the app reads. Ideas and the buckets they
// belong to now sit together, and BucketLibrary in brand_system.dart is the only
// list of buckets in the app.
//
// A bucket id is one thing everywhere now. puzzle became challenge, talk became
// conversation, skill became age_practice, and wrap became the new community
// bucket. That last one is new because the three posts that used it ask the
// followers a question, which none of the other five buckets describes, and
// folding them into 'conversation' would have quietly changed what they were about.

import 'brand_system.dart';
import 'models/quick_idea.dart';

// -- Buckets ---------------------------------------------------------------------
//
// Thin names over BucketLibrary rather than a second list. quick_content.dart and
// plan_screen.dart call these, so they stay put and stop being a second truth.

const List<ContentBucket> kContentBuckets = BucketLibrary.all;

ContentBucket? bucketById(String id) => BucketLibrary.byId(id);

ContentBucket? bucketByName(String name) => BucketLibrary.byName(name);

String bucketLabel(String id) => bucketById(id)?.shortLabel ?? id;

// ── Hooks ─────────────────────────────────────────────────────────────────────

// Shared wording for readyPrompt video-generation text, so the house style lives
// in one place instead of being retyped in every PROMPT: line and every Part.
const kPromptStyle = '3D Pixar animation style, vertical 9:16';
const kPartStyle = '3D Pixar style, 9:16';

class HookIdea {
  final String id;
  final String category;

  /// Human-readable title for lists, search, and anywhere an id would be
  /// unreadable. Defaults to the cover text when not set separately.
  final String title;

  /// Two to four words for the cover. Short on purpose: longer stops being a hook
  /// and starts being a sentence nobody reads at thumbnail size.
  final String cover;

  /// The first line said out loud, in the first three seconds.
  final String opening;

  /// The real preschool problem the story is built on.
  final String problem;
  final String lesson;
  final String postFormat;
  final String strategy;
  final String caption;
  final String pinnedComment;

  /// False for posts the app cannot make — milestones and behind-the-scenes need your
  /// own screen recordings, not an illustrated story.
  final bool forApp;

  /// When it was last used, so the same hook does not go out twice in a month.
  final String usedOn;

  /// True for one you added yourself. Built-in ones can be edited but not deleted,
  /// so an update that adds new ones never fights with your changes.
  final bool custom;

  /// True for posts that have been retired from active rotation.
  final bool archived;

  /// Full 3-part video prompt detail for offline generation. Empty when the
  /// offline generator should derive prompts from the story template fields.
  final String storyDetail;

  // NEW FIELDS for specificity & anti-AI-smell
  final String setting; // where/when, Indian-home specific
  final String sceneDetail; // one physical, imperfect detail
  final String dialogue; // the line somebody actually says
  final String mess; // what goes wrong and stays wrong
  final String innerThought; // what the parent thinks but doesn't say
  final String endingBeat; // closing image; replaces spoken moral
  final List<String> defaultCast; // Characters used by this story.
  final bool keepMoralOffScreen;

  // Task 3: quote, detail, punchline
  final String quote; // exact line of dialogue for the hook
  final String detail; // one concrete sensory detail
  final String punchline; // closing image/beat (alternative to endingBeat)

  /// Ready-to-use 30-second viral Reel prompt (Part 1 + Part 2 + Part 3 + on-screen text).
  /// Empty when the hook does not have a pre-built viral prompt.
  final String readyPrompt;

  /// Story quality score (1-10), derived from StoryCheck pass count.
  final int score;

  /// Quality band: 'Ready', 'Improve', or 'Rewrite'. Read from StoryCheck.
  final String band;

  /// ISO date string of when the story was last reviewed.
  final String reviewedOn;

  const HookIdea({
    required this.id,
    required this.category,
    this.title = '',
    required this.cover,
    required this.opening,
    required this.problem,
    required this.lesson,
    this.postFormat = 'Reel',
    this.strategy = '',
    this.caption = '',
    this.pinnedComment = '',
    this.forApp = true,
    this.usedOn = '',
    this.custom = false,
    this.archived = false,
    this.storyDetail = '',
    this.setting = '',
    this.sceneDetail = '',
    this.dialogue = '',
    this.mess = '',
    this.innerThought = '',
    this.endingBeat = '',
    this.defaultCast = const ['Ria', 'Rio', 'Cuty'],
    this.keepMoralOffScreen = false,
    this.quote = '',
    this.detail = '',
    this.punchline = '',
    this.readyPrompt = '',
    this.score = 0,
    this.band = '',
    this.reviewedOn = '',
  });

  HookIdea copyWith({
    String? id,
    String? category,
    String? title,
    String? cover,
    String? opening,
    String? problem,
    String? lesson,
    String? postFormat,
    String? strategy,
    String? caption,
    String? pinnedComment,
    bool? forApp,
    String? usedOn,
    bool? custom,
    bool? archived,
    String? storyDetail,
    String? setting,
    String? sceneDetail,
    String? dialogue,
    String? mess,
    String? innerThought,
    String? endingBeat,
    List<String>? defaultCast,
    bool? keepMoralOffScreen,
    String? quote,
    String? detail,
    String? punchline,
    String? readyPrompt,
    int? score,
    String? band,
    String? reviewedOn,
  }) => HookIdea(
    id: id ?? this.id,
    category: category ?? this.category,
    title: title ?? this.title,
    cover: cover ?? this.cover,
    opening: opening ?? this.opening,
    problem: problem ?? this.problem,
    lesson: lesson ?? this.lesson,
    postFormat: postFormat ?? this.postFormat,
    strategy: strategy ?? this.strategy,
    caption: caption ?? this.caption,
    pinnedComment: pinnedComment ?? this.pinnedComment,
    forApp: forApp ?? this.forApp,
    usedOn: usedOn ?? this.usedOn,
    custom: custom ?? this.custom,
    archived: archived ?? this.archived,
    storyDetail: storyDetail ?? this.storyDetail,
    setting: setting ?? this.setting,
    sceneDetail: sceneDetail ?? this.sceneDetail,
    dialogue: dialogue ?? this.dialogue,
    mess: mess ?? this.mess,
    innerThought: innerThought ?? this.innerThought,
    endingBeat: endingBeat ?? this.endingBeat,
    defaultCast: defaultCast ?? this.defaultCast,
    keepMoralOffScreen: keepMoralOffScreen ?? this.keepMoralOffScreen,
    quote: quote ?? this.quote,
    detail: detail ?? this.detail,
    punchline: punchline ?? this.punchline,
    readyPrompt: readyPrompt ?? this.readyPrompt,
    score: score ?? this.score,
    band: band ?? this.band,
    reviewedOn: reviewedOn ?? this.reviewedOn,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'cover': cover,
    'opening': opening,
    'problem': problem,
    'lesson': lesson,
    'forApp': forApp,
    'usedOn': usedOn,
    'custom': custom,
    'archived': archived,
    'postFormat': postFormat,
    'strategy': strategy,
    'caption': caption,
    'pinnedComment': pinnedComment,
    'storyDetail': storyDetail,
    'setting': setting,
    'sceneDetail': sceneDetail,
    'dialogue': dialogue,
    'mess': mess,
    'innerThought': innerThought,
    'endingBeat': endingBeat,
    'defaultCast': defaultCast,
    'keepMoralOffScreen': keepMoralOffScreen,
    'quote': quote,
    'detail': detail,
    'punchline': punchline,
    'readyPrompt': readyPrompt,
    'score': score,
    'band': band,
    'reviewedOn': reviewedOn,
  };

  factory HookIdea.fromJson(Map<String, dynamic> j) => HookIdea(
    id: j['id'] as String? ?? '',
    category: j['category'] as String? ?? 'Relatable',
    title: j['title'] as String? ?? '',
    cover: j['cover'] as String? ?? '',
    opening: j['opening'] as String? ?? '',
    problem: j['problem'] as String? ?? '',
    lesson: j['lesson'] as String? ?? '',
    postFormat: j['postFormat'] as String? ?? 'Reel',
    strategy: j['strategy'] as String? ?? '',
    caption: j['caption'] as String? ?? '',
    pinnedComment: j['pinnedComment'] as String? ?? '',
    forApp: j['forApp'] as bool? ?? true,
    usedOn: j['usedOn'] as String? ?? '',
    custom: j['custom'] as bool? ?? false,
    archived: j['archived'] as bool? ?? false,
    storyDetail: j['storyDetail'] as String? ?? '',
    setting: j['setting'] as String? ?? '',
    sceneDetail: j['sceneDetail'] as String? ?? '',
    dialogue: j['dialogue'] as String? ?? '',
    mess: j['mess'] as String? ?? '',
    innerThought: j['innerThought'] as String? ?? '',
    endingBeat: j['endingBeat'] as String? ?? '',
    defaultCast:
        (j['defaultCast'] as List?)?.map((e) => e as String).toList() ??
        ['Ria', 'Rio', 'Cuty'],
    keepMoralOffScreen: j['keepMoralOffScreen'] as bool? ?? false,
    quote: j['quote'] as String? ?? '',
    detail: j['detail'] as String? ?? '',
    punchline: j['punchline'] as String? ?? '',
    readyPrompt: j['readyPrompt'] as String? ?? '',
    score: j['score'] as int? ?? 0,
    band: j['band'] as String? ?? '',
    reviewedOn: j['reviewedOn'] as String? ?? '',
  );

  /// Laid out as the story form, ready for Write the script.
  /// If [storyDetail] is present, it is the primary source. Otherwise, falls back
  /// to individual fields. If both are empty, marks the idea as "Draft".
  String asStoryText() {
    if (storyDetail.trim().isNotEmpty) {
      return 'Cover hook: $cover\n'
          'Hook: $opening\n'
          'Who: ${defaultCast.join(", ")}\n'
          'Where: $setting\n'
          'What starts it: $problem\n'
          'Scene detail: $sceneDetail\n'
          'Dialogue: $dialogue\n'
          'What goes wrong: $mess\n'
          'Parent inner thought: $innerThought\n'
          'How it is solved: $endingBeat\n'
          'Moral (off-screen): ${keepMoralOffScreen ? "(not spoken)" : lesson}\n'
          'Post format: $postFormat\n'
          'Strategy: $strategy\n'
          'Caption: $caption\n'
          'Pinned comment: $pinnedComment\n'
          '$storyDetail\n'
          'Status: ${usedOn.isEmpty ? "New" : usedOn}';
    }
    // Fallback to individual fields, but mark as Draft if no real content
    final hasContent =
        setting.isNotEmpty ||
        sceneDetail.isNotEmpty ||
        dialogue.isNotEmpty ||
        mess.isNotEmpty ||
        innerThought.isNotEmpty ||
        endingBeat.isNotEmpty;
    if (!hasContent) {
      return 'Cover hook: $cover\n'
          'Hook: $opening\n'
          'Who: ${defaultCast.join(", ")}\n'
          'Where: $setting\n'
          'What starts it: $problem\n'
          'Status: Draft\n';
    }
    return 'Cover hook: $cover\n'
        'Hook: $opening\n'
        'Who: ${defaultCast.join(", ")}\n'
        'Where: $setting\n'
        'What starts it: $problem\n'
        'Scene detail: $sceneDetail\n'
        'Dialogue: $dialogue\n'
        'What goes wrong: $mess\n'
        'Parent inner thought: $innerThought\n'
        'How it is solved: $endingBeat\n'
        'Moral (off-screen): ${keepMoralOffScreen ? "(not spoken)" : lesson}\n'
        'Post format: $postFormat\n'
        'Strategy: $strategy\n'
        'Caption: $caption\n'
        'Pinned comment: $pinnedComment\n'
        'Status: ${usedOn.isEmpty ? "New" : usedOn}';
  }
}

const kHookCategories = [
  'Safety',
  'Learning Lesson',
  'Child Chaos',
  'Ria Chaos',
  'Funny',
  'Festivals',
  'Navratri',
  'Diwali',
  'Series',
];

/// The starting list. Merged from several AI suggestions and cut down hard: the same
/// three problems (screen time, shoes, toy fights) appeared four or five times each,
/// and several were written as "I" — a parent speaking — when the reels are told by a
/// storyteller about Ria and Rio.
///
/// Kids Safety hooks (shield collection) and the former 14-day post package all live
/// directly in this one list now too, so every idea is one format in one place instead
/// of three different lists and two different classes.
/// Each carries a full storyDetail with the Story/Twist/Resolution/Moral
/// labels the offline generator expects.


/// Combined hooks list with safety hooks appended.


// ── Bulk Parser ───────────────────────────────────────────────────────────────

class ParsedPostPackage {
  final String title;
  final String postType;
  final String audience;
  final String contentGoal;
  final String mood;
  final String hook;
  final String mainIdea;
  final String problem;
  final String lesson;
  final String visualStyle;
  final String imagePrompt;
  final String caption;
  final String cta;
  final String hashtags;
  final String pinnedComment;
  final List<String> replyComments;
  final String script;
  final String bucket;

  // Moment fields for story detail
  final String opening;
  final String sceneDetail;
  final String dialogue;
  final String mess;
  final String innerThought;
  final String endingBeat;
  final bool keepMoralOffScreen;

  ParsedPostPackage({
    this.title = '',
    this.postType = 'Carousel',
    this.audience = 'Parents of 3-6 year olds',
    this.contentGoal = '',
    this.mood = '',
    this.hook = '',
    this.mainIdea = '',
    this.problem = '',
    this.lesson = '',
    this.visualStyle = '',
    this.imagePrompt = '',
    this.caption = '',
    this.cta = '',
    this.hashtags = '',
    this.pinnedComment = '',
    this.replyComments = const [],
    this.script = '',
    this.bucket = '',
    this.opening = '',
    this.sceneDetail = '',
    this.dialogue = '',
    this.mess = '',
    this.innerThought = '',
    this.endingBeat = '',
    this.keepMoralOffScreen = false,
  });

  bool get hasAnyContent =>
      title.isNotEmpty ||
      hook.isNotEmpty ||
      mainIdea.isNotEmpty ||
      problem.isNotEmpty ||
      lesson.isNotEmpty ||
      caption.isNotEmpty ||
      imagePrompt.isNotEmpty ||
      script.isNotEmpty ||
      dialogue.isNotEmpty ||
      endingBeat.isNotEmpty;

  /// Builds a [HookIdea] from the parsed fields, in the one shared format
  /// every idea in the JSON source now uses. [category] overrides the guess
  /// made from [bucket] when the caller already knows which one fits.
  HookIdea toHookIdea(String id, {String? category}) {
    return HookIdea(
      id: id,
      category: category ?? _categoryFromBucket(bucket),
      cover: hook.isNotEmpty ? hook : title,
      title: title,
      opening: opening.isNotEmpty ? opening : mainIdea,
      problem: problem,
      lesson: lesson,
      postFormat: _normalizePostType(postType),
      strategy: [audience, contentGoal].where((s) => s.isNotEmpty).join(' — '),
      caption: caption,
      pinnedComment: cta.isNotEmpty ? cta : pinnedComment,
      forApp: true,
      storyDetail: script,
      setting: visualStyle,
      sceneDetail: sceneDetail,
      dialogue: dialogue,
      mess: mess,
      innerThought: innerThought,
      endingBeat: endingBeat,
      defaultCast: const ['Ria', 'Rio', 'Cuty'],
      keepMoralOffScreen: keepMoralOffScreen,
      readyPrompt: imagePrompt,
    );
  }
}

ParsedPostPackage parseBulkPaste(String text) {
  final result = ParsedPostPackage();
  if (text.trim().isEmpty) return result;

  final lines = text.split('\n');
  final sections = <String, List<String>>{};
  String currentSection = 'header';
  final sectionContent = <String>[];

  for (final line in lines) {
    if (line.startsWith('--- ') && line.endsWith(' ---')) {
      if (sectionContent.isNotEmpty) {
        sections[currentSection] = List.of(sectionContent);
      }
      sectionContent.clear();
      currentSection = line.substring(4, line.length - 4).trim().toLowerCase();
    } else {
      sectionContent.add(line);
    }
  }
  if (sectionContent.isNotEmpty) {
    sections[currentSection] = List.of(sectionContent);
  }

  // Parse header key-value pairs
  final headerLines = sections['header'] ?? [];
  final kv = <String, String>{};
  String? currentKey;
  final currentVal = StringBuffer();

  for (int i = 0; i < headerLines.length; i++) {
    final line = headerLines[i];
    final colonIdx = line.indexOf(':');
    final isNewKey =
        colonIdx > 0 &&
        line.substring(0, colonIdx).trim().split(' ').length <= 4 &&
        !line.startsWith('---') &&
        !line.startsWith(' ');

    if (isNewKey) {
      if (currentKey != null) {
        kv[currentKey] = currentVal.toString().trim();
        currentVal.clear();
      }
      currentKey = line.substring(0, colonIdx).trim();
      currentVal.write(line.substring(colonIdx + 1).trim());
    } else if (currentKey != null) {
      currentVal.write('\n$line');
    }
  }
  if (currentKey != null) {
    kv[currentKey] = currentVal.toString().trim();
  }

  // Helper to read a key case-insensitively
  String readKey(String key) {
    for (final entry in kv.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) {
        return entry.value;
      }
    }
    return '';
  }

  return ParsedPostPackage(
    title: readKey('Title'),
    postType: _normalizePostType(
      readKey('Post Type').isNotEmpty
          ? readKey('Post Type')
          : readKey('PostType'),
    ),
    audience: readKey('Audience').isNotEmpty
        ? readKey('Audience')
        : 'Parents of 3-6 year olds',
    contentGoal: readKey('Content Goal'),
    mood: readKey('Mood'),
    hook: readKey('Hook'),
    opening: readKey('Opening'),
    mainIdea: readKey('Main Idea'),
    problem: readKey('Problem'),
    lesson: readKey('Lesson'),
    visualStyle: readKey('Visual Style'),
    imagePrompt: _sectionText(sections, ['image prompt', 'imageprompt']),
    caption: _sectionText(sections, ['caption']),
    cta: readKey('CTA'),
    hashtags: readKey('Hashtags'),
    pinnedComment: _sectionText(sections, ['pinned comment', 'pin comment']),
    replyComments: _parseComments(
      _sectionText(sections, ['reply comments', 'comments']),
    ),
    script: _sectionText(sections, ['script', 'carousel text', 'carousel']),
    bucket: _resolveBucket(readKey('Bucket')),
    sceneDetail: _sectionText(sections, ['scene detail', 'scene']),
    dialogue: _sectionText(sections, ['dialogue', 'dialog']),
    mess: _sectionText(sections, ['mess']),
    innerThought: _sectionText(sections, ['inner thought', 'inner', 'thought']),
    endingBeat: _sectionText(sections, ['ending beat', 'ending']),
    keepMoralOffScreen:
        readKey('Keep Moral Off Screen').toLowerCase() == 'true',
  );
}

String _normalizePostType(String value) {
  final v = value.trim().toLowerCase();
  if (v.contains('static')) return 'Static Image';
  if (v.contains('reel')) return 'Reel';
  if (v.contains('carousel') || v.contains('carous')) return 'Carousel';
  if (v.contains('story')) return 'Story';
  return value.trim().isEmpty ? 'Carousel' : value.trim();
}

String _sectionText(Map<String, List<String>> sections, List<String> keys) {
  for (final key in keys) {
    final lines = sections[key];
    if (lines != null && lines.isNotEmpty) {
      return lines.join('\n').trim();
    }
  }
  return '';
}

List<String> _parseComments(String text) {
  if (text.trim().isEmpty) return [];
  final lines = text.split('\n');
  final comments = <String>[];
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final match = RegExp(r'^(\d+)\.?\s*(.*)$').firstMatch(trimmed);
    if (match != null && match.group(2)!.isNotEmpty) {
      comments.add(match.group(2)!);
    } else if (!trimmed.startsWith('1.') && !trimmed.startsWith('2.')) {
      comments.add(trimmed);
    }
  }
  return comments;
}

String _resolveBucket(String name) {
  final b = bucketByName(name);
  if (b != null) return b.id;
  final lower = name.toLowerCase();
  if (lower.contains('puzzle') ||
      lower.contains('figure') ||
      lower.contains('hidden') ||
      lower.contains('pattern')) {
    return 'challenge';
  }
  if (lower.contains('humor') ||
      lower.contains('funny') ||
      lower.contains('mumma')) {
    return 'humor';
  }
  if (lower.contains('activity') ||
      lower.contains('challenge') ||
      lower.contains('hunt')) {
    return 'activity';
  }
  if (lower.contains('talk') ||
      lower.contains('question') ||
      lower.contains('ask')) {
    return 'conversation';
  }
  if (lower.contains('skill') ||
      lower.contains('year-old') ||
      lower.contains('checklist')) {
    return 'age_practice';
  }
  if (lower.contains('wrap') ||
      lower.contains('favorite') ||
      lower.contains('feedback')) {
    return 'community';
  }
  return '';
}

/// Best-guess [kHookCategories] value for a pasted idea, from its bucket.
/// Lets [ParsedPostPackage.toHookIdea] produce something sane without the
/// caller having to pick a category by hand every time.
String _categoryFromBucket(String bucket) {
  switch (bucket) {
    case 'challenge':
    case 'humor':
      return 'Funny';
    case 'community':
      return 'Series';
    case 'activity':
    case 'conversation':
    case 'age_practice':
    default:
      return 'Learning Lesson';
  }
}
