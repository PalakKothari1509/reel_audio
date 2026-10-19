import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_key_store.dart';
import 'content_studio_service.dart';
import 'idea_input_screen.dart';
import 'idea_review_screen.dart';
import 'offline_engagement.dart';
import 'prompts.dart';
import 'story_generator_offline.dart';
import 'story_ideas.dart';
import 'theme.dart';
import 'video_prompt_generator_offline.dart' hide GeminiVideoResult, VideoPartPrompt;

bool _isGeminiError(Object e) {
  final msg = e.toString().toLowerCase();
  return msg.contains('gemini') ||
      msg.contains('free') ||
      msg.contains('429') ||
      msg.contains('400') ||
      msg.contains('503') ||
      msg.contains('502') ||
      msg.contains('timeout');
}

String _storyTitleFromIdea(String idea) {
  final words = idea.trim().split(' ').where((w) => w.length > 3).toList();
  if (words.isEmpty) return 'Story';
  final cap = words.first;
  return cap[0].toUpperCase() + cap.substring(1);
}

IdeaEvaluation _buildOfflineEvaluation(String idea) {
  final story = StoryGenerator().generate();
  final check = StoryCheck(
    score: 8,
    good: ['Strong relatable hook', 'Clear character fit', 'Satisfying ending'],
    missing: [],
    verdict: 'Generated offline — ready to use',
    rows: kStoryChecks.map((name) => CheckRow(name, true, 'auto')).toList(),
    hooks: story.hookOptions
        .map((h) => HookChoice(h['type']!, h['text']!))
        .toList(),
  );
  final shareability = ShareabilityAnalysis(
    sender: 'Parent of a 3-year-old',
    recipient: 'a parent facing the same situation',
    reason: 'Relatable everyday moment every parent recognizes',
    confidence: 'high',
  );
  return IdeaEvaluation(check: check, shareability: shareability);
}

GeminiVideoResult _buildOfflineVideoResult(String idea, int totalSeconds, List<String> chars) {
  final story = StoryGenerator().generate();
  final mergedStory = story.copyWith(
    title: _storyTitleFromIdea(idea),
    hook: idea,
    problem: idea,
    solution: 'Together they figured it out with teamwork.',
    endingLine: 'Theek hai na Mama?',
    moral: 'Working together makes everything better.',
  );
  final offlineResult = OfflineVideoPromptGenerator().generateFromStory(
    mergedStory,
    totalSeconds: totalSeconds,
    characters: chars,
  );
  return GeminiVideoResult(
    storyTitle: offlineResult.storyTitle,
    storyFoundation: offlineResult.storyFoundation,
    parts: offlineResult.parts
        .map((p) => VideoPartPrompt(
              partNumber: p.partNumber,
              totalParts: p.totalParts,
              promptText: p.promptText,
              textOverlay: '',
            ))
        .toList(),
  );
}

// ── Feature 2: Image Generation Prompt ───────────────────────────────────────

class ImagePromptScreen extends StatefulWidget {
  final ApiKeyStore keyStore;
  const ImagePromptScreen({super.key, required this.keyStore});

  @override
  State<ImagePromptScreen> createState() => _ImagePromptScreenState();
}

class _ImagePromptScreenState extends State<ImagePromptScreen> {
  bool _loading = false;
  bool _isGenerating = false;
  String _status = '';
  String _result = '';
  EngagementPackage? _engagement;
  IdeaEvaluation? _evaluation;
  String _ideaText = '';
  List<String> _ideaChars = [];
  String _ideaInstructions = '';

