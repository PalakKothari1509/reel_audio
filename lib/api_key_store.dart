import 'secrets.dart';

/// Centralizes API key resolution.
/// Keys are read from lib/secrets.dart (git-ignored).
class ApiKeyStore {
  final String _defaultGeminiKey = geminiApiKey;
  final String _defaultElevenLabsKey = elevenLabsApiKey;
  final String _defaultElevenVoiceId = elevenVoiceId;

  ApiKeyStore();

  static Future<ApiKeyStore> fromSharedPreferences() async => ApiKeyStore();

  String getGeminiApiKey() => _defaultGeminiKey;
  String getElevenLabsApiKey() => _defaultElevenLabsKey;
  String getElevenVoiceId() => _defaultElevenVoiceId;
  bool hasCustomGeminiKey() => false;
}
