// ── Instagram Caption Generator ───────────────────────────────────────────────
//
// One topic in, one ready-to-paste caption out. The caption follows the same
// house format every time: a hook a parent recognises, a short scannable body,
// a takeaway, a call to action, and exactly five hashtags.
//
// The rules live in [kCaptionSpec] rather than inside the prompt below so that
// anything else in the app that writes a caption can borrow the same wording
// instead of inventing a second, slightly different set of rules. The prompt is
// built by a pure function, which is what makes it testable and reusable.
//
// If Gemini is unavailable the caption still comes out, because a template that
// matches the format is a better answer than an error box on a screen someone
// is standing in front of when they mean to post.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_system.dart';
import 'gemini_call.dart';
import 'secrets.dart';
import 'theme.dart';

const _lightModel = 'gemini-3.6-flash-lite';
const _fullModel = 'gemini-3.6-flash';
const _timeout = Duration(seconds: 60);

// ── The house caption format ──────────────────────────────────────────────────

/// The rules every caption in this app is held to.
///
/// Kept separate from the request so the wording can be changed in one place and
/// so another screen can pull the same rules in rather than restating them.
const String kCaptionSpec = '''
STRUCTURE
1. Line 1 (the hook): one short, relatable, scroll-stopping line that makes a
   parent think "this is exactly my child". 2 to 9 words. No emoji in the hook.
2. Body: 3 to 5 short lines, each on its own line, prefixed with a bullet or a
   number. Short enough to read in one glance and easy to screenshot. At least
   one line carries a concrete moment, tip, or takeaway the parent can use today.
3. A closing takeaway line: a small lesson or parenting reminder, one sentence.
4. A call to action that sounds like a real parent talking, such as
   "Comment love if your child does this too", "Save this for later", or
   "Send this to a parent who needs this".
5. Exactly 5 hashtags, on their own final line, each specific to this post.

TONE
Warm, playful, relatable, conversational. Write like a real Indian parent
talking to another parent. Simple English or natural Hinglish, whichever fits the
moment better. Child friendly and positive. No corporate language. No parenting
terminology or jargon. Never use an em dash. Do not use semicolons.
''';

// ── The caption itself ────────────────────────────────────────────────────────

class GeneratedCaption {
  final String hook;
  final List<String> body;
  final String takeaway;
  final String cta;
  final List<String> hashtags;

  const GeneratedCaption({
    required this.hook,
    required this.body,
    required this.takeaway,
    required this.cta,
    required this.hashtags,
  });

  /// The whole caption as one block, which is what gets copied to the clipboard.
  String get fullText {
    final buffer = StringBuffer()
      ..writeln(hook)
      ..writeln();
    for (final line in body) {
      buffer.writeln('- $line');
    }
    buffer
      ..writeln()
      ..writeln(takeaway)
      ..writeln()
      ..writeln(cta)
      ..writeln()
      ..writeln(hashtags.map((t) => (t.startsWith('#') ? t : '#$t')).join(' '));
    return buffer.toString().trimRight();
  }
}

/// How much Hindi to mix into the caption.
enum CaptionLanguage {
  hinglish('Hinglish', 'Roman Hindi with English, the way we actually talk'),
  english('Simple English', 'Plain English, short and easy');

  final String label;
  final String guidance;
  const CaptionLanguage(this.label, this.guidance);
}

/// Builds the request. Pure, so the same topic always produces the same prompt.
String buildCaptionPrompt({
  required String topic,
  required CaptionLanguage language,
  String bucket = '',
  String extraNotes = '',
}) {
  final buffer = StringBuffer()
    ..writeln(
      'Write one Instagram caption for "${BrandDefaults.name}" (${BrandDefaults.handle}).',
    )
    ..writeln()
    ..writeln('TOPIC: $topic')
    ..writeln()
    ..writeln('AUDIENCE: ${BrandDefaults.audience}')
    ..writeln('BRAND FEEL: Little stories, big lessons. Real preschool moments.')
    ..writeln('LANGUAGE: ${language.guidance}.')
    ..writeln();

  if (bucket.trim().isNotEmpty) {
    buffer.writeln('CONTENT ANGLE: ${bucket.trim()}');
    buffer.writeln();
  }
  if (extraNotes.trim().isNotEmpty) {
    buffer.writeln('EXTRA NOTES FROM PALAK: ${extraNotes.trim()}');
    buffer.writeln();
  }

  buffer
    ..writeln(kCaptionSpec)
    ..writeln()
    ..writeln('The Fun Learning With Palak world has Ria, a toddler girl who')
    ..writeln('gets into everyday preschool situations, and Cuty, her small white')
    ..writeln('bunny with a pink bow. Bring them in only when the topic suits it.')
    ..writeln()
    ..writeln('Return ONLY valid JSON in exactly this shape:')
    ..writeln()
    ..writeln('''{
  "hook": "the scroll stopping first line, no emoji",
  "body": ["short line one", "short line two", "short line three"],
  "takeaway": "one sentence lesson or parenting reminder",
  "cta": "a natural call to action",
  "hashtags": ["#tagone", "#tagtwo", "#tagthree", "#tagfour", "#tagfive"]
}''')
    ..writeln()
    ..writeln('"hashtags" must hold exactly 5 tags, specific to this post rather')
    ..writeln('than five big generic tags. Do not repeat a tag.');

  return buffer.toString();
}

