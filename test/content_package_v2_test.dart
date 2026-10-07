import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_quality_gate.dart';

void main() {
  group('ClassificationSnapshot', () {
    test('isFullyApproved returns true for fully approved snapshot', () {
      final snapshot = ClassificationSnapshot(
        axisStates: {
          'pillar': AxisResolution.approved,
          'series': AxisResolution.approved,
          'narrativeFormat': AxisResolution.approved,
          'contentType': AxisResolution.approved,
          'productionMethod': AxisResolution.approved,
          'goal': AxisResolution.approved,
        },
        shareTrigger: ShareTrigger.filled(
          sender: 'test',
          recipient: 'test',
          situation: 'test',
          reason: 'test',
        ),
        openLoop: OpenLoop.filled(
          withheld: 'test',
          promise: 'test',
          mechanic: 'test',
          payoff: 'test',
          formatName: 'ministory',
        ),
      );
      expect(snapshot.isFullyApproved, isTrue);
    });
  });
}