/// Content-collection grouping for browsing ideas by theme.
///
/// This file does NOT modify HookIdea, QuickIdea, or any stored data.
/// It is a read-only mapping from idea id → collection id, used only for
/// grouping in list views.

/// One thematic collection the user can browse ideas by.
class IdeaCollection {
  final String id;
  final String label;
  final String emoji;
  const IdeaCollection(this.id, this.label, this.emoji);
  const IdeaCollection._(this.id, this.label, this.emoji);
}

const kCollections = <IdeaCollection>[
  IdeaCollection._('robot', 'Ria & Robot', '🤖'),
  IdeaCollection._('festivals', 'Festivals & Events', '🪔'),
  IdeaCollection._('routines', 'Morning & Bedtime Routines', '🌙'),
  IdeaCollection._('food', 'Food & Mealtime', '🍽️'),
  IdeaCollection._('tantrums', 'Tantrums & Big Feelings', '😤'),
  IdeaCollection._('siblings', 'Siblings & Sharing', '👫'),
  IdeaCollection._('parent', 'Parent Moments', '😂'),
  IdeaCollection._('warm', 'Warm Lessons', '❤️'),
  IdeaCollection._('play', 'Play & Learning', '🧩'),
  IdeaCollection._('guides', 'Parent Guides', '🗣️'),
  IdeaCollection._('missions', '7 Missions Week', '🏁'),
  IdeaCollection._('milestones', 'Milestones & Community', '🎉'),
  IdeaCollection._('safety', 'Kids Safety', '🛡️'),
  IdeaCollection._('mine', 'My Ideas', '✏️'),
];

/// Maps collection id → display metadata.
final Map<String, IdeaCollection> kCollectionById = {
  for (final c in kCollections) c.id: c,
};

/// Members of each collection, excluding items handled by rules
/// (robot prefix, navratri prefix, day15-day25 regex).
const Map<String, List<String>> _members = {
  'routines': [
    'h01', 'h04', 'h05', 'h07', 'h09', 'h12',
    'pal06', 'pal07', 'pal09', 'pal12',
    'shoe-bandhani', 'brushing-battle', 'missing-shoe-mystery',
  ],
  'food': [
    'h08', 'vegetable-drama', 'plate-patana',
    'broken-biscuit-meltdown', 'the-snack-reach',
    'day12-dinner-types',
  ],
  'tantrums': [
    'h02', 'h03', 'h10', 'h11', 'h13', 'h15', 'h17',
    'pal03', 'pal04', 'pal13', 'pal14', 'park-se-nikalna',
  ],
  'siblings': [
    'h06', 'h14', 'pal18',
    'toy-sharing', 'the-toy-car-share', 'the-block-tower',
  ],
  'parent': [
    'h16', 'h19',
    'pal01', 'pal02', 'pal05', 'pal08', 'pal11', 'pal15',
    'pal16', 'pal19',
    'dangerous-silence', 'asmr-cleaning-reel',
    'day3-mumma-says', 'day7-toddler-math',
  ],
  'warm': [
    'h18', 'h20', 'h21',
    'pal10', 'pal17', 'pal20',
  ],
  'play': [
    'day2-which-doesnt-belong', 'day4-kitchen-challenge',
    'day8-find-cuty', 'day9-sock-hunt', 'day13-pattern-game',
  ],
  'guides': [
    'day5-ask-tonight', 'day6-3year-skills',
    'day10-3-questions', 'day11-4year-skills',
  ],
  'milestones': [
    'p01', 'p02', 'p03', 'p04', 'p05', 'p06', 'p07', 'p08',
    'day14-favorite-format',
  ],
  'safety': [
    'safety-good-touch', 'safety-stranger', 'safety-road',
    'safety-emergency-number', 'safety-lost-crowd', 'safety-kitchen-line',
  ],
};

/// Reverse lookup: idea id → collection id.
final Map<String, String> _collectionById = {
  for (final e in _members.entries)
    for (final id in e.value) id: e.key,
};

/// Assigns a collection id to any idea.
///
/// Rules:
/// 1. Custom ideas (added by user) → 'mine'
/// 2. Robot series → 'robot'
/// 3. Navratri posts + Annual Day night → 'festivals'
/// 4. Day 15–25 posts → 'missions'
/// 5. Anything in [_members] → its mapped collection
/// 6. Everything else → 'mine' (so it is never lost)
String collectionOf(String id, {bool custom = false}) {
  if (custom) return 'mine';
  if (id.startsWith('robot-')) return 'robot';
  if (id.startsWith('navratri-') || id == 'night-before-annual-day') {
    return 'festivals';
  }
  if (RegExp(r'^day(1[5-9]|2[0-5])-').hasMatch(id)) return 'missions';
  return _collectionById[id] ?? 'mine';
}

/// Returns the list of idea ids mapped to [collectionId], or empty if none.
List<String> ideaIdsInCollection(String collectionId) => [
      for (final e in _members.entries)
        if (e.key == collectionId) ...e.value,
    ];
