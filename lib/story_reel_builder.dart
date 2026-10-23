// Story Reel Builder — generates 10-second Reels split into two 10-second
// segments, specifically for the Navratri reel ideas and similar short
// character-story content.
//
// Uses the existing AI pipeline (AIProvider → ContentPackage → ContentPackageV2)
// but with a Reel-specific prompt and forced 10-second scene durations.

import 'ai_provider.dart';
import 'brand_system.dart';
import 'content_axes.dart';
import 'content_generator.dart';
import 'content_package_v2.dart';
import 'content_quality_gate.dart';
import 'prompts.dart';
import 'story_ideas.dart';

/// Input parameters for a Story Reel generation request.
class StoryReelRequest {
  final String ideaId;
  final String title;
  final String parentProblem;
  final String learningGoal;
  final String hook;
  final List<String> characters;
  final ContentPillar pillar;
  final ContentSeries? series;
  final ContentGoal? goal;
  final String language;
  final String tone;
  final int segmentDurationSeconds;
  final int segmentCount;

  const StoryReelRequest({
    required this.ideaId,
    required this.title,
    required this.parentProblem,
    required this.learningGoal,
    required this.hook,
    required this.characters,
    required this.pillar,
    this.series,
    this.goal,
    this.language = 'hinglish',
    this.tone = 'warm, playful, parent-relatable',
    this.segmentDurationSeconds = 10,
    this.segmentCount = 2,
  })  : assert(segmentCount >= 1 && segmentCount <= 10,
            'segmentCount must be between 1 and 10'),
        assert(segmentDurationSeconds >= 5 && segmentDurationSeconds <= 30,
            'segmentDurationSeconds must be between 5 and 30');

  /// Total Reel duration.
  int get totalDurationSeconds => segmentDurationSeconds * segmentCount;

  /// Builds the AI generation prompt with Reel-specific instructions.
  String toPromptString() {
    final charList = characters.map((id) {
      final c = CharacterLibrary.byId(id);
      return c?.name ?? id;
    }).join(', ');
    return _buildReelPrompt(
      title: title,
      parentProblem: parentProblem,
      learningGoal: learningGoal,
      hook: hook,
      characters: charList,
      pillar: pillar.label,
      language: language,
      tone: tone,
      segmentDuration: segmentDurationSeconds,
      segmentCount: segmentCount,
    );
  }
}

class StoryReelBuilder {
  final AIProvider _provider;

  StoryReelBuilder(this._provider);

  /// Generates a Story Reel package for the given request.
  ///
  /// Produces [request.segmentCount] scenes, each [request.segmentDurationSeconds]
  /// long. For Navratri reels: 2 scenes × 10 seconds = 20 seconds total.
  Future<ContentPackageV2> buildReel(StoryReelRequest request) async {
    final input = IdeaInput(
      topic: request.hook,
      bucket: _resolveBucket(request.pillar),
      targetFormats: [ContentFormat.reel],
      brand: _brandContext(),
      characters: _resolveCharacters(request.characters),
      slideCount: request.segmentCount,
      extraContext: {
        'storyReelPrompt': request.toPromptString(),
        'segmentDurationSeconds': request.segmentDurationSeconds,
      },
    );

    final pkg = await _provider.generate(input);
    return _convertToReelPackage(pkg, request);
  }

  ContentBucket _resolveBucket(ContentPillar pillar) {
    switch (pillar) {
      case ContentPillar.play:
        return BucketLibrary.challenge;
      case ContentPillar.doIt:
        return BucketLibrary.activity;
      case ContentPillar.talk:
        return BucketLibrary.conversation;
      default:
        return BucketLibrary.challenge;
    }
  }

  BrandContext _brandContext() {
    return BrandContext(
      brandName: 'Fun Learning With Palak',
      handle: '@funlearningwithpalak',
      audience: 'Parents of preschoolers (1-4)',
      tone: 'warm, playful, parent-relatable',
      visualStyle: 'Soft 3D Pixar/Disney-style render, cream backgrounds, gentle textures',
      defaultHashtags: ['#FunLearningWithPalak', '#ScreenFreePlay', '#Parenting'],
      ctaOptions: ['Save for later', 'Try at home', 'Follow for more'],
      characters: const [
        CharacterLibrary.ria,
        CharacterLibrary.rio,
        CharacterLibrary.cuty,
        CharacterLibrary.mumma,
      ],
    );
  }

