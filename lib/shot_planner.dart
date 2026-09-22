import 'dart:convert';

import 'package:flutter/material.dart';

import 'characters.dart';
import 'gemini_call.dart';
import 'secrets.dart';
import 'theme.dart';

const _shotModel = 'gemini-3.6-flash';
const _shotFallback = 'gemini-2.5-flash';
const _shotTimeout = Duration(seconds: 60);

class ShotPlan {
  final int number;
  final int duration;
  final String purpose;
  final String characters;
  final String location;
  final String action;
  final String emotion;
  final String camera;
  final String movement;
  final String dialogue;
  final String ending;

  const ShotPlan({
    required this.number,
    required this.duration,
    required this.purpose,
    required this.characters,
    required this.location,
    required this.action,
    required this.emotion,
    required this.camera,
    required this.movement,
    required this.dialogue,
    required this.ending,
  });

  factory ShotPlan.fromJson(Map<String, dynamic> json, int fallbackNumber, int fallbackDuration) => ShotPlan(
        number: int.tryParse('${json['number']}') ?? fallbackNumber,
        duration: int.tryParse('${json['duration']}') ?? fallbackDuration,
        purpose: '${json['purpose'] ?? 'Story beat'}',
        characters: '${json['characters'] ?? 'Ria, Rio and Cuty'}',
        location: '${json['location'] ?? 'Family home'}',
        action: '${json['action'] ?? ''}',
        emotion: '${json['emotion'] ?? 'Playful'}',
        camera: '${json['camera'] ?? 'Medium shot'}',
        movement: '${json['movement'] ?? 'Gentle character movement'}',
        dialogue: '${json['dialogue'] ?? ''}',
        ending: '${json['ending'] ?? ''}',
      );

  String get veoPrompt => '''Portrait 9:16 animated children's story shot.
Characters: $characters.
Location: $location.
Action: $action.
Emotion: $emotion.
Camera: $camera.
Movement: $movement.
Dialogue or sound cue: $dialogue.
Continuity: preserve the exact supplied character identities, face shapes, hair, clothing, body proportions, colours, and age. Do not redesign the characters. Bright, warm, polished 3D storybook animation for Fun Learning With Palak. No text or captions inside the video. Duration: $duration seconds.''';
}

class ShotDurationPlan {
  final int requested;
  final List<int> durations;

  const ShotDurationPlan(this.requested, this.durations);

  int get actual => durations.fold(0, (sum, item) => sum + item);
  bool get exact => actual == requested;
}

ShotDurationPlan planShotDurations(int target) {
  final options = [4, 6, 8];
  final max = target + 8;
  final best = List<List<int>?>.filled(max + 1, null);
  best[0] = [];
  for (var total = 0; total <= max; total++) {
    final current = best[total];
    if (current == null) continue;
    for (final duration in options) {
      final next = total + duration;
      if (next > max) continue;
      final candidate = [...current, duration];
      final existing = best[next];
      if (existing == null || candidate.length < existing.length) best[next] = candidate;
    }
  }

  List<int>? chosen;
  var distance = 999;
  for (var total = 0; total <= max; total++) {
    final candidate = best[total];
    if (candidate == null || candidate.isEmpty) continue;
    final difference = (total - target).abs();
    if (difference < distance || (difference == distance && total <= target)) {
      chosen = candidate;
      distance = difference;
    }
  }
  return ShotDurationPlan(target, chosen ?? [8]);
}

