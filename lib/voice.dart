import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ── Which voice speaks the script ─────────────────────────────────────────────
//
// Three engines behind one call, so trying another is a setting rather than an edit.
// The phone is the only one that always works — the other two need a key and a network,
// so it stays the default and the fallback.

enum VoiceEngine { phone, gemini, elevenLabs }

String voiceEngineLabel(VoiceEngine engine) {
  switch (engine) {
    case VoiceEngine.gemini:
      return '✨ Gemini';
    case VoiceEngine.elevenLabs:
      return '🎧 ElevenLabs';
    case VoiceEngine.phone:
      return '📱 Phone';
  }
}

String voiceEngineHint(VoiceEngine engine) {
  switch (engine) {
    case VoiceEngine.gemini:
      return 'Natural voice, free tier. Needs internet.';
    case VoiceEngine.elevenLabs:
      return 'Best quality, about 25 reels a month free.';
    case VoiceEngine.phone:
      return 'Always works, no internet, but sounds robotic.';
  }
}

// ── Gemini speech ─────────────────────────────────────────────────────────────
//
// One place for the names Google changes. To see what your key can use:
//   https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY
// Look for a model with "tts" in the name; if this one is rejected, put that one here.
// Confirmed working: Google resolves this to gemini-2.5-flash-tts, which is the name
// that comes back in quota errors. Either appears to be accepted.
const geminiTtsModel = 'gemini-2.5-flash-preview-tts';

/// Gemini's prebuilt voices. Kore is warm and even, which suits a children's story.
const geminiVoiceName = 'Kore';

const _timeout = Duration(seconds: 60);

// ── One call, whichever engine ────────────────────────────────────────────────

/// Speaks one line to a file and returns the path it wrote.
///
/// The extension is decided here, not by the caller: the phone and Gemini produce WAV
/// while ElevenLabs produces MP3, and FFmpeg works out the format from the extension.
Future<String> synthesizeLine({
  required VoiceEngine engine,
  required String text,
  required String basePath,
  required String languageTag,
  required double rate,
  required double pitch,
  required String geminiKey,
  required String elevenLabsKey,
  required String elevenVoiceId,
  /// Called while waiting out a rate limit, so a long pause doesn't look like a hang.
  void Function(String message)? onWait,
}) async {
  switch (engine) {
    case VoiceEngine.gemini:
      return _geminiSpeak(
        text: text, outPath: '$basePath.wav', apiKey: geminiKey, onWait: onWait);
    case VoiceEngine.elevenLabs:
      return _elevenLabsSpeak(
        text: text, outPath: '$basePath.mp3',
        apiKey: elevenLabsKey, voiceId: elevenVoiceId,
      );
    case VoiceEngine.phone:
      return _phoneSpeak(
        text: text, outPath: '$basePath.wav',
        languageTag: languageTag, rate: rate, pitch: pitch,
      );
  }
}

// ── Phone ─────────────────────────────────────────────────────────────────────

const _ttsChannel = MethodChannel('com.example.reel_audio/tts');

Future<String> _phoneSpeak({
  required String text,
  required String outPath,
  required String languageTag,
  required double rate,
  required double pitch,
}) async {
  await _deleteIfExists(outPath);
  await _ttsChannel.invokeMethod('synthesizeToFile', {
    'text': text, 'filePath': outPath,
    'lang': languageTag, 'rate': rate, 'pitch': pitch,
  });

  // Android reports the utterance done a moment before the file is closed.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (!await File(outPath).exists()) {
    throw Exception('The phone voice produced no file. Check Settings → '
        'Accessibility → Text-to-speech and that the language is installed.');
  }
  return outPath;
}

// ── Gemini ────────────────────────────────────────────────────────────────────

/// Gemini's free tier allows this many speech requests a minute, per model.
///
/// The app speaks one line per request, so a seven line script fires seven requests in
/// a few seconds and the fourth comes back 429. Pacing them here is the difference
/// between "slow but it works" and "fails halfway with a wall of JSON".
const geminiSpeechPerMinute = 3;

/// When each recent Gemini speech request went out, so the next one can wait its turn.
final List<DateTime> _geminiCallTimes = [];

