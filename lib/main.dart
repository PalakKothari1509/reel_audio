import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'secrets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'gemini_call.dart';
import 'video_builder.dart';
import 'voice.dart';
import 'plan_data.dart';
import 'plan_screen.dart';
import 'posting_kit.dart';
import 'projects.dart';
import 'prompt_builder.dart';
import 'prompts.dart';
import 'prompt_screen.dart';
import 'caption_renderer.dart';
import 'story_ideas.dart';
import 'theme.dart';
import 'music.dart';
import 'quick_content.dart';

/// Android side of saving a finished reel. Its own channel rather than the voice one,
/// because saving a video has nothing to do with speech.
const _mediaChannel = MethodChannel('com.example.reel_audio/media');

// ── API Keys ──────────────────────────────────────────────────────────────────

const _geminiKey     = geminiApiKey;
const _elevenLabsKey = elevenLabsApiKey;
// ElevenLabs voice ID — "Aria" multilingual (works well for Hinglish)
const _elevenVoiceId = elevenVoiceId;

// ── Gemini Service ────────────────────────────────────────────────────────────
//
// One place for the model name. Google retires and renames these, and a name the key
// can't use fails in a way that looks like a bug in the app. To see what your key is
// allowed to call:
//   https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY
const _geminiModel = 'gemini-3.6-flash';

/// Long enough for a slow first call. Thirty seconds was not: Gemini regularly takes
/// longer than that to answer the first request of a session, and the old timeout
/// turned a slow reply into what looked like a broken app.
const _geminiTimeout = Duration(seconds: 60);

// Writes a timed script from the story you type. It never sees the video or the images —
// the description is all Gemini gets, which is why that field matters.

Future<List<ScriptLine>> generateScriptWithGemini({
  required String videoDescription,
  required String language,
  required String style,
  required double videoDuration,
  void Function(String message)? onWait,
}) async {
  final langNote = language == 'Hinglish'
      ? 'Write in Hinglish (Hindi words in English script, e.g. "Ek baar ki baat hai"). Natural, fun, kid-friendly for 3-5 year old Indian children.'
      : language == 'Hindi'
          ? 'Write in Hindi (Devanagari script).'
          : 'Write in simple English for Indian preschool children.';

  final styleNote = style.contains('Funny') ? 'Make it funny and energetic with expressions like Haha, Arey, Wah!'
      : style.contains('Adventure') ? 'Make it exciting and adventurous.'
      : style.contains('Educational') ? 'Make it educational and clear.'
      : style.contains('Problem') ? 'Focus on problem solving.'
      : 'Make it warm and heartwarming.';

  final storyNote = videoDescription.isNotEmpty
      ? 'The video is about: $videoDescription'
      : 'Write a general fun preschool story with Ria and Rio.';
  final expectedLines = (videoDuration / 4).floor().clamp(4, 20);
  final totalSecs = videoDuration.round();

  // Hinglish only. A Hindi voice reading Latin letters mispronounces the words, so ask
  // for the same line in Devanagari as well — that half is what gets spoken, while the
  // Hinglish half stays on screen where it is easier to read and edit.
  final isHinglish = language == 'Hinglish';
  final formatNote = isHinglish
      ? 'Each line: timestamp, space, Hinglish text, then " | ", then the SAME line '
        'written in Devanagari script.'
      : 'Each line: timestamp space text.';
  // The examples open on a hook, because Gemini copies the shape of what it is shown
  // far more reliably than it follows an instruction about it.
  final exampleBlock = isHinglish
      ? '''
0:00 Arey! Cuty ka gajar kaun le gaya? | अरे! क्यूटी का गाजर कौन ले गया?
0:04 Ria boli, maine nahi liya | रिया बोली, मैंने नहीं लिया
0:08 Rio bhi peeche chhup gaya | रियो भी पीछे छुप गया
0:12 Phir dono ne milkar dhoonda | फिर दोनों ने मिलकर ढूंढा
0:16 Tum bhi dhoondo, kahan hai? | तुम भी ढूंढो, कहाँ है?'''
      : '''
0:00 Wait! Who took Cuty's carrot?
0:04 Ria said, it was not me
0:08 Rio quietly hid behind the chair
0:12 Then they looked for it together
0:16 Can you find it too?''';

  // Reels are won or lost in the first second, and most are watched on mute with the
  // thumb ready to scroll. So the shape is told to Gemini explicitly — without it the
  // script reads like a bedtime story, which is pleasant and gets scrolled past.
  final prompt = '''
Write a voiceover script for a $totalSecs second preschool video for "Fun Learning With Palak" Instagram Reels.

Characters: Ria (girl), Rio (boy), Cuty (rabbit), Mum, Dad
$storyNote
$langNote
$styleNote

The script must follow the story above. Do not invent a different story.

Shape it like a reel that holds attention:
$kScriptShapeRules

Keep every line to 4-9 words: short on screen, still easy to say in about 4 seconds.
Write how a person talks, not how a book reads.

Output ONLY $expectedLines lines. $formatNote Nothing else. No explanations. No bullet points. No asterisks.

Example output:
$exampleBlock

Now output exactly $expectedLines lines for a $totalSecs second video:
''';

  final body = jsonEncode({
    'contents': [{
      'parts': [{'text': prompt}]
    }],
    'generationConfig': {
      'temperature': 0.8,
      // 1024 was not enough and failed silently: Devanagari costs several tokens per
      // character, asking for both halves roughly triples the output, and newer models
      // spend part of the budget thinking before they write anything. The script came
      // back cut off after a line or two with no error at all.
      'maxOutputTokens': 8192,
    }
  });

  late final http.Response response;
  try {
    response = await geminiPost(
      model: _geminiModel,
      apiKey: _geminiKey,
      body: body,
      timeout: _geminiTimeout,
      onWait: onWait,
    );
  } on TimeoutException {
    // A bare TimeoutException says nothing about which of these it was.
    throw Exception('Gemini did not answer within ${_geminiTimeout.inSeconds}s.\n'
        'Check the phone has internet, and that "$_geminiModel" is a model your key can use.');
  } catch (e) {
    throw Exception('Could not reach Gemini: $e');
  }

  if (response.statusCode == 404) {
    throw Exception('Gemini has no model called "$_geminiModel" for this key.\n'
        'Open the models list in a browser to see the right name:\n'
        'https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY');
  }
  if (response.statusCode != 200) {
    // Still busy after the retries. Say so plainly rather than handing over the JSON.
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
        : 'Gemini API error ${response.statusCode}: ${response.body}');
  }

  final json = jsonDecode(response.body);
  final candidate = json['candidates']?[0];
  final text = candidate?['content']?['parts']?[0]?['text'] as String? ?? '';
  final finish = candidate?['finishReason'] as String? ?? '';

  // Gemini stopping early used to look like a short script rather than a failure.
  if (text.isEmpty) {
    throw Exception(finish.isEmpty
        ? 'Gemini returned nothing.'
        : 'Gemini returned nothing (stopped because: $finish).');
  }
  if (finish == 'MAX_TOKENS') {
    throw Exception('Gemini ran out of room and the script was cut off. '
        'Try a shorter video length, or raise maxOutputTokens.');
  }
  if (finish == 'SAFETY' || finish == 'RECITATION') {
    throw Exception('Gemini refused this story ($finish). Try rewording it.');
  }

  final lines = parseScript(text);
  if (lines.isEmpty) throw Exception('Gemini response had no valid timed lines:\n$text');

  // A script far shorter than asked for is a truncation nobody would otherwise notice.
  if (lines.length < 3 && expectedLines >= 4) {
    throw Exception('Gemini only returned ${lines.length} line(s) instead of $expectedLines. '
        'What it sent back:\n$text');
  }
  return lines;
}

// The speaking itself lives in voice.dart — phone, Gemini and ElevenLabs behind one call.

// ── Text cleaner ──────────────────────────────────────────────────────────────

String cleanForTts(String text) => text
    .replaceAll('?!', '!').replaceAll('!?', '!')
    .replaceAll(',,', ',').replaceAll('...', ' ')
    .replaceAll('…', ' ').replaceAll('  ', ' ').trim();

// ── Voice profiles ────────────────────────────────────────────────────────────

class VoiceProfile {
  final double rate;
  final double pitch;
  const VoiceProfile(this.rate, this.pitch);
}

const Map<String, VoiceProfile> kVoiceProfiles = {
  '❤️ Heartwarming':    VoiceProfile(0.50, 1.20),
  '😂 Funny':           VoiceProfile(0.65, 1.40),
  '🌈 Adventure':       VoiceProfile(0.62, 1.25),
  '📚 Educational':     VoiceProfile(0.52, 1.00),
  '🧩 Problem-solving': VoiceProfile(0.48, 0.95),
  '🌱 Independence':    VoiceProfile(0.55, 1.10),
};

// ── Story format ──────────────────────────────────────────────────────────────

/// The shape a reel story needs, as something anyone can copy and fill in.
///
/// Five beats, in the order a reel plays them: hook, trouble, worse, turn, ending.
/// Written as plain labels rather than prose so it survives being pasted into
/// WhatsApp or Notes by someone who never opens the app.
/// The blank story form.
///
/// Hook first and Moral last because those are the two the script generator most often
/// invents when they are missing — and an invented hook is the line that decides
/// whether anyone watches. The Idea button fills exactly these fields, in this order,
/// so a generated story and a hand-written one arrive in the same shape.
///
/// "Ending line" is what a character says out loud at the end. "Moral" is what the reel
/// leaves the parent with. They are usually not the same sentence.
const kStoryTemplate = '''Hook:
Who: Ria, Rio, Cuty
Where:
What starts it:
What goes wrong:
How it gets worse:
How it is solved:
Ending line:
Moral: ''';

// ── ScriptLine ────────────────────────────────────────────────────────────────

class ScriptLine {
  Duration time;
  /// What you read and edit on screen.
  String text;
  /// What the voice actually says, when that differs.
  ///
  /// Hinglish is Hindi written in English letters, and a Hindi voice reading Latin
  /// letters mispronounces it badly. So Gemini returns the same line twice — Hinglish
  /// to read, Devanagari to speak — and this holds the second one. Null means speak
  /// [text] as it stands.
  String? speak;
  ScriptLine(this.time, this.text, {this.speak});

  /// Cleared when the line is edited, since the two would no longer match.
  String get spoken => (speak == null || speak!.trim().isEmpty) ? text : speak!;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String fmtDuration(Duration d) {
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

Duration parseDuration(String s) {
  final parts = s.trim().split(':');
  if (parts.length == 2) {
    return Duration(minutes: int.tryParse(parts[0]) ?? 0, seconds: int.tryParse(parts[1]) ?? 0);
  }
  return Duration.zero;
}

/// One script line as a single string, for saving.
///
/// The same "0:04 text | spoken" shape parseScript already reads, so a saved script
/// goes back in through the code that was already there rather than a second reader
/// that could drift away from the first.
String scriptLineToText(ScriptLine line) {
  final spoken = line.speak;
  final tail = (spoken == null || spoken.trim().isEmpty) ? '' : ' | ${spoken.trim()}';
  return '${fmtDuration(line.time)} ${line.text}$tail';
}

List<ScriptLine> parseScript(String raw) {
  final lines = <ScriptLine>[];
  for (final line in raw.split('\n')) {
    final trimmed = line.replaceAll(RegExp(r'^[\*\-\•\d\.\s]+(?=\d+:\d+)'), '').trim();
    if (trimmed.isEmpty) continue;
    final match = RegExp(r'(\d{1,2}:\d{2})\s+(.+)$').firstMatch(trimmed);
    if (match == null) continue;

    // "0:04 Ria ne dekha | रिया ने देखा" — the half after the pipe is what gets spoken.
    // Scripts pasted by hand have no pipe, and still work exactly as before.
    final rest = match.group(2)!;
    final pipe = rest.indexOf('|');
    final display = (pipe >= 0 ? rest.substring(0, pipe) : rest).trim();
    final spoken = pipe >= 0 ? rest.substring(pipe + 1).trim() : '';
    if (display.isEmpty) continue;

    lines.add(ScriptLine(parseDuration(match.group(1)!), display,
        speak: spoken.isEmpty ? null : spoken));
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}

// ── Characters ────────────────────────────────────────────────────────────────

class Character {
  final String name;
  final String emoji;
  bool selected;
  Character({required this.name, required this.emoji, this.selected = false});
}

final List<Character> kCharacters = [
  Character(name: 'Ria',  emoji: '👧', selected: true),
  Character(name: 'Rio',  emoji: '👦'),
  Character(name: 'Cuty', emoji: '🐰'),
  Character(name: 'Mum',  emoji: '👩'),
  Character(name: 'Dad',  emoji: '👨'),
];

// ── Main ──────────────────────────────────────────────────────────────────────

void main() {
  // Hooks, posting times and results go into the Downloads backup with the stories.
  onPlanSaved = ProjectBackup.schedule;
  runApp(MaterialApp(
    title: 'Story Reel Maker',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: const StoryScreen(),
  ));
}

/// What a reel is mainly for. Parent relatable first: for this page it is the one that
/// earns saves and shares, rather than chasing "viral" on every post.
const kReelPurposes = [
  'Parent relatable', 'Save-worthy', 'Share-worthy', 'Funny',
  'Emotional', 'Life lesson', 'Curiosity',
];

/// The five steps, named once so the bar says the same thing on every screen.
const kSteps = ['Story', 'Script', 'Pictures', 'Voice', 'Reel'];

/// The words the app draws onto the reel itself, after your edits are applied.
class _ReelText {
  /// Two to four words across picture 1, which is the thumbnail.
  final String coverHook;
  /// The last screen: the question, a blank line, then the reason to keep the reel.
  final String closing;
  const _ReelText({this.coverHook = '', this.closing = ''});
}

// ── Home Screen ───────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _video;
  VideoPlayerController? _ctrl;

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    await _ctrl?.dispose();
    final c = VideoPlayerController.file(File(picked.path));
    await c.initialize();
    c.setLooping(true);
    c.play();
    setState(() { _video = File(picked.path); _ctrl = c; });
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, title: const Text('Story Voice Maker')),
      body: Column(children: [
        Expanded(
          child: _ctrl != null && _ctrl!.value.isInitialized
              ? AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!))
              : const Center(child: Text('No video selected', style: TextStyle(color: AppColors.textSoft))),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _btn(Icons.video_library, 'Select Reel', AppColors.textSoft, _pickVideo),
            const SizedBox(height: 10),
            _btn(Icons.auto_awesome, 'Add Voice', AppColors.primary,
              _video == null ? null : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => StoryInputScreen(
                  videoFile: _video!,
                  videoDuration: _ctrl!.value.duration.inSeconds.toDouble(),
                )))),
          ]),
        ),
      ]),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback? onPressed) =>
    SizedBox(width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed, icon: Icon(icon), label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color, foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
        ),
      ),
    );
}

