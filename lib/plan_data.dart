import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

// ── The content plan, kept on the phone ───────────────────────────────────────
//
// Three things that used to live in chat windows and get lost: the hooks worth using,
// when to post, and how each post actually did. All three are written to the phone and
// go into the Downloads backup with the stories, so a reinstall keeps them.
//
// The posting times are a starting guess, not a fact, and the results log is what
// turns them into one. Nobody outside Instagram knows when your followers are awake;
// your own numbers after a few weeks will.

/// Called after any hook, schedule or result is saved, so the Downloads backup picks
/// it up. Set once at startup rather than imported, because the backup code already
/// imports this file and the two importing each other would tie them in a knot.
void Function()? onPlanSaved;

// ── Hooks ─────────────────────────────────────────────────────────────────────

class HookIdea {
  final String id;
  final String category;
  /// Two to four words for the cover. Short on purpose: longer stops being a hook
  /// and starts being a sentence nobody reads at thumbnail size.
  final String cover;
  /// The first line said out loud, in the first three seconds.
  final String opening;
  /// The real preschool problem the story is built on.
  final String problem;
  final String lesson;
  /// False for posts the app cannot make — milestones and behind-the-scenes need your
  /// own screen recordings, not an illustrated story.
  final bool forApp;
  /// When it was last used, so the same hook does not go out twice in a month.
  final String usedOn;
  /// True for one you added yourself. Built-in ones can be edited but not deleted,
  /// so an update that adds new ones never fights with your changes.
  final bool custom;

  const HookIdea({
    required this.id,
    required this.category,
    required this.cover,
    required this.opening,
    required this.problem,
    required this.lesson,
    this.forApp = true,
    this.usedOn = '',
    this.custom = false,
  });

  HookIdea copyWith({String? cover, String? opening, String? problem, String? lesson,
      String? category, String? usedOn}) =>
      HookIdea(
        id: id,
        category: category ?? this.category,
        cover: cover ?? this.cover,
        opening: opening ?? this.opening,
        problem: problem ?? this.problem,
        lesson: lesson ?? this.lesson,
        forApp: forApp,
        usedOn: usedOn ?? this.usedOn,
        custom: custom,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'category': category, 'cover': cover, 'opening': opening,
        'problem': problem, 'lesson': lesson, 'forApp': forApp,
        'usedOn': usedOn, 'custom': custom,
      };

  factory HookIdea.fromJson(Map<String, dynamic> j) => HookIdea(
        id: j['id'] as String? ?? '',
        category: j['category'] as String? ?? 'Relatable',
        cover: j['cover'] as String? ?? '',
        opening: j['opening'] as String? ?? '',
        problem: j['problem'] as String? ?? '',
        lesson: j['lesson'] as String? ?? '',
        forApp: j['forApp'] as bool? ?? true,
        usedOn: j['usedOn'] as String? ?? '',
        custom: j['custom'] as bool? ?? false,
      );

  /// Laid out as the story form, ready for Write the script.
  String asStoryText() => 'Cover hook: $cover\n'
      'Hook: $opening\n'
      'Who: Ria, Rio, Cuty\n'
      'Where:\n'
      'What starts it: $problem\n'
      'What goes wrong:\n'
      'How it gets worse:\n'
      'How it is solved:\n'
      'Ending line:\n'
      'Moral: $lesson';
}

const kHookCategories = [
  'Relatable', 'Struggle first', 'Surprising', 'Warm lesson', 'Page & milestone',
];

