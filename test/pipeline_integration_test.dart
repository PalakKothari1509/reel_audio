import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/ai_content_service.dart';
import 'package:reel_audio/ai_content_service_impl.dart';
import 'package:reel_audio/ai_provider.dart';
import 'package:reel_audio/ai_parser_validator.dart';
import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_generator.dart';
import 'package:reel_audio/content_package_v2.dart';
import 'package:reel_audio/content_quality_gate.dart';
import 'package:reel_audio/production_adapter.dart';

/// A mock AIProvider that returns pre-canned JSON or throws.
class MockAIProvider implements AIProvider {
  final String? cannedJson;
  final Exception? error;
  bool generateCalled = false;

  MockAIProvider({this.cannedJson, this.error});

  @override
  Future<ContentPackage> generate(IdeaInput input) async {
    generateCalled = true;
    if (error != null) throw error!;
    if (cannedJson == null) {
      throw Exception('No canned response set');
    }
    // Simulate what GeminiClient would do: parse JSON → ContentPackage
    return _parseCanned(cannedJson!, input);
  }

  @override
  Future<ContentPackage> regenerate(
      ContentPackage pkg, dynamic target, dynamic style) {
    throw UnimplementedError();
  }

  @override
  Future<void> testConnection() async {}

  @override
  String get providerName => 'Mock';

  @override
  bool get isAvailable => error == null;