// ── Story Screen ──────────────────────────────────────────────────────────────
// Where the app opens. Say what happens in the story and Gemini writes the timed
// script; the pictures are chosen afterwards, on the script screen, where you can see
// how many lines there are to fill.

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});
  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final _descCtrl = TextEditingController();
  final _languages = ['Hinglish', 'English', 'Hindi'];
  final _lengths = [20, 30, 45, 60];

  String _style = '❤️ Heartwarming';
  String _language = 'Hinglish';
  int _seconds = 30;
  bool _isGenerating = false;
  String _status = '';

  /// The story being written, saved to the phone as it is typed.
  Project? _project;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(_autoSave);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _descCtrl.removeListener(_autoSave);
    _descCtrl.dispose();
    super.dispose();
  }

  /// Writes the story to the phone a moment after typing stops.
  ///
  /// No save button, deliberately. A save button gets pressed once you already know
  /// the work was worth keeping, and the work people lose is always the work they had
  /// not decided about yet — which here is every story, right up until the reel is made.
  ///
  /// Debounced because writing a file on every keystroke is wasteful, and 1.2 seconds
  /// is long enough to stop that without being long enough to lose a sentence.
  void _autoSave() {
    // Cleared the box: whatever is typed next is a different story. Without this the
    // next story was saved INTO the last one — its text replacing the old story's, the
    // old reel and voice left attached to a story they were never made for.
    if (_descCtrl.text.trim().length < 12 && _project != null) {
      _saveTimer?.cancel();
      _project = null;
      if (mounted) setState(() {});
      return;
    }

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1200), _saveNow);
  }

  /// Writes the story in the box straight away.
  Future<void> _saveNow() async {
    _saveTimer?.cancel();
    // Refreshes the main button, which says "continue" or "write" depending on
    // whether this exact text already has a script.
    if (mounted) setState(() {});

    final story = _descCtrl.text.trim();
    if (story.length < 12) return;

    // Read fresh and written in one step: the script, voice, reel and edits are all
    // written by other screens, and saving from a copy held here would put back
    // whatever it held when you left.
    _project = await ProjectStore.upsert(_project ?? _newProject(), (p) => p.copyWith(
      title: Project.titleFrom(story),
      story: story,
      style: _style,
      language: _language,
      seconds: _seconds,
    ));
  }

  Project _newProject() => Project(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        savedAt: DateTime.now(),
        story: '',
      );

  /// Saves what is in the box, then lets the next thing start a brand new story.
  ///
  /// The save comes first because the last second of typing may not have been written
  /// yet, and starting a new story on top of it would lose those words.
  Future<void> _startNewStory({String text = '', String status = ''}) async {
    if (_descCtrl.text.trim().length >= 12) await _saveNow();
    if (!mounted) return;
    setState(() {
      _project = null;
      _descCtrl.text = text;
      _status = status;
    });
  }

  /// Opens the plan. A hook chosen there comes back as a filled-in story form.
  Future<void> _openPlan() async {
    final hook = await Navigator.push<HookIdea>(context,
      MaterialPageRoute(builder: (_) => const PlanScreen()));
    if (hook == null || !mounted) return;

    // A new story, not an edit of whatever was in the box — otherwise the chosen hook
    // would be saved over a different story you were in the middle of.
    if (_descCtrl.text.trim().isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start a new story?'),
          content: const Text('The story in the box is saved already. This starts a new '
              'one from the hook you picked.', style: AppText.hint),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start new')),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    await _startNewStory(
      text: hook.asStoryText(),
      status: '💡 ${hook.cover} — fill in anything you like, then write the script.');
    await HookStore.markUsed(hook.id);
  }

  /// Opens the saved stories, and puts the chosen one back in the box.
  Future<void> _openSaved() async {
    final chosen = await Navigator.push<Project>(context,
      MaterialPageRoute(builder: (_) => const SavedStoriesScreen()));
    if (chosen == null || !mounted) return;

    setState(() {
      _project = chosen;
      _descCtrl.text = chosen.story;
      if (chosen.style.isNotEmpty) _style = chosen.style;
      if (chosen.language.isNotEmpty) _language = chosen.language;
      _seconds = chosen.seconds;
      _status = 'Opened "${chosen.displayName}".';
    });
  }

  /// Reads the story back and says whether it will make a reel worth watching.
  ///
  /// Before the script rather than after: a weak story makes a weak script, a weak
  /// voiceover and seven weak pictures, and by then it has cost twenty minutes.
  Future<void> _checkStory() async {
    setState(() { _isGenerating = true; _status = 'Reading the story...'; });

    try {
      final check = await checkStory(_descCtrl.text,
        onWait: (message) { if (mounted) setState(() => _status = message); });
      if (!mounted) return;
      setState(() => _isGenerating = false);

      // Ready / Improve / Rewrite, coloured, because the one decision this check exists
      // for is whether to spend the evening making pictures for this story.
      final bandColour = check.band == 'Ready'
          ? AppColors.primary
          : check.band == 'Improve' ? AppColors.warning : AppColors.danger;
      final bandNote = check.band == 'Ready'
          ? 'Good to make today.'
          : check.band == 'Improve'
              ? 'Fix the points below before making pictures.'
              : 'Not worth the pictures yet — rework the story first.';

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(children: [
            Text('${check.score}/10',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: bandColour)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bandColour.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
              child: Text(check.band, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: bandColour)),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bandNote, style: TextStyle(fontSize: 13, color: bandColour,
                  fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (check.verdict.isNotEmpty) ...[
                  Text(check.verdict, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                ],
                // The ten requirements, each passed or not, so a low score says exactly
                // where it lost its points instead of only that it did.
                ...check.rows.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(r.pass ? Icons.check_circle : Icons.cancel,
                          size: 16, color: r.pass ? AppColors.primary : AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(child: Text.rich(TextSpan(children: [
                          TextSpan(text: r.name, style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                          if (r.note.isNotEmpty)
                            TextSpan(text: ' — ${r.note}', style: const TextStyle(
                              fontSize: 12, color: AppColors.textSoft)),
                        ]))),
                      ]),
                    )),
                if (check.rows.isNotEmpty && check.missing.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 6),
                    child: Text('Fix first', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                if (check.rows.isEmpty) ...check.good.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.check, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(g, style: const TextStyle(fontSize: 12))),
                      ]),
                    )),
                if (check.missing.isNotEmpty) const SizedBox(height: 8),
                ...check.missing.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.priority_high, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(child: Text(m,
                          style: const TextStyle(fontSize: 12, color: AppColors.warning))),
                      ]),
                    )),
                // Five hooks from the same request, so one can be chosen before the
                // script is written — and the script then uses it word for word.
                if (check.hooks.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 14, bottom: 4),
                    child: Text('Pick a hook', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                  _HookPicker(
                    hooks: check.hooks,
                    chosen: _coverHookInStory,
                    onUse: _setCoverHook,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() { _isGenerating = false; _status = '❌ $e'; });
    }
  }

  /// Asks for a story idea: pick an age and a problem, get one written up.
  ///
  /// Exists so the next reel does not start at a blank field. The problem list is real
  /// preschool arguments, because a story invented without one to hang on comes out as
  /// a fable — pleasant, and nothing a parent recognises.
  Future<void> _askForIdea() async {
    var age = kStoryAges[1];
    var problem = kStoryProblems.first;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Story idea'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: age,
              decoration: const InputDecoration(labelText: 'Age'),
              dropdownColor: AppColors.surface,
              items: kStoryAges
                  .map((a) => DropdownMenuItem(value: a, child: Text('$a years')))
                  .toList(),
              onChanged: (v) => setLocal(() => age = v ?? age),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: problem,
              decoration: const InputDecoration(labelText: 'Problem'),
              dropdownColor: AppColors.surface,
              isExpanded: true,
              items: kStoryProblems
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setLocal(() => problem = v ?? problem),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Give me one'),
            ),
          ],
        ),
      ),
    );

    if (go != true || !mounted) return;

    setState(() { _isGenerating = true; _status = 'Thinking of a story...'; });
    try {
      final idea = await generateStoryIdea(age: age, problem: problem,
        onWait: (message) { if (mounted) setState(() => _status = message); });
      if (!mounted) return;
      // Dropped straight into the box rather than shown for approval: it is a starting
      // point to edit, and an extra "use this?" step helps nobody. As a NEW story —
      // written into the current one, it replaced a story you may already have made a
      // reel from. The one that was in the box stays in Saved stories.
      await _startNewStory(
        text: idea.asStoryText,
        status: '💡 ${idea.title} — edit anything, then write the script.');

      // The idea came with five hooks; offer them now rather than locking in the first.
      if (idea.hooks.isNotEmpty && mounted) {
        setState(() => _isGenerating = false);
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pick a hook', style: AppText.screenTitle),
              Gap.xs,
              const Text('Drawn big on picture 1. You can change it later on the Script '
                  'step or in the posting kit.', style: AppText.hint),
              Gap.m,
              _HookPicker(hooks: idea.hooks, chosen: _coverHookInStory, onUse: (h) {
                _setCoverHook(h);
                Navigator.pop(ctx);
              }),
            ]),
          )),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _status = '❌ $e');
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  /// Puts the skeleton in the box AND on the clipboard.
  ///
  /// On the clipboard as well because the story usually gets written somewhere else
  /// first — WhatsApp, Notes, by someone who isn't holding the phone. Filling in blanks
  /// beats facing an empty field, and a vague story is where Gemini starts inventing.
  void _useFormat() {
    final alreadyWritten = _descCtrl.text.trim().isNotEmpty;
    if (!alreadyWritten) _descCtrl.text = kStoryTemplate;

    Clipboard.setData(const ClipboardData(text: kStoryTemplate));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(alreadyWritten
          ? 'Format copied. Your story was left alone.'
          : 'Format copied, and filled in below.'),
    ));
    setState(() => _status = '');
  }

  /// [prompts] is set when the script and the prompts arrived in the same reply, so
  /// they can be written down now and the prompts screen never has to ask for them.
  Future<void> _openScript(List<ScriptLine> lines, {PromptSet? prompts}) async {
    // Saved before leaving rather than after coming back: the whole point is that a
    // failure on the next screen cannot take the story with it.
    _saveTimer?.cancel();
    final story = _descCtrl.text.trim();
    // Awaited: the next screen reads this story straight back off disk to restore the
    // voice and reel, and would find the old version if it got there first.
    _project = await ProjectStore.upsert(_project ?? _newProject(), (p) => p.copyWith(
      title: Project.titleFrom(story), story: story,
      style: _style, language: _language, seconds: _seconds,
      // Null for "write it myself", which opens an empty editor. Saving that empty
      // list would have wiped a script this story already had.
      script: lines.isEmpty ? null : lines.map(scriptLineToText).toList(),
      scriptStoryKey: lines.isEmpty ? null : fingerprint(story),
      promptsJson: prompts?.rawJson,
      // Matched against the on-screen text later, so it has to be that and not the
      // timestamped form, or the cache never recognises itself.
      promptsScript: prompts == null ? null : lines.map((l) => l.text).toList(),
      // A fresh script from the model brings fresh cover options, so an earlier pick
      // from the old ones no longer applies.
      edits: prompts == null ? null : ({...p.edits}..remove('cover_hook')),
    ));
    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TimedScriptScreen(
        style: _style, language: _language,
        videoFile: null, images: const [], initialLines: lines,
        // Carried through for the AI prompts, which describe the story you typed
        // rather than reverse-engineering it from the finished script lines.
        storyDescription: story,
        seconds: _seconds,
        // So the next screen saves the script and pictures onto the same story
        // rather than starting a second copy of it.
        projectId: _project!.id,
      ),
    ));
  }

  static final _coverHookLine = RegExp(r'^Cover hook:\s*(.*)$', multiLine: true);

  /// The hook written into the story, or empty.
  String get _coverHookInStory =>
      _coverHookLine.firstMatch(_descCtrl.text)?.group(1)?.trim() ?? '';

  /// Writes the chosen hook into the story as its "Cover hook:" line. The script request
  /// uses that line word for word as the cover, so choosing it here decides the cover
  /// before anything is spent on the script.
  void _setCoverHook(String hook) {
    final text = _descCtrl.text;
    setState(() {
      _descCtrl.text = _coverHookLine.hasMatch(text)
          ? text.replaceFirst(_coverHookLine, 'Cover hook: $hook')
          : 'Cover hook: $hook\n$text';
      _status = '✅ Hook chosen: $hook';
    });
  }

  static final _purposeLine = RegExp(r'^Purpose:\s*(.*)$', multiLine: true);

  /// The purpose written in the story, or empty.
  String get _purpose => _purposeLine.firstMatch(_descCtrl.text)?.group(1)?.trim() ?? '';

  /// Sets the story's purpose line, adding it at the top if it is not there yet.
  void _setPurpose(String purpose) {
    final text = _descCtrl.text;
    setState(() {
      _descCtrl.text = _purposeLine.hasMatch(text)
          ? text.replaceFirst(_purposeLine, 'Purpose: $purpose')
          : 'Purpose: $purpose\n$text';
    });
  }

  /// True when this exact story already has a script written for it.
  ///
  /// Checked against a fingerprint of the story text rather than just "has a script",
  /// because the story autosaves as you edit it — a script written for yesterday's
  /// version is not a script for today's.
  bool get _hasSavedScript =>
      _project != null &&
      _project!.script.isNotEmpty &&
      _project!.scriptStoryKey == fingerprint(_descCtrl.text.trim());

  /// Opens the script already written for this story. No request.
  void _continueSaved() {
    final lines = parseScript(_project!.script.join('\n'));
    if (lines.isEmpty) { _generate(force: true); return; }
    _openScript(lines);
  }

  /// [force] writes a new script even when this story already has one.
  Future<void> _generate({bool force = false}) async {
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _status = 'Type what happens in the story first — without it Gemini makes one up.');
      return;
    }
    if (!force && _hasSavedScript) { _continueSaved(); return; }
    setState(() { _isGenerating = true; _status = 'Writing the script with Gemini...'; });
    final story = _descCtrl.text.trim();
    final expectedLines = (_seconds / 4).floor().clamp(4, 20);

    try {
      // One request for the whole reel where it fits, rather than one for the script
      // and another for the prompts. On a free tier the second request is the one
      // that runs you out, and the prompts arrive already written down so opening
      // that screen later costs nothing either.
      if (expectedLines <= kCombinedLineLimit) {
        try {
          final package = await generateEverything(
            storyDescription: story,
            language: _language,
            style: _style,
            seconds: _seconds,
            expectedLines: expectedLines,
            onWait: (message) { if (mounted) setState(() => _status = message); },
          );
          final lines = parseScript(package.scriptLines.join('\n'));
          if (lines.isNotEmpty) {
            if (!mounted) return;
            _openScript(lines, prompts: package.prompts);
            if (mounted) setState(() => _isGenerating = false);
            return;
          }
          // Parsed to nothing, which is the same as not having worked.
        } on CombinedCallFailed catch (e) {
          // Expected often enough not to be an error anyone should read. The two
          // smaller calls fit where the big one did not, so just take that road.
          if (mounted) {
            setState(() => _status = 'Writing it in two steps instead '
                '(${e.reason})...');
          }
        }
      }

      final lines = await generateScriptWithGemini(
        videoDescription: story,
        language: _language,
        style: _style,
        videoDuration: _seconds.toDouble(),
        onWait: (message) { if (mounted) setState(() => _status = message); },
      );
      if (!mounted) return;
      _openScript(lines);
    } catch (e) {
      setState(() => _status = '❌ $e');
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Reel Maker'),
        actions: [
          // The dependable way to begin the next reel. Clearing the box works too, but
          // pasting a new story over the old one cannot be told apart from editing it.
          IconButton(
            tooltip: 'New story',
            icon: const Icon(Icons.note_add_outlined, size: 21),
            onPressed: _isGenerating ? null : () => _startNewStory(
              status: 'New story. The last one is in Saved stories.'),
          ),
          IconButton(
            tooltip: 'Plan: hooks, when to post, results',
            icon: const Icon(Icons.calendar_month_outlined, size: 21),
            onPressed: _isGenerating ? null : _openPlan,
          ),
          IconButton(
            tooltip: 'Saved stories',
            icon: const Icon(Icons.folder_open, size: 21),
            onPressed: _isGenerating ? null : _openSaved,
          ),
          IconButton(
            tooltip: 'Quick Content Studio',
            icon: const Icon(Icons.article_outlined, size: 21),
            onPressed: _isGenerating ? null : () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QuickContentScreen())),
          ),
          // The old-path entry lives up here now. It still works, but it is not what
          // the app is for, and as a full-width button it read like a main choice.
          IconButton(
            tooltip: 'Add voice to a video I already have',
            icon: const Icon(Icons.video_library_outlined, size: 20),
            onPressed: _isGenerating ? null : () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HomeScreen())),
          ),
        ],
      ),
      body: Column(children: [
        const StepBar(steps: kSteps, current: 0),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Text("What's the story?", style: AppText.screenTitle),
              Gap.xs,
              const Text('A few lines is enough. The more you say about what actually '
                  'happens, the closer the script stays to your story.',
                style: AppText.hint),
              Gap.m,

              TextField(
                controller: _descCtrl,
                maxLines: 10,
                minLines: 6,
                style: AppText.body,
                decoration: const InputDecoration(
                  hintText: 'e.g. Cuty ka gajar gum ho gaya. Ria aur Rio dono ek dusre '
                      'ko blame karte hain. Phir milkar dhoondte hain aur sofa ke '
                      'neeche mil jaata hai. Sab hass padte hain.',
                ),
              ),
              Gap.s,

              // Real buttons rather than three tiny text links crammed above the box.
              // These are the three things worth doing before writing a script, and
              // they were the least visible controls on the screen.
              Row(children: [
                Expanded(child: SecondaryButton(
                  label: 'Idea', icon: Icons.lightbulb_outline,
                  colour: AppColors.accent,
                  onPressed: _isGenerating ? null : _askForIdea)),
                Gap.wS,
                Expanded(child: SecondaryButton(
                  label: 'Check', icon: Icons.fact_check_outlined,
                  onPressed: _isGenerating ? null : _checkStory)),
                Gap.wS,
                Expanded(child: SecondaryButton(
                  label: 'Form', icon: Icons.list_alt,
                  onPressed: _isGenerating ? null : _useFormat)),
              ]),
              Gap.l,

              // Chosen before the script, because the purpose decides how the story is
              // built — a funny reel and a save-worthy one turn in different places.
              // Kept as a line in the story itself, so it is saved with it and seen by
              // every prompt without anything else needing to carry it.
              const SectionTitle('What is this reel for?'),
              _chips(kReelPurposes.map((p) => _Choice(p, _purpose == p,
                  () => _setPurpose(p)))),
              Gap.l,

              const SectionTitle('How long'),
              _chips(_lengths.map((s) => _Choice('$s sec', _seconds == s,
                  () => setState(() => _seconds = s)))),
              Gap.l,

              const SectionTitle('Tone'),
              _chips(kVoiceProfiles.keys.map((s) => _Choice(s, _style == s,
                  () => setState(() => _style = s)))),
              Gap.l,

              const SectionTitle('Language'),
              _chips(_languages.map((l) => _Choice(l, _language == l,
                  () => setState(() => _language = l)))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            StatusBar(message: _status, onCopy: () {
              Clipboard.setData(ClipboardData(text: _status));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Copied'), duration: Duration(seconds: 1)));
            }),
            PrimaryButton(
              // Says "continue" when the script already exists, because that is what
              // it does — and a button that says "write" teaches you to expect a
              // request and a new script every time you press it.
              label: _isGenerating
                  ? 'Writing the script...'
                  : _hasSavedScript ? 'Continue with this story' : 'Write the script',
              icon: _hasSavedScript ? Icons.arrow_forward : Icons.auto_awesome,
              loading: _isGenerating,
              onPressed: _generate,
            ),
            Gap.s,
            if (_hasSavedScript)
              TextButton.icon(
                onPressed: _isGenerating ? null : () => _generate(force: true),
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Write a new script instead (uses a request)',
                  style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSoft),
              )
            else
              TextButton.icon(
                onPressed: _isGenerating ? null : () => _openScript(const []),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Or write the script myself',
                  style: TextStyle(fontSize: 14)),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSoft),
              ),
          ]),
        ),
      ]),
    );
  }

  /// A row of choices that wraps. One place, so all three groups look the same —
  /// they were three different ChoiceChip calls with three different text sizes.
  Widget _chips(Iterable<_Choice> choices) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: choices.map((c) => GestureDetector(
          onTap: c.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: c.selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: c.selected ? AppColors.primary : AppColors.border),
            ),
            child: Text(c.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: c.selected ? FontWeight.w700 : FontWeight.w500,
                color: c.selected ? Colors.white : AppColors.text)),
          ),
        )).toList(),
      );
}