/// The starting list. Merged from several AI suggestions and cut down hard: the same
/// three problems (screen time, shoes, toy fights) appeared four or five times each,
/// and several were written as "I" — a parent speaking — when the reels are told by a
/// storyteller about Ria and Rio.
const kDefaultHooks = <HookIdea>[
  // Relatable: the child's own words, the thing every parent has heard this week.
  HookIdea(id: 'h01', category: 'Relatable', cover: 'Main Khud Karungi!',
    opening: 'Ria ne Mumma ka haath jhatak diya... joote khud pehnenge!',
    problem: 'Ria insists on putting her shoes on herself and pushes Mumma away',
    lesson: 'Thoda intezaar, aur bachcha khud seekh jaata hai'),
  HookIdea(id: 'h02', category: 'Relatable', cover: 'Bas 5 Minute Aur?!',
    opening: 'Phone band hua... aur Ria ka rona shuru!',
    problem: 'Ria melts down when screen time ends suddenly',
    lesson: 'Achanak nahi, pehle se bataakar band karo'),
  HookIdea(id: 'h03', category: 'Relatable', cover: 'Mujhe Nahi Aata!',
    opening: 'Rio ka tower teesri baar gira... aur usne haar maan li.',
    problem: 'Rio gives up when his block tower keeps falling',
    lesson: 'Galti se hi seekhte hain, phir se try karo'),
  HookIdea(id: 'h04', category: 'Relatable', cover: 'Cuty Kahan Gaya?!',
    opening: 'Poore kamre mein khilone... aur Cuty gayab!',
    problem: 'Cuty is lost in the messy room; tidying turns into a treasure hunt',
    lesson: 'Saaf kamra, sab kuch saamne'),
  HookIdea(id: 'h05', category: 'Relatable', cover: 'Ek Aur Paani!',
    opening: 'Lights band... aur Ria ko phir se paani chahiye.',
    problem: 'Bedtime stretches on with one more water, one more story, one more hug',
    lesson: 'Roz ek jaisa routine, neend jaldi aati hai'),
  HookIdea(id: 'h06', category: 'Relatable', cover: 'Meri Car Hai!',
    opening: 'Ria aur Rio ne car do taraf se kheenchi...',
    problem: 'Ria and Rio fight over one toy car',
    lesson: 'Baari baari khelne mein sabka mazaa'),
  HookIdea(id: 'h07', category: 'Relatable', cover: 'Brush Nahi Karungi!',
    opening: 'Ria kambal ke andar chhup gayi... brush ke dar se!',
    problem: 'Ria hides under the blanket to avoid brushing her teeth',
    lesson: 'Khel banao, zidd khud chali jaati hai'),
  HookIdea(id: 'h08', category: 'Relatable', cover: 'Broccoli? Bilkul Nahi!',
    opening: 'Plate aage aayi... aur Ria ne haath baandh liye.',
    problem: 'Ria refuses vegetables at the table',
    lesson: 'Khud banaya khaana, khud khaane ka mann'),
  HookIdea(id: 'h09', category: 'Relatable', cover: 'Apne Kapde Khud!',
    opening: 'Garmi mein bhi Ria ko winter boots hi pehenne hain!',
    problem: 'Ria wants to choose her own mismatched outfit',
    lesson: 'Chhote faisle, bada confidence'),

  // New built-in content ideas from Palak's marketing and character plan.
  HookIdea(id: 'pal01', category: 'Relatable', cover: 'Which Kid Is Yours?',
    opening: 'Ria = tofani, Rio = ziddi, Cuty = sleep lover.',
    problem: 'Parents want to recognise their child in a playful character style',
    lesson: 'Every child has a personality and every family sees themselves in it'),
  HookIdea(id: 'pal02', category: 'Relatable', cover: '7 Things Every Toddler Does',
    opening: 'Says no, wants the same spoon, and suddenly needs Mumma.',
    problem: 'Parents need a humorous way to see their own daily chaos reflected back',
    lesson: 'The tiny behaviours are the funny little signs of childhood'),
  HookIdea(id: 'pal03', category: 'Relatable', cover: 'When Mumma Says No',
    opening: 'Ria protests, Rio refuses, Cuty quietly quietly gives in.',
    problem: 'The same parent boundary can trigger three very different reactions',
    lesson: 'Kids react differently, but all of them need patience and clarity'),
  HookIdea(id: 'pal04', category: 'Relatable', cover: '5 Minute Warning!',
    opening: 'Five minutes left and suddenly every child hears a different story.',
    problem: 'Screen time transitions create a dramatic meltdown in most homes',
    lesson: 'Warning helps, but a gentle transition still matters most'),
  HookIdea(id: 'pal05', category: 'Relatable', cover: 'Things Kids Say',
    opening: 'Mumma, I am not sleepy and then five seconds later, snores.',
    problem: 'Kids say the funniest things right before bedtime and during chaos',
    lesson: 'A little laughter makes the hard moments easier to handle'),
  HookIdea(id: 'pal06', category: 'Relatable', cover: 'Morning Personalities',
    opening: 'Ria wakes up ready to play, Rio wants five more minutes, and Cuty is still sleeping.',
    problem: 'Morning energy can look very different across siblings and personalities',
    lesson: 'The family routine works better when personalities are respected'),
  HookIdea(id: 'pal07', category: 'Relatable', cover: 'Ready to Go?',
    opening: 'One child is ready, one is searching for a toy, and one is still half asleep.',
    problem: 'Leaving the house is a daily family-level circus',
    lesson: 'A little planning makes the morning calmer for everyone'),
  HookIdea(id: 'pal08', category: 'Relatable', cover: 'Mumma\'s Little Detective',
    opening: 'Who did it? Toys everywhere, crumbs on the floor, and one very innocent rabbit.',
    problem: 'Kids create chaos and then deny it with talent',
    lesson: 'The grown-up always knows, even when they try to act innocent'),
  HookIdea(id: 'pal09', category: 'Warm lesson', cover: 'Main Khud Karungi',
    opening: 'Let me do it myself and I will do it my way.',
    problem: 'Kids want independence even when the task is small',
    lesson: 'Support effort and trust them to learn through trying'),
  HookIdea(id: 'pal10', category: 'Warm lesson', cover: 'Little Things Kids Remember',
    opening: 'The bedtime story, the silly dance, the hug after a bad day.',
    problem: 'Parents often forget that tiny everyday moments become the memories children hold',
    lesson: 'Love is built in the little, repeated moments of the day'),
  HookIdea(id: 'pal11', category: 'Relatable', cover: 'At The Supermarket',
    opening: 'Ria wants everything, Rio wants the toy, Cuty is already ready to go home.',
    problem: 'Shopping turns into a mini-lesson in patience, negotiation and excitement',
    lesson: 'Every child brings a different energy into the same space'),
  HookIdea(id: 'pal12', category: 'Relatable', cover: 'Bedtime Personalities',
    opening: 'One child wants one more story, one wants one more screen, one is already asleep.',
    problem: 'Bedtime is always different inside the same house',
    lesson: 'Night routines work best when they match the child who is in them'),
  HookIdea(id: 'pal13', category: 'Struggle first', cover: 'Toy Broke!',
    opening: 'The toy breaks, everyone reacts differently, and then they learn together.',
    problem: 'Small losses feel huge when a child is attached to a favourite thing',
    lesson: 'A bad moment can become a calm lesson if we slow down and help'),
  HookIdea(id: 'pal14', category: 'Warm lesson', cover: 'Big Feelings, Little Problems',
    opening: 'To a child, a broken biscuit or a missing sock feels enormous.',
    problem: 'Little problems can feel huge when your child is overwhelmed',
    lesson: 'What seems small to us is often a big emotion to them'),
  HookIdea(id: 'pal15', category: 'Surprising', cover: 'Ria\'s House Rules',
    opening: 'Ria\'s five rules for fun, chaos and completely valid family drama.',
    problem: 'Kids often create their own rules and logic in the middle of daily life',
    lesson: 'Playful routines and family humour keep the home feeling lighter'),
  HookIdea(id: 'pal16', category: 'Surprising', cover: 'Rio\'s Vocabulary',
    opening: 'Rio\'s top words are no, mine, why, and one more time.',
    problem: 'The toddler vocabulary is often very short but very intense',
    lesson: 'A little repetition and a lot of parenting grace go a long way'),
  HookIdea(id: 'pal17', category: 'Warm lesson', cover: 'Cuty Knows Best',
    opening: 'Cuty believes in naps, calm, and never rushing through life.',
    problem: 'Some children are highly sensitive to noise, pressure and movement',
    lesson: 'Rest and calm are not lazy; they are part of healthy growth'),
  HookIdea(id: 'pal18', category: 'Relatable', cover: 'One House, Three Kids',
    opening: 'Same house, different universes: Ria, Rio and Cuty all live in their own rhythm.',
    problem: 'Each child has a different personality, energy level and way of reacting',
    lesson: 'Family life works when we learn to love the differences, not fight them'),
  HookIdea(id: 'pal19', category: 'Relatable', cover: 'Mumma Says This Daily',
    opening: 'Put your shoes on, stop running, where is your bottle, and come here.',
    problem: 'Parents repeat the same phrases each day because the day repeats itself',
    lesson: 'Even the hard repeated words are part of the family rhythm'),
  HookIdea(id: 'pal20', category: 'Warm lesson', cover: 'Parent Memory',
    opening: 'One day they won\'t ask you to carry them, and they won\'t need the same little routines.',
    problem: 'Parents need a reminder to value the current chaos before it changes',
    lesson: 'Enjoy the little moments while they are still happening'),

  // Struggle first: open on the moment it goes wrong. Struggle stops the scroll; the
  // warm ending is what earns the save.
  HookIdea(id: 'h10', category: 'Struggle first', cover: '1 Galti, Bada Mess!',
    opening: 'Rio ke haath se saare rang gir gaye...',
    problem: 'Rio spills paint everywhere by accident',
    lesson: 'Galti pe gussa nahi, saath mein saaf karo'),
  HookIdea(id: 'h11', category: 'Struggle first', cover: 'Tower Gir Gaya!',
    opening: 'Rio zameen pe lot gaya... sirf blocks ke liye?',
    problem: 'Rio has a big tantrum when his tower breaks',
    lesson: 'Pehle gale lagao, phir samjhao'),
  HookIdea(id: 'h12', category: 'Struggle first', cover: 'Subah Ka Drama',
    opening: 'School ka time... aur Ria abhi tak bistar mein!',
    problem: 'Morning school prep turns into a battle',
    lesson: 'Jaldbaazi kam, zidd bhi kam'),
  HookIdea(id: 'h13', category: 'Struggle first', cover: 'Suno Na, Ria!',
    opening: 'Mumma teesri baar bulaa rahi hain... Ria sun hi nahi rahi.',
    problem: 'Ria ignores instructions called from across the room',
    lesson: 'Paas jaakar, aankhon mein dekhkar bolo'),
  HookIdea(id: 'h14', category: 'Struggle first', cover: 'Tod Diya!',
    opening: 'Car ke do tukde... aur dono ek doosre ko blame kar rahe hain.',
    problem: 'The shared toy breaks and both children blame each other',
    lesson: 'Kaun jeeta nahi, saath mein kaise theek karein'),

  // Surprising: says the opposite of what a parent expects, then shows it.
  HookIdea(id: 'h15', category: 'Surprising', cover: 'Phone Asli Problem Nahi',
    opening: 'Ria ko phone se nahi, phone chhinne se gussa aata hai.',
    problem: 'The upset is about the sudden stop, not the screen itself',
    lesson: 'Timer lagao, badlaav aasaan ho jaata hai'),
  HookIdea(id: 'h16', category: 'Surprising', cover: 'Dabba Ban Gaya Rocket!',
    opening: 'Itne saare khilone... aur Rio ko chahiye khaali dabba?',
    problem: 'Expensive toys are ignored; an empty box becomes a spaceship',
    lesson: 'Kam khilone, zyada kalpana'),
  HookIdea(id: 'h17', category: 'Surprising', cover: 'Mumma Ne NO Kyun Bola?',
    opening: 'Baarish mein bahar jaana tha... Mumma ne mana kar diya!',
    problem: 'Ria thinks Mumma is mean for saying no to playing in the rain',
    lesson: 'NO ka matlab kabhi nahi — kabhi kabhi bas ruko'),
  HookIdea(id: 'h18', category: 'Surprising', cover: 'Tumne Khud Kiya!',
    opening: 'Ria ko "good girl" nahi... kuch aur sunna tha.',
    problem: 'Praising the effort instead of calling the child good',
    lesson: 'Mehnat ki taareef, himmat badhaati hai'),
  HookIdea(id: 'h19', category: 'Surprising', cover: 'Bhaago Mat? Dheere Chalo!',
    opening: 'Mumma ne "mat bhaago" bola... Rio aur tez bhaaga!',
    problem: 'A child ignores "don\'t" but follows a clear "do"',
    lesson: 'Kya nahi karna, nahi — kya karna hai, woh batao'),

  // Warm lesson: gentle stories that end on something a parent wants to keep.
  HookIdea(id: 'h20', category: 'Warm lesson', cover: 'Pyaar Bhi, Rule Bhi',
    opening: 'Rio ne phir se rule toda... par Mumma ne chillaaya nahi.',
    problem: 'Holding a boundary kindly instead of giving in or shouting',
    lesson: 'Pyaar ke saath rule, bachcha safe mehsoos karta hai'),
  HookIdea(id: 'h21', category: 'Warm lesson', cover: 'Ria Ne Samjhaaya',
    opening: 'Aaj Ria ne Mumma ko ek baat sikha di...',
    problem: 'A small child says something that makes the adult rethink',
    lesson: 'Bachche humse zyada samajhte hain'),

  // Page posts: need your own footage, so the app lists them but cannot build them.
  HookIdea(id: 'p01', category: 'Page & milestone', forApp: false,
    cover: '1,000 Ke Paas!',
    opening: 'Ruko... hum 1,000 dost hone wale hain?!',
    problem: 'Milestone reel as you approach 1,000 followers',
    lesson: 'Thank the parents who came first'),
  HookIdea(id: 'p02', category: 'Page & milestone', forApp: false,
    cover: '1,000 Dost!',
    opening: 'Aaj Ria, Rio aur Cuty ke 1,000 dost ho gaye.',
    problem: 'Thank-you reel on reaching 1,000',
    lesson: 'A place in your feed means a lot'),
  HookIdea(id: 'p03', category: 'Page & milestone', forApp: false,
    cover: 'Ek Reel Kaise Banti Hai',
    opening: '30 second ki ek kahani ke peeche kitna kaam hai...',
    problem: 'Behind the scenes of making one story',
    lesson: 'Shows the care that goes into every story'),
  HookIdea(id: 'p04', category: 'Page & milestone', forApp: false,
    cover: 'Jab Humne Shuru Kiya',
    opening: 'Pehli kahani post ki thi... pata nahi tha koi dekhega bhi.',
    problem: 'How the page started',
    lesson: 'Honest start builds trust'),
];

