// Content axes: the controlled vocabulary for what a piece of content IS.
//
// GENERATED-FEELING BUT HAND-MAINTAINED. Unlike `format_handbook.dart` there is no
// markdown source here, because these are closed enumerations, not prose an author
// edits. Adding a value is a deliberate code change, which is the point: an axis
// value that appears in a prompt, a prompt-builder, a stored idea and a filter needs
// to be one identifier, not a string four files each spell slightly differently.
//
// ── Why this file exists ─────────────────────────────────────────────────────
//
// `content_ideas.md` had one field called `Format` doing three unrelated jobs. Of 59
// ideas: 33 held a content type (Reel, Carousel, Trial Reel, Image Reel, Story Reel),
// 24 held a narrative shape (Save This List, Problem -> Fix, Quick Tip, POV), and 2
// were empty. A second field, `Best content type`, existed on only 24 of them, so
// which one was authoritative depended on which shape the author happened to use.
//
// Splitting the axes is what makes the pipeline decidable. `GenerationRecipe` below
// refuses a combination that cannot be produced, rather than quietly producing a
// Reel script for an idea filed as a Carousel.
//
// ── On NarrativeFormat ───────────────────────────────────────────────────────
//
// There is deliberately no `enum NarrativeFormat`. Narrative formats live in
// `format_handbook.dart` as `FormatSpec`, which is editable data synced from
// `content_formats.md`, and 38 more are planned. A parallel enum would have to be
// hand-edited in lockstep with the handbook on every addition, and the two would
// drift — which is the exact failure this refactor exists to remove. Use
// `FormatLibrary.byId` / `FormatLibrary.byName` instead, and `validateNarrativeFormat`
// below for a check with a good error message.
//
// ── Lexical scope ────────────────────────────────────────────────────────────
//
// PILAR, SERIES and NARRATIVE FORMAT describe what the content says. They are
// instructions to a writer and belong in the generation prompt.
//
// CONTENT TYPE and PRODUCTION METHOD describe what the app renders. They are
// rendering configuration and belong in the build pipeline, not in the creative
// prompt. `GenerationRecipe.renderSpec` is the split point.

import 'format_handbook.dart';

// ============================================================================
// PILLAR - what value the content gives
// ============================================================================

enum ContentPillar {
  play('PLAY', 'Activities kids can actually do'),
  think('THINK', 'Simple problem-solving challenges'),
  discover('DISCOVER', 'Things kids explore themselves'),
  talk('TALK', 'Questions, conversation prompts, language-building'),
  doIt('DO', 'Practical preschool skills and everyday independence');

  final String label;
  final String description;

  const ContentPillar(this.label, this.description);

  /// Named `doIt` because `do` is a Dart keyword and cannot be an enum member.
  ///
  /// The label stays `DO`, which is what appears in the prompt and in the markdown.
  /// Renaming the concept rather than the identifier was the alternative, and it
  /// would have put a keyword-shaped word into every stored idea and every prompt.
  static ContentPillar? byLabel(String label) {
    final lower = label.trim().toLowerCase();
    for (final p in ContentPillar.values) {
      if (p.label.toLowerCase() == lower || p.name.toLowerCase() == lower) return p;
    }
    return null;
  }

  static const Map<String, ContentPillar> _legacy = {
    'learning-through-play': ContentPillar.play,
    'parenting-relatability': ContentPillar.play,
    'relatability': ContentPillar.play,
  };

  /// Maps a retired pillar id onto the current set.
  static ContentPillar? fromLegacy(String id) =>
      _legacy[id.trim().toLowerCase().replaceAll('_', '-')];
}

// ============================================================================
// SERIES - recurring brand identity
// ============================================================================

enum ContentSeries {
  jugaaduMummy(
      'Jugaadu Mummy', 'Low-cost activities and parenting hacks'),
  lifeWithRiaRio(
      'Life With Ria & Rio', 'Everyday preschool problems'),
  canYourChildFigureItOut(
      'Can Your Child Figure It Out?', 'Interactive problem-solving content'),
  talkWithYourChild(
      'Talk With Your Child', 'Conversation starters'),
  tryThisAtHome('Try This At Home', 'Practical parent activities'),
  parentRelatable('Parent-Relatable', 'Funny preschool-parent moments'),
  ageBasedSkills('Age-Based Skills', 'Useful reference content');

