import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins three bugs that corrupted every generated post, found by audit rather than by
/// a failing test.
///
/// None of these had a test. Each was invisible in normal use: the posts looked
/// plausible, so the defect only showed up as reach that never arrived.

void main() {
  // -- T-4: every post carried the same five hashtags.
  //
  // `hashtagPool.take(hashtagCount)` injected the FIRST five tags into every request,
  // while the generation prompt simultaneously asked for five tags relevant to the
  // topic. The fixed set always won, so no post could be topically tagged.
  test('the brand block no longer injects a fixed hashtag set', () {
    final source = File('lib/brand_system.dart').readAsStringSync();

    expect(
      source,
      isNot(contains('hashtagPool.take(BrandDefaults.hashtagCount)')),
      reason: 'a fixed tag set defeats topical hashtag generation',
    );
    expect(
      source,
      contains('relevant to THIS post'),
      reason: 'the instruction must ask for topic-relevant tags',
    );
  });

  test('the provider context no longer pre-truncates the hashtag pool', () {
    final source = File('lib/ai_provider.dart').readAsStringSync();
    expect(source, isNot(contains('hashtagPool.take(')));
  });

  test('offline caption hashtags are deduplicated and topic-led', () {
    final source = File('lib/caption_generator.dart').readAsStringSync();
    expect(source, isNot(contains('hashtagPool.take(2)')));
    expect(
      source,
      contains('if (!tags.contains(tag))'),
      reason: 'a topic tag can also be a brand tag; duplicates look like a bug',
    );
  });

  // -- T-5: the CTA menu instructed the model to break a brand rule.
  //
  // `ctaOptions` was injected in full, including "Follow for daily play ideas", while
  // prompts.dart explicitly bans "follow for more" as engagement bait. The app told
  // the model to do the thing another file forbade.
  test('the CTA menu no longer offers the banned follow-for-more option', () {
    for (final path in ['lib/brand_system.dart', 'lib/ai_provider.dart']) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        isNot(contains('ctaOptions.join(')),
        reason: '$path injects the whole CTA menu, including a banned option',
      );
    }

    final brand = File('lib/brand_system.dart').readAsStringSync();
    expect(
      brand,
      contains('Banned by brand rule'),
      reason: 'the prohibition must be stated where the menu used to be',
    );
    expect(
      brand,
      contains('follow for daily play ideas'),
      reason: 'the specific banned phrase must be named, not just referred to',
    );
  });

  // -- T-16: reasoning tokens silently truncated large responses.
  //
  // Reasoning is drawn from maxOutputTokens. On the caption call this was found and
  // fixed; the four 8192-token call sites were missed. A truncated script returns
  // unparseable JSON with no error, which is the worst shape this can fail in.
  test('every hand-built Gemini request caps the thinking budget', () {
    // The SDK call site cannot: `google_generative_ai` has no thinkingConfig. That one
    // is a documented gap rather than a regression, so it is excluded explicitly.
    const sdkSite = 'lib/gemini_client.dart';
    const rawCallSites = ['lib/main.dart', 'lib/prompt_builder.dart'];

    for (final path in rawCallSites) {
      final source = File(path).readAsStringSync();

      // Every generationConfig block in these files must cap thinking.
      final blocks = RegExp(r"'generationConfig':\s*\{([^}]*)\}",
              multiLine: true)
          .allMatches(source)
          .toList();
      expect(blocks, isNotEmpty, reason: '$path has no generationConfig to check');

      for (final b in blocks) {
        expect(
          b.group(1),
          contains('thinkingBudget'),
          reason: '$path has a generationConfig without a thinking cap',
        );
      }
    }

    // The known gap is still a known gap, not silently forgotten.
    final sdk = File(sdkSite).readAsStringSync();
    expect(
      sdk,
      contains('thinkingConfig` is deliberately absent'),
      reason: 'the one uncapped site must stay documented',
    );
  });

  test('the reference fix that started this is still present', () {
    final source = File('lib/caption_generator.dart').readAsStringSync();
    expect(source, contains('thinkingBudget'));
  });
}