// -- Every Content Idea, In One Place --------------------------------------------
//
// The hook library, the ready-made post packages, and the bulk paste parser all
// live here now. They used to sit in two files (plan_data.dart and
// day14_posts.dart) and between them they had drifted apart: the posts carried
// their own ContentBucket class and their own bucket ids, four of which did not
// exist in the library the rest of the app reads. Ideas and the buckets they
// belong to now sit together, and BucketLibrary in brand_system.dart is the only
// list of buckets in the app.
//
// A bucket id is one thing everywhere now. puzzle became challenge, talk became
// conversation, skill became age_practice, and wrap became the new community
// bucket. That last one is new because the three posts that used it ask the
// followers a question, which none of the other five buckets describes, and
// folding them into 'conversation' would have quietly changed what they were about.

import 'brand_system.dart';
import 'quick_content.dart';

// -- Buckets ---------------------------------------------------------------------
//
// Thin names over BucketLibrary rather than a second list. quick_content.dart and
// plan_screen.dart call these, so they stay put and stop being a second truth.

const List<ContentBucket> kContentBuckets = BucketLibrary.all;

ContentBucket? bucketById(String id) => BucketLibrary.byId(id);

ContentBucket? bucketByName(String name) => BucketLibrary.byName(name);

String bucketLabel(String id) => bucketById(id)?.shortLabel ?? id;

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
  final String postFormat;
  final String strategy;
  final String caption;
  final String pinnedComment;
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
    this.postFormat = 'Reel',
    this.strategy = '',
    this.caption = '',
    this.pinnedComment = '',
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
        postFormat: postFormat,
        strategy: strategy,
        caption: caption,
        pinnedComment: pinnedComment,
        forApp: forApp,
        usedOn: usedOn ?? this.usedOn,
        custom: custom,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'category': category, 'cover': cover, 'opening': opening,
        'problem': problem, 'lesson': lesson, 'forApp': forApp,
        'usedOn': usedOn, 'custom': custom, 'postFormat': postFormat,
        'strategy': strategy, 'caption': caption, 'pinnedComment': pinnedComment,
      };

  factory HookIdea.fromJson(Map<String, dynamic> j) => HookIdea(
        id: j['id'] as String? ?? '',
        category: j['category'] as String? ?? 'Relatable',
        cover: j['cover'] as String? ?? '',
        opening: j['opening'] as String? ?? '',
        problem: j['problem'] as String? ?? '',
        lesson: j['lesson'] as String? ?? '',
        postFormat: j['postFormat'] as String? ?? 'Reel',
        strategy: j['strategy'] as String? ?? '',
        caption: j['caption'] as String? ?? '',
        pinnedComment: j['pinnedComment'] as String? ?? '',
        forApp: j['forApp'] as bool? ?? true,
        usedOn: j['usedOn'] as String? ?? '',
        custom: j['custom'] as bool? ?? false,
      );

  /// Laid out as the story form, ready for Write the script.
  String asStoryText() => 'Cover hook: $cover\n'
      'Hook: $opening\n'
      'Who: Ria, Rio, Cuty\n'
      'Where: A warm, familiar family home\n'
      'What starts it: $problem\n'
      'What goes wrong: The small problem turns into funny family chaos\n'
      'How it gets worse: Each character reacts in their own way\n'
      'How it is solved: They listen, help one another, and try again\n'
      'Ending line: That is how one little moment becomes a big family memory\n'
      'Moral: $lesson\n'
      'Post format: $postFormat\n'
      'Strategy: $strategy\n'
      'Caption: $caption\n'
      'Pinned comment: $pinnedComment';
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

  // Milestone posts: complete concepts for the 100th Instagram post.
  HookIdea(id: 'p05', category: 'Page & milestone',
    cover: '100 Posts. One World.',
    opening: '100 posts. ❤️ But who are we? Ria jumps in, Rio says NO, and Cuty is sleeping.',
    problem: 'A new visitor should understand Fun Learning With Palak, the three characters, and the page world in one reel',
    lesson: 'Little stories, learning, masti and everyday childhood can grow into one warm little world',
    postFormat: 'Reel / Trial Reel',
    strategy: 'Milestone + brand introduction + character introduction + discovery. Use a 25-35 second reel with Ria, Rio and Cuty, then test two hooks as Trial Reels: 100 POSTS ❤️ and Meet Our Little World 👀.',
    caption: '100 posts. ❤️\n\nWhat started as little ideas slowly became our little world — Ria, Rio, Cuty and so many tiny stories, laughs and lessons. 🌸💙🐰\n\nThank you for being here.\n\nLittle Stories. Big Lessons. 🌱\n\nAre you Team Ria, Team Rio or Team Cuty? 👇',
    pinnedComment: 'Okay, important question 😂👇\n🌸 Ria = Tofani\n💙 Rio = Ziddi\n🐰 Cuty = Sleep Lover\nWhich one is most like your little one?'),
  HookIdea(id: 'p06', category: 'Page & milestone',
    cover: '100 Posts Ago...',
    opening: '100 posts ago, there was no big world — just one little idea and one little character.',
    problem: 'The page journey and its characters need an emotional introduction for new visitors',
    lesson: 'One small idea can grow into a little family and a community that learns together',
    postFormat: 'Reel / Emotional milestone',
    strategy: 'Open with 100 posts ago, introduce Ria, then Rio, then Cuty, and end with 100 POSTS ❤️ and We are just getting started.',
    caption: '100 posts ago, there was only one little idea. Today, Ria, Rio and Cuty have their own little world. ❤️\n\nThank you for growing with us. Little Stories. Big Lessons. 🌱',
    pinnedComment: 'Which character did you meet first — Ria, Rio or Cuty? ❤️'),
  HookIdea(id: 'p07', category: 'Page & milestone',
    cover: 'Who Made Post 100?',
    opening: 'Ria says she made Post 100. Rio says NO. Cuty says wake me up at Post 200.',
    problem: 'A milestone announcement can feel too formal unless the characters make it funny and memorable',
    lesson: 'Ria\'s masti, Rio\'s zidd and Cuty\'s neend are what make this little world special',
    postFormat: 'Funny Reel / Trial Reel',
    strategy: 'Use the funniest version for discovery. Ria claims credit, Rio argues, Cuty keeps sleeping, and the final card reveals POST #100 🎉.',
    caption: 'Who made it to Post #100? 😂\n\nRia says it was her. Rio says NO. Cuty is sleeping through the celebration.\n\nStill causing trouble, one little story at a time. ❤️',
    pinnedComment: 'Who is most like your little one: Tofani Ria, Ziddi Rio or sleepy Cuty? 😂'),
  HookIdea(id: 'p08', category: 'Page & milestone',
    cover: 'Meet Our Little World',
    opening: 'Meet Ria, Rio and Cuty — one is Tofani, one is Ziddi, and one just wants to sleep.',
    problem: 'New followers need a simple pinned introduction to the characters and the page promise',
    lesson: 'Together they make Fun Learning With Palak: cute preschool stories, learning, laughter and little lessons',
    postFormat: 'Reel / Pinned brand introduction',
    strategy: 'Pin this after Post 100. Introduce each character in one quick beat, then show learning, masti, family and everyday childhood.',
    caption: 'Welcome to our little world. 🌸💙🐰\n\nRia is Tofani, Rio is Ziddi, and Cuty is our sleep lover. Together they bring little stories, little lessons and lots of masti.\n\nFun Learning With Palak ❤️',
    pinnedComment: 'Which one are you: Team Ria, Team Rio or Team Cuty? 👇'),

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

// ── The 14-Day Post Packages ───────────────────────────────────────────────────
//
// Every field filled and ready to paste into Quick Content Studio.
// Day 1 ("100 Posts. One World.") is already a built-in hook in plan_data.dart.
// This list covers Days 2–14.