  final String label;
  final String description;

  const ContentSeries(this.label, this.description);

  static ContentSeries? byLabel(String label) {
    final lower = label.trim().toLowerCase();
    for (final s in ContentSeries.values) {
      if (s.label.toLowerCase() == lower || s.name == lower) return s;
    }
    return null;
  }

  /// Retired series ids, and what they become.
  ///
  /// The ids are slugged, and the old vocabulary was slugs while the new one is enum
  /// names, so a migration that compared strings directly would have matched nothing.
  ///
  /// Three old ids have **no** correct target and are deliberately absent, so the
  /// validator reports them rather than guessing:
  ///
  /// - `learning-through-play` was a pillar, not a series. Its content is real; the
  ///   bucket it lived in was not a series identity.
  /// - `little-stories` was the retired "Little Stories, Big Lessons" name, which the
  ///   current direction moved away from.
  /// - `cuty-lessons` has no equivalent in the seven, and Cuty is a character, not a
  ///   series.
  /// - `the-casts` was an audience-voting series. `parentRelatable` would be a
  ///   plausible-looking answer and a wrong one: both its ideas optimise for comments,
  ///   not relatability, and folding them in would misfile them.
  ///
  /// `tool/check_ideas.dart` lists every unmappable idea rather than failing
  /// opaquely.
  static const Map<String, ContentSeries> _legacy = {
    'jugaadu-mummy': ContentSeries.jugaaduMummy,
    'jugaadu_mummy': ContentSeries.jugaaduMummy,
    'play-at-home': ContentSeries.tryThisAtHome,
    'play_at_home': ContentSeries.tryThisAtHome,
    'ria-adventures': ContentSeries.lifeWithRiaRio,
    'ria_adventures': ContentSeries.lifeWithRiaRio,
    'milestone-check': ContentSeries.ageBasedSkills,
    'milestone_check': ContentSeries.ageBasedSkills,
  };

  static ContentSeries? fromLegacy(String id) =>
      _legacy[id.trim().toLowerCase()];
}

// ============================================================================
// CONTENT TYPE - what is published
// ============================================================================

enum ContentType {
  reel('Reel', '9:16 video, 15-25 sec'),
  carousel('Carousel', 'Swipeable multi-slide feed post'),
  trialReel('Trial Reel', 'Fast-cut discovery Reel, judged on non-follower reach'),
  imageSlideshowReel(
      'Image Slideshow Reel', 'A story told through generated images'),
  staticImage('Static Image', 'One image with the full caption pack'),
  story('Story', 'Full-bleed 9:16 ephemeral frame');

  final String label;
  final String description;

  const ContentType(this.label, this.description);

  /// Matches the ids in `format_handbook.dart`'s `kContentTypeIds`.
  String get id => name;

  static ContentType? byLabel(String label) {
    final lower = label.trim().toLowerCase();
    for (final t in ContentType.values) {
      if (t.label.toLowerCase() == lower || t.name == lower) return t;
    }
    return null;
  }

  /// Content types the app cannot actually render yet.
  ///
  /// Both are reachable from `format_handbook.dart`, so this is reachable from a
  /// format recommendation too. Surfaced as a list rather than filtered, because a
  /// format that recommends an unproducible content type should be visible as a gap,
  /// not silently downgraded.
  static const Set<ContentType> unimplemented = {
    ContentType.imageSlideshowReel,
    ContentType.story,
  };

  static bool isImplemented(ContentType t) => !unimplemented.contains(t);
}

// ============================================================================
// PRODUCTION METHOD - how the asset is created
// ============================================================================

enum ProductionMethod {
  characterImages(
      'Character images', 'AI-generated character illustrations per scene'),
  realLifeVideo('Real-life video', 'Shot on camera, edited in the app'),
  imageSlideshow('Image slideshow', 'Stills paced over audio'),
  textBased('Text-based', 'Typography over a background'),
  carousel('Carousel', 'Multi-slide card layout'),
  mixed('Mixed', 'More than one method in one post');

  final String label;
  final String description;

  const ProductionMethod(this.label, this.description);

  static ProductionMethod? byLabel(String label) {
    final lower = label.trim().toLowerCase();
    for (final m in ProductionMethod.values) {
      if (m.label.toLowerCase() == lower || m.name == lower) return m;
    }
    return null;
  }

  /// Whether the app has a pipeline that produces this.
  ///
  /// `mixed` is the honest default for an idea with no stated method: an idea whose
  /// production is undecided is better served by a method the app can actually
  /// render than by one it cannot.
  static const Set<ProductionMethod> unimplemented = {
    ProductionMethod.mixed,
  };

  static bool isImplemented(ProductionMethod m) => !unimplemented.contains(m);
}

// ============================================================================
// GOAL
// ============================================================================

enum ContentGoal {
  reach('Reach', 'Broad distribution'),
  nonFollowerReach('Non-follower Reach', 'Discovery beyond the existing audience'),
  saves('Saves', 'Reference content a viewer returns to'),
  shares('Shares', 'Sent to another person'),
  comments('Comments', 'Conversation started'),
  relatability('Relatability', 'Recognition of a shared moment'),
  authority('Authority', 'Trusted on a subject'),
  follows('Follows', 'Profile visit leading to a follow');

  final String label;
  final String description;

  const ContentGoal(this.label, this.description);

  /// Matches the ids in `format_handbook.dart`'s `kGoalIds`.
  String get id => name;

  static ContentGoal? byLabel(String label) {
    final lower = label.trim().toLowerCase();
    for (final g in ContentGoal.values) {
      if (g.label.toLowerCase() == lower || g.name == lower) return g;
    }
    return null;
  }

  /// Retired goal names.
  ///
  /// `Engagement` and `Community` are the two that need a human decision rather than
  /// a mechanical one, so they are deliberately absent. Both sat on `the-casts` ideas
  /// whose whole point was audience participation; guessing `comments` for them would
  /// quietly change what those posts are optimising for.
  static const Map<String, ContentGoal> _legacy = {
    'reach': ContentGoal.reach,
    'saves': ContentGoal.saves,
    'shares': ContentGoal.shares,
    'followers': ContentGoal.follows,
    'authority': ContentGoal.authority,
  };

  static ContentGoal? fromLegacy(String id) =>
      _legacy[id.trim().toLowerCase()];
}

// ============================================================================
// STATUS - where the idea is in production
// ============================================================================

/// Production-aware, so `imagesReady` is distinguishable from `scripted`.
///
/// The earlier six-value ladder could not express the image-generation stage, which is
/// where a Ria/Rio/Cuty story Reel spends most of its time. An idea that is written
/// and one whose images exist are different states with different next actions.
enum IdeaStatus {
  idea('idea'),
  approved('approved'),
  scripted('scripted'),
  imagesReady('imagesReady'),
  generated('generated'),
  posted('posted'),
  tested('tested'),
  archived('archived');

  final String id;

  const IdeaStatus(this.id);

  static IdeaStatus? byId(String id) {
    final lower = id.trim().toLowerCase();
    for (final s in IdeaStatus.values) {
      if (s.id == lower || s.name == lower) return s;
    }
    return null;
  }

  /// Storage migration from the two older ladders.
  ///
  /// Two enums disagreed on the same names before this one: `reuse` versus `reused`,
  /// which made `values.byName` throw on the mismatch. This maps positionally instead
  /// of by name, so neither spelling can fail, and an unrecognised value falls back to
  /// [idea] rather than throwing — a status is not worth crashing a restore over.
  static IdeaStatus fromLegacy(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'idea':
      case 'draft':
      case 'inbox':
        return IdeaStatus.idea;
      case 'approved':
      case 'proposed':
      case 'ready':
        return IdeaStatus.approved;
      case 'scripted':
      case 'script':
      case 'developing':
        return IdeaStatus.scripted;
      case 'imagesready':
      case 'images':
        return IdeaStatus.imagesReady;
      case 'generated':
      case 'draft2':
        return IdeaStatus.generated;
      case 'posted':
      case 'published':
      case 'live':
        return IdeaStatus.posted;
      case 'tested':
      case 'reuse':
      case 'reused':
        return IdeaStatus.tested;
      case 'archived':
        return IdeaStatus.archived;
      default:
        return IdeaStatus.idea;
    }
  }
}

// ============================================================================
// NARRATIVE FORMAT - delegated to the handbook
// ============================================================================

