import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'ai_provider.dart';
import 'brand_system.dart';
import 'content_generator.dart';
import 'content_ideas.dart' as ideas;
import 'format_adapter.dart';
import 'models/quick_idea.dart';
import 'posting_pack.dart';
import 'quality_check.dart';
import 'regenerator.dart';
import 'slide_prompts.dart';
import 'theme.dart';


// A reusable comment in the promo comment vault, optionally tagged with a content bucket.
class PromoComment {
  final String text;
  final String bucket;

  const PromoComment({required this.text, this.bucket = ''});

  /// The text in a normalized form for duplicate detection.
  String get normalizedText => text.trim();

  Map<String, dynamic> toJson() => {'text': text, 'bucket': bucket};

  factory PromoComment.fromJson(Map<String, dynamic> json) => PromoComment(
    text: (json['text'] as String?)?.trim() ?? '',
    bucket: (json['bucket'] as String?)?.trim() ?? '',
  );

  factory PromoComment.fromString(String text) => PromoComment(text: text);
}

class PromoCommentStore {
  static const _fileName = 'promo_comments.json';
  static const starterComments = [
    'Thank you ! ❤️ Meri Profile pe Ria, Rio & Cuty ki full masti chal rahi hai - miss mat karna! 👇',
    'Meri Profile pe Ria, Rio & Cuty ki full masti chal rahi hai - miss mat karna! ❤️',
    'Cuty ki masti + Ria Rio ki stories = perfect little-kids content 🐰💕',
    'Ria ne aaj phir kya kaand kar diya dekho meri Profile pe 🤣😂',
    'Ria ne aaj phir kya kaand kiya hai 😂🌸 Profile pe dekho!',
    'Meri Ria ko ek jagah shaant rehna aata hi nahi 😂❤️',
    'Ria ki Tofani duniya mein welcome 😂🌸',
    'Ria ke naye kaand dekhne hain? 😂❤️',
    'Ria = full masti, zero silence 😂🌸',
    'Meri profile pe Ria ki full Tofani masti chal rahi hai 😂❤️',
    'Ria ko dekhke har Mumma bolegi — “ye toh meri beti hai!” 😂',
    'Ria phir se kuch karne wali hai… mujhe already pata hai 😂🌸',
    'Rio ka favourite word? “Nahi!” 😂💙',
    'Rio ki zidd aur Ria ki masti… ghar mein shanti impossible 😂',
    'Mera Rio har baat pe negotiation karta hai 😂💙',
    'Rio ki zidd dekhke parents ko apna ghar yaad aa jayega 😂💙',
    'Rio ne phir “Nahi!” bol diya 😤😂',
    'Rio ki little adventures meri profile pe chal rahi hain 💙',
    'Rio ko samjhana = full-time job 😂💙',
    'Jahan Rio hai, wahan “Nahi!” toh hoga hi 😂',
    'Cuty ka solution? Pehle nap… phir problem solve 😴🐰😂',
    'Cuty peacefully sabki masti dekh raha hai 😂🐰',
    'Ria-Rio lad rahe hain, Cuty so raha hai… perfect balance 😂🐰',
    'Cuty ko duniya ki sabse important cheez pata hai — NAP 😴🐰❤️',
    'Meri profile ka sabse peaceful member = Cuty 🐰💤',
    'Cuty enters… aur pura drama suddenly cute ho jata hai 🐰❤️',
    'Cuty ko bas sone do, baaki Ria-Rio sambhal lenge 😂🐰',
    'Cuty ki sleepy masti miss mat karna 😴🐰',
    'Ria ki masti + Rio ki zidd + Cuty ki neend = meri daily story 😂❤️',
    'Ek Tofani, ek Ziddi, ek sleepy… aur ek ghar 😂🌸💙🐰',
    'Ria chaos create karti hai, Rio problem badhata hai, Cuty peace lata hai 😂❤️',
    'Meri profile pe teen personalities ki full masti chal rahi hai 🌸💙🐰',
    'Ria + Rio + Cuty = ghar mein kabhi boring nahi hota 😂❤️',
    'Teen little characters, har din ek nayi story 🌸💙🐰',
    'In teenon ko ek saath chhod do… story khud ban jaati hai 😂',
    'Ria aur Rio ka drama, Cuty ka nap — perfect combo 😂🐰',
    'Little characters, big masti ❤️ Ria, Rio & Cuty!',
    'Meri profile pe chhoti-chhoti stories aur full-on masti ❤️😂',
    'Aaj Ria ne jo kiya na… 😂 Profile pe story dekho!',
    'Rio ko aaj bhi “Nahi” bolna tha 😭😂',
    'Cuty ne aaj phir sabse unexpected kaam kiya 🐰😂',
    'In teenon ke saath normal day bhi adventure ban jata hai 😂',
    'Aaj ka Ria-Rio drama dekhke Mumma log relate karenge 😂❤️',
    'Bas ek baar Ria, Rio & Cuty se mil lo… phir yaad rahenge ❤️🐰',
    'Agar ghar mein toddler hai, Ria-Rio ki stories definitely relatable hongi 😂',
    'Parents ke liye ye little stories too relatable hain 😂❤️',
    'Meri profile pe abhi ek aisi story hai jo har parent relate karega 👀❤️',
    'Ria-Rio-Cuty ki little world mein roz kuch na kuch hota rehta hai 😂',
    'Our little world is growing one story at a time 🌱❤️',
    'Ria, Rio & Cuty ki little world mein aapka welcome hai 🥹❤️',
    'Little stories, little lessons, lots of masti 🌸🐰',
    'Humari little world mein har din ek nayi story hoti hai ❤️',
    'Ria-Rio-Cuty ke saath childhood ko thoda aur fun bana rahe hain 🌸❤️',
    'Chhoti stories, big little lessons ❤️🌱',
  ];

  static Future<File> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Load comments as PromoComment objects with bucket tags.
  static Future<List<PromoComment>> loadWithBuckets() async {
    try {
      final file = await _path();
      if (!await file.exists()) {
        return starterComments.map((s) => PromoComment.fromString(s)).toList();
      }
      final raw = jsonDecode(await file.readAsString());
      return decode(raw);
    } catch (_) {
      return starterComments.map((s) => PromoComment.fromString(s)).toList();
    }
  }

  static List<PromoComment> decode(dynamic raw) {
    if (raw is! List) {
      return starterComments.map((s) => PromoComment.fromString(s)).toList();
    }
    return raw
        .map((item) {
          if (item is String) return PromoComment.fromString(item);
          if (item is Map<String, dynamic>) return PromoComment.fromJson(item);
          return null;
        })
        .whereType<PromoComment>()
        .where((comment) => comment.text.isNotEmpty)
        .toList();
  }

  /// Backward-compatible: load as plain strings.
  static Future<List<String>> load() async {
    return (await loadWithBuckets()).map((c) => c.text).toList();
  }

  static Future<void> add(PromoComment comment) async {
    final list = await loadWithBuckets();
    list.insert(0, comment);
    await save(list.map((c) => c.toJson()).toList());
  }

  static Future<void> save(List<dynamic> comments) async {
    try {
      final file = await _path();
      await file.writeAsString(jsonEncode(comments));
    } catch (_) {}
  }
}

class PromoCommentVaultScreen extends StatefulWidget {
  const PromoCommentVaultScreen({super.key});

  @override
  State<PromoCommentVaultScreen> createState() =>
      _PromoCommentVaultScreenState();
}

class _PromoCommentVaultScreenState extends State<PromoCommentVaultScreen> {
  List<PromoComment> _comments = const [];
  String _selectedBucket = '';
  bool _loading = true;

  List<String> get _buckets =>
      _comments
          .map((comment) => comment.bucket)
          .where((bucket) => bucket.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  List<PromoComment> get _visibleComments => _selectedBucket.isEmpty
      ? _comments
      : _comments
            .where((comment) => comment.bucket == _selectedBucket)
            .toList();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await PromoCommentStore.loadWithBuckets();
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _copyComment(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Comment copied')));
  }

  Future<void> _addComment() async {
    final controller = TextEditingController();
    var bucket = '';
    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Add promotion comment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Comment text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: bucket,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('No category'),
                      ),
                      ...BucketLibrary.all.map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.emoji} ${item.name}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => bucket = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    final text = controller.text.trim();
    controller.dispose();
    if (!shouldSave || text.isEmpty) return;

