import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_provider.dart';
import 'gemini_client.dart';
import 'brand_system.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  final AIProvider? initialProvider;
  final ValueChanged<AIProvider?>? onProviderChanged;

  const SettingsScreen({
    super.key,
    this.initialProvider,
    this.onProviderChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  AIProvider? _currentProvider;
  bool _testing = false;
  String? _testResult;
  bool _loaded = false;

  // Default settings
  ContentBucket? _defaultBucket;
  ContentFormat? _defaultFormat;
  bool _autoSaveHistory = true;
  bool _includeBrandInPrompts = true;
  int _defaultSlideCount = 7;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    _apiKeyController.text = apiKey;
    
    if (apiKey.isNotEmpty) {
      _currentProvider = GeminiClient(apiKey: apiKey);
    } else if (widget.initialProvider != null) {
      _currentProvider = widget.initialProvider;
    }

    _defaultBucket = BucketLibrary.all
        .firstWhere(
          (b) => b.id == (prefs.getString('default_bucket') ?? ''),
          orElse: () => BucketLibrary.challenge,
        );
    if ((prefs.getString('default_bucket') ?? '').isEmpty) _defaultBucket = null;
    
    _defaultFormat = ContentFormat.values
        .firstWhere(
          (f) => f.name == (prefs.getString('default_format') ?? ''),
          orElse: () => ContentFormat.carousel,
        );
    if ((prefs.getString('default_format') ?? '').isEmpty) _defaultFormat = null;
    _autoSaveHistory = prefs.getBool('auto_save_history') ?? true;
    _includeBrandInPrompts = prefs.getBool('include_brand_in_prompts') ?? true;
    _defaultSlideCount = prefs.getInt('default_slide_count') ?? 7;

    setState(() {
      _loaded = true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    if (_defaultBucket != null) await prefs.setString('default_bucket', _defaultBucket!.id);
    if (_defaultFormat != null) await prefs.setString('default_format', _defaultFormat!.name);
    await prefs.setBool('auto_save_history', _autoSaveHistory);
    await prefs.setBool('include_brand_in_prompts', _includeBrandInPrompts);
    await prefs.setInt('default_slide_count', _defaultSlideCount);

    if (_apiKeyController.text.trim().isNotEmpty) {
      _currentProvider = GeminiClient(apiKey: _apiKeyController.text.trim());
    } else {
      _currentProvider = null;
    }

    widget.onProviderChanged?.call(_currentProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _testConnection() async {
    if (_currentProvider == null || _currentProvider is! GeminiClient) {
      setState(() => _testResult = 'No API key configured');
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      await _currentProvider!.testConnection();
      setState(() => _testResult = '✅ Connection successful!');
    } catch (e) {
      setState(() => _testResult = '❌ Failed: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('🤖 AI Provider (Gemini)'),
              Gap.s,
              _aiProviderCard(),
              Gap.l,
              _sectionTitle('🎯 Default Content Settings'),
              Gap.s,
              _defaultsCard(),
              Gap.l,
              _sectionTitle('⚙️ App Behavior'),
              Gap.s,
              _behaviorCard(),
              Gap.l,
              _sectionTitle('📊 Data & Storage'),
              Gap.s,
              _dataCard(),
              Gap.l,
              _sectionTitle('ℹ️ About'),
              Gap.s,
              _aboutCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: AppText.section);

  Widget _aiProviderCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gemini API Key', style: AppText.subtitle),
              Gap.s,
              Text(
                'Enter your Google AI Studio API key to enable AI-powered content generation. '
                'Get a free key at https://aistudio.google.com/apikey',
                style: AppText.hint,
              ),
              Gap.m,
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'AIzaSy...',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: _currentProvider?.isAvailable == true
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                obscureText: true,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && !v.trim().startsWith('AIza')) {
                    return 'Gemini API keys typically start with "AIza"';
                  }
                  return null;
                },
              ),
              Gap.m,
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _testing ? null : _testConnection,
                      icon: _testing 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.wifi_find),
                      label: Text(_testing ? 'Testing...' : 'Test Connection'),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(width: 12),
                    Expanded(child: Text(_testResult!, style: AppText.body)),
                  ],
                ],
              ),
              if (_testResult?.contains('successful') == true) ...[
                Gap.m,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI generation enabled! Quick Content Studio will now use Gemini for new content.',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_currentProvider?.isAvailable != true && _apiKeyController.text.trim().isEmpty) ...[
                Gap.m,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No API key set. Content generation will use local templates only.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _defaultsCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<ContentBucket>(
                value: _defaultBucket,
                hint: const Text('Default Content Bucket'),
                decoration: const InputDecoration(
                  labelText: 'Default Bucket',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<ContentBucket>(value: null, child: Text('None (ask each time)')),
                  ...BucketLibrary.all.map((b) => DropdownMenuItem(
                    value: b,
                    child: Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(color: b.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('${b.emoji} ${b.name}'),
                      ],
                    ),
                  )),
                ],
                onChanged: (v) => setState(() => _defaultBucket = v),
              ),
              Gap.m,
              DropdownButtonFormField<ContentFormat>(
                value: _defaultFormat,
                hint: const Text('Default Format'),
                decoration: const InputDecoration(
                  labelText: 'Default Format',
                  prefixIcon: Icon(Icons.format_list_bulleted_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<ContentFormat>(value: null, child: Text('None (ask each time)')),
                  ...ContentFormat.values.map((f) => DropdownMenuItem(
                    value: f,
                    child: Row(
                      children: [
                        Text('${f.emoji} '),
                        Text(f.label),
                      ],
                    ),
                  )),
                ],
                onChanged: (v) => setState(() => _defaultFormat = v),
              ),
              Gap.m,
              Row(
                children: [
                  const Text('Default Slide Count: '),
                  Expanded(
                    child: Slider(
                      value: _defaultSlideCount.toDouble(),
                      min: 5,
                      max: 10,
                      divisions: 5,
                      label: '$_defaultSlideCount slides',
                      onChanged: (v) => setState(() => _defaultSlideCount = v.round()),
                    ),
                  ),
                  Text('$_defaultSlideCount', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _behaviorCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Auto-save to History'),
                subtitle: const Text('Automatically save generated packs to post history'),
                value: _autoSaveHistory,
                onChanged: (v) => setState(() => _autoSaveHistory = v),
                secondary: const Icon(Icons.history_outlined),
              ),
              SwitchListTile(
                title: const Text('Include Brand in AI Prompts'),
                subtitle: const Text('Automatically inject brand context (characters, style, buckets) into AI prompts'),
                value: _includeBrandInPrompts,
                onChanged: (v) => setState(() => _includeBrandInPrompts = v),
                secondary: const Icon(Icons.auto_awesome_outlined),
              ),
            ],
          ),
        ),
      );

  Widget _dataCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export All Data'),
                subtitle: const Text('Export ideas, history, comments, and settings as JSON'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportData,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Import Data'),
                subtitle: const Text('Import previously exported JSON data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _importData,
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
                title: Text('Clear All Local Data', style: TextStyle(color: Colors.red.shade700)),
                subtitle: const Text('Permanently delete all saved ideas, history, and settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _confirmClearData,
              ),
            ],
          ),
        ),
      );

  Widget _aboutCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reel Audio', style: AppText.screenTitle),
              Gap.s,
              Text('Version 1.0.0+1', style: AppText.hint),
              Text('Screen-free parenting content creator', style: AppText.hint),
              Gap.m,
              const Text('Built with Flutter • Powered by Gemini AI', style: AppText.hint),
              Gap.m,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showLicenses(context),
                      icon: const Icon(Icons.article_outlined),
                      label: const Text('Open Source Licenses'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildSaveBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      );

  Future<void> _exportData() async {
    // Implementation would gather all local data and export as JSON
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  Future<void> _importData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon!')),
    );
  }

  Future<void> _confirmClearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete all saved ideas, post history, promo comments, and settings. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      setState(() {
        _apiKeyController.clear();
        _currentProvider = null;
        _defaultBucket = null;
        _defaultFormat = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }

  void _showLicenses(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Reel Audio',
      applicationVersion: '1.0.0+1',
      applicationIcon: const Icon(Icons.music_note, size: 48, color: AppColors.primary),
      children: const [
        Text('This app uses open source packages. See LICENSE files for details.'),
      ],
    );
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? firstOrNull() {
    for (final element in this) {
      return element;
    }
    return null;
  }
}