/// Resolves a narrative format name to a registered [FormatSpec].
///
/// Returns null rather than defaulting. A silently substituted narrative format is
/// the worst outcome available here: the idea gets generated in a shape nobody chose,
/// posted, and its performance is filed against the wrong format — which is exactly
/// how a format gets wrongly retired after one test.
FormatSpec? validateNarrativeFormat(String name) =>
    FormatLibrary.byId(name) ?? FormatLibrary.byName(name);

// ============================================================================
// THE RECIPE - one idea, fully specified
// ============================================================================

class GenerationRecipe {
  final String id;
  final ContentPillar pillar;
  final ContentSeries series;
  final ContentType contentType;
  final FormatSpec narrativeFormat;
  final ProductionMethod productionMethod;
  final ContentGoal goal;
  final IdeaStatus status;
  final String topic;
  final String notes;

  const GenerationRecipe({
    required this.id,
    required this.pillar,
    required this.series,
    required this.contentType,
    required this.narrativeFormat,
    required this.productionMethod,
    required this.goal,
    this.status = IdeaStatus.idea,
    this.topic = '',
    this.notes = '',
  });

  /// The creative block: the axes that describe what the content *says*.
  ///
  /// Deliberately excludes content type and production method. Those describe what
  /// the app renders, and a model told "Content Type: Carousel" starts writing slide
  /// markers into the script, which then get narrated aloud by the voiceover.
  String get creativeSpec => '''
PILLAR: ${pillar.label} - ${pillar.description}
SERIES: ${series.label} - ${series.description}
NARRATIVE FORMAT: ${narrativeFormat.name} (${narrativeFormat.id})
GOAL: ${goal.label} - ${goal.description}${topic.isEmpty ? '' : '\nTOPIC: $topic'}''';

  /// The rendering block: the axes that describe what gets built.
  String get renderSpec => '''
Content type: ${contentType.label}
Production method: ${productionMethod.label}''';

  /// Whether the app can produce this combination end to end.
  ///
  /// Checked before generation rather than after, so an impossible combination is a
  /// clear message instead of a half-rendered post.
  List<String> get blockers {
    final issues = <String>[];
    if (!ContentType.isImplemented(contentType)) {
      issues.add('Content type "${contentType.label}" is not renderable yet '
          '(task T-14).');
    }
    if (!ProductionMethod.isImplemented(productionMethod)) {
      issues.add('Production method "${productionMethod.label}" has no pipeline '
          'yet.');
    }
    if (!narrativeFormat.supportsContentType(contentType.id)) {
      issues.add('Narrative format "${narrativeFormat.name}" does not list '
          '${contentType.label} as suitable. Override or change one.');
    }
    if (!narrativeFormat.servesGoal(goal.id)) {
      issues.add('Narrative format "${narrativeFormat.name}" is weak for '
          '${goal.label}.');
    }
    return issues;
  }

  bool get isGeneratable => blockers.isEmpty;
}

// ============================================================================
// VALIDATION REPORTING
// ============================================================================

/// One problem found on one idea.
class AxisIssue {
  final String ideaId;

  /// Which axis, or `null` for a whole-idea problem.
  final String? axis;
  final String message;

  /// `error` blocks generation. `warning` is a judgement call worth surfacing.
  final bool isError;

  const AxisIssue(this.ideaId, this.axis, this.message, {this.isError = true});

  @override
  String toString() {
    final where = axis == null ? ideaId : '$ideaId.$axis';
    return '${isError ? 'ERROR' : 'warn '} $where: $message';
  }
}

/// Collects issues so `tool/check_ideas.dart` can report all 59 at once.
///
/// A validator that stops at the first failure is worse than none here: the whole
/// point of migrating a library by hand is seeing the complete list of decisions a
/// human still has to make.
class AxisValidator {
  final List<AxisIssue> issues = [];

  void error(String id, String? axis, String message) =>
      issues.add(AxisIssue(id, axis, message));

  void warn(String id, String? axis, String message) =>
      issues.add(AxisIssue(id, axis, message, isError: false));

  bool get hasErrors => issues.any((i) => i.isError);
  bool get hasWarnings => issues.any((i) => !i.isError);
  int get errorCount => issues.where((i) => i.isError).length;
  int get warningCount => issues.where((i) => !i.isError).length;
}