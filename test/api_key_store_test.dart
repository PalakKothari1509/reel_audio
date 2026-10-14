import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/api_key_store.dart';
import 'package:reel_audio/secrets.dart' as secrets;

void main() {
  group('ApiKeyStore', () {
    test('getGeminiApiKey returns key from secrets', () {
      final store = ApiKeyStore();
      expect(store.getGeminiApiKey(), secrets.geminiApiKey);
    });

    test('hasCustomGeminiKey is always false', () {
      expect(ApiKeyStore().hasCustomGeminiKey(), isFalse);
    });

    test('getElevenLabsApiKey returns default', () {
      expect(ApiKeyStore().getElevenLabsApiKey(), secrets.elevenLabsApiKey);
    });

    test('getElevenVoiceId returns default', () {
      expect(ApiKeyStore().getElevenVoiceId(), secrets.elevenVoiceId);
    });
  });
}
