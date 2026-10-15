import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_key_store.dart';
import 'content_studio_service.dart';
import 'idea_input_screen.dart';
import 'theme.dart';

// ── Feature 2: Image Generation Prompt ───────────────────────────────────────

class ImagePromptScreen extends StatefulWidget {
  final ApiKeyStore keyStore;
  const ImagePromptScreen({super.key, required this.keyStore});

  @override
  State<ImagePromptScreen> createState() => _ImagePromptScreenState();
}

class _ImagePromptScreenState extends State<ImagePromptScreen> {
  bool _loading = false;
  String _status = '';
  String _result = '';

  Future<void> _generate({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    setState(() {
      _loading = true;
      _status = 'Generating image prompt...';
      _result = '';
    });
    try {
      final result = await generateImagePrompt(
        idea: idea,
        characters: characters,
        additionalInstructions: additionalInstructions,
        apiKey: widget.keyStore.getGeminiApiKey(),
        onWait: (msg) {
          if (mounted) setState(() => _status = msg);
        },
      );
      if (!mounted) return;
      setState(() {
        _result = result.prompt;
        _status = '';
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _status = '❌ $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result.isNotEmpty) {
      return _ResultScreen(
        title: '🖼️ Image Generation Prompt',
        result: _result,
        onBack: () => setState(() {
          _result = '';
          _status = '';
        }),
      );
    }

    return IdeaInputScreen(
      feature: ContentFeature.imagePrompt,
      onGenerate: _loading
          ? ({required idea, required characters, required additionalInstructions}) {}
          : _generate,
      extraControls: _loading
          ? _LoadingCard(message: _status)
          : _status.isNotEmpty
              ? _StatusCard(message: _status)
              : null,
    );
  }
}

// ── Feature 3: Carousel Generation Prompts ───────────────────────────────────

class CarouselPromptsScreen extends StatefulWidget {
  final ApiKeyStore keyStore;
  const CarouselPromptsScreen({super.key, required this.keyStore});

  @override
  State<CarouselPromptsScreen> createState() => _CarouselPromptsScreenState();
}

class _CarouselPromptsScreenState extends State<CarouselPromptsScreen> {
  bool _loading = false;
  String _status = '';
  CarouselPromptsResult? _result;
  int _slideCount = 7;

  static const _slideCounts = [5, 6, 7, 8, 10];

  Future<void> _generate({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    setState(() {
      _loading = true;
      _status = 'Generating carousel prompts...';
      _result = null;
    });
    try {
      final result = await generateCarouselPrompts(
        idea: idea,
        slideCount: _slideCount,
        characters: characters,
        additionalInstructions: additionalInstructions,
        apiKey: widget.keyStore.getGeminiApiKey(),
        onWait: (msg) {
          if (mounted) setState(() => _status = msg);
        },
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = '';
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _status = '❌ $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _CarouselResultScreen(
        result: _result!,
        onBack: () => setState(() {
          _result = null;
          _status = '';
        }),
      );
    }

    return IdeaInputScreen(
      feature: ContentFeature.carouselPrompts,
      onGenerate: _loading
          ? ({required idea, required characters, required additionalInstructions}) {}
          : _generate,
      extraControls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Number of slides', style: AppText.section),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slideCounts.map((n) {
              final selected = _slideCount == n;
              return GestureDetector(
                onTap: () => setState(() => _slideCount = n),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '$n slides',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            _LoadingCard(message: _status),
          ] else if (_status.isNotEmpty) ...[
            const SizedBox(height: 16),
            _StatusCard(message: _status),
          ],
        ],
      ),
    );
  }
}

class _CarouselResultScreen extends StatelessWidget {
  final CarouselPromptsResult result;
  final VoidCallback onBack;
  const _CarouselResultScreen({required this.result, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(result.title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        actions: [
          IconButton(
            tooltip: 'Copy all prompts',
            icon: const Icon(Icons.copy_all),
            onPressed: () {
              final all = result.slides
                  .map((s) =>
                      '--- SLIDE ${s.slideNumber}: ${s.purpose} ---\n'
                      '${s.textOverlay.isNotEmpty ? "TEXT: ${s.textOverlay}\n\n" : ""}'
                      '${s.prompt}')
                  .join('\n\n');
              Clipboard.setData(ClipboardData(text: all));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All prompts copied')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: result.slides.length,
        itemBuilder: (ctx, i) {
          final slide = result.slides[i];
          return _SlideCard(slide: slide);
        },
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final CarouselSlidePrompt slide;
  const _SlideCard({required this.slide});

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Slide ${slide.slideNumber}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slide.purpose,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy this prompt',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: slide.prompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Slide ${slide.slideNumber} copied')),
                    );
                  },
                ),
              ],
            ),
            if (slide.textOverlay.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TEXT: ${slide.textOverlay}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              slide.prompt,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSoft,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feature 4: Gemini Story Video ────────────────────────────────────────────

class GeminiVideoScreen extends StatefulWidget {
  final ApiKeyStore keyStore;
  const GeminiVideoScreen({super.key, required this.keyStore});

  @override
  State<GeminiVideoScreen> createState() => _GeminiVideoScreenState();
}

class _GeminiVideoScreenState extends State<GeminiVideoScreen> {
  bool _loading = false;
  String _status = '';
  GeminiVideoResult? _result;
  int _totalSeconds = 30;
  String _lastIdea = '';
  List<String> _lastCharacters = [];

  static const _durations = [
    (20, '20s — 2 parts'),
    (30, '30s — 3 parts'),
    (40, '40s — 4 parts'),
    (60, '60s — 6 parts'),
  ];

  Future<void> _generate({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    setState(() {
      _loading = true;
      _status = 'Generating video prompts...';
      _result = null;
    });
    try {
      final result = await generateGeminiVideoPrompts(
        idea: idea,
        totalSeconds: _totalSeconds,
        characters: characters,
        additionalInstructions: additionalInstructions,
        apiKey: widget.keyStore.getGeminiApiKey(),
        onWait: (msg) {
          if (mounted) setState(() => _status = msg);
        },
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _lastIdea = idea;
        _lastCharacters = List.from(characters);
        _status = '';
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _status = '❌ $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _VideoResultScreen(
        result: _result!,
        onBack: () => setState(() {
          _result = null;
          _status = '';
        }),
        onRegeneratePart: (partIndex) async {
          final current = _result!;
          setState(() {
            _loading = true;
            _status = 'Regenerating Part ${partIndex + 1}...';
          });
          try {
            final newPart = await regenerateSingleVideoPart(
              idea: _lastIdea,
              storyFoundation: current.storyFoundation,
              partNumber: partIndex + 1,
              totalParts: current.parts.length,
              characters: _lastCharacters,
              previousEndingState: partIndex > 0
                  ? current.parts[partIndex - 1].promptText
                  : '',
              apiKey: widget.keyStore.getGeminiApiKey(),
              onWait: (msg) {
                if (mounted) setState(() => _status = msg);
              },
            );
            if (!mounted) return;
            final updatedParts = List<VideoPartPrompt>.from(current.parts);
            updatedParts[partIndex] = newPart;
            setState(() {
              _result = GeminiVideoResult(
                storyTitle: current.storyTitle,
                storyFoundation: current.storyFoundation,
                parts: updatedParts,
              );
              _status = '';
              _loading = false;
            });
          } catch (e) {
            if (mounted) setState(() {
              _status = '❌ $e';
              _loading = false;
            });
          }
        },
      );
    }

    return IdeaInputScreen(
      feature: ContentFeature.geminiVideo,
      onGenerate: _loading
          ? ({required idea, required characters, required additionalInstructions}) {}
          : _generate,
      extraControls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total video duration', style: AppText.section),
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
          if (_loading) ...[
            const SizedBox(height: 16),
            _LoadingCard(message: _status),
          ] else if (_status.isNotEmpty) ...[
            const SizedBox(height: 16),
            _StatusCard(message: _status),
          ],
        ],
      ),
    );
  }
}

class _VideoResultScreen extends StatelessWidget {
  final GeminiVideoResult result;
  final VoidCallback onBack;
  final void Function(int partIndex) onRegeneratePart;

  const _VideoResultScreen({
    required this.result,
    required this.onBack,
    required this.onRegeneratePart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(result.storyTitle, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        actions: [
          IconButton(
            tooltip: 'Copy all parts',
            icon: const Icon(Icons.copy_all),
            onPressed: () {
              final all = result.parts
                  .map((p) =>
                      '=== ${p.title.toUpperCase()} ===\n\n${p.promptText}')
                  .join('\n\n');
              Clipboard.setData(ClipboardData(text: all));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All parts copied')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Story foundation card
          Card(
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
                  const Text('Story Foundation',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                  const SizedBox(height: 6),
                  Text(result.storyFoundation,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.text, height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Part cards
          ...result.parts.asMap().entries.map((entry) {
            final i = entry.key;
            final part = entry.value;
            return _VideoPartCard(
              part: part,
              onRegenerate: () => onRegeneratePart(i),
            );
          }),
        ],
      ),
    );
  }
}

class _VideoPartCard extends StatelessWidget {
  final VideoPartPrompt part;
  final VoidCallback onRegenerate;
  const _VideoPartCard({required this.part, required this.onRegenerate});

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
                const Spacer(),
                TextButton.icon(
                  onPressed: onRegenerate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Regenerate', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSoft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy this part',
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: part.promptText));
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
              part.promptText,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSoft,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared result screen for single-prompt features ───────────────────────────

class _ResultScreen extends StatelessWidget {
  final String title;
  final String result;
  final VoidCallback onBack;
  const _ResultScreen({
    required this.title,
    required this.result,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        actions: [
          IconButton(
            tooltip: 'Copy prompt',
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prompt copied')),
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
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  result,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.text,
                      height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prompt copied')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy prompt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared loading / status widgets ──────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  final String message;
  const _LoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSoft)),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String message;
  const _StatusCard({required this.message});

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (context.mounted) {
      showBottomSheet(
        context: context,
        builder: (_) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: AppColors.surface,
          child: const Text('Error copied to clipboard',
              style: AppText.body),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = message.startsWith('❌');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFDEEEE) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isError ? AppColors.danger : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 13,
                    color: isError ? AppColors.danger : AppColors.textSoft)),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Copy message',
            icon: const Icon(Icons.content_copy, size: 18),
            color: isError ? AppColors.danger : AppColors.textSoft,
            onPressed: () => _copyToClipboard(context),
          ),
        ],
      ),
    );
  }
}
