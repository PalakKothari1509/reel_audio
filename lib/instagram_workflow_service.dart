import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'brand_system.dart';
import 'gemini_call.dart';

enum InstagramWorkflowType {
  growthSystem(
    'Instagram Growth System',
    'Plan experiments from approved ideas and evidence you provide.',
  ),
  reelsScriptEngine(
    'Reels Script Engine',
    'Turn an approved idea into an editable, character-aware Reel script.',
  ),
  carouselBuilder(
    'Carousel Builder',
    'Optionally build an editable slide sequence and image prompts.',
  ),
  captionRewriter(
    'Caption Rewriter',
    'Rewrite an existing caption without losing its intended meaning.',
  ),
  hashtagKeywordMap(
    'Hashtag & Keyword Map',
    'Create topic keywords and five relevant hashtag suggestions.',
  ),
  storiesSequence(
    'Instagram Stories Sequence',
    'Draft a text-and-frame sequence; publishing is not included.',
  );

  final String label;
  final String description;

  const InstagramWorkflowType(this.label, this.description);
}

class InstagramWorkflowGeneration {
  final String title;
  final String content;
  final Map<String, dynamic> metadata;
  final bool usedOfflineFallback;
  final String? notice;

  const InstagramWorkflowGeneration({
    required this.title,
    required this.content,
    this.metadata = const {},
    this.usedOfflineFallback = false,
    this.notice,
  });
}

class InstagramWorkflowService {
  static const _model = 'gemini-3.5-flash';
  static const _fallbackModel = 'gemini-3.8-flash';
  static const _timeout = Duration(seconds: 90);

  static Future<InstagramWorkflowGeneration> generateGrowthPlan({
    required String scope,
    required String idea,
    required String category,
    required String evidence,
    required bool hasRecordedMetrics,
    required String apiKey,
    void Function(String message)? onWait,
  }) async {
    final prompt = '''
You are a careful Instagram content planner for "${BrandDefaults.name}".
Audience: ${BrandDefaults.audience}. Brand voice: ${BrandDefaults.tone}.

SCOPE: $scope
${idea.trim().isEmpty ? '' : 'APPROVED IDEA: $idea'}
${category.trim().isEmpty ? '' : 'CATEGORY: $category'}
${evidence.trim().isEmpty ? 'PERFORMANCE EVIDENCE: none supplied.' : 'USER-PROVIDED PERFORMANCE EVIDENCE: $evidence'}
EVIDENCE STATUS: ${hasRecordedMetrics ? 'User-provided or saved values; not independently verified.' : 'No performance metrics supplied. Treat every recommendation as a hypothesis to test.'}

Create a practical content strategy and small experiments, not predictions.
Do not invent trends, audience behavior, reach, benchmarks, or results.
Never claim a recommendation will increase performance. When evidence is
missing, say the plan is an estimate/hypothesis and request manual measurement.
Use approved idea material only; do not invent account history.
Return JSON only:
{"title":"short plan title","sections":[{"heading":"section","actions":["specific next step"]}]}
Include a section for what to measure and how to compare the next test. Keep
actions feasible for a small Indian preschool-parent education account.
''';

    final generated = await _requestObject(
      prompt: prompt,
      apiKey: apiKey,
      onWait: onWait,
    );
    if (generated.value == null) {
      return InstagramWorkflowGeneration(
        title: 'Growth plan',
        content: _offlineGrowthPlan(scope, idea, evidence, hasRecordedMetrics),
        metadata: {
          'scope': scope,
          'evidence': evidence,
          'evidenceType': hasRecordedMetrics ? 'user-provided' : 'estimate',
        },
        usedOfflineFallback: true,
        notice: generated.reason,
      );
    }

    final sections = _readSections(generated.value!['sections']);
    if (sections.isEmpty) {
      return InstagramWorkflowGeneration(
        title: 'Growth plan',
        content: _offlineGrowthPlan(scope, idea, evidence, hasRecordedMetrics),
        metadata: {
          'scope': scope,
          'evidence': evidence,
          'evidenceType': hasRecordedMetrics ? 'user-provided' : 'estimate',
        },
        usedOfflineFallback: true,
        notice: 'The response had no usable plan sections; an offline template was used.',
      );
    }
    return InstagramWorkflowGeneration(
      title: _readText(generated.value!['title']).isEmpty
          ? 'Growth plan'
          : _readText(generated.value!['title']),
      content: sections,
      metadata: {
        'scope': scope,
        'evidence': evidence,
        'evidenceType': hasRecordedMetrics ? 'user-provided' : 'estimate',
      },
    );
  }

