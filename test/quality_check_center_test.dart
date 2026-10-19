import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/quality_check_center.dart';
import 'package:reel_audio/video_library.dart';

void main() {
  group('QualityReport2', () {
    test('canApprove is false when critical issues exist', () {
      final report = QualityReport2(
        id: 'r1',
        contentId: 'FLWP-0001',
        assetId: 'FLWP-0001',
        assetType: QualityCheckType.script,
        assetVersion: 1,
        findings: [
          QualityFinding(
            id: 'f1',
            checkId: 'test',
            checkName: 'Test',
            severity: FindingSeverity.critical,
            passed: false,
            message: 'Failed',
          ),
        ],
      );
      expect(report.canApprove, isFalse);
      expect(report.hasCriticalIssues, isTrue);
      expect(report.overallStatus, 'FAIL');
    });

    test('canApprove is false when major issues exist', () {
      final report = QualityReport2(
        id: 'r2',
        contentId: 'FLWP-0001',
        assetId: 'FLWP-0001',
        assetType: QualityCheckType.script,
        assetVersion: 1,
        findings: [
          QualityFinding(
            id: 'f1',
            checkId: 'test',
            checkName: 'Test',
            severity: FindingSeverity.major,
            passed: false,
            message: 'Failed',
          ),
        ],
      );
      expect(report.canApprove, isFalse);
      expect(report.hasMajorIssues, isTrue);
      expect(report.overallStatus, 'NEEDS REVISION');
    });

    test('canApprove is true when only suggestions exist', () {
      final report = QualityReport2(
        id: 'r3',
        contentId: 'FLWP-0001',
        assetId: 'FLWP-0001',
        assetType: QualityCheckType.script,
        assetVersion: 1,
        findings: [
          QualityFinding(
            id: 'f1',
            checkId: 'test',
            checkName: 'Test',
            severity: FindingSeverity.suggestion,
            passed: false,
            message: 'Suggestion',
          ),
          QualityFinding(
            id: 'f2',
            checkId: 'test2',
            checkName: 'Test2',
            severity: FindingSeverity.minor,
            passed: true,
            message: 'Passed',
          ),
        ],
      );
      expect(report.canApprove, isTrue);
      expect(report.overallStatus, 'PASS WITH NOTES');
    });

    test('toJson and fromJson round-trip', () {
      final report = QualityReport2(
        id: 'r4',
        contentId: 'FLWP-0001',
        assetId: 'FLWP-0001',
        assetType: QualityCheckType.video,
        assetVersion: 2,
        findings: [
          QualityFinding(
            id: 'f1',
            checkId: 'dur',
            checkName: 'Duration',
            severity: FindingSeverity.minor,
            passed: true,
            message: 'Good',
          ),
        ],
        manualNotes: 'Looks great',
        requiresHumanReview: false,
      );

      final json = report.toJson();
      final restored = QualityReport2.fromJson(json);

      expect(restored.id, 'r4');
      expect(restored.contentId, 'FLWP-0001');
      expect(restored.assetId, 'FLWP-0001');
      expect(restored.assetType, QualityCheckType.video);
      expect(restored.findings.length, 1);
      expect(restored.findings.first.message, 'Good');
      expect(restored.manualNotes, 'Looks great');
    });
  });

  group('FindingSeverity', () {
    test('names round-trip', () {
      expect(FindingSeverity.critical.name, 'critical');
      expect(FindingSeverity.major.name, 'major');
      expect(FindingSeverityExtension.fromName('critical'), FindingSeverity.critical);
      expect(FindingSeverityExtension.fromName('major'), FindingSeverity.major);
    });
  });

  group('QualityCheckType', () {
    test('names round-trip', () {
      expect(QualityCheckType.script.name, 'script');
      expect(QualityCheckType.video.name, 'video');
      expect(QualityCheckTypeExtension.fromName('video'), QualityCheckType.video);
    });
  });

  group('QualityCheckCenter.checkScript', () {
    test('detects missing resolution as major issue', () {
      final report = QualityCheckCenter.checkScript(
        contentId: 'FLWP-0001',
        version: 1,
        title: 'Test',
        scriptText: 'Ria plays with toys. No resolution here.',
      );

      final resFinding = report.findings.firstWhere((f) => f.checkId == 'clear_resolution');
      expect(resFinding.passed, isFalse);
      expect(resFinding.severity, FindingSeverity.major);
    });

    test('detects scary content as critical', () {
      final report = QualityCheckCenter.checkScript(
        contentId: 'FLWP-0001',
        version: 1,
        title: 'Test',
        scriptText: 'There was a scary monster and Ria had a nightmare.',
      );

      final ageFinding = report.findings.firstWhere((f) => f.checkId == 'age_appropriateness');
      expect(ageFinding.passed, isFalse);
      expect(ageFinding.severity, FindingSeverity.critical);
    });

    test('passes on a good script', () {
      final report = QualityCheckCenter.checkScript(
        contentId: 'FLWP-0001',
        version: 1,
        title: 'Test',
        scriptText: 'Ria wants to put on shoes. She says "Mumma!" Story: Ria tries. Twist: Shoe is backwards. Resolution: They fix it together. Moral: Patience.',
      );

      expect(report.canApprove, isTrue);
    });
  });

  group('QualityCheckCenter.checkPrompt', () {
    test('detects missing characters as critical', () {
      final report = QualityCheckCenter.checkPrompt(
        contentId: 'FLWP-0001',
        assetId: 'FLWP-0001_v1',
        version: 1,
        promptText: 'A scene with someone unnamed. 10 seconds, 9:16.',
        expectedCharacters: ['Ria'],
      );

      final charFinding = report.findings.firstWhere((f) => f.checkId == 'characters_present');
      expect(charFinding.passed, isFalse);
      expect(charFinding.severity, FindingSeverity.critical);
    });

    test('detects missing duration as major', () {
      final report = QualityCheckCenter.checkPrompt(
        contentId: 'FLWP-0001',
        assetId: 'FLWP-0001_v1',
        version: 1,
        promptText: 'Scene with Ria. 9:16 vertical. No duplicates.',
        expectedCharacters: [],
      );

      final durFinding = report.findings.firstWhere((f) => f.checkId == 'duration_specified');
      expect(durFinding.passed, isFalse);
      expect(durFinding.severity, FindingSeverity.major);
    });
  });
}
