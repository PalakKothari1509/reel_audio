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
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

// ── API Keys ──────────────────────────────────────────────────────────────────

const _geminiKey     = geminiApiKey;
const _elevenLabsKey = elevenLabsApiKey;
// ElevenLabs voice ID — "Aria" multilingual (works well for Hinglish)
const _elevenVoiceId = elevenVoiceId;

// ── Gemini Service ────────────────────────────────────────────────────────────
// Extracts frames from video, sends to Gemini Vision, gets timed script back

Future<List<ScriptLine>> generateScriptWithGemini({
  required String videoDescription,
  required String language,
  required String style,
  required double videoDuration,
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

  final prompt = '''
Write a voiceover script for a $totalSecs second preschool video for "Fun Learning With Palak" Instagram Reels.

Characters: Ria (girl), Rio (boy), Cuty (rabbit), Mum, Dad
$storyNote
$langNote
$styleNote

The script must follow the story above. Do not invent a different story.

Output ONLY $expectedLines lines. Each line: timestamp space text. Nothing else. No explanations. No bullet points. No asterisks.

Example output:
0:00 Ek baar ki baat hai
0:04 Ria ne dekha ek titli
0:08 Rio bhi aa gaya
0:12 Cuty ne kaha wah
0:16 Bye bye dosto

Now output exactly $expectedLines lines for a $totalSecs second video:
''';

  final body = jsonEncode({
    'contents': [{
      'parts': [{'text': prompt}]
    }],
    'generationConfig': {
      'temperature': 0.8,
      'maxOutputTokens': 1024,
    }
  });

  final response = await http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$_geminiKey'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  ).timeout(const Duration(seconds: 30));

  if (response.statusCode != 200) {
    throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
  }

  final json = jsonDecode(response.body);
  final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.isEmpty) throw Exception('Gemini returned empty response.');

  final lines = parseScript(text);
  if (lines.isEmpty) throw Exception('Gemini response had no valid timed lines:\n$text');
  return lines;
}

// ── ElevenLabs Service ────────────────────────────────────────────────────────
// Converts text to natural AI voice, saves to file

Future<void> elevenLabsSynthesize({
  required String text,
  required String filePath,
}) async {
  final response = await http.post(
    Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$_elevenVoiceId'),
    headers: {
      'xi-api-key': _elevenLabsKey,
      'Content-Type': 'application/json',
      'Accept': 'audio/mpeg',
    },
    body: jsonEncode({
      'text': text,
      'model_id': 'eleven_multilingual_v2',
      'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.75,
        'style': 0.3,
        'use_speaker_boost': true,
      }
    }),
  ).timeout(const Duration(seconds: 30));

  if (response.statusCode != 200) {
    throw Exception('ElevenLabs error ${response.statusCode}: ${response.body}');
  }
  await File(filePath).writeAsBytes(response.bodyBytes);
}

// ── Native TTS (for preview only) ────────────────────────────────────────────

const _ttsCh = MethodChannel('com.example.reel_audio/tts');

Future<void> nativeSynthesize({
  required String text,
  required String filePath,
  required String lang,
  required double rate,
  required double pitch,
}) async {
  await _ttsCh.invokeMethod('synthesizeToFile', {
    'text': text, 'filePath': filePath,
    'lang': lang, 'rate': rate, 'pitch': pitch,
  });
}

// ── Media helpers ─────────────────────────────────────────────────────────────

/// Length of an audio or video file in seconds; null when it can't be read.
///
/// This has to be FFprobe, not FFmpeg. The old code passed ffprobe-only flags
/// (-show_entries, -of) to FFmpegKit, which rejects them — so the parse always failed
/// and every spoken line was assumed to be 3 seconds. Anything longer pushed the next
/// line late, and the error added up down the script.
Future<double?> getAudioDuration(String path) async {
  final session = await FFprobeKit.getMediaInformation(path);
  final seconds = double.tryParse(session.getMediaInformation()?.getDuration() ?? '');
  return (seconds != null && seconds > 0.05) ? seconds : null;
}

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

// ── ScriptLine ────────────────────────────────────────────────────────────────

