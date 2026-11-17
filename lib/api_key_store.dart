import 'package:shared_preferences/shared_preferences.dart';

import 'secrets.dart';

/// Centralizes API key resolution.
///
/// Keys are read from lib/secrets.dart (git-ignored defaults). A user can
/// override either key from the Settings screen, which is stored in
/// SharedPreferences and takes priority over the default. This matters for
/// Gemini: the shared free-tier key has a 20-request/day limit, and a user
/// with their own paid Google Cloud key gets a much higher quota.
class ApiKeyStore {
  static const String _geminiKeyPref = 'custom_gemini_api_key';
  static const String _elevenLabsKeyPref = 'custom_elevenlabs_api_key';

  /// Sentinel value used in secrets.example.dart to detect unconfigured keys.
  static const String _placeholderPrefix = 'YOUR_';
  static const String _placeholderSuffix = '_HERE';

  SharedPreferences? _prefs;

  ApiKeyStore();

  static Future<ApiKeyStore> fromSharedPreferences() async {
    final store = ApiKeyStore();
    store._prefs = await SharedPreferences.getInstance();
    return store;
  }

  String getGeminiApiKey() {
    final saved = _prefs?.getString(_geminiKeyPref);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    final key = geminiApiKey;
    _validateNotPlaceholder(key, 'Gemini');
    return key;
  }

  String getElevenLabsApiKey() {
    final saved = _prefs?.getString(_elevenLabsKeyPref);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    final key = elevenLabsApiKey;
    _validateNotPlaceholder(key, 'ElevenLabs');
    return key;
  }

  void _validateNotPlaceholder(String key, String serviceName) {
    if (key.startsWith(_placeholderPrefix) && key.endsWith(_placeholderSuffix)) {
      throw Exception(
        '$serviceName API key not configured. '
        'Copy lib/secrets.example.dart to lib/secrets.dart and add your key. '
        'Or set a custom key in the Settings screen.',
      );
    }
  }

  String getElevenVoiceId() => elevenVoiceId;

  bool hasCustomGeminiKey() {
    final saved = _prefs?.getString(_geminiKeyPref);
    return saved != null && saved.trim().isNotEmpty;
  }

  bool hasCustomElevenLabsKey() {
    final saved = _prefs?.getString(_elevenLabsKeyPref);
    return saved != null && saved.trim().isNotEmpty;
  }

  Future<void> setGeminiApiKey(String? key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final trimmed = key?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_geminiKeyPref);
    } else {
      await prefs.setString(_geminiKeyPref, trimmed);
    }
  }

  Future<void> setElevenLabsApiKey(String? key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final trimmed = key?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_elevenLabsKeyPref);
    } else {
      await prefs.setString(_elevenLabsKeyPref, trimmed);
    }
  }
}
