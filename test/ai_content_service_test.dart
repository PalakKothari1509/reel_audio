import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/ai_content_service.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_package_v2.dart';
import 'package:reel_audio/content_quality_gate.dart';

/// A testable AiContentService that returns canned GeneratedContent
/// without needing a real AIProvider or Flutter.
class TestableAiContentService extends AiContentServiceImplBase {
  final GeneratedContent? cannedContent;
  final AiContentFailure? failure;
  bool wasCalled = false;
  GenerationRequest? capturedRequest;

  TestableAiContentService({this.cannedContent, this.failure});

  @override
  String get providerName => 'Testable';

  @override
  bool get isAvailable => failure == null;

  @override
  Future<GeneratedContent> generateContent(GenerationRequest request) async {
    wasCalled = true;
    capturedRequest = request;
    if (failure != null) throw failure!;
    if (cannedContent == null) {
      throw AiContentFailure('No content configured');
    }
    return cannedContent!;
  }
}

void main() {
  group('AiContentService', () {
    ClassificationSnapshot fullyApproved() {
      return ClassificationSnapshot(
        pillar: ContentPillar.play,
        narrativeFormatName: 'problemFix',
        contentType: ContentType.reel,
        productionMethod: ProductionMethod.characterImages,
        goal: ContentGoal.reach,
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
    }

    GateReport passingReport() {
      return QualityGate.evaluateIdea(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        classification: fullyApproved(),
        voiceMode: VoiceMode.required,
        testCount: 5,
      );
    }

    GeneratedContent sampleContent() {
      return GeneratedContent(
        title: 'The Sock Hunt',
        hook: 'Where are your socks?',
        script: 'Narration: Where are your socks?\nDialogue: Cuty: I hid them!',
        narration: 'Where are your socks?',
        dialogue: 'Cuty: I hid them!',
        caption: 'Caption text here',
        cta: 'Save this for later',
        hashtags: ['#parenting', '#toddlers'],
        scenes: [
          Scene(
            index: 0,
            title: 'The Mystery',
            description: 'Socks are missing',
            visualPrompt: 'A child looking under furniture',
            narration: 'Where are your socks?',
            dialogue: 'Cuty: I hid them!',
          ),
        ],
        imagePrompts: ['A child looking under furniture'],
        shotList: [
          ShotListItem(
            shotNumber: 0,
            title: 'The Mystery',
            visualDescription: 'A child looking under furniture',
            cameraMove: '',
            lighting: '',
            durationSeconds: 3,
            characters: [],
          ),
        ],
      );
    }

    test('generate on a PASS idea returns a ready ContentPackageV2', () async {
      final svc = TestableAiContentService(cannedContent: sampleContent());
      final report = passingReport();

      final pkg = await svc.generate(GenerationRequest(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        gateReport: report,
      ));

      expect(pkg.ideaId, 'day9-sock-hunt');
      expect(pkg.isReadyToGenerate, isTrue);
      expect(pkg.canGenerate, isTrue);
      expect(pkg.narration, 'Where are your socks?');
      expect(pkg.dialogue, 'Cuty: I hid them!');
      expect(pkg.hasVoiceContent, isTrue);
    });

    test('generate on a BLOCKED idea throws StateError', () async {
      final svc = TestableAiContentService(cannedContent: sampleContent());

      final blockedReport = QualityGate.evaluateIdea(
        ideaId: 'bad-format',
        title: 'Bad',
        classification: ClassificationSnapshot(
          narrativeFormatName: 'notARealFormat',
          axisStates: {
            'narrativeFormat': AxisResolution.invalid,
          },
        ),
      );

      expect(
        () => svc.generate(GenerationRequest(
          ideaId: 'bad-format',
          title: 'Bad',
          gateReport: blockedReport,
        )),
        throwsA(isA<StateError>()),
      );
    });

    test('generate on an UNKNOWN idea throws StateError', () async {
      final svc = TestableAiContentService(cannedContent: sampleContent());

      final unknownReport = QualityGate.evaluateIdea(
        ideaId: 'open-idea',
        title: 'Open',
        classification: ClassificationSnapshot(
          axisStates: {
            'narrativeFormat': null,
          },
        ),
      );

      expect(
        () => svc.generate(GenerationRequest(
          ideaId: 'open-idea',
          title: 'Open',
          gateReport: unknownReport,
        )),
        throwsA(isA<StateError>()),
      );
    });

    test('generate on a needsFilming idea returns package with needsFilming',
        () async {
      final svc = TestableAiContentService(cannedContent: sampleContent());

      final filmingReport = QualityGate.evaluateIdea(
        ideaId: 'film-this',
        title: 'Film This',
        classification: ClassificationSnapshot(
          narrativeFormatName: 'problemFix',
          contentType: ContentType.imageSlideshowReel,
          productionMethod: ProductionMethod.realLifeVideo,
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

      final pkg = await svc.generate(GenerationRequest(
        ideaId: 'film-this',
        title: 'Film This',
        gateReport: filmingReport,
      ));

      expect(pkg.needsFilming, isTrue);
      expect(pkg.isBlockedByGate, isFalse);
    });

    test('AI failure is wrapped as AiContentFailure', () async {
      final svc = TestableAiContentService(
        cannedContent: sampleContent(),
        failure: AiContentFailure('Gemini is rate-limited'),
      );
      final report = passingReport();

      expect(
        () => svc.generate(GenerationRequest(
          ideaId: 'day9-sock-hunt',
          title: 'The Sock Hunt',
          gateReport: report,
        )),
        throwsA(isA<AiContentFailure>()),
      );
    });

    test('package carries classification snapshot from gateReport', () async {
      final svc = TestableAiContentService(cannedContent: sampleContent());
      final report = passingReport();

      final pkg = await svc.generate(GenerationRequest(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        gateReport: report,
      ));

      expect(pkg.classification.pillar, isNotNull);
      expect(pkg.classification.narrativeFormatName, 'problemFix');
      expect(pkg.classification.contentType, ContentType.reel);
    });

    test('captures request for verification', () async {
      final svc = TestableAiContentService(cannedContent: sampleContent());
      final report = passingReport();

      await svc.generate(GenerationRequest(
        ideaId: 'test-id',
        title: 'Test Title',
        gateReport: report,
      ));

      expect(svc.capturedRequest!.ideaId, 'test-id');
      expect(svc.capturedRequest!.title, 'Test Title');
    });

    test('generated package round-trips through JSON', () async {
      final svc = TestableAiContentService(cannedContent: sampleContent());
      final report = passingReport();

      final pkg = await svc.generate(GenerationRequest(
        ideaId: 'day9-sock-hunt',
        title: 'The Sock Hunt',
        gateReport: report,
        audience: 'Parents of 1-4',
        hook: 'Where are your socks?',
      ));

      final json = pkg.toJson();
      final restored = ContentPackageV2.fromJson(json);

      expect(restored.ideaId, 'day9-sock-hunt');
      expect(restored.narration, 'Where are your socks?');
      expect(restored.dialogue, 'Cuty: I hid them!');
      expect(restored.gateReport, isNotNull);
      expect(restored.isReadyToGenerate, isTrue);
    });
  });

  group('AiContentFailure', () {
    test('stringifies with message', () {
      final failure = AiContentFailure('Gemini is down');
      expect(failure.toString(), contains('Gemini is down'));
    });

    test('implements Exception', () {
      final failure = AiContentFailure('Test');
      expect(failure, isA<Exception>());
    });
  });

  group('GeneratedContent', () {
    test('hasVoiceContent is true when narration present', () {
      final content = GeneratedContent(
        title: 'T', hook: 'H', script: 'S', narration: 'N', dialogue: '',
        caption: 'C', cta: 'CTA', hashtags: [], scenes: [],
        imagePrompts: [], shotList: [],
      );
      expect(content.hasVoiceContent, isTrue);
    });

    test('hasVoiceContent is true when dialogue present', () {
      final content = GeneratedContent(
        title: 'T', hook: 'H', script: 'S', narration: '', dialogue: 'D',
        caption: 'C', cta: 'CTA', hashtags: [], scenes: [],
        imagePrompts: [], shotList: [],
      );
      expect(content.hasVoiceContent, isTrue);
    });

    test('hasVoiceContent is false when both empty', () {
      final content = GeneratedContent(
        title: 'T', hook: 'H', script: 'S', narration: '', dialogue: '',
        caption: 'C', cta: 'CTA', hashtags: [], scenes: [],
        imagePrompts: [], shotList: [],
      );
      expect(content.hasVoiceContent, isFalse);
    });
  });
}