  Future<void> _evaluate({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    _ideaText = idea;
    _ideaChars = List.from(characters);
    _ideaInstructions = additionalInstructions;

    setState(() {
      _loading = true;
      _status = 'Evaluating idea...';
      _evaluation = null;
    });
    try {
      final evaluation = await evaluateIdea(
        idea: idea,
        apiKey: widget.keyStore.getGeminiApiKey(),
        onWait: (msg) {
          if (mounted) setState(() => _status = msg);
        },
      );
      if (!mounted) return;
      setState(() => _evaluation = evaluation);
    } catch (e) {
      if (_isGeminiError(e)) {
        setState(() => _status = 'Using offline idea evaluator...');
        final evaluation = _buildOfflineEvaluation(idea);
        if (!mounted) return;
        setState(() => _evaluation = evaluation);
      } else if (mounted) {
        setState(() => _status = '❌ $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleApproval(HookChoice? hook) async {
    setState(() {
      _isGenerating = true;
      _status = 'Generating image prompt...';
    });
    try {
      final idea = hook != null
          ? 'Cover hook: ${hook.text}\n\n$_ideaText'
          : _ideaText;
      String resultPrompt;
      try {
        final result = await generateImagePrompt(
          idea: idea,
          characters: _ideaChars,
          additionalInstructions: _ideaInstructions,
          apiKey: widget.keyStore.getGeminiApiKey(),
          onWait: (msg) {
            if (mounted) setState(() => _status = msg);
          },
        );
        if (!mounted) return;
        resultPrompt = result.prompt;
      } catch (e) {
        if (_isGeminiError(e)) {
          resultPrompt = buildOfflineImagePrompt(
            idea: idea,
            characters: _ideaChars,
            additionalInstructions: _ideaInstructions,
          );
        } else {
          rethrow;
        }
      }

      EngagementPackage? engagement;
      try {
        engagement = await generateEngagementPackage(
          idea: _ideaText,
          selectedHook: hook,
          contentPurpose: _evaluation?.check.contentPurpose ?? 'RELATE',
          apiKey: widget.keyStore.getGeminiApiKey(),
          onWait: (msg) {
            if (mounted) setState(() => _status = msg);
          },
        );
      } catch (e) {
        if (_isGeminiError(e)) {
          final offlinePkg = OfflineEngagementGenerator()
              .generate(storyMoral: _evaluation?.check.verdict ?? 'Shared moments matter');
          engagement = EngagementPackage(
            caption: offlinePkg.caption,
            hashtags: offlinePkg.hashtags,
            pinnedComment: offlinePkg.pinnedComment,
            suggestedReplies: offlinePkg.suggestedReplies
                .map((r) => SuggestedReply(
                    r['situation'] ?? '', r['text'] ?? ''))
                .toList(),
            followReason: offlinePkg.followReason,
          );
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      setState(() {
        _result = resultPrompt;
        _engagement = engagement;
        _evaluation = null;
        _status = '';
      });
    } catch (e) {
      if (mounted) setState(() => _status = '❌ $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleRegenerate() async {
    await _evaluate(
      idea: _ideaText,
      characters: _ideaChars,
      additionalInstructions: _ideaInstructions,
    );
  }

  void _handleBack() {
    setState(() {
      _evaluation = null;
      _isGenerating = false;
      _status = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result.isNotEmpty) {
      return _ResultScreen(
        title: '🖼️ Image Generation Prompt',
        result: _result,
        engagement: _engagement,
        onBack: () => setState(() {
          _result = '';
          _engagement = null;
          _status = '';
        }),
      );
    }

    if (_evaluation != null) {
      return IdeaReviewScreen(
        evaluation: _evaluation!,
        originalIdea: _ideaText,
        isRegenerating: _loading,
        isGenerating: _isGenerating,
        status: _status,
        onApprove: _handleApproval,
        onRegenerate: _handleRegenerate,
        onBack: _handleBack,
      );
    }

    return IdeaInputScreen(
      feature: ContentFeature.imagePrompt,
      initialText: _ideaText.isNotEmpty ? _ideaText : null,
      onGenerate: _loading
          ? ({required idea, required characters, required additionalInstructions}) {}
          : _evaluate,
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
  bool _isGenerating = false;
  String _status = '';
  CarouselPromptsResult? _result;
  EngagementPackage? _engagement;
  IdeaEvaluation? _evaluation;
  String _ideaText = '';
  List<String> _ideaChars = [];
  String _ideaInstructions = '';
  int _slideCount = 7;

  static const _slideCounts = [5, 6, 7, 8, 10];

  Future<void> _evaluate({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    _ideaText = idea;
    _ideaChars = List.from(characters);
    _ideaInstructions = additionalInstructions;

    setState(() {
      _loading = true;
      _status = 'Evaluating idea...';
      _evaluation = null;
    });
    try {
      final evaluation = await evaluateIdea(
        idea: idea,
        apiKey: widget.keyStore.getGeminiApiKey(),
        onWait: (msg) {
          if (mounted) setState(() => _status = msg);
        },
      );
      if (!mounted) return;
      setState(() => _evaluation = evaluation);
    } catch (e) {
      if (_isGeminiError(e)) {
        setState(() => _status = 'Using offline idea evaluator...');
        final evaluation = _buildOfflineEvaluation(idea);
        if (!mounted) return;
        setState(() => _evaluation = evaluation);
      } else if (mounted) {
        setState(() => _status = '❌ $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleApproval(HookChoice? hook) async {
    setState(() {
      _isGenerating = true;
      _status = 'Generating carousel prompts...';
    });
    try {
      final idea = hook != null
          ? 'Cover hook: ${hook.text}\n\n$_ideaText'
          : _ideaText;
      CarouselPromptsResult result;
      try {
        result = await generateCarouselPrompts(
          idea: idea,
          slideCount: _slideCount,
          characters: _ideaChars,
          additionalInstructions: _ideaInstructions,
          apiKey: widget.keyStore.getGeminiApiKey(),
          onWait: (msg) {
            if (mounted) setState(() => _status = msg);
          },
        );
      } catch (e) {
        if (_isGeminiError(e)) {
          final offlineSlides = buildOfflineCarouselSlides(
            idea: _ideaText,
            characters: _ideaChars,
            slideCount: _slideCount,
          );
          result = CarouselPromptsResult(
            title: _storyTitleFromIdea(_ideaText),
            slides: offlineSlides.map((s) => CarouselSlidePrompt(
              slideNumber: int.parse(s['slideNumber']!),
              purpose: s['purpose']!,
              textOverlay: s['textOverlay']!,
              prompt: s['prompt']!,
            )).toList(),
          );
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      EngagementPackage? engagement;
      try {
        engagement = await generateEngagementPackage(
          idea: _ideaText,
          selectedHook: hook,
          contentPurpose: _evaluation?.check.contentPurpose ?? 'RELATE',
          apiKey: widget.keyStore.getGeminiApiKey(),
          onWait: (msg) {
            if (mounted) setState(() => _status = msg);
          },
        );
      } catch (e) {
        if (_isGeminiError(e)) {
          final offlinePkg = OfflineEngagementGenerator()
              .generate(storyMoral: _evaluation?.check.verdict ?? 'Shared moments matter');
          engagement = EngagementPackage(
            caption: offlinePkg.caption,
            hashtags: offlinePkg.hashtags,
            pinnedComment: offlinePkg.pinnedComment,
            suggestedReplies: offlinePkg.suggestedReplies
                .map((r) => SuggestedReply(
                    r['situation'] ?? '', r['text'] ?? ''))
                .toList(),
            followReason: offlinePkg.followReason,
          );
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _engagement = engagement;
        _evaluation = null;
        _status = '';
      });
    } catch (e) {
      if (mounted) setState(() => _status = '❌ $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleRegenerate() async {
    await _evaluate(
      idea: _ideaText,
      characters: _ideaChars,
      additionalInstructions: _ideaInstructions,
    );
  }

  void _handleBack() {
    setState(() {
      _evaluation = null;
      _isGenerating = false;
      _status = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _CarouselResultScreen(
        result: _result!,
        engagement: _engagement,
        onBack: () => setState(() {
          _result = null;
          _engagement = null;
          _status = '';
        }),
      );
    }

    if (_evaluation != null) {
      return IdeaReviewScreen(
        evaluation: _evaluation!,
        originalIdea: _ideaText,
        isRegenerating: _loading,
        isGenerating: _isGenerating,
        status: _status,
        onApprove: _handleApproval,
        onRegenerate: _handleRegenerate,
        onBack: _handleBack,
      );
    }

    return IdeaInputScreen(
      feature: ContentFeature.carouselPrompts,
      initialText: _ideaText.isNotEmpty ? _ideaText : null,
      onGenerate: _loading
          ? ({required idea, required characters, required additionalInstructions}) {}
          : _evaluate,
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
  final EngagementPackage? engagement;
  final VoidCallback onBack;
  const _CarouselResultScreen({
    required this.result,
    required this.onBack,
    this.engagement,
  });

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...result.slides.asMap().entries.map((entry) {
            final slide = entry.value;
            return _SlideCard(slide: slide);
          }),
          if (engagement != null) ...[
            const SizedBox(height: 16),
            _EngagementCard(engagement: engagement!),
          ],
        ],
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
  bool _isGenerating = false;
  String _status = '';
  GeminiVideoResult? _result;
  EngagementPackage? _engagement;
  IdeaEvaluation? _evaluation;
  String _ideaText = '';
  List<String> _ideaChars = [];
  String _ideaInstructions = '';
  int _totalSeconds = 30;
  String _lastIdea = '';
  List<String> _lastCharacters = [];

  static const _durations = [
    (20, '20s — 2 parts'),
    (30, '30s — 3 parts'),
    (40, '40s — 4 parts'),
    (60, '60s — 6 parts'),
  ];

  Future<void> _evaluate({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    _ideaText = idea;
    _ideaChars = List.from(characters);
    _ideaInstructions = additionalInstructions;

    setState(() {
      _loading = true;
      _status = 'Evaluating idea...';
      _evaluation = null;
    });
    try {
      final evaluation = await evaluateIdea(
        idea: idea,
        apiKey: widget.keyStore.getGeminiApiKey(),
        onWait: (msg) {
          if (mounted) setState(() => _status = msg);
        },
      );
      if (!mounted) return;
      setState(() => _evaluation = evaluation);
    } catch (e) {
      if (_isGeminiError(e)) {
        setState(() => _status = 'Using offline story generator...');
        final evaluation = _buildOfflineEvaluation(idea);
        if (!mounted) return;
        setState(() => _evaluation = evaluation);
      } else if (mounted) {
        setState(() => _status = '❌ $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleApproval(HookChoice? hook) async {
    setState(() {
      _isGenerating = true;
      _status = 'Generating video prompts...';
    });
    try {
      final idea = hook != null
          ? 'Cover hook: ${hook.text}\n\n$_ideaText'
          : _ideaText;
      GeminiVideoResult result;
      EngagementPackage? engagement;
      try {
        result = await generateGeminiVideoPrompts(
          idea: idea,
          totalSeconds: _totalSeconds,
          characters: _ideaChars,
          additionalInstructions: _ideaInstructions,
          apiKey: widget.keyStore.getGeminiApiKey(),
          onWait: (msg) {
            if (mounted) setState(() => _status = msg);
          },
        );
        if (!mounted) return;
        engagement = await generateEngagementPackage(
          idea: _ideaText,
          selectedHook: hook,
          contentPurpose: _evaluation?.check.contentPurpose ?? 'RELATE',
          apiKey: widget.keyStore.getGeminiApiKey(),
          onWait: (msg) {
            if (mounted) setState(() => _status = msg);
          },
        );
      } catch (e) {
        if (_isGeminiError(e)) {
          setState(() => _status = 'Using offline video prompts...');
          result = _buildOfflineVideoResult(_ideaText, _totalSeconds, _ideaChars);
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      setState(() {
        _result = result;
       _engagement = engagement;
        _lastIdea = idea;
        _lastCharacters = List.from(_ideaChars);
        _evaluation = null;
        _status = '';
      });
    } catch (e) {
      if (mounted) setState(() => _status = '❌ $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleRegenerate() async {
    await _evaluate(
      idea: _ideaText,
      characters: _ideaChars,
      additionalInstructions: _ideaInstructions,
    );
  }

  void _handleBack() {
    setState(() {
      _evaluation = null;
      _isGenerating = false;
      _status = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _VideoResultScreen(
        result: _result!,
        engagement: _engagement,
        onBack: () => setState(() {
          _result = null;
          _engagement = null;
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
            if (mounted) {
              setState(() {
                _status = '❌ $e';
                _loading = false;
              });
            }
          }
        },
      );
    }

    if (_evaluation != null) {
      return IdeaReviewScreen(
        evaluation: _evaluation!,
        originalIdea: _ideaText,
        isRegenerating: _loading,
        isGenerating: _isGenerating,
        status: _status,
        onApprove: _handleApproval,
        onRegenerate: _handleRegenerate,
        onBack: _handleBack,
      );
    }

    return IdeaInputScreen(
      feature: ContentFeature.geminiVideo,
      initialText: _ideaText.isNotEmpty ? _ideaText : null,
      onGenerate: _loading
          ? ({required idea, required characters, required additionalInstructions}) {}
          : _evaluate,
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
  final EngagementPackage? engagement;
  final VoidCallback onBack;
  final void Function(int partIndex) onRegeneratePart;

  const _VideoResultScreen({
    required this.result,
    required this.onBack,
    required this.onRegeneratePart,
    this.engagement,
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
          if (engagement != null) ...[
            const SizedBox(height: 16),
            _EngagementCard(engagement: engagement!),
          ],
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
  final EngagementPackage? engagement;
  final VoidCallback onBack;
  const _ResultScreen({
    required this.title,
    required this.result,
    required this.onBack,
    this.engagement,
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
            if (engagement != null) _EngagementCard(engagement: engagement!),
            if (engagement != null) const SizedBox(height: 16),
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

// ── Shared engagement package card ─────────────────────────────────────────────

class _EngagementCard extends StatelessWidget {
  final EngagementPackage engagement;
  const _EngagementCard({required this.engagement});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      colour: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Caption', style: AppText.section),
          Gap.s,
          Text(engagement.caption, style: AppText.body),
          Gap.s,

          // Hashtags
          Wrap(
            spacing: 6,
            children: EngagementPackage(
              caption: engagement.caption,
              hashtags: engagement.hashtags,
              pinnedComment: engagement.pinnedComment,
              suggestedReplies: engagement.suggestedReplies,
              followReason: engagement.followReason,
            ).hashtags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.accentSoft,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          Gap.s,

          // Pinned comment
          const Text('Pinned Comment', style: AppText.section),
          Gap.s,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.push_pin, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(child: Text(engagement.pinnedComment, style: AppText.body)),
              ],
            ),
          ),
          Gap.s,

          // Follow reason
          const Text('Why follow?', style: AppText.section),
          Gap.s,
          Text(engagement.followReason, style: AppText.body),
          Gap.s,

          // Suggested replies
          const Text('Suggested Replies', style: AppText.section),
          Gap.s,
          ...engagement.suggestedReplies.map((reply) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reply.situation,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSoft)),
                  Gap.xs,
                  Text(reply.text, style: AppText.body),
                  Gap.s,
                ],
              )),

          // Copy all button
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Copy Engagement Package',
              icon: Icons.copy,
              onPressed: () {
                final buffer = StringBuffer();
                buffer.writeln('CAPTION:');
                buffer.writeln(engagement.caption);
                buffer.writeln();
                buffer.writeln('HASHTAGS:');
                buffer.writeln(engagement.hashtags.join(' '));
                buffer.writeln();
                buffer.writeln('PINNED COMMENT:');
                buffer.writeln(engagement.pinnedComment);
                buffer.writeln();
                buffer.writeln('FOLLOW REASON:');
                buffer.writeln(engagement.followReason);
                buffer.writeln();
                buffer.writeln('SUGGESTED REPLIES:');
                for (final r in engagement.suggestedReplies) {
                  buffer.writeln('${r.situation}: ${r.text}');
                  buffer.writeln();
                }
                Clipboard.setData(ClipboardData(text: buffer.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Engagement package copied')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