class HookStore {
  static const _file = 'hooks.json';

  /// Your list: built-in hooks with your edits applied, then the ones you added.
  /// New built-in hooks from an update appear without touching anything you changed.
  static Future<List<HookIdea>> load() async {
    final saved = <String, HookIdea>{};
    try {
      final f = await _path(_file);
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is List) {
          for (final e in raw.whereType<Map<String, dynamic>>()) {
            final h = HookIdea.fromJson(e);
            if (h.id.isNotEmpty) saved[h.id] = h;
          }
        }
      }
    } catch (_) {}

    return [
      ...kDefaultHooks.map((d) => saved[d.id] ?? d),
      ...saved.values.where((h) => h.custom),
    ];
  }

  static Future<void> save(List<HookIdea> hooks) async {
    try {
      final f = await _path(_file);
      await f.writeAsString(jsonEncode(hooks.map((h) => h.toJson()).toList()));
    } catch (_) {}
    // Hooks, times and results belong in the backup too; see onPlanSaved.
    onPlanSaved?.call();
  }

  static Future<void> markUsed(String id) async {
    final all = await load();
    await save(all.map((h) => h.id == id
        ? h.copyWith(usedOn: DateTime.now().toIso8601String()) : h).toList());
  }
}

// ── When to post ──────────────────────────────────────────────────────────────

