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

/// Members of each collection.
///
/// Every built-in idea id (idea_1 through idea_116) is listed here so the
/// collection is always resolvable without fragile prefix rules.
const Map<String, List<String>> _members = {
  'safety': [
    'idea_1', 'idea_2', 'idea_3', 'idea_4', 'idea_5', 'idea_6',
  ],
  'robot': [
    'idea_59', 'idea_60', 'idea_61', 'idea_62', 'idea_63', 'idea_64',
    'idea_65', 'idea_66', 'idea_67', 'idea_68', 'idea_69', 'idea_70',
    'idea_71',
  ],
  'festivals': [
    'idea_41', 'idea_42', 'idea_43', 'idea_44', 'idea_45', 'idea_46',
    'idea_47', 'idea_48', 'idea_49',
    'idea_54',
    'idea_diwali_shopping_papa',
    'idea_76', 'idea_77', 'idea_78',
  ],
  'routines': [
    'idea_7', 'idea_10', 'idea_11', 'idea_12', 'idea_18', 'idea_19',
    'idea_23', 'idea_32', 'idea_57',
  ],
  'food': [
    'idea_13', 'idea_50', 'idea_53', 'idea_58', 'idea_103',
  ],
  'tantrums': [
    'idea_8', 'idea_9', 'idea_16', 'idea_24', 'idea_25', 'idea_30',
    'idea_31', 'idea_34', 'idea_73',
  ],
  'siblings': [
    'idea_29', 'idea_33', 'idea_51', 'idea_52',
  ],
  'parent': [
    'idea_14', 'idea_15', 'idea_17', 'idea_20', 'idea_22', 'idea_26',
    'idea_27', 'idea_35', 'idea_36', 'idea_38', 'idea_55', 'idea_56',
    'idea_72', 'idea_74', 'idea_75', 'idea_79', 'idea_80', 'idea_82',
    'idea_83', 'idea_84', 'idea_86', 'idea_89', 'idea_90', 'idea_91',
    'idea_92', 'idea_94', 'idea_98',
  ],
  'warm': [
    'idea_21', 'idea_28', 'idea_37', 'idea_39', 'idea_40', 'idea_81',
    'idea_85', 'idea_87', 'idea_88',
  ],
  'play': [
    'idea_93', 'idea_95', 'idea_99', 'idea_100', 'idea_104',
  ],
  'guides': [
    'idea_96', 'idea_97', 'idea_101', 'idea_102',
  ],
  'missions': [
    'idea_106', 'idea_107', 'idea_108', 'idea_109', 'idea_110',
    'idea_111', 'idea_112', 'idea_113', 'idea_114', 'idea_115',
    'idea_116',
  ],
  'milestones': [
    'idea_105',
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
/// 2. Anything in [_members] → its mapped collection
/// 3. Everything else → 'mine' (so it is never lost)
String collectionOf(String id, {bool custom = false}) {
  if (custom) return 'mine';
  return _collectionById[id] ?? 'mine';
}

/// Returns the list of idea ids mapped to [collectionId], or empty if none.
List<String> ideaIdsInCollection(String collectionId) => [
      for (final e in _members.entries)
        if (e.key == collectionId) ...e.value,
    ];
