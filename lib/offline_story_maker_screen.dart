import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'offline_engagement.dart';
import 'prompts.dart';
import 'story_generator_offline.dart';
import 'theme.dart';
import 'video_prompt_generator_offline.dart';

class OfflineStoryMakerScreen extends StatefulWidget {
  const OfflineStoryMakerScreen({super.key});

  @override
  State<OfflineStoryMakerScreen> createState() =>
      _OfflineStoryMakerScreenState();
}

class _OfflineStoryMakerScreenState extends State<OfflineStoryMakerScreen> {
  bool _loading = false;
  String _status = '';
  final List<String> _selectedChars = ['Ria', 'Rio', 'Cuty'];
  int _totalSeconds = 30;
  GeneratedStory? _story;
  GeminiVideoResult? _videoResult;
  OfflineEngagementPackage? _engagement;
  HookChoice? _selectedHook;

  static const _durations = [
    (20, '20s — 2 parts'),
    (30, '30s — 3 parts'),
    (40, '40s — 4 parts'),
    (60, '60s — 6 parts'),
  ];

  static const _characterOptions = ['Ria', 'Rio', 'Cuty', 'Mumma'];

  Future<void> _generateStory() async {
    setState(() {
      _loading = true;
      _status = 'Generating story idea...';
    });

    try {
      final generator = StoryGenerator();
      final story = generator.generate();

      setState(() {
        _story = story;
        _status = 'Building video prompts...';
      });

      final videoGen = OfflineVideoPromptGenerator();
      final videoResult = videoGen.generateFromIdea(
        idea: story.problem,
        totalSeconds: _totalSeconds,
        characters: _selectedChars,
      );

      setState(() {
        _videoResult = videoResult;
        _status = 'Building engagement package...';
      });

      final engagementGen = OfflineEngagementGenerator();
      final engagement = engagementGen.generate(storyMoral: story.moral);

      setState(() {
        _engagement = engagement;
        _story = story;
        _videoResult = videoResult;
        _loading = false;
        _status = '';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = '❌ $e';
      });
    }
  }

  Future<void> _regenerateStory() async {
    setState(() {
      _story = null;
      _videoResult = null;
      _engagement = null;
      _selectedHook = null;
    });
    await _generateStory();
  }

  void _selectHook(HookChoice? hook) {
    setState(() => _selectedHook = hook);
  }

  void _toggleChar(String name) {
    setState(() {
      if (_selectedChars.contains(name)) {
        _selectedChars.remove(name);
      } else {
        _selectedChars.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resultReady) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Story Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Character Selection',
                style: AppText.section),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _characterOptions.map((name) {
                final selected = _selectedChars.contains(name);
                return FilterChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (_) => _toggleChar(name),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Video Duration', style: AppText.section),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) {
                final selected = _totalSeconds == d.$1;
                return GestureDetector(
                  onTap: () => setState(() => _totalSeconds = d.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      d.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : AppColors.text,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _generateStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(_status,
                              style: const TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Text('Generate Story (No Internet Required)',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _resultReady =>
      _story != null && _videoResult != null && _engagement != null;

  Widget _buildResultScreen() {
    final story = _story!;
    final result = _videoResult!;
    final engagement = _engagement!;

    return Scaffold(
      appBar: AppBar(
        title: Text(result.storyTitle,
            overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _story = null;
              _videoResult = null;
              _engagement = null;
              _selectedHook = null;
            });
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Copy all parts',
            icon: const Icon(Icons.copy_all),
            onPressed: () {
              final all = result.parts
                  .map((p) =>
                      '=== ${p.title.toUpperCase()} ===\n\n${p.fullPrompt}')
                  .join('\n\n');
              Clipboard.setData(ClipboardData(text: all));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All parts copied')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoryCard(story),
            const SizedBox(height: 16),
            _buildVideoResult(result),
            const SizedBox(height: 16),
            _buildEngagementCard(engagement),
            const SizedBox(height: 16),
            _buildHookSelector(story),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _regenerateStory,
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate Story'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(GeneratedStory story) {
    return Card(
      color: AppColors.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.accent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generated Story',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent)),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.5),
                children: [
                  const TextSpan(
                      text: 'Title: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: story.title),
                  const TextSpan(text: '\n\n'),
                  const TextSpan(
                      text: 'Hook: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: story.hook),
                  const TextSpan(text: '\n\n'),
                  const TextSpan(
                      text: 'Problem: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: story.problem),
                  const TextSpan(text: '\n\n'),
                  const TextSpan(
                      text: 'Ending: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: story.endingLine),
                  const TextSpan(text: '\n\n'),
                  const TextSpan(
                      text: 'Moral: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: story.moral),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoResult(GeminiVideoResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Story Foundation',
            style: Theme.of(context).textTheme.titleMedium),
        Text(result.storyFoundation,
            style: const TextStyle(fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('Video Prompts (${result.parts.length} parts)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
      ...result.parts.map((part) => _VideoPartCard(part: part)),
      ],
    );
  }

  Widget _buildEngagementCard(OfflineEngagementPackage engagement) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Engagement Package',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Caption: ${engagement.caption}',
                style: const TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 8),
            Text('Hashtags: ${engagement.hashtags.join(" ")}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text('Pinned: ${engagement.pinnedComment}',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text('Follow: ${engagement.followReason}',
                style: const TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: engagement.forInstagram));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caption copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Instagram Caption'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHookSelector(GeneratedStory story) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Cover Hook',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: story.hookOptions.asMap().entries.map((entry) {
            final hook = entry.value;
            final selected = _selectedHook?.text == hook['text'];
            return ChoiceChip(
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hook['text']!,
                      style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : AppColors.text)),
                  Text(hook['type']!,
                      style: TextStyle(
                          fontSize: 10,
                          color: selected ? Colors.white70 : AppColors.textSoft)),
                ],
              ),
              selected: selected,
              onSelected: (_) => _selectHook(
                HookChoice(hook['type']!, hook['text']!),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _VideoPartCard extends StatelessWidget {
  final VideoPartPrompt part;

  const _VideoPartCard({required this.part});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    part.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    part.purpose,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy this prompt',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: part.fullPrompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${part.title} copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              part.fullPrompt,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSoft, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