class PostSlot {
  /// 1 is Monday, 7 is Sunday, matching DateTime.weekday.
  final int weekday;
  /// "13:30" in 24-hour time.
  final String first;
  final String backup;
  final String focus;
  const PostSlot(this.weekday, this.first, this.backup, this.focus);

  Map<String, dynamic> toJson() =>
      {'weekday': weekday, 'first': first, 'backup': backup, 'focus': focus};
  factory PostSlot.fromJson(Map<String, dynamic> j) => PostSlot(
        (j['weekday'] as num?)?.toInt() ?? 1,
        j['first'] as String? ?? '13:30',
        j['backup'] as String? ?? '20:45',
        j['focus'] as String? ?? '');
}

const kDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Built around a parent of a 2 to 6 year old rather than an office worker: the
/// afternoon lull after school pick-up and lunch, and the half hour after the children
/// are asleep. A reasoned guess — the results log is what should replace it.
const kDefaultSchedule = <PostSlot>[
  PostSlot(1, '13:30', '20:45', 'Everyday problem story'),
  PostSlot(2, '14:00', '21:00', 'Routine story'),
  PostSlot(3, '13:30', '20:45', 'Most relatable story of the week'),
  PostSlot(4, '14:00', '20:45', 'Gentle lesson story'),
  PostSlot(5, '13:30', '21:15', 'Light, funny story'),
  PostSlot(6, '10:30', '21:30', 'Fun or chaos story'),
  PostSlot(7, '11:00', '20:30', 'Warm story with a question for parents'),
];

