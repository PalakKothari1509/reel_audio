import 'package:shared_preferences/shared_preferences.dart';

import 'secrets.dart';

/// Centralizes API key resolution with a Settings-priority fallback chain.
///
/// Resolution order:
/// 1. User key stored in Settings (SharedPreferences)
/// 2. Default key from lib/secrets.dart
///
/// This ensures the Settings-screen key override is honored by every
/// call site, not just the 2 that currently read SharedPreferences directly.
class ApiKeyStore {
  /// Preference key used by settings_screen.dart and caption_generator.dart.
  static const geminiApiKeyPref = 'gemini_api_key';

  final String _defaultGeminiKey = geminiApiKey;
  final String _defaultElevenLabsKey = elevenLabsApiKey;
  final String _defaultElevenVoiceId = elevenVoiceId;

  final String Function() _readSettingsGeminiKey;

  /// Creates a store with a custom Settings key reader.
  ///
  /// For testing: pass a closure returning a fixed string.
  /// For production: use [ApiKeyStore.fromSharedPreferences].
  ApiKeyStore({String Function()? readSettingsGeminiKey})
      : _readSettingsGeminiKey = readSettingsGeminiKey ??
            (() => '');

  /// Creates a store backed by real SharedPreferences.
  /// Keys are read live from disk on every call, so a change in Settings
  /// is picked up without re-instantiating.
  static Future<ApiKeyStore> fromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return ApiKeyStore(
      readSettingsGeminiKey: () => prefs.getString(geminiApiKeyPref)?.trim() ?? '',
    );
  }

  /// The Gemini API key: Settings override if present, else default.
  String getGeminiApiKey() {
    final settingsKey = _readSettingsGeminiKey().trim();
    if (settingsKey.isNotEmpty) return settingsKey;
    return _defaultGeminiKey;
  }

  /// The ElevenLabs API key.
  ///
  /// There is no Settings-screen override for ElevenLabs yet, so this
  /// always returns the default key.
  String getElevenLabsApiKey() => _defaultElevenLabsKey;

  /// The ElevenLabs voice ID ("Aria" multilingual — not a secret).
  String getElevenVoiceId() => _defaultElevenVoiceId;

  /// Whether the user has configured a custom Gemini key in Settings.
  bool hasCustomGeminiKey() {
    final settingsKey = _readSettingsGeminiKey().trim();
    return settingsKey.isNotEmpty;
  }
}
