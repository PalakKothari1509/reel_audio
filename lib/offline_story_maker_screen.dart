import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'characters.dart';
import 'content_ideas.dart';
import 'offline_engagement.dart';
import 'plan_data.dart';
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
  HookIdea? _selectedHookIdea;
  HookChoice? _selectedStoryHook;

  static const _durations = [
    (20, '20s — 2 parts'),
    (30, '30s — 3 parts'),
    (40, '40s — 4 parts'),
    (60, '60s — 6 parts'),
  ];

  Future<void> _generateStory() async {
    setState(() {
      _loading = true;
      _status = 'Generating story idea...';
    });

    try {
      final generator = StoryGenerator();
      final story = _selectedHookIdea != null
          ? _storyFromHook(_selectedHookIdea!)
          : await generator.generate();

      setState(() {
        _story = story;
        _status = 'Building video prompts...';
      });

      final videoGen = OfflineVideoPromptGenerator();
      final videoResult = videoGen.generateFromStory(
        story,
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

  void _pickFromLibrary() async {
    final HookIdea? picked = await showModalBottomSheet<HookIdea>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => _LibraryPicker(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedHookIdea = picked;
        _selectedChars
          ..clear()
          ..addAll(['Ria', 'Rio', 'Cuty']);
      });
    }
  }

  GeneratedStory _storyFromHook(HookIdea hook) {
    final lines = _parseStoryDetail(hook.storyDetail);
    final hasDetail = hook.storyDetail.trim().isNotEmpty;

    String fromDetail(String key) {
      final v = lines[key]?.trim() ?? '';
      return (hasDetail && v.isNotEmpty) ? v : '';
    }

    // Precedence: the hook's own moment fields win. storyDetail is the
    // fallback for ideas that have not been migrated to the moment schema yet.
    final setting = hook.setting.trim().isNotEmpty
        ? hook.setting.trim()
        : (fromDetail('where').isNotEmpty
            ? fromDetail('where')
            : _deriveWhere(hook.problem));

    final problem =
        hook.problem.trim().isNotEmpty ? hook.problem.trim() : fromDetail('problem');

    final resolution = fromDetail('resolution');

    final escalation = hook.mess.trim().isNotEmpty
        ? hook.mess.trim()
        : (fromDetail('worse').isNotEmpty
            ? fromDetail('worse')
            : (fromDetail('twist').isNotEmpty
                ? fromDetail('twist')
                : _firstSentence(resolution)));

    final beat = hook.endingBeat.trim().isNotEmpty
        ? hook.endingBeat.trim()
        : (fromDetail('ending').isNotEmpty ? fromDetail('ending') : resolution);

    return GeneratedStory(
      title: hook.cover,
      hook: _buildHookText(hook),
      who: _selectedChars.join(', '),
      where: setting,
      problem: problem,
      twist: fromDetail('twist').isNotEmpty ? fromDetail('twist') : escalation,
      worse: escalation,
      solution: resolution.isNotEmpty ? resolution : beat,
      endingLine: beat,
      moral: hook.keepMoralOffScreen
          ? ''
          : (fromDetail('moral').isNotEmpty ? fromDetail('moral') : hook.lesson),
      hookOptions: _buildHookOptions(hook),
      setting: setting,
      sceneDetail: hook.sceneDetail,
      dialogue: hook.dialogue,
      mess: hook.mess.trim().isNotEmpty ? hook.mess.trim() : escalation,
      innerThought: hook.innerThought,
      endingBeat: beat,
      cast: hook.defaultCast,
      moralHidden: hook.keepMoralOffScreen,
    );
  }

  /// First sentence of a resolution, used as a fallback escalation so the app
  /// never has to mint boilerplate like "everything fell apart at once".
  String _firstSentence(String text) {
    final match = RegExp(r'^[^.!?]*[.!?]').firstMatch(text.trim());
    return match == null ? text.trim() : match.group(0)!.trim();
  }

  /// Parses the Story:/Where:/Twist:/Worse:/Resolution:/Ending:/Moral: labels.
  /// Nothing is aliased any more — 'worse' is NOT the resolution, and 'ending'
  /// is NOT the moral. That aliasing is what put the moral on screen as the
  /// closing beat of every legacy idea.
  Map<String, String> _parseStoryDetail(String detail) {
    final result = <String, String>{};
    if (detail.trim().isEmpty) return result;

    for (final line in detail.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      String valueAfter(String label) => trimmed.substring(label.length).trim();

      if (trimmed.startsWith('Story:') || trimmed.startsWith('PART 1:')) {
        result['problem'] = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (trimmed.startsWith('Where:')) {
        result['where'] = valueAfter('Where:');
      } else if (trimmed.startsWith('Twist:')) {
        result['twist'] = valueAfter('Twist:');
      } else if (trimmed.startsWith('Worse:')) {
        result['worse'] = valueAfter('Worse:');
      } else if (trimmed.startsWith('Resolution:')) {
        result['resolution'] = valueAfter('Resolution:');
      } else if (trimmed.startsWith('Ending:') ||
          trimmed.startsWith('Ending image:')) {
        result['ending'] = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (trimmed.startsWith('Moral:')) {
        result['moral'] = valueAfter('Moral:');
      }
    }
    return result;
  }

  /// The opening is the first three seconds. If the idea has one, say it —
  /// never mint one at random. Deterministic, so regenerating shows the same text.
  String _buildHookText(HookIdea hook) {
    if (hook.opening.trim().isNotEmpty) return hook.opening.trim();
    if (hook.cover.trim().isNotEmpty) return hook.cover.trim();
    return '';
  }

  List<Map<String, String>> _buildHookOptions(HookIdea hook) {
    final options = <Map<String, String>>[
      if (hook.opening.trim().isNotEmpty)
        {'type': 'Opening line', 'text': hook.opening.trim()},
      if (hook.cover.trim().isNotEmpty) {'type': 'Cover', 'text': hook.cover.trim()},
      if (hook.dialogue.trim().isNotEmpty)
        {'type': 'Dialogue', 'text': hook.dialogue.trim()},
      if (hook.innerThought.trim().isNotEmpty)
        {'type': 'Parent thought', 'text': hook.innerThought.trim()},
    ];
    if (options.isEmpty) options.add({'type': 'Cover', 'text': hook.cover});
    return options;
  }

  String _deriveWhere(String problem) {
    final lower = problem.toLowerCase();
    if (lower.contains('kitchen') || lower.contains('food')) return 'in the kitchen';
    if (lower.contains('playground') || lower.contains('park')) return 'at the playground';
    if (lower.contains('bedroom') || lower.contains('sleep')) return 'in the bedroom';
    if (lower.contains('garba') || lower.contains('dance') || lower.contains('festival')) return 'at home';
    if (lower.contains('snack') || lower.contains('eat')) return 'in the dining area';
    return 'at home';
  }

  Future<void> _regenerateStory() async {
    setState(() {
      _story = null;
      _videoResult = null;
      _engagement = null;
      _selectedHookIdea = null;
    });
    await _generateStory();
  }

  void _selectHook(HookChoice hook) {
    setState(() {
      _selectedStoryHook = hook;
      _story = _story!.copyWith(hook: hook.text);
      _status = 'Regenerating video prompts...';
    });
    _regenerateVideoPrompt();
  }

  Future<void> _regenerateVideoPrompt() async {
    final story = _story!;
    final videoGen = OfflineVideoPromptGenerator();
    final videoResult = videoGen.generateFromStory(
      story,
      totalSeconds: _totalSeconds,
      characters: _selectedChars,
    );

    setState(() {
      _videoResult = videoResult;
      _status = '';
    });
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
              children: kCharacterNames.map((name) {
                final selected = _selectedChars.contains(name);
                return FilterChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (_) => _toggleChar(name),
                );
              }            ).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickFromLibrary,
                icon: const Icon(Icons.library_books_outlined, size: 18),
                label: const Text('Select from Content Library'),
              ),
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
              _selectedHookIdea = null;
              _selectedStoryHook = null;
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
    List<InlineSpan> _row(String label, String value) {
      if (value.trim().isEmpty) return const [];
      return [
        TextSpan(
            text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: '$value\n\n'),
      ];
    }

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
                  ..._row('Title', story.title),
                  ..._row('Hook', story.hook),
                  ..._row('Where', story.setting),
                  ..._row('What starts it', story.problem),
                  ..._row('Scene detail', story.sceneDetail),
                  ..._row('Dialogue', story.dialogue),
                  ..._row('What goes wrong', story.mess),
                  ..._row('Parent thought', story.innerThought),
                  ..._row('Ending image', story.endingBeat),
                  if (!story.moralHidden) ..._row('Moral (spoken)', story.moral),
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
            final selected = _selectedStoryHook?.text == hook['text'];
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
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy', style: TextStyle(fontSize: 12)),
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

class _LibraryPicker extends StatefulWidget {
  @override
  State<_LibraryPicker> createState() => _LibraryPickerState();
}

class _LibraryPickerState extends State<_LibraryPicker> {
  String _filter = '';
  final _ctrl = TextEditingController();
  List<HookIdea> _hooks = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadHooks();
    _ctrl.addListener(() {
      setState(() => _filter = _ctrl.text.toLowerCase());
    });
  }

  Future<void> _loadHooks() async {
    final loaded = await HookStore.load();
    setState(() {
      _hooks = loaded.where((h) => h.forApp).toList();
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _hooks
        .where((h) =>
            _filter.isEmpty ||
            h.cover.toLowerCase().contains(_filter) ||
            h.problem.toLowerCase().contains(_filter) ||
            h.setting.toLowerCase().contains(_filter) ||
            h.dialogue.toLowerCase().contains(_filter) ||
            h.sceneDetail.toLowerCase().contains(_filter) ||
            h.category.toLowerCase().contains(_filter))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Column(
        children: [
          if (!_loaded)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...[
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search ideas...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _filter = v.toLowerCase()),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final h = filtered[i];
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      title: Text(
                        h.cover,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        h.problem,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small,
                      ),
                      trailing: Text(
                        h.category,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textFaint),
                      ),
                      onTap: () => Navigator.pop(ctx, h),
                    );
                  },
                ),
              ),
            ],
        ],
      ),
    );
  }
}