  List<Character> _resolveCharacters(List<String> names) {
    final resolved = names
        .map((id) => CharacterLibrary.byId(id))
        .whereType<Character>()
        .toList();
    if (resolved.isEmpty) {
      return [CharacterLibrary.byId('ria'), CharacterLibrary.byId('rio')]
          .whereType<Character>()
          .toList();
    }
    return resolved;
  }

  ContentPackageV2 _convertToReelPackage(
    ContentPackage pkg,
    StoryReelRequest request,
  ) {
    final now = DateTime.now();
    final classification = ClassificationSnapshotV2(
      pillar: request.pillar,
      series: request.series,
      narrativeFormatName: 'problemFix',
      contentType: ContentType.reel,
      productionMethod: ProductionMethod.characterImages,
      goal: request.goal ?? ContentGoal.reach,
      status: IdeaStatus.idea,
      axisStates: {},
      capturedAt: now,
    );

    final scenes = pkg.slides.asMap().entries.map((entry) {
      final body = entry.value.body;
      return Scene(
        index: entry.key,
        title: entry.value.title,
        description: body,
        visualPrompt: entry.value.visualPrompt,
        narration: body.isNotEmpty ? body : null,
        overlayText: entry.value.overlayText,
        durationSeconds: request.segmentDurationSeconds,
      );
    }).toList();

    final shotList = pkg.slides.asMap().entries.map((entry) {
      final i = entry.key;
      return ShotListItem(
        shotNumber: i,
        title: entry.value.title,
        visualDescription: entry.value.visualPrompt,
        cameraMove: _cameraMoveFor(i),
        lighting: 'Soft natural lighting',
        durationSeconds: request.segmentDurationSeconds,
        characters: request.characters,
      );
    }).toList();

    final script = pkg.slides.map((s) => s.body).where((b) => b.isNotEmpty).join('\n');
    final narration = pkg.slides.map((s) => s.body).where((b) => b.isNotEmpty).join('\n');

    return ContentPackageV2(
      id: '${request.ideaId}-reel-${now.millisecondsSinceEpoch}',
      ideaId: request.ideaId,
      createdAt: now,
      updatedAt: now,
      classification: classification,
      audience: 'Parents of preschoolers (1-4)',
      problem: request.parentProblem,
      lesson: request.learningGoal,
      hook: pkg.hook,
      shareTrigger: ShareTrigger.filled(
        sender: 'Mumma',
        recipient: 'Parent friend',
        situation: 'Toddler screen-time refusal',
        reason: 'Relatable hack they can try tonight',
      ),
      voiceMode: VoiceMode.required,
      cta: pkg.cta,
      reachCandidacy: ReachCandidacy.yes,
      productionCompatibility: ProductionCompatibility.yes,
      title: request.title,
      script: script,
      narration: narration,
      dialogue: '',
      caption: pkg.caption,
      hashtags: pkg.hashtags,
      scenes: scenes,
      productionMethod: ProductionMethod.characterImages,
      shotList: shotList,
      imagePrompts: pkg.visualPrompts,
      experimentGroup: 'navratri-reels',
      testNumber: 1,
      testCount: request.segmentCount,
    );
  }

  String _cameraMoveFor(int index) {
    const moves = ['slow_zoom_in', 'slow_pan', 'static_gentle'];
    return moves[index % moves.length];
  }
}

