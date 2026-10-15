import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reel_audio/api_key_store.dart';
import 'package:reel_audio/secrets.dart' as secrets;

void main() {
  group('ApiKeyStore', () {
    test('getGeminiApiKey returns key from secrets by default', () {
      final store = ApiKeyStore();
      expect(store.getGeminiApiKey(), secrets.geminiApiKey);
    });

    test('hasCustomGeminiKey is false when no custom key is saved', () {
      final store = ApiKeyStore();
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

    group('fromSharedPreferences with custom key', () {
      test('returns custom key when saved', () async {
        SharedPreferences.setMockInitialValues({
          'custom_gemini_api_key': 'my-custom-paid-key',
        });
        final store = await ApiKeyStore.fromSharedPreferences();
        expect(store.getGeminiApiKey(), 'my-custom-paid-key');
        expect(store.hasCustomGeminiKey(), isTrue);
      });

      test('falls back to default when no custom key saved', () async {
        SharedPreferences.setMockInitialValues({});
        final store = await ApiKeyStore.fromSharedPreferences();
        expect(store.getGeminiApiKey(), secrets.geminiApiKey);
        expect(store.hasCustomGeminiKey(), isFalse);
      });

      test('falls back to default when custom key is empty', () async {
        SharedPreferences.setMockInitialValues({
          'custom_gemini_api_key': '   ',
        });
        final store = await ApiKeyStore.fromSharedPreferences();
        expect(store.getGeminiApiKey(), secrets.geminiApiKey);
        expect(store.hasCustomGeminiKey(), isFalse);
      });
    });

    group('setGeminiApiKey', () {
      test('persists and returns the custom key', () async {
        SharedPreferences.setMockInitialValues({});
        final store = await ApiKeyStore.fromSharedPreferences();
        await store.setGeminiApiKey('new-key-from-user');
        expect(store.getGeminiApiKey(), 'new-key-from-user');
        expect(store.hasCustomGeminiKey(), isTrue);
      });

      test('clears the key when set to null or empty', () async {
        SharedPreferences.setMockInitialValues({'custom_gemini_api_key': 'old-key'});
        final store = await ApiKeyStore.fromSharedPreferences();
        expect(store.getGeminiApiKey(), 'old-key');
        await store.setGeminiApiKey('');
        expect(store.hasCustomGeminiKey(), isFalse);
        expect(store.getGeminiApiKey(), secrets.geminiApiKey);
      });
    });

    group('setElevenLabsApiKey', () {
      test('persists and returns the custom key', () async {
        SharedPreferences.setMockInitialValues({});
        final store = await ApiKeyStore.fromSharedPreferences();
        await store.setElevenLabsApiKey('my-elevenlabs-key');
        expect(store.getElevenLabsApiKey(), 'my-elevenlabs-key');
        expect(store.hasCustomElevenLabsKey(), isTrue);
      });
    });
  });
}
