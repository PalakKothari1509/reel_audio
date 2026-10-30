import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_key_store.dart';
import 'brand_system.dart';
import 'caption_generator.dart';
import 'content_axes.dart';
import 'content_generator.dart';
import 'content_library.dart';
import 'content_library_service.dart';
import 'content_service.dart';
import 'content_studio_service.dart';
import 'character_definitions.dart';
import 'format_adapter.dart';
import 'instagram_workflow_service.dart';
import 'quality_check.dart';
import 'theme.dart';

typedef ReelScriptGenerator = Future<String> Function(
  String idea,
  List<String> characterIds,
);

class InstagramWorkflowsScreen extends StatefulWidget {
  final ApiKeyStore keyStore;
  final ReelScriptGenerator generateReelScript;

  const InstagramWorkflowsScreen({
    super.key,
    required this.keyStore,
    required this.generateReelScript,
  });

  @override
  State<InstagramWorkflowsScreen> createState() =>
      _InstagramWorkflowsScreenState();
}

class _InstagramWorkflowsScreenState extends State<InstagramWorkflowsScreen> {
  final _ideaController = TextEditingController();
  final _metricsController = TextEditingController();
  final _sourceCaptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _captionController = TextEditingController();
  final _hashtagsController = TextEditingController();

  List<ContentIdea> _approvedIdeas = const [];
  List<ContentLibraryItem> _savedWorkflows = const [];
  InstagramWorkflowType? _workflow;
  ContentLibraryItem? _editingItem;
  String? _selectedIdeaId;
  String _category = BucketLibrary.challenge.id;
  String _growthScope = 'Account';
  ContentFormat _format = ContentFormat.reel;
  List<String> _selectedCharacterIds = ['ria', 'rio', 'cuty'];
  bool _loading = true;
  bool _generating = false;
  String _status = '';
  String? _notice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ideaController.dispose();
    _metricsController.dispose();
    _sourceCaptionController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _status = '';
    });
    try {
      final ideas = await ContentLibraryService.instance.getAllIdeas();
      final items = await ContentLibraryStore.getAll();
      if (!mounted) return;
      setState(() {
        _approvedIdeas = ideas
            .where((idea) => idea.status == IdeaStatus.approved)
            .toList();
        _savedWorkflows = items
            .where((item) => item.workflowType != null)
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'Could not load approved ideas or saved workflows: $error';
      });
    }
  }

  void _startWorkflow(InstagramWorkflowType workflow) {
    setState(() {
      _workflow = workflow;
      _editingItem = null;
      _notice = null;
      _status = '';
      _selectedIdeaId = null;
      _ideaController.clear();
      _metricsController.clear();
      _titleController.clear();
      _contentController.clear();
      _captionController.clear();
      _hashtagsController.clear();
      _sourceCaptionController.clear();
      _selectedCharacterIds = ['ria', 'rio', 'cuty'];
      _growthScope = 'Account';
      _format = ContentFormat.reel;
      _hasDraft = false;
    });
  }

  void _selectIdea(String? id) {
    setState(() {
      _selectedIdeaId = id;
      final matches = _approvedIdeas.where((candidate) => candidate.id == id);
      final idea = matches.isEmpty ? null : matches.first;
      if (idea == null) return;
      _ideaController.text = [
        idea.title,
        if (idea.opening.isNotEmpty) idea.opening,
        if (idea.problem.isNotEmpty) idea.problem,
        if (idea.lesson.isNotEmpty) idea.lesson,
        if (idea.storyDetail.isNotEmpty) idea.storyDetail,
      ].join('\n');
      if (_workflow == InstagramWorkflowType.captionRewriter &&
          idea.caption.trim().isNotEmpty) {
        _sourceCaptionController.text = idea.caption;
      }
      final bucket = BucketLibrary.all.where(
        (candidate) =>
            candidate.name.toLowerCase() == idea.category.toLowerCase() ||
            candidate.id.toLowerCase() == idea.category.toLowerCase(),
      );
      if (bucket.isNotEmpty) _category = bucket.first.id;
      if (idea.characterIds.isNotEmpty) {
        final availableIds =
            _workflow == InstagramWorkflowType.reelsScriptEngine
            ? kMainAppCharacterDefinitions.map((c) => c.id).toSet()
            : kCharacterDefinitions.map((c) => c.id).toSet();
        _selectedCharacterIds = idea.characterIds
            .map((id) => id.toLowerCase())
            .where(availableIds.contains)
            .toList();
        if (_selectedCharacterIds.isEmpty) _selectedCharacterIds = ['ria'];
      }
    });
  }

  ContentIdea? get _selectedIdea {
    for (final idea in _approvedIdeas) {
      if (idea.id == _selectedIdeaId) return idea;
    }
    return null;
  }

  Future<void> _generate() async {
    final workflow = _workflow;
    if (workflow == null) return;
    final idea = _ideaController.text.trim();
    if (workflow != InstagramWorkflowType.growthSystem &&
        idea.isEmpty &&
        workflow != InstagramWorkflowType.captionRewriter) {
      setState(
        () => _status = 'Choose an approved idea or enter an idea first.',
      );
      return;
    }
    if (workflow == InstagramWorkflowType.captionRewriter &&
        _sourceCaptionController.text.trim().isEmpty) {
      setState(() => _status = 'Paste the caption you want to rewrite.');
      return;
    }
    if (workflow == InstagramWorkflowType.growthSystem &&
        _growthScope == 'One approved idea' &&
        _selectedIdea == null) {
      setState(
        () => _status = 'Choose an approved idea for per-idea planning, or switch to Account.',
      );
      return;
    }

    setState(() {
      _generating = true;
      _status = 'Preparing ${workflow.label.toLowerCase()}...';
      _notice = null;
    });
    try {
      final generation = await _generateWorkflow(workflow, idea);
      if (!mounted) return;
      final captionResult = await _captionFor(workflow, idea, generation);
      if (!mounted) return;
      setState(() {
        _titleController.text = generation.title;
        _contentController.text = generation.content;
        _captionController.text = captionResult.caption;
        _hashtagsController.text = captionResult.hashtags.join(' ');
        _notice = [
          if (generation.notice != null) generation.notice!,
          if (generation.usedOfflineFallback && generation.notice == null)
            'An offline template was used.',
          if (captionResult.notice != null) captionResult.notice!,
        ].where((part) => part.isNotEmpty).join('\n');
        _status = _notice ?? 'Draft ready. Edit it before saving.';
        _generationMetadata = {
          ...generation.metadata,
          'generationMode': generation.usedOfflineFallback
              ? 'offline-template'
              : 'online',
          'workflowType': workflow.name,
        };
        _hasDraft = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Generation failed: $error');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Map<String, dynamic> _generationMetadata = {};
  bool _hasDraft = false;

  Future<InstagramWorkflowGeneration> _generateWorkflow(
    InstagramWorkflowType workflow,
    String idea,
  ) async {
    final apiKey = widget.keyStore.getGeminiApiKey();
    final characters = _selectedCharacterIds;
    switch (workflow) {
      case InstagramWorkflowType.growthSystem:
        final savedMetrics = await _savedMetricsText();
        final manualMetrics = _metricsController.text.trim();
        final evidence = [
          if (savedMetrics.isNotEmpty)
            'Saved user-recorded metrics:\n$savedMetrics',
          if (manualMetrics.isNotEmpty)
            'Additional manual metrics:\n$manualMetrics',
        ].join('\n\n');
        return InstagramWorkflowService.generateGrowthPlan(
          scope: _growthScope,
          idea: _growthScope == 'Account' ? '' : idea,
          category: _selectedIdea?.category ?? _category,
          evidence: evidence,
          hasRecordedMetrics: evidence.isNotEmpty,
          apiKey: apiKey,
          onWait: _updateStatus,
        );
      case InstagramWorkflowType.reelsScriptEngine:
        try {
          final script = await widget.generateReelScript(idea, characters);
          if (script.trim().isEmpty) {
            throw Exception('The Reel script generator returned no lines.');
          }
          return InstagramWorkflowGeneration(
            title: _selectedIdea?.title ?? 'Reel script',
            content: script,
          );
        } on Exception catch (error) {
          final local = _offlinePackage(idea, ContentFormat.reel, characters);
          return InstagramWorkflowGeneration(
            title: _selectedIdea?.title ?? 'Reel script',
            content: FormatAdapter.adapt(local, ContentFormat.reel).script,
            usedOfflineFallback: true,
            notice:
                'Online Reel generation failed ($error); an offline script template was used.',
          );
        }
      case InstagramWorkflowType.carouselBuilder:
        try {
          _updateStatus('Generating optional carousel slides...');
          final result = await generateCarouselPrompts(
            idea: idea,
            slideCount: 7,
            characters: _characterNames(characters),
            contentTheme: _selectedIdea?.category ?? _category,
            language: 'Hinglish',
            apiKey: apiKey,
            onWait: _updateStatus,
          );
          return InstagramWorkflowGeneration(
            title: result.title,
            content: [
              for (final slide in result.slides)
                'SLIDE ${slide.slideNumber} — ${slide.purpose}\n'
                    'TEXT: ${slide.textOverlay}\n'
                    'IMAGE PROMPT: ${slide.prompt}',
            ].join('\n\n'),
            metadata: {'slideCount': result.slides.length},
          );
        } on Exception catch (error) {
          final local = _offlinePackage(
            idea,
            ContentFormat.carousel,
            characters,
          );
          return InstagramWorkflowGeneration(
            title: _selectedIdea?.title ?? 'Carousel draft',
            content: [
              for (final slide in local.slides)
                'SLIDE ${slide.index + 1} — ${slide.title}\n'
                    'TEXT: ${slide.body}\n'
                    'IMAGE PROMPT: ${slide.visualPrompt}',
            ].join('\n\n'),
            metadata: {'slideCount': local.slides.length},
            usedOfflineFallback: true,
            notice:
                'Online carousel generation failed ($error); an offline template was used.',
          );
        }
      case InstagramWorkflowType.captionRewriter:
        final sourceCaption = _sourceCaptionController.text.trim();
        if (apiKey.trim().isEmpty) {
          return InstagramWorkflowGeneration(
            title: _selectedIdea?.title ?? 'Caption rewrite',
            content: sourceCaption,
            metadata: {
              'sourceCaption': sourceCaption,
              'generatedHashtags': captionFromTemplate(
                topic: idea.isEmpty ? sourceCaption : idea,
                language: CaptionLanguage.hinglish,
                bucket: _category,
              ).hashtags,
            },
            usedOfflineFallback: true,
            notice: 'No API key is configured; the original is preserved for manual editing.',
          );
        }
        try {
          final result = await generateCaption(
            topic: idea.isEmpty ? sourceCaption : idea,
            language: CaptionLanguage.hinglish,
            bucket: _selectedIdea?.category ?? _category,
            sourceCaption: sourceCaption,
            apiKey: apiKey,
            onWait: _updateStatus,
          );
          return InstagramWorkflowGeneration(
            title: _selectedIdea?.title ?? 'Caption rewrite',
            content: [
              result.hook,
              ...result.body,
              result.takeaway,
              result.cta,
            ].where((part) => part.trim().isNotEmpty).join('\n'),
            metadata: {
              'sourceCaption': sourceCaption,
              'generatedHashtags': result.hashtags,
            },
          );
        } on Exception catch (error) {
          return InstagramWorkflowGeneration(
            title: _selectedIdea?.title ?? 'Caption rewrite',
            content: sourceCaption,
            metadata: {
              'sourceCaption': sourceCaption,
              'generatedHashtags': captionFromTemplate(
                topic: idea.isEmpty ? sourceCaption : idea,
                language: CaptionLanguage.hinglish,
                bucket: _category,
              ).hashtags,
            },
            usedOfflineFallback: true,
            notice:
                'Online rewrite failed ($error); the original is preserved for manual editing.',
          );
        }
      case InstagramWorkflowType.hashtagKeywordMap:
        final keywords = InstagramWorkflowService.topicKeywords(
          idea,
          category: _selectedIdea?.category ?? _category,
        );
        return InstagramWorkflowGeneration(
          title: _selectedIdea?.title ?? 'Hashtag & keyword map',
          content:
              'TOPIC KEYWORDS (derived from your idea; not trend data)\n'
              '${keywords.isEmpty ? '- Add a more specific topic to derive keywords.' : keywords.map((word) => '- $word').join('\n')}\n\n'
              'HASHTAG NOTE\n'
              '- Five suggestions are shown below; they are topic/brand suggestions only, not current Instagram trends.',
          metadata: {
            'keywords': keywords,
            'dataSource': 'topic text; no trend lookup',
          },
        );
      case InstagramWorkflowType.storiesSequence:
        final result = await InstagramWorkflowService.generateStoriesSequence(
          idea: idea,
          category: _selectedIdea?.category ?? _category,
          characters: _characterNames(characters),
          apiKey: apiKey,
          onWait: _updateStatus,
        );
        return result;
    }
  }

  Future<({String caption, List<String> hashtags, String? notice})> _captionFor(
    InstagramWorkflowType workflow,
    String idea,
    InstagramWorkflowGeneration generation,
  ) async {
    if (workflow == InstagramWorkflowType.growthSystem) {
      return (caption: '', hashtags: const <String>[], notice: null);
    }
    if (workflow == InstagramWorkflowType.captionRewriter) {
      final rawTags = generation.metadata['generatedHashtags'];
      final List<String> tags = rawTags is List
          ? rawTags.map((tag) => '$tag').toList()
          : captionFromTemplate(
              topic: idea.isEmpty ? _sourceCaptionController.text : idea,
              language: CaptionLanguage.hinglish,
              bucket: _category,
            ).hashtags;
      return (
        caption: generation.content,
        hashtags: tags,
        notice: generation.usedOfflineFallback
            ? 'The original caption was preserved; no rewrite is claimed without a successful online response.'
            : null,
      );
    }
    final template = captionFromTemplate(
      topic: idea,
      language: CaptionLanguage.hinglish,
      bucket: _selectedIdea?.category ?? _category,
    );
    if (workflow == InstagramWorkflowType.hashtagKeywordMap) {
      return (
        caption: '',
        hashtags: template.hashtags,
        notice: 'Five topic/brand suggestions are provided without live trend data or an extra API request.',
      );
    }
    return (
      caption: template.fullText,
      hashtags: template.hashtags,
      notice: 'The existing offline caption template was used; no additional API request was made.',
    );
  }

  ContentPackage _offlinePackage(
    String idea,
    ContentFormat format,
    List<String> characterIds,
  ) {
    final characters = characterIds
        .map(CharacterLibrary.byId)
        .whereType<Character>()
        .toList();
    final bucket = BucketLibrary.byId(_category) ?? BucketLibrary.challenge;
    return ContentGenerator.generateFromTemplate(
      idea,
      bucket,
      format,
      characters.isEmpty
          ? [CharacterLibrary.ria, CharacterLibrary.rio]
          : characters,
      format.defaultSlideCount.clamp(format.minSlides, format.maxSlides),
    );
  }

  List<String> _characterNames(List<String> ids) => ids
      .map(CharacterLibrary.byId)
      .whereType<Character>()
      .map((character) => character.name)
      .toList();

  List<Character> _availableCharacters(InstagramWorkflowType workflow) =>
      workflow == InstagramWorkflowType.reelsScriptEngine
      ? kMainAppCharacterDefinitions
      : kCharacterDefinitions;

  Future<String> _savedMetricsText() async {
    final items = await ContentLibraryStore.getAll();
    final entries = <String>[];
    for (final item in items) {
      if (item.status != IdeaStatus.posted &&
          item.status != IdeaStatus.tested) {
        continue;
      }
      if (item.performanceMetrics.isEmpty) continue;
      entries.add(
        '${item.title}: ${item.performanceMetrics.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}',
      );
    }
    return entries.join('\n');
  }

  void _updateStatus(String message) {
    if (mounted) setState(() => _status = message);
  }

  Future<void> _save() async {
    final workflow = _workflow;
    if (workflow == null || !_hasDraft) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _status = 'Add editable workflow content before saving.');
      return;
    }
    final hashtags = _parseHashtags(_hashtagsController.text);
    final hasSocialPost = workflow != InstagramWorkflowType.growthSystem;
    if (hasSocialPost && hashtags.length != 5) {
      setState(
        () => _status = 'A post draft needs exactly five hashtags. Edit the hashtag field and try again.',
      );
      return;
    }

    final package = _makePackage(workflow, content, hashtags);
    final formats = FormatAdapter.adaptAll(package);
    final report = hasSocialPost
        ? QualityChecker.check(package, formats)
        : null;
    final data = <String, dynamic>{
      ..._generationMetadata,
      'editableText': content,
      'scope': workflow == InstagramWorkflowType.growthSystem
          ? _growthScope
          : null,
      'category': _selectedIdea?.category ?? _category,
      'sourceCaption': _sourceCaptionController.text.trim(),
      'sourceIdeaId': _selectedIdea?.id,
      'qualitySummary': report == null
          ? null
          : {
              'passCount': report.passCount,
              'warnCount': report.warnCount,
              'failCount': report.failCount,
            },
    }..removeWhere((_, value) => value == null);

    try {
      final editing = _editingItem;
      if (editing == null) {
        await ContentService.saveGeneratedPackage(
          package,
          _selectedIdea?.id,
          workflowType: workflow.name,
          workflowData: data,
          status: workflow == InstagramWorkflowType.growthSystem
              ? IdeaStatus.idea
              : IdeaStatus.scripted,
          qualityReport: report,
          tags: _workflowTags(workflow, hashtags),
        );
      } else {
        final updated = editing.copyWith(
          title: _titleController.text.trim(),
          topic: _ideaController.text.trim(),
          contentPackage: package,
          format: package.format,
          formatOutputs: formats,
          qualityReport: report,
          tags: _workflowTags(workflow, hashtags),
          workflowType: workflow.name,
          workflowData: data,
        );
        await ContentLibraryStore.update(updated);
        if (await ContentLibraryStore.getById(updated.id) == null) {
          throw StateError(
            'The saved workflow draft no longer exists in the library.',
          );
        }
      }
      await _load();
      if (!mounted) return;
      setState(() {
        _status = [
          'Saved to Content Library. You can reopen this draft to edit it.',
          if (report != null)
            'Quality check: ${report.passCount} passed, ${report.warnCount} warnings, ${report.failCount} failed.',
        ].join(' ');
        _editingItem = null;
        _hasDraft = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'Could not save this draft: $error');
      }
    }
  }

  ContentPackage _makePackage(
    InstagramWorkflowType workflow,
    String content,
    List<String> hashtags,
  ) {
    final format = switch (workflow) {
      InstagramWorkflowType.growthSystem => _format,
      InstagramWorkflowType.reelsScriptEngine => ContentFormat.reel,
      InstagramWorkflowType.carouselBuilder => ContentFormat.carousel,
      InstagramWorkflowType.captionRewriter => ContentFormat.reel,
      InstagramWorkflowType.hashtagKeywordMap => ContentFormat.singleImage,
      InstagramWorkflowType.storiesSequence => ContentFormat.reel,
    };
    final blocks = content
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList();
    final slides = [
      for (var index = 0; index < blocks.length; index++)
        _slideFromBlock(blocks[index], index),
    ];
    final title = _titleController.text.trim().isEmpty
        ? workflow.label
        : _titleController.text.trim();
    final characters = _selectedCharacterIds
        .map(CharacterLibrary.byId)
        .whereType<Character>()
        .toList();
    final bucket = BucketLibrary.byId(_category) ?? BucketLibrary.challenge;
    return ContentPackage(
      id:
          _editingItem?.contentPackage?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      idea: _ideaController.text.trim().isEmpty
          ? workflow.label
          : _ideaController.text.trim(),
      bucket: bucket,
      format: format,
      characters: characters.isEmpty
          ? const [CharacterLibrary.ria]
          : characters,
      hook: title,
      slides: slides,
      visualPrompts: slides
          .map((slide) => slide.visualPrompt)
          .where((prompt) => prompt.isNotEmpty)
          .toList(),
      caption: _captionController.text.trim(),
      cta: '',
      hashtags: hashtags,
      pinnedComment: '',
      replyComments: const [],
      createdAt: _editingItem?.contentPackage?.createdAt ?? DateTime.now(),
    );
  }

  SlideContent _slideFromBlock(String block, int index) {
    final lines = block.split('\n');
    final firstLine = lines.first.trim();
    final title = firstLine
        .replaceFirst(RegExp(r'^(?:FRAME|SLIDE)\s+\d+\s*[—-]\s*'), '')
        .replaceFirst(RegExp(r':$'), '')
        .trim();
    String valueAfter(String label) {
      final index = lines.indexWhere(
        (line) => line.trimLeft().toUpperCase().startsWith(label),
      );
      if (index < 0) return '';
      final first = lines[index].trim().substring(label.length).trim();
      final continuation = <String>[];
      for (final line in lines.skip(index + 1)) {
        final normalized = line.trimLeft().toUpperCase();
        if (const [
          'TEXT:',
          'IMAGE PROMPT:',
          'VISUAL:',
          'INTERACTION:',
        ].any(normalized.startsWith)) {
          break;
        }
        continuation.add(line);
      }
      return [
        first,
        continuation.join('\n').trim(),
      ].where((part) => part.isNotEmpty).join('\n');
    }

    final body = valueAfter('TEXT:');
    final visual = valueAfter('IMAGE PROMPT:').isNotEmpty
        ? valueAfter('IMAGE PROMPT:')
        : valueAfter('VISUAL:');
    return SlideContent(
      index: index,
      title: title.isEmpty ? 'Section ${index + 1}' : title,
      body: body.isNotEmpty ? body : block,
      visualPrompt: visual,
      overlayText: body.isEmpty ? null : body,
    );
  }

  List<String> _parseHashtags(String raw) => raw
      .split(RegExp(r'[\s,]+'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .map((tag) => tag.startsWith('#') ? tag.substring(1) : tag)
      .map((tag) => tag.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '').toLowerCase())
      .where((tag) => tag.isNotEmpty)
      .map((tag) => '#$tag')
      .toSet()
      .toList();

  List<String> _workflowTags(
    InstagramWorkflowType workflow,
    List<String> hashtags,
  ) => [_category, 'instagram-workflow', workflow.name, ...hashtags];

  void _openSaved(ContentLibraryItem item) {
    final matches = InstagramWorkflowType.values.where(
      (candidate) => candidate.name == item.workflowType,
    );
    final workflow = matches.isEmpty ? null : matches.first;
    if (workflow == null) {
      setState(
        () => _status = 'This saved workflow has an unknown type and cannot be edited here.',
      );
      return;
    }
    final pkg = item.contentPackage;
    setState(() {
      _workflow = workflow;
      _editingItem = item;
      _selectedIdeaId =
          _approvedIdeas.any((idea) => idea.id == item.sourceIdeaId)
          ? item.sourceIdeaId
          : null;
      _ideaController.text = pkg?.idea ?? item.topic;
      _titleController.text = item.title;
      _contentController.text =
          item.workflowData['editableText'] as String? ?? _textFromPackage(pkg);
      _captionController.text = pkg?.caption ?? '';
      _hashtagsController.text = pkg?.hashtags.join(' ') ?? '';
      _category = item.workflowData['category'] as String? ?? item.bucket.id;
      _growthScope = item.workflowData['scope'] as String? ?? 'Account';
      _format = item.format;
      _sourceCaptionController.text =
          item.workflowData['sourceCaption'] as String? ?? '';
      _generationMetadata = Map<String, dynamic>.from(item.workflowData);
      _hasDraft = true;
      _notice = 'Editing a saved ${workflow.label} draft.';
      _status = '';
    });
  }

  String _textFromPackage(ContentPackage? pkg) {
    if (pkg == null) return '';
    return pkg.slides
        .map((slide) {
          if (slide.body == slide.title) return slide.body;
          return '${slide.title}\nTEXT: ${slide.body}'
              '${slide.visualPrompt.isEmpty ? '' : '\nVISUAL: ${slide.visualPrompt}'}';
        })
        .join('\n\n');
  }

  void _copyDraft() {
    final buffer = StringBuffer()
      ..writeln(_titleController.text)
      ..writeln()
      ..writeln(_contentController.text);
    if (_captionController.text.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(_captionController.text.trim());
    }
    if (_hashtagsController.text.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(_hashtagsController.text.trim());
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Workflow draft copied')));
  }

  @override
  Widget build(BuildContext context) {
    final workflow = _workflow;
    return Scaffold(
      appBar: AppBar(
        title: Text(workflow?.label ?? 'Instagram Workflows'),
        leading: workflow == null
            ? null
            : IconButton(
                tooltip: 'All workflows',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _workflow = null;
                  _editingItem = null;
                  _hasDraft = false;
                  _status = '';
                }),
              ),
        actions: [
          if (workflow == null)
            IconButton(
              tooltip: 'Refresh ideas and saved drafts',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : workflow == null
          ? _workflowList()
          : _workflowEditor(workflow),
    );
  }

  Widget _workflowList() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Choose a workflow', style: AppText.screenTitle),
      const SizedBox(height: 4),
      const Text(
        'Drafts are editable before saving. Recommendations use only the '
        'ideas and performance data you provide.',
        style: AppText.hint,
      ),
      const SizedBox(height: 16),
      if (_status.isNotEmpty) _statusCard(_status),
      for (final workflow in InstagramWorkflowType.values)
        Card(
          child: ListTile(
            leading: Icon(_iconFor(workflow)),
            title: Text(workflow.label),
            subtitle: Text(workflow.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _startWorkflow(workflow),
          ),
        ),
      const SizedBox(height: 16),
      const Text('Saved workflow drafts', style: AppText.section),
      const SizedBox(height: 8),
      if (_savedWorkflows.isEmpty)
        const Text(
          'Saved drafts will appear here. They are stored in the existing Content Library.',
          style: AppText.hint,
        ),
      for (final item in _savedWorkflows)
        Card(
          child: ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(item.title),
            subtitle: Text(
              '${_workflowLabel(item.workflowType)} · ${item.status.label}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _openSaved(item),
          ),
        ),
    ],
  );

  Widget _workflowEditor(InstagramWorkflowType workflow) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(workflow.description, style: AppText.hint),
      const SizedBox(height: 12),
      if (_approvedIdeas.isNotEmpty)
        DropdownButtonFormField<String>(
          initialValue: _selectedIdeaId,
          decoration: const InputDecoration(
            labelText: 'Approved idea (optional for account plan)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Choose an approved idea'),
            ),
            for (final idea in _approvedIdeas)
              DropdownMenuItem(
                value: idea.id,
                child: Text(
                  idea.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) =>
              _selectIdea(value?.isEmpty == true ? null : value),
        )
      else
        const Text(
          'No approved ideas are available yet. You can enter a working idea below.',
          style: AppText.hint,
        ),
      const SizedBox(height: 12),
      TextField(
        controller: _ideaController,
        minLines: 2,
        maxLines: 6,
        decoration: const InputDecoration(
          labelText: 'Idea / content context',
          hintText:
              'Use an approved idea or describe the idea you want to work on.',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: const InputDecoration(
          labelText: 'Content category',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final bucket in BucketLibrary.all)
            DropdownMenuItem(value: bucket.id, child: Text(bucket.name)),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _category = value);
        },
      ),
      if (workflow == InstagramWorkflowType.growthSystem) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _growthScope,
          decoration: const InputDecoration(
            labelText: 'Planning scope',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Account', child: Text('Account')),
            DropdownMenuItem(
              value: 'One approved idea',
              child: Text('One approved idea'),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _growthScope = value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _metricsController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Manual Instagram metrics (optional)',
            hintText: 'For example: post date, reach, saves, shares, comments. No API connection is used.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Saved posted-item metrics are included as user-recorded, not API-verified. Without metrics, suggestions are labeled as estimates.',
          style: AppText.small,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ContentFormat>(
          initialValue: _format,
          decoration: const InputDecoration(
            labelText: 'Primary format to plan around',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final format in ContentFormat.values)
              DropdownMenuItem(value: format, child: Text(format.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _format = value);
          },
        ),
      ],
      if (workflow == InstagramWorkflowType.captionRewriter) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _sourceCaptionController,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Existing caption',
            border: OutlineInputBorder(),
          ),
        ),
      ],
      if (workflow == InstagramWorkflowType.reelsScriptEngine ||
          workflow == InstagramWorkflowType.carouselBuilder ||
          workflow == InstagramWorkflowType.storiesSequence) ...[
        const SizedBox(height: 12),
        const Text('Characters', style: AppText.section),
        Wrap(
          spacing: 8,
          children: [
            for (final character in _availableCharacters(workflow))
              FilterChip(
                label: Text(character.name),
                selected: _selectedCharacterIds.contains(character.id),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCharacterIds.add(character.id);
                    } else {
                      _selectedCharacterIds.remove(character.id);
                    }
                  });
                },
              ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _generating ? null : _generate,
        icon: _generating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_generating ? _status : 'Generate editable draft'),
      ),
      if (_status.isNotEmpty) ...[
        const SizedBox(height: 8),
        _statusCard(_status),
      ],
      if (_hasDraft) ...[
        const SizedBox(height: 20),
        Text(
          _editingItem == null ? 'Edit your draft' : 'Edit saved draft',
          style: AppText.section,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Draft title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _contentController,
          minLines: 8,
          maxLines: 24,
          decoration: const InputDecoration(
            labelText: 'Workflow content',
            helperText:
                'Edit the generated script, plan, frames, or keyword map here.',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        if (workflow != InstagramWorkflowType.growthSystem) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _captionController,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Short Instagram caption',
              helperText: 'Keep it concise and edit freely.',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _hashtagsController,
            decoration: const InputDecoration(
              labelText: 'Exactly five relevant hashtags',
              helperText: 'Separate hashtags with spaces or commas. Trend status is not checked.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        if (_notice != null && _notice!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _statusCard(_notice!),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyDraft,
                icon: const Icon(Icons.copy),
                label: const Text('Copy draft'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _editingItem == null ? 'Save to Library' : 'Update Library',
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _statusCard(String message) => Card(
    color: AppColors.surfaceAlt,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(message, style: AppText.bodySmall),
    ),
  );

  IconData _iconFor(InstagramWorkflowType workflow) => switch (workflow) {
    InstagramWorkflowType.growthSystem => Icons.trending_up,
    InstagramWorkflowType.reelsScriptEngine => Icons.movie_creation_outlined,
    InstagramWorkflowType.carouselBuilder => Icons.view_carousel_outlined,
    InstagramWorkflowType.captionRewriter => Icons.edit_note,
    InstagramWorkflowType.hashtagKeywordMap => Icons.tag,
    InstagramWorkflowType.storiesSequence => Icons.auto_stories_outlined,
  };

  String _workflowLabel(String? name) {
    for (final workflow in InstagramWorkflowType.values) {
      if (workflow.name == name) return workflow.label;
    }
    return name ?? 'Unknown workflow';
  }
}