final kDay14Posts = <QuickIdea>[
  // ── DAY 2 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day2-which-doesnt-belong',
    title: 'Which One Doesn\'t Belong?',
    postType: 'Static Image',
    audience: 'Parents of 3-6 year olds',
    contentGoal: 'Observation skill practice — save-worthy',
    mood: 'Curious / Playful',
    hook: 'Which One Doesn\'t Belong? 🧩',
    mainIdea: 'A simple 4-item observation puzzle for preschoolers.',
    problem: 'Four illustrated objects side by side: apple, banana, orange, car.',
    lesson: 'The car — it\'s the only one that\'s not food!',
    visualStyle: 'Bright, clean, minimal — 4 large icon-style illustrations on a cream card',
    imagePrompt: 'Create a bright, clean preschool puzzle card, square format, cream pastel background. Four large, simple, colorful illustrations in a row: a red apple, a yellow banana, an orange, and a small blue toy car. Rounded card border, soft drop shadow under each object, minimal clutter, no text inside the image, playful children\'s illustration style.',
    caption: 'Which one doesn\'t belong? 🧩 A simple thinking game for your little explorer — no right or wrong way to try, just fun observation! Save this for your next 5-minute activity with your child. 💛\n\n#FunLearningWithPalak',
    cta: 'Comment your child\'s answer below 👇',
    hashtags: '#preschoolactivities #toddlerlearning #kidsbrainbooster #earlylearningindia #funlearningwithpalak #momsofinstagram #observationskills',
    comments: [
      'Try this with your little one and tell us — did they spot it right away? 👀',
      'My daughter said the car too! So proud 😍',
      'This is such a simple but smart activity, saving it!',
      '😂😂 my son picked the banana because "it\'s yellow like his shirt" — close enough!',
      'Love how easy this is to do with things we already have at home.',
    ],
    script: '',
    bucket: 'challenge',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 3 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day3-mumma-says',
    title: 'Mumma Says This 100x a Day',
    postType: 'Reel',
    audience: 'Parents of 2-5 year olds',
    contentGoal: 'Relatable connection + share-worthy',
    mood: 'Funny / Chaotic-cute',
    hook: 'MUMMA SAYS THIS 100× A DAY 😂',
    mainIdea: 'Fast-cut relatable moments of things parents repeat all day.',
    problem: 'Put your shoes on / Where\'s your water bottle / Don\'t run / Stop fighting / Come here',
    lesson: 'Tag a parent who needs to see this',
    visualStyle: 'Bright, cartoon, fast cuts, expressive reactions',
    imagePrompt: 'Bright cartoon reel style, cream background, vertical 9:16. Scene 1: Ria barefoot holding shoes, "Coming!" speech bubble, 5 min later still barefoot. Scene 2: Rio shrugging, water bottle beside him. Scene 3: Ria and Rio sprinting past, Cuty asleep. Scene 4: Both with angry faces, Cuty still asleep. Scene 5: Parent searching, "COME HERE!" text.',
    caption: 'Mummas, be honest — how many times did you say this TODAY? 😂 Tag a parent who needs to see this.\n\n#FunLearningWithPalak',
    cta: 'Be honest — how many times today? 👇',
    hashtags: '#parentingmemes #toddlerlife #momsofindia #relatablemom #funlearningwithpalak #parentinghumor #toddlermom',
    comments: [
      'Drop a number 👇 be honest, we won\'t judge 😂',
      'Literally on repeat in my house every single morning 😭',
      'This is SO accurate it hurts 😂',
      'I said "come here" 4 times before dinner today alone.',
      'Even non-moms understand this energy 😂',
    ],
    script: 'Scene 1: "Put your shoes on." — Ria: "Coming!" — 5 minutes later, still barefoot 😂\nScene 2: "Where\'s your water bottle?" — Rio: "I don\'t know." (bottle right beside him)\nScene 3: "Don\'t run!" — Ria and Rio sprint past, Cuty asleep 😴\nScene 4: "Stop fighting!" — Ria 😤 Rio 😤 Cuty: still asleep\nScene 5: "Come here." — silence — "COME HERE!" 😂',
    bucket: 'humor',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 4 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day4-kitchen-challenge',
    title: '5-Minute Kitchen Challenge',
    postType: 'Carousel',
    audience: 'Parents of 2-4 year olds',
    contentGoal: 'Save-worthy practical activity',
    mood: 'Warm / Practical',
    hook: '5-MINUTE KITCHEN CHALLENGE 🥄',
    mainIdea: 'A quick sorting activity using household spoons.',
    problem: 'What you need: 5 spoons of different sizes from your kitchen drawer.',
    lesson: '1. Give your child the 5 spoons. 2. Ask them to line them up from smallest to biggest. 3. Count them together out loud — "1, 2, 3, 4, 5!"',
    visualStyle: 'Real-life-inspired but illustrated, cream kitchen setting',
    imagePrompt: 'Soft pastel watercolor illustration, cream kitchen countertop background, five spoons of varying sizes arranged playfully, a small illustrated child\'s hand reaching toward them, warm cozy lighting, minimal text, vertical or square format matching slide.',
    caption: 'No fancy toys needed — just 5 spoons from your drawer! This 5-minute activity builds sorting + counting skills while you finish making dinner. 💛 Save this for later!\n\n#FunLearningWithPalak',
    cta: 'Save this for your next kitchen moment ❤️',
    hashtags: '#preschoolactivities #kitchenlearning #toddleractivities #earlylearning #sortingskills #funlearningwithpalak #momhacks',
    comments: [
      'Tried this yet? Tell us how your little chef did! 🥄',
      'Love that this uses stuff I already have at home!',
      'My 3-year-old turned it into a spoon xylophone instead 😂 still counts as learning right?',
      'Doing this tonight while I cook, thank you!',
      'So simple but so smart.',
    ],
    script: 'Slide 1: "5-MINUTE KITCHEN CHALLENGE 🥄"\nSlide 2: "You\'ll need: 5 spoons, any size!"\nSlide 3: "Step 1: Mix them up on the table."\nSlide 4: "Step 2: Ask — \'Can you line them up smallest to biggest?\'"\nSlide 5: "Step 3: Count together — 1, 2, 3, 4, 5!"\nSlide 6: "That\'s it! Save this for your next kitchen moment ❤️"',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 5 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day5-ask-tonight',
    title: 'Ask Your Child This Tonight',
    postType: 'Static Image',
    audience: 'Parents of 2-6 year olds',
    contentGoal: 'Conversation starter value',
    mood: 'Warm / Curious',
    hook: 'ASK YOUR CHILD THIS TONIGHT 🗣️',
    mainIdea: 'A conversation-starter question for bedtime or dinner.',
    problem: 'Question to ask: "If your teddy could talk, what would it say?"',
    lesson: 'Encourages imagination and gives you a window into how your child thinks.',
    visualStyle: 'Cozy, soft evening lighting',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream bedroom background, warm evening lighting. Ria sitting on her bed hugging Cuty the white bunny, a small illustrated thought bubble above Cuty\'s head with a question mark inside. Rio peeking in from the doorway, curious. No glasses, no text inside the image, gentle cozy mood, vertical 9:16 or square format.',
    caption: 'Tonight, instead of the usual bedtime questions, try this one: "If your teddy could talk, what would it say?" You might be surprised by the answer. 💛\n\n#FunLearningWithPalak',
    cta: 'What did they say? Comment below 👇',
    hashtags: '#talkwithyourkids #parentingtips #bedtimeroutine #toddlerconversations #funlearningwithpalak #earlychildhood #momlife',
    comments: [
      'We\'d love to hear what your little one said — share it below! ❤️',
      'My son said his teddy would say "let\'s go on an adventure!" 😍',
      'This made for such a sweet bedtime chat tonight.',
      'She said her teddy would just say "I love you" — I nearly cried 🥹',
      'Trying this tonight, such a lovely idea.',
    ],
    script: '',
    bucket: 'conversation',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 6 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day6-3year-skills',
    title: 'Can Your 3-Year-Old Do These?',
    postType: 'Carousel',
    audience: 'Parents of 3-year-olds',
    contentGoal: 'Informative milestone reference',
    mood: 'Informative / Reassuring',
    hook: 'CAN YOUR 3-YEAR-OLD DO THESE? ✅',
    mainIdea: 'A quick skill-check reference for parents of 3-year-olds.',
    problem: 'Age group: 3 Years',
    lesson: '1. Identify basic colours\n2. Name 5 fruits\n3. Recognise their own name\n4. Count 1–10\n5. Identify body parts',
    visualStyle: 'Clean checklist card, soft pastel icons per item',
    imagePrompt: 'Soft pastel watercolor illustration, cream background, Ria and Rio standing together pointing at a floating checklist icon relevant to each slide (color palette / fruit basket / name tag / number blocks / body outline), Cuty sitting nearby. Clean, warm, reassuring tone, no glasses, minimal text inside image, square format.',
    caption: 'Every child grows at their own pace — this is simply a gentle guide, not a race! ❤️ Save this to casually check in with your 3-year-old\'s development.\n\n#FunLearningWithPalak',
    cta: 'Bookmark this for your 3-year-old\'s next milestone check 📌',
    hashtags: '#preschoolmilestones #3yearoldactivities #toddlerdevelopment #earlylearning #parentingindia #funlearningwithpalak #momsofinstagram',
    comments: [
      'How many can your 3-year-old already do? Tell us below! 💛',
      'My daughter can do 4 out of 5, so proud!',
      'This is a great reminder, not a pressure checklist. Thank you for that note.',
      'Saving this to track over the next few months.',
      'She\'s still working on counting to 10 but getting there!',
    ],
    script: 'Slide 1: "CAN YOUR 3-YEAR-OLD DO THESE? ✅"\nSlide 2: "🎨 Identify basic colours"\nSlide 3: "🍎 Name 5 fruits"\nSlide 4: "📛 Recognise their own name"\nSlide 5: "🔢 Count 1–10"\nSlide 6: "👀 Identify body parts"\nSlide 7: "Save this to check off with your little one this week! 📌"',
    bucket: 'age_practice',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 7 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day7-toddler-math',
    title: 'Toddler Mathematics',
    postType: 'Reel',
    audience: 'Parents of 1-4 year olds',
    contentGoal: 'Relatable humor + share',
    mood: 'Funny / Punchy',
    hook: 'TODDLER MATHEMATICS 😂',
    mainIdea: 'A funny, exaggerated "math lesson" about biscuit logic.',
    problem: '1 biscuit = hungry / 2 biscuits = still hungry / 3 biscuits = MUMMA, MORE!',
    lesson: 'Tag a parent who has lived this exact equation',
    visualStyle: 'Bold, bright, meme-style text overlays',
    imagePrompt: 'Bold bright meme-style reel, cream background, vertical 9:16. Scene 1: "1 biscuit = hungry" — Rio holding one biscuit, neutral face. Scene 2: "2 biscuits = still hungry" — same neutral face. Scene 3: "3 biscuits = \'MUMMA, MORE!\'" — dramatic happy face, arms out. Scene 4: Cuty unimpressed, nibbling one carrot.',
    caption: 'Toddler mathematics — it\'s a whole different subject 😂 Tag a parent who\'s lived this exact equation.\n\n#FunLearningWithPalak',
    cta: 'Tag a parent who gets this 😅',
    hashtags: '#toddlerlife #parentingmemes #momsofindia #relatablehumor #funlearningwithpalak #toddlermom #parentinghumor',
    comments: [
      'Be honest — how many biscuits does it take in your house? 😂',
      'This is exact science in my house 😭',
      'Replace biscuit with chocolate and this is my son.',
      '😂😂😂 too accurate.',
      'Cuty staying calm through all of this is such a mood.',
    ],
    script: 'Scene 1: "1 biscuit = hungry" — Rio holds one biscuit, neutral face.\nScene 2: "2 biscuits = still hungry" — same neutral face.\nScene 3: "3 biscuits = \'MUMMA, MORE!\'" — Rio\'s face lights up dramatically, arms out.\nScene 4: Cuty sitting nearby, unimpressed, still nibbling one carrot.',
    bucket: 'humor',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 8 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day8-find-cuty',
    title: 'Find the Hidden Cuty!',
    postType: 'Static Image',
    audience: 'Parents of 2-5 year olds',
    contentGoal: 'Observation game',
    mood: 'Playful / Fun',
    hook: 'FIND THE HIDDEN CUTY! 👀',
    mainIdea: 'A "spot the character" observation game.',
    problem: 'A busy, colorful garden scene with Cuty the bunny camouflaged somewhere.',
    lesson: 'Cuty was hidden behind a flower pot — look for the pink bow!',
    visualStyle: 'Busy but not overwhelming, bright colors, lots of details to scan',
    imagePrompt: 'Soft pastel watercolor illustrated garden scene, cream and green tones, flowers, bushes, small toys scattered around. Cuty the small white bunny cleverly tucked partially behind a bush or flower pot, blending gently but still findable. Ria and Rio standing to the side looking around playfully, no glasses, vertical or square format, minimal text inside image.',
    caption: 'Cuty is hiding somewhere in this picture! 🐰 Can your little one spot him before you do? Comment when you find him!\n\n#FunLearningWithPalak',
    cta: 'How fast did you find him? ⏱️ Comment below!',
    hashtags: '#hiddenobject #spotthedifference #preschoolgames #observationskills #toddleractivities #funlearningwithpalak #kidsgames',
    comments: [
      'Found him? Drop a 🐰 in the comments!',
      'Found him behind the flower pot! 🐰',
      'Took my daughter 10 seconds, she\'s a pro at this now.',
      'This kind of activity is so good for focus, love it.',
      'My son said "there he is!" so excited 😍',
    ],
    script: '',
    bucket: 'challenge',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 9 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day9-sock-hunt',
    title: 'The Sock Hunt',
    postType: 'Reel',
    audience: 'Parents of 1-4 year olds',
    contentGoal: 'Practical activity that saves time',
    mood: 'Playful / Everyday-relatable',
    hook: 'THE SOCK HUNT 🧦',
    mainIdea: 'A laundry-basket matching game turned into play.',
    problem: 'You need: a laundry basket full of mixed, unmatched socks.',
    lesson: '1. Dump the basket. 2. Ask "Can you find all the matching pairs?" 3. Celebrate every match!',
    visualStyle: 'Cozy home laundry scene, bright sock colors for visual interest',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream laundry room background. Scene 1: Pile of mismatched colorful socks on floor, Ria and Rio diving in curiously. Scene 2: Rio holds two socks — different colors, shakes head "no match." Scene 3: Ria finds matching pair, holds triumphantly. Scene 4: Montage of pairs stacking, Cuty sitting on finished pile. Vertical 9:11.',
    caption: 'Turn laundry day into a game! 🧦 This simple sock-matching hunt builds sorting skills and buys you 5 quiet minutes to actually finish the laundry. Win-win. 😂\n\n#FunLearningWithPalak',
    cta: 'Try this before your next laundry day 😂',
    hashtags: '#laundryhacks #toddleractivities #preschoollearning #momhacks #sortingskills #funlearningwithpalak #parentingtips',
    comments: [
      'Does this actually work in your house too? 😂 Tell us!',
      'Genius, why didn\'t I think of this before 😂',
      'My toddler actually helped me fold today because of this!',
      'Turning chores into games is the real parenting hack.',
      'Trying this literally today, laundry pile is huge 😅',
    ],
    script: 'Scene 1: Laundry basket dumped — pile of mismatched colorful socks on the floor. Ria and Rio both dive in curiously.\nScene 2: Rio holds two socks — different colors — shakes head "no match."\nScene 3: Ria finds a matching pair, holds them up triumphantly.\nScene 4: Small montage — pairs stacking up. Cuty "helps" by sitting on the finished pile.',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 10 ───────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day10-3-questions',
    title: '3 Questions Every Parent Should Ask This Week',
    postType: 'Carousel',
    audience: 'Parents of 2-6 year olds',
    contentGoal: 'Conversation starter / community engagement',
    mood: 'Warm / Reflective',
    hook: '3 QUESTIONS TO ASK YOUR CHILD THIS WEEK ❤️',
    mainIdea: 'A small set of conversation-starter questions for the week ahead.',
    problem: 'Questions:\n1. "What made you happy today?"\n2. "What would you build with 100 blocks?"\n3. "Which animal would you want as a friend?"',
    lesson: 'Small questions can open up the biggest conversations.',
    visualStyle: 'Soft, cozy, one question per slide with gentle illustration',
    imagePrompt: 'Soft pastel watercolor illustration, cream background, warm evening lighting, Ria and Rio sitting together on the floor in conversation, Cuty curled nearby, gentle cozy family mood, no glasses, minimal text inside image, square format.',
    caption: 'Small questions can open up the biggest conversations. Save this and try asking just one each night this week. 💛\n\n#FunLearningWithPalak',
    cta: 'Save this — ask one each night this week.',
    hashtags: '#talkwithyourkids #parentingtips #mindfulparenting #toddlerconversations #funlearningwithpalak #familytime #momlife',
    comments: [
      'Starting with the 100 blocks question tonight!',
      'These are so simple but so meaningful, saving this.',
      'My son\'s animal answer was a dinosaur, obviously 😂',
      'Love having actual questions instead of just "how was your day."',
      'This is going into our nightly routine now.',
    ],
    script: 'Slide 1: "3 QUESTIONS TO ASK YOUR CHILD THIS WEEK ❤️"\nSlide 2: "\'What made you happy today?\'"\nSlide 3: "\'What would you build with 100 blocks?\'"\nSlide 4: "\'Which animal would you want as a friend?\'"\nSlide 5: "Save this — ask one each night this week 💛"',
    bucket: 'conversation',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 11 ───────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day11-4year-skills',
    title: 'Can Your 4-Year-Old Do These?',
    postType: 'Carousel',
    audience: 'Parents of 4-year-olds',
    contentGoal: 'Informative milestone reference (series with Day 6)',
    mood: 'Informative / Reassuring',
    hook: 'CAN YOUR 4-YEAR-OLD DO THESE? ✅',
    mainIdea: 'A skill-check reference for parents of 4-year-olds.',
    problem: 'Age group: 4 Years',
    lesson: '1. Count 1–20\n2. Recognise A–Z\n3. Name the days of the week\n4. Sort objects by category\n5. Follow 2–3 step instructions',
    visualStyle: 'Same clean checklist card style as Day 6, for visual series consistency',
    imagePrompt: 'Soft pastel watercolor illustration, cream background, Rio and Ria standing together pointing at a floating icon relevant to each slide (number blocks / alphabet letters / calendar / sorting bins / ear listening icon), Cuty sitting nearby. Clean, warm, reassuring tone, no glasses, square format.',
    caption: 'Every child moves at their own pace — this is just a gentle guide! Save this to casually check in with your 4-year-old\'s growth. ❤️\n\n#FunLearningWithPalak',
    cta: 'Bookmark this for your 4-year-old\'s next milestone check 📌',
    hashtags: '#preschoolmilestones #4yearoldactivities #toddlerdevelopment #earlylearning #parentingindia #funlearningwithpalak #momsofinstagram',
    comments: [
      'How many can your 4-year-old already do? Tell us below! 💛',
      'He\'s got the alphabet down but still working on days of the week!',
      'This is such a helpful, non-stressful way to check progress.',
      'Saving this series, loved the 3-year-old one too.',
      'Would love a 5-year-old version too!',
    ],
    script: 'Slide 1: "CAN YOUR 4-YEAR-OLD DO THESE? ✅"\nSlide 2: "🔢 Count 1–20"\nSlide 3: "🔤 Recognise A–Z"\nSlide 4: "📅 Name the days of the week"\nSlide 5: "🗂️ Sort objects by category"\nSlide 6: "👂 Follow 2–3 step instructions"\nSlide 7: "Bookmark this for your 4-year-old\'s next milestone check 📌"',
    bucket: 'age_practice',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 12 ───────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day12-dinner-types',
    title: 'Three Types of Kids at Dinner',
    postType: 'Static Image',
    audience: 'Parents of 1-5 year olds',
    contentGoal: 'Relatable humor + share',
    mood: 'Funny / Character-driven',
    hook: 'THREE TYPES OF KIDS AT DINNER 🍽️',
    mainIdea: 'A character-based relatable meme using the established Ria/Rio/Cuty personalities.',
    problem: '🌸 Ria = "What\'s this?" (curious, poking at food) / 💙 Rio = "I don\'t want it." (arms crossed, ziddi) / 🐰 Cuty = peacefully eating, unbothered',
    lesson: 'Every family has all three at the dinner table',
    visualStyle: 'Three-panel meme layout, bright and simple',
    imagePrompt: 'Soft pastel watercolor illustration, three-panel layout on cream background, dinner table setting. Panel 1: Ria poking curiously at a plate of food, questioning expression. Panel 2: Rio with arms crossed, refusing his plate, stubborn expression. Panel 3: Cuty the white bunny calmly and happily eating a carrot from a small bowl. No glasses, clean simple outlines, minimal text inside image, square format.',
    caption: 'Every family has all three at the dinner table 😂 Which one is your child tonight?\n\n#FunLearningWithPalak',
    cta: 'Which one is your child? 👇',
    hashtags: '#parentingmemes #toddlerdinner #relatablehumor #momsofindia #pickyeater #funlearningwithpalak #toddlermom',
    comments: [
      'Tag the parent whose child is ALL THREE some nights 😂',
      'My son is 100% Rio energy at every meal 😩',
      'We have a Ria who questions every single ingredient 😂',
      'Cuty\'s energy is the dream honestly.',
      'All three, every night, in the same child 😭',
    ],
    script: '',
    bucket: 'humor',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 13 ───────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day13-pattern-game',
    title: 'What Comes Next?',
    postType: 'Reel',
    audience: 'Parents of 2-5 year olds',
    contentGoal: 'Early math thinking game',
    mood: 'Curious / Satisfying',
    hook: 'WHAT COMES NEXT? 🟡🔵🟡🔵❓',
    mainIdea: 'A simple color-pattern completion challenge.',
    problem: 'Pattern: yellow, blue, yellow, blue — then a pause on question mark.',
    lesson: 'Yellow is the correct next color in the sequence.',
    visualStyle: 'Bold, simple shapes, clean animation-style reveal',
    imagePrompt: 'Bold simple animation-style reel, cream background, vertical 9:16. Yellow and blue circles appear in sequence: 🟡🔵🟡🔵. Then a large question mark where the next circle should go. Ria taps her chin, thinking. Yellow circle slides into place, Ria claps, Cuty hops happily.',
    caption: 'Can your child guess what comes next? 🟡🔵🟡🔵❓ A simple pattern game that builds early math thinking!\n\n#FunLearningWithPalak',
    cta: 'Did your child guess it before the reveal? 😄',
    hashtags: '#patternrecognition #preschoolmath #earlylearning #toddlerbrain #funlearningwithpalak #kidsactivities #momsofinstagram',
    comments: [
      'Guess before you scroll — what comes next? 👇',
      'Got it right away, yellow obviously! 🟡',
      'My daughter shouted the answer before the reveal, so proud.',
      'Simple but so satisfying to watch.',
      'This is a great one to do out loud with my son.',
    ],
    script: 'Scene 1: Pattern builds on screen one shape at a time — 🟡🔵🟡🔵\nScene 2: Hold on a large "❓" where the next shape should go.\nScene 3: Ria taps her chin, thinking.\nScene 4: Reveal — 🟡 slides into place, Ria claps, Cuty hops happily.',
    bucket: 'challenge',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 14 ───────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day14-favorite-format',
    title: 'Which New Format Was Your Favorite?',
    postType: 'Carousel',
    audience: 'Existing followers',
    contentGoal: 'Community feedback + engagement',
    mood: 'Reflective / Community-driven',
    hook: 'WHICH NEW FORMAT WAS YOUR FAVORITE? 🗳️',
    mainIdea: 'A visual recap of the 5 buckets tested this week, inviting audience feedback.',
    problem: 'Five content types tested this week:\n🔎 Puzzles & Challenges\n🗣️ Talk With Your Child\n🏠 Try This at Home\n😂 Parent-Relatable Humor\n📚 Age-Based Skill Checks',
    lesson: 'Use this post\'s engagement + Insights data to decide bucket weighting for Days 15-30.',
    visualStyle: 'Clean 5-tile grid or carousel, cream background, one word label per tile',
    imagePrompt: 'Soft pastel watercolor illustration, cream background, small icon representing the bucket theme (puzzle piece / speech bubble / house / laughing face / checklist), Ria, Rio, or Cuty featured lightly in the corner depending on tile, clean minimal design, square format.',
    caption: 'This past week, we tried something new — 5 completely different formats instead of just stories! Which one did you enjoy the most? Vote in our Story or tell us below. 💛\n\n#FunLearningWithPalak',
    cta: 'Vote in the poll sticker on our Story, or comment your favorite below 👇',
    hashtags: '#newcontent #parentingcommunity #preschoollearning #funlearningwithpalak #momsofinstagram #instagramgrowth',
    comments: [
      'Tell us honestly — which one should we make more of? 👇',
      'Loved the puzzles the most, more of those please!',
      'The humor reels made me laugh out loud, keep those coming.',
      'The 3/4-year-old checklists were genuinely useful for me.',
      'Honestly loved all of them, such a fun week of content!',
    ],
    script: 'Slide 1: "WHICH NEW FORMAT WAS YOUR FAVORITE? 🗳️"\nSlide 2: "🔎 Puzzles & Challenges"\nSlide 3: "🗣️ Talk With Your Child"\nSlide 4: "🏠 Try This at Home"\nSlide 5: "😂 Parent-Relatable Humor"\nSlide 6: "📚 Age-Based Skill Checks"\nSlide 7: "Vote in our Story poll or comment your favorite below! 💛"',
    bucket: 'community',
    createdAt: DateTime(2026, 9, 24),
  ),

  // ── DAY 15 ────────────────────────────────────────────────────────────────────
  // Part 1: How to Play Each Mission With Household Items
  QuickIdea(
    id: 'day15-household-swaps',
    title: 'How to Play Each Mission With Household Items',
    postType: 'Carousel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Fulfill promise + drive saves',
    mood: 'Practical / Warm',
    hook: 'NO SPECIAL TOYS NEEDED — HERE\'S WHAT TO USE! 🏠',
    mainIdea: 'A practical substitution guide showing exactly what household item replaces each mission\'s prop.',
    problem: 'Parents may think missions need special equipment (hurdles, treasure boxes, detective kits).',
    lesson: 'Race Track → broomstick + 2 chairs as hurdle, dupatta as line | Concert → wooden spoon mic, steel plate drums | Art Studio → any paper + slate/notebook, kitchen chalk on floor | Detective → sunglasses/toy binoculars or cupped hands | Rescue Team → laundry basket, dupatta/old rope | Treasure Box → any box/tiffin with lid, small toys inside | Daily Care → owned tiffin, water bottle, toothbrush',
    visualStyle: 'Same consistent characters, showing the "official" prop next to the "at-home swap"',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, vertical carousel format. Consistent Ria (brown eyes, warm skin tone, no glasses) and Rio (brown eyes, warm skin tone, no glasses) appear across all slides with Cuty the white bunny (pink bow). Each slide shows split view: left side "official" mission prop, right side "at-home swap" using household items. Slide 1: broomstick between chairs + dupatta line. Slide 2: wooden spoon mic + steel plates. Slide 3: paper/slate + kitchen chalk. Slide 4: sunglasses/binoculars + cupped hands. Slide 5: laundry basket + dupatta rope. Slide 6: tiffin box with toys. Slide 7: tiffin, water bottle, toothbrush. Warm, practical, encouraging mood.',
    caption: 'Promised, delivered! 🏠 Here\'s exactly what to swap in for each mission using things already in your house. No special toys, no shopping list — just play. Which swap are you trying first? #FunLearningWithPalak',
    cta: 'Save this — now you have zero excuses to skip a mission! 📌',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities',
    comments: [
      'Using my dupatta for the rescue mission right now 😂',
      'This removes literally every excuse, thank you!',
      'Wooden spoon microphone was a huge hit here!',
      'Love that I didn\'t need to buy anything at all.',
      'Saving this permanently, so practical.',
    ],
    script: 'Slide 1: "NO SPECIAL TOYS NEEDED — HERE\'S WHAT TO USE! 🏠"\nSlide 2: "Race Track → Broomstick + 2 chairs = hurdle, dupatta = line"\nSlide 3: "Concert → Wooden spoon = mic, steel plates = drums"\nSlide 4: "Art Studio → Any paper + slate, kitchen chalk on floor"\nSlide 5: "Detective → Sunglasses/binoculars or just cupped hands"\nSlide 6: "Rescue Team → Laundry basket + dupatta rope"\nSlide 7: "Treasure Box → Any box/tiffin with lid, small toys inside"\nSlide 8: "Daily Care → Your tiffin, water bottle, toothbrush — done!"\nSlide 9: "Save this — zero excuses to skip a mission! 📌"',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 25),
  ),

  // ── DAY 16 ────────────────────────────────────────────────────────────────────
  // Part 2: Engagement Recap - You Voted!
  QuickIdea(
    id: 'day16-voted-mission-won',
    title: 'You Voted! Here\'s Which Mission Won',
    postType: 'Single Image',
    audience: 'Existing followers who commented',
    contentGoal: 'Close the loop + build community + drive comments again',
    mood: 'Fun / Celebratory',
    hook: 'THE VOTES ARE IN! 🏆',
    mainIdea: 'A results reveal based on which mission number got the most comments, turning passive voters into repeat engagers.',
    problem: 'N/A (results format, no puzzle needed)',
    lesson: 'Reveal the winning mission with a small "why this one might be the most popular" note (e.g., "Detective Mission is your favorite — mystery never gets old!")',
    visualStyle: 'Celebratory, confetti, winning mission\'s characters front and center',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, celebratory mood with confetti. Ria and Rio (brown eyes, warm skin tone, no glasses) holding a trophy, Cuty the white bunny (pink bow) cheering. Winning mission number displayed prominently (e.g., "Mission 5 Won!"). Colorful, joyful, vertical 4:5 or square format.',
    caption: 'You voted, and Mission [X] won! 🏆 Here\'s why we think it\'s such a hit... [one line reason]. Try it today and show us how it goes! #FunLearningWithPalak',
    cta: 'Try today\'s winning mission and tag us in your Story! 🏆',
    hashtags: '#playbasedlearning #toddleractivities #funlearningwithpalak #noscreenactivities #montessoriathome',
    comments: [
      'Yes! This was my top pick too!',
      'My son will be so excited to see this won.',
      'Didn\'t expect this one to win, but I get it!',
      'Trying this with my daughter this evening.',
      'More voting posts like this please, so fun!',
    ],
    script: '',
    bucket: 'community',
    createdAt: DateTime(2026, 9, 26),
  ),

  // ── DAY 17 ────────────────────────────────────────────────────────────────────
  // Part 3 Day 1: Race Track Mission
  QuickIdea(
    id: 'day17-mission1-race-track',
    title: 'Mission 2: On Your Mark! 🏁',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Energetic / Fun',
    hook: 'MISSION 2: ON YOUR MARK! 🏁',
    mainIdea: 'Ria & Rio running, jumping a pillow hurdle, walking a line - Mission 1 of the 7 Mission Week.',
    problem: 'Parents need a simple, structured movement activity for toddlers.',
    lesson: 'Race Track builds coordination, listening skills, and gross motor confidence.',
    visualStyle: 'Same consistent characters, home setting with pillow hurdle and taped line',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) and Rio (brown eyes, warm skin tone, no glasses) in a home hallway/living room. Scene: Rio jumping over a pillow "hurdle" made from cushions, Ria walking a taped line on floor, Cuty the white bunny (pink bow) cheering from the side. Bright morning light, energetic movement captured in soft watercolor style, consistent character designs.',
    caption: 'Mission 2: Race Track! 🏁 Run, jump, walk — simple gross motor play that builds coordination and confidence. No equipment needed, just pillows and tape! Tag us trying this mission! #FunLearningWithPalak',
    cta: 'Tag us trying this mission! 🏁',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #grossmotorskills',
    comments: [
      'My toddler LOVED the pillow hurdle! 😂',
      'We used couch cushions and it was perfect!',
      'Walking the line was harder than it looked for my 2yo!',
      'Great energy burner before nap time!',
      'Cuty cheering is the best part 🐰💕',
    ],
    script: 'Scene 1: "Mission 2: On Your Mark! 🏁" — Ria and Rio at start line\nScene 2: Rio jumps pillow hurdle — "Jump!"\nScene 3: Ria walks taped line carefully — "Walk the line"\nScene 4: Both run to finish — "Run!"\nScene 5: Cuty hands them a "medal" (spoon) 🏅\nScene 6: "Try Mission 2 today! Tag us 🏁"',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 27),
  ),

  // ── DAY 18 ────────────────────────────────────────────────────────────────────
  // Part 3 Day 2: Concert Mission
  QuickIdea(
    id: 'day18-mission2-concert',
    title: 'Mission 3: Living Room Concert! 🎤',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Energetic / Fun',
    hook: 'MISSION 3: LIVING ROOM CONCERT! 🎤',
    mainIdea: 'Singing into a spoon mic, dancing, clapping to rhythm - Mission 2 of the 7 Mission Week.',
    problem: 'Parents need a simple music and movement activity.',
    lesson: 'Concert builds rhythm awareness, self-expression, and language through song.',
    visualStyle: 'Same consistent characters, home setting with wooden spoon mic and steel plate drums',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) singing into a wooden spoon microphone, Rio (brown eyes, warm skin tone, no glasses) clapping and dancing, Cuty the white bunny (pink bow) tapping a steel plate like a drum. Kitchen utensils as instruments visible. Joyful musical chaos, warm family energy, consistent character designs.',
    caption: 'Mission 3: Concert! 🎤 Spoon mic, plate drums, living room stage — music time with zero prep. Show us your concert! 🎤 #FunLearningWithPalak',
    cta: 'Show us your concert! 🎤',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #musiceducation',
    comments: [
      'Wooden spoon mic is iconic now! 😂🎤',
      'My daughter performed a 20-minute concert for us!',
      'Steel plate drums = best drums ever 😂',
      'Love how this uses kitchen items as instruments.',
      'Cuty on drums is everything 🐰🥁',
    ],
    script: 'Scene 1: "Mission 3: Living Room Concert! 🎤"\nScene 2: Ria sings into wooden spoon — "La la la!"\nScene 3: Rio dances, claps to rhythm\nScene 4: Cuty taps steel plate — "Drum solo!"\nScene 5: Family bow together 🎭\nScene 6: "Your turn! Show us your concert 🎤"',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 28),
  ),

  // ── DAY 19 ────────────────────────────────────────────────────────────────────
  // Part 3 Day 3: Art Studio Mission
  QuickIdea(
    id: 'day19-mission3-art-studio',
    title: 'Mission 4: Art Corner Time! 🎨',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Creative / Calm',
    hook: 'MISSION 4: ART CORNER TIME! 🎨',
    mainIdea: 'Reading a book, writing their name, drawing a sun - Mission 3 of the 7 Mission Week.',
    problem: 'Parents need a simple fine motor / creative activity.',
    lesson: 'Art Studio builds fine motor skills, early literacy, and creative confidence.',
    visualStyle: 'Same consistent characters, home art corner with paper, slate, chalk',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) drawing a big yellow sun on paper, Rio (brown eyes, warm skin tone, no glasses) writing his name on a slate with chalk, Cuty the white bunny (pink bow) watching curiously. Kitchen chalk drawing on floor visible. Cozy creative atmosphere, warm light, consistent character designs.',
    caption: 'Mission 4: Art Studio! 🎨 Paper, slate, chalk — three ways to create with what you have. Share your child\'s masterpiece! 🎨 #FunLearningWithPalak',
    cta: 'Share your child\'s masterpiece! 🎨',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #fineartforkids',
    comments: [
      'Kitchen chalk on the floor = genius and washable!',
      'Slate writing practice is such a classic for a reason.',
      'My son drew a sun that looked like a blob but he was SO proud 😍',
      'Love the paper + slate + chalk variety.',
      'Art corner doesn\'t need fancy supplies!',
    ],
    script: 'Scene 1: "Mission 4: Art Corner Time! 🎨"\nScene 2: Ria draws sun on paper — "Look, a sun!"\nScene 3: Rio writes name on slate — "R-I-O"\nScene 4: Kitchen chalk on floor — "Big canvas!"\nScene 5: Cuty hops through drawings 🐰\nScene 6: "Show us your masterpiece! 🎨"',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 29),
  ),

  // ── DAY 20 ────────────────────────────────────────────────────────────────────
  // Part 3 Day 4: Detective Mission
  QuickIdea(
    id: 'day20-mission4-detective',
    title: 'Mission 5: Case Open! 🕵️',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Mysterious / Playful',
    hook: 'MISSION 5: CASE OPEN! 🕵️',
    mainIdea: 'Looking through binoculars, closing eyes to listen, solving a clue - Mission 4 of the 7 Mission Week.',
    problem: 'Parents need an observation and critical thinking activity.',
    lesson: 'Detective builds observation skills, auditory discrimination, and problem-solving.',
    visualStyle: 'Same consistent characters, home setting with sunglasses/binoculars or cupped hands',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) looking through cardboard tube binoculars, Rio (brown eyes, warm skin tone, no glasses) with cupped hands around eyes, Cuty the white bunny (pink bow) with a magnifying glass. A "clue" (toy footprint) on floor. Playful mystery mood, consistent character designs.',
    caption: 'Mission 5: Detective! 🕵️ Binoculars, listening ears, mystery clues — observation play that builds thinking skills. Did your detective solve it? #FunLearningWithPalak',
    cta: 'Did your detective solve it? 🕵️',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #criticalthinking',
    comments: [
      'Cardboard tube binoculars = best DIY ever!',
      'My son found the "clue" in 3 seconds flat 😂',
      'Cupped hands as binoculars is so cute and free!',
      'Love how this builds real observation skills.',
      'Cuty with magnifying glass 🐰🔍',
    ],
    script: 'Scene 1: "Mission 5: Case Open! 🕵️"\nScene 2: Ria with cardboard binoculars — "I see something!"\nScene 3: Rio cupped hands around eyes — "Looking closely"\nScene 4: Rio closes eyes to listen — "Shhh, I hear it!"\nScene 5: Found the clue! 🎉\nScene 6: "Did your detective solve it? 🕵️"',
    bucket: 'challenge',
    createdAt: DateTime(2026, 9, 30),
  ),

  // ── DAY 21 ────────────────────────────────────────────────────────────────────
  // Part 3 Day 5: Rescue Team Mission
  QuickIdea(
    id: 'day21-mission5-rescue',
    title: 'Mission 6: Rescue Time! 🧸',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Heroic / Teamwork',
    hook: 'MISSION 6: RESCUE TIME! 🧸',
    mainIdea: 'Pushing a laundry basket, pulling a rope, helping tidy up - Mission 5 of the 7 Mission Week.',
    problem: 'Parents need a heavy work / proprioception activity.',
    lesson: 'Rescue Team builds gross motor strength, teamwork, and helpfulness.',
    visualStyle: 'Same consistent characters, home setting with laundry basket and dupatta/rope',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) pushing a laundry basket with toys inside, Rio (brown eyes, warm skin tone, no glasses) pulling a dupatta rope attached to the basket, Cuty the white bunny (pink bow) riding in the basket. Heavy work play, teamwork energy, warm home setting, consistent character designs.',
    caption: 'Mission 6: Rescue Team! 🧸 Push, pull, help — heavy work play that builds strength AND teamwork. Teamwork tip from your house? 🧸 #FunLearningWithPalak',
    cta: 'Teamwork tip from your house? 🧸',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #heavywork #proprioception',
    comments: [
      'Laundry basket rescue is our go-to now!',
      'My kids fight over who gets to pull the rope 😂',
      'Heavy work before bed = better sleep, proven!',
      'Cuty riding in the basket is the cutest 🐰',
      'This turns cleanup into a mission!',
    ],
    script: 'Scene 1: "Mission 6: Rescue Time! 🧸"\nScene 2: Ria pushes laundry basket — "Coming through!"\nScene 3: Rio pulls dupatta rope — "Pulling hard!"\nScene 4: Cuty rides inside — "Rescue complete!"\nScene 5: High five teamwork moment ✋\nScene 6: "Your teamwork tip? 🧸"',
    bucket: 'activity',
    createdAt: DateTime(2026, 10, 1),
  ),

  // ── DAY 22 ────────────────────────────────────────────────────────────────────
  // Part 3 Day 6: Treasure Box Mission
  QuickIdea(
    id: 'day22-mission6-treasure',
    title: 'Mission 7: Treasure Hunt! 🎁',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Exciting / Cozy',
    hook: 'MISSION 7: TREASURE HUNT! 🎁',
    mainIdea: 'Opening a box, finding a toy, closing it, tucking bunny to sleep - Mission 6 of the 7 Mission Week.',
    problem: 'Parents need an object permanence / fine motor activity.',
    lesson: 'Treasure Box builds object permanence, fine motor skills, and nurturing play.',
    visualStyle: 'Same consistent characters, home setting with tiffin box or any box with lid',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) opening a tiffin box to find a small toy, Rio (brown eyes, warm skin tone, no glasses) closing the box carefully, Cuty the white bunny (pink bow) being tucked into a blanket nearby. Cozy bedtime transition energy, consistent character designs.',
    caption: 'Mission 7: Treasure Box! 🎁 Open, find, close, tuck in — fine motor + nurturing play with any box. What treasure did you hide? 🎁 #FunLearningWithPalak',
    cta: 'What treasure did you hide? 🎁',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #fine motor #objectpermanence',
    comments: [
      'Tiffin box treasure hunt is brilliant!',
      'My daughter tucks Cuty in every night now 😍',
      'Opening/closing boxes is the best fine motor practice.',
      'We used an old shoebox and it worked perfectly.',
      'The bedtime transition at the end is so smooth!',
    ],
    script: 'Scene 1: "Mission 7: Treasure Hunt! 🎁"\nScene 2: Ria opens tiffin — "What\'s inside?"\nScene 3: Finds toy — "Treasure!"\nScene 4: Rio closes box carefully — "Safe now"\nScene 5: Tucking Cuty in — "Night night bunny" 🐰\nScene 6: "What treasure did you hide? 🎁"',
    bucket: 'age_practice',
    createdAt: DateTime(2026, 10, 2),
  ),

  // ── DAY 23 ────────────────────────────────────────────────────────────────────
  // Part 3 Day 7: Daily Care Mission
  QuickIdea(
    id: 'day23-mission7-daily-care',
    title: 'Mission 8: Self-Care Squad! 🍎',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Warm / Routine',
    hook: 'MISSION 8: SELF-CARE SQUAD! 🍎',
    mainIdea: 'Eating fruit, drinking water, brushing teeth, bedtime routine - Mission 7 of the 7 Mission Week.',
    problem: 'Parents need to build independent self-care routines.',
    lesson: 'Daily Care builds independence, body awareness, and healthy habits.',
    visualStyle: 'Same consistent characters, home bathroom/kitchen setting with tiffin, water bottle, toothbrush',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) eating apple slices from her tiffin, Rio (brown eyes, warm skin tone, no glasses) drinking from his water bottle, both brushing teeth side by side, Cuty the white bunny (pink bow) watching from the counter. Cozy bathroom/kitchen routine atmosphere, consistent character designs.',
    caption: 'Mission 8: Daily Care! 🍎 Eat, drink, brush, sleep — the self-care squad routine with your own tiffin, bottle, brush. Which routine is hardest at your house? #FunLearningWithPalak',
    cta: 'Which routine is hardest at your house? 🍎',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #selfcare #routinesforkids',
    comments: [
      'Tiffin for snacks = independence unlocked!',
      'Brushing together makes it way easier.',
      'Water bottle independence = fewer spills 😂',
      'Bedtime routine is still our biggest battle 😭',
      'Cuty watching them brush is too cute 🐰',
    ],
    script: 'Scene 1: "Mission 8: Self-Care Squad! 🍎"\nScene 2: Ria eats apple from tiffin — "Crunch!"\nScene 3: Rio drinks water — "Glug glug"\nScene 4: Both brush teeth together — "Scrub scrub"\nScene 5: Cuty watches from counter 🐰\nScene 6: "Hardest routine at your house? 🍎"',
    bucket: 'age_practice',
    createdAt: DateTime(2026, 10, 3),
  ),

  // ── DAY 24 ────────────────────────────────────────────────────────────────────
  // Part 4: Trial Reel - 7 Missions in 60 Seconds
  QuickIdea(
    id: 'day24-trial-reel-7-missions',
    title: '7 Missions in 60 Seconds',
    postType: 'Reel',
    audience: 'Non-followers, parents of 1.5-4 year olds',
    contentGoal: 'Maximize non-follower reach + follows',
    mood: 'Energetic / Fun',
    hook: '7 SCREEN-FREE MISSIONS IN 60 SECONDS 🏠✨',
    mainIdea: 'A fast-cut compilation reel showing one shot from each of the 7 missions back to back, building toward the "We Did It!" celebration.',
    problem: 'Parents scrolling don\'t know screen-free play can look this structured and fun.',
    lesson: 'Recap card at the end listing all 7 mission names quickly.',
    visualStyle: 'Fast cuts (1-2 sec per mission), consistent characters, upbeat music',
    imagePrompt: 'Fast-cut vertical 9:16 reel montage, soft pastel watercolor style, cream background. Quick 1-2 second shots: 1) Ria/Rio jumping pillow hurdle (Race Track) 2) Ria singing into spoon, Rio on plate drums (Concert) 3) Ria drawing sun, Rio on slate (Art Studio) 4) Ria with binoculars, Rio cupped hands (Detective) 5) Pushing laundry basket, pulling rope (Rescue) 6) Opening tiffin box, finding toy (Treasure) 7) Eating fruit, drinking water, brushing (Daily Care). Final frame: All 7 mission icons in a grid, "We Did It!" celebration with Ria, Rio, Cuty. Upbeat, energetic, consistent character designs throughout.',
    caption: '7 screen-free missions, 60 seconds, zero shopping required 🏠✨ Follow along as we play through all of them with Ria & Rio! #FunLearningWithPalak',
    cta: 'Follow for a new mission every day this week! 🏠',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #earlylearning',
    comments: [
      'This makes screen-free time actually look doable!',
      'Following now, need this mission list saved!',
      'My kids would love the treasure box one especially.',
      'So well organized, love the mission theme!',
      'This is exactly the structure I needed for our afternoons.',
    ],
    script: '0-3s: Race Track — jump, walk, run 🏁\n3-6s: Concert — spoon mic, plate drums 🎤\n6-9s: Art Studio — draw, write, chalk 🎨\n9-12s: Detective — look, listen, think 🕵️\n12-15s: Rescue — push, pull, help 🧸\n15-18s: Treasure — open, find, close 🎁\n18-21s: Daily Care — eat, drink, brush 🍎\n21-60s: Recap grid of all 7 + "We Did It!" celebration 🎉\nCTA: "Follow for daily missions! 🏠"',
    bucket: 'activity',
    createdAt: DateTime(2026, 10, 4),
  ),

  // ── DAY 25 ────────────────────────────────────────────────────────────────────
  // Part 5: Week Wrap-up - We Completed All 7 Missions!
  QuickIdea(
    id: 'day25-week-wrap-up',
    title: 'We Completed All 7 Missions! Here\'s What Happened',
    postType: 'Carousel',
    audience: 'Existing followers + parents who joined the week',
    contentGoal: 'Build community + set up next series',
    mood: 'Celebratory / Reflective',
    hook: 'WE DID IT — ALL 7 MISSIONS COMPLETE! 🎉',
    mainIdea: 'A recap carousel celebrating the full week, featuring any parent responses/tags from the week if available.',
    problem: 'N/A',
    lesson: 'One slide per mission with a one-line "what we learned" note, then a final "what\'s next" teaser.',
    visualStyle: 'Celebratory, consistent characters, confetti/trophy theme matching the original "We Did It!" page',
    imagePrompt: 'Soft pastel watercolor storybook illustration, cream background, square carousel format. Consistent Ria (brown eyes, warm skin tone, no glasses), Rio (brown eyes, warm skin tone, no glasses), Cuty (white bunny, pink bow) across all slides. Celebratory confetti/trophy theme. Slide 1: "WE DID IT — ALL 7 MISSIONS COMPLETE! 🎉" with trophy. Slides 2-8: Each mission with one-line learning (Race Track: "Movement builds confidence" / Concert: "Music is self-expression" / Art: "Creativity needs no fancy tools" / Detective: "Observation is a superpower" / Rescue: "Teamwork makes the dream work" / Treasure: "Small things bring big joy" / Daily Care: "Routines build independence"). Slide 9: "What\'s next? Tell us below!" with Ria, Rio, Cuty excited for new adventures.',
    caption: 'A full week of screen-free missions, complete! 🎉 From racing to detective work to bedtime routines, Ria & Rio (and hopefully your little ones too) played through all 7. What should our next mission set be about? #FunLearningWithPalak',
    cta: 'Which mission will you repeat this week? Comment below! 🎉',
    hashtags: '#playbasedlearning #toddleractivities #funlearningwithpalak #noscreenactivities #montessoriathome #milestone',
    comments: [
      'This was such a fun week to follow along with!',
      'Please do a kitchen-themed mission series next!',
      'My daughter asks for "mission time" every day now 😍',
      'Loved seeing this build up all week.',
      'Can\'t wait to see what\'s next!',
    ],
    script: 'Slide 1: "WE DID IT — ALL 7 MISSIONS COMPLETE! 🎉"\nSlide 2: "Race Track → Movement builds confidence 🏁"\nSlide 3: "Concert → Music is self-expression 🎤"\nSlide 4: "Art Studio → Creativity needs no fancy tools 🎨"\nSlide 5: "Detective → Observation is a superpower 🕵️"\nSlide 6: "Rescue Team → Teamwork makes the dream work 🧸"\nSlide 6: "Treasure Box → Small things bring big joy 🎁"\nSlide 7: "Daily Care → Routines build independence 🍎"\nSlide 8: "What\'s next? Tell us below! 🚀"',
    bucket: 'community',
    createdAt: DateTime(2026, 10, 5),
  ),
];