  static Future<InstagramWorkflowGeneration> generateStoriesSequence({
    required String idea,
    required String category,
    required List<String> characters,
    required String apiKey,
    void Function(String message)? onWait,
  }) async {
    final prompt = '''
Create a five-frame Instagram Stories sequence for "${BrandDefaults.name}".
Audience: ${BrandDefaults.audience}. Voice: ${BrandDefaults.tone}.
APPROVED IDEA: $idea
CATEGORY: $category
CHARACTERS: ${characters.isEmpty ? 'Use only characters that fit the idea.' : characters.join(', ')}

Return five connected frames with short editable on-screen copy, a visual
direction, and an optional native Instagram interaction suggestion (poll,
question, slider, or none). Do not claim audience reactions or results. Do not
render text into image prompts. This is a planning draft only; do not claim to
publish or render Stories.
Return JSON only:
{"title":"short sequence title","frames":[{"purpose":"hook","text":"short frame copy","visual":"simple visual direction","interaction":"poll or none"}]}
''';

    final generated = await _requestObject(
      prompt: prompt,
      apiKey: apiKey,
      onWait: onWait,
    );
    if (generated.value == null) {
      return InstagramWorkflowGeneration(
        title: 'Stories sequence',
        content: _offlineStoriesSequence(idea, characters),
        metadata: {'frameCount': 5},
        usedOfflineFallback: true,
        notice: generated.reason,
      );
    }

    final frames = generated.value!['frames'];
    if (frames is! List || frames.length != 5) {
      return InstagramWorkflowGeneration(
        title: 'Stories sequence',
        content: _offlineStoriesSequence(idea, characters),
        metadata: {'frameCount': 5},
        usedOfflineFallback: true,
        notice: 'The response did not contain exactly five frames; an offline template was used.',
      );
    }

    final content = <String>[];
    for (var index = 0; index < frames.length; index++) {
      final rawFrame = frames[index];
      if (rawFrame is! Map) continue;
      final frame = Map<String, dynamic>.from(rawFrame);
      content.add(
        'FRAME ${index + 1} — ${_readText(frame['purpose'])}\n'
        'TEXT: ${_readText(frame['text'])}\n'
        'VISUAL: ${_readText(frame['visual'])}\n'
        'INTERACTION: ${_readText(frame['interaction'])}',
      );
    }
    if (content.length != 5 ||
        content.any((frame) => frame.contains('TEXT: \n'))) {
      return InstagramWorkflowGeneration(
        title: 'Stories sequence',
        content: _offlineStoriesSequence(idea, characters),
        metadata: {'frameCount': 5},
        usedOfflineFallback: true,
        notice: 'The response contained incomplete frames; an offline template was used.',
      );
    }
    return InstagramWorkflowGeneration(
      title: _readText(generated.value!['title']).isEmpty
          ? 'Stories sequence'
          : _readText(generated.value!['title']),
      content: content.join('\n\n'),
      metadata: {'frameCount': 5},
    );
  }

  static List<String> topicKeywords(String source, {String category = ''}) {
    const stopWords = {
      'about', 'after', 'again', 'also', 'are', 'because', 'been', 'before',
      'being', 'between', 'could', 'does', 'from', 'have', 'into', 'just',
      'more', 'most', 'other', 'over', 'same', 'some', 'than', 'that',
      'their', 'them', 'then', 'there', 'these', 'they', 'this', 'those',
      'through', 'under', 'very', 'what', 'when', 'where', 'which', 'while',
      'the', 'with', 'would', 'your', 'meri', 'mera', 'mere', 'hai', 'hain', 'aur',
      'ka', 'ki', 'ke', 'ko', 'mein', 'par', 'se', 'tha', 'thi',
      'and', 'for', 'you',
    };
    final result = <String>[];
    for (final match in RegExp(r"[A-Za-z0-9]+(?:'[A-Za-z]+)?").allMatches(
      '$category $source',
    )) {
      final word = match.group(0)!;
      final normalized = word.toLowerCase();
      if (normalized.length < 3 || stopWords.contains(normalized)) continue;
      if (result.every((existing) => existing.toLowerCase() != normalized)) {
        result.add(word);
      }
      if (result.length == 8) break;
    }
    return result;
  }