/// Five hooks, each with its type and a Use this button; the chosen one is marked.
class _HookPicker extends StatefulWidget {
  final List<HookChoice> hooks;
  final String chosen;
  final void Function(String hook) onUse;
  const _HookPicker({required this.hooks, required this.chosen, required this.onUse});

  @override
  State<_HookPicker> createState() => _HookPickerState();
}

class _HookPickerState extends State<_HookPicker> {
  late String _chosen = widget.chosen;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.hooks.map((h) {
          final isChosen = h.text == _chosen;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(isChosen ? Icons.check_circle : Icons.circle_outlined,
                size: 18, color: isChosen ? AppColors.primary : AppColors.textFaint),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.text, style: TextStyle(fontSize: 15,
                  fontWeight: isChosen ? FontWeight.w800 : FontWeight.w600)),
                if (h.type.isNotEmpty) Text(h.type, style: AppText.small),
              ])),
              if (!isChosen)
                TextButton(
                  onPressed: () {
                    setState(() => _chosen = h.text);
                    widget.onUse(h.text);
                  },
                  child: const Text('Use this')),
            ]),
          );
        }).toList(),
      );
}

/// One option in a chip row.
class _Choice {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice(this.label, this.selected, this.onTap);
}


// ── Story Input Screen ────────────────────────────────────────────────────────

class StoryInputScreen extends StatefulWidget {
  final File videoFile;
  final double videoDuration;
  const StoryInputScreen({super.key, required this.videoFile, required this.videoDuration});
  @override
  State<StoryInputScreen> createState() => _StoryInputScreenState();
}