class ParsedPostPackage {
  final String title;
  final String postType;
  final String audience;
  final String contentGoal;
  final String mood;
  final String hook;
  final String mainIdea;
  final String problem;
  final String lesson;
  final String visualStyle;
  final String imagePrompt;
  final String caption;
  final String cta;
  final String hashtags;
  final String pinnedComment;
  final List<String> replyComments;
  final String script;
  final String bucket;

  ParsedPostPackage({
    this.title = '',
    this.postType = 'Carousel',
    this.audience = 'Parents of 3-6 year olds',
    this.contentGoal = '',
    this.mood = '',
    this.hook = '',
    this.mainIdea = '',
    this.problem = '',
    this.lesson = '',
    this.visualStyle = '',
    this.imagePrompt = '',
    this.caption = '',
    this.cta = '',
    this.hashtags = '',
    this.pinnedComment = '',
    this.replyComments = const [],
    this.script = '',
    this.bucket = '',
  });

  bool get hasAnyContent =>
      title.isNotEmpty || hook.isNotEmpty || mainIdea.isNotEmpty ||
      problem.isNotEmpty || lesson.isNotEmpty || caption.isNotEmpty ||
      imagePrompt.isNotEmpty || script.isNotEmpty;

  QuickIdea toQuickIdea(String id) {
    final comments = <String>[];
    if (pinnedComment.isNotEmpty) comments.add(pinnedComment);
    comments.addAll(replyComments.where((c) => c.isNotEmpty));
    // Pad to 5 comments minimum
    while (comments.length < 5 && replyComments.length > 0) {
      comments.add(replyComments[comments.length - 1]);
    }
    return QuickIdea(
      id: id,
      title: title,
      postType: postType,
      audience: audience,
      contentGoal: contentGoal,
      mood: mood,
      hook: hook,
      mainIdea: mainIdea,
      problem: problem,
      lesson: lesson,
      visualStyle: visualStyle,
      imagePrompt: imagePrompt,
      caption: caption,
      cta: cta,
      hashtags: hashtags,
      comments: comments,
      script: script,
      bucket: bucket,
      createdAt: DateTime.now(),
    );
  }
}