class ScheduleStore {
  static const _file = 'schedule.json';

  static Future<List<PostSlot>> load() async {
    try {
      final f = await _path(_file);
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is List && raw.length == 7) {
          return raw.whereType<Map<String, dynamic>>().map(PostSlot.fromJson).toList();
        }
      }
    } catch (_) {}
    return List.of(kDefaultSchedule);
  }

  static Future<void> save(List<PostSlot> slots) async {
    try {
      await (await _path(_file))
          .writeAsString(jsonEncode(slots.map((s) => s.toJson()).toList()));
    } catch (_) {}
    // Hooks, times and results belong in the backup too; see onPlanSaved.
    onPlanSaved?.call();
  }
}

/// The next posting time from now, in words: "Today 8:45 PM" or "Tomorrow 1:30 PM".
String nextPostingTime(List<PostSlot> schedule, [DateTime? from]) {
  final now = from ?? DateTime.now();
  for (var offset = 0; offset < 8; offset++) {
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
    final slot = schedule.firstWhere((s) => s.weekday == day.weekday,
        orElse: () => kDefaultSchedule[day.weekday - 1]);
    for (final t in [slot.first, slot.backup]) {
      final parts = t.split(':');
      final at = day.add(Duration(
        hours: int.tryParse(parts.first) ?? 0,
        minutes: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0));
      if (at.isAfter(now)) {
        final when = offset == 0 ? 'Today' : offset == 1 ? 'Tomorrow' : kDayNames[day.weekday - 1];
        return '$when ${formatClock(t)} — ${slot.focus}';
      }
    }
  }
  return '';
}

