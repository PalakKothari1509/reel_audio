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
  });

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
    return names
        .map((id) => CharacterLibrary.byId(id))
        .whereType<Character>()
        .toList();
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
Scene 1 (${segmentDuration}s): Hook + relatable setup + the real struggle (show, don't tell)
Scene 2 (${segmentDuration}s): The small practical jugaad/solution + warm takeaway

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
    {
      "slideNumber": 1,
      "headline": "Scene 1 heading",
      "body": "Scene 1 content — the struggle",
      "imagePrompt": "Detailed visual: characters, action, expression, 3D Pixar style, cream background",
      "overlayText": "Short overlay for scene 1",
      "cta": "CTA for scene 1"
    },
    {
      "slideNumber": 2,
      "headline": "Scene 2 heading",
      "body": "Scene 2 content — the solution + takeaway",
      "imagePrompt": "Detailed visual: characters, action, expression, 3D Pixar style, cream background",
      "overlayText": "Short overlay for scene 2",
      "cta": "CTA for scene 2"
    }
  ],
  "caption": "Hook + idea + CTA + exactly 5 hashtags",
  "hashtags": ["5hashtags", "max12chars", "each", "mixbrand", "bucket"],
  "pinnedComment": "Engagement-driving question",
  "replyComments": ["relatable parent response", "non-parent response", "emoji reaction", "validation", "CTA"],
  "script": "Full narration for both scenes, timed to ${totalDuration}s total"
}
''';
}