ParsedPostPackage parseBulkPaste(String text) {
  final result = ParsedPostPackage();
  if (text.trim().isEmpty) return result;

  final lines = text.split('\n');
  final sections = <String, List<String>>{};
  String currentSection = 'header';
  final sectionContent = <String>[];

  for (final line in lines) {
    if (line.startsWith('--- ') && line.endsWith(' ---')) {
      if (sectionContent.isNotEmpty) {
        sections[currentSection] = List.of(sectionContent);
      }
      sectionContent.clear();
      currentSection = line.substring(4, line.length - 4).trim().toLowerCase();
    } else {
      sectionContent.add(line);
    }
  }
  if (sectionContent.isNotEmpty) {
    sections[currentSection] = List.of(sectionContent);
  }

  // Parse header key-value pairs
  final headerLines = sections['header'] ?? [];
  final kv = <String, String>{};
  final multiLineKeys = <String>[];
  String? currentKey;
  final currentVal = StringBuffer();

  for (int i = 0; i < headerLines.length; i++) {
    final line = headerLines[i];
    final colonIdx = line.indexOf(':');
    final isNewKey = colonIdx > 0 &&
        line.substring(0, colonIdx).trim().split(' ').length <= 4 &&
        !line.startsWith('---') &&
        !line.startsWith('  ');

    if (isNewKey && colonIdx >= 0) {
      if (currentKey != null) {
        kv[currentKey] = currentVal.toString().trim();
        currentVal.clear();
      }
      currentKey = line.substring(0, colonIdx).trim();
      currentVal.write(line.substring(colonIdx + 1).trim());
    } else if (currentKey != null) {
      currentVal.write('\n$line');
    }
  }
  if (currentKey != null) {
    kv[currentKey] = currentVal.toString().trim();
  }

  // Helper to read a key case-insensitively
  String readKey(String key) {
    for (final entry in kv.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) {
        return entry.value;
      }
    }
    return '';
  }

  return ParsedPostPackage(
    title: readKey('Title'),
    postType: _normalizePostType(readKey('Post Type').isNotEmpty
        ? readKey('Post Type') : readKey('PostType')),
    audience: readKey('Audience').isNotEmpty
        ? readKey('Audience') : 'Parents of 3-6 year olds',
    contentGoal: readKey('Content Goal'),
    mood: readKey('Mood'),
    hook: readKey('Hook'),
    mainIdea: readKey('Main Idea'),
    problem: readKey('Problem'),
    lesson: readKey('Lesson'),
    visualStyle: readKey('Visual Style'),
    imagePrompt: _sectionText(sections, ['image prompt', 'imageprompt']),
    caption: _sectionText(sections, ['caption']),
    cta: readKey('CTA'),
    hashtags: readKey('Hashtags'),
    pinnedComment: _sectionText(sections, ['pinned comment', 'pin comment']),
    replyComments: _parseComments(_sectionText(sections, ['reply comments', 'comments'])),
    script: _sectionText(sections, ['script', 'carousel text', 'carousel']),
    bucket: _resolveBucket(readKey('Bucket')),
  );
}