/// Blocks until a request would be inside the free-tier limit.
Future<void> _waitForGeminiSlot(void Function(String)? onWait) async {
  final now = DateTime.now();
  _geminiCallTimes.removeWhere((t) => now.difference(t).inSeconds >= 60);
  if (_geminiCallTimes.length < geminiSpeechPerMinute) return;

  // The oldest of the three has to fall out of the window before there is room.
  final oldest = _geminiCallTimes.first;
  final wait = 61 - now.difference(oldest).inSeconds;
  if (wait <= 0) return;

  for (var left = wait; left > 0; left--) {
    onWait?.call('Free tier allows $geminiSpeechPerMinute lines a minute — '
        'waiting ${left}s...');
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  _geminiCallTimes.removeWhere(
      (t) => DateTime.now().difference(t).inSeconds >= 60);
}

Future<String> _geminiSpeak({
  required String text,
  required String outPath,
  required String apiKey,
  void Function(String message)? onWait,
}) async {
  if (apiKey.trim().isEmpty) {
    throw Exception('No Gemini key set in secrets.dart.');
  }
  await _waitForGeminiSlot(onWait);
  _geminiCallTimes.add(DateTime.now());
  await _deleteIfExists(outPath);

  final url = 'https://generativelanguage.googleapis.com/v1beta/models/'
      '$geminiTtsModel:generateContent?key=$apiKey';

  final body = jsonEncode({
    'contents': [
      {'parts': [{'text': text}]}
    ],
    'generationConfig': {
      'responseModalities': ['AUDIO'],
      'speechConfig': {
        'voiceConfig': {
          'prebuiltVoiceConfig': {'voiceName': geminiVoiceName},
        },
      },
    },
  });

  var response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: body,
  ).timeout(_timeout);

  // Pacing above keeps us under the limit in normal use, but the window is Google's,
  // not ours — another app on the same key, or a retry after an error, can still push
  // us over. Google says how long to wait, so wait that long and go again rather than
  // throwing away the whole script.
  if (response.statusCode == 429) {
    final seconds = _retryAfterSeconds(response.body);
    for (var left = seconds; left > 0; left--) {
      onWait?.call('Gemini free tier is busy — retrying in ${left}s...');
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    _geminiCallTimes.clear();
    _geminiCallTimes.add(DateTime.now());
    response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(_timeout);
  }

  if (response.statusCode == 404) {
    throw Exception('Gemini has no speech model called "$geminiTtsModel" for this key.\n'
        'Check the models list and put the right name in lib/voice.dart.');
  }
  if (response.statusCode == 429) {
    throw Exception('Gemini free tier is out of speech requests for now '
        '(only $geminiSpeechPerMinute a minute). Switch the voice to Phone, '
        'or wait a minute and press Save Voice again.');
  }
  if (response.statusCode != 200) {
    throw Exception('Gemini speech error ${response.statusCode}: ${response.body}');
  }

  final json = jsonDecode(response.body);
  final part = json['candidates']?[0]?['content']?['parts']?[0];
  final base64Audio = part?['inlineData']?['data'] as String?;
  if (base64Audio == null || base64Audio.isEmpty) {
    throw Exception('Gemini returned no audio for: "$text"');
  }

  // Gemini hands back raw PCM, not a playable file, so it needs a WAV header before
  // FFmpeg or a player will touch it. The rate is named in the mime type.
  final mime = part?['inlineData']?['mimeType'] as String? ?? '';
  final pcm = base64Decode(base64Audio);
  await File(outPath).writeAsBytes(_wrapPcmAsWav(pcm, sampleRate: _rateFromMime(mime)));
  return outPath;
}

/// How long Google asked us to wait, from the retryDelay in a 429 body ("19s").
/// A second is added because retrying on the exact boundary tends to fail again.
int _retryAfterSeconds(String body) {
  final match = RegExp(r'"retryDelay"\s*:\s*"(\d+)').firstMatch(body);
  final seconds = int.tryParse(match?.group(1) ?? '') ?? 25;
  return seconds.clamp(1, 90) + 1;
}

/// Reads the rate out of "audio/L16;codec=pcm;rate=24000". Falls back to Gemini's
/// usual 24 kHz — a wrong rate doesn't fail, it just plays at the wrong speed.
int _rateFromMime(String mimeType) {
  final match = RegExp(r'rate=(\d+)').firstMatch(mimeType);
  return int.tryParse(match?.group(1) ?? '') ?? 24000;
}

// ── ElevenLabs ────────────────────────────────────────────────────────────────

Future<String> _elevenLabsSpeak({
  required String text,
  required String outPath,
  required String apiKey,
  required String voiceId,
}) async {
  if (apiKey.trim().isEmpty || apiKey == 'unused') {
    throw Exception('No ElevenLabs key set in secrets.dart.');
  }
  await _deleteIfExists(outPath);

  final response = await http.post(
    Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
    headers: {
      'xi-api-key': apiKey,
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
      },
    }),
  ).timeout(_timeout);

  if (response.statusCode == 401) {
    throw Exception('ElevenLabs rejected the key. Check it in secrets.dart.');
  }
  if (response.statusCode == 429) {
    throw Exception('ElevenLabs monthly free characters are used up. '
        'Switch the voice to Phone or Gemini.');
  }
  if (response.statusCode != 200) {
    throw Exception('ElevenLabs error ${response.statusCode}: ${response.body}');
  }

  await File(outPath).writeAsBytes(response.bodyBytes);
  return outPath;
}

// ── WAV ───────────────────────────────────────────────────────────────────────

/// Puts a 44-byte WAV header in front of raw 16-bit mono PCM.
Uint8List _wrapPcmAsWav(Uint8List pcm, {int sampleRate = 24000}) {
  const channels = 1;
  const bitsPerSample = 16;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final byteRate = sampleRate * blockAlign;

  final out = BytesBuilder();
  out.add(ascii.encode('RIFF'));
  out.add(_le32(36 + pcm.length));
  out.add(ascii.encode('WAVE'));
  out.add(ascii.encode('fmt '));
  out.add(_le32(16));       // size of this chunk
  out.add(_le16(1));        // 1 = uncompressed PCM
  out.add(_le16(channels));
  out.add(_le32(sampleRate));
  out.add(_le32(byteRate));
  out.add(_le16(blockAlign));
  out.add(_le16(bitsPerSample));
  out.add(ascii.encode('data'));
  out.add(_le32(pcm.length));
  out.add(pcm);
  return out.toBytes();
}

Uint8List _le32(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little);

Uint8List _le16(int value) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little);

Future<void> _deleteIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