String _buildReelPrompt({
  required String title,
  required String parentProblem,
  required String learningGoal,
  required String hook,
  required String characters,
  required String pillar,
  required String language,
  required String tone,
  required int segmentDuration,
  required int segmentCount,
}) {
  final totalDuration = segmentDuration * segmentCount;
  final sceneDescriptions = StringBuffer();
  for (int i = 1; i <= segmentCount; i++) {
    if (i == 1) {
      sceneDescriptions.writeln('Scene 1 (${segmentDuration}s): Hook + relatable setup + the real struggle (show, don\'t tell)');
    } else if (i == segmentCount) {
      sceneDescriptions.writeln('Scene $i (${segmentDuration}s): The small practical jugaad/solution + warm takeaway');
    } else {
      sceneDescriptions.writeln('Scene $i (${segmentDuration}s): Escalation or bridge between struggle and solution');
    }
  }

  final slideExamples = StringBuffer();
  for (int i = 1; i <= segmentCount; i++) {
    slideExamples.writeln('    {');
    slideExamples.writeln('      "slideNumber": $i,');
    slideExamples.writeln('      "headline": "Scene $i heading",');
    slideExamples.writeln('      "body": "Scene $i content",');
    slideExamples.writeln('      "imagePrompt": "Detailed visual: characters, action, expression, 3D Pixar style, cream background",');
    slideExamples.writeln('      "overlayText": "Short overlay for scene $i",');
    slideExamples.writeln('      "cta": "CTA for scene $i"');
    slideExamples.write('    }');
    if (i < segmentCount) slideExamples.writeln(',');
  }

  return '''
STORY REEL REQUEST:

Title: "$title"
Parent Problem: "$parentProblem"
Learning Goal: "$learningGoal"
Hook (max 125 chars, scroll-stopping): "$hook"

Characters: $characters
Pillar: $pillar
Language: $language
Tone: $tone
Format: Vertical 9:16 Reel, $totalDuration seconds total ($segmentCount scenes, each exactly $segmentDuration seconds)

STRUCTURE:
$sceneDescriptions
INSTRUCTIONS:
- Show the real struggle first, then a small realistic adjustment that helps — never perfect parents who solve everything instantly
- Narration: max 2 lines per scene, short on screen, easy to say in about $segmentDuration seconds
- Each scene needs: title, body (max 160 chars), visualPrompt, overlayText (max 40 chars), cta (max 60 chars)
- Visual style: Soft 3D Pixar/Disney-style render, cream backgrounds, characters $characters
- Character lock: Ria and Rio NEVER wear glasses; Cuty is ALWAYS a small white bunny with pink bow
- Output valid JSON matching the schema with exactly $segmentCount slides

OUTPUT JSON SCHEMA:
{
  "topic": "$hook",
  "bucket": "challenge",
  "hook": "$hook",
  "slides": [
$slideExamples,
  ],
  "caption": "Hook + idea + CTA + exactly 5 hashtags",
  "hashtags": ["5hashtags", "max12chars", "each", "mixbrand", "bucket"],
  "pinnedComment": "Engagement-driving question",
  "replyComments": ["relatable parent response", "non-parent response", "emoji reaction", "validation", "CTA"],
  "script": "Full narration for all $segmentCount scenes, timed to ${totalDuration}s total"
}
''';
}

// ── Stage 2: Length calculator ─────────────────────────────────────────────────
//
// Converts a BeatSheet (Stage 1, no timing) into N 10-second parts by spreading
// the beats across the parts based on the chosen length.

/// Returns the number of 10-second parts for a given total length.
/// 20 → 2, 30 → 3, 40 → 4, 60 → 6.
int partsForLength(int seconds) => (seconds / 10).round();

/// How beats map to parts for each supported length.
///
/// Beat indices: 0=setup, 1=problem, 2=escalation, 3=turn, 4=payoff
/// Sentinel values:
/// -1 = stretch beat if present, otherwise skipped
/// -2 = extra escalation or reaction beat
/// -3 = payoff buffer / ending
///
/// - 20s (2 parts): [0,1,2] → Part 1, [3,4] → Part 2
/// - 30s (3 parts): [0,1] → Part 1, [2,-1] → Part 2 (escalation + stretch),
///   [3,4] → Part 3
/// - 40s (4 parts): [0,1] → Part 1, [2,-1] → Part 2, [-2,3] → Part 3,
///   [4,-3] → Part 4
/// - 60s (6 parts): the 30s structure spread across six parts. Adjacent
///   parts share a beat at the cut point, so the turn and the payoff each
///   span two clips instead of being squeezed into one.
class PartBeatMapping {
  final List<List<int>> partToBeatIndices;
  const PartBeatMapping(this.partToBeatIndices);
}

PartBeatMapping beatIndicesForParts(int seconds) {
  final parts = partsForLength(seconds);
  switch (parts) {
    case 2:
      return const PartBeatMapping([
        [0, 1, 2],
        [3, 4],
      ]);
    case 3:
      return const PartBeatMapping([
        [0, 1],
        [2, -1],
        [3, 4],
      ]);
    case 4:
      return const PartBeatMapping([
        [0, 1],
        [2, -1],
        [-2, 3],
        [4, -3],
      ]);
    case 6:
      // The 30s structure expanded across six parts. Adjacent parts share a
      // beat at the cut point, so a beat that needs more than 10 seconds to
      // land (the turn and the payoff) spans two clips instead of being
      // squeezed into one or dropped.
      return const PartBeatMapping([
        [0, 1],
        [2, -1],
        [-2, 3],
        [3, 4],
        [4, -3],
        [-3, 4],
      ]);
    default:
      throw ArgumentError(
          'Unsupported reel length: $seconds seconds. Use 20, 30, 40 or 60.');
  }
}