class ScriptLine {
  Duration time;
  String text;
  ScriptLine(this.time, this.text);
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

List<ScriptLine> parseScript(String raw) {
  final lines = <ScriptLine>[];
  for (final line in raw.split('\n')) {
    final trimmed = line.replaceAll(RegExp(r'^[\*\-\•\d\.\s]+(?=\d+:\d+)'), '').trim();
    if (trimmed.isEmpty) continue;
    final match = RegExp(r'(\d{1,2}:\d{2})\s+(.+)$').firstMatch(trimmed);
    if (match != null) {
      lines.add(ScriptLine(parseDuration(match.group(1)!), match.group(2)!.trim()));
    }
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

void main() => runApp(MaterialApp(
      title: 'Story Voice Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const HomeScreen(),
    ));

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
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('Story Voice Maker')),
      body: Column(children: [
        Expanded(
          child: _ctrl != null && _ctrl!.value.isInitialized
              ? AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!))
              : const Center(child: Text('No video selected', style: TextStyle(color: Colors.white54))),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _btn(Icons.video_library, 'Select Reel', Colors.blueGrey, _pickVideo),
            const SizedBox(height: 10),
            _btn(Icons.auto_awesome, 'Add Voice', Colors.deepPurple,
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
          disabledBackgroundColor: Colors.grey.shade800,
        ),
      ),
    );
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
  final _styles    = kVoiceProfiles.keys.toList();
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
                value: _language, dropdownColor: Colors.grey[850],
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.grey[900],
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
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  filled: true, fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
      if (_genStatus.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(_genStatus, style: const TextStyle(fontSize: 12))),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
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
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.shade800,
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
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.grey.shade800,
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
  final File videoFile;
  final List<ScriptLine> initialLines;
  const TimedScriptScreen({
    super.key, required this.style, required this.language,
    required this.videoFile, required this.initialLines,
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

  @override
  void initState() {
    super.initState();
    _lines = List.from(widget.initialLines);
    _showPaste = _lines.isEmpty;
    _textCtrls = _lines.map((l) => TextEditingController(text: l.text)).toList();
    _timeCtrls = _lines.map((l) => TextEditingController(text: fmtDuration(l.time))).toList();
    _initTts();
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
      _showPaste = false; _audioPath = null; _status = '';
    });
  }

  void _syncLines() {
    for (int i = 0; i < _lines.length; i++) {
      _lines[i].text = _textCtrls[i].text;
      _lines[i].time = parseDuration(_timeCtrls[i].text);
    }
  }

  void _addLine() {
    _syncLines();
    final lastTime = _lines.isNotEmpty ? _lines.last.time + const Duration(seconds: 4) : Duration.zero;
    setState(() {
      _lines.add(ScriptLine(lastTime, ''));
      _textCtrls.add(TextEditingController());
      _timeCtrls.add(TextEditingController(text: fmtDuration(lastTime)));
    });
  }

  void _removeLine(int i) {
    setState(() {
      _lines.removeAt(i);
      _textCtrls.removeAt(i).dispose();
      _timeCtrls.removeAt(i).dispose();
    });
  }