Future<List<ShotPlan>> generateShotPlan({
  required String story,
  required int targetSeconds,
  String? focus,
  void Function(String message)? onWait,
}) async {
  final durationPlan = planShotDurations(targetSeconds);
  final cast = await CharacterStore.load();
  final castText = cast.map((character) => '${character.name}: ${character.description}').join('\n');
  final focusText = focus == null ? '' : '\nRegenerate shot $focus while keeping every other story beat consistent.\n';
  final prompt = '''You are a cinematic story planner for Fun Learning With Palak.
Turn this complete preschool story into exactly ${durationPlan.durations.length} connected cinematic shots.
Story:
$story

Required durations in order: ${durationPlan.durations.join(', ')} seconds. Total generated duration: ${durationPlan.actual} seconds.
$focusText
Return ONLY valid JSON with this shape:
{"shots":[{"number":1,"duration":8,"purpose":"Hook","characters":"Ria, Mumma","location":"Bedroom","action":"...","emotion":"...","camera":"...","movement":"...","dialogue":"Hinglish dialogue or empty","ending":"..."}]}

Rules:
- Use the exact duration for each corresponding shot.
- Make the sequence Hook, Problem, Escalation, Turn, Payoff, or Ending as appropriate.
- Every shot must have visible action, not a static illustration.
- Keep Ria, Rio, Cuty, Mumma and other characters consistent with the cast descriptions.
- Write dialogue in natural Hinglish using English letters. Keep dialogue short.
- Do not put captions or written words inside the generated video.
- Include a clear child-friendly ending and lesson beat.

REFERENCE CAST:
$castText''';

  final response = await geminiPost(
    model: _shotModel,
    fallbackModel: _shotFallback,
    apiKey: geminiApiKey,
    timeout: _shotTimeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.75,
        'maxOutputTokens': 6000,
        'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(response.statusCode == 429 || response.statusCode == 503
        ? geminiBusyMessage(response.statusCode, response.body)
        : 'Gemini error ${response.statusCode}: ${response.body}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned an empty shot plan.');

  final decoded = jsonDecode(_stripJsonFence(text)) as Map<String, dynamic>;
  final rawShots = decoded['shots'] as List? ?? const [];
  if (rawShots.length != durationPlan.durations.length) {
    throw Exception('Gemini returned ${rawShots.length} shots instead of ${durationPlan.durations.length}.');
  }
  return rawShots.asMap().entries.map((entry) => ShotPlan.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
        entry.key + 1,
        durationPlan.durations[entry.key],
      )).toList();
}

String _stripJsonFence(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('```')) {
    return trimmed.replaceFirst(RegExp(r'^```(?:json)?\s*'), '').replaceFirst(RegExp(r'\s*```$'), '').trim();
  }
  return trimmed;
}

class ShotPlannerScreen extends StatefulWidget {
  final String story;
  final int targetSeconds;

  const ShotPlannerScreen({super.key, required this.story, required this.targetSeconds});

  @override
  State<ShotPlannerScreen> createState() => _ShotPlannerScreenState();
}

class _ShotPlannerScreenState extends State<ShotPlannerScreen> {
  List<ShotPlan> _shots = [];
  bool _loading = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate({String? focus}) async {
    setState(() {
      _loading = true;
      _status = focus == null ? 'Planning cinematic shots...' : 'Regenerating shot $focus...';
    });
    try {
      final shots = await generateShotPlan(
        story: widget.story,
        targetSeconds: widget.targetSeconds,
        focus: focus,
        onWait: (message) { if (mounted) setState(() => _status = message); },
      );
      if (!mounted) return;
      setState(() {
        _shots = shots;
        _loading = false;
        _status = 'Shot plan ready';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationPlan = planShotDurations(widget.targetSeconds);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shot Planner'),
        actions: [
          IconButton(tooltip: 'Regenerate plan', onPressed: _loading ? null : () => _generate(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text('Plan the story before making video', style: AppText.screenTitle),
          Gap.s,
          Text('${durationPlan.durations.length} shots • ${durationPlan.actual}s total', style: AppText.hint),
          if (!durationPlan.exact) ...[
            Gap.s,
            Text('Veo cannot make an exact ${durationPlan.requested}s plan with 4/6/8-second shots, so this uses the nearest valid total.', style: AppText.hint),
          ],
          Gap.m,
          if (_loading) ...[
            const LinearProgressIndicator(),
            Gap.s,
            Text(_status, style: AppText.hint),
          ] else if (_status.isNotEmpty && _shots.isEmpty) ...[
            Text(_status, style: const TextStyle(color: AppColors.danger)),
          ],
          ..._shots.map(_shotCard),
        ],
      ),
    );
  }

  Widget _shotCard(ShotPlan shot) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('SHOT ${shot.number}  •  ${shot.duration}s', style: AppText.section)),
                IconButton(
                  tooltip: 'Regenerate shot',
                  onPressed: _loading ? null : () => _generate(focus: '${shot.number}'),
                  icon: const Icon(Icons.refresh, size: 19),
                ),
              ],
            ),
            Text(shot.purpose, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
            Gap.s,
            _line('Characters', shot.characters),
            _line('Location', shot.location),
            _line('Action', shot.action),
            _line('Emotion', shot.emotion),
            _line('Camera', shot.camera),
            _line('Movement', shot.movement),
            if (shot.dialogue.isNotEmpty) _line('Hinglish dialogue', shot.dialogue),
            if (shot.ending.isNotEmpty) _line('Ending beat', shot.ending),
            Gap.s,
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('Veo prompt', style: AppText.section),
              children: [Text(shot.veoPrompt, style: AppText.hint)],
            ),
          ],
        ),
      ),
      );

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: RichText(text: TextSpan(style: AppText.hint, children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
          TextSpan(text: value),
        ])),
      );
}
