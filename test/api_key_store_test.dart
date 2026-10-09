import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/api_key_store.dart';
import 'package:reel_audio/secrets.dart' as secrets;

void main() {
  group('ApiKeyStore', () {
    test('getGeminiApiKey falls back to default when no Settings key', () {
      final store = ApiKeyStore();
      expect(store.getGeminiApiKey(), secrets.geminiApiKey);
    });

    test('getGeminiApiKey returns Settings key when configured', () {
      final store = ApiKeyStore(
        readSettingsGeminiKey: () => 'custom-key-from-settings',
      );
      expect(store.getGeminiApiKey(), 'custom-key-from-settings');
    });

    test('getGeminiApiKey ignores whitespace-only Settings key', () {
      final store = ApiKeyStore(
        readSettingsGeminiKey: () => '   ',
      );
      expect(store.getGeminiApiKey(), secrets.geminiApiKey);
    });

    test('getGeminiApiKey trims Settings key', () {
      final store = ApiKeyStore(
        readSettingsGeminiKey: () => '  custom-key  ',
      );
      expect(store.getGeminiApiKey(), 'custom-key');
    });

    test('hasCustomGeminiKey is false when no key', () {
      final store = ApiKeyStore();
      expect(store.hasCustomGeminiKey(), isFalse);
    });

    test('hasCustomGeminiKey is true when key is set', () {
      final store = ApiKeyStore(
        readSettingsGeminiKey: () => 'my-key',
      );
      expect(store.hasCustomGeminiKey(), isTrue);
    });

    test('hasCustomGeminiKey is false for whitespace-only key', () {
      final store = ApiKeyStore(
        readSettingsGeminiKey: () => '  ',
      );
      expect(store.hasCustomGeminiKey(), isFalse);
    });

    test('getElevenLabsApiKey returns default', () {
      final store = ApiKeyStore();
      expect(store.getElevenLabsApiKey(), secrets.elevenLabsApiKey);
    });

    test('getElevenVoiceId returns default', () {
      final store = ApiKeyStore();
      expect(store.getElevenVoiceId(), secrets.elevenVoiceId);
    });
  });
}