  static ContentPackage _parseCanned(String jsonText, IdeaInput input) {
    final validated = AiParserValidator.validateOrThrow(jsonText);
    final map = validated.data;

    final slides = ((map['slides'] as List?) ?? const [])
        .whereType<Map>()
        .map((s) {
          final m = s.cast<String, dynamic>();
          return SlideContent(
            index: m['slideNumber'] as int? ?? 0,
            title: m['headline'] as String? ?? '',
            body: m['body'] as String? ?? '',
            visualPrompt: m['imagePrompt'] as String? ?? '',
            overlayText: m['cta'] as String?,
          );
        })
        .toList();

    return ContentPackage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idea: map['topic'] as String? ?? input.topic,
      bucket: BucketLibrary.byId(map['bucket'] as String? ?? '') ?? input.bucket,
      format: input.targetFormats.first,
      characters: input.characters,
      hook: map['hook'] as String? ?? '',
      slides: slides,
      visualPrompts: slides.map((s) => s.visualPrompt).toList(),
      caption: map['caption'] as String? ?? '',
      cta: slides.isNotEmpty ? slides.last.overlayText ?? '' : '',
      hashtags: (map['hashtags'] as List?)?.cast<String>() ?? [],
      pinnedComment: map['pinnedComment'] as String? ?? '',
      replyComments: (map['replyComments'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('Pipeline integration: Gemini → Validator → AiContentService → ContentPackageV2', () {
    late ClassificationSnapshot fullyApproved;
    late GateReport gateReport;

    setUp(() {
      fullyApproved = ClassificationSnapshot(
        narrativeFormatName: 'problemFix',
        contentType: ContentType.reel,
        productionMethod: ProductionMethod.characterImages,
        goal: ContentGoal.reach,
        pillar: ContentPillar.play,
        axisStates: {
          'pillar': AxisResolution.approved,
          'series': AxisResolution.approved,
          'narrativeFormat': AxisResolution.approved,
          'contentType': AxisResolution.approved,
          'productionMethod': AxisResolution.approved,
          'goal': AxisResolution.approved,
        },
        shareTrigger: ShareTrigger.filled(
          sender: 'Parent',
          recipient: 'Friend',
          situation: 'Sock refusal',
          reason: 'Same thing',
        ),
      );

      gateReport = QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: fullyApproved,
        voiceMode: VoiceMode.required,
        testCount: 5,
      );
    });

    test('full valid response preserves hook/narration/dialogue through conversion', () async {
      final json = jsonEncode({
        'topic': 'sock-hunt',
        'bucket': 'challenge',
        'hook': 'Where did the socks go?',
        'script': 'Where did the socks go? Check under the bed. Cuty: I hid them!',
        'slides': [
          {
            'slideNumber': 1,
            'headline': 'The Mystery',
            'body': 'Where did the socks go?',
            'imagePrompt': 'child looking under bed',
            'cta': 'Save for later',
          },
          {
            'slideNumber': 2,
            'headline': 'The Find',
            'body': 'Cuty: I hid them! Under the bed.',
            'imagePrompt': 'bunny behind bed',
          },
        ],
        'caption': 'Lost socks? Check under the bed!',
        'hashtags': ['#parenting', '#toddlers'],
        'pinnedComment': 'Everyone loses socks here',
        'replyComments': ['So true!', 'My kid does this'],
      });

      final mockProvider = MockAIProvider(cannedJson: json);
      final svc = AiContentServiceImpl(mockProvider);

      final pkg = await svc.generate(GenerationRequest(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        gateReport: gateReport,
      ));

      // Core content survives
      expect(pkg.hook, 'Where did the socks go?');
      expect(pkg.script.contains('Where did the socks go'), isTrue);
      expect(pkg.narration.contains('Where did the socks go'), isTrue);
      expect(pkg.caption, 'Lost socks? Check under the bed!');
      expect(pkg.hashtags, ['#parenting', '#toddlers']);

      // Scenes have per-scene content
      expect(pkg.scenes.length, 2);
      expect(pkg.scenes[0].narration, contains('Where did the socks go'));
      expect(pkg.scenes[0].dialogue, isNull);
      expect(pkg.scenes[1].dialogue, contains('Cuty'));
    });

    test('malformed JSON produces AiContentFailure, not silent empty result', () async {
      final mockProvider = MockAIProvider(cannedJson: '{broken json}');
      final svc = AiContentServiceImpl(mockProvider);

      expect(
        () => svc.generate(GenerationRequest(
          ideaId: 'test',
          title: 'Test',
          gateReport: gateReport,
        )),
        throwsA(isA<AiContentFailure>()),
      );
    });

    test('empty response ({}) produces AiContentFailure', () async {
      final mockProvider = MockAIProvider(cannedJson: '{}');
      final svc = AiContentServiceImpl(mockProvider);

      expect(
        () => svc.generate(GenerationRequest(
          ideaId: 'test',
          title: 'Test',
          gateReport: gateReport,
        )),
        throwsA(isA<AiContentFailure>()),
      );
    });

    test('response missing slides produces AiContentFailure', () async {
      final json = jsonEncode({'hook': 'Test hook'});
      final mockProvider = MockAIProvider(cannedJson: json);
      final svc = AiContentServiceImpl(mockProvider);

      expect(
        () => svc.generate(GenerationRequest(
          ideaId: 'test',
          title: 'Test',
          gateReport: gateReport,
        )),
        throwsA(isA<AiContentFailure>()),
      );
    });

    test('AI provider timeout is wrapped as AiContentFailure', () async {
      final mockProvider = MockAIProvider(
        error: TimeoutException('Request timed out', Duration(seconds: 45)),
      );
      final svc = AiContentServiceImpl(mockProvider);

      expect(
        () => svc.generate(GenerationRequest(
          ideaId: 'test',
          title: 'Test',
          gateReport: gateReport,
        )),
        throwsA(isA<AiContentFailure>()),
      );
    });

    test('ContentPackageV2 from full pipeline preserves classification snapshot', () async {
      final json = jsonEncode({
        'topic': 'sock-hunt',
        'hook': 'Where did the socks go?',
        'script': 'Narration here',
        'slides': [
          {
            'slideNumber': 1,
            'headline': 'Mystery',
            'body': 'Where did they go?',
            'imagePrompt': 'child looking',
          },
        ],
        'caption': 'Caption text',
        'hashtags': ['#parenting'],
      });

      final mockProvider = MockAIProvider(cannedJson: json);
      final svc = AiContentServiceImpl(mockProvider);

      final pkg = await svc.generate(GenerationRequest(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        gateReport: gateReport,
        audience: 'Parents of 1-4 year olds',
      ));

      // Classification survives
      expect(pkg.classification.pillar, ContentPillar.play);
      expect(pkg.classification.narrativeFormatName, 'problemFix');
      expect(pkg.classification.contentType, ContentType.reel);
      expect(pkg.classification.goal, ContentGoal.reach);

      // Gate report is attached
      expect(pkg.gateReport, isNotNull);
      expect(pkg.gateReport!.ideaId, 'day9-sock-hunt');

      // Voice mode is inherited
      expect(pkg.voiceMode, VoiceMode.required);

      // Package is ready for production
      expect(pkg.canGenerate, isTrue);
      expect(pkg.isBlockedByGate, isFalse);
    });

    test('ProductionInput can consume a fully generated package', () async {
      final json = jsonEncode({
        'topic': 'sock-hunt',
        'hook': 'Where did the socks go?',
        'script': 'Where did the socks go? Check under the bed.',
        'slides': [
          {
            'slideNumber': 1,
            'headline': 'The Mystery',
            'body': 'Where did the socks go?',
            'imagePrompt': 'child looking under bed',
          },
        ],
        'caption': 'Check under the bed',
        'hashtags': ['#parenting'],
      });

      final mockProvider = MockAIProvider(cannedJson: json);
      final svc = AiContentServiceImpl(mockProvider);

      final pkg = await svc.generate(GenerationRequest(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        gateReport: gateReport,
      ));

      // Package can be consumed by ProductionAdapter
      final input = ProductionInput(
        package: pkg,
        voiceMode: ProductionVoiceMode.gemini,
        imagePaths: ['/fake/path/image1.png'],
      );

      expect(input.package.id, pkg.id);
      expect(input.package.ideaId, 'day9-sock-hunt');
      expect(input.package.narration, isNotEmpty);
      expect(input.package.hook, 'Where did the socks go?');
    });

    test('needsFilming package produces needsFilming from adapter', () async {
      final filmingReport = QualityGate.evaluateIdea(
        ideaId: 'video-story',
        title: 'Video Story',
        classification: ClassificationSnapshot(
          narrativeFormatName: 'problemFix',
          contentType: ContentType.imageSlideshowReel,
          productionMethod: ProductionMethod.realLifeVideo,
          pillar: ContentPillar.play,
          axisStates: {
            'narrativeFormat': AxisResolution.approved,
            'contentType': AxisResolution.approved,
            'productionMethod': AxisResolution.approved,
            'pillar': AxisResolution.approved,
            'series': AxisResolution.approved,
            'goal': AxisResolution.approved,
          },
        ),
        testCount: 5,
      );

      // Package with needsFilming compatibility
      final pkg = ContentPackageV2(
        id: 'pkg-film',
        ideaId: 'video-story',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        classification: ClassificationSnapshotV2(
          status: IdeaStatus.approved,
          axisStates: {},
          capturedAt: DateTime.now(),
        ),
        audience: '',
        problem: '',
        lesson: '',
        hook: 'A video story',
        voiceMode: VoiceMode.required,
        cta: '',
        reachCandidacy: ReachCandidacy.yes,
        productionCompatibility: ProductionCompatibility.needsFilming,
        title: 'Video Story',
        script: 'Script here',
        narration: 'Narration here',
        dialogue: '',
        caption: '',
        hashtags: [],
        scenes: [],
        productionMethod: ProductionMethod.realLifeVideo,
        shotList: [],
        imagePrompts: [],
        gateReport: filmingReport,
      );

      final input = ProductionInput(
        package: pkg,
        imagePaths: ['/fake/image.png'],
      );

      // The adapter should return needsFilming without attempting production
      // (We can't test the actual adapter since it needs Flutter/FFmpeg,
      // but we verify the package's compatibility flag is correct)
      expect(pkg.needsFilming, isTrue);
      expect(pkg.isBlockedByGate, isFalse);
      expect(pkg.isReadyToGenerate, isTrue);
    });

    test('blocked package cannot be generated', () {
      final blockedReport = QualityGate.evaluateIdea(
        ideaId: 'bad',
        title: 'Bad',
        classification: ClassificationSnapshot(
          narrativeFormatName: 'invalidFormat',
          axisStates: {
            'narrativeFormat': AxisResolution.invalid,
          },
        ),
      );

      expect(
        () => AiContentServiceImpl(MockAIProvider()).generate(
          GenerationRequest(
            ideaId: 'bad',
            title: 'Bad',
            gateReport: blockedReport,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