class _StoryInputScreenState extends State<StoryInputScreen> {
  final _languages = ['Hinglish', 'English', 'Hindi'];
  String _style    = '❤️ Heartwarming';
  String _language = 'Hinglish';
  bool _isGenerating = false;
  String _genStatus  = '';
  final _descCtrl = TextEditingController();

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  Future<void> _autoGenerate() async {
    setState(() { _isGenerating = true; _genStatus = 'Analyzing video with Gemini AI...'; });
    try {
      final lines = await generateScriptWithGemini(
        videoDescription: _descCtrl.text.trim(),
        language: _language,
        style: _style,
        videoDuration: widget.videoDuration,
        onWait: (message) { if (mounted) setState(() => _genStatus = message); },
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TimedScriptScreen(
          style: _style, language: _language,
          videoFile: widget.videoFile, initialLines: lines,
        ),
      ));
    } catch (e) {
      setState(() { _genStatus = '❌ $e'; });
    }
    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Voice Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(children: [
              ...kVoiceProfiles.keys.map((s) => RadioListTile<String>(
                value: s, groupValue: _style,
                title: Text(s), dense: true,
                onChanged: (v) => setState(() => _style = v!),
              )),
              const SizedBox(height: 16),
              const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _language, dropdownColor: AppColors.surface,
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _language = v!),
              ),
              const SizedBox(height: 16),
              const Text('Video Description (for AI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Ria aur Rio ek teddy ke liye ladte hain, phir Rio share karta hai aur sab khush ho jaate hain',
                  hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 12),
                  filled: true, fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
      if (_genStatus.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(_genStatus, style: const TextStyle(fontSize: 12))),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: AppColors.textSoft),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _genStatus));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error copied!'), duration: Duration(seconds: 1)));
                      },
                    ),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          // Auto-generate with Gemini
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _autoGenerate,
              icon: _isGenerating
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Analyzing video...' : '✨ Auto-Generate Script (AI)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppColors.border,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Manual script
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => TimedScriptScreen(
                  style: _style, language: _language,
                  videoFile: widget.videoFile, initialLines: [],
                ),
              )),
              icon: const Icon(Icons.edit),
              label: const Text('Write Script Manually'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: AppColors.border,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Timed Script Screen ───────────────────────────────────────────────────────

class TimedScriptScreen extends StatefulWidget {
  final String style;
  final String language;
  /// Null in image mode — there is no source video to lay the voice over.
  final File? videoFile;
  /// Empty in video mode. When present the reel is built from these instead.
  final List<String> images;
  final List<ScriptLine> initialLines;
  /// Which voice speaks it. Phone by default, because that one always works.
  final VoiceEngine engine;
  /// What you typed on the story screen. Carried through so the AI prompts can
  /// describe the same story rather than guessing it back from the script lines.
  final String storyDescription;
  /// Target length, for the timings in the video prompt.
  final int seconds;
  /// The saved story this belongs to, so edits here are written back to it rather
  /// than being lost the moment anything on this screen fails. Empty in video mode.
  final String projectId;
  const TimedScriptScreen({
    super.key, required this.style, required this.language,
    required this.videoFile, required this.initialLines,
    this.images = const [],
    this.engine = VoiceEngine.phone,
    this.storyDescription = '',
    this.seconds = 30,
    this.projectId = '',
  });

  @override
  State<TimedScriptScreen> createState() => _TimedScriptScreenState();
}

class _TimedScriptScreenState extends State<TimedScriptScreen> {
  final FlutterTts _tts = FlutterTts();
  late List<ScriptLine> _lines;
  bool _isPlaying = false;
  bool _isSaving  = false;
  bool _isMerging = false;
  int  _activeIdx = -1;
  String? _audioPath;
  String  _status = '';
  bool _showPaste = false;

  final _pasteCtrl = TextEditingController();
  List<TextEditingController> _textCtrls = [];
  List<TextEditingController> _timeCtrls = [];
  final List<Timer> _timers = [];

  /// The pictures the reel is built from. Chosen here rather than before the script,
  /// because until the script exists you don't know how many moments there are to show.
  List<String> _images = [];

  /// True when there is no source video, so the reel has to be built from pictures.
  bool get _storyMode => widget.videoFile == null;

  /// Changeable here rather than only on the story screen, so you can hear one engine,
  /// switch, and hear the difference without starting the script again.
  late VoiceEngine _engine;

  /// When each line actually starts in the saved voice, in seconds.
  ///
  /// For the line-by-line engines these are the script's own timestamps, because that
  /// is what the audio was built to. For a single-pass read they are estimated from
  /// line length, since there are no separate files to measure.
  List<double> _lineStarts = [];

  /// Burn the script onto the video. On by default — most reels are watched muted,
  /// so a reel with no text on screen is a reel nobody understands.
  bool _captions = true;
  /// Both only affect rendering, so changing either does not throw away the voice.
  ///
  /// Top by default. Across the middle it sits on the faces and the thing the picture
  /// is of, which breaks the moment the picture exists to carry.
  CaptionSpot _captionSpot = CaptionSpot.high;
  /// The closing brand card. On by default — it should be on every reel.
  bool _endCard = true;

  /// The big cover words on picture 1. On by default, because that picture is the
  /// thumbnail; switchable, and separate from Captions, for reels that want it clean.
  bool _coverHook = true;

  /// The Moment look: every picture as a tilted printed photo over a blurred copy of
  /// itself. Off unless chosen — it changes how every reel looks, so it is a decision
  /// you make, not something that happens to you.
  bool _moment = false;

  /// Which of Script, Pictures, Voice, Reel is showing. One screen, four views, so
  /// nothing about the state or the pipeline had to move to make it step by step.
  int _step = 0;
  ClipMotion _motion = ClipMotion.drift;

  /// Which bundled track plays under the voice. Null means none.
  MusicTrack? _music;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine;
    _images = List.of(widget.images);
    _lines = List.from(widget.initialLines);
    _showPaste = _lines.isEmpty;
    _textCtrls = _lines.map((l) => TextEditingController(text: l.text)).toList();
    _timeCtrls = _lines.map((l) => TextEditingController(text: fmtDuration(l.time))).toList();
    _initTts();
    // Brings back the pictures, voice and settings this story was left with, and finds
    // the reel if one was already made — so coming back never means starting over.
    _restoreFromProject();
  }

  VoiceProfile get _vp => kVoiceProfiles[widget.style] ?? const VoiceProfile(0.55, 1.1);

  Future<void> _initTts() async {
    final locale = widget.language == 'English' ? 'en-IN' : 'hi-IN';
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(_vp.rate);
    await _tts.setPitch(_vp.pitch);
    await _tts.setVolume(1.0);
  }

  void _applyPaste() {
    final parsed = parseScript(_pasteCtrl.text);
    if (parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid lines. Format: 0:05 Your text here')));
      return;
    }
    for (final c in _textCtrls) c.dispose();
    for (final c in _timeCtrls) c.dispose();
    setState(() {
      _lines = parsed;
      _textCtrls = _lines.map((l) => TextEditingController(text: l.text)).toList();
      _timeCtrls = _lines.map((l) => TextEditingController(text: fmtDuration(l.time))).toList();
      _showPaste = false; _audioPath = null; _lineStarts = []; _status = '';
    });
  }

  void _syncLines() {
    var wordsChanged = false;
    var timesChanged = false;

    for (int i = 0; i < _lines.length; i++) {
      final edited = _textCtrls[i].text;
      // An edited line no longer matches its Devanagari twin, so drop that and speak
      // what is on screen rather than the sentence it used to be.
      if (edited != _lines[i].text) {
        _lines[i].speak = null;
        wordsChanged = true;
      }
      final time = parseDuration(_timeCtrls[i].text);
      if (time != _lines[i].time) timesChanged = true;

      _lines[i].text = edited;
      _lines[i].time = time;
    }

    // Written back on every edit, so a failure later on this screen — a busy Gemini,
    // a render that dies — costs the render and nothing else.
    _saveProject();

    // Words and times are not the same kind of change, and treating them as one was
    // making every small timing fix cost a whole re-recording.
    //
    // A one-take Gemini read is one continuous recording. The times only say when the
    // picture changes, so nudging one does not make the voice wrong — nothing about
    // the audio depends on them. The phone and ElevenLabs are different: their track
    // is BUILT to those timestamps with silence between the lines, so there a time
    // change really does make the saved audio wrong.
    // Any edit at all means the saved reel shows something different from the screen.
    if (wordsChanged || timesChanged) _matchingReel = null;

    final voiceIsOneTake = _engine == VoiceEngine.gemini;
    final voiceStale = wordsChanged || (timesChanged && !voiceIsOneTake);

    if (_audioPath == null) return;

    if (voiceStale) {
      _audioPath = null;
      _lineStarts = [];
      _status = wordsChanged
          ? 'Script changed — tap Save Voice again.'
          : 'Times changed — tap Save Voice again.';
      return;
    }

    // Times moved and the voice still stands: keep it, and just move the pictures.
    if (timesChanged) {
      // Only the lines you actually moved take the new time. The rest keep the start
      // measured from the voice's own pauses, to the millisecond. Rebuilding them all
      // from the boxes rounded every picture change to a whole second, so nudging one
      // line put every other picture up to half a second off the words.
      final measured = _lineStarts;
      _lineStarts = List.generate(_lines.length, (i) {
        final shown = _lines[i].time.inMilliseconds / 1000.0;
        final untouched = i < measured.length &&
            measured[i].round() == _lines[i].time.inSeconds;
        return untouched ? measured[i] : shown;
      });
      _status = 'Picture times updated — tap Make Reel to build it again.';
    }
  }

  void _addLine() {
    _syncLines();
    final lastTime = _lines.isNotEmpty ? _lines.last.time + const Duration(seconds: 4) : Duration.zero;
    setState(() {
      _lines.add(ScriptLine(lastTime, ''));
      _textCtrls.add(TextEditingController());
      _timeCtrls.add(TextEditingController(text: fmtDuration(lastTime)));
      _scriptShapeChanged();
    });
    _saveProject();
  }

  void _removeLine(int i) {
    _syncLines();
    setState(() {
      _lines.removeAt(i);
      _textCtrls.removeAt(i).dispose();
      _timeCtrls.removeAt(i).dispose();
      _scriptShapeChanged();
    });
    // Saved, or the removed line comes back the next time this story is opened.
    _saveProject();
  }

  /// A line added or removed after recording: the voice no longer matches.
  ///
  /// Editing a line is noticed by comparing each box with its line, but adding or
  /// removing one moves the boxes and the lines together, so nothing looked changed.
  /// The reel was then built from a voice still saying the deleted line, with every
  /// picture after it a line out of step.
  void _scriptShapeChanged() {
    _matchingReel = null;
    if (_audioPath != null) {
      _audioPath = null;
      _lineStarts = [];
      _status = 'Lines changed — the voice will be recorded again for the new script.';
    }
  }

  /// Preview always speaks with the phone, whatever engine is selected — it is instant
  /// and costs nothing, where Gemini and ElevenLabs would mean a network call per line
  /// every time you tapped it. Say so, or the preview sounds like the engine is broken.
  Future<void> _previewAll() async {
    _syncLines();
    _cancelTimers();
    setState(() {
      _isPlaying = true;
      _activeIdx = -1;
      _status = _engine == VoiceEngine.phone
          ? ''
          : 'Preview uses the phone voice. Tap Save Voice to hear ${voiceEngineLabel(_engine)}.';
    });
    await _initTts();
    for (int i = 0; i < _lines.length; i++) {
      final idx = i;
      final text = cleanForTts(_lines[i].spoken);
      final delay = _lines[i].time;
      _timers.add(Timer(delay, () async {
        if (!_isPlaying || !mounted) return;
        setState(() => _activeIdx = idx);
        await _tts.stop();
        await _tts.speak(text);
      }));
    }
    final lastTime = _lines.isNotEmpty ? _lines.last.time : Duration.zero;
    _timers.add(Timer(lastTime + const Duration(seconds: 12), () {
      if (mounted) setState(() { _isPlaying = false; _activeIdx = -1; });
    }));
  }

  void _stopPreview() {
    _cancelTimers(); _tts.stop();
    setState(() { _isPlaying = false; _activeIdx = -1; });
  }

  void _cancelTimers() { for (final t in _timers) t.cancel(); _timers.clear(); }

  /// Reads the whole script in one pass. One request instead of ten keeps it inside
  /// the free tier, and the voice keeps its rhythm across sentences instead of being
  /// stitched from clips — which is most of what makes stitched speech sound robotic.
  Future<void> _saveGeminiInOnePass() async {
    final dir = await getTemporaryDirectory();
    final style = widget.style.replaceAll(RegExp(r'[^\w\s-]'), '').trim();

    setState(() => _status = 'Reading the whole story in one take...');
    final path = await synthesizeWholeScript(
      lines: _lines.map((l) => cleanForTts(l.spoken)).toList(),
      basePath: '${dir.path}/narration_gemini',
      apiKey: _geminiKey,
      styleHint: voiceDirection(style),
      onWait: (message) { if (mounted) setState(() => _status = message); },
    );

    final total = await getMediaDuration(path);
    if (total == null) throw Exception('Could not read the voice that was just made.');

    // Where the voice actually stopped between lines, rather than where a line of that
    // length was expected to end. This is what keeps the pictures on the story.
    setState(() => _status = 'Listening for where each line ends...');
    final pauses = await findVoicePauses(path);

    _audioPath = path;
    _lineStarts = alignedLineStarts(
      texts: _lines.map((l) => l.spoken).toList(),
      totalSeconds: total,
      pauses: pauses,
    );

    // The timeline on screen is what the line cards show, so move it onto the real
    // timings too — otherwise the numbers say one thing and the reel does another.
    //
    // Rounded to the second, and the line and its box are set from the same rounded
    // value on purpose: _syncLines treats any difference between the two as an edit
    // and throws the voice away, so writing 3.4 into a box that reads back as 3 would
    // clear the audio the moment anything else was tapped.
    for (int i = 0; i < _lines.length && i < _lineStarts.length; i++) {
      final shown = Duration(seconds: _lineStarts[i].round());
      _lines[i].time = shown;
      _timeCtrls[i].text = fmtDuration(shown);
    }
  }

  /// Speaks one line in the chosen voice so it can be heard before a reel is built.
  Future<void> _hearVoiceSample() async {
    setState(() { _isSaving = true; _status = 'Making a sample in $geminiVoiceName...'; });
    try {
      final dir = await getTemporaryDirectory();
      final style = widget.style.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final wav = await speakSample(
        apiKey: _geminiKey,
        style: style,
        onWait: (message) { if (mounted) setState(() => _status = message); },
      );

      // Converted before playing: the player is happy with m4a everywhere, and a raw
      // WAV with no video track is the kind of thing it sometimes refuses.
      final playable = '${dir.path}/sample_voice.m4a';
      final old = File(playable);
      if (await old.exists()) await old.delete();
      await FFmpegKit.executeWithArguments(
        ['-i', wav, '-c:a', 'aac', '-b:a', '128k', '-y', playable]);

      if (!mounted) return;
      setState(() { _isSaving = false; _status = ''; });
      await _playSample(File(playable));
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _status = '❌ $e'; });
    }
  }

  /// Plays the sample and holds the dialog open until it is closed, so the player is
  /// always disposed — a left-running player keeps speaking over the next screen.
  Future<void> _playSample(File file) async {
    final player = VideoPlayerController.file(file);
    try {
      await player.initialize();
      await player.play();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(geminiVoiceName, style: const TextStyle(fontSize: 16)),
          content: Text(kVoiceSampleText,
            style: const TextStyle(fontSize: 13, color: AppColors.textSoft)),
          actions: [
            TextButton(
              onPressed: () { player.seekTo(Duration.zero); player.play(); },
              child: const Text('Again')),
            TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
        ),
      );
    } finally {
      await player.dispose();
    }
  }

  /// The voice list, with what each one actually sounds like next to it.
  Future<void> _pickVoice() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: kGeminiVoices.map((v) => ListTile(
            dense: true,
            leading: Icon(
              v.name == geminiVoiceName
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: v.name == geminiVoiceName ? AppColors.primary : AppColors.textFaint),
            title: Text(v.name, style: const TextStyle(fontSize: 14)),
            subtitle: Text(v.note,
              style: const TextStyle(fontSize: 11, color: AppColors.textSoft)),
            onTap: () => Navigator.pop(ctx, v.name),
          )).toList(),
        ),
      ),
    );

    if (chosen == null || !mounted) return;
    // Same voice picked again: keep what was recorded with it.
    if (chosen == geminiVoiceName) return;
    setState(() {
      geminiVoiceName = chosen;
      // The saved voice was spoken by the old one, so it no longer matches the choice.
      _audioPath = null;
      _lineStarts = [];
      _matchingReel = null;
      _status = 'Voice set to $chosen. Tap Hear it, or Save Voice to use it.';
    });
    _saveProject();
  }

  /// Speaks every line to its own file, then lays them out on a timeline with FFmpeg.
  Future<void> _saveAudio() async {
    _syncLines();
    if (_lines.isEmpty) { setState(() => _status = 'No lines to save!'); return; }

    setState(() { _isSaving = true; _status = 'Generating voice...'; });

    // Gemini reads the script in one request; the other engines speak line by line and
    // are laid out on a timeline below.
    if (_engine == VoiceEngine.gemini) {
      try {
        await _saveGeminiInOnePass();
        // Kept, so this is the last request this voice ever costs.
        await _persistVoice();
        setState(() {
          _status = _storyMode
              ? '✅ Voice ready. Now tap Build Video.'
              : '✅ Voice ready. Now tap Merge with Video.';
        });
      } catch (e) {
        setState(() { _status = '❌ $e'; _audioPath = null; });
      }
      setState(() => _isSaving = false);
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final segPaths = <String>[];
      final locale = widget.language == 'English' ? 'en-IN' : 'hi-IN';
      final engineName = voiceEngineLabel(_engine);

      // Step 1: one file per line, from whichever voice is selected.
      for (int i = 0; i < _lines.length; i++) {
        setState(() => _status = '$engineName voice: line ${i + 1} of ${_lines.length}...');
        // `spoken` is the Devanagari half for Hinglish, and the plain text otherwise.
        segPaths.add(await synthesizeLine(
          engine: _engine,
          text: cleanForTts(_lines[i].spoken),
          basePath: '${dir.path}/seg_$i',
          languageTag: locale,
          rate: _vp.rate,
          pitch: _vp.pitch,
          geminiKey: _geminiKey,
          elevenLabsKey: _elevenLabsKey,
          elevenVoiceId: _elevenVoiceId,
          // Waiting out a rate limit takes longer than the speaking does, so say so
          // rather than leaving the button spinning with nothing happening.
          onWait: (message) {
            if (mounted) {
              setState(() => _status = 'Line ${i + 1} of ${_lines.length} — $message');
            }
          },
        ));
      }

      setState(() => _status = 'Building timed audio track...');

      // Step 2: how long each spoken line actually is, so the gaps can be worked out.
      final segDurations = <double>[];
      for (final p in segPaths) {
        segDurations.add(await getMediaDuration(p) ?? 3.0);
      }

      // Step 3: Build a single audio track using silence + concat
      // For each line: insert silence from previous end to this line's timestamp,
      // then the audio segment. This guarantees ZERO overlap.
      final parts = <String>[];
      double cursor = 0.0;

      for (int i = 0; i < _lines.length; i++) {
        final targetMs = _lines[i].time.inMilliseconds / 1000.0;
        final silenceDur = (targetMs - cursor).clamp(0.0, double.infinity);

        if (silenceDur > 0.01) {
          // Generate silence segment
          final silPath = '${dir.path}/sil_$i.wav';
          await FFmpegKit.executeWithArguments([
            '-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=mono',
            '-t', silenceDur.toStringAsFixed(3),
            '-y', silPath,
          ]);
          parts.add(silPath);
        }

        parts.add(segPaths[i]);
        cursor = targetMs + segDurations[i];
      }

      // Concat all parts into final audio
      _audioPath = '${dir.path}/narration_final.wav';
      if (await File(_audioPath!).exists()) await File(_audioPath!).delete();

      // Concat refuses inputs that disagree on sample rate or channel layout, and the TTS
      // files rarely match the generated silence — so put every input through aformat first.
      final inputs = <String>[];
      for (final p in parts) {
        inputs.addAll(['-i', p]);
      }
      final normalised = List.generate(parts.length,
          (i) => '[$i:a]aformat=sample_fmts=s16:sample_rates=44100:channel_layouts=mono[a$i]');
      final joined = List.generate(parts.length, (i) => '[a$i]').join();
      final concatFilter = '${normalised.join(';')};${joined}concat=n=${parts.length}:v=0:a=1[out]';

      final session = await FFmpegKit.executeWithArguments([
        ...inputs,
        '-filter_complex', concatFilter,
        '-map', '[out]',
        '-y', _audioPath!,
      ]);
      final rc = await session.getReturnCode();
      if (!ReturnCode.isSuccess(rc)) {
        final logs = await session.getAllLogsAsString();
        throw Exception('FFmpeg concat failed: $logs');
      }

      // This track was built to the script's own timestamps, so the pictures follow them.
      _lineStarts = _lines.map((l) => l.time.inMilliseconds / 1000.0).toList();
      await _persistVoice();

      // Says which button to press next, and doesn't call the phone's voice "AI".
      setState(() {
        _status = _storyMode
            ? '✅ Voice ready. Now tap Build Video.'
            : '✅ Voice ready. Now tap Merge with Video.';
      });
    } catch (e) {
      setState(() { _status = '❌ $e'; _audioPath = null; });
    }
    setState(() => _isSaving = false);
  }

  /// Picks the background track, or turns music off.
  Future<void> _pickMusic() async {
    // "No music" and swiping the sheet away would both come back as null, and they
    // mean different things — one is a choice, the other is cancelling. So the choice
    // is recorded as it happens rather than read from the return value.
    MusicTrack? picked;
    var didChoose = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          ListTile(
            leading: const Icon(Icons.music_off),
            title: const Text('No music'),
            selected: _music == null,
            onTap: () { didChoose = true; picked = null; Navigator.pop(ctx); },
          ),
          const Divider(height: 1),
          ...kMusicLibrary.map((t) => ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(t.name),
                subtitle: Text(t.mood, style: const TextStyle(fontSize: 11)),
                selected: _music?.asset == t.asset,
                onTap: () { didChoose = true; picked = t; Navigator.pop(ctx); },
              )),
        ]),
      ),
    );

    if (!mounted || !didChoose) return;
    setState(() => _music = picked);
  }

  /// Prompts for an image or video generator, built from this script.
  void _openPrompts() {
    _syncLines();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PromptScreen(
        // Falls back to the script itself, so prompts still work for a pasted script
        // that never went through the story screen.
        storyDescription: widget.storyDescription.trim().isNotEmpty
            ? widget.storyDescription
            : _lines.map((l) => l.text).join(' '),
        scriptLines: _lines.map((l) => l.text).toList(),
        seconds: widget.seconds,
        // So the prompts are written down against this story and read back next time
        // instead of being asked for again.
        projectId: widget.projectId,
      ),
    // Coming back, the prompts screen may have written the cover options for the first
    // time — long reels and pasted scripts get them there, not with the script — or
    // changed the cover. Read them again so the Script step shows what is saved.
    )).then((_) {
      _loadHookChoices();
      _checkSavedReel();
    });
  }

  /// Builds the reel from the chosen images instead of a source video.
  Future<void> _buildFromImages() async {
    // Sync FIRST: it clears the saved voice when the script has changed since, so
    // checking before it would pass and then hand a null path to the builder.
    _syncLines();
    if (_audioPath == null) {
      setState(() => _status = 'Tap Save Voice first.');
      return;
    }

    // Already made from exactly this? Then open it. Rebuilding an identical reel costs
    // minutes and gives you the same file you already had.
    await _checkSavedReel();
    if (_matchingReel != null) {
      if (!mounted) return;
      _openReel(_matchingReel!);
      return;
    }

    setState(() { _isMerging = true; _status = 'Building the video...'; });
    try {
      final dir = await getTemporaryDirectory();
      // The cover hook and the closing question were written when the prompts were,
      // and are read back off the phone here. Nothing is asked of Gemini to build a
      // reel — that would be a request spent on words already written down.
      final post = await _savedPost();
      final outPath = await SlideshowBuilder.build(
        imagePaths: _images,
        // One image per line, so the picture changes as the story moves on.
        // Set when the voice was saved — either the script's timestamps or, for a
        // single-pass read, where each line was estimated to fall.
        lineStarts: _lineStarts.isNotEmpty
            ? _lineStarts
            : _lines.map((l) => l.time.inMilliseconds / 1000.0).toList(),
        audioPath: _audioPath!,
        workDir: dir.path,
        // Unpacked from the APK to a real file, because FFmpeg needs a path.
        musicPath: _music == null ? null : await unpackTrack(_music!, dir.path),
        // Drawn by Flutter, not FFmpeg's drawtext: drawtext does no complex-script
        // shaping, so Devanagari conjuncts and matras come out in the wrong places.
        captionPngs: await _captionPngs(dir.path, post),
        // The same closing shape on every reel, which is the point of it — a channel
        // gets recognised by what repeats, not by what varies.
        brandPng: _endCard
            ? await renderBrandCard('${dir.path}/brand_card.png',
                message: post.closing)
            : null,
        captionSpot: _captionSpot,
        motion: _motion,
        // Picture 1 carries the cover hook when it is switched on, captions or not.
        coverOnFirst: _coverHook,
        moment: _moment ? await _momentFrames(dir.path, post) : null,
        onStatus: (message) { if (mounted) setState(() => _status = message); },
      );
      // Out of the cache folder and into the app's own storage, with a note of what it
      // was made from. This is what lets you leave, come back, and find it waiting.
      var reelPath = outPath;
      if (widget.projectId.isNotEmpty) {
        reelPath = await keepFile(outPath, 'reels', '${widget.projectId}.mp4');
        final key = await _reelKey();
        final look = _lookMap();
        final kept = reelPath;
        await ProjectStore.update(widget.projectId, (p) => p.copyWith(
          reelPath: kept,
          reelKey: key,
          // A new reel is a new file the gallery has not seen.
          inGallery: false,
          look: look,
        ));
      }

      if (!mounted) return;
      setState(() { _status = ''; _isMerging = false; _matchingReel = reelPath; });
      _openReel(reelPath);
      return;
    } catch (e) {
      setState(() { _status = '❌ $e'; });
    }
    if (mounted) setState(() => _isMerging = false);
  }

  Future<void> _mergeWithVideo() async {
    // Same order as above: sync can clear the voice, so check after it.
    _syncLines();
    if (_audioPath == null) {
      setState(() => _status = 'Tap Save Voice first.');
      return;
    }
    final video = widget.videoFile;
    if (video == null) { setState(() => _status = 'No video to merge with.'); return; }
    setState(() { _isMerging = true; _status = 'Merging voice with video...'; });
    try {
      final dir = await getTemporaryDirectory();
      final tmpPath = '${dir.path}/reel_preview.mp4';
      if (await File(tmpPath).exists()) await File(tmpPath).delete();

      final session = await FFmpegKit.executeWithArguments([
        '-i', video.path,
        '-itsoffset', '-0.5',
        '-i', _audioPath!,
        '-map', '0:v:0', '-map', '1:a:0',
        '-shortest', '-c:v', 'libx264', '-crf', '28',
        '-preset', 'ultrafast',
        '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2',
        '-c:a', 'aac', '-b:a', '96k',
        '-movflags', '+faststart', '-y', tmpPath,
      ]);
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        setState(() { _status = ''; _isMerging = false; });
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PreviewMergedScreen(mergedFile: File(tmpPath)),
        ));
        return;
      } else {
        final logs = await session.getAllLogsAsString();
        setState(() { _status = '❌ Merge failed.\n$logs'; });
      }
    } catch (e) { setState(() { _status = '❌ $e'; }); }
    setState(() => _isMerging = false);
  }

  @override
  void dispose() {
    _cancelTimers(); _tts.stop(); _pasteCtrl.dispose();
    for (final c in _textCtrls) c.dispose();
    for (final c in _timeCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showPaste ? 'Paste a script' : kSteps[_step + 1]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showPaste) { setState(() => _showPaste = false); return; }
            if (_step > 0) { setState(() => _step -= 1); return; }
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_showPaste && _step == 0)
            IconButton(icon: const Icon(Icons.edit_note), tooltip: 'Paste a script',
              onPressed: () => setState(() => _showPaste = true)),
          if (!_showPaste && _step == 0)
            IconButton(icon: const Icon(Icons.add), tooltip: 'Add a line',
              onPressed: (_isSaving || _isMerging) ? null : _addLine),
        ],
      ),
      body: _showPaste ? _buildPastePanel() : _buildStep(),
    );
  }

  // ── The steps ───────────────────────────────────────────────────────────────
  //
  // One screen underneath, shown one job at a time. Everything used to be on this
  // screen at once — script, pictures, voice engine, voice name, captions, caption
  // position, motion, end card, music — in rows of ten-pixel grey chips that all
  // looked equally important, which meant none of them did.

  Widget _buildStep() {
    final busy = _isSaving || _isMerging;
    return Column(children: [
      StepBar(
        steps: kSteps,
        current: _step + 1,
        // Only backwards. A step ahead cannot be jumped to, because the app has no
        // way of knowing you did the ones in between.
        onTap: (i) {
          if (i == 0) { Navigator.pop(context); return; }
          setState(() => _step = i - 1);
          if (_step == 3) _checkSavedReel();
        },
      ),
      Expanded(child: _stepBody(busy)),
      _buildBottomBar(busy),
    ]);
  }

  Widget _stepBody(bool busy) {
    if (_step == 0) return _stepScript(busy);
    if (_step == 1) return _stepPictures(busy);
    if (_step == 2) return _stepVoice(busy);
    return _stepReel(busy);
  }

  /// Status and the one action for this step, always in the same place.
  Widget _buildBottomBar(bool busy) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        StatusBar(message: _status, onCopy: () {
          Clipboard.setData(ClipboardData(text: _status));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Copied'), duration: Duration(seconds: 1)));
        }),
        if (_step < 3)
          PrimaryButton(
            label: 'Next: ${kSteps[_step + 2].toLowerCase()}',
            onPressed: busy ? null : () {
              setState(() => _step += 1);
              // Arriving at the last step is when "is it already made?" matters.
              if (_step == 3) _checkSavedReel();
            },
          )
        // A reel already made from exactly this: the main button opens it, and making
        // it again is still possible but no longer the thing you reach for by default.
        else if (_matchingReel != null) ...[
          PrimaryButton(
            label: 'Open your reel',
            icon: Icons.play_circle_outline,
            onPressed: busy ? null : () => _openReel(_matchingReel!),
          ),
          TextButton(
            onPressed: busy ? null : () async {
              await ProjectStore.update(widget.projectId, (p) => p.copyWith(reelKey: ''));
              setState(() => _matchingReel = null);
              await _makeReel();
            },
            child: const Text('Build it again anyway',
              style: TextStyle(fontSize: 13, color: AppColors.textSoft)),
          ),
        ]
        else ...[
          if (_notReadyReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(child: Text(_notReadyReason,
                  style: const TextStyle(fontSize: 13, color: AppColors.warning))),
              ]),
            ),
          PrimaryButton(
            label: _isSaving
                ? 'Recording the voice...'
                : _isMerging
                    ? (_storyMode ? 'Building the reel...' : 'Merging...')
                    : (_storyMode ? 'Make the reel' : 'Merge with video'),
            icon: Icons.movie_creation_outlined,
            loading: _isMerging || _isSaving,
            onPressed: (busy || _lines.isEmpty || (_storyMode && _images.isEmpty))
                ? null : _makeReel,
          ),
        ],
      ]),
    );
  }

  // ── Step 1: the script ──────────────────────────────────────────────────────

  Widget _stepScript(bool busy) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const Text('Your script', style: AppText.screenTitle),
        Gap.xs,
        const Text('Edit any line. The time beside it is when its picture appears.',
          style: AppText.hint),
        Gap.m,

        // The first line gets its own card and its own label, because it is not just
        // another line — it is the three seconds that decide whether the rest is seen.
        if (_lines.isNotEmpty) ...[
          AppCard(
            colour: AppColors.accentSoft,
            borderColour: AppColors.accent,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.bolt, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('FIRST 3 SECONDS',
                  style: AppText.section.copyWith(color: AppColors.accent)),
              ]),
              Gap.s,
              TextField(
                controller: _textCtrls[0],
                maxLines: null,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.text, height: 1.35),
                decoration: const InputDecoration(
                  hintText: 'The line that stops someone scrolling',
                  isDense: true,
                ),
              ),
            ]),
          ),
          Gap.m,
        ],

        // Five kinds of cover hook, written with the script. You pick; the model only
        // suggests. The chosen one is drawn big on picture 1, which is the thumbnail.
        if (_hookChoices.isNotEmpty) ...[
          const SectionTitle('Cover words — pick one'),
          ..._hookChoices.map((c) {
            final chosen = c.text == _coverChoice;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: busy ? null : () => _chooseCover(c.text),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  colour: chosen ? AppColors.primarySoft : AppColors.surface,
                  borderColour: chosen ? AppColors.primary : AppColors.border,
                  child: Row(children: [
                    Icon(chosen ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 18, color: chosen ? AppColors.primary : AppColors.textFaint),
                    Gap.wS,
                    Expanded(child: Text(c.text, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text))),
                    Text(c.type, style: AppText.small),
                  ]),
                ),
              ),
            );
          }),
          Gap.m,
        ],

        SectionTitle('The rest', trailing: '${_lines.length} lines'),
        ...List.generate(_lines.length, (i) => i == 0
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _lineCard(i, busy),
              )),
        Gap.s,
        SecondaryButton(
          label: 'Add a line', icon: Icons.add,
          onPressed: busy ? null : _addLine),
      ],
    );
  }

  Widget _lineCard(int i, bool busy) {
    final isActive = _activeIdx == i;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      borderColour: isActive ? AppColors.primary : AppColors.border,
      colour: isActive ? AppColors.primarySoft : AppColors.surface,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          width: 52,
          child: TextField(
            controller: _timeCtrls[i],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.primary),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              isDense: true,
              fillColor: AppColors.surfaceAlt,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            ),
          ),
        ),
        Gap.wS,
        Expanded(
          child: TextField(
            controller: _textCtrls[i],
            maxLines: null,
            style: AppText.body,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintText: 'Type the line',
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: AppColors.textFaint),
          onPressed: busy ? null : () => _removeLine(i),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        ),
      ]),
    );
  }

  // ── Step 2: the pictures ────────────────────────────────────────────────────

  Widget _stepPictures(bool busy) {
    if (!_storyMode) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text(
          'Not needed here — you are adding a voice to a video you already have.',
          textAlign: TextAlign.center, style: AppText.hint)),
      );
    }

    final missing = _lines.length - _images.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const Text('Pictures', style: AppText.screenTitle),
        Gap.xs,
        const Text('One per line, in the order the story happens. Fewer than lines is '
            'fine — they repeat from the start.', style: AppText.hint),
        Gap.m,

        Row(children: [
          Expanded(child: SecondaryButton(
            label: 'Get prompts', icon: Icons.auto_fix_high,
            colour: AppColors.accent,
            onPressed: _lines.isEmpty ? null : _openPrompts)),
          Gap.wS,
          Expanded(child: SecondaryButton(
            label: 'Add pictures', icon: Icons.add_photo_alternate_outlined,
            onPressed: busy ? null : _pickImages)),
        ]),
        Gap.m,

        if (_images.isEmpty)
          AppCard(
            colour: AppColors.accentSoft,
            borderColour: AppColors.accent,
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.accent),
              SizedBox(width: 10),
              Expanded(child: Text(
                'No pictures yet. Tap Get prompts, make them in Meta AI, then come '
                'back and tap Add pictures.',
                style: TextStyle(fontSize: 13, color: AppColors.text, height: 1.4))),
            ]),
          )
        else ...[
          SectionTitle('Which picture goes where',
            trailing: missing > 0 ? '$missing repeat' : '${_images.length} pictures'),
          // Line and picture side by side, because the only question worth answering
          // here is whether the picture matches the words that play over it.
          ...List.generate(_lines.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                _lineStatus(i),
                Gap.wS,
                Expanded(child: Text(
                  _lines[i].text.isEmpty ? '(empty line)' : _lines[i].text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body)),
              ]),
            ),
          )),
          Gap.s,
          const SectionTitle('All pictures', trailing: 'tap one to remove it'),
          Wrap(spacing: 8, runSpacing: 8, children:
            List.generate(_images.length, (i) => GestureDetector(
              onTap: busy ? null : () => setState(() {
                _images.removeAt(i);
                _status = '';
                _matchingReel = null;
                // Remembered, or the removed picture comes back next time it opens.
                _saveProject();
              }),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(_images[i]),
                    width: 66, height: 94, fit: BoxFit.cover),
                ),
                Positioned(top: 3, left: 3, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.text.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('${i + 1}', style: const TextStyle(
                    fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                )),
              ]),
            )),
          ),
        ],
      ],
    );
  }

  // ── Step 3: the voice ───────────────────────────────────────────────────────

  Widget _stepVoice(bool busy) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const Text('The voice', style: AppText.screenTitle),
        Gap.xs,
        const Text('Gemini reads the whole script in one take, which is what keeps it '
            'sounding like a person rather than clips stitched together.',
          style: AppText.hint),
        Gap.m,

        ...VoiceEngine.values.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: busy ? null : () {
              // Tapping the engine already chosen is not a change, and must not throw
              // away a voice that took a request to make.
              if (_engine == e) return;
              setState(() {
                _engine = e;
                _audioPath = null;
                _lineStarts = [];
                _matchingReel = null;
                _status = '';
              });
              _saveProject();
            },
            child: AppCard(
              colour: _engine == e ? AppColors.primarySoft : AppColors.surface,
              borderColour: _engine == e ? AppColors.primary : AppColors.border,
              child: Row(children: [
                Icon(_engine == e ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20, color: _engine == e ? AppColors.primary : AppColors.textFaint),
                Gap.wM,
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(voiceEngineLabel(e), style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(voiceEngineHint(e), style: AppText.small),
                  ])),
              ]),
            ),
          ),
        )),

        if (_engine == VoiceEngine.gemini) ...[
          Gap.s,
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Column(children: [
              SettingRow(
                icon: Icons.record_voice_over_outlined,
                label: 'Voice',
                value: geminiVoiceName,
                onTap: busy ? null : _pickVoice,
              ),
              const Divider(height: 1, color: AppColors.border),
              SettingRow(
                icon: Icons.play_circle_outline,
                label: 'Hear a sample',
                value: 'Play',
                onTap: busy ? null : _hearVoiceSample,
              ),
            ]),
          ),
        ],

        Gap.m,
        if (_audioPath != null)
          AppCard(
            colour: AppColors.primarySoft,
            borderColour: AppColors.primary,
            child: const Row(children: [
              Icon(Icons.check_circle, size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Voice recorded and ready.',
                style: TextStyle(fontSize: 14, color: AppColors.text))),
            ]),
          )
        else
          const Text('You can record it here, or just tap Make the reel on the next '
              'step and it records for you.', style: AppText.hint),

        Gap.m,
        Row(children: [
          Expanded(child: SecondaryButton(
            label: _isPlaying ? 'Stop' : 'Read it out',
            icon: _isPlaying ? Icons.stop : Icons.play_arrow,
            colour: _isPlaying ? AppColors.danger : AppColors.primary,
            onPressed: busy ? null : (_isPlaying ? _stopPreview : _previewAll))),
          Gap.wS,
          Expanded(child: SecondaryButton(
            label: _isSaving ? 'Recording...' : 'Record voice',
            icon: Icons.mic_none,
            onPressed: busy ? null : _saveAudio)),
        ]),
      ],
    );
  }

  // ── Step 4: how the reel looks ──────────────────────────────────────────────

  Widget _stepReel(bool busy) {
    final hasMusic = kMusicLibrary.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const Text('How it looks', style: AppText.screenTitle),
        Gap.xs,
        const Text('None of these change the voice, so you can adjust them and build '
            'again without recording anything.', style: AppText.hint),
        Gap.m,

        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Column(children: [
            // First in the list because it changes everything else on it: in the
            // Moment look the caption sits inside the photo, so its position setting
            // no longer applies.
            SettingRow(
              icon: Icons.photo_outlined,
              label: 'Look',
              value: _moment ? 'Moment' : 'Plain',
              valueColour: _moment ? AppColors.accent : AppColors.textFaint,
              onTap: busy ? null : () => _setLook(() => _moment = !_moment),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingRow(
              icon: Icons.title,
              label: 'Cover hook on picture 1',
              value: _coverHook ? 'On' : 'Off',
              valueColour: _coverHook ? AppColors.primary : AppColors.textFaint,
              onTap: busy ? null : () => _setLook(() => _coverHook = !_coverHook),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingRow(
              icon: Icons.subtitles_outlined,
              label: 'Captions',
              value: _captions ? 'On' : 'Off',
              valueColour: _captions ? AppColors.primary : AppColors.textFaint,
              onTap: busy ? null : () => _setLook(() => _captions = !_captions),
            ),
            // Hidden in the Moment look, where the caption always sits inside the photo.
            if (_captions && !_moment) ...[
              const Divider(height: 1, color: AppColors.border),
              SettingRow(
                icon: Icons.vertical_align_top,
                label: 'Caption position',
                value: captionSpotLabel(_captionSpot),
                onTap: busy ? null : () => _setLook(() {
                  _captionSpot = CaptionSpot.values[
                      (_captionSpot.index + 1) % CaptionSpot.values.length];
                }),
              ),
            ],
            const Divider(height: 1, color: AppColors.border),
            SettingRow(
              icon: Icons.animation,
              label: 'Movement',
              value: clipMotionLabel(_motion),
              onTap: busy ? null : () => _setLook(() {
                _motion = ClipMotion.values[
                    (_motion.index + 1) % ClipMotion.values.length];
              }),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingRow(
              icon: Icons.branding_watermark_outlined,
              label: 'End card',
              value: _endCard ? 'On' : 'Off',
              valueColour: _endCard ? AppColors.primary : AppColors.textFaint,
              onTap: busy ? null : () => _setLook(() => _endCard = !_endCard),
            ),
            if (hasMusic) ...[
              const Divider(height: 1, color: AppColors.border),
              SettingRow(
                icon: Icons.music_note_outlined,
                label: 'Background music',
                value: _music?.name ?? 'None',
                valueColour: _music == null ? AppColors.textFaint : AppColors.primary,
                onTap: busy ? null : _pickMusic,
              ),
            ],
          ]),
        ),

        // Here, before the build, because the hook and the ending are drawn onto the
        // video — choosing them after the reel is made means making it again.
        if (widget.projectId.isNotEmpty) ...[
          Gap.m,
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Posting kit — hook, ending, pinned comment',
              icon: Icons.checklist,
              colour: AppColors.accent,
              onPressed: busy ? null : () => showPostingKit(context, widget.projectId)
                  .then((_) { _loadHookChoices(); _checkSavedReel(); }),
            ),
          ),
        ],

        Gap.l,
        const SectionTitle('Ready to build'),
        AppCard(
          child: Column(children: [
            _summaryRow(Icons.notes, '${_lines.length} lines', _lines.isNotEmpty),
            const SizedBox(height: 10),
            if (_storyMode) ...[
              _summaryRow(Icons.image_outlined, '${_images.length} pictures',
                _images.isNotEmpty),
              const SizedBox(height: 10),
            ],
            _summaryRow(Icons.mic_none,
              _audioPath == null ? 'Voice will be recorded now' : 'Voice ready',
              _audioPath != null),
            const SizedBox(height: 10),
            _summaryRow(Icons.branding_watermark_outlined,
              _endCard ? 'Ends with your brand card' : 'No end card', _endCard),
          ]),
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String text, bool ok) => Row(children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 17, color: ok ? AppColors.primary : AppColors.textFaint),
        const SizedBox(width: 10),
        Icon(icon, size: 16, color: AppColors.textSoft),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppText.body)),
      ]);
  Widget _buildPastePanel() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(
        colour: AppColors.primarySoft,
        borderColour: AppColors.primary,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('One line each, starting with the time',
            style: AppText.section.copyWith(color: AppColors.primary)),
          Gap.s,
          const Text('0:00  Ek Teddy Do Dost\n'
              '0:05  Arey chhodo ye mera Teddy hai\n'
              '0:10  Dono ladne lage',
            style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.text)),
        ]),
      ),
      Gap.m,
      Expanded(
        child: TextField(
          controller: _pasteCtrl,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: AppText.body,
          decoration: const InputDecoration(hintText: 'Paste your script here'),
        ),
      ),
      Gap.m,
      PrimaryButton(
        label: 'Use this script',
        icon: Icons.check,
        onPressed: _applyPaste,
      ),
    ]),
  );

  /// The picture this line will use, as a small numbered thumbnail.
  ///
  /// Pictures cycle when there are fewer than lines, so line 8 with 3 pictures shows
  /// picture 2 — which is worth seeing before building rather than after.
  Widget _lineStatus(int index) {
    if (_images.isEmpty) {
      return Container(
        width: 34, height: 46,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.accent),
        ),
        child: const Icon(Icons.priority_high, size: 16, color: AppColors.accent),
      );
    }

    final picture = index % _images.length;
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(File(_images[picture]),
          width: 34, height: 46, fit: BoxFit.cover),
      ),
      Positioned(bottom: 0, right: 0, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.text.withOpacity(0.8),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6))),
        child: Text('${picture + 1}', style: const TextStyle(
          fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
      )),
    ]);
  }
  String get _notReadyReason {
    if (_lines.isEmpty) return 'Write or paste a script first.';
    if (_storyMode && _images.isEmpty) return 'Add at least one picture.';
    return '';
  }

  /// Records the voice if it is not recorded, then builds the reel.
  ///
  /// Three taps in a fixed order, where getting the order wrong was the only way to
  /// fail, is not a choice worth offering. Save Voice is still there on its own for
  /// when you change the voice and want to hear it before spending a render on it.
  Future<void> _makeReel() async {
    _syncLines();
    if (_notReadyReason.isNotEmpty) {
      setState(() => _status = _notReadyReason);
      return;
    }

    if (_audioPath == null) {
      await _saveAudio();
      // _saveAudio puts the reason in _status itself, so a failure here just stops.
      if (_audioPath == null || !mounted) return;
    }

    await (_storyMode ? _buildFromImages() : _mergeWithVideo());
  }


  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;

    // Copied out of the picker's cache, which Android clears without asking. A story
    // whose pictures vanish next week cannot be rebuilt or adjusted.
    final kept = <String>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < picked.length; i++) {
      final path = picked[i].path;
      if (widget.projectId.isEmpty) { kept.add(path); continue; }
      final ext = path.contains('.') ? path.split('.').last : 'jpg';
      try {
        kept.add(await keepFile(path, 'pictures/${widget.projectId}', '${stamp}_$i.$ext'));
      } catch (_) {
        kept.add(path);
      }
    }

    setState(() { _images.addAll(kept); _status = ''; _matchingReel = null; });
    _saveProject();
  }

  /// What goes on the cover and the last screen, with your own rewrites applied.
  ///
  /// Empty is fine and common: a pasted script never went through the prompts screen,
  /// so it has none of this. The reel is built without them rather than refusing.
  Future<_ReelText> _savedPost() async {
    if (widget.projectId.isEmpty) return const _ReelText();
    try {
      final all = await ProjectStore.load();
      final matches = all.where((p) => p.id == widget.projectId);
      if (matches.isEmpty) return const _ReelText();

      final project = matches.first;
      final edits = project.edits;

      PostDetails? post;
      if (project.promptsJson.isNotEmpty) {
        post = promptsFromSaved(
          project.promptsJson, _lines.map((l) => l.text).toList()).post;
      }

      // What you typed always wins over what was generated — that is the whole point
      // of keeping edits in their own place rather than writing over the reply.
      final hook = edits['cover_hook']?.trim();
      final closing = edits['last_screen']?.trim();

      return _ReelText(
        coverHook: (hook != null && hook.isNotEmpty) ? hook : (post?.coverHook ?? ''),
        // Question first, then the reason to keep it. A closing screen that asks
        // nothing gets no comments.
        // The ending you picked; otherwise the first one offered; and for stories written
        // before endings were offered, the question and save lines they always had —
        // the same rule the posting kit shows, so the two never disagree.
        closing: (closing != null && closing.isNotEmpty)
            ? closing
            : post == null ? kDefaultCtaLine : defaultEnding(post),
      );
    } catch (_) {
      return const _ReelText();
    }
  }

  /// The captions, with the first one swapped for the cover.
  ///
  /// Picture 1 is the thumbnail, and a thumbnail carrying an ordinary caption is a
  /// wasted thumbnail. The hook goes there instead, at nearly twice the size.
  ///
  /// The cover has its own switch rather than riding on Captions. It is not a caption
  /// — it is the thumbnail in the profile grid — so turning captions off should not
  /// quietly take it too, and a reel can want captions with a clean first picture.
  Future<List<String?>> _captionPngs(String workDir, _ReelText post) async {
    if (_lines.isEmpty) return const [];
    final captions = _captions
        ? await renderCaptions(lines: _lines.map((l) => l.text).toList(), workDir: workDir)
        : List<String?>.filled(_lines.length, null);

    if (_coverHook) {
      final cover = await _renderCover(workDir, post);
      if (cover != null) captions[0] = cover;
    }
    return captions;
  }

  /// The cover hook image. Falls back to the first script line, which is the hook
  /// anyway — just longer than the two to four words a cover wants.
  Future<String?> _renderCover(String workDir, _ReelText post) {
    final hook = post.coverHook.trim().isNotEmpty ? post.coverHook.trim() : _lines.first.text;
    return renderCoverHook(hook, '$workDir/cover_hook.png');
  }

  /// Every picture drawn as a Moment frame, with its caption and the cover hook inside.
  Future<List<MomentFrame>> _momentFrames(String workDir, _ReelText post) async {
    final frames = <MomentFrame>[];
    // Its own switch, for the same reason as above.
    final cover = (_lines.isEmpty || !_coverHook) ? null : await _renderCover(workDir, post);

    for (var i = 0; i < _lines.length; i++) {
      if (mounted) {
        setState(() => _status = 'Framing picture ${i + 1} of ${_lines.length}...');
      }
      final frame = await renderMomentFrame(
        imagePath: SlideshowBuilder.imageForLine(_images, i),
        index: i,
        workDir: workDir,
        caption: _captions ? _lines[i].text : '',
        coverPng: i == 0 ? cover : null,
      );
      if (frame == null) {
        throw Exception('Picture ${i + 1} could not be read to frame it.');
      }
      frames.add(frame);
    }
    return frames;
  }

  /// Writes the script and pictures back onto the saved story.
  ///
  /// Reads the file first rather than keeping a copy in memory: the story text itself
  /// belongs to the previous screen, and overwriting it from a stale copy held here
  /// would lose an edit made there.
  Future<void> _saveProject() async {
    if (widget.projectId.isEmpty) return;
    // Taken now, not inside the update: by the time it runs, the screen may have moved.
    final script = _lines.map(scriptLineToText).toList();
    final images = List.of(_images);
    final engine = _engine.name;
    final voice = geminiVoiceName;
    final look = _lookMap();
    await ProjectStore.update(widget.projectId, (p) => p.copyWith(
      script: script, images: images, engine: engine, voiceName: voice, look: look));
  }

  // ── Not making the same thing twice ─────────────────────────────────────────
  //
  // A finished voice and a finished reel are both kept with a fingerprint of what
  // they were made from. Opening this screen again, or coming back from the preview,
  // finds them and uses them — the reel you already made is the reel you get.

  /// Bump when rendering changes in a way an old reel would not have, so reels built
  /// before an update are rebuilt once instead of being reused with the old look.
  static const _renderVersion = 3;

  Map<String, String> _lookMap() => {
        'captions': _captions ? '1' : '0',
        'captionSpot': _captionSpot.name,
        'motion': _motion.name,
        'endCard': _endCard ? '1' : '0',
        'moment': _moment ? '1' : '0',
        'cover': _coverHook ? '1' : '0',
      };

  /// What the voice depends on. The times only matter for the line-by-line engines,
  /// whose track is built to them; a one-take read does not care where pictures change.
  String _voiceKey() => fingerprint([
        _engine.name,
        geminiVoiceName,
        widget.style,
        widget.language,
        ..._lines.map((l) => l.spoken),
        if (_engine != VoiceEngine.gemini)
          ..._lines.map((l) => '${l.time.inMilliseconds}'),
      ].join(''));

  /// What the reel depends on — every picture, word, timing and setting that changes
  /// what ends up on screen.
  Future<String> _reelKey() async {
    final post = await _savedPost();
    return fingerprint([
      '$_renderVersion',
      _voiceKey(),
      ..._lineStarts.map((s) => (s * 1000).round().toString()),
      ..._images,
      ..._lines.map((l) => l.text),
      ..._lookMap().values,
      _music?.asset ?? '',
      post.coverHook,
      post.closing,
    ].join(''));
  }

  /// Puts back the pictures, voice, settings and choices this story was left with.
  Future<void> _restoreFromProject() async {
    final project = await loadProject(widget.projectId);
    if (project == null || !mounted) return;
    _loadHookChoices();

    final images = await ProjectStore.existingImages(project.images);

    // A new story has no engine of its own yet, so it takes the one used last time
    // rather than quietly falling back to the phone voice nobody picked.
    var engineName = project.engine;
    if (engineName.isEmpty) {
      final recent = (await ProjectStore.load()).where((p) => p.engine.isNotEmpty);
      if (recent.isNotEmpty) engineName = recent.first.engine;
    }
    final engine = VoiceEngine.values.where((e) => e.name == engineName);

    setState(() {
      if (_images.isEmpty) _images = images;
      if (engine.isNotEmpty) _engine = engine.first;
      if (project.voiceName.isNotEmpty) geminiVoiceName = project.voiceName;

      final look = project.look;
      if (look['captions'] != null) _captions = look['captions'] == '1';
      if (look['endCard'] != null) _endCard = look['endCard'] == '1';
      if (look['moment'] != null) _moment = look['moment'] == '1';
      if (look['cover'] != null) _coverHook = look['cover'] == '1';
      final spot = CaptionSpot.values.where((s) => s.name == look['captionSpot']);
      if (spot.isNotEmpty) _captionSpot = spot.first;
      final motion = ClipMotion.values.where((m) => m.name == look['motion']);
      if (motion.isNotEmpty) _motion = motion.first;
    });

    // The voice is only reused when it was made from exactly these words with exactly
    // this voice. Anything else would build a reel that says something the captions do not.
    if (project.voicePath.isNotEmpty &&
        await File(project.voicePath).exists() &&
        project.voiceKey == _voiceKey()) {
      if (!mounted) return;
      setState(() {
        _audioPath = project.voicePath;
        _lineStarts = List.of(project.lineStarts);
      });
      await _checkSavedReel();
    }
  }

  /// The saved reel, if it still matches everything on screen.
  String? _matchingReel;

  /// The five cover hooks written with the script, and the one currently chosen.
  List<HookChoice> _hookChoices = [];
  String _coverChoice = '';

  Future<void> _loadHookChoices() async {
    final project = await loadProject(widget.projectId);
    if (project == null || project.promptsJson.isEmpty) return;
    try {
      final post = promptsFromSaved(project.promptsJson, project.promptsScript).post;
      if (!mounted) return;
      setState(() {
        _hookChoices = post.coverHookOptions;
        final edited = project.edits['cover_hook']?.trim() ?? '';
        _coverChoice = edited.isNotEmpty ? edited : post.coverHook;
      });
    } catch (_) {}
  }

  /// Makes one of the five the cover. Saved as an edit, which is what the cover on the
  /// reel and the caption sheet already read — so choosing here changes both.
  Future<void> _chooseCover(String text) async {
    setState(() { _coverChoice = text; _matchingReel = null; });
    // Merged into the edits as they are on disk at that moment, so a caption edited on
    // another screen is not undone by picking a cover here.
    await ProjectStore.update(widget.projectId, (p) => p.copyWith(
      edits: {...p.edits, 'cover_hook': text}));
  }

  Future<void> _checkSavedReel() async {
    final project = await loadProject(widget.projectId);
    String? match;
    if (project != null &&
        project.reelPath.isNotEmpty &&
        _audioPath != null &&
        await File(project.reelPath).exists() &&
        project.reelKey == await _reelKey()) {
      match = project.reelPath;
    }
    if (!mounted) return;
    setState(() {
      _matchingReel = match;
      if (match != null && _status.isEmpty) {
        _status = '✅ This reel is already made. Open it — nothing needs redoing.';
      }
    });
  }

  /// Moves a just-recorded voice somewhere it will still be tomorrow, and notes what
  /// it was made from.
  Future<void> _persistVoice() async {
    if (widget.projectId.isEmpty || _audioPath == null) return;
    final ext = _audioPath!.split('.').last;
    final kept = await keepFile(_audioPath!, 'voices', '${widget.projectId}.$ext');

    _audioPath = kept;
    final key = _voiceKey();
    final starts = List.of(_lineStarts);
    final engine = _engine.name;
    final voice = geminiVoiceName;
    await ProjectStore.update(widget.projectId, (p) => p.copyWith(
      voicePath: kept, voiceKey: key, lineStarts: starts,
      engine: engine, voiceName: voice));
  }

  void _openReel(String path) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PreviewMergedScreen(
        mergedFile: File(path), projectId: widget.projectId),
    ));
  }

  /// Changes a render setting and remembers it, and the saved reel no longer matches.
  void _setLook(VoidCallback change) {
    setState(() {
      change();
      _matchingReel = null;
    });
    _saveProject();
    _checkSavedReel();
  }
}