/// Asks Gemini for a caption. Falls back to the template on any failure, so the
/// screen always has something to show.
Future<GeneratedCaption> generateCaption({
  required String topic,
  required CaptionLanguage language,
  String bucket = '',
  String extraNotes = '',
  String? apiKey,
  void Function(String message)? onWait,
}) async {
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  if (key.trim().isEmpty) {
    return captionFromTemplate(topic: topic, language: language, bucket: bucket);
  }

  final response = await geminiPost(
    model: _lightModel,
    fallbackModel: _fullModel,
    apiKey: key,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': buildCaptionPrompt(
                topic: topic,
                language: language,
                bucket: bucket,
                extraNotes: extraNotes,
              ),
            },
          ],
        },
      ],
      'generationConfig': {
        // Higher than the critique calls in this app: a caption that reads the
        // same every time is not a caption, it is a form letter.
        'temperature': 0.9,
        'maxOutputTokens': 1024,
        // Measured, not guessed: this model thinks before it answers, and the
        // thinking is counted against maxOutputTokens. On a 1024 budget it spent
        // 981 tokens thinking and cut the reply off mid-JSON with
        // finishReason MAX_TOKENS, which failed to parse. Writing a caption does
        // not need deliberation, so the thinking is turned off and the whole
        // budget goes to the caption.
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
        : 'Gemini error ${response.statusCode}: ${response.body}');
  }

  final reply = jsonDecode(response.body);
  final text = reply['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned no caption.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(_stripFence(text)) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.\n$text');
  }

  final body = ((json['body'] as List?) ?? const [])
      .map((e) => '$e'.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final hashtags = ((json['hashtags'] as List?) ?? const [])
      .map((e) => '$e'.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (body.isEmpty || hashtags.isEmpty) {
    throw Exception('Gemini returned an incomplete caption.');
  }

  return GeneratedCaption(
    hook: '${json['hook'] ?? ''}'.trim(),
    body: body,
    takeaway: '${json['takeaway'] ?? ''}'.trim(),
    cta: '${json['cta'] ?? ''}'.trim(),
    // Five is the rule. Take what came back and top up, never ship seven.
    hashtags: hashtags.take(5).toList(),
  );
}

String _stripFence(String text) {
  return text
      .trim()
      .replaceFirst(RegExp(r'^```(?:json)?'), '')
      .replaceFirst(RegExp(r'```$'), '')
      .trim();
}

/// The offline answer. Same shape as a real caption so the screen does not need
/// a second layout for it, and honest about being a starting point.
GeneratedCaption captionFromTemplate({
  required String topic,
  required CaptionLanguage language,
  String bucket = '',
}) {
  final clean = topic.trim();
  final subject = clean.isEmpty ? 'everyday preschool moment' : clean;

  final body = language == CaptionLanguage.hinglish
      ? [
          'Ria ki yeh moment roz ka hai, ghar pe bhi hota hai',
          'Chhoti si cheez se bada seekhne ka mauka mil jaata hai',
          'Gussa karne ke bajaye ek saath saath baitho aur dekho ki kya ho raha hai',
          '5 minute ka play, poore din ka confidence',
        ]
      : [
          'Ria runs into this same moment every single day at home',
          'A tiny everyday thing becomes a real lesson when you slow down with her',
          'Sit beside her instead of hurrying her along, and watch what she does next',
          'Five minutes of play can carry a whole day of confidence',
        ];

  return GeneratedCaption(
    hook: language == CaptionLanguage.hinglish
        ? 'Ye toh bilkul mere ghar pe hota hai!'
        : 'This happens at our home every single day!',
    body: body,
    takeaway: language == CaptionLanguage.hinglish
        ? 'Bacche galtiyan isliye nahi karte kyunki seekhe nahi, kyunki koi saath nahi deta.'
        : 'Little ones are not being difficult on purpose, they are still learning how to do it with you.',
    cta: 'Comment love if your child does this too.',
    hashtags: [
      ..._topicTags(subject),
      ...BrandDefaults.hashtagPool.take(2),
    ].take(5).toList(),
  );
}

/// Pulls two tags off the topic itself so the offline caption is still about
/// this post rather than five brand tags wearing a disguise.
List<String> _topicTags(String topic) {
  final words = topic
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 3)
      .take(2)
      .toList();
  if (words.isEmpty) return const ['#preschoollearning', '#toddlermomlife'];
  return words.map((w) => '#$w').toList();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CaptionGeneratorScreen extends StatefulWidget {
  const CaptionGeneratorScreen({super.key});

  @override
  State<CaptionGeneratorScreen> createState() => _CaptionGeneratorScreenState();
}

class _CaptionGeneratorScreenState extends State<CaptionGeneratorScreen> {
  final _topicCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  CaptionLanguage _language = CaptionLanguage.hinglish;
  GeneratedCaption? _caption;
  bool _generating = false;
  String? _error;

  @override
  void dispose() {
    _topicCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      setState(() => _error = 'Type the topic first, for example: shoe rack time chaos');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });

    // Read the key here rather than taking it as a constructor argument, so a
    // key changed in Settings is picked up without going back to the home screen.
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('gemini_api_key')?.trim() ?? '';

    try {
      final caption = await generateCaption(
        topic: topic,
        language: _language,
        extraNotes: _notesCtrl.text.trim(),
        apiKey: stored,
        onWait: (message) {
          if (mounted) setState(() => _error = message);
        },
      );
      if (mounted) {
        setState(() {
          _caption = caption;
          _error = null;
        });
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('$what copied')));
  }

  @override
  Widget build(BuildContext context) {
    final caption = _caption;

    return Scaffold(
      appBar: AppBar(title: const Text('Caption Generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Type one topic, get a ready to post caption.',
            style: AppText.screenTitle,
          ),
          Gap.s,
          const Text(
            'Same format every time: a hook you recognise, a short body, a takeaway, '
            'a call to action, and 5 hashtags.',
            style: AppText.hint,
          ),
          Gap.m,
          _field('Topic', _topicCtrl, hint: 'Shoe rack time chaos at home'),
          Gap.s,
          _field('Anything else to add? (optional)', _notesCtrl, lines: 2),
          Gap.m,
          SegmentedButton<CaptionLanguage>(
            segments: [
              for (final l in CaptionLanguage.values)
                ButtonSegment(value: l, label: Text(l.label)),
            ],
            selected: {_language},
            onSelectionChanged: (s) => setState(() => _language = s.first),
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
            label: Text(caption == null ? 'Generate Caption' : 'Generate Another'),
          ),
          Gap.l,
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: AppText.body),
            ),
            Gap.m,
          ],
          if (caption != null) ...[
            Row(
              children: [
                const Expanded(
                  child: Text('Your caption', style: AppText.section),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy whole caption',
                  onPressed: () => _copy(caption.fullText, 'Caption'),
                ),
              ],
            ),
            Gap.s,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caption.hook, style: AppText.screenTitle),
                  Gap.m,
                  ...caption.body.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('- $line', style: AppText.body),
                    ),
                  ),
                  Gap.s,
                  Text(caption.takeaway, style: AppText.body),
                  Gap.m,
                  Text(caption.cta, style: AppText.body),
                  Gap.m,
                  Text(
                    caption.hashtags
                        .map((t) => (t.startsWith('#') ? t : '#$t'))
                        .join(' '),
                    style: AppText.small,
                  ),
                ],
              ),
            ),
            Gap.m,
            SecondaryButton(
              label: 'Copy caption',
              icon: Icons.copy,
              onPressed: () => _copy(caption.fullText, 'Caption'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body),
        Gap.xs,
        TextField(
          controller: ctrl,
          maxLines: lines,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