/// "20:45" → "8:45 PM".
String formatClock(String hhmm) {
  final parts = hhmm.split(':');
  var h = int.tryParse(parts.first) ?? 0;
  final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  final pm = h >= 12;
  h = h % 12 == 0 ? 12 : h % 12;
  return '$h:$m ${pm ? 'PM' : 'AM'}';
}

// ── How each post did ─────────────────────────────────────────────────────────

class PostRecord {
  final String id;
  final String title;
  final String projectId;
  final String hookId;
  final DateTime postedAt;
  /// Filled in by hand from Instagram a day or two after posting. Zero means not yet.
  final int views, likes, comments, saves, shares;

  const PostRecord({
    required this.id,
    required this.title,
    required this.postedAt,
    this.projectId = '',
    this.hookId = '',
    this.views = 0, this.likes = 0, this.comments = 0, this.saves = 0, this.shares = 0,
  });

  PostRecord copyWith({DateTime? postedAt, int? views, int? likes, int? comments,
      int? saves, int? shares}) =>
      PostRecord(
        id: id, title: title, projectId: projectId, hookId: hookId,
        postedAt: postedAt ?? this.postedAt,
        views: views ?? this.views, likes: likes ?? this.likes,
        comments: comments ?? this.comments, saves: saves ?? this.saves,
        shares: shares ?? this.shares,
      );