  // Preview uses flutter_tts (free, no API cost)
  Future<void> _previewAll() async {
    _syncLines();
    _cancelTimers();
    setState(() { _isPlaying = true; _activeIdx = -1; });
    await _initTts();
    for (int i = 0; i < _lines.length; i++) {
      final idx = i;
      final text = cleanForTts(_lines[i].text);
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

  // Save voice using native TTS (same voice as Preview) — then build timed track with FFmpeg concat
  Future<void> _saveAudio() async {
    _syncLines();
    if (_lines.isEmpty) { setState(() => _status = 'No lines to save!'); return; }
    setState(() { _isSaving = true; _status = 'Generating voice...'; });
    try {
      final dir = await getTemporaryDirectory();
      final segPaths = <String>[];
      final locale = widget.language == 'English' ? 'en-IN' : 'hi-IN';

      // Step 1: Native TTS generates each line as wav
      for (int i = 0; i < _lines.length; i++) {
        setState(() => _status = 'Voice: line ${i + 1} of ${_lines.length}...');
        final p = '${dir.path}/seg_$i.wav';
        if (await File(p).exists()) await File(p).delete();
        await nativeSynthesize(
          text: cleanForTts(_lines[i].text),
          filePath: p,
          lang: locale,
          rate: _vp.rate,
          pitch: _vp.pitch,
        );
        // Wait briefly for TTS to finish writing
        await Future.delayed(const Duration(milliseconds: 300));
        if (!await File(p).exists()) throw Exception('TTS failed for line ${i + 1}.');
        segPaths.add(p);
      }

      setState(() => _status = 'Building timed audio track...');

      // Step 2: how long each spoken line actually is, so the gaps can be worked out.
      final segDurations = <double>[];
      for (final p in segPaths) {
        segDurations.add(await getAudioDuration(p) ?? 3.0);
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

      setState(() { _status = '✅ AI voice ready! Now tap Merge with Video.'; });
    } catch (e) {
      setState(() { _status = '❌ $e'; _audioPath = null; });
    }
    setState(() => _isSaving = false);
  }

  Future<void> _mergeWithVideo() async {
    if (_audioPath == null) { setState(() => _status = 'Please save voice first!'); return; }
    setState(() { _isMerging = true; _status = 'Merging voice with video...'; });
    try {
      final dir = await getTemporaryDirectory();
      final tmpPath = '${dir.path}/reel_preview.mp4';
      if (await File(tmpPath).exists()) await File(tmpPath).delete();

      final session = await FFmpegKit.executeWithArguments([
        '-i', widget.videoFile.path,
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
        title: const Text('Script Editor'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_note), tooltip: 'Paste script',
            onPressed: () => setState(() => _showPaste = true)),
          IconButton(icon: const Icon(Icons.add), tooltip: 'Add line',
            onPressed: (_isSaving || _isMerging) ? null : _addLine),
        ],
      ),
      body: _showPaste ? _buildPastePanel() : _buildEditor(),
    );
  }

  Widget _buildPastePanel() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.deepPurple.shade300),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Format: M:SS your text', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
          SizedBox(height: 4),
          Text('0:00 Ek Teddy Do Dost', style: TextStyle(fontSize: 13, color: Colors.white70)),
          Text('0:05 Arey chhodo ye mera Teddy hai', style: TextStyle(fontSize: 13, color: Colors.white70)),
          Text('0:10 Dono ladne lage', style: TextStyle(fontSize: 13, color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: TextField(
          controller: _pasteCtrl, maxLines: null, expands: true,
          style: const TextStyle(fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText: 'Paste your script here...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true, fillColor: Colors.grey[900],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _applyPaste,
          icon: const Icon(Icons.check),
          label: const Text('Apply Script', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ]),
  );

  Widget _buildEditor() {
    final busy = _isSaving || _isMerging;
    return Column(children: [
      Container(
        width: double.infinity,
        color: Colors.orange.shade900.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text('🎙️ Native TTS Voice  •  ${widget.style}  •  ${widget.language}',
          style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _lines.length,
          itemBuilder: (ctx, i) {
            final isActive = _activeIdx == i;
            return Card(
              color: isActive ? Colors.deepPurple.shade800 : Colors.grey[900],
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 52,
                    child: TextField(
                      controller: _timeCtrls[i],
                      style: const TextStyle(fontSize: 13, color: Colors.amber),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        filled: true, fillColor: Colors.black38,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textCtrls[i], maxLines: null,
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive ? Colors.white : Colors.white70,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        filled: true, fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        hintText: 'Type line here...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: busy ? null : () => _removeLine(i),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
      if (_status.isNotEmpty)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(_status, style: const TextStyle(fontSize: 12))),
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _status));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)));
              },
            ),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(child: _btn(
              icon: _isPlaying ? Icons.stop : Icons.play_arrow,
              label: _isPlaying ? 'Stop' : 'Preview',
              color: _isPlaying ? Colors.red : Colors.blueGrey,
              onPressed: busy ? null : (_isPlaying ? _stopPreview : _previewAll),
            )),
            const SizedBox(width: 8),
            Expanded(child: _btn(
              icon: Icons.record_voice_over,
              label: _isSaving ? 'Generating...' : 'Save Voice 🎙️',
              color: Colors.teal,
              onPressed: busy ? null : _saveAudio,
              loading: _isSaving,
            )),
          ]),
          const SizedBox(height: 8),
          _btn(
            icon: Icons.movie_creation,
            label: _isMerging ? 'Merging...' : 'Merge with Video 🎬',
            color: Colors.deepPurple,
            onPressed: (busy || _audioPath == null) ? null : _mergeWithVideo,
            loading: _isMerging,
          ),
        ]),
      ),
    ]);
  }

  Widget _btn({required IconData icon, required String label, required Color color,
      required VoidCallback? onPressed, bool loading = false}) =>
    SizedBox(width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          disabledBackgroundColor: Colors.grey.shade800,
        ),
      ),
    );
}

// ── Preview Merged Screen ─────────────────────────────────────────────────────

class PreviewMergedScreen extends StatefulWidget {
  final File mergedFile;
  const PreviewMergedScreen({super.key, required this.mergedFile});
  @override
  State<PreviewMergedScreen> createState() => _PreviewMergedScreenState();
}

class _PreviewMergedScreenState extends State<PreviewMergedScreen> {
  VideoPlayerController? _ctrl;
  bool _isSaving = false;
  String _status = '';

  @override
  void initState() { super.initState(); _initVideo(); }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.file(widget.mergedFile);
    await c.initialize();
    c.setLooping(true);
    c.play();
    setState(() => _ctrl = c);
  }

  Future<void> _saveToGallery() async {
    setState(() { _isSaving = true; _status = 'Saving to Movies folder...'; });
    try {
      final outDir = Directory('/storage/emulated/0/Movies');
      if (!await outDir.exists()) await outDir.create(recursive: true);
      final outPath = '${outDir.path}/reel_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await widget.mergedFile.copy(outPath);
      setState(() { _status = '🎉 Saved! Open Files app → Movies folder.'; });
    } catch (e) { setState(() { _status = '❌ $e'; }); }
    setState(() => _isSaving = false);
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Preview Reel'),
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
        Expanded(
          child: _ctrl != null && _ctrl!.value.isInitialized
              ? AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!))
              : const Center(child: CircularProgressIndicator()),
        ),
        if (_status.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
            child: Text(_status, style: const TextStyle(fontSize: 12)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveToGallery,
                icon: _isSaving ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save to Gallery 💾'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.edit),
                label: const Text('Go Back & Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
