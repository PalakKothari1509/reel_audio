import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_axes.dart';

void main() {
  group('content axis parsing', () {
    test('accepts canonical labels and slugged variants across legacy data', () {
      expect(ContentSeries.byLabel('Jugaadu Mummy'), ContentSeries.jugaaduMummy);
      expect(ContentSeries.byLabel('jugaadu_mummy'), ContentSeries.jugaaduMummy);
      expect(
        ContentSeries.byLabel('Life With Ria & Rio'),
        ContentSeries.lifeWithRiaRio,
      );
      expect(
        ContentSeries.byLabel('life-with-ria-rio'),
        ContentSeries.lifeWithRiaRio,
      );
      expect(
        ContentSeries.fromLegacy('ria_adventures'),
        ContentSeries.lifeWithRiaRio,
      );
      expect(ContentPillar.byLabel('DO'), ContentPillar.doIt);
      expect(ContentPillar.byLabel('do'), ContentPillar.doIt);
      expect(
        ContentPillar.fromLegacy('learning-through-play'),
        ContentPillar.play,
      );
    });

    test('normalizes punctuation-only variants from stored values', () {
      expect(ContentType.byLabel('image reel'), ContentType.imageSlideshowReel);
      expect(
        ContentGoal.byLabel('Non-follower Reach'),
        ContentGoal.nonFollowerReach,
      );
      expect(
        ProductionMethod.byLabel('Real-life video'),
        ProductionMethod.realLifeVideo,
      );
      expect(IdeaStatus.byId('imagesReady'), IdeaStatus.imagesReady);
      expect(IdeaStatus.byId('images_ready'), IdeaStatus.imagesReady);
    });
  });
}
