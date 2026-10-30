import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_key_store.dart';
import 'content_studio_service.dart';
import 'idea_input_screen.dart';
import 'idea_review_screen.dart';
import 'prompt_preview.dart';
import 'prompt_vault.dart';
import 'prompts.dart';
import 'story_ideas.dart';
import 'theme.dart';

String _storyTitleFromIdea(String idea) {
  final words = idea.trim().split(' ').where((w) => w.length > 3).toList();
  if (words.isEmpty) return 'Story';
  final cap = words.first;
  return cap[0].toUpperCase() + cap.substring(1);
}

String _contentIdFromTitle(String title) {
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .trim()
      .replaceAll(' ', '-');
  return 'FLWP-$slug';
}

Future<void> _saveVideoPromptsToVault(
  GeminiVideoResult result,
  String lastIdea,
  List<String> lastCharacters,
) async {
  final contentId = _contentIdFromTitle(result.storyTitle);
  final metadata = <String, dynamic>{
    'idea': lastIdea,
    'characters': lastCharacters,
    'storyFoundation': result.storyFoundation,
    'totalParts': result.parts.length,
  };
  for (final part in result.parts) {
    await PromptVault.saveWithVersion(
      contentId: contentId,
      title: '${result.storyTitle} ${part.title}',
      type: PromptType.video,
      promptText: part.promptText,
      metadata: {...metadata, 'partNumber': part.partNumber, 'textOverlay': part.textOverlay},
    );
  }
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
  String? _readyPrompt;

  Future<void> _evaluate({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
    String? readyPrompt,
    String? caption,
    List<String>? hashtags,
    String? pinnedComment,
  }) async {
    _ideaText = idea;
    _ideaChars = List.from(characters);
    _ideaInstructions = additionalInstructions;
    _readyPrompt = readyPrompt;

    setState(() {
      _loading = true;
      _status = 'Evaluating idea...';
      _evaluation = null;
    });
    try {
      final evaluation = await evaluateIdeaWithPreview(
        context: context,
        idea: idea,
        apiKey: widget.keyStore.getGeminiApiKey(),
        onWait: (msg) {
          if (mounted) setState(() => _status = msg);
        },
        useSheet: true,
      );
      if (!mounted) return;
      setState(() => _evaluation = evaluation);
    } catch (e) {
      rethrow;
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
        rethrow;
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
        rethrow;
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

  
Future<void> _showEvaluationPromptOnly({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    final prompt = buildCheckStoryPrompt(idea);
    if (!mounted) return;
    await prompt.showPromptOnly(
      context: context,
      title: 'Story Quality Check Prompt',
      modelName: 'gemini-3.5-flash',
      generationConfig: {
        'temperature': 0.3,
        'maxOutputTokens': 2048,
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
useSheet: true,
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
        onEditIdea: _handleBack,
      );
    }
return IdeaInputScreen(
      feature: ContentFeature.imagePrompt,
      initialText: _ideaText.isNotEmpty ? _ideaText : null,
      onGenerate: _loading
          ? ({required String idea, required List<String> characters, required String additionalInstructions, String? readyPrompt, String? caption, List<String>? hashtags, String? pinnedComment}) {}
          : _evaluate,
      onGeneratePromptOnly: _showEvaluationPromptOnly,
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
  String? _readyPrompt;
  int _slideCount = 7;

  static const _slideCounts = [5, 6, 7, 8, 10];

  Future<void> _evaluate({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
    String? readyPrompt,
    String? caption,
    List<String>? hashtags,
    String? pinnedComment,
  }) async {
    _ideaText = idea;
    _ideaChars = List.from(characters);
    _ideaInstructions = additionalInstructions;
    _readyPrompt = readyPrompt;

    setState(() {
      _loading = true;
      _status = 'Evaluating idea...';
      _evaluation = null;
    });
    try {
      final evaluation = await evaluateIdeaWithPreview(
        context: context,
        idea: idea,
        apiKey: widget.keyStore.getGeminiApiKey(),
        onWait: (msg) {
          if (mounted) setState(() => _status = msg);
        },
        useSheet: true,
      );
      if (!mounted) return;
      setState(() => _evaluation = evaluation);
    } catch (e) {
      if (mounted) {
        setState(() => _status = '❌ Evaluation failed: $e\nPlease check your API key and internet connection.');
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
        result = await generateCarouselPromptsWithPreview(
          context: context,
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
        rethrow;
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
        rethrow;
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

  
  Future<void> _showEvaluationPromptOnly({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    final prompt = buildCheckStoryPrompt(idea);
    if (!mounted) return;
    await prompt.showPromptOnly(
      context: context,
      title: 'Story Quality Check Prompt',
      modelName: 'gemini-3.5-flash',
      generationConfig: {
        'temperature': 0.3,
        'maxOutputTokens': 2048,
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
      useSheet: true,
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
          ? ({required String idea, required List<String> characters, required String additionalInstructions, String? readyPrompt, String? caption, List<String>? hashtags, String? pinnedComment}) {}
          : _evaluate,
      onGeneratePromptOnly: _showEvaluationPromptOnly,
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
  String? _readyPrompt;
  String? _caption;
  List<String>? _hashtags;
  String? _pinnedComment;
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
    String? readyPrompt,
    String? caption,
    List<String>? hashtags,
    String? pinnedComment,
  }) async {
    _ideaText = idea;
    _ideaChars = List.from(characters);
    _ideaInstructions = additionalInstructions;
    _readyPrompt = readyPrompt;
    _caption = caption;
    _hashtags = hashtags;
    _pinnedComment = pinnedComment;

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
      if (mounted) {
        setState(() => _status = '❌ Evaluation failed: $e\nPlease check your API key and internet connection.');
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
      late GeminiVideoResult result;
      EngagementPackage? engagement;
      bool usedReadyPrompt = false;

      if (_readyPrompt != null && _readyPrompt!.isNotEmpty) {
        // CASE A: Ready prompt exists - parse and validate
        setState(() => _status = 'Loading ready viral prompt...');
        result = GeminiVideoResult.parseReadyPrompt(
          _readyPrompt!,
          hook?.text ?? 'Viral Reel',
        );
        usedReadyPrompt = true;

        // If ready prompt has validation errors, show them and DON'T auto-fallback
        if (result.validationErrors.isNotEmpty) {
          if (!mounted) return;
          final shouldFallback = await _showValidationErrorsDialog(
            context,
            result.validationErrors,
          );
          if (!shouldFallback) {
            setState(() {
              _isGenerating = false;
              _status = '';
            });
            return;
          }
          // User chose to fallback - clear readyPrompt and regenerate
          _readyPrompt = null;
          usedReadyPrompt = false;
        }

        // Extract engagement data from stored HookIdea data (not from readyPrompt which is legacy)
        if (result.isValid && result.fromReadyPrompt) {
          engagement = EngagementPackage(
            caption: _caption ?? '',
            hashtags: _hashtags ?? [],
            pinnedComment: _pinnedComment ?? '',
            suggestedReplies: [],
            followReason: '',
          );
        }
      }

      // CASE B: No readyPrompt or user chose fallback - generate via Gemini
      if (!usedReadyPrompt) {
        try {
          // Use Master Reel prompt for 30-second videos (3 clips)
          if (_totalSeconds == 30) {
            result = await generateMasterReelPromptsWithPreview(
              context: context,
              idea: idea,
              characters: _ideaChars,
              additionalInstructions: _ideaInstructions,
              hasReferenceImages: true,
              apiKey: widget.keyStore.getGeminiApiKey(),
              onWait: (msg) {
                if (mounted) setState(() => _status = msg);
              },
              useSheet: true,
            );
          } else {
            result = await generateGeminiVideoPromptsWithPreview(
              context: context,
              idea: idea,
              totalSeconds: _totalSeconds,
              characters: _ideaChars,
              additionalInstructions: _ideaInstructions,
              hasReferenceImages: true,
              apiKey: widget.keyStore.getGeminiApiKey(),
              onWait: (msg) {
                if (mounted) setState(() => _status = msg);
              },
              useSheet: true,
            );
          }
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
        _usedReadyPrompt = usedReadyPrompt;
      });
      _saveVideoPromptsToVault(result, idea, _ideaChars);
    } catch (e) {
      if (mounted) setState(() => _status = '❌ $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  bool _usedReadyPrompt = false;

  Future<bool> _showValidationErrorsDialog(
    BuildContext context,
    List<String> errors,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ready Prompt Validation Issues'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The ready prompt has validation issues:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...errors.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $e', style: const TextStyle(fontSize: 13)),
            )),
            const SizedBox(height: 16),
            const Text(
              'Do you want to discard this ready prompt and generate a new one via Gemini (API call)?',
              style: TextStyle(fontSize: 13, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate New (API)'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _handleRegenerate() async {
    await _evaluate(
      idea: _ideaText,
      characters: _ideaChars,
      additionalInstructions: _ideaInstructions,
    );
  }

  
  Future<void> _showEvaluationPromptOnly({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    final prompt = buildCheckStoryPrompt(idea);
    if (!mounted) return;
    await prompt.showPromptOnly(
      context: context,
      title: 'Story Quality Check Prompt',
      modelName: 'gemini-3.5-flash',
      generationConfig: {
        'temperature': 0.3,
        'maxOutputTokens': 2048,
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
      useSheet: true,
    );
  }  
  Future<void> _showMasterReelPromptOnly({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) async {
    final prompt = buildMasterReelPrompt(
      idea: idea,
      characters: characters,
      additionalInstructions: additionalInstructions,
    );
    if (!mounted) return;
    await prompt.showPromptOnly(
      context: context,
      title: 'Master 30-Second Reel Prompt (3 Clips)',
      modelName: 'gemini-3.8-flash',
      generationConfig: {
        'temperature': 0.7,
        'maxOutputTokens': 8192,
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
      useSheet: true,
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
        caption: _caption,
        pinnedComment: _pinnedComment,
        usedReadyPrompt: _usedReadyPrompt,
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
            final contentId = _contentIdFromTitle(current.storyTitle);
            await PromptVault.saveWithVersion(
              contentId: contentId,
              title: '${current.storyTitle} ${newPart.title}',
              type: PromptType.video,
              promptText: newPart.promptText,
              metadata: {
                'partNumber': newPart.partNumber,
                'textOverlay': newPart.textOverlay,
                'regenerated': true,
              },
            );
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
        onEditIdea: _handleBack,
      );
    }
return IdeaInputScreen(
      feature: ContentFeature.geminiVideo,
      initialText: _ideaText.isNotEmpty ? _ideaText : null,
      onGenerate: _loading
          ? ({required String idea, required List<String> characters, required String additionalInstructions, String? readyPrompt, String? caption, List<String>? hashtags, String? pinnedComment}) {}
          : _evaluate,
      onGeneratePromptOnly: _totalSeconds == 30
          ? _showMasterReelPromptOnly
          : _showEvaluationPromptOnly,
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

class _VideoResultScreen extends StatefulWidget {
  final GeminiVideoResult result;
  final EngagementPackage? engagement;
  final VoidCallback onBack;
  final void Function(int partIndex) onRegeneratePart;
  final String? caption;
  final String? pinnedComment;
  final bool usedReadyPrompt;

  const _VideoResultScreen({
    required this.result,
    required this.onBack,
    required this.onRegeneratePart,
    this.engagement,
    this.caption,
    this.pinnedComment,
    this.usedReadyPrompt = false,
  });

  @override
  State<_VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends State<_VideoResultScreen> {
  bool _enhancing = false;

  Future<void> _handleEnhance() async {
    final shouldEnhance = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Enhancement'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will use Gemini to enhance the prompt.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Uses API quota\n'
              '• Original approved prompt will be preserved\n'
              '• You can accept or reject the enhanced version',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Continue with AI enhancement?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enhance (API)'),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldEnhance || !mounted) return;

    setState(() => _enhancing = true);

    // TODO: Implement actual enhancement via Gemini
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enhancement feature coming soon')),
    );
    setState(() => _enhancing = false);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Scaffold(
      appBar: AppBar(
        title: Text(result.storyTitle, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          // Source indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.usedReadyPrompt
                      ? Colors.green.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.usedReadyPrompt
                          ? Icons.check_circle
                          : Icons.auto_awesome,
                      size: 14,
                      color: widget.usedReadyPrompt ? Colors.green : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.usedReadyPrompt ? 'Ready Prompt' : 'Gemini Generated',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.usedReadyPrompt ? Colors.green : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          // Enhancement button
          IconButton(
            tooltip: 'Enhance with AI (uses API)',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _enhancing ? null : _handleEnhance,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Source badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.usedReadyPrompt
                  ? Colors.green.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.usedReadyPrompt
                    ? Colors.green.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.usedReadyPrompt
                      ? Icons.library_books
                      : Icons.auto_awesome,
                  color: widget.usedReadyPrompt ? Colors.green : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.usedReadyPrompt
                        ? 'Loaded from approved Ready Prompt — No API call made'
                        : 'Generated via Gemini API',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.usedReadyPrompt ? Colors.green[700] : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
              onRegenerate: () => widget.onRegeneratePart(i),
            );
          }),
          if (widget.engagement != null) ...[
            const SizedBox(height: 16),
            _EngagementCard(engagement: widget.engagement!),
          ],

          // Caption card
          if (widget.caption != null && widget.caption!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CopyableFieldCard(
              label: 'Caption',
              value: widget.caption!,
              icon: Icons.text_fields,
            ),
          ],

          // Pinned Comment card
          if (widget.pinnedComment != null && widget.pinnedComment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CopyableFieldCard(
              label: 'Pinned Comment',
              value: widget.pinnedComment!,
              icon: Icons.push_pin_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reusable copyable field card ───────────────────────────────────────────────

class _CopyableFieldCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CopyableFieldCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy $label',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                value,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.text, height: 1.5, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
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