String _normalizePostType(String value) {
  final v = value.trim().toLowerCase();
  if (v.contains('static')) return 'Static Image';
  if (v.contains('reel')) return 'Reel';
  if (v.contains('carousel') || v.contains('carous')) return 'Carousel';
  if (v.contains('story')) return 'Story';
  return value.trim().isEmpty ? 'Carousel' : value.trim();
}

String _sectionText(Map<String, List<String>> sections, List<String> keys) {
  for (final key in keys) {
    final lines = sections[key];
    if (lines != null && lines.isNotEmpty) {
      return lines.join('\n').trim();
    }
  }
  return '';
}

List<String> _parseComments(String text) {
  if (text.trim().isEmpty) return [];
  final lines = text.split('\n');
  final comments = <String>[];
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final match = RegExp(r'^(\d+)\.?\s*(.*)$').firstMatch(trimmed);
    if (match != null && match.group(2)!.isNotEmpty) {
      comments.add(match.group(2)!);
    } else if (!trimmed.startsWith('1.') && !trimmed.startsWith('2.')) {
      comments.add(trimmed);
    }
  }
  return comments;
}

String _resolveBucket(String name) {
  final b = bucketByName(name);
  if (b != null) return b.id;
  final lower = name.toLowerCase();
  if (lower.contains('puzzle') || lower.contains('figure') || lower.contains('hidden') || lower.contains('pattern')) return 'challenge';
  if (lower.contains('humor') || lower.contains('funny') || lower.contains('mumma')) return 'humor';
  if (lower.contains('activity') || lower.contains('challenge') || lower.contains('hunt')) return 'activity';
  if (lower.contains('talk') || lower.contains('question') || lower.contains('ask')) return 'conversation';
  if (lower.contains('skill') || lower.contains('year-old') || lower.contains('checklist')) return 'age_practice';
  if (lower.contains('wrap') || lower.contains('favorite') || lower.contains('feedback')) return 'community';
  return '';
}