/// Builds N self-contained 10-second video prompts from a BeatSheet + length.
///
/// Each prompt is standalone: style, size, characters, camera, timed action,
/// and a continuity line for Parts 2+. Returns the canonical
/// [VideoClipPrompt] model defined in `prompts.dart` so there is one output
/// type for the whole two-stage workflow.
List<VideoClipPrompt> buildVideoPrompts({
  required BeatSheet beats,
  required int seconds,
}) {
  final parts = partsForLength(seconds);
  final mapping = beatIndicesForParts(seconds);
  final prompts = <VideoClipPrompt>[];

  for (int i = 0; i < parts; i++) {
    final isFirst = i == 0;
    final beatIndices = mapping.partToBeatIndices[i];
    final prompt = _buildPartPrompt(
      beats: beats,
      partNumber: i + 1,
      totalParts: parts,
      beatIndices: beatIndices,
      isFirstPart: isFirst,
    );
    prompts.add(VideoClipPrompt(
      partNumber: i + 1,
      totalParts: parts,
      promptText: prompt,
    ));
  }

  return prompts;
}

String _buildPartPrompt({
  required BeatSheet beats,
  required int partNumber,
  required int totalParts,
  required List<int> beatIndices,
  required bool isFirstPart,
}) {
  final cast = beats.characters
      .map((id) => CharacterLibrary.byId(id))
      .whereType<Character>()
      .toList();

  final beatTexts = <String>[];
  for (final idx in beatIndices) {
    if (idx == -1) {
      if (beats.hasStretchBeat) {
        beatTexts.add(beats.stretchBeat!);
      }
    } else if (idx == -2) {
      beatTexts.add(beats.beat3Escalation);
    } else if (idx == -3) {
      beatTexts.add(beats.beat5Payoff);
    } else if (idx >= 0 && idx < beats.beats.length) {
      beatTexts.add(beats.beats[idx]);
    }
  }

  // Every 10-second part must carry meaningful action in all three intervals.
  // A part that only has one beat would otherwise leave 4-10s empty, and the
  // last part must not be written off as a "transition to next part". When a
  // part has fewer beats than intervals, the beat is developed along the
  // story's natural order rather than repeated verbatim.
  final action04 = beatTexts.isNotEmpty
      ? beatTexts[0]
      : beats.beat3Escalation;
  final action48 = beatTexts.length > 1
      ? beatTexts[1]
      : _nextBeat(beatTexts, beats, skip: 1);
  final action810 = beatTexts.length > 2
      ? beatTexts[2]
      : _nextBeat(beatTexts, beats, skip: 2);

  final continuity = isFirstPart
      ? ''
      : 'CONTINUITY: This is Part $partNumber of $totalParts. The first frame must '
          'match the previous clip exactly — same room, same lighting, same '
          'character positions and same outfits. Do not restart the story; '
          'continue from where the previous clip ended.';

  return '''
Create a 10-second vertical 9:16 animated video clip.

STYLE: ${BrandDefaults.visualStyle}
SIZE: Vertical 9:16 (1080x1920). Keep characters centred and leave the bottom
20% clear for Instagram's overlay buttons.

${CharacterLibrary.characterLockFor(cast)}

Only the characters named above may appear. Do not introduce background
characters, bystanders, extras or mascots. Ria and Rio must never wear glasses.

SETTING: ${beats.where}

CAMERA: Fixed medium shot at child eye level. Keep the characters centred in
the frame; the bottom 20% must stay clear.

ACTION:
0-4s: $action04
4-8s: $action48
8-10s: $action810

AUDIO: Hinglish narration describing the action above, plus matching natural
sound effects. No background music.

AVOID: Distorted hands, changing outfits between clips, on-screen text, logos,
and any visual inconsistency with the reference images.
$continuity
''';
}

/// The next beat in the story after the ones this part already uses.
///
/// When a part has fewer beats than action intervals, the remaining intervals
/// follow the story forward instead of repeating the same sentence. Beats are
/// consumed in the story's own order: setup, problem, escalation, stretch,
/// turn, payoff, ending line. A beat that already appears in this part counts
/// as used once for every time it appears, so a part carrying the payoff beat
/// twice does not loop back to the setup.
String _nextBeat(List<String> used, BeatSheet beats, {required int skip}) {
  final ordered = <String>[
    beats.beat1Setup,
    beats.beat2Problem,
    beats.beat3Escalation,
    if (beats.hasStretchBeat) beats.stretchBeat!,
    beats.beat4Turn,
    beats.beat5Payoff,
    beats.endingLine,
  ];
  for (final beat in ordered) {
    if (used.where((b) => b == beat).length <= skip) continue;
    return beat;
  }
  // Everything in the story has already been used by this part; fall back to
  // the ending line rather than repeating the first beat a third time.
  return beats.endingLine;
}