  static String _offlineGrowthPlan(
    String scope,
    String idea,
    String evidence,
    bool hasRecordedMetrics,
  ) {
    final evidenceLine = hasRecordedMetrics
        ? 'Evidence supplied (not independently verified): $evidence'
        : 'No performance metrics supplied. This is a planning estimate, not an account-performance finding.';
    return [
      'SCOPE: $scope',
      if (idea.trim().isNotEmpty) 'APPROVED IDEA: $idea',
      evidenceLine,
      'NEXT STEPS:',
      '- Choose one approved idea and one format to test.',
      '- Record the post date, format, reach, saves, shares, and comments manually.',
      '- Compare with a previous post only when the same metrics are available.',
      '- Treat any change as a hypothesis; do not attribute cause from one post.',
      'REVIEW:',
      '- Revisit after collecting comparable account data.',
      '- No trend, audience, reach, or growth claim is made by this offline plan.',
    ].join('\n');
  }

  static String _offlineStoriesSequence(String idea, List<String> characters) {
    final cast = characters.isEmpty ? 'Your chosen characters' : characters.join(', ');
    final prompts = [
      ('HOOK', 'A relatable moment from: $idea', 'Question sticker: What would you try?'),
      ('SETUP', 'Show the situation clearly with $cast.', 'None'),
      ('TRY', 'Invite viewers to try one small, screen-free activity.', 'Poll: Try it / Save it'),
      ('REFLECT', 'Share the simple learning moment from the approved idea.', 'Slider: How useful was this?'),
      ('CTA', 'Invite parents to save the idea or reply with their own version.', 'Question sticker: What worked at home?'),
    ];
    return [
      for (var i = 0; i < prompts.length; i++)
        'FRAME ${i + 1} — ${prompts[i].$1}\n'
            'TEXT: ${prompts[i].$2}\n'
            'VISUAL: ${prompts[i].$2}\n'
            'INTERACTION: ${prompts[i].$3}',
    ].join('\n\n');
  }

  static String _readSections(Object? raw) {
    if (raw is! List) return '';
    final sections = <String>[];
    for (final value in raw) {
      if (value is! Map) continue;
      final section = Map<String, dynamic>.from(value);
      final heading = _readText(section['heading']);
      final actions = section['actions'];
      if (heading.isEmpty || actions is! List) continue;
      final lines = actions
          .map(_readText)
          .where((action) => action.isNotEmpty)
          .map((action) => '- $action')
          .toList();
      if (lines.isNotEmpty) sections.add('$heading\n${lines.join('\n')}');
    }
    return sections.join('\n\n');
  }

  static String _readText(Object? value) =>
      value is String ? value.trim() : '';

  static Future<_ObjectResult> _requestObject({
    required String prompt,
    required String apiKey,
    void Function(String message)? onWait,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const _ObjectResult(
        reason: 'No Gemini API key is configured; an offline template was used.',
      );
    }
    try {
      onWait?.call('Generating strategy workflow...');
      final response = await geminiPost(
        model: _model,
        fallbackModel: _fallbackModel,
        apiKey: apiKey,
        timeout: _timeout,
        onWait: onWait,
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.6,
            'maxOutputTokens': 4096,
            'responseMimeType': 'application/json',
          },
        }),
      );
      if (response.statusCode != 200) {
        return _ObjectResult(
          reason:
              'Gemini returned ${response.statusCode}; an offline template was used.',
        );
      }
      final responseJson = jsonDecode(response.body);
      if (responseJson is! Map) {
        return const _ObjectResult(
          reason: 'Gemini returned an unexpected response; an offline template was used.',
        );
      }
      final candidates = responseJson['candidates'];
      Object? parts;
      if (candidates is List &&
          candidates.isNotEmpty &&
          candidates.first is Map) {
        final candidate =
            Map<String, dynamic>.from(candidates.first as Map);
        final content = candidate['content'];
        if (content is Map) parts = content['parts'];
      }
      Object? text;
      if (parts is List && parts.isNotEmpty && parts.first is Map) {
        text = Map<String, dynamic>.from(parts.first as Map)['text'];
      }
      if (text is! String || text.trim().isEmpty) {
        return const _ObjectResult(
          reason: 'Gemini returned no workflow content; an offline template was used.',
        );
      }
      final parsed = jsonDecode(text.trim());
      if (parsed is! Map) {
        return const _ObjectResult(
          reason: 'Gemini returned invalid workflow JSON; an offline template was used.',
        );
      }
      return _ObjectResult(value: Map<String, dynamic>.from(parsed));
    } on Exception catch (error) {
      debugPrint('InstagramWorkflowService: $error');
      return _ObjectResult(
        reason: 'Online generation failed ($error); an offline template was used.',
      );
    }
  }
}

class _ObjectResult {
  final Map<String, dynamic>? value;
  final String? reason;

  const _ObjectResult({this.value, this.reason});
}