    await PromoCommentStore.add(PromoComment(text: text, bucket: bucket));
    await _loadComments();
  }

  String _bucketLabel(String id) {
    final matches = BucketLibrary.all.where((bucket) => bucket.id == id);
    if (matches.isEmpty) return id;
    final bucket = matches.first;
    return '${bucket.emoji} ${bucket.name}';
  }

  @override
  Widget build(BuildContext context) {
    final comments = _visibleComments;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Comments'),
        actions: [
          IconButton(
            tooltip: 'Add comment',
            onPressed: _addComment,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_buckets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _bucketChip('', 'All'),
                        for (final bucket in _buckets)
                          _bucketChip(bucket, _bucketLabel(bucket)),
                      ],
                    ),
                  ),
                Expanded(
                  child: comments.isEmpty
                      ? const Center(
                          child: Text('No comments in this category yet.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  6,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: SelectableText(
                                            comment.text,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Copy comment',
                                          onPressed: () =>
                                              _copyComment(comment.text),
                                          icon: const Icon(Icons.copy_outlined),
                                        ),
                                      ],
                                    ),
                                    if (comment.bucket.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Chip(
                                          label: Text(
                                            _bucketLabel(comment.bucket),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _bucketChip(String bucket, String label) => FilterChip(
    label: Text(label),
    selected: _selectedBucket == bucket,
    onSelected: (_) => setState(() => _selectedBucket = bucket),
  );
}

String makeHashtags(String audience) {
  final normalized = audience.trim();
  final tags = <String>[];
  if (normalized.isEmpty) {
    tags.addAll(['#ParentingTips', '#ToddlerLife', '#KidsStories']);
  } else {
    tags.add('#ParentingTips');
    tags.add('#KidsStories');
    tags.add('#ToddlerLife');
    if (normalized.toLowerCase().contains('mom')) tags.add('#MomLife');
    if (normalized.toLowerCase().contains('dad')) tags.add('#DadLife');
  }
  return tags.toSet().join(' ');
}

List<String> makeCommentPack({
  required String postType,
  required String hook,
  required String audience,
  required String message,
  String bucket = '',
}) {
  final base = message.trim();
  final result = <String>[];
  final mom = 'This is my life right now 😭 and honestly, so relatable.';
  final nonMom =
      'This is not just a mom thing — this feels like real family life for so many of us.';
  final emoji = '😅😅😅 this is us every single day.';
  final truth =
      'So true. This is exactly the kind of moment that makes parenting feel real.';
  final cta = 'Which part of this feels most like your home? Tell me below 👇';

  final extra = base.isNotEmpty ? ' "$base"' : '';
  result.addAll(['This is so relatable$extra', mom, nonMom, emoji, truth, cta]);

  if (postType.toLowerCase() == 'static image' ||
      postType.toLowerCase() == 'carousel') {
    result[0] = 'This is exactly the kind of post I keep saving for later.';
  }

  if (audience.toLowerCase().contains('mom')) {
    result[1] = 'This is my life right now 😭 and honestly, I need this reminder today.';
  }

  if (audience.toLowerCase().contains('dad') ||
      audience.toLowerCase().contains('non')) {
    result[2] = 'This is relatable even outside mom life — real family chaos looks the same for everyone.';
  }

  // Bucket-specific comment styles — avoids repeating the same wording across every post
  if (bucket == 'challenge') {
    result[0] = 'My child spotted it right away! 🧩';
    result[1] = 'These observation games are so good for focus — saving this!';
    result[2] = 'Took me longer than my 4-year-old 😂 good one!';
    result[3] = 'More puzzles please, this was fun! 👀';
    result[4] = 'We found it! How fast did you spot it? ⏱️';
  } else if (bucket == 'humor') {
    result[0] = '😂😂😂 this is EXACTLY my house every day';
    result[1] = 'I need to print this and tape it to my forehead 😭';
    result[2] = 'My partner and I say this to each other on loop';
    result[3] = 'Tag a parent who needs to see this right now';
    result[4] = 'Be honest — what number are you on today? 👇';
  } else if (bucket == 'activity') {
    result[0] = 'Trying this tonight while dinner cooks — perfect timing!';
    result[1] = 'Love that this uses stuff already in my kitchen!';
    result[2] = 'My little one turned this into their own version 😂';
    result[3] = 'Simple enough that I can actually do it too';
    result[4] = 'Going straight into my saved activities — thank you!';
  } else if (bucket == 'conversation') {
    result[0] =
        'Trying this at bedtime tonight — can\'t wait to hear the answer!';
    result[1] = 'These questions open up the best conversations 💛';
    result[2] = 'Finally, actual questions instead of "how was your day?"';
    result[3] = 'My child said the most unexpected thing...';
    result[4] = 'More of these please, this is gold ✨';
  } else if (bucket == 'age_practice') {
    result[0] = 'Bookmarking this for when my little one hits this milestone';
    result[1] = 'So reassuring — not a race, just a guide ❤️';
    result[2] = 'My 3-year-old can do most of these already!';
    result[3] = 'Saving this to track progress over the next few months';
    result[4] = 'Such a helpful, non-stressful way to check in ✨';
  } else if (bucket == 'community') {
    result[0] = 'Loved the puzzles the most this week — more please!';
    result[1] = 'Honestly all of them were great, such a fun week!';
    result[2] = 'The humor reels made me laugh out loud 😂';
    result[3] = 'The skill checklists were genuinely useful for me';
    result[4] = 'Can we get more activities like the sock hunt?';
  }

  return result.take(5).toList();
}

String makeImagePrompt({
  required String title,
  required String hook,
  required String idea,
  required String visualStyle,
  required String audience,
  String contentGoal = '',
  String mood = '',
}) {
  final a = audience.isEmpty ? 'parents of preschool children' : audience;
  final style = visualStyle.isEmpty
      ? 'bright, warm, realistic family lifestyle'
      : visualStyle;
  final topic = idea.isEmpty ? 'a cute everyday family scene' : idea;
  final goal = contentGoal.isEmpty ? 'build connection' : contentGoal;
  final feeling = mood.isEmpty ? 'relatable' : mood;
  return 'Create a $style Instagram post illustration for $a. Theme: $topic. Goal: $goal. Mood: $feeling. Include the playful character energy of $hook. Make it warm, modern, and highly shareable. Keep the composition clean, polished, and suitable for a social media post. Title: $title.';
}

String makeCaption({
  required String title,
  required String hook,
  required String mainIdea,
  required String lesson,
  required String cta,
  required String hashtags,
}) {
  final text = <String>[
    hook.isNotEmpty ? hook : title,
    '',
    mainIdea.isEmpty ? 'A little moment from everyday family life.' : mainIdea,
    '',
    lesson.isEmpty
        ? 'Tiny moments really do build the biggest memories.'
        : lesson,
    '',
    cta.isEmpty ? 'Save this for the next time your child says no.' : cta,
    '',
    hashtags.isEmpty ? makeHashtags('Parents of 3-6 year olds') : hashtags,
  ];
  return text.join('\n');
}

/// A script and the image prompts that go with its beats.
///
/// Written together on purpose: the slides and the prompts come from one list, so a
/// seven-slide carousel cannot come back with five prompts, and no prompt can ever
/// describe a slide the script does not have.
class ScriptAndPrompts {
  final String script;
  final List<String> slidePrompts;

  const ScriptAndPrompts({required this.script, required this.slidePrompts});
}

/// How many frames a story is written in. A story is a short sequence rather than a
/// swipeable deck, so it does not follow the carousel's slide picker.
const kStoryFrames = kMinCarouselSlides;

ScriptAndPrompts buildScriptAndPrompts({
  required String title,
  required String postType,
  required String audience,
  required String hook,
  required String mainIdea,
  required String problem,
  required String lesson,
  required String visualStyle,
  required String cta,
  required String contentGoal,
  required String mood,
  int slideCount = kDefaultCarouselSlides,
}) {
  final type = postType.trim().toLowerCase();

  if (type == 'carousel' || type == 'story') {
    final isStory = type == 'story';
    final plan = planCarousel(
      title: title,
      hook: hook,
      mainIdea: mainIdea,
      problem: problem,
      lesson: lesson,
      cta: cta,
      slideCount: isStory ? kStoryFrames : slideCount,
      beatLabel: isStory ? 'Frame' : 'Slide',
      visualStyle: visualStyle,
      audience: audience,
      contentGoal: contentGoal,
      mood: mood,
    );
    return ScriptAndPrompts(script: plan.script, slidePrompts: plan.prompts);
  }

  if (type == 'reel') {
    final script = makeReelScript(
      hook: hook,
      mainIdea: mainIdea,
      lesson: lesson,
    );
    return ScriptAndPrompts(
      script: script,
      // One prompt per timeline moment, so the footage has a prompt of its own.
      slidePrompts: promptsForScript(
        script: script,
        title: title,
        visualStyle: visualStyle,
        audience: audience,
        contentGoal: contentGoal,
        mood: mood,
        postType: postType,
        beatLabel: 'Shot',
      ),
    );
  }

  // A static image is one picture, so there is nothing per slide to write and the
  // single prompt above it is the whole set.
  final single = hook.trim().isEmpty ? title.trim() : hook.trim();
  return ScriptAndPrompts(
    script: single.isEmpty ? '' : 'Single image: $single',
    slidePrompts: const [],
  );
}

/// The reel timeline: five moments, four seconds apart.
String makeReelScript({
  required String hook,
  required String mainIdea,
  required String lesson,
}) {
  final title = hook.isEmpty ? 'Daily Family Drama' : hook;
  final base = mainIdea.isEmpty
      ? 'A normal morning turns into a small family challenge.'
      : mainIdea;
  final message = lesson.isEmpty ? 'Little moments teach big lessons.' : lesson;
  return '0:00 $title\n0:04 $base\n0:08 Everyone reacts differently\n'
      '0:12 Then the tiny lesson appears\n0:16 $message';
}

/// The script on its own, for a caller that does not need the prompts.
///
/// Delegates rather than writing its own slides, so there is exactly one writer and
/// the script and the prompt list can never drift apart.
String makeScript({
  required String hook,
  required String mainIdea,
  required String lesson,
  required String postType,
  String problem = '',
  String cta = '',
  int slideCount = kDefaultCarouselSlides,
}) => buildScriptAndPrompts(
  title: hook,
  postType: postType,
  audience: '',
  hook: hook,
  mainIdea: mainIdea,
  problem: problem,
  lesson: lesson,
  visualStyle: '',
  cta: cta,
  contentGoal: '',
  mood: '',
  slideCount: slideCount,
).script;

QuickIdea buildQuickIdea({
  required String title,
  required String postType,
  required String audience,
  required String hook,
  required String mainIdea,
  required String problem,
  required String lesson,
  required String visualStyle,
  required String cta,
  required String contentGoal,
  required String mood,
  int slideCount = kDefaultCarouselSlides,
  String bucket = '',
}) {
  final pack = buildScriptAndPrompts(
    title: title,
    postType: postType,
    audience: audience,
    hook: hook,
    mainIdea: mainIdea,
    problem: problem,
    lesson: lesson,
    visualStyle: visualStyle,
    cta: cta,
    contentGoal: contentGoal,
    mood: mood,
    slideCount: slideCount,
  );

  // The single Image prompt box shows the cover, so what sits beside the slide list
  // is the first entry of that same list rather than a second, vaguer description.
  final imagePrompt = pack.slidePrompts.isNotEmpty
      ? pack.slidePrompts.first
      : makeImagePrompt(
          title: title,
          hook: hook,
          idea: mainIdea.isEmpty ? problem : mainIdea,
          visualStyle: visualStyle,
          audience: audience,
          contentGoal: contentGoal,
          mood: mood,
        );
  final hashtags = makeHashtags(audience);
  final caption = makeCaption(
    title: title,
    hook: hook,
    mainIdea: mainIdea,
    lesson: lesson,
    cta: cta,
    hashtags: hashtags,
  );
  final comments = makeCommentPack(
    postType: postType,
    hook: hook,
    audience: audience,
    message: mainIdea,
    bucket: bucket,
  );
  final script = pack.script;

  return QuickIdea(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: title.isEmpty ? 'New post idea' : title,
    postType: postType.isEmpty ? 'Carousel' : postType,
    audience: audience.isEmpty ? 'Parents of 3-6 year olds' : audience,
    contentGoal: contentGoal.isEmpty ? 'Build connection' : contentGoal,
    mood: mood.isEmpty ? 'Relatable' : mood,
    hook: hook,
    mainIdea: mainIdea,
    problem: problem,
    lesson: lesson,
    visualStyle: visualStyle,
    imagePrompt: imagePrompt,
    caption: caption,
    cta: cta,
    hashtags: hashtags,
    comments: comments,
    script: script,
    slidePrompts: pack.slidePrompts,
    createdAt: DateTime.now(),
    bucket: bucket,
  );
}

class QuickContentScreen extends StatefulWidget {
  final AIProvider? aiProvider;

  const QuickContentScreen({super.key, this.aiProvider});

  @override
  State<QuickContentScreen> createState() => _QuickContentScreenState();
}

class _QuickContentScreenState extends State<QuickContentScreen> {
  final _titleCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController(text: 'Parents of 3-6 year olds');
  final _goalCtrl = TextEditingController(text: 'Build connection');
  final _moodCtrl = TextEditingController(text: 'Relatable');
  final _hookCtrl = TextEditingController();
  final _ideaCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _lessonCtrl = TextEditingController();
  final _styleCtrl = TextEditingController(
    text: 'Bright, warm, playful family lifestyle',
  );
  final _ctaCtrl = TextEditingController(text: 'Save this for later');
  final _imagePromptCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _scriptCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();
  final _pinCommentCtrl = TextEditingController();

  List<String> _comments = [];
  List<QuickIdea> _savedIdeas = [];
  List<QuickIdea> _history = [];
  bool _loading = true;

  String _postType = 'Carousel';
  String _bucketValue = '';

  /// The slide count the next Generate writes, picked from the dropdown. Kept apart
  /// from a loaded post's own slide count, so this is never a value the dropdown
  /// does not offer.
  int _slideCount = kDefaultCarouselSlides;

  // AI Provider for content generation
  AIProvider? _aiProvider;
  bool _generatingAllFormats = false;

  @override
  void initState() {
    super.initState();
    _aiProvider = widget.aiProvider;
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final results = await Future.wait([
      QuickIdeaStore.load(),
      QuickHistoryStore.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _savedIdeas = results[0] as List<QuickIdea>;
      _history = results[1] as List<QuickIdea>;
      _loading = false;
    });
  }

  /// The per-slide prompts for whatever is on screen right now.
  ///
  /// Derived from the script rather than stored, so the prompts always describe the
  /// slides actually being looked at. A carousel just generated, one opened from the
  /// saved library and one pasted in as text all come through here, which is why none
  /// of them can end up with a prompt list that does not match its script.
  List<String> get _slidePrompts => promptsForScript(
    script: _scriptCtrl.text,
    title: _titleCtrl.text,
    visualStyle: _styleCtrl.text,
    audience: _audienceCtrl.text,
    contentGoal: _goalCtrl.text,
    mood: _moodCtrl.text,
    postType: _postType,
    beatLabel: _beatLabelFor(_postType),
  );

  /// What one beat is called in a format: a carousel has slides, a story has frames
  /// and a reel has shots.
  String _beatLabelFor(String postType) {
    final type = postType.trim().toLowerCase();
    if (type == 'story') return 'Frame';
    if (type == 'reel') return 'Shot';
    return 'Slide';
  }

  Future<void> _generatePack() async {
    final idea = buildQuickIdea(
      title: _titleCtrl.text,
      postType: _postType,
      audience: _audienceCtrl.text,
      contentGoal: _goalCtrl.text,
      mood: _moodCtrl.text,
      hook: _hookCtrl.text,
      mainIdea: _ideaCtrl.text,
      problem: _problemCtrl.text,
      lesson: _lessonCtrl.text,
      visualStyle: _styleCtrl.text,
      cta: _ctaCtrl.text,
      slideCount: _slideCount,
      bucket: _bucketValue,
    );

    _imagePromptCtrl.text = idea.imagePrompt;
    _captionCtrl.text = idea.caption;
    _scriptCtrl.text = idea.script;
    _hashtagsCtrl.text = idea.hashtags;
    _pinCommentCtrl.text = idea.comments.first;
    _comments = idea.comments;

    await QuickHistoryStore.add(idea);
    _history = [idea, ..._history].take(50).toList();

    setState(() {});
  }

  Future<void> _generateAllFormats() async {
    if (_ideaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an idea first')),
      );
      return;
    }

    if (_aiProvider == null || !_aiProvider!.isAvailable) {
      // Fallback to template generation
      final bucket = _bucketValue.isNotEmpty
          ? BucketLibrary.byId(_bucketValue) ?? BucketLibrary.challenge
          : BucketLibrary.challenge;

      final pkg = await ContentGenerator.generate(
        idea: _ideaCtrl.text,
        bucket: bucket,
        format: ContentFormat.carousel,
        characters: CharacterLibrary.all,
        slideCount: _slideCount,
      );

      final formats = FormatAdapter.adaptAll(pkg);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PostingPackScreen(formats: formats, originalPackage: pkg),
        ),
      );
      return;
    }

    setState(() => _generatingAllFormats = true);

    try {
      final bucket = _bucketValue.isNotEmpty
          ? BucketLibrary.byId(_bucketValue) ?? BucketLibrary.challenge
          : BucketLibrary.challenge;

      final input = IdeaInput(
        topic: _ideaCtrl.text,
        bucket: bucket,
        targetFormats: ContentFormat.values,
        brand: BrandContext.defaultContext(),
        characters: CharacterLibrary.all,
        slideCount: _slideCount,
      );

      final pkg = await _aiProvider!.generate(input);
      final formats = FormatAdapter.adaptAll(pkg);

      if (!mounted) return;

      // Run quality check
      final report = QualityChecker.check(pkg, formats);

      if (!report.isReadyToPost && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Quality Check: Issues Found'),
            content: Text(
              '${report.failCount} critical issues, ${report.warnCount} warnings. Continue anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Review First'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PostingPackScreen(formats: formats, originalPackage: pkg),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Generation failed: $e')));
    } finally {
      if (mounted) setState(() => _generatingAllFormats = false);
    }
  }

  void _loadFrom14DayPost(QuickIdea post) {
    _titleCtrl.text = post.title;
    _postType = post.postType;
    _audienceCtrl.text = post.audience;
    _goalCtrl.text = post.contentGoal.isEmpty
        ? 'Build connection'
        : post.contentGoal;
    _moodCtrl.text = post.mood;
    _hookCtrl.text = post.hook;
    _ideaCtrl.text = post.mainIdea;
    _problemCtrl.text = post.problem;
    _lessonCtrl.text = post.lesson;
    _styleCtrl.text = post.visualStyle;
    _ctaCtrl.text = post.cta;
    _imagePromptCtrl.text = post.imagePrompt;
    _captionCtrl.text = post.caption;
    _scriptCtrl.text = post.script;
    _hashtagsCtrl.text = post.hashtags;
    _pinCommentCtrl.text = post.comments.isNotEmpty ? post.comments.first : '';
    _comments = post.comments;
    _bucketValue = post.bucket;
    setState(() {});
  }

  Future<void> _pick14DayPost() async {
    final chosen = await showModalBottomSheet<QuickIdea>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (sheetCtx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('14-Day Test', style: AppText.screenTitle),
            Gap.s,
            const Text(
              'Pre-built post packages. Tap one to load into Quick Content Studio.',
              style: AppText.hint,
            ),
            Gap.m,
            ...ideas.kDay14Posts.map(
              (post) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        ideas.bucketById(post.bucket)?.color ??
                        AppColors.accent,
                    child: Text(
                      post.id.substring(4).substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    post.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${post.postType} • ${ideas.bucketLabel(post.bucket)}\n${post.hook}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.hint,
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(sheetCtx, post),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) _loadFrom14DayPost(chosen);
  }

  Future<void> _bulkPaste() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste full post package'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your complete post package text below. It will be split into the '
                'fields automatically.',
                style: AppText.hint,
              ),
              Gap.s,
              TextField(
                controller: ctrl,
                minLines: 8,
                maxLines: 20,
                style: AppText.body,
                decoration: const InputDecoration(
                  hintText:
                      'Title: ...\nPost Type: ...\n--- Image Prompt ---\n...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Paste'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final parsed = ideas.parseBulkPaste(ctrl.text);
    if (!parsed.hasAnyContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fields found in the pasted text')),
      );
      return;
    }

    _titleCtrl.text = parsed.title;
    _postType = parsed.postType;
    _audienceCtrl.text = parsed.audience;
    _goalCtrl.text = parsed.contentGoal;
    _moodCtrl.text = parsed.mood;
    _hookCtrl.text = parsed.hook;
    _ideaCtrl.text = parsed.mainIdea;
    _problemCtrl.text = parsed.problem;
    _lessonCtrl.text = parsed.lesson;
    _styleCtrl.text = parsed.visualStyle;
    _ctaCtrl.text = parsed.cta;
    _imagePromptCtrl.text = parsed.imagePrompt;
    _captionCtrl.text = parsed.caption;
    _scriptCtrl.text = parsed.script;
    _hashtagsCtrl.text = parsed.hashtags;
    _pinCommentCtrl.text = parsed.pinnedComment;
    _comments = parsed.replyComments;
    _bucketValue = parsed.bucket;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post package parsed and filled.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _saveIdea() async {
    final idea = buildQuickIdea(
      title: _titleCtrl.text,
      postType: _postType,
      audience: _audienceCtrl.text,
      contentGoal: _goalCtrl.text,
      mood: _moodCtrl.text,
      hook: _hookCtrl.text,
      mainIdea: _ideaCtrl.text,
      problem: _problemCtrl.text,
      lesson: _lessonCtrl.text,
      visualStyle: _styleCtrl.text,
      cta: _ctaCtrl.text,
      // The slide count that is on screen wins, so saving never rebuilds a different
      // number of slides than the one being looked at.
      slideCount: _slidePrompts.isEmpty ? _slideCount : _slidePrompts.length,
      bucket: _bucketValue,
    );

    final fullIdea = QuickIdea(
      id: idea.id,
      title: idea.title,
      postType: idea.postType,
      audience: idea.audience,
      contentGoal: idea.contentGoal,
      mood: idea.mood,
      hook: idea.hook,
      mainIdea: idea.mainIdea,
      problem: idea.problem,
      lesson: idea.lesson,
      visualStyle: idea.visualStyle,
      imagePrompt: _imagePromptCtrl.text.isEmpty
          ? idea.imagePrompt
          : _imagePromptCtrl.text,
      caption: _captionCtrl.text.isEmpty ? idea.caption : _captionCtrl.text,
      cta: _ctaCtrl.text,
      hashtags: _hashtagsCtrl.text.isEmpty ? idea.hashtags : _hashtagsCtrl.text,
      comments: _comments.isEmpty ? idea.comments : _comments,
      script: _scriptCtrl.text.isEmpty ? idea.script : _scriptCtrl.text,
      slidePrompts: _slidePrompts.isEmpty ? idea.slidePrompts : _slidePrompts,
      createdAt: DateTime.now(),
      bucket: _bucketValue,
    );

    await QuickIdeaStore.add(fullIdea);
    await _loadSaved();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Idea saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteSavedIdea(QuickIdea idea) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete saved idea?'),
            content: Text('“${idea.title}” will be removed from Saved ideas.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await QuickIdeaStore.delete(idea.id);
    if (!mounted) return;
    setState(() => _savedIdeas.removeWhere((saved) => saved.id == idea.id));
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Saved idea deleted')));
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _audienceCtrl.dispose();
    _goalCtrl.dispose();
    _moodCtrl.dispose();
    _hookCtrl.dispose();
    _ideaCtrl.dispose();
    _problemCtrl.dispose();
    _lessonCtrl.dispose();
    _styleCtrl.dispose();
    _ctaCtrl.dispose();
    _imagePromptCtrl.dispose();
    _captionCtrl.dispose();
    _scriptCtrl.dispose();
    _hashtagsCtrl.dispose();
    _pinCommentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Content Studio'),
        actions: [
          if (_savedIdeas.isNotEmpty)
            IconButton(
              tooltip: 'Saved ideas',
              icon: const Icon(Icons.bookmark_outline),
              onPressed: () => _showSavedIdeas(),
            ),
          if (_history.isNotEmpty)
            IconButton(
              tooltip: 'Post history',
              icon: const Icon(Icons.history),
              onPressed: () => _showHistory(),
            ),
          IconButton(
            tooltip: 'Load 14-Day Test',
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _pick14DayPost,
          ),
          IconButton(
            tooltip: 'Bulk paste',
            icon: const Icon(Icons.paste_rounded),
            onPressed: _bulkPaste,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: const Text(
                          'Quick post pack',
                          style: AppText.screenTitle,
                        ),
                      ),
                      if (_savedIdeas.isNotEmpty)
                        Text(
                          '${_savedIdeas.length} saved',
                          style: AppText.small,
                        ),
                    ],
                  ),
                  Gap.s,
                  const Text(
                    'Create a prompt, caption, comments and script without entering the full reel flow.',
                    style: AppText.hint,
                  ),
                  Gap.m,

                  const Text('1  BUILD THE BRIEF', style: AppText.section),
                  Gap.s,
                  const Text(
                    'Choose the format, audience and feeling first. The outputs below will follow this brief.',
                    style: AppText.hint,
                  ),
                  Gap.s,
                  const Text('Post type', style: AppText.section),
                  Gap.s,
                  DropdownButtonFormField<String>(
                    value: _postType,
                    items: const [
                      DropdownMenuItem(
                        value: 'Carousel',
                        child: Text('Carousel'),
                      ),
                      DropdownMenuItem(
                        value: 'Static Image',
                        child: Text('Static Image'),
                      ),
                      DropdownMenuItem(value: 'Reel', child: Text('Reel')),
                      DropdownMenuItem(value: 'Story', child: Text('Story')),
                    ],
                    onChanged: (v) =>
                        setState(() => _postType = v ?? 'Carousel'),
                  ),
                  Gap.m,

                  if (_postType == 'Carousel') ...[
                    const Text('Slide count', style: AppText.section),
                    Gap.s,
                    DropdownButtonFormField<int>(
                      value: _slideCount,
                      items: kCarouselSlideOptions
                          .map(
                            (count) => DropdownMenuItem(
                              value: count,
                              child: Text('$count slides'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _slideCount = v ?? kDefaultCarouselSlides,
                      ),
                    ),
                    Gap.m,
                  ],

                  _field('Title', _titleCtrl),
                  _field('Audience', _audienceCtrl),
                  _field('Content goal', _goalCtrl),
                  _field('Mood / emotion', _moodCtrl),
                  _field('Hook / cover text', _hookCtrl),
                  _field('Main idea', _ideaCtrl),
                  _field('Problem', _problemCtrl),
                  _field('Lesson / takeaway', _lessonCtrl),
                  _field('Visual style', _styleCtrl),
                  _field('CTA', _ctaCtrl),
                  Gap.s,
                  const Text('Content bucket', style: AppText.section),
                  Gap.s,
                  DropdownButtonFormField<String>(
                    value: _bucketValue.isEmpty ? null : _bucketValue,
                    hint: const Text('Choose a bucket (optional)'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('None')),
                      ...ideas.kContentBuckets.map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: b.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(b.shortLabel),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _bucketValue = v ?? ''),
                  ),

                  Gap.m,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _generatePack,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate post pack'),
                    ),
                  ),
                  Gap.s,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _generatingAllFormats
                          ? null
                          : _generateAllFormats,
                      icon: _generatingAllFormats
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_mosaic),
                      label: Text(
                        _generatingAllFormats
                            ? 'Generating All Formats...'
                            : 'Generate All Formats (AI)',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ),
                  Gap.m,

                  const Text('2  READY TO COPY', style: AppText.section),
                  Gap.s,
                  const Text(
                    'Generate once, then copy only the piece you need for your next post.',
                    style: AppText.hint,
                  ),
                  Gap.s,
                  _readOnlyBox(
                    'Image prompt',
                    _imagePromptCtrl,
                    () => _copy(_imagePromptCtrl.text, 'Image prompt'),
                  ),
                  _readOnlyBox(
                    'Caption',
                    _captionCtrl,
                    () => _copy(_captionCtrl.text, 'Caption'),
                  ),
                  _readOnlyBox(
                    'Script / carousel text',
                    _scriptCtrl,
                    () => _copy(_scriptCtrl.text, 'Script'),
                  ),
                  _readOnlyBox(
                    'Hashtags',
                    _hashtagsCtrl,
                    () => _copy(_hashtagsCtrl.text, 'Hashtags'),
                  ),

                  // ── Slide image prompts (carousel / story / reel) ──────────────
                  if (_postType.toLowerCase() != 'static image' &&
                      _slidePrompts.isNotEmpty)
                    _buildSlidePromptsSection(),

                  const SizedBox(height: 16),
                  const Text('Pin comment', style: AppText.section),
                  _commentBox(_pinCommentCtrl, _pinCommentCtrl.text),
                  const SizedBox(height: 16),
                  const Text('Reply comments', style: AppText.section),
                  if (_comments.isEmpty)
                    const Text(
                      'Generate a pack to see five different replies.',
                      style: AppText.hint,
                    )
                  else
                    ..._comments.asMap().entries.map((entry) {
                      final i = entry.key;
                      final comment = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}. ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(child: Text(comment, style: AppText.body)),
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  _copy(comment, 'Comment ${i + 1}'),
                              icon: const Icon(
                                Icons.copy_all_outlined,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  Gap.m,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveIdea,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save idea'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _copy(
                            [
                              'Title: ${_titleCtrl.text}',
                              'Hook: ${_hookCtrl.text}',
                              'Prompt: ${_imagePromptCtrl.text}',
                              if (_postType.toLowerCase() != 'static image' &&
                                  _slidePrompts.isNotEmpty)
                                'All slide prompts: ${_slidePrompts.asMap().entries.map((e) => 'Slide ${e.key + 1}: ${e.value}').join(' | ')}',
                              'Caption: ${_captionCtrl.text}',
                              'Comments: ${_comments.join(' | ')}',
                              'Script: ${_scriptCtrl.text}',
                              'Hashtags: ${_hashtagsCtrl.text}',
                            ].join('\n\n'),
                            'All pack',
                          ),
                          icon: const Icon(Icons.copy_all),
                          label: const Text('Copy all'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.section),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: label.contains('Main idea') || label.contains('Lesson')
              ? 3
              : 1,
          decoration: const InputDecoration(),
        ),
      ],
    ),
  );

  Widget _readOnlyBox(
    String label,
    TextEditingController controller,
    VoidCallback onCopy,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppText.section)),
            IconButton(
              tooltip: 'Copy $label',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_all_outlined, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          minLines: 3,
          maxLines: 7,
        ),
      ],
    ),
  );

  /// Builds the per-slide image prompt list for carousel / story / reel posts.
  ///
  /// Each prompt gets its own copy button, and the whole set is copyable at once.
  Widget _buildSlidePromptsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Slide image prompts (${_slidePrompts.length})',
              style: AppText.section,
            ),
          ),
          IconButton(
            tooltip: 'Copy all slide prompts',
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            onPressed: () => _copy(
              _slidePrompts
                  .asMap()
                  .entries
                  .map((e) => 'Slide ${e.key + 1}:\n${e.value}')
                  .join('\n\n'),
              'All slide prompts',
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ..._slidePrompts.asMap().entries.map((entry) {
        final i = entry.key;
        final prompt = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${i + 1} of ${_slidePrompts.length}', style: AppText.hint),
              const SizedBox(height: 4),
              Text(prompt, style: AppText.body),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Copy slide ${i + 1} prompt',
                  icon: const Icon(Icons.copy_all_outlined, size: 16),
                  onPressed: () => _copy(prompt, 'Slide ${i + 1} prompt'),
                ),
              ),
            ],
          ),
        );
      }),
    ],
  );

  Widget _commentBox(TextEditingController controller, String initialText) =>
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Pin comment'),
            ),
          ),
          IconButton(
            onPressed: () => _copy(controller.text, 'Pin comment'),
            icon: const Icon(Icons.copy_all_outlined),
          ),
        ],
      );

  Future<void> _showSavedIdeas() async {
    if (_savedIdeas.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (sheetContext, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Saved ideas', style: AppText.screenTitle),
            Gap.s,
            ..._savedIdeas.map(
              (idea) => Card(
                child: ListTile(
                  leading: (idea.bucket.isNotEmpty)
                      ? CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              ideas.bucketById(idea.bucket)?.color ??
                              AppColors.accent,
                          child: Text(
                            ideas.bucketLabel(idea.bucket)[0],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primarySoft,
                          child: const Icon(
                            Icons.lightbulb,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                  title: Row(
                    children: [
                      Expanded(child: Text(idea.title)),
                      if (idea.bucket.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            ideas.bucketLabel(idea.bucket),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  ideas.bucketById(idea.bucket)?.color ??
                                  AppColors.textSoft,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text('${idea.postType} • ${idea.audience}'),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Saved idea actions',
                    onSelected: (action) {
                      if (action == 'copy') {
                        _copy(
                          [
                            'Title: ${idea.title}',
                            'Hook: ${idea.hook}',
                            'Caption: ${idea.caption}',
                            'Prompt: ${idea.imagePrompt}',
                            'Comments: ${idea.comments.join(' | ')}',
                            if (idea.script.isNotEmpty)
                              'Script: ${idea.script}',
                            if (idea.hashtags.isNotEmpty)
                              'Hashtags: ${idea.hashtags}',
                          ].join('\n\n'),
                          'Saved idea',
                        );
                      } else if (action == 'delete') {
                        _deleteSavedIdea(idea);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy_outlined),
                            SizedBox(width: 12),
                            Text('Copy'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 12),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _titleCtrl.text = idea.title;
                    _postType = idea.postType;
                    _audienceCtrl.text = idea.audience;
                    _hookCtrl.text = idea.hook;
                    _ideaCtrl.text = idea.mainIdea;
                    _problemCtrl.text = idea.problem;
                    _lessonCtrl.text = idea.lesson;
                    _styleCtrl.text = idea.visualStyle;
                    _goalCtrl.text = idea.contentGoal;
                    _moodCtrl.text = idea.mood;
                    _ctaCtrl.text = idea.cta;
                    _imagePromptCtrl.text = idea.imagePrompt;
                    _captionCtrl.text = idea.caption;
                    _scriptCtrl.text = idea.script;
                    _hashtagsCtrl.text = idea.hashtags;
                    _pinCommentCtrl.text = idea.comments.isNotEmpty
                        ? idea.comments.first
                        : '';
                    _comments = idea.comments;
                    _bucketValue = idea.bucket;
                    _slideCount = _slidePrompts.isNotEmpty
                        ? _slidePrompts.length.clamp(
                            kMinCarouselSlides,
                            kMaxCarouselSlides,
                          )
                        : _slideCount;
                    setState(() {});
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHistory() async {
    if (_history.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (sheetContext, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Post history', style: AppText.screenTitle),
            Gap.s,
            const Text(
              'Generated carousel, static-image, story, and reel packs stay here automatically.',
              style: AppText.hint,
            ),
            Gap.m,
            ..._history.map(
              (idea) => Card(
                child: ListTile(
                  leading: Icon(
                    idea.postType == 'Carousel'
                        ? Icons.view_carousel_outlined
                        : idea.postType == 'Reel'
                        ? Icons.play_arrow_outlined
                        : Icons.image_outlined,
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(idea.title)),
                      if (idea.bucket.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            ideas.bucketLabel(idea.bucket),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  ideas.bucketById(idea.bucket)?.color ??
                                  AppColors.textSoft,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${idea.postType} • ${idea.createdAt.toLocal()}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Copy history item',
                    icon: const Icon(Icons.copy_all_outlined),
                    onPressed: () => _copy(
                      'Title: ${idea.title}\n\nCaption: ${idea.caption}\n\nPrompt: ${idea.imagePrompt}\n\nScript: ${idea.script}',
                      'History item',
                    ),
                  ),
                  onTap: () {
                    _titleCtrl.text = idea.title;
                    _postType = idea.postType;
                    _audienceCtrl.text = idea.audience;
                    _goalCtrl.text = idea.contentGoal;
                    _moodCtrl.text = idea.mood;
                    _hookCtrl.text = idea.hook;
                    _ideaCtrl.text = idea.mainIdea;
                    _problemCtrl.text = idea.problem;
                    _lessonCtrl.text = idea.lesson;
                    _styleCtrl.text = idea.visualStyle;
                    _ctaCtrl.text = idea.cta;
                    _imagePromptCtrl.text = idea.imagePrompt;
                    _captionCtrl.text = idea.caption;
                    _scriptCtrl.text = idea.script;
                    _hashtagsCtrl.text = idea.hashtags;
                    _pinCommentCtrl.text = idea.comments.isNotEmpty
                        ? idea.comments.first
                        : '';
                    _comments = idea.comments;
                    _bucketValue = idea.bucket;
                    _slideCount = _slidePrompts.isNotEmpty
                        ? _slidePrompts.length.clamp(
                            kMinCarouselSlides,
                            kMaxCarouselSlides,
                          )
                        : _slideCount;
                    setState(() {});
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Carousel Maker Screen - Simplified: enter idea, get carousel prompts
// ============================================================================

class CarouselMakerScreen extends StatefulWidget {
  const CarouselMakerScreen({super.key});
  @override
  State<CarouselMakerScreen> createState() => _CarouselMakerScreenState();
}

class _CarouselMakerScreenState extends State<CarouselMakerScreen> {
  final _titleCtrl = TextEditingController();
  final _ideaCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController(text: 'Parents of 3-6 year olds');
  final _visualStyleCtrl = TextEditingController(
    text: 'Bright, warm, playful preschool lifestyle',
  );
  final _moodCtrl = TextEditingController(text: 'Relatable / Playful');
  int _slideCount = kDefaultCarouselSlides;
  List<String> _slidePrompts = [];
  List<String> _slideTexts = [];
  bool _generating = false;

  Future<void> _generate() async {
    if (_titleCtrl.text.trim().isEmpty || _ideaCtrl.text.trim().isEmpty) return;
    setState(() => _generating = true);

    final plan = planCarousel(
      title: _titleCtrl.text.trim(),
      hook: _titleCtrl.text.trim(),
      mainIdea: _ideaCtrl.text.trim(),
      problem: '',
      lesson: '',
      cta: 'Save this for later',
      slideCount: _slideCount,
      visualStyle: _visualStyleCtrl.text.trim(),
      audience: _audienceCtrl.text.trim(),
      contentGoal: 'Build connection',
      mood: _moodCtrl.text.trim(),
    );

    setState(() {
      _slideTexts = plan.slides;
      _slidePrompts = plan.prompts;
      _generating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carousel Maker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'What is your carousel about?',
            style: AppText.screenTitle,
          ),
          Gap.s,
          _field('Title / Hook', _titleCtrl),
          _field('Main Idea', _ideaCtrl),
          _field('Target Audience', _audienceCtrl),
          _field('Visual Style', _visualStyleCtrl),
          _field('Mood / Emotion', _moodCtrl),
          Gap.s,
          DropdownButtonFormField<int>(
            value: _slideCount,
            items: kCarouselSlideOptions
                .map(
                  (c) => DropdownMenuItem(value: c, child: Text('$c slides')),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _slideCount = v ?? kDefaultCarouselSlides),
            decoration: const InputDecoration(labelText: 'Slide count'),
          ),
          Gap.m,
          FilledButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _generating ? 'Generating...' : 'Generate Carousel Prompts',
            ),
          ),
          Gap.l,
          if (_slidePrompts.isNotEmpty) ...[
            const Text('Generated Slide Prompts', style: AppText.section),
            Gap.s,
            ..._slidePrompts.asMap().entries.map((entry) {
              final i = entry.key;
              final prompt = entry.value;
              final text = i < _slideTexts.length ? _slideTexts[i] : '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Slide ${i + 1}: $text', style: AppText.body),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(prompt, style: AppText.hint),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy prompt',
                          onPressed: () =>
                              _copy(prompt, 'Carousel Slide ${i + 1} Prompt'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Gap.m,
            FilledButton.icon(
              onPressed: () => _copy(
                _slidePrompts
                    .asMap()
                    .entries
                    .map((e) => 'Slide ${e.key + 1}:\n${e.value}')
                    .join('\n\n'),
                'All Carousel Prompts',
              ),
              icon: const Icon(Icons.copy_all),
              label: const Text('Copy All Prompts'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.section),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: label.contains('Idea') ? 3 : 1,
          decoration: const InputDecoration(),
        ),
      ],
    ),
  );

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ============================================================================
// Content Quality Check — Actionable pre-export validation
// ============================================================================

enum QualitySeverity {
  pass('✅', 'Pass', const Color(0xFF2E7D32)),
  warn('⚠️', 'Improve', AppColors.warning),
  fail('❌', 'Fix Required', AppColors.danger);

  final String icon;
  final String label;
  final Color color;

  const QualitySeverity(this.icon, this.label, this.color);
}

// ============================================================================
// Content Quality Check — Actionable pre-export validation
// ============================================================================

class QualityCheck {
  final String id;
  final String title;
  final String description;
  final QualitySeverity severity;
  final String? fixHint;

  const QualityCheck({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.fixHint,
  });

  bool get isPass => severity == QualitySeverity.pass;
  bool get isWarn => severity == QualitySeverity.warn;
  bool get isFail => severity == QualitySeverity.fail;
}

class ContentQualityChecker {
  static List<QualityCheck> check(ContentPackage pkg) {
    final checks = <QualityCheck>[];

    // 1. Hook length check
    final hookWords = pkg.hook.split(' ').length;
    if (hookWords <= 8) {
      checks.add(
        QualityCheck(
          id: 'hook_length',
          title: 'Hook Length',
          description: 'Hook is $hookWords words — optimal for stopping scroll',
          severity: QualitySeverity.pass,
        ),
      );
    } else if (hookWords <= 12) {
      checks.add(
        QualityCheck(
          id: 'hook_length',
          title: 'Hook Length',
          description:
              'Hook is $hookWords words — consider shortening to ≤8 words',
          severity: QualitySeverity.warn,
          fixHint: 'Regenerate hook with "Simpler" style',
        ),
      );
    } else {
      checks.add(
        QualityCheck(
          id: 'hook_length',
          title: 'Hook Length',
          description: 'Hook is $hookWords words — too long, will get cut off',
          severity: QualitySeverity.fail,
          fixHint: 'Regenerate hook with "Simpler" style',
        ),
      );
    }

    // 2. Slide text density check
    final denseSlides = <int>[];
    for (final slide in pkg.slides) {
      final wordCount = slide.body.split(' ').length;
      if (wordCount > 30) denseSlides.add(slide.index + 1);
    }
    if (denseSlides.isEmpty) {
      checks.add(
        QualityCheck(
          id: 'slide_density',
          title: 'Slide Text Density',
          description: 'All slides have readable text amounts (≤30 words)',
          severity: QualitySeverity.pass,
        ),
      );
    } else {
      checks.add(
        QualityCheck(
          id: 'slide_density',
          title: 'Slide Text Density',
          description:
              'Slides ${denseSlides.join(', ')} have >30 words — text may be too small',
          severity: QualitySeverity.warn,
          fixHint: 'Regenerate slides with "Simpler" or "More Visual" style',
        ),
      );
    }

    // 3. Character visibility check
    final charNames = pkg.characters.map((c) => c.name.toLowerCase()).toList();
    final promptText = pkg.visualPrompts.join(' ').toLowerCase();
    final visibleChars = charNames
        .where((name) => promptText.contains(name))
        .toList();
    if (visibleChars.length == pkg.characters.length) {
      checks.add(
        QualityCheck(
          id: 'character_visibility',
          title: 'Character Visibility',
          description:
              'All ${pkg.characters.length} characters (${charNames.join(', ')}) appear in visual prompts',
          severity: QualitySeverity.pass,
        ),
      );
    } else {
      final missing = charNames
          .where((name) => !promptText.contains(name))
          .toList();
      checks.add(
        QualityCheck(
          id: 'character_visibility',
          title: 'Character Visibility',
          description: 'Missing characters in prompts: ${missing.join(', ')}',
          severity: QualitySeverity.fail,
          fixHint: 'Regenerate visual prompts with "More Visual" style — ensures Character Lock injection',
        ),
      );
    }

    // 4. CTA presence
    if (pkg.cta.trim().isNotEmpty) {
      checks.add(
        QualityCheck(
          id: 'cta_presence',
          title: 'Call to Action',
          description: 'CTA present: "${pkg.cta}"',
          severity: QualitySeverity.pass,
        ),
      );
    } else {
      checks.add(
        QualityCheck(
          id: 'cta_presence',
          title: 'Call to Action',
          description: 'No CTA found — engagement will suffer',
          severity: QualitySeverity.fail,
          fixHint: 'Regenerate CTA or add manually',
        ),
      );
    }

    // 5. Hashtag count (exactly 5)
    if (pkg.hashtags.length == 5) {
      checks.add(
        QualityCheck(
          id: 'hashtag_count',
          title: 'Hashtag Count',
          description: 'Exactly 5 hashtags — optimal for Instagram',
          severity: QualitySeverity.pass,
        ),
      );
    } else {
      checks.add(
        QualityCheck(
          id: 'hashtag_count',
          title: 'Hashtag Count',
          description:
              '${pkg.hashtags.length} hashtags — Instagram allows 30 but 5 is optimal',
          severity: QualitySeverity.warn,
          fixHint: 'Regenerate hashtags to get exactly 5',
        ),
      );
    }

    // 6. Character Lock in prompts
    final hasCharacterLock = pkg.visualPrompts.any(
      (p) =>
          p.contains('CHARACTER LOCK') ||
          p.contains('Ria:') ||
          p.contains('Rio:'),
    );
    if (hasCharacterLock) {
      checks.add(
        QualityCheck(
          id: 'character_lock',
          title: 'Character Lock Injection',
          description: 'Character Lock present in visual prompts — consistency guaranteed',
          severity: QualitySeverity.pass,
        ),
      );
    } else {
      checks.add(
        QualityCheck(
          id: 'character_lock',
          title: 'Character Lock Injection',
          description:
              'Character Lock NOT found in prompts — characters may drift',
          severity: QualitySeverity.fail,
          fixHint: 'Regenerate visual prompts — ensures Character Lock block is injected',
        ),
      );
    }

    // 7. Pinned comment question format
    final hasQuestion = pkg.pinnedComment.contains('?');
    if (hasQuestion) {
      checks.add(
        QualityCheck(
          id: 'pinned_comment',
          title: 'Pinned Comment',
          description: 'Pinned comment is a question — drives first comment',
          severity: QualitySeverity.pass,
        ),
      );
    } else {
      checks.add(
        QualityCheck(
          id: 'pinned_comment',
          title: 'Pinned Comment',
          description:
              'Pinned comment is not a question — may not drive engagement',
          severity: QualitySeverity.warn,
          fixHint: 'Regenerate pinned comment with "More Curiosity" style',
        ),
      );
    }

    // 8. Reply comment variety (5 distinct)
    if (pkg.replyComments.length == 5) {
      final unique = pkg.replyComments.toSet().length;
      if (unique == 5) {
        checks.add(
          QualityCheck(
            id: 'reply_variety',
            title: 'Reply Comment Variety',
            description:
                '5 unique reply comments — covers different engagement styles',
            severity: QualitySeverity.pass,
          ),
        );
      } else {
        checks.add(
          QualityCheck(
            id: 'reply_variety',
            title: 'Reply Comment Variety',
            description: '$unique/5 unique replies — some may be duplicates',
            severity: QualitySeverity.warn,
            fixHint: 'Regenerate reply comments for more variety',
          ),
        );
      }
    } else {
      checks.add(
        QualityCheck(
          id: 'reply_variety',
          title: 'Reply Comment Count',
          description:
              '${pkg.replyComments.length} replies — expected 5 for optimal engagement',
          severity: QualitySeverity.warn,
        ),
      );
    }

    return checks;
  }

  static Map<String, int> summary(List<QualityCheck> checks) {
    return {
      'pass': checks.where((c) => c.isPass).length,
      'warn': checks.where((c) => c.isWarn).length,
      'fail': checks.where((c) => c.isFail).length,
    };
  }
}

// ============================================================================
// Quality Check Screen — Shows actionable flags with Fix buttons
// ============================================================================

class QualityCheckScreen extends StatefulWidget {
  final ContentPackage package;
  final void Function(RegenerateTarget, RegenerateStyle)? onRegenerate;

  const QualityCheckScreen({
    super.key,
    required this.package,
    this.onRegenerate,
  });

  @override
  State<QualityCheckScreen> createState() => _QualityCheckScreenState();
}

class _QualityCheckScreenState extends State<QualityCheckScreen> {
  late List<QualityCheck> _checks;

  @override
  void initState() {
    super.initState();
    _checks = ContentQualityChecker.check(widget.package);
  }

  void _fixAllIssues() {
    // Show a snackbar indicating the fix action
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Auto-fix would regenerate all flagged sections. Use individual Fix buttons for precise control.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ContentQualityChecker.summary(_checks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Quality Check'),
        actions: [
          if (_checks.any((c) => !c.isPass))
            TextButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Fix All Issues'),
              onPressed: _fixAllIssues,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  count: _checks.where((c) => c.isPass).length,
                  label: 'Pass',
                  icon: Icons.check_circle,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  count: _checks.where((c) => c.isWarn).length,
                  label: 'Improve',
                  icon: Icons.warning,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  count: _checks.where((c) => c.isFail).length,
                  label: 'Fix',
                  icon: Icons.error,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          Gap.l,
          const Text('Actionable Checks', style: AppText.screenTitle),
          Gap.s,
          ..._checks
              .map(
                (check) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: check.severity.color.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              check.severity.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                check.title,
                                style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: check.severity.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                check.severity.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Gap.s,
                        Text(check.description, style: AppText.body),
                        if (check.fixHint != null) ...[
                          Gap.s,
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    check.fixHint!,
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Gap.s,
                          if (widget.onRegenerate != null) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (check.id.contains('hook')) ...[
                                  _FixButton(
                                    label: 'Simpler Hook',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.hook,
                                      RegenerateStyle.simpler,
                                    ),
                                  ),
                                  _FixButton(
                                    label: 'Curious Hook',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.hook,
                                      RegenerateStyle.moreCuriosity,
                                    ),
                                  ),
                                ],
                                if (check.id.contains('slide')) ...[
                                  _FixButton(
                                    label: 'Simpler Slides',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.slides,
                                      RegenerateStyle.simpler,
                                    ),
                                  ),
                                  _FixButton(
                                    label: 'More Visual Slides',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.slides,
                                      RegenerateStyle.moreVisual,
                                    ),
                                  ),
                                ],
                                if (check.id.contains('character_visibility') ||
                                    check.id.contains('character_lock')) ...[
                                  _FixButton(
                                    label: 'Fix Visual Prompts',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.visualPrompts,
                                      RegenerateStyle.moreVisual,
                                    ),
                                  ),
                                ],
                                if (check.id.contains('hashtag')) ...[
                                  _FixButton(
                                    label: 'Fix Hashtags',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.hashtags,
                                      RegenerateStyle.original,
                                    ),
                                  ),
                                ],
                                if (check.id.contains('pinned')) ...[
                                  _FixButton(
                                    label: 'Curious Pinned',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.pinnedComment,
                                      RegenerateStyle.moreCuriosity,
                                    ),
                                  ),
                                ],
                                if (check.id.contains('reply')) ...[
                                  _FixButton(
                                    label: 'Fresh Replies',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.replyComments,
                                      RegenerateStyle.original,
                                    ),
                                  ),
                                ],
                                if (check.id.contains('cta')) ...[
                                  _FixButton(
                                    label: 'Fix CTA',
                                    onTap: () => widget.onRegenerate!(
                                      RegenerateTarget.cta,
                                      RegenerateStyle.original,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          Gap.xs,
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _FixButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FixButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: AppColors.primary),
        foregroundColor: AppColors.primary,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ============================================================================
// Posting Section Helper
// ============================================================================

class _PostingSection extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onCopy;
  final IconData icon;

  const _PostingSection({
    required this.title,
    required this.content,
    required this.onCopy,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: AppText.section),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: onCopy,
                  tooltip: 'Copy $title',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: AppText.body,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Idea Inbox — Capture raw ideas, develop into content
// ============================================================================

enum IdeaStatus {
  idea('💡', 'Idea'),
  developing('📝', 'Developing'),
  ready('✅', 'Ready'),
  posted('📤', 'Posted'),
  reuse('♻️', 'Reuse');

  final String emoji;
  final String label;

  const IdeaStatus(this.emoji, this.label);
}

class IdeaInboxItem {
  final String id;
  final String title;
  final String rawIdea;
  final String bucketId;
  final String notes;
  final IdeaStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IdeaInboxItem({
    required this.id,
    required this.title,
    required this.rawIdea,
    required this.bucketId,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  IdeaInboxItem copyWith({
    String? title,
    String? rawIdea,
    String? bucketId,
    String? notes,
    IdeaStatus? status,
    DateTime? updatedAt,
  }) => IdeaInboxItem(
    id: id,
    title: title ?? this.title,
    rawIdea: rawIdea ?? this.rawIdea,
    bucketId: bucketId ?? this.bucketId,
    notes: notes ?? this.notes,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'rawIdea': rawIdea,
    'bucketId': bucketId,
    'notes': notes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory IdeaInboxItem.fromJson(Map<String, dynamic> json) => IdeaInboxItem(
    id: json['id'] as String,
    title: json['title'] as String,
    rawIdea: json['rawIdea'] as String,
    bucketId: json['bucketId'] as String,
    notes: json['notes'] as String,
    status: IdeaStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  ContentBucket get bucket =>
      BucketLibrary.byId(bucketId) ?? BucketLibrary.challenge;
}

class IdeaInboxStore {
  static const _fileName = 'idea_inbox.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<IdeaInboxItem>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(content);
    return jsonList.map((e) => IdeaInboxItem.fromJson(e)).toList();
  }

  static Future<void> save(List<IdeaInboxItem> items) async {
    final file = await _file();
    final jsonList = items.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  static Future<void> add(IdeaInboxItem item) async {
    final items = await load();
    items.insert(0, item);
    await save(items);
  }

  static Future<void> update(IdeaInboxItem item) async {
    final items = await load();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      items[index] = item;
      await save(items);
    }
  }

  static Future<void> delete(String id) async {
    final items = await load();
    items.removeWhere((e) => e.id == id);
    await save(items);
  }
}

class IdeaInboxScreen extends StatefulWidget {
  const IdeaInboxScreen({super.key});
  @override
  State<IdeaInboxScreen> createState() => _IdeaInboxScreenState();
}

class _IdeaInboxScreenState extends State<IdeaInboxScreen> {
  List<IdeaInboxItem> _items = [];
  IdeaStatus? _statusFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await IdeaInboxStore.load();
    if (mounted)
      setState(() {
        _items = items;
        _loading = false;
      });
  }

  Future<void> _addIdea() async {
    final titleCtrl = TextEditingController();
    final ideaCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    ContentBucket selectedBucket = BucketLibrary.challenge;

    final result = await showModalBottomSheet<IdeaInboxItem>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Idea', style: AppText.screenTitle),
              Gap.m,
              _field('Title', titleCtrl),
              _field('Raw Idea', ideaCtrl),
              _field('Notes (optional)', notesCtrl),
              Gap.s,
              DropdownButtonFormField<ContentBucket>(
                value: selectedBucket,
                items: BucketLibrary.all
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: b.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${b.emoji} ${b.name}'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedBucket = v!),
                decoration: const InputDecoration(labelText: 'Bucket'),
              ),
              Gap.m,
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty ||
                            ideaCtrl.text.trim().isEmpty)
                          return;
                        final item = IdeaInboxItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text.trim(),
                          rawIdea: ideaCtrl.text.trim(),
                          bucketId: selectedBucket.id,
                          notes: notesCtrl.text.trim(),
                          status: IdeaStatus.idea,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        Navigator.pop(ctx, item);
                      },
                      child: const Text('Save Idea'),
                    ),
                  ),
                ],
              ),
              Gap.m,
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      await IdeaInboxStore.add(result);
      _load();
    }
  }

  Future<void> _editIdea(IdeaInboxItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final ideaCtrl = TextEditingController(text: item.rawIdea);
    final notesCtrl = TextEditingController(text: item.notes);
    ContentBucket selectedBucket = item.bucket;
    IdeaStatus selectedStatus = item.status;

    final result = await showModalBottomSheet<IdeaInboxItem>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Idea', style: AppText.screenTitle),
              Gap.m,
              _field('Title', titleCtrl),
              _field('Raw Idea', ideaCtrl),
              _field('Notes', notesCtrl),
              Gap.s,
              DropdownButtonFormField<ContentBucket>(
                value: selectedBucket,
                items: BucketLibrary.all
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: b.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${b.emoji} ${b.name}'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedBucket = v!),
                decoration: const InputDecoration(labelText: 'Bucket'),
              ),
              Gap.s,
              DropdownButtonFormField<IdeaStatus>(
                value: selectedStatus,
                items: IdeaStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Text(s.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(s.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedStatus = v!),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              Gap.m,
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty ||
                            ideaCtrl.text.trim().isEmpty)
                          return;
                        final updated = item.copyWith(
                          title: titleCtrl.text.trim(),
                          rawIdea: ideaCtrl.text.trim(),
                          bucketId: selectedBucket.id,
                          notes: notesCtrl.text.trim(),
                          status: selectedStatus,
                          updatedAt: DateTime.now(),
                        );
                        Navigator.pop(ctx, updated);
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
              Gap.m,
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      await IdeaInboxStore.update(result);
      _load();
    }
  }

  Future<void> _deleteIdea(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete idea?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await IdeaInboxStore.delete(id);
      _load();
    }
  }

  Future<void> _generateFromIdea(IdeaInboxItem item) async {
    final updated = item.copyWith(
      status: IdeaStatus.developing,
      updatedAt: DateTime.now(),
    );
    await IdeaInboxStore.update(updated);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MultiFormatScreen(initialIdea: item)),
    );
  }

  List<IdeaInboxItem> get _filteredItems {
    if (_statusFilter == null) return _items;
    return _items.where((i) => i.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idea Inbox'),
        actions: [
          PopupMenuButton<IdeaStatus>(
            initialValue: _statusFilter,
            onSelected: (v) =>
                setState(() => _statusFilter = v == _statusFilter ? null : v),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: null, child: Text('All Statuses')),
              ...IdeaStatus.values.map(
                (s) => PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Text(s.emoji),
                      const SizedBox(width: 8),
                      Text(s.label),
                    ],
                  ),
                ),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add idea',
        onPressed: _addIdea,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 64,
                    color: AppColors.textFaint,
                  ),
                  Gap.m,
                  Text(
                    _statusFilter != null
                        ? 'No ideas with status "${_statusFilter!.label}"'
                        : 'No ideas yet. Tap + to capture one!',
                    style: AppText.hint,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredItems.length,
              itemBuilder: (ctx, index) {
                final item = _filteredItems[index];
                final bucket = item.bucket;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _editIdea(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: bucket.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${bucket.emoji} ${bucket.shortLabel}',
                                style: AppText.small.copyWith(
                                  color: bucket.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                item.status.emoji + ' ' + item.status.label,
                                style: AppText.small,
                              ),
                            ],
                          ),
                          Gap.s,
                          Text(
                            item.title,
                            style: AppText.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Gap.xs,
                          Text(
                            item.rawIdea,
                            style: AppText.hint,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.notes.isNotEmpty) ...[
                            Gap.xs,
                            Text(
                              'Note: ${item.notes}',
                              style: AppText.hint.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          Gap.s,
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: const Text('Generate'),
                                onPressed: () => _generateFromIdea(item),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit'),
                                onPressed: () => _editIdea(item),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Delete'),
                                onPressed: () => _deleteIdea(item.id),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.section),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: label.contains('Idea') ? 3 : 1,
          decoration: const InputDecoration(),
        ),
      ],
    ),
  );
}

// ============================================================================
// Multi-Format Generator Screen — One Idea → Multiple Formats
// ============================================================================

class MultiFormatScreen extends StatefulWidget {
  final IdeaInboxItem? initialIdea;

  const MultiFormatScreen({super.key, this.initialIdea});
  @override
  State<MultiFormatScreen> createState() => _MultiFormatScreenState();
}

class _MultiFormatScreenState extends State<MultiFormatScreen> {
  final _ideaCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  ContentBucket _selectedBucket = BucketLibrary.challenge;
  final Set<ContentFormat> _selectedFormats = {
    ContentFormat.carousel,
    ContentFormat.reel,
    ContentFormat.trialReel,
    ContentFormat.singleImage,
  };
  bool _generating = false;
  Map<ContentFormat, ContentPackage> _results = {};
  Map<ContentFormat, String> _errors = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialIdea != null) {
      _titleCtrl.text = widget.initialIdea!.title;
      _ideaCtrl.text = widget.initialIdea!.rawIdea;
      _selectedBucket = widget.initialIdea!.bucket;
    }
  }

  @override
  void dispose() {
    _ideaCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateAll() async {
    if (_ideaCtrl.text.trim().isEmpty || _selectedFormats.isEmpty) return;
    setState(() {
      _generating = true;
      _results.clear();
      _errors.clear();
    });

    final idea = _ideaCtrl.text.trim();
    final title = _titleCtrl.text.trim().isEmpty
        ? idea
        : _titleCtrl.text.trim();

    for (final format in _selectedFormats) {
      try {
        final package = await ContentGenerator.generate(
          idea: idea,
          bucket: _selectedBucket,
          format: format,
        );
        // Override title with user's title
        final updatedPackage = ContentPackage(
          id: package.id,
          idea: package.idea,
          bucket: package.bucket,
          format: package.format,
          characters: package.characters,
          hook: package.hook,
          slides: package.slides,
          visualPrompts: package.visualPrompts,
          caption: package.caption,
          cta: package.cta,
          hashtags: package.hashtags,
          pinnedComment: package.pinnedComment,
          replyComments: package.replyComments,
          createdAt: package.createdAt,
        );
        _results[format] = updatedPackage;
      } catch (e) {
        _errors[format] = e.toString();
      }
    }

    setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('One Idea → Multiple Formats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Enter your idea once, generate all formats',
            style: AppText.screenTitle,
          ),
          Gap.s,
          const Text(
            'Select formats, pick a bucket, and generate. Each format gets the same core idea with format-specific structure.',
            style: AppText.hint,
          ),
          Gap.m,

          _field('Title (optional)', _titleCtrl),
          _field('Your Idea', _ideaCtrl),
          Gap.m,

          const Text('Content Bucket', style: AppText.section),
          Gap.s,
          DropdownButtonFormField<ContentBucket>(
            value: _selectedBucket,
            items: BucketLibrary.all
                .map(
                  (b) => DropdownMenuItem(
                    value: b,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: b.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${b.emoji} ${b.name}'),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedBucket = v!),
          ),
          Gap.m,

          const Text('Formats to Generate', style: AppText.section),
          Gap.s,
          ...ContentFormat.values.map(
            (format) => CheckboxListTile(
              value: _selectedFormats.contains(format),
              onChanged: (v) => setState(() {
                if (v == true)
                  _selectedFormats.add(format);
                else
                  _selectedFormats.remove(format);
              }),
              title: Row(
                children: [
                  Text(format.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(format.label, style: AppText.body)),
                  Text(
                    '${format.defaultSlideCount} ${format == ContentFormat.singleImage ? 'image' : 'slides/shots'}',
                    style: AppText.hint,
                  ),
                ],
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Gap.m,

          FilledButton.icon(
            onPressed: _generating || _selectedFormats.isEmpty
                ? null
                : _generateAll,
            icon: _generating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_generating ? 'Generating...' : 'Generate All Formats'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          Gap.l,

          if (_results.isNotEmpty || _errors.isNotEmpty) ...[
            const Text('Results', style: AppText.screenTitle),
            Gap.s,
            ...ContentFormat.values.where((f) => _selectedFormats.contains(f)).map((
              format,
            ) {
              final pkg = _results[format];
              final err = _errors[format];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Text(
                    format.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(format.label, style: AppText.body),
                  subtitle: Text(
                    err != null
                        ? 'Error: $err'
                        : '${pkg?.slides.length ?? 0} slides, ${pkg?.visualPrompts.length ?? 0} prompts',
                    style: AppText.hint,
                  ),
                  initiallyExpanded: true,
                  trailing: pkg != null
                      ? TextButton.icon(
                          icon: const Icon(Icons.content_copy, size: 18),
                          label: const Text('Posting Pack'),
                          onPressed: () {
                            final formats = <ContentFormat, FormatOutput>{};
                            for (final entry in _results.entries) {
                              formats[entry.key] = FormatAdapter.adapt(
                                entry.value,
                                entry.key,
                              );
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostingPackScreen(
                                  formats: formats,
                                  originalPackage: pkg,
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                  children: [
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          err,
                          style: TextStyle(color: AppColors.danger),
                        ),
                      )
                    else if (pkg != null)
                      _FormatResultCard(
                        package: pkg,
                        onRegenerate: (target, style) =>
                            _regenerateSection(format, target, style),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _regenerateSection(
    ContentFormat format,
    RegenerateTarget target,
    RegenerateStyle style,
  ) async {
    final pkg = _results[format];
    if (pkg == null) return;
    final result = await Regenerator.regenerate(
      RegenerationRequest(originalPackage: pkg, target: target, style: style),
    );
    setState(() {
      // Update the package with regenerated content
      final updated = _applyRegeneration(pkg, result);
      _results[format] = updated;
    });
  }

  ContentPackage _applyRegeneration(
    ContentPackage pkg,
    RegenerationResult result,
  ) {
    switch (result.target) {
      case RegenerateTarget.hook:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: result.newValue as String,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: pkg.cta,
          hashtags: pkg.hashtags,
          pinnedComment: pkg.pinnedComment,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.caption:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: result.newValue as String,
          cta: pkg.cta,
          hashtags: pkg.hashtags,
          pinnedComment: pkg.pinnedComment,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.hashtags:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: pkg.cta,
          hashtags: result.newValue as List<String>,
          pinnedComment: pkg.pinnedComment,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.pinnedComment:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: pkg.cta,
          hashtags: pkg.hashtags,
          pinnedComment: result.newValue as String,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.replyComments:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: pkg.cta,
          hashtags: pkg.hashtags,
          pinnedComment: pkg.pinnedComment,
          replyComments: result.newValue as List<String>,
          createdAt: pkg.createdAt,
        );
      default:
        return pkg;
    }
  }

  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.section),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: label.contains('Idea') ? 3 : 1,
          maxLines: label.contains('Idea') ? 5 : 1,
          decoration: const InputDecoration(),
        ),
      ],
    ),
  );
}

// ============================================================================
// Format Result Card — Shows generated package with regenerate options
// ============================================================================

class _FormatResultCard extends StatelessWidget {
  final ContentPackage package;
  final void Function(RegenerateTarget, RegenerateStyle) onRegenerate;

  const _FormatResultCard({required this.package, required this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    void showRegenerateMenu(RegenerateTarget target) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Regenerate with style', style: AppText.section),
            ),
            ...RegenerateStyle.values.map(
              (style) => ListTile(
                title: Text(style.label),
                subtitle: Text(style.description, style: AppText.hint),
                onTap: () {
                  Navigator.pop(ctx);
                  onRegenerate(target, style);
                },
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hook
          _SectionCard(
            title: 'Hook',
            content: package.hook,
            onRegenerate: () => showRegenerateMenu(RegenerateTarget.hook),
            copyText: package.hook,
          ),
          Gap.s,

          // Slides
          _SectionCard(
            title: 'Slides/Shots (${package.slides.length})',
            content: package.slides
                .map((s) => '${s.index + 1}. ${s.title}: ${s.body}')
                .join('\n\n'),
            onRegenerate: () => showRegenerateMenu(RegenerateTarget.slides),
            copyText: package.slides
                .map((s) => '${s.title}\n${s.body}')
                .join('\n\n'),
          ),
          Gap.s,

          // Visual Prompts
          _SectionCard(
            title: 'Visual Prompts (${package.visualPrompts.length})',
            content: package.visualPrompts
                .map((p) => p.split('\n').first)
                .join('\n\n'),
            onRegenerate: () =>
                showRegenerateMenu(RegenerateTarget.visualPrompts),
            copyText: package.visualPrompts.join('\n\n'),
          ),
          Gap.s,

          // Caption
          _SectionCard(
            title: 'Caption',
            content: package.caption,
            onRegenerate: () => showRegenerateMenu(RegenerateTarget.caption),
            copyText: package.caption,
          ),
          Gap.s,

          // CTA + Hashtags
          Row(
            children: [
              Expanded(
                child: _SectionCard(
                  title: 'CTA',
                  content: package.cta,
                  onRegenerate: () => showRegenerateMenu(RegenerateTarget.cta),
                  copyText: package.cta,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  title: 'Hashtags (${package.hashtags.length})',
                  content: package.hashtags.join(' '),
                  onRegenerate: () =>
                      showRegenerateMenu(RegenerateTarget.hashtags),
                  copyText: package.hashtags.join(' '),
                ),
              ),
            ],
          ),
          Gap.s,

          // Pinned Comment
          _SectionCard(
            title: 'Pinned Comment',
            content: package.pinnedComment,
            onRegenerate: () =>
                showRegenerateMenu(RegenerateTarget.pinnedComment),
            copyText: package.pinnedComment,
          ),
          Gap.s,

          // Reply Comments
          _SectionCard(
            title: 'Reply Comments (${package.replyComments.length})',
            content: package.replyComments
                .asMap()
                .entries
                .map((e) => '${e.key + 1}. ${e.value}')
                .join('\n\n'),
            onRegenerate: () =>
                showRegenerateMenu(RegenerateTarget.replyComments),
            copyText: package.replyComments.join('\n\n'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Section Card Helper
// ============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onRegenerate;
  final String copyText;

  const _SectionCard({
    required this.title,
    required this.content,
    required this.onRegenerate,
    required this.copyText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: AppText.section),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: onRegenerate,
                  tooltip: 'Regenerate',
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copy(context, copyText, title),
                  tooltip: 'Copy',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: AppText.body,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext ctx, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ============================================================================
// Trial Reel Screen - 60-sec compilation for non-follower reach
// ============================================================================

class TrialReelScreen extends StatefulWidget {
  const TrialReelScreen({super.key});
  @override
  State<TrialReelScreen> createState() => _TrialReelScreenState();
}

class _TrialReelScreenState extends State<TrialReelScreen> {
  final _titleCtrl = TextEditingController(text: '7 Missions in 60 Seconds');
  final _ideaCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController(
    text: 'Non-followers, parents of 1.5-4 year olds',
  );
  final _visualStyleCtrl = TextEditingController(
    text:
        'Fast cuts (1-2 sec per mission), consistent characters, upbeat music',
  );
  final _moodCtrl = TextEditingController(text: 'Energetic / Fun');
  List<String> _reelScript = [];
  List<String> _shotPrompts = [];
  bool _generating = false;

  Future<void> _generate() async {
    if (_titleCtrl.text.trim().isEmpty || _ideaCtrl.text.trim().isEmpty) return;
    setState(() => _generating = true);

    // Generate the Trial Reel script (60 sec)
    final script = '''
0-3s: Race Track — jump, walk, run 🏁
3-6s: Concert — spoon mic, plate drums 🎤
6-9s: Art Studio — draw, write, chalk 🎨
9-12s: Detective — look, listen, think 🕵️
12-15s: Rescue — push, pull, help 🧸
15-18s: Treasure — open, find, close 🎁
18-21s: Daily Care — eat, drink, brush 🍎
21-60s: Recap grid of all 7 + "We Did It!" celebration 🎉
CTA: "Follow for daily missions! 🏠"''';

    // Generate VEO-STYLE SHOT PROMPTS for AI video generation
    // Each shot includes: CHARACTERS, ACTION, LOCATION, CAMERA, MOVEMENT, EXPRESSION, LIGHTING, STYLE, CONTINUITY, DURATION
    final missions = [
      (
        'Race Track',
        '0-3s',
        'Ria and Rio jumping pillow hurdle, walking taped line',
        'Ria mid-air over pillow hurdle, arms out for balance, Rio walking carefully on taped floor line, Cuty cheering from side',
      ),
      (
        'Concert',
        '3-6s',
        'Ria singing into wooden spoon, Rio clapping, Cuty on steel plate drums',
        'Ria holding wooden spoon like microphone, mouth open singing, Rio clapping enthusiastically, Cuty tapping steel plates with paws',
      ),
      (
        'Art Studio',
        '6-9s',
        'Ria drawing sun on paper, Rio writing name on slate, kitchen chalk on floor',
        'Ria drawing big yellow sun with crayon, Rio writing R-I-O on slate with chalk, colorful kitchen chalk art on floor',
      ),
      (
        'Detective',
        '9-12s',
        'Ria with cardboard binoculars, Rio cupped hands around eyes, Cuty with magnifying glass',
        'Ria looking through cardboard tube binoculars, Rio cupping hands around eyes like binoculars, Cuty holding magnifying glass over clue',
      ),
      (
        'Rescue Team',
        '12-15s',
        'Ria pushing laundry basket, Rio pulling dupatta rope, Cuty riding in basket',
        'Ria pushing blue laundry basket full of stuffed toys, Rio pulling dupatta rope attached to basket, Cuty sitting proudly in basket',
      ),
      (
        'Treasure Box',
        '15-18s',
        'Ria opening tiffin box finding toy, Rio closing box, tucking Cuty in blanket',
        'Ria opening steel tiffin box revealing small toy, Rio carefully closing lid, tucking Cuty into soft blanket',
      ),
      (
        'Daily Care',
        '18-21s',
        'Ria eating apple from tiffin, Rio drinking water, both brushing teeth, Cuty watching',
        'Ria eating apple slices from tiffin, Rio drinking from water bottle, both brushing teeth side-by-side at sink, Cuty watching from counter',
      ),
    ];

    final charLock = CharacterLibrary.characterLockBlock;

    final shots = <String>[];
    for (var i = 0; i < missions.length; i++) {
      final (name, timing, desc, action) = missions[i];
      final shotPrompt =
          '''
VEO SHOT PROMPT — Shot ${i + 1}: $name ($timing)

CHARACTERS:
Ria: Indian preschool girl, dark brown hair in two ponytails with pink bows, brown eyes, pink dress, NO GLASSES
Rio: Indian preschool boy, dark brown hair, blue outfit, brown eyes, NO GLASSES
Cuty: Small white bunny, pink bow, soft friendly expression, UNCHANGED

ACTION: $action
LOCATION: Cozy Indian home interior — living room/kitchen/floor, warm natural morning light
CAMERA: Smartphone vertical 9:16, eye-level with children, slight handheld shake for authenticity
MOVEMENT: ${i < 3
                  ? 'Fast, energetic'
                  : i < 5
                  ? 'Playful, curious'
                  : 'Gentle, caring'} — match mission energy
EXPRESSION: Ria: excited/determined | Rio: focused/enthusiastic | Cuty: calm/amused
LIGHTING: Warm morning sunlight through window, soft shadows, pastel color palette
STYLE: Soft 3D Pixar/Disney-style render aesthetic, cream background, consistent character designs
CONTINUITY: Characters maintain exact appearance across all shots; outfits may change per scene but hair/eyes/face consistent
DURATION: ${timing.split('–').last.trim()} (${(double.parse(timing.split('–').first.trim().replaceAll('s', '')) * 1000).round()}ms)
'''
              .trim();
      shots.add('$name (Shot ${i + 1}):\n$shotPrompt');
    }

    // Final recap shot
    final recapPrompt =
        '''
VEO SHOT PROMPT — Shot 8: Final Recap (21-60s)

CHARACTERS:
Ria: Indian preschool girl, dark brown hair in two ponytails with pink bows, brown eyes, pink dress, NO GLASSES
Rio: Indian preschool boy, dark brown hair, blue outfit, brown eyes, NO GLASSES
Cuty: Small white bunny, pink bow, soft friendly expression, UNCHANGED

ACTION: Grid of 7 mission icons appears rapidly (Race Track 🏁, Concert 🎤, Art Studio 🎨, Detective 🕵️, Rescue 🧸, Treasure 🎁, Daily Care 🍎), then all 3 characters jump into frame together with confetti explosion, "WE DID IT!" text banner, group high-five celebration
LOCATION: Bright celebratory home setting, confetti falling, warm golden light
CAMERA: Vertical 9:16, wide shot for grid, then push-in to medium close-up for celebration
MOVEMENT: Fast grid animation (0.5s per icon), then energetic celebration with confetti burst
EXPRESSION: All three characters: pure joy, accomplishment, pride
LIGHTING: Bright celebratory, golden hour warmth, confetti sparkle
STYLE: Soft 3D Pixar/Disney-style render, cream background, consistent characters, Instagram Reel ready
CONTINUITY: Final celebration of all previous shots — characters unchanged, visual style locked
DURATION: 39s (21-60 second mark)
'''
            .trim();

    shots.add('Final Recap (Shot 8):\n$recapPrompt');

    setState(() {
      _reelScript = script.trim().split('\n');
      _shotPrompts = shots;
      _generating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trial Reel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Create a 60-second Trial Reel for non-follower reach',
            style: AppText.screenTitle,
          ),
          Gap.s,
          const Text(
            'Fast hook, 7 missions in 1-2 sec cuts, celebration end, follow CTA.',
            style: AppText.hint,
          ),
          Gap.m,
          _field('Title / Hook', _titleCtrl),
          _field('Main Concept', _ideaCtrl),
          _field('Target Audience', _audienceCtrl),
          _field('Visual Style', _visualStyleCtrl),
          _field('Mood / Emotion', _moodCtrl),
          Gap.m,
          FilledButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_generating ? 'Generating...' : 'Generate Trial Reel'),
          ),
          Gap.l,
          if (_reelScript.isNotEmpty) ...[
            const Text('Reel Script (60 sec)', style: AppText.section),
            Gap.s,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _reelScript
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(line, style: AppText.body),
                      ),
                    )
                    .toList(),
              ),
            ),
            Gap.m,
            FilledButton.icon(
              onPressed: () =>
                  _copy(_reelScript.join('\n'), 'Trial Reel Script'),
              icon: const Icon(Icons.copy_all),
              label: const Text('Copy Script'),
            ),
            Gap.l,
            const Text(
              'Shot Prompts (for AI video generation)',
              style: AppText.section,
            ),
            Gap.s,
            ..._shotPrompts.asMap().entries.map((entry) {
              final i = entry.key;
              final prompt = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.accent,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Shot ${i + 1}', style: AppText.body),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(prompt, style: AppText.hint),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy prompt',
                          onPressed: () =>
                              _copy(prompt, 'Trial Reel Shot ${i + 1}'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Gap.m,
            FilledButton.icon(
              onPressed: () => _copy(
                _shotPrompts
                    .asMap()
                    .entries
                    .map((e) => 'Shot ${e.key + 1}:\n${e.value}')
                    .join('\n\n'),
                'All Trial Reel Shot Prompts',
              ),
              icon: const Icon(Icons.copy_all),
              label: const Text('Copy All Shot Prompts'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.section),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: label.contains('Idea') || label.contains('Concept') ? 3 : 1,
          decoration: const InputDecoration(),
        ),
      ],
    ),
  );

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ============================================================================
// Single Image Screen - Simplified: enter idea, get 7 different image prompts
// ============================================================================

class SingleImageScreen extends StatefulWidget {
  const SingleImageScreen({super.key});
  @override
  State<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends State<SingleImageScreen> {
  final _titleCtrl = TextEditingController();
  final _ideaCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController(text: 'Parents of 3-6 year olds');
  final _visualStyleCtrl = TextEditingController(
    text: 'Bright, warm, playful preschool lifestyle',
  );
  final _moodCtrl = TextEditingController(text: 'Relatable / Playful');
  List<String> _imagePrompts = [];
  bool _generating = false;

  Future<void> _generate() async {
    if (_titleCtrl.text.trim().isEmpty || _ideaCtrl.text.trim().isEmpty) return;
    setState(() => _generating = true);

    // Generate 7 different prompt variations
    final prompts = <String>[];
    final baseStyle = _visualStyleCtrl.text.trim();
    final baseAudience = _audienceCtrl.text.trim();
    final baseMood = _moodCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final idea = _ideaCtrl.text.trim();

    // 7 prompt styles
    final styles = [
      'Soft 3D Pixar/Disney-style render, cream background, warm friendly preschool look',
      'Clean minimal illustration, white background, simple line art, modern kid-friendly',
      'Cozy realistic lifestyle photo, natural morning light, authentic family moment',
      'Cheerful cartoon style, bold colors, expressive characters, fun energetic vibe',
      'Dreamy whimsical illustration, soft glow, magical preschool atmosphere',
      'Flat design vector art, geometric shapes, vibrant colors, Instagram-ready',
      'Hand-drawn sketch style, pencil texture, warm tones, personal intimate feel',
    ];

    for (var i = 0; i < 7; i++) {
      final style = i < styles.length ? styles[i] : styles.last;
      final prompt = makeImagePrompt(
        title: title,
        hook: title,
        idea: idea,
        visualStyle: '$baseStyle, $style',
        audience: baseAudience,
        contentGoal: 'Build connection',
        mood: baseMood,
      );
      prompts.add(prompt);
    }

    setState(() {
      _imagePrompts = prompts;
      _generating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Single Image Post')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'What is your single image post about?',
            style: AppText.screenTitle,
          ),
          Gap.s,
          const Text(
            'Enter your idea and get 7 different image prompts. Use them on Meta AI, pick the best image, and post.',
            style: AppText.hint,
          ),
          Gap.m,
          _field('Title / Concept', _titleCtrl),
          _field('Main Idea', _ideaCtrl),
          _field('Target Audience', _audienceCtrl),
          _field('Visual Style Base', _visualStyleCtrl),
          _field('Mood / Emotion', _moodCtrl),
          Gap.m,
          FilledButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _generating ? 'Generating...' : 'Generate 7 Image Prompts',
            ),
          ),
          Gap.l,
          if (_imagePrompts.isNotEmpty) ...[
            const Text('7 Image Prompts for Meta AI', style: AppText.section),
            Gap.s,
            ..._imagePrompts.asMap().entries.map((entry) {
              final i = entry.key;
              final prompt = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.accent,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Option ${i + 1}', style: AppText.body),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(prompt, style: AppText.hint),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy prompt',
                          onPressed: () =>
                              _copy(prompt, 'Single Image Option ${i + 1}'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Gap.m,
            FilledButton.icon(
              onPressed: () => _copy(
                _imagePrompts
                    .asMap()
                    .entries
                    .map((e) => 'Option ${e.key + 1}:\n${e.value}')
                    .join('\n\n'),
                'All 7 Image Prompts',
              ),
              icon: const Icon(Icons.copy_all),
              label: const Text('Copy All 7 Prompts'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.section),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: label.contains('Idea') ? 3 : 1,
          decoration: const InputDecoration(),
        ),
      ],
    ),
  );

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