  bool get hasResults => views > 0;

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'projectId': projectId, 'hookId': hookId,
        'postedAt': postedAt.toIso8601String(),
        'views': views, 'likes': likes, 'comments': comments,
        'saves': saves, 'shares': shares,
      };

  factory PostRecord.fromJson(Map<String, dynamic> j) => PostRecord(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        projectId: j['projectId'] as String? ?? '',
        hookId: j['hookId'] as String? ?? '',
        postedAt: DateTime.tryParse(j['postedAt'] as String? ?? '') ?? DateTime.now(),
        views: (j['views'] as num?)?.toInt() ?? 0,
        likes: (j['likes'] as num?)?.toInt() ?? 0,
        comments: (j['comments'] as num?)?.toInt() ?? 0,
        saves: (j['saves'] as num?)?.toInt() ?? 0,
        shares: (j['shares'] as num?)?.toInt() ?? 0,
      );
}

class PostLogStore {
  static const _file = 'posts.json';

  static Future<List<PostRecord>> load() async {
    try {
      final f = await _path(_file);
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is List) {
          final out = raw.whereType<Map<String, dynamic>>().map(PostRecord.fromJson).toList()
            ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
          return out;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<void> save(List<PostRecord> posts) async {
    try {
      await (await _path(_file))
          .writeAsString(jsonEncode(posts.map((p) => p.toJson()).toList()));
    } catch (_) {}
    // Hooks, times and results belong in the backup too; see onPlanSaved.
    onPlanSaved?.call();
  }

  static Future<void> add(PostRecord post) async {
    final all = await load();
    await save([post, ...all]);
  }
}

/// A time of day a post went out in, broad enough that a handful of posts can say
/// something. By the hour, a month of posting would still be one post per bucket.
String timeBucket(DateTime t) {
  final h = t.hour;
  if (h < 6) return 'Late night (12–6 AM)';
  if (h < 11) return 'Morning (6–11 AM)';
  if (h < 16) return 'Afternoon (11 AM–4 PM)';
  if (h < 20) return 'Evening (4–8 PM)';
  return 'Night (8 PM–12 AM)';
}

class BucketResult {
  final String bucket;
  final int posts;
  final double avgViews, avgSaves, avgComments, avgShares;
  const BucketResult(this.bucket, this.posts, this.avgViews, this.avgSaves,
      this.avgComments, this.avgShares);
}

/// Average results per time of day, best first, from posts with numbers filled in.
List<BucketResult> resultsByTime(List<PostRecord> posts) {
  final groups = <String, List<PostRecord>>{};
  for (final p in posts.where((p) => p.hasResults)) {
    groups.putIfAbsent(timeBucket(p.postedAt), () => []).add(p);
  }
  double avg(List<PostRecord> g, int Function(PostRecord) f) =>
      g.map(f).fold<int>(0, (a, b) => a + b) / g.length;

  return groups.entries
      .map((e) => BucketResult(e.key, e.value.length,
          avg(e.value, (p) => p.views), avg(e.value, (p) => p.saves),
          avg(e.value, (p) => p.comments), avg(e.value, (p) => p.shares)))
      .toList()
    ..sort((a, b) => b.avgViews.compareTo(a.avgViews));
}

Future<File> _path(String name) async =>
    File('${(await getApplicationDocumentsDirectory()).path}/$name');
