import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'theme.dart';

class QuickIdea {
  final String id;
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
  final List<String> comments;
  final String script;
  final DateTime createdAt;

  const QuickIdea({
    required this.id,
    required this.title,
    required this.postType,
    required this.audience,
    required this.contentGoal,
    required this.mood,
    required this.hook,
    required this.mainIdea,
    required this.problem,
    required this.lesson,
    required this.visualStyle,
    required this.imagePrompt,
    required this.caption,
    required this.cta,
    required this.hashtags,
    required this.comments,
    required this.script,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'postType': postType,
        'audience': audience,
        'contentGoal': contentGoal,
        'mood': mood,
        'hook': hook,
        'mainIdea': mainIdea,
        'problem': problem,
        'lesson': lesson,
        'visualStyle': visualStyle,
        'imagePrompt': imagePrompt,
        'caption': caption,
        'cta': cta,
        'hashtags': hashtags,
        'comments': comments,
        'script': script,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuickIdea.fromJson(Map<String, dynamic> json) => QuickIdea(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        postType: json['postType'] as String? ?? 'Carousel',
        audience: json['audience'] as String? ?? 'Parents of 3-6 year olds',
        contentGoal: json['contentGoal'] as String? ?? 'Build connection',
        mood: json['mood'] as String? ?? 'Relatable',
        hook: json['hook'] as String? ?? '',
        mainIdea: json['mainIdea'] as String? ?? '',
        problem: json['problem'] as String? ?? '',
        lesson: json['lesson'] as String? ?? '',
        visualStyle: json['visualStyle'] as String? ?? 'Bright and playful',
        imagePrompt: json['imagePrompt'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        cta: json['cta'] as String? ?? 'Save this for later',
        hashtags: json['hashtags'] as String? ?? '',
        comments: ((json['comments'] as List?) ?? const []).whereType<String>().toList(),
        script: json['script'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class QuickIdeaStore {
  static const _fileName = 'quick_ideas.json';

  static Future<File> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<QuickIdea>> load() async {
    try {
      final file = await _path();
      if (!await file.exists()) return const [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return raw.whereType<Map<String, dynamic>>().map(QuickIdea.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveAll(List<QuickIdea> ideas) async {
    try {
      final file = await _path();
      await file.writeAsString(jsonEncode(ideas.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> add(QuickIdea idea) async {
    final list = await load();
    final updated = [idea, ...list];
    await saveAll(updated);
  }
}

class PromoCommentStore {
  static const _fileName = 'promo_comments.json';
  static const starterComments = [
    'Thank you ! ❤️ Meri Profile pe Ria, Rio & Cuty ki full masti chal rahi hai - miss mat karna! 👇',
    'Meri Profile pe Ria, Rio & Cuty ki full masti chal rahi hai - miss mat karna! ❤️',
    'Cuty ki masti + Ria Rio ki stories = perfect little-kids content 🐰💕',
    'Ria ne aaj phir kya kaand kar diya dekho meri Profile pe 🤣😂',
  ];

  static Future<File> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<String>> load() async {
    try {
      final file = await _path();
      if (!await file.exists()) return starterComments;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return starterComments;
      return raw.whereType<String>().where((text) => text.trim().isNotEmpty).toList();
    } catch (_) {
      return starterComments;
    }
  }

  static Future<void> save(List<String> comments) async {
    try {
      final file = await _path();
      await file.writeAsString(jsonEncode(comments));
    } catch (_) {}
  }
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
}) {
  final base = message.trim();
  final result = <String>[];
  final mom = 'This is my life right now 😭 and honestly, so relatable.';
  final nonMom = 'This is not just a mom thing — this feels like real family life for so many of us.';
  final emoji = '😅😅😅 this is us every single day.';
  final truth = 'So true. This is exactly the kind of moment that makes parenting feel real.';
  final cta = 'Which part of this feels most like your home? Tell me below 👇';

  final extra = base.isNotEmpty ? ' "$base"' : '';
  result.addAll([
    'This is so relatable$extra',
    mom,
    nonMom,
    emoji,
    truth,
    cta,
  ]);

  if (postType.toLowerCase() == 'static image' || postType.toLowerCase() == 'carousel') {
    result[0] = 'This is exactly the kind of post I keep saving for later.';
  }

  if (audience.toLowerCase().contains('mom')) {
    result[1] = 'This is my life right now 😭 and honestly, I need this reminder today.';
  }

  if (audience.toLowerCase().contains('dad') || audience.toLowerCase().contains('non')) {
    result[2] = 'This is relatable even outside mom life — real family chaos looks the same for everyone.';
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
  final style = visualStyle.isEmpty ? 'bright, warm, realistic family lifestyle' : visualStyle;
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
    lesson.isEmpty ? 'Tiny moments really do build the biggest memories.' : lesson,
    '',
    cta.isEmpty ? 'Save this for the next time your child says no.' : cta,
    '',
    hashtags.isEmpty ? makeHashtags('Parents of 3-6 year olds') : hashtags,
  ];
  return text.join('\n');
}

String makeScript({
  required String hook,
  required String mainIdea,
  required String lesson,
  required String postType,
}) {
  final title = hook.isEmpty ? 'Daily Family Drama' : hook;
  final base = mainIdea.isEmpty ? 'A normal morning turns into a small family challenge.' : mainIdea;
  final message = lesson.isEmpty ? 'Little moments teach big lessons.' : lesson;
  if (postType.toLowerCase() == 'reel') {
    return '0:00 $title\n0:04 $base\n0:08 Everyone reacts differently\n0:12 Then the tiny lesson appears\n0:16 $message';
  }
  return 'Slide 1: $title\nSlide 2: The moment it starts\nSlide 3: What children do\nSlide 4: What parents learn\nSlide 5: $message';
}

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
}) {
  final imagePrompt = makeImagePrompt(
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
  );
  final script = makeScript(
    hook: hook,
    mainIdea: mainIdea.isEmpty ? problem : mainIdea,
    lesson: lesson,
    postType: postType,
  );

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
    createdAt: DateTime.now(),
  );
}

class QuickContentScreen extends StatefulWidget {
  const QuickContentScreen({super.key});

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
  final _styleCtrl = TextEditingController(text: 'Bright, warm, playful family lifestyle');
  final _ctaCtrl = TextEditingController(text: 'Save this for later');
  final _imagePromptCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _scriptCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();
  final _pinCommentCtrl = TextEditingController();
  final _promoCommentCtrl = TextEditingController();

  List<String> _comments = [];
  List<String> _promoComments = [];
  List<QuickIdea> _savedIdeas = [];
  bool _loading = true;

  String _postType = 'Carousel';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final results = await Future.wait([
      QuickIdeaStore.load(),
      PromoCommentStore.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _savedIdeas = results[0] as List<QuickIdea>;
      _promoComments = results[1] as List<String>;
      _loading = false;
    });
  }

  Future<void> _addPromoComment() async {
    final text = _promoCommentCtrl.text.trim();
    if (text.isEmpty) return;
    if (_promoComments.contains(text)) {
      _promoCommentCtrl.clear();
      return;
    }
    final updated = [text, ..._promoComments];
    await PromoCommentStore.save(updated);
    if (!mounted) return;
    setState(() {
      _promoComments = updated;
      _promoCommentCtrl.clear();
    });
  }

  Future<void> _deletePromoComment(String comment) async {
    final updated = _promoComments.where((item) => item != comment).toList();
    await PromoCommentStore.save(updated);
    if (!mounted) return;
    setState(() => _promoComments = updated);
  }

  void _generatePack() {
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
    );

    _imagePromptCtrl.text = idea.imagePrompt;
    _captionCtrl.text = idea.caption;
    _scriptCtrl.text = idea.script;
    _hashtagsCtrl.text = idea.hashtags;
    _pinCommentCtrl.text = idea.comments.first;
    _comments = idea.comments;

    setState(() {});
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
      imagePrompt: _imagePromptCtrl.text.isEmpty ? idea.imagePrompt : _imagePromptCtrl.text,
      caption: _captionCtrl.text.isEmpty ? idea.caption : _captionCtrl.text,
      cta: _ctaCtrl.text,
      hashtags: _hashtagsCtrl.text.isEmpty ? idea.hashtags : _hashtagsCtrl.text,
      comments: _comments.isEmpty ? idea.comments : _comments,
      script: _scriptCtrl.text.isEmpty ? idea.script : _scriptCtrl.text,
      createdAt: DateTime.now(),
    );

    await QuickIdeaStore.add(fullIdea);
    await _loadSaved();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Idea saved'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 1)),
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
    _promoCommentCtrl.dispose();
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
                      Expanded(child: const Text('Quick post pack', style: AppText.screenTitle)),
                      if (_savedIdeas.isNotEmpty)
                        Text('${_savedIdeas.length} saved', style: AppText.small),
                    ],
                  ),
                  Gap.s,
                  const Text('Create a prompt, caption, comments and script without entering the full reel flow.', style: AppText.hint),
                  Gap.m,

                  const Text('1  BUILD THE BRIEF', style: AppText.section),
                  Gap.s,
                  const Text('Choose the format, audience and feeling first. The outputs below will follow this brief.', style: AppText.hint),
                  Gap.s,
                  const Text('Post type', style: AppText.section),
                  Gap.s,
                  DropdownButtonFormField<String>(
                    value: _postType,
                    items: const [
                      DropdownMenuItem(value: 'Carousel', child: Text('Carousel')),
                      DropdownMenuItem(value: 'Static Image', child: Text('Static Image')),
                      DropdownMenuItem(value: 'Reel', child: Text('Reel')),
                      DropdownMenuItem(value: 'Story', child: Text('Story')),
                    ],
                    onChanged: (v) => setState(() => _postType = v ?? 'Carousel'),
                  ),
                  Gap.m,

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

                  Gap.m,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _generatePack,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate post pack'),
                    ),
                  ),
                  Gap.m,

                  const Text('2  READY TO COPY', style: AppText.section),
                  Gap.s,
                  const Text('Generate once, then copy only the piece you need for your next post.', style: AppText.hint),
                  Gap.s,
                  _readOnlyBox('Image prompt', _imagePromptCtrl, () => _copy(_imagePromptCtrl.text, 'Image prompt')),
                  _readOnlyBox('Caption', _captionCtrl, () => _copy(_captionCtrl.text, 'Caption')),
                  _readOnlyBox('Script / carousel text', _scriptCtrl, () => _copy(_scriptCtrl.text, 'Script')),
                  _readOnlyBox('Hashtags', _hashtagsCtrl, () => _copy(_hashtagsCtrl.text, 'Hashtags')),

                  const SizedBox(height: 16),
                  const Text('Pin comment', style: AppText.section),
                  _commentBox(_pinCommentCtrl, _pinCommentCtrl.text),
                  const SizedBox(height: 16),
                  const Text('Reply comments', style: AppText.section),
                  if (_comments.isEmpty)
                    const Text('Generate a pack to see five different replies.', style: AppText.hint)
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
                            Text('${i + 1}. ', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Expanded(child: Text(comment, style: AppText.body)),
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _copy(comment, 'Comment ${i + 1}'),
                              icon: const Icon(Icons.copy_all_outlined, size: 18),
                            ),
                          ],
                        ),
                      );
                    }),

                  Gap.m,
                  const Text('PROFILE PROMOTION COMMENTS', style: AppText.section),
                  Gap.s,
                  const Text('Save friendly comments you can use when replying on other people\'s posts.', style: AppText.hint),
                  Gap.s,
                  TextField(
                    controller: _promoCommentCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a reusable profile comment...',
                    ),
                  ),
                  Gap.s,
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addPromoComment,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Save comment'),
                    ),
                  ),
                  if (_promoComments.isNotEmpty) ...[
                    Gap.s,
                    ..._promoComments.map((comment) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Text(comment, style: AppText.body)),
                              IconButton(
                                tooltip: 'Copy comment',
                                onPressed: () => _copy(comment, 'Promotion comment'),
                                icon: const Icon(Icons.copy_all_outlined, size: 18),
                              ),
                              IconButton(
                                tooltip: 'Delete comment',
                                onPressed: () => _deletePromoComment(comment),
                                icon: const Icon(Icons.delete_outline, size: 18),
                              ),
                            ],
                          ),
                        )),
                  ],

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
                              'Caption: ${_captionCtrl.text}',
                              'Comments: ${_comments.join(' | ')}',
                              'Script: ${_scriptCtrl.text}',
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
              maxLines: label.contains('Main idea') || label.contains('Lesson') ? 3 : 1,
              decoration: const InputDecoration(),
            ),
          ],
        ),
      );

  Widget _readOnlyBox(String label, TextEditingController controller, VoidCallback onCopy) => Padding(
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

  Widget _commentBox(TextEditingController controller, String initialText) => Row(
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
            ..._savedIdeas.map((idea) => Card(
                  child: ListTile(
                    title: Text(idea.title),
                    subtitle: Text('${idea.postType} • ${idea.audience}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.content_copy),
                      onPressed: () => _copy(
                        [
                          'Title: ${idea.title}',
                          'Hook: ${idea.hook}',
                          'Caption: ${idea.caption}',
                          'Prompt: ${idea.imagePrompt}',
                          'Comments: ${idea.comments.join(' | ')}',
                        ].join('\n\n'),
                        'Saved idea',
                      ),
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
                      _pinCommentCtrl.text = idea.comments.isNotEmpty ? idea.comments.first : '';
                      _comments = idea.comments;
                      setState(() {});
                      Navigator.pop(sheetContext);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