// ── Preview Merged Screen ─────────────────────────────────────────────────────

class PreviewMergedScreen extends StatefulWidget {
  final File mergedFile;
  /// The story this reel belongs to, so the caption and comments can be opened from
  /// here and the gallery state remembered. Empty for the old add-voice-to-video path.
  final String projectId;
  const PreviewMergedScreen({super.key, required this.mergedFile, this.projectId = ''});
  @override
  State<PreviewMergedScreen> createState() => _PreviewMergedScreenState();
}

class _PreviewMergedScreenState extends State<PreviewMergedScreen> {
  VideoPlayerController? _ctrl;
  bool _isSaving = false;
  String _status = '';
  bool _inGallery = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _loadGalleryState();
  }

  Future<void> _loadGalleryState() async {
    final project = await loadProject(widget.projectId);
    if (mounted && project != null) setState(() => _inGallery = project.inGallery);
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.file(widget.mergedFile);
    await c.initialize();
    c.setLooping(true);
    c.play();
    setState(() => _ctrl = c);
  }

  /// Hands the file to Android to put in the gallery, rather than copying it into the
  /// Movies folder ourselves.
  ///
  /// Copying it was the bug. Gallery, Photos and Instagram do not read the filesystem,
  /// they read MediaStore, so a file copied in by hand is on the phone but invisible to
  /// every app you would actually want to post it from. A folder-scanning player like
  /// MX finds it, which is why it looked saved and missing at the same time.
  Future<void> _saveToGallery() async {
    setState(() { _isSaving = true; _status = 'Saving to your gallery...'; });
    try {
      await _mediaChannel.invokeMethod('saveVideoToGallery', {
        'path': widget.mergedFile.path,
        'name': 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4',
      });
      setState(() {
        _inGallery = true;
        _status = '🎉 Saved. Look in Gallery → Movies → Reels, or pick it straight '
            'from Instagram.';
      });
      await ProjectStore.update(widget.projectId, (p) => p.copyWith(inGallery: true));
    } catch (e) { setState(() { _status = '❌ $e'; }); }
    setState(() => _isSaving = false);
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your reel'),
        actions: [
          IconButton(
            icon: Icon(_ctrl?.value.isPlaying == true ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (_ctrl == null) return;
              setState(() { _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play(); });
            },
          ),
        ],
      ),
      body: Column(children: [
        const StepBar(steps: kSteps, current: 4),
        // The video sits on near-black whatever the rest of the app looks like: a
        // 9:16 reel never fills a phone screen, and cream bars either side change
        // how the colours in it read.
        Expanded(
          child: Container(
            color: const Color(0xFF17140F),
            width: double.infinity,
            child: Center(
              child: _ctrl != null && _ctrl!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _ctrl!.value.aspectRatio,
                      child: VideoPlayer(_ctrl!))
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.bg,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            StatusBar(message: _status),
            // Posting needs the caption more than it needs anything else, and it used
            // to be several screens away. Now it is the first thing under the reel.
            if (widget.projectId.isNotEmpty) ...[
              PrimaryButton(
                label: 'Caption & comments',
                icon: Icons.content_copy,
                onPressed: () => showPostingKit(context, widget.projectId),
              ),
              Gap.s,
            ],
            Row(children: [
              Expanded(child: SecondaryButton(
                label: _isSaving ? 'Saving...' : _inGallery ? 'In gallery ✓' : 'Save to gallery',
                icon: Icons.download,
                onPressed: _isSaving ? null : _saveToGallery,
              )),
              Gap.wS,
              // Nothing is lost by going back any more: the reel and the voice are both
              // kept, so adjusting and returning opens this same reel again.
              Expanded(child: SecondaryButton(
                label: 'Adjust',
                icon: Icons.tune,
                colour: AppColors.textSoft,
                onPressed: () => Navigator.pop(context),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── Saved stories ─────────────────────────────────────────────────────────────

/// Every story the app has written down, newest first.
///
/// Tapping one hands it back to the story screen. Nothing is ever deleted on your
/// behalf, including stories you abandoned halfway — those are often the ones worth
/// coming back to.
class SavedStoriesScreen extends StatefulWidget {
  const SavedStoriesScreen({super.key});
  @override
  State<SavedStoriesScreen> createState() => _SavedStoriesScreenState();
}

class _SavedStoriesScreenState extends State<SavedStoriesScreen> {
  List<Project> _projects = [];
  bool _loading = true;
  bool _busy = false;
  String _note = '';

  /// Reads a backup you point at and puts back anything missing.
  ///
  /// A file picker rather than the app finding it on its own: after a reinstall the
  /// app no longer owns the file it wrote last week and cannot see it any more.
  Future<void> _restore() async {
    setState(() { _busy = true; _note = ''; });
    try {
      final added = await ProjectBackup.restore();
      if (!mounted) return;
      if (added == null) {
        setState(() { _busy = false; _note = ''; });
        return;
      }
      await _load();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _note = added == 0
            ? 'Nothing new in that backup — everything in it is already here.'
            : added == 1 ? '1 story restored.' : '$added stories restored.';
      });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _note = '❌ $e'; });
    }
  }

  /// What can be done with one story, depending on how far it got.
  ///
  /// Tapping a story used to drop it back into the story box, which meant writing the
  /// script again, recording the voice again and building the reel again just to get
  /// back to something already finished. Now each thing it already has is one tap.
  Future<void> _openStory(Project p) async {
    final hasReel = p.reelPath.isNotEmpty && await File(p.reelPath).exists();
    final lines = parseScript(p.script.join('\n'));
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(p.displayName, maxLines: 2, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
            title: Text(p.name.trim().isEmpty ? 'Name this story' : 'Rename'),
            subtitle: const Text('So you can find it at a glance'),
            onTap: () {
              Navigator.pop(ctx);
              _rename(p);
            },
          ),
          if (hasReel)
            ListTile(
              leading: const Icon(Icons.play_circle, color: AppColors.primary),
              title: const Text('Open the reel'),
              subtitle: const Text('Already made — opens straight away'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PreviewMergedScreen(
                    mergedFile: File(p.reelPath), projectId: p.id)));
              },
            ),
          if (p.promptsJson.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.content_copy, color: AppColors.primary),
              title: const Text('Caption & comments'),
              subtitle: const Text('Copy for posting'),
              onTap: () {
                Navigator.pop(ctx);
                showPostingKit(context, p.id);
              },
            ),
          if (lines.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.tune, color: AppColors.textSoft),
              title: const Text('Continue working on it'),
              subtitle: const Text('Script, pictures, voice — as you left them'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TimedScriptScreen(
                    style: p.style.isEmpty ? '❤️ Heartwarming' : p.style,
                    language: p.language.isEmpty ? 'Hinglish' : p.language,
                    videoFile: null,
                    initialLines: lines,
                    storyDescription: p.story,
                    seconds: p.seconds,
                    projectId: p.id,
                  ))).then((_) => _load());
              },
            ),
          if (lines.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.auto_fix_high, color: AppColors.textSoft),
              title: const Text('Picture prompts'),
              subtitle: const Text('For Meta AI'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PromptScreen(
                    storyDescription: p.story,
                    scriptLines: lines.map((l) => l.text).toList(),
                    seconds: p.seconds,
                    projectId: p.id,
                  )));
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit_note, color: AppColors.textSoft),
            title: const Text('Edit the story text'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pop(context, p);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  /// Writes the backup now, for when you want to be sure before uninstalling.
  Future<void> _backUpNow() async {
    setState(() { _busy = true; _note = ''; });
    try {
      final where = await ProjectBackup.write();
      if (mounted) setState(() { _busy = false; _note = '✅ Saved to $where'; });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _note = '❌ $e'; });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ProjectStore.load();
    if (!mounted) return;
    setState(() { _projects = all; _loading = false; });
  }

  /// Gives a story a heading of your own, so it can be found without opening it.
  ///
  /// Saving an empty box goes back to the automatic title from the story's first line.
  Future<void> _rename(Project p) async {
    final ctrl = TextEditingController(text: p.name.trim().isNotEmpty ? p.name : '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Story name'),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Ria brush nahi karegi — park wali'),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          const SizedBox(height: 4),
          Text('Right now: ${p.title}', maxLines: 2, overflow: TextOverflow.ellipsis,
            style: AppText.small),
        ]),
        actions: [
          if (p.name.trim().isNotEmpty)
            TextButton(onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Use automatic')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save')),
        ],
      ),
    );
    if (result == null) return;

    final name = result.trim();
    await ProjectStore.update(p.id, (x) => x.copyWith(name: name));
    await _load();
  }

  Future<void> _delete(Project p) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this story?'),
        content: Text('"${p.displayName}" will be gone for good.',
          style: AppText.hint),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
              style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (sure != true) return;
    await ProjectStore.delete(p.id);
    await _load();
  }

  String _when(DateTime t) {
    final days = DateTime.now().difference(t).inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved stories'),
        actions: [
          IconButton(
            tooltip: 'Restore from a backup file',
            icon: const Icon(Icons.restore, size: 21),
            onPressed: _busy ? null : _restore,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
        if (_note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: StatusBar(message: _note),
          ),
        // Said plainly rather than hidden in a settings screen, because the one time
        // it matters is the moment before somebody uninstalls the app.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppCard(
            colour: AppColors.surfaceAlt,
            child: Row(children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppColors.textSoft),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'A copy of everything is kept in Downloads, so it survives the app '
                'being uninstalled.',
                style: AppText.small)),
              TextButton(
                onPressed: _busy ? null : _backUpNow,
                child: const Text('Back up now', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),
        ),
        Expanded(
          child: _projects.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text(
                    'Nothing saved yet.\n\nStories are written down on their own as '
                    'you type, so this fills up by itself.',
                    textAlign: TextAlign.center, style: AppText.hint)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length,
                  itemBuilder: (ctx, i) {
                    final p = _projects[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _openStory(p),
                        child: AppCard(
                          child: Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text, height: 1.3)),
                                // With a name of your own, the story's first line still
                                // shows underneath, so two stories named alike can be
                                // told apart.
                                if (p.name.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(p.title, maxLines: 1,
                                    overflow: TextOverflow.ellipsis, style: AppText.small),
                                ],
                                const SizedBox(height: 6),
                                Row(children: [
                                  Text(_when(p.savedAt), style: AppText.small),
                                  if (p.script.isNotEmpty) ...[
                                    const Text('  •  ', style: AppText.small),
                                    Text('${p.script.length} lines',
                                      style: AppText.small),
                                  ],
                                  if (p.images.isNotEmpty) ...[
                                    const Text('  •  ', style: AppText.small),
                                    Text('${p.images.length} pictures',
                                      style: AppText.small),
                                  ],
                                ]),
                              ])),
                            // A finished reel is marked on the row itself, so the
                            // stories that are ready to post stand out in a long list.
                            if (p.reelPath.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.movie, size: 20,
                                  color: AppColors.primary),
                              ),
                            IconButton(
                              tooltip: 'Name this story',
                              icon: const Icon(Icons.edit_outlined, size: 20,
                                color: AppColors.primary),
                              onPressed: () => _rename(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20,
                                color: AppColors.textFaint),
                              onPressed: () => _delete(p),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
