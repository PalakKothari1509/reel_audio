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
import 'models/quick_idea.dart';

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

  /// True for posts that have been retired from active rotation.
  final bool archived;

  /// Full 3-part video prompt detail for offline generation. Empty when the
  /// offline generator should derive prompts from the story template fields.
  final String storyDetail;

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
    this.archived = false,
    this.storyDetail = '',
  });

  HookIdea copyWith({
    String? id,
    String? category,
    String? cover,
    String? opening,
    String? problem,
    String? lesson,
    String? postFormat,
    String? strategy,
    String? caption,
    String? pinnedComment,
    bool? forApp,
    String? usedOn,
    bool? custom,
    bool? archived,
    String? storyDetail,
  }) =>
      HookIdea(
        id: id ?? this.id,
        category: category ?? this.category,
        cover: cover ?? this.cover,
        opening: opening ?? this.opening,
        problem: problem ?? this.problem,
        lesson: lesson ?? this.lesson,
        postFormat: postFormat ?? this.postFormat,
        strategy: strategy ?? this.strategy,
        caption: caption ?? this.caption,
        pinnedComment: pinnedComment ?? this.pinnedComment,
        forApp: forApp ?? this.forApp,
        usedOn: usedOn ?? this.usedOn,
        custom: custom ?? this.custom,
        archived: archived ?? this.archived,
        storyDetail: storyDetail ?? this.storyDetail,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'cover': cover,
        'opening': opening,
        'problem': problem,
        'lesson': lesson,
        'forApp': forApp,
        'usedOn': usedOn,
        'custom': custom,
        'archived': archived,
        'postFormat': postFormat,
        'strategy': strategy,
        'caption': caption,
        'pinnedComment': pinnedComment,
        'storyDetail': storyDetail,
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
        archived: j['archived'] as bool? ?? false,
        storyDetail: j['storyDetail'] as String? ?? '',
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
      'Pinned comment: $pinnedComment\n'
      '${storyDetail.isNotEmpty ? '$storyDetail\n' : ''}'
      'Status: ${usedOn.isEmpty ? "New" : usedOn}';
}

const kHookCategories = [
  'Relatable',
  'Struggle first',
  'Surprising',
  'Warm lesson',
  'Page & milestone',
  'Navratri',
  'Series',
];

/// Kids Safety hooks for the 🛡️ collection.
/// Each carries a full storyDetail with the Story/Twist/Resolution/Moral
/// labels the offline generator expects.
const kSafetyHooks = <HookIdea>[
  HookIdea(
    id: 'safety-good-touch',
    category: 'Warm lesson',
    cover: 'Meri Marzi!',
    opening: 'Uncle bole "Ek pappi do"... aur Ria ne bola nahi.',
    problem: 'A relative asks for a hug and a kiss, and Ria does not want to',
    lesson: 'Bachche ko "nahi" kehne ka haq hai, aur bade ko sunna chahiye',
    forApp: true,
    caption: 'जब कोई भी touch अच्छा न लगे, तो तुरंत मम्मी या पापा के पास चला जाओ। Family code word तय करें — अगर कोई पूछे, तो कहें "मम्मी ने कहा था!" कभी भी अपना number न दिखाएं। #ChildSafety #GoodTouchBadTouch #SafetyFirst #IndianParents #FunLearningWithPalak',
    storyDetail: '''
Story: At Daadi's house, an uncle opens his arms: "Ria, hug?" Ria hides behind Mumma: "Nahi, mujhe hug nahi chahiye."
Twist: Mumma: "Theek hai. Wave, high-five, ya kuch bhi nahi—Ria choose karegi." Ria gives a small wave from beside Mumma.
Resolution: Uncle smiles: "Wave bhi accha hai." End card: "Aap hug ke bina bhi pyaar dikha sakte ho."
Moral: Body autonomy starts with a simple "no thank you."
''',
  ),
  HookIdea(
    id: 'safety-stranger',
    category: 'Warm lesson',
    cover: 'Chocolate Nahi!',
    opening: 'Park mein aunty ne chocolate di... Ria ne kya kiya?',
    problem: 'A person Ria does not know offers her a chocolate at the park',
    lesson: 'Jo hume nahi jaanta, uske saath nahi jaate',
    forApp: true,
    caption: 'जो हम नहीं जानते, उनसे कुछ नहीं लेना सीखाएं। Family code word: अगर कोई दावा करे या पूछे तो कोड शब्द बताओ। #StrangerSafety #ChildSafety #SafetyTips #IndianParents #FunLearningWithPalak',
    storyDetail: '''
Story: At park, stranger offers Ria chocolate: "Mere saath chalo, aur milegi."
Twist: Ria takes two steps back: "Mumma!" She remembers the family code word: "Mumma ne kaha tha!"
Resolution: Mumma runs over. They practice saying no, staying with trusted adult. Code word confirmed.
Moral: "Mere saath chalo" — but only with people you know and trust.
''',
  ),
  HookIdea(
    id: 'safety-road',
    category: 'Warm lesson',
    cover: 'Ruko, Dekho, Chalo!',
    opening: 'Zebra crossing par Rio ruk gaya... kisi ne bola nahi tha!',
    problem: 'Toddlers run toward the road without stopping or looking',
    lesson: 'Red light, green light ka khel ghar par seekho',
    forApp: true,
    caption: 'सड़क पार करते समय हमेशा adult के साथ चलें। Family code word: अगर कोई मदद पूछे तो कहें कोड शब्द। #RoadSafety #ChildSafety #CrossingSafety #IndianParents #FunLearningWithPalak',
    storyDetail: '''
Story: Ball rolls toward the gate. Rio starts after it, takes two steps — "Ruko—road!"
Twist: Mumma grabs his hand: "Stop, look, listen." They count cars together. "Ab green light?"
Resolution: Mumma: "Jab grown-up kahe aur saaf ho." They hold hands and cross together.
Moral: Khel mein seekha — sadak par bhi kaam aayega.
''',
  ),
  HookIdea(
    id: 'safety-emergency-number',
    category: 'Warm lesson',
    cover: 'Mera Number Gaana',
    opening: 'Ria ko Mumma ka number yaad nahi tha... phir gaana bana.',
    problem: 'A preschooler cannot recall a parent\'s phone number when asked',
    lesson: 'Gaane mein yaad karna aasaan hota hai',
    forApp: true,
    caption: 'घर में एक family code word रखें — सिर्फ़ परिवार जानता है। कभी भी real emergency number न दिखाएं, बस code word से सुरक्षित रहें। #EmergencySafety #ChildSafety #SafetyTip #IndianParents #FunLearningWithPalak',
    storyDetail: '''
Story: Papa makes a clapping rhythm with family contact details — name first, number made of pretend digits on screen. Ria remembers her name first.
Twist: The family practises: "Agar mummy nahi ho toh — Dada, ya neighbor?" Ria points to Dada.
Resolution: "Pura number yaad rakho," Papa says, "lekin pehle apna naam bolo." Ria: "Main Ria hoon."
Moral: Name pehle, number baad mein — safety starts with identity.
''',
  ),
  HookIdea(
    id: 'safety-lost-crowd',
    category: 'Warm lesson',
    cover: 'Mela Mein Kho Gayi',
    opening: 'Bheed mein Mumma ka haath chhoot gaya... ab kya?',
    problem: 'Ria loses her parents\' hand in a crowded fair',
    lesson: 'Kho jao toh ruk jao, aur sahi insaan se madad maango',
    forApp: true,
    caption: 'खो जाओ तो रुक जाओ और सुरक्षित adult से मदद माँगो। Family code word: अगर कोई पूछे तो कहें "मम्मी ने सिखाया था!" #LostChild #CrowdSafety #ChildSafety #IndianParents #FunLearningWithPalak',
    storyDetail: '''
Story: At mela, Ria can't see Mumma. She stops near the help desk — stays put.
Twist: She tells a uniformed worker: "Mera naam Ria hai. Mumma kho gayi hain." Worker nods, radios for help.
Resolution: In minutes, Mumma rushes over. "Family code word?" Ria: "Chocolate!" Mumma hugs her.
Moral: Stop, stay, tell — and trust a uniformed helper.
''',
  ),
  HookIdea(
    id: 'safety-kitchen-line',
    category: 'Warm lesson',
    cover: 'Laal Line Ke Peeche',
    opening: 'Rasoi mein Ria ko aage jaana tha... par ek line thi.',
    problem: 'A toddler keeps wandering into the kitchen while the stove is on',
    lesson: 'Garam jagah ke liye ek clear line banao',
    forApp: true,
    caption: 'गर्म जगह के पास न जाना — लाल line हमेशा मानें। Family code word: अगर कोई मदद करना चाहे तो कोड शब्द बताओ। #KitchenSafety #ChildSafety #SafetyFirst #IndianParents #FunLearningWithPalak',
    storyDetail: '''
Story: Gas jal rahi hai — Ria yahin rukegi. Mumma is cooking; Ria carries a toy car toward the stove.
Twist: Mumma: "Gas jal rahi hai—Ria yahin rukegi." Ria stops where the red line is drawn.
Resolution: Papa adds a floor marker the next day: "Laal line = safe boundary." Ria stays behind it, watching safely.
Moral: Grown-up present, boundary clear — safety needs both.
''',
  ),
];

/// The starting list. Merged from several AI suggestions and cut down hard: the same
/// three problems (screen time, shoes, toy fights) appeared four or five times each,
/// and several were written as "I" — a parent speaking — when the reels are told by a
/// storyteller about Ria and Rio.
const kDefaultHooks = <HookIdea>[
  // Relatable: the child's own words, the thing every parent has heard this week.
  HookIdea(
    id: 'h01',
    category: 'Relatable',
    cover: 'Main Khud!',
    opening: 'Ria ne Mumma ka haath jhatak diya... joote khud pehnenge!',
    problem: 'Ria insists on putting her shoes on herself and pushes Mumma away',
    lesson: 'Thoda intezaar, aur bachcha khud seekh jaata hai',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma is running late; Ria plants her feet — "Main khud!" Shoe goes on the wrong foot, slips off, she tries again and nearly gives up.
Twist: Mumma softly counts to five instead of grabbing the shoe. "Ek, do, teen, char, paanch…"
Resolution: Ria turns the shoe the right way, gets it on, and beams: "Dekha? Shoe ko bhi direction chahiye thi!"
Moral: A little patience and a count to five gives Ria a win she earned herself.
''',
  ),
  HookIdea(
    id: 'h02',
    category: 'Relatable',
    cover: 'Bas 5 Minute Aur?!',
    opening: 'Phone band hua... aur Ria ka rona shuru!',
    problem: 'Ria cries when cartoon ends mid-song without warning',
    lesson: 'Two-minute warning helps Ria choose a calm goodbye',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Cartoon ends mid-song. Ria protests: "Bas five minute aur!" Mumma admits it was abrupt.
Twist: Next time Mumma gives a two-minute warning. Ria chooses goodbye: wave or sing.
Resolution: Ria waves at the screen, switches off, and asks Robot to draw the character.
Moral: Transition works better with a warning — and letting the child pick the goodbye.
''',
  ),
  HookIdea(
    id: 'h03',
    category: 'Relatable',
    cover: 'Mujhe Nahi Aata!',
    opening: 'Rio ka tower teesri baar gira... aur usne haar maan li.',
    problem: 'Rio gives up when his block tower keeps falling',
    lesson: 'Galti se hi seekhte hain, phir se try karo',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Tower falls third time. Rio throws his hands up: "Mujhse nahi hoga!"
Twist: Ria offers to help; Rio refuses: "Mera tower!" Cuty slides a wide base block toward him.
Resolution: Rio tries a wider base, builds a shorter tower, and grins: "Yeh tower nahi—building ka ground floor hai!"
Moral: Support means helping children think, not doing it for them.
''',
  ),
  HookIdea(
    id: 'h04',
    category: 'routines',
    cover: 'Cuty Kahan Gaya?!',
    opening: 'Ria ki awaaz tezi — "Cuty kahan gaya?!"',
    problem: 'Room so messy they keep getting distracted',
    lesson: 'Clear one small path at a time',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria shouts, "Cuty kahan gaya?!" The floor is a toy jungle. Every time Rio searches, he starts playing.
Twist: Ria makes a "Cuty rescue basket" — they clear just one path, then spot Cuty asleep under a blanket.
Resolution: Rio whispers, "Hum poora room saaf karne aaye the?" Ria: "Shhh, patient so raha hai."
Moral: Ek chhota sa raasta bhi bada madad karta hai.
''',
  ),
  HookIdea(
    id: 'h05',
    category: 'Relatable',
    cover: 'Ek Aur Paani!',
    opening: 'Lights band... aur Ria ko phir se paani chahiye.',
    problem: 'Bedtime stretches on with one more water, one more story, one more hug',
    lesson: 'Roz ek jaisa routine, neend jaldi aati hai',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Lights off. Ria calls out: "Mumma, ek aur paani!" Mumma brings it. Then Ria remembers: "Teddy ko blanket chahiye." Mumma brings that too. "Aur ek hug?" Planned hug. Ria snuggles in.
Twist: Mumma pre-places a small cup and a hug-stuffed animal on the bedside table the next night.
Resolution: When lights go off, Ria reaches for both. "Ab bas... unless Teddy ko paani chahiye."
Moral: A little prep turns the endless loop into a quiet goodnight.
''',
  ),
  HookIdea(
    id: 'h06',
    archived: true,
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h14 — single toy-car conflict with ticket-based turns)
''',
    cover: 'Meri Car Hai!',
    opening: 'Ria aur Rio ne car do taraf se kheenchi...',
    problem: 'Ria and Rio fight over one toy car',
    lesson: 'Baari baari khelne mein sabka mazza',
  ),
  HookIdea(
    id: 'h07',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria refuses: "Brush nahi!" Mumma picks up Cuty's brush: "Pehle Cuty ki teeth clean karte hain."
Twist: Tiny circles on Cuty's toy teeth. Ria watches, then grabs a brush. "Cuty ke teeth clean, ab mere!"
Resolution: Mumma helps guide Ria's hand through the last stubborn spot. Ria spits, grins at her sparkly smile.
Moral: Watching a friend get first makes the real thing feel less scary.
''',
    cover: 'Brush Nahi Karungi!',
    opening: 'Ria kambal ke andar chhup gayi... brush ke dar se!',
    problem: 'Ria hides under the blanket to avoid brushing her teeth',
    lesson: 'Khel banao, zidd khud chali jaati hai',
  ),
  HookIdea(
    id: 'h08',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Papa holds up broccoli: "Dekho, mini tree!" He takes a dinosaur bite first.
Twist: Then the real bite. Ria studies it. "Is tree ka taste kaisa?"
Resolution: She decides — one small bite, then another. Or: "Thoda sa, phir dil se."
Moral: A bite modeled first feels safe enough to try.
''',
    cover: 'Broccoli? Bilkul Nahi!',
    opening: 'Plate aage aayi... aur Ria ne haath baandh liye.',
    problem: 'Ria refuses vegetables at the table',
    lesson: 'Khud banaya khaana, khud khaane ka mann',
  ),
  HookIdea(
    id: 'h09',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: "Shoes pehen lo, park jaana hai." Ria: "Main half-ready hoon!" Rio sits with one shoe on, one off.
Twist: Mumma: "Rio full-ready nahi, full-confused hai!" She kneels, points to toes.
Resolution: They fix both shoes together. Ria helps Rio tie his lace. "Partner ban gayi!"
Moral: Getting ready is faster when you help each other put things right.
''',
    cover: 'Half-Ready Hoon!',
    opening: 'Joote pehenlo... park jaana hai. Rio ne ulta laga diya.',
    problem: 'Ria wants to leave but Rio shoes are on wrong feet',
    lesson: 'Chhote galtiyan, saath mein theek ban jaati hain',
  ),

  // New built-in content ideas from Palak's marketing and character plan.
  HookIdea(
    id: 'pal01',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: At the park, three swings — three personalities.
Slide 1 (Negotiator): Ria — "Mere saath 5 minute, phir Rio karega!" She bargains for extra turns.
Slide 2 (One-more-minute kid): Rio — "Ek aur slide, ek aur!" He protests every transition.
Slide 3 (Escape artist): Cuty — slides off, hides behind Mumma's leg, sneaks away mid-count.
Twist: Mumma gives each a match: Ria negotiates timing, Rio picks a goodbye song, Cuty gets a quiet corner.
Resolution: Three swings, three needs — and Mumma's voice stays calm through them all.
Moral: Your kid will sit in any of these seats. Which one is yours?
''',
    cover: 'Which Kid Is Yours?',
    opening: 'Ria = tofani, Rio = ziddi, Cuty = sleep lover.',
    problem: 'Parents want to recognise their child in a playful character style',
    lesson: 'Every child has a personality and every family sees themselves in it',
  ),
  HookIdea(
    id: 'pal02',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Slide 1 — Parent says: "Time to clean up!" Toddler hears: "Fun stopped forever."
Twist: Slide 2 — Parent says: "Just put the blocks in the box." Toddler hears: "I failed my life's work."
Resolution: Slide 3 — Parent: "You choose one more tower, then 2 minutes cleanup?" Toddler hears: "I get a say!"
Moral: Toddler subtitles are fiction — but what they actually hear matters more than what you said.
''',
    cover: '7 Things Every Toddler Does',
    opening: 'Says no, wants the same spoon, and suddenly needs Mumma.',
    problem: 'Parents need a humorous way to see their own daily chaos reflected back',
    lesson: 'The tiny behaviours are the funny little signs of childhood',
  ),
  HookIdea(
    id: 'pal03',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma: "Abhi chocolate nahi." Three reactions in three seconds.
Twist: Ria negotiates — "Bas ek piece, maine kal se diet shuru karungi!" Rio drops to the floor — "NO!" Cuty quietly munches a carrot.
Resolution: Mumma: "Carrot nahi? Theek hai." She hands Cuty a cheese cube. Ria gets a story, Rio gets a countdown hug.
Moral: One "no" can meet three different needs — see each before you solve.
''',
    cover: 'Three Kids, One No',
    opening: 'Ria protests, Rio refuses, Cuty quietly gives in.',
    problem: 'The same parent boundary can trigger three very different reactions',
    lesson: 'Kids react differently, but all of them need patience and clarity',
  ),
  HookIdea(
    id: 'pal04',
    archived: true,
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h02 — duplicate screen-time story)
''',
    cover: 'Merged h02',
    opening: 'Screen time transition merged into h02',
    problem: 'Duplicate of h02',
    lesson: 'Consolidated into h02',
  ),
  HookIdea(
    id: 'pal05',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio: "Mujhe neend nahi aa rahi!" He sits bolt-upright, mid-story, mid-sentence, yawns so wide Mumma sees his toy car inside.
Twist: His eyes start drooping — the car slips from his hand. "Evidence mil gaya."
Resolution: Mumma quietly places a pillow under his arm, reads one more page, and by page three his breathing is even.
Moral: Sometimes the loudest protest ends with the softest sleep.
''',
    cover: 'Neend Ka Evidence',
    opening: 'Rio kehte hain... "Mujhe neend nahi!" Tab tak jab tak nahi.',
    problem: 'Rio protests sleep loudly, then falls asleep mid-story',
    lesson: 'Protest ke baad bhi mamla sul jata hai',
  ),
  HookIdea(
    id: 'pal06',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Morning check: one sock by the couch, shirt inside-out, water bottle left on the chair.
Twist: Ria spots her own sock—"Mumma, maine hi girana diya!"—and laughs instead of crying.
Resolution: They make a "morning checklist" together: sock, shirt, bottle. Rio adds "smile" at the end.
Moral: Small things make big mornings — and finding your own lost sock feels like winning.
''',
    cover: 'Ek Sock Gir Gaya!',
    opening: 'Socks missing, shirt reversed, bottle abandoned. Morning chaos.',
    problem: 'Morning routine creates scattered chaos across the house',
    lesson: 'Ek checklist, ek family banati hai',
  ),
  HookIdea(
    id: 'pal07',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria: "Ready Captain!" — but she changes her hair clip three times: blue bow, pink bow, no bow.
Twist: Rio points at the clock: "Time khatam ho raha hai!" Cuty is still tying his shoes.
Resolution: Ria picks "no bow" and helps Cuty with his second shoe. "Jab tak sabke saath, tab tak team complete."
Moral: Being first ready doesn't mean you leave everyone behind.
''',
    cover: 'Ready Captain!',
    opening: 'Ria: "Done!" Par hair clip wapas badal rahi hai.',
    problem: 'Ria is ready but keeps fussing over small details',
    lesson: 'Tumse pehle ready hone se matlab nahi, team chhod dena',
  ),
  HookIdea(
    id: 'pal08',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Crumbs on Cuty's nose. Ria: "Mumma, Mumma — koi ne cookies khaaye!" Points at Rio.
Twist: Mumma: "Let's check." Cuty's nose — cookie crumbs. Rio's mouth — clean.
Resolution: Ria: "Mujhe pata hai!" She wipes Cuty's nose with a tissue. "Innocent rabbit!"
Moral: The most obvious suspect is often the cutest.
''',
    cover: "Cuty's Nose",
    opening: 'Crumbs everywhere... Ria points at Rio.',
    problem: 'Crumbs on Cuty nose, Ria blames wrong suspect',
    lesson: 'Sabse pyaara baccha sabse zyada blame kamaati hai',
  ),
  HookIdea(
    id: 'pal09',
    archived: true,
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h01 — second shoe independence story)
''',
    cover: 'Main Khud!',
    opening: 'Merged into h01',
    problem: 'Duplicate of h01',
    lesson: 'Consolidated',
  ),
  HookIdea(
     id: 'pal10',
    category: 'parent',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma tells Ria at bedtime, "Aaj jaldi sona hai." Later that night, Ria tucks Teddy in and repeats Mumma's phrase: "Teddy, negotiation band."
Twist: Mumma, sitting nearby on the bed, tries not to laugh — she's heard every word.
Resolution: Ria whispers, "Mumma ne kaha tha!" and Mumma gives her a quiet hug.
Moral: Jo baatein hum dete hain, wohi din mein dobara sunai deti hain — par pyaar ke saath.
''',
    cover: 'Mumma Ne Kaha Tha!',
    opening: 'Mumma ne kaha — "Aaj jaldi sona hai."',
    problem: 'Children repeat the smallest things adults say — often at exactly the wrong moment',
    lesson: 'Small phrases stick; what we say becomes their inner voice',
  ),
  HookIdea(
    id: 'pal11',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: At the supermarket, Mumma gives each a job — Ria: "Pick the yellow fruit." Rio: "Find the big box." Cuty: "Carry the list."
Twist: Ria comes back with a yellow choochoo train, Rio drags a giant cereal box twice his size, and Cuty "carries" the list by sitting on it.
Resolution: They all crack up — "Hamari shopping team badi achhi hai!" — and Ria trades the train for mangoes.
Moral: Give them a role, even if they misunderstand — the practical result is still teamwork.
''',
    cover: 'At The Supermarket',
    opening: 'Ria wants everything, Rio wants the toy, Cuty is already ready to go home.',
    problem: 'Shopping turns into a mini-lesson in patience, negotiation and excitement',
    lesson: 'Every child brings a different energy into the same space',
  ),
  HookIdea(
    id: 'pal12',
    archived: true,
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h05 — third bedtime story)
''',
    cover: 'Bedtime Merged',
    opening: 'Merged into h05',
    problem: 'Duplicate of h05',
    lesson: 'Consolidated',
  ),
  HookIdea(
    id: 'pal13',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria wants the toy car to go on the road trip — "Car bhi ghar chalegi!"
Twist: "Seatbelt ka concept samajh aa gaya?" Mumma buckles the car into a backpack: "Tumhara travel bag, car ke saath!"
Resolution: Rio inspects the backpack — "Lock hai!" — and the car rides along, buckled and safe.
Moral: Two choices beat a fight — one for the car, one for the journey.
''',
    cover: 'Car Bhi Ghar Chalegi!',
    opening: 'Car ko bhi le jaane ka plan ban gaya.',
    problem: 'Child insists favorite toy must come along for outings',
    lesson: 'Buckle the toy into the trip, not the argument',
  ),
  HookIdea(
    id: 'pal14',
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is crying over a torn drawing—"MERI drawing phaa gaya!"
Twist: Mumma kneels: "Yeh paper toh gaya, lekin yeh drawing tumhara saath nibhaati hai."
Resolution: They make a new drawing together — "Nayi shuruaat!" — and Ria's tears turn to giggles.
Moral: Big feelings over small things are real — and they deserve big love to match.
''',
    cover: 'Big Feelings, Little Problems',
    opening: 'To a child, a broken biscuit or a missing sock feels enormous.',
    problem: 'Little problems can feel huge when your child is overwhelmed',
    lesson: 'What seems small to us is often a big emotion to them',
  ),
  HookIdea(
     id: 'pal15',
    category: 'parent',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Papa: "Do blocks aur, phir shoes." Rio: "Ab do aur do!"
Twist: Papa holds firm: "Ek bite dal, phir do-minute phone." Rio stomps but the timer starts.
Resolution: They settle at "Ek bite dal, phir do-minute phone." Rio gets the timer and phone, then takes his bite of dal — everyone wins a high-five.
Moral: Ek chhota sa bargain sabke liye badi khushiyon ka source.
''',
    cover: 'Do Aur Do!',
    opening: 'Papa: "Do blocks aur, phir shoes." Rio: "Ab do aur do!"',
    problem: 'Toddler insists on more — more blocks, more time, more everything',
    lesson: 'One small bargain can turn "more" into "done"',
  ),
  HookIdea(
     id: 'pal16',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio's vocabulary for the day is just "No!" "Mine!" "Why!" — three escalating moments when Ria tries to share, take, and explain.
Twist: Everyone echoes "No! Mine! Why!" — Ria: "No, mujhe bhi!" — and Cuty gets confused: "Toh kya sabke paas ek hi jawaab hai?"
Resolution: They count all the "no, mine, why" moments — and end with Rio handing Cuty the ball: "Tumhara bhi hai."
Moral: One word can fill a whole day — and then just as quickly, it can end.
''',
    cover: 'No, Mine, Why!',
    opening: 'Rio kehte hain: No! Mine! Why!',
    problem: 'One word repeated drives parents to the edge of sanity',
    lesson: 'Lean into the word — count it, echo it, then watch it lose its power',
  ),
  HookIdea(
    id: 'pal17',
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria has a scraped knee and sits on the couch, sulking.
Twist: Cuty sits beside her, nudges a fresh sheet of paper over. "Napkins please," Ria whispers.
Resolution: They wrap the knee together — no lectures, no "it's okay" speeches. Just quiet presence.
Moral: Sometimes the best help is sitting close with a clean sheet.
''',
    cover: 'Cuty Stays Close',
    opening: 'Ria neeche bethi... Cuty saath bhi baithi.',
    problem: 'Child sulks after injury; comfort comes from quiet presence',
    lesson: 'Cuddle, no lecture — presence over words',
  ),
  HookIdea(
    id: 'pal18',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Cuty's brush is missing — "Cuty brush kahaan hai?" — but it's not under the bed.
Twist: Rio's shoes are missing too — he's been wearing Cuty's brush like a hairbrush in his hair.
Resolution: "Ab dono milenge!" — brush goes back to Cuty, shoes to Rio. Everyone laughs at the mix-up.
Moral: Lost things are usually found in the wrong place — and the wrong place is often hilarious.
''',
    cover: 'Brush vs Shoes!',
    opening: 'Brush kahaan? Shoes kahan? Sab kuchh ulta ho gaya.',
    problem: 'Cuty brush and Rio shoes get swapped in the morning',
    lesson: 'Misplaced items lead to funny mix-ups',
  ),
  HookIdea(
    id: 'pal19',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma asks, "Jootey kahan rakha?"—and gets 5 different answers.
Twist: Rio says, "Mummy ne kaha tha woh wahan!"—but Ria points to the couch.
Resolution: They find the shoes, but Cuty has "borrowed" them as a drum—"Dum-dum-dum!"
Moral: Memory is subjective—but family humor makes every search an adventure.
''',
    cover: 'Mumma Says This Daily',
    opening: 'Put your shoes on, stop running, where is your bottle, and come here.',
    problem: 'Parents repeat the same phrases each day because the day repeats itself',
    lesson: 'Even the hard repeated words are part of the family rhythm',
  ),
  HookIdea(
     id: 'pal20',
    category: 'parent',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma comes home tired, bag on floor. Ria notices, picks up bag, hands it over. Small believable gesture.
Twist: Mumma starts to take the bag back — "Beta, I've got it."
Worse: Ria insists: "Tum bahut thak gayi ho. Main help kar sakta hun."
Resolution: Mumma lets Ria help. They sit together — Mumma with her tea, Ria with a small drawing. No words about growing up; just two people being quiet.
Ending line: "Mumma: Shukriya beta. Ria: Tumhara saath hi toh maza aata hai."
Moral: Sometimes noticing is the gift.
''',
    cover: 'Notice the Bag!',
    opening: 'Mumma neeche gir gaya bag, Ria ne notice kiya.',
    problem: 'Children see when parents are tired — and can offer small help without being asked',
    lesson: 'A small gesture needs no speech; noticing is already love in action',
  ),

  // Struggle first: open on the moment it goes wrong.
  HookIdea(
    id: 'h10',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Blue paint tips onto a perfectly clean white table — "Arre, blue paint!" Napkin smears it wider.
Twist: Mumma moves the paint cup away, gives a damp cloth. "Table ko blue dress chahiye thi."
Resolution: Rio scrubs, watches the blue disappear. Table is clean again, but Rio is streaked with blue.
Moral: A spill can look huge — but a little help makes it manageable.
''',
    cover: '1 Galti, Bada Mess!',
    opening: 'Rio ke haath se saare rang gir gaye...',
    problem: 'Rio spills paint everywhere by accident',
    lesson: 'Galti pe gussa nahi, saath mein saaf karo',
  ),
  HookIdea(
    id: 'h11',
    archived: true,
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h03 — second tower story)
''',
    cover: 'Tower Gir Gaya!',
    opening: 'Rio zameen pe lot gaya... sirf blocks ke liye?',
    problem: 'Rio has a big tantrum when his tower breaks',
    lesson: 'Pehle gale lagao, phir samjhao',
  ),
  HookIdea(
    id: 'h12',
    category: 'Struggle first',
    cover: 'Mumma Bhi Thak Gayi!',
    opening: 'Mumma: "Bas 5 minute rest." Lies down. Ria tucks her in.',
    problem: 'Mumma needs rest but asks Ria to respect it',
    lesson: 'Thoda sa pause, poori family ke liye',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma sits down — "Bas five minute rest." She lies on the floor with a cushion.
Twist: Ria tucks a blanket over her: "Ab paani nahi maangna, okay?" Mumma: "Main itni bhi dramatic hoon?"
Resolution: Ria: "Mumma, aap hi toh ho." She brings a small cup of water and sits quietly beside her.
Moral: When grown-ups rest, children learn that love doesn't always mean fixing — sometimes just being there.
''',
  ),
  HookIdea(
    id: 'h13',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria's block tower gets knocked — pieces scatter. Mumma crouches down: "Pehle cuddle ya paani?"
Twist: Ria's body language shifts — shoulders drop, she leans toward Mumma. "Cuddle."
Resolution: One hug, then they rebuild together. "Tower phir se lagega!" Cunty the bunny hops over to sniff a block.
Moral: Meeting feelings first makes solutions stick.
''',
    cover: 'Pehle Cuddle Ya Paani!',
    opening: 'Tower gir gaya... Mumma crouch karti hain.',
    problem: 'Child upset after tower falls; needs feeling-first response',
    lesson: 'Body language se pehle baat karo',
  ),
  HookIdea(
    id: 'h14',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Both grab the red car — "Mera pehle!" They argue over whose lap it is for.
Twist: Mumma: "Rio one lap, Ria one lap." They make paper tickets — Rio gets #1, Ria gets #2.
Resolution: Cuty sits as ticket checker. One minute each, then together. "Dono car, do laps!"
Ending line: "Next time? Ek ticket, teen dots!"
Moral: Tickets turn fights into fair turns — everyone wins a lap.
''',
    cover: 'Tod Diya!',
    opening: 'Car ke do tukde... aur dono ek doosre ko blame kar rahe hain.',
    problem: 'The shared toy breaks and both children blame each other',
    lesson: 'Kaun jeeta nahi, saath mein kaise theek karein',
  ),

  // Surprising: says the opposite of what a parent expects, then shows it.
  HookIdea(
    id: 'h15',
    category: 'Surprising',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio is dancing to his favorite song when the music suddenly stops mid-beat. Rio freezes, eyes wide.
Twist: Mumma names the change: "Music bandh ho gayi. Ab kya karein?" She offers: "Ek minute aur dance karo, ya turant room saaf karo?"
Resolution: Rio chooses one more minute of dance, then they clean up the toys together. Mumma restarts soft music.
Ending line: Rio: "Next time phone use karoongi!" Mumma: "Haan, volume button dikha."
Moral: Badlaav ka intezaar karo, phir agla kadam lagao.
''',
    cover: 'Music Sudden Ruko!',
    opening: 'Music bandh ho gayi... Rio freezz!',
    problem: 'Music suddenly stops mid-play, and Rio freezes or protests',
    lesson: 'Name the change, then offer the next step',
  ),
  HookIdea(
    id: 'h16',
    category: 'Surprising',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio is bored with all his expensive toys—"Kuchh bhi nahi maza aa raha!"
Twist: He spots an empty box—"Mummy, yeh dabba rocket ban sakta hai!"
Resolution: Mumma helps him decorate it—"Dabba rocket tayar!"—and Rio blasts off across the living room.
Moral: Simple things spark the biggest imagination.
''',
    cover: 'Dabba Ban Gaya Rocket!',
    opening: 'Itne saare khilone... aur Rio ko chahiye khaali dabba?',
    problem: 'Expensive toys are ignored; an empty box becomes a spaceship',
    lesson: 'Kam khilone, zyada kalpana',
  ),
  HookIdea(
    id: 'h17',
    category: 'Surprising',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Light flickers, fan cuts out mid-hum. Ria tugs Mumma's hand: "Bijli ko bolo band ho jaye!"
Twist: Mumma kneels: "Thumbs up if you're worried. Bijli khel rahi thi—ab rest karegi."
Resolution: They sit in the quiet. Ria discovers she can hear her own heartbeat. "Thump-thump!" "It means you're safe."
Moral: Naming the noise makes the fear small enough to hold.
''',
    cover: 'Bijli Band Ho Gayi!',
    opening: 'Lifi krik krak... fan ruka. Ria: "Bijli band ho jaye!"',
    problem: 'Power cuts out suddenly and Ria is startled',
    lesson: 'Naam dekar dar ko chhota karna',
  ),
  HookIdea(
    id: 'h18',
    category: 'Surprising',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio dumps a box of blocks everywhere. Mumma points: "Tumne saare blocks box mein rakhe—thank you!"
Twist: Rio beams, then spots one block hiding behind the couch. "Mummy, yeh bhi!"
Resolution: They put the last block in together. Papa claps. "Box full, heart full."
Moral: Cleaning up becomes a team win when the praise names what they did.
''',
    cover: 'Blocks Box Mein!',
    opening: 'Rio ne saare blocks phailaye... Mumma ne name dia.',
    problem: 'Rio dumps blocks; Mumma names the cleanup action',
    lesson: 'Specific praise builds confidence',
  ),
  HookIdea(
    id: 'h19',
    category: 'Surprising',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma says "Mat bhaago" at the crossing—Rio runs faster!
Twist: Mumma changes—"Ruko, phir dheere chalo"—Rio walks right beside her.
Resolution: They cross together, hand in hand, and Rio says, "Mummy aapka haath pakadna sabse achcha hai!"
Moral: Tell them what TO do, not what NOT to do—children follow positive direction.
''',
    cover: 'Bhaago Mat? Dheere Chalo!',
    opening: 'Mumma ne "mat bhaago" bola... Rio aur tez bhaaga!',
    problem: "A child ignores \"don't\" but follows a clear \"do\"",
    lesson: 'Kya nahi karna, nahi — kya karna hai, woh batao',
  ),

  // Warm lesson: gentle stories that end on something a parent wants to keep.
  HookIdea(
    id: 'h20',
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
storyDetail: '''
Story: Rio takes cookie from the jar again—"Mummy, maine bas ek hi liya tha!"
Twist: Instead of shouting, Mumma kneels down—"Haan beta, tumne kara. Par main tumhe pyar karti hoon."
Resolution: Rio hugs her—"Next time I'll ask pehle!"—and puts the cookie back in the jar.
Ending line: "Phir se promise, Mummy?" "Haan, phir se promise."
Moral: Pyaar ke saath rule set karna, bachcha safe mehsoos karta hai.
''',
    cover: 'Pyaar Bhi, Rule Bhi',
    opening: 'Rio ne phir se rule toda... par Mumma ne chillaaya nahi.',
    problem: 'Holding a boundary kindly instead of giving in or shouting',
    lesson: 'Pyaar ke saath rule, bachcha safe mehsoos karta hai',
  ),
  HookIdea(
    id: 'h21',
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria notices Mumma tired, picks up bag from floor and hands it.
Twist: Mumma starts to refuse — "Maine kaha tha, main saambhaa lunga."
Resolution: Ria: "Tum itni thak gayi ho!" Mumma lets her help, ruffles her hair.
Ending line: "Mumma: Shukriya beta. Ria: Tumhara saath hi toh maza aata hai."
Moral: Children see tiredness before we admit it — and small hands can still hold a big bag.
''',
    cover: 'Bag On Floor!',
    opening: 'Mumma ke saath bag gir gaya, Ria ne turant pick up kiya.',
    problem: 'Ria sees Mumma tired and picks up the bag from the floor',
    lesson: 'A child noticing and helping without being asked',
  ),

  // Milestone posts: complete concepts for the 100th Instagram post.
  HookIdea(
    id: 'p05',
    category: 'Page & milestone',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: New here? 1-4 saal ke bachchon ke liye screen-free play ideas, tiny stories aur everyday parenting moments.
Twist: Ria wants the box, Rio wants the lid, Cuty wants the packing peanuts. Mumma: "Sabko ek minute."
Resolution: They discover the box becomes a car, a house, a cave — and three imaginations fill it.
Moral: The best toy costs nothing and takes up no space.
''',
    cover: 'New Here?',
    opening: '1-4 saal ke bachchon ke liye screen-free ideas.',
    problem: 'New visitors need a 30-second hook that explains the whole page',
    lesson: 'Box = car = house — one toy, infinite play',
    postFormat: 'Reel / Pinned intro',
    strategy: 'Milestone + brand introduction + character introduction + discovery. Use a 25-35 second reel with Ria, Rio and Cuty, then test two hooks as Trial Reels: 100 POSTS ❤️ and Meet Our Little World 👀.',
    caption: '100 posts. ❤️\n\nWhat started as little ideas slowly became our little world — Ria, Rio, Cuty and so many tiny stories, laughs and lessons. 🌸💙🐰\n\nThank you for being here.\n\nLittle Stories. Big Lessons. 🌱\n\nAre you Team Ria, Team Rio or Team Cuty? 👇',
    pinnedComment: 'Okay, important question 😂👇\n🌸 Ria = Tofani\n💙 Rio = Ziddi\n🐰 Cuty = Sleep Lover\nWhich one is most like your little one?',
  ),
  HookIdea(
    id: 'p06',
    archived: true,
    category: 'Page & milestone',
    forApp: false,
    cover: 'Merged p08',
    opening: 'Merged into p08',
    problem: 'Consolidated into p08',
    lesson: 'See p08',
    strategy: 'Open with 100 posts ago, introduce Ria, then Rio, then Cuty, and end with 100 POSTS ❤️ and We are just getting started.',
    caption: '100 posts ago, there was only one little idea. Today, Ria, Rio and Cuty have their own little world. ❤️\n\nThank you for growing with us. Little Stories. Big Lessons. 🌱',
    pinnedComment: 'Which character did you meet first — Ria, Rio or Cuty? ❤️',
  ),
  HookIdea(
    id: 'p07',
    category: 'Page & milestone',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: "Aapke ghar kaun hai?" Ria is the negotiator — "Ek aur slide, phir packup!"
Twist: Rio is the "NO!" expert — "Bahar nahi jaana!" Floor meltdown. Cuty just observes, chewing a crumb.
Resolution: Mumma gives Ria a countdown, offers Rio a goodbye sticker, and lets Cuty finish his crumb. "Tum sab ke saath."
Moral: Three kids, three reactions — one family solution fits all.
''',
    cover: 'Aapke Ghar Kaun Hai?',
    opening: 'Ria negotiates, Rio says NO, Cuty quietly eats everything.',
    problem: 'Non-followers need a quick intro to the three characters and their distinct reactions',
    lesson: 'Meet the negotiator, the no-expert, the silent observer',
    postFormat: 'Reel / Discovery',
    strategy: 'Use the funniest version for discovery. Ria claims credit, Rio argues, Cuty keeps sleeping, and the final card reveals POST #100 🎉.',
    caption: 'Who made it to Post #100? 😂\n\nRia says it was her. Rio says NO. Cuty is sleeping through the celebration.\n\nStill causing trouble, one little story at a time. ❤️',
    pinnedComment: 'Who is most like your little one: Tofani Ria, Ziddi Rio or sleepy Cuty? 😂',
  ),
  HookIdea(
    id: 'p08',
    category: 'Page & milestone',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: "Toddler ke saath roz naya drama?" That's the page promise in one line.
Twist: Ria tries the "no" button, Rio tests boundaries, Cuty naps through it all — and Mumma stays calm.
Resolution: Problem + playful solution. Screen-free play, short stories, everyday learning for ages 1-4.
Moral: Tiny moments, big lessons — and every day brings a new reel.
''',
    cover: 'Naya Drama Har Din!',
    opening: 'Screen-free play, short stories, everyday learning for ages 1-4.',
    problem: 'New followers need a clear pinned introduction to the page promise',
    lesson: 'Problem + playful solution = every reel',
    postFormat: 'Reel / Pinned brand introduction',
    strategy: 'Pin this after Post 100. Introduce each character in one quick beat, then show learning, masti, family and everyday childhood.',
    caption: 'Welcome to our little world. 🌸💙🐰\n\nRia is Tofani, Rio is Ziddi, and Cuty is our sleep lover. Together they bring little stories, little lessons and lots of masti.\n\nFun Learning With Palak ❤️',
    pinnedComment: 'Which one are you: Team Ria, Team Rio or Team Cuty? 👇',
  ),

  // Page posts: need your own footage, so the app lists them but cannot build them.
  HookIdea(
    id: 'p01',
    category: 'Page & milestone',
    forApp: false,
    archived: true,
    cover: '1,000 Ke Paas!',
    opening: 'Ruko... hum 1,000 dost hone wale hain?!',
    problem: 'Milestone reel as you approach 1,000 followers',
    lesson: 'Thank the parents who came first',
  ),
  HookIdea(
    id: 'p02',
    category: 'Page & milestone',
    forApp: false,
    archived: true,
    cover: '1,000 Dost!',
    opening: 'Aaj Ria, Rio aur Cuty ke 1,000 dost ho gaye.',
    problem: 'Thank-you reel on reaching 1,000',
    lesson: 'A place in your feed means a lot',
  ),
  HookIdea(
    id: 'p03',
    category: 'Page & milestone',
    forApp: false,
    cover: 'Ek Reel Kaise Banti Hai',
    opening: '30 second ki ek kahani ke peeche kitna kaam hai...',
    problem: 'Behind the scenes of making one story',
    lesson: 'Shows the care that goes into every story',
  ),
  HookIdea(
    id: 'p04',
    category: 'Page & milestone',
    forApp: false,
    cover: 'Jab Humne Shuru Kiya',
    opening: 'Pehli kahani post ki thi... pata nahi tha koi dekhega bhi.',
    problem: 'How the page started',
    lesson: 'Honest start builds trust',
  ),

  // Navratri: Problem → Jugaad → Result → Moral.
  HookIdea(
    id: 'navratri-garba-ghar',
    archived: true,
    category: 'Navratri',
    cover: 'Child Won\'t Leave Fun Place',
    opening: 'Shelved evergreen — child refuses to leave a fun place.',
    problem: 'Shelved seasonal content',
    lesson: 'Evergreen version: ball rolling toward gate, one final slide',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Navratri mein bachche ko Garba se ghar kaise laayein? Thodi si planning, aur outing mein kam tension! #NavratriWithKids #ParentingHack #FunLearningWithPalak',
    pinnedComment: 'Tip: Garba se pehle 5 minute "one more song" sunao — phir packup signal dikhao',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is dancing happily at Garba, but when Mumma says it's time to leave, she protests—"Nahi, aur ghoomna hai!"
Twist: Ria spots other parents also packing up their kids—"Dekho, sab bachche yahan se jaa rahe hain!"
Resolution: Mumma gives Ria a "Garba star" sticker and lets her put her tiny bangles in her pocket to keep for home—"Kal phir milenge!"
Moral: One more song, then it's time to go—good-byes feel easier with a small promise.
''',
  ),
  HookIdea(
    id: 'navratri-bachcha-roye',
    archived: true,
    category: 'Navratri',
    cover: 'Shelved Sensory Overload',
    opening: 'Shelved evergreen — crowd makes child uncomfortable.',
    problem: 'Shelved seasonal content',
    lesson: 'Evergreen version: move to quieter spot',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Garba night par bachcha enjoy karne ki jagah rone lage toh? Quiet corner aur safe space sabse pehle! #NavratriTips #ToddlerLife #FunLearningWithPalak',
    pinnedComment: 'Tip: Venue par pehle se quiet family corner dhoondh ke rakhein!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria and Rio are excited for Garba, but the loud dhol and flashing lights make Cuty cover her ears and cry.
Twist: Mumma moves the kids to the quiet corner where Daadi is sitting—"Yahan se bhi Garba dikhai dega!"
Resolution: Daadi teaches Cuty to clap along to a softer beat, and soon Cuty is smiling and joining in her own way.
Moral: Every child celebrates differently—finding their comfort rhythm is its own kind of joy.
''',
  ),
  HookIdea(
    id: 'navratri-junk-food',
    archived: true,
    category: 'Navratri',
    cover: 'Shelved Junk Food Boundary',
    opening: 'Shelved evergreen — chips before dinner.',
    problem: 'Shelved seasonal content',
    lesson: 'Evergreen version: clear snack boundary, no shaming',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Garba jaate waqt bachche ke food tantrums ka kya karein? Lunch box mein favorite snack bhi saath le jao! #NavratriFood #ToddlerTips #FunLearningWithPalak',
    pinnedComment: 'Tip: Small snack pouch—5 bites before Garba, 5 after. Tantrum-free!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is ready for Garba but keeps asking for chips and sweets, saying "Mummy, bhookh lagi hai!"
Twist: Mumma offers the healthy snack box she packed—"Pehle yeh khao, phir Garba!"—but Ria still wants the chips.
Resolution: Mumma lets Ria choose one small sweet after the first round of Garba—balancing treat and fun.
Moral: Hunger at parties is often excitement—redirect with healthy fuel, then a small treat.
''',
  ),
  HookIdea(
    id: 'navratri-late-night',
    archived: true,
    category: 'Navratri',
    cover: 'Shelved Late Night',
    opening: 'Shelved — trivial resolution only.',
    problem: 'Shelved seasonal content',
    lesson: 'Revive only with real overtired child conflict',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Late-night Garba vs bachche ki sleep! 9 baje tak enjoy karo, phir cozy bedtime. #LateNightParenting #Navratri #FunLearningWithPalak',
    pinnedComment: 'Tip: Toddler ka comfort item (chhoti blanket ya soft toy) zaroor saath rakhein.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: It's 10 PM and Ria is enjoying Garba, but suddenly she yawns and says, "Mummy, main thak gayi hoon."
Twist: Mumma checks the clock—only one more song left, but Ria is already sleepy and cranky.
Resolution: Mumma whispers, "Ek last dance, then straight to bed"—Ria dances one more time, then happily goes home.
Moral: Late nights are okay sometimes, but knowing the end is near helps kids say goodbye.
''',
  ),
  HookIdea(
    id: 'navratri-uncomfortable-outfit',
    category: 'Navratri',
    cover: 'Outfit Pehante Hi Rona Shuru?',
    opening: 'Outfit toh cute hai... par bachcha sirf "nikal do, nikal do" bol raha hai!',
    problem: 'Fancy clothes, tight waistbands, or heavy accessories irritate a toddler',
    lesson: 'Cute outfit se pehle comfortable outfit!',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Navratri outfit pehna diya, ab bachcha chidchid kar raha hai? Comfort pe focus karo—style apne aap aayega. #NavratriFashion #ToddlerLife #FunLearningWithPalak',
    pinnedComment: 'Tip: Heavy accessories pehnane se pehle 5-minute comfort test zaroor karein!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria's new lehenga is itchy — "Nikal do, nikal do!" She refuses to wear it at all.
Twist: Mumma offers two options: "Option one, lehenga without the heavy dupatta. Option two, comfortable chaniya."
Resolution: Ria picks Option 2 — comfy chaniya and light jhumkas. She twirls and grins. "Maa, main khoobsurat lag rahi hoon!"
Moral: Comfort before style — when kids feel good, they shine.
''',
  ),
  HookIdea(
    id: 'navratri-no-partner',
    archived: true,
    category: 'Navratri',
    cover: 'Archived',
    opening: 'Archived — generic content.',
    problem: 'Archived: no real child problem',
    lesson: 'No real child problem',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Chhote bachchon ko Garba mein kaise include karein? Simple steps aur extra smiles—perfection se zyada khushi zaroori hai. #InclusiveGarba #KidsDance #FunLearningWithPalak',
    pinnedComment: 'Tip: Toddler ke saath simple 2-step taali banayein—kids energy copy karte hain!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria sees older kids dancing and wants to join, but she can't follow the complex steps—"Mummy, main nahi kar paa rahi!"
Twist: Papa joins her with a simple 2-step twist—"Ria-style dance, papa-style dance!"—and soon Rio and Cuty copy them.
Resolution: Ria's simple steps become the hit of the circle—everyone wants to learn the "toddler twist."
Moral: You don't need to follow—it's better to create your own way to celebrate.
''',
  ),
  HookIdea(
    id: 'navratri-late-ready',
    category: 'Navratri',
    cover: 'Late For Garba, Toddler Not Ready!',
    opening: 'Garba ke liye sab taiyyar the... par bachcha joote pehan hi nahi raha tha!',
    problem: 'Parents are ready but the toddler refuses to get dressed or put on shoes',
    lesson: 'Ready hone ka pressure kam, routine simple rakho',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Garba party ke liye late ho rahe hain aur bachcha ready hi nahi? Game banao, pressure nahi! #LastMinuteGarba #ToddlerRoutine #FunLearningWithPalak',
    pinnedComment: 'Tip: Shoes pehne ke baad "Garba star" sticker challenge try karke dekhiye!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Garba is starting in 5 minutes, but Ria is still struggling with her jootneys—"Jootey pehne mein dikkat ho rahi hai!"
Twist: Papa turns it into a game—"Jootey pehne, superhero ban jao!"—Ria giggles and slips them on.
Resolution: Ria runs to join the Garba circle just in time, her "superhero jootneys" clicking as she dances.
Moral: Rushing creates resistance—transform the race into play and everything falls into place.
''',
  ),
  HookIdea(
    id: 'navratri-bumped-crowd',
    archived: true,
    category: 'Navratri',
    cover: 'Shelved Crowd Bump',
    opening: 'Shelved evergreen — stay close to trusted adult in crowd.',
    problem: 'Shelved seasonal content',
    lesson: 'Evergreen version: stay close to trusted adult',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Crowded Garba mein toddler ko safe kaise rakhein? Family boundary banayein aur sides mein enjoy karein. #SafeGarba #CrowdedEvents #FunLearningWithPalak',
    pinnedComment: 'Tip: Event entry par hi family corner aur quiet spot pehle dekh lein.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: The Garba floor is packed and Ria gets accidentally bumped—she looks scared and clings to Mumma.
Twist: Mumma lifts Ria onto her shoulders so she can see over the crowd—"Ab dekho, yeh sab kuch badiya lag raha hai!"
Resolution: From above, Ria sees the beautiful lights and starts waving at other dancers—her fear turns to wonder.
Moral: A new perspective can turn overwhelm into magic—sometimes elevation helps us see the beauty.
''',
  ),
  HookIdea(
    id: 'navratri-phone-at-event',
    archived: true,
    category: 'Navratri',
    cover: 'Merged h02',
    opening: 'Merged into h02 — screen time transition.',
    problem: 'Merged: duplicate of h02',
    lesson: 'Consolidated into h02',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Garba mein phone ke bina toddler ko busy kaise rakhein? Chhota activity pouch—crayons, stickers aur finger puppets! #ScreenFreeKids #NavratriTips #FunLearningWithPalak',
    pinnedComment: 'Tip: Activity bag mein sirf 3-4 favorite items rakhein—focus bana rehta hai.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Garba has started but Ria keeps asking for her phone—"Mummy, phone dikhao, videos banana hai!"
Twist: Mumma gives Ria a small bag with crayons and stickers—"Garba mein draw kar lo kya dekh rahe ho!"
Resolution: Ria is busy drawing her Garba scene and forgets about the phone—she shows Mumma her artwork happily.
Moral: Engagement beats screen time—small offline activities keep little hands busy during big moments.
''',
  ),
  HookIdea(
    id: 'navratri-attention-prep',
    category: 'Navratri',
    cover: 'Festival Prep Mein Bachche Ko Kaise Sambhalein?',
    opening: 'Mumma decoration mein busy thi... aur bachcha bola "mere saath khelo na!"',
    problem: 'Parents are busy with preparations and the toddler seeks constant attention',
    lesson: 'Har baar alag playtime zaroori nahi—bachche ko apne saath chhotey kaamo mein shaamil karo',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Navratri preparations mein bachche ko time nahi mil raha? Unhe helping hands banaiye! #MomLife #NavratriPrep #FunLearningWithPalak',
    pinnedComment: 'Tip: Decor items arrange karne ya phool ginne ka task dijiye—bachcha khush!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma is setting the Diwali table, but Ria keeps grabbing things. "Mere saath khelo!"
Twist: Mumma hands Ria a stack of napkins: "Tum bhi Maa ki helper ho, napkins ghoomao."
Resolution: Ria carefully places each napkin beside a plate. "Mainne madad ki!" "Perfect," Mumma says.
Moral: Invitations beat interruptions — when kids feel helpful, they don't compete for attention.
''',
  ),
  // ── New 30s Reel Stories ─────────────────────────────────────────────────────
  /// Built-in offline story seeds. Each carries a full `storyDetail` with three
  /// 10-second parts so the offline generator can break it into a video prompt
  /// without any network call.
  HookIdea(
    id: 'plate-patana',
    category: 'Relatable',
    cover: 'Plate Patana',
    opening: 'Ria plate mein khana rakhti thi — phir "Mumma, sab mix ho gaya!"',
    problem: 'Plate mein dal, rice, aur vegetable sab mix ho gaya.',
    lesson: 'Ek chhota sa separation — dal ka swimming pool.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria plate mein khana rakhti thi — phir "Mumma, sab mix ho gaya!" Dal, chawal, aur vegetable sab ek saath ghubhrey.
Twist: Mumma ek chhota sa bowl le aati hain: "Ek minute, maaro ek alag." Rio bhi dekh rahe hain.
Resolution: Dal ka swimming pool alag, chawal phir se — "Bachcha ne engineering shuru kar di!"
Moral: Ek minute separation, poora mood badal jaata hai.
''',
  ),
  HookIdea(
    id: 'shoe-bandhani',
    archived: true,
    category: 'Relatable',
    cover: 'Merged h01',
    opening: 'Merged into h01',
    problem: 'Duplicate shoe story',
    lesson: 'Consolidated into h01',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h01 — shoe independence)
''',
  ),
  HookIdea(
    id: 'toy-sharing',
    category: 'Relatable',
    cover: 'Toy Sharing',
    opening: 'Ria aur Rio dono ek hi toy car ko pakad kar khushboo mein latke the.',
    problem: 'Ria aur Rio dono ek hi toy car ko pakad kar khushboo mein latke the.',
    lesson: 'Share karne se toy gam nahi hota, saath khelne se toh mazaa hi kuchh aur hota hai.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Ria and Rio both grab the same red-yellow toy car and tug in opposite directions on the living room rug. The car wobbles between them.
Twist: When Mummy hands it to one, the other grabs it too — and the car goes flying across the room.
Resolution: Cuty pushes the car down the middle between them — "Ek do pal ke liye, dono ke liye!"
Moral: Share karne se toy gam nahi hota, saath khelne se toh mazaa hi kuchh aur hota hai.
''',
  ),
  HookIdea(
    id: 'vegetable-drama',
    archived: true,
    category: 'Relatable',
    cover: 'Merged h08',
    opening: 'Merged into h08',
    problem: 'Duplicate vegetable refusal story',
    lesson: 'Consolidated into h08',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h08 — vegetable/broccoli bite story)
''',
  ),
  HookIdea(
    id: 'brushing-battle',
    archived: true,
    category: 'Relatable',
    cover: 'Merged h07',
    opening: 'Merged into h07',
    problem: 'Duplicate brushing story',
    lesson: 'Consolidated into h07',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h07 — brushing teeth with Cuty)
''',
  ),
  HookIdea(
    id: 'park-se-nikalna',
    category: 'Relatable',
    cover: 'Park Se Nikalna',
    opening: 'Ria ne kaha — "Main yahan nahi jaungi park se!" jab papa ne time khatam kaha.',
    problem: 'Ria ne kaha — "Main yahan nahi jaungi park se!" jab papa ne time khatam kaha.',
    lesson: 'Game toh game hota hai, lekin har game ek nayi baat sunane dega.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Park time is over. Papa checks his watch — "Time to go." Ria plants her feet — "Main yahan nahi jaungi park se!"
Twist: Rio joins the protest — "Mujhe bhi nahi jaana!" — both sit on the ground.
Resolution: Papa turns it into a game — "Jiska pehla step niklega, wohi jeeti ka countdown karega."
Moral: Game toh game hota hai, lekin har game ek nayi baat sunane dega.
''',
  ),
  HookIdea(
    id: 'the-toy-car-share',
    category: 'Relatable',
    cover: 'The Toy Car Share',
    opening: 'Ria and Rio both grabbed the same red-yellow toy car and tugged in opposite directions.',
    problem: 'Ria and Rio both grabbed the same red-yellow toy car and tugged in opposite directions on the living room rug.',
    lesson: 'Sharing something means twice the fun, not twice the fight.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Ria and Rio both grab the same red-yellow toy car and tug in opposite directions on the living room rug. The car wobbles between them.
Twist: When Mummy hands it to one, the other grabs it too — and the car goes flying toward the kitchen doorway.
Resolution: They take a breath, look at each other, and agree to roll the car right down the middle together.
Moral: Sharing something means twice the fun, not twice the fight.
''',
  ),
  HookIdea(
    id: 'the-block-tower',
    category: 'Relatable',
    cover: 'The Block Tower',
    opening: 'Rio carefully balanced the final wooden block on a tall colorful tower.',
    problem: 'Rio carefully balanced the final wooden block on a tall colorful tower while afternoon sun streamed through the window.',
    lesson: 'A mistake is just a new game waiting to be named.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Rio balances the final wooden block on a tall tower, proud of his creation.
Twist: Ria toddles over for a better look and accidentally bumps the base with her shoe.
Resolution: Blocks scatter, but Rio giggles — "Now we can build a flat playhouse!"
Moral: A mistake is just a new game waiting to be named.
''',
  ),
  HookIdea(
    id: 'the-snack-reach',
    category: 'Relatable',
    cover: 'The Snack Reach',
    opening: 'Ria: "Mumma, bas ek aur chips!"',
    problem: 'Ria wants one more snack — a spoken hook about wanting "just one more."',
    lesson: 'Boundary offered, no pressure.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria: "Mumma, bas ek aur chips!" She stretches toward the snack jar.
Twist: Mumma: "Ek aur nahi, lekin kal subah ek extra milegi." Ria negotiates — "Ek poori teekha!"
Resolution: Mumma offers: "Ek chips, phir brush." Ria grins: "Deal!" She eats it slowly, savoring.
Moral: One chip with a condition feels like a win, not a battle.
''',
  ),
  HookIdea(
    id: 'night-before-annual-day',
    category: 'Relatable',
    cover: 'Night Before Annual Day',
    opening: 'At 9:30 PM, Ria dropped the bombshell — tomorrow was Annual Day!',
    problem: 'At 9:30 PM, Ria casually dropped the bombshell — tomorrow was Annual Day and she needed a yellow costume and cardboard sunflower prop.',
    lesson: 'Even the messiest all-nighter ends when everyone works as a team.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: At 9:30 PM, Ria drops the bombshell — Annual Day is tomorrow and she needs a costume.
Twist: While Papa frantically glues cardboard petals at midnight, Mummy forgets all the dance steps during rehearsal.
Resolution: By morning, the costume is perfect and the prop stands tall — and the kids take all the credit on stage.
Moral: Even the messiest all-nighter ends when everyone works as a team.
''',
  ),
  HookIdea(
    id: 'asmr-cleaning-reel',
    category: 'Relatable',
    cover: 'ASMR Cleaning Reel',
    opening: 'Mummy found the living room in complete chaotic toddler disarray.',
    problem: 'Mummy found the living room in complete chaotic toddler disarray — crayons, blocks, cushions, and snack bowls scattered everywhere.',
    lesson: 'Ten minutes of peace and a lifetime of love — perfectly balanced.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Mummy finds the living room in complete chaotic toddler disarray. She rolls up her sleeves and begins the satisfying deep clean.
Twist: As she cleans, the soundscape fills with crisp latch clicks and block clatter — pure ASMR.
Resolution: She sits back on the pristine sofa with her chai in pure bliss — then opens the bedroom door to a new storm.
Moral: Ten minutes of peace and a lifetime of love — perfectly balanced.
''',
  ),
  // ── New 30s Reel Stories ─────────────────────────────────────────────────────
  HookIdea(
    id: 'dangerous-silence',
    category: 'Relatable',
    cover: 'Ghar mein 2 minute ki shanti... DANGER!',
    opening: 'Mummy heard two minutes of dead silence from the toddlers.',
    problem: 'When toddlers are suddenly quiet for two minutes, disaster is unfolding.',
    lesson: 'Check on quiet toddlers - creative chaos always follows.',
    postFormat: 'Reel',
    strategy: 'Suspense hook, then reveal',
    caption: 'Ghar mein 2 minute ki shanti... DANGER! 😱 Jab bachche bilkul silent ho jaate hain, toh bura haal hota hai. Watched the full video to see what Cuty was up to! #toddlermeltdown #indianparents #funlearningwithpalak #PreschoolMeltdown #ToddlerHumor',
    pinnedComment: 'Tip: The silence is always louder than the chaos that came before. Check on them! 🐰',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Two minutes of dead silence from the toddlers. Mummy tiptoes toward the kitchen — suspiciously quiet.
Twist: Flour footprints lead across the floor: tiny bare feet, Cuty's paw prints, and a trail of white dust.
Resolution: Round the corner — Ria and Rio, flour-covered, sitting in a cloud of spilled wheat, building a "snowman."
Moral: The most suspicious silences always end with creative chaos to clean up.
''',
  ),
  HookIdea(
    id: 'missing-shoe-mystery',
    category: 'Relatable',
    cover: 'Ek Joota Gayab — 7:55 AM Panic!',
    opening: 'School van honking downstairs, but one shoe has vanished.',
    problem: 'At 7:55 AM school rush, one shoe disappears into another dimension.',
    lesson: 'The things we lose are just having their own adventure.',
    postFormat: 'Reel',
    strategy: 'Morning rush comedy, relatable chaos',
    caption: 'School van neeche aa gayi... aur ek joota gayab! 🚐 Joota kho gaya, par kahaan gaya? Full video dekho. #morningrush #toddlerlife #funlearningwithpalak #indianparents #MomLife',
    pinnedComment: 'Tip: Always check the balcony curtains — shoes love to hide there! 👟',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: School van at 7:55 AM, but one shoe has vanished into another dimension.
Twist: Visual clues only: tiny footprint in flour (Rio), a trail of blocks (Cuty), and a doll stroller with one shoe tucked inside.
Resolution: With seconds to spare, they pull the shoe from the stroller. "Doll ne bhi date ki hai!" Rio grins.
Moral: Lost things usually have simple explanations — check the stroller.
''',
  ),
  HookIdea(
    id: 'broken-biscuit-meltdown',
    category: 'Relatable',
    cover: 'Biscuit Toota — Duniya Khatam!',
    opening: 'Mummy snaps a cookie in half to share, Ria acts like the world ended.',
    problem: 'A snapped cookie causes dramatic toddler despair.',
    lesson: 'A shared laugh turns every broken thing into something sweet.',
    postFormat: 'Reel',
    strategy: 'Exaggerated emotion, then sweet payoff',
    caption: 'Biscuit toota matlab duniya khatam! 🍪😭 Doctor Rio ne banaya jugaad repair, par Cuty ne bhi ek nibble liya! #toddlerlogic #biscuitcrisis #funlearningwithpalak #ToddlerHumor #BiscuitDrama',
    pinnedComment: 'When your toddler snaps a cookie and treats it like breaking the Mona Lisa! 😂',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mummy snapped a big round cookie in half to share, and Ria acted dramatic shock as if the world itself had shattered.
Twist: Rio became "Doctor Rio," dipping his finger in warm milk to glue the broken halves back together, but Cuty took a nibble right on the seam.
Resolution: Instead of tears, both kids burst into uncontrollable belly laughs — the broken biscuit became the funniest thing ever.
Moral: A shared laugh turns every broken thing into something sweet.
''',
  ),

  // ── Ria Talking to AI Robot Series ─────────────────────────────────────────────
  // 20 scripted reel ideas following a consistent character-driven comedy format.
  // Each uses Story:/Twist:/Resolution:/Moral: labels inside storyDetail so
  // the offline StoryGenerator can parse and break it into video parts.

  HookIdea(
    id: 'robot-01',
    category: 'Series',
    cover: 'Phone Rakh Do!',
    opening: 'Robot, phone rakh do — par haath mein hi hai!',
    problem: 'Ria asks Robot to put her phone away, but she is still holding it.',
    lesson: 'Robot scans literally and finds the phone in Ria own hand.',
    postFormat: 'Reel',
    strategy: 'AI comedy misunderstanding, family situation, physical comedy payoff',
    caption: 'Jab Mumma ka phone haath mein hai lekin woh kho dhundh rahi hai... aur Robot ne phone wapas dedi! 😂 Har mummy ko yehi dekhna chahiye. #RiaAndRobot #IndianMomLife #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'We all need a personal robot who tells us the truth — and hands back our phone from our own hand! 🤖',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria: "Robot, phone rakh do!" But her hand is still gripping it.
Twist: Robot: "Object is resting. Hand is still attached." Robot scans behind couch, under pillows, in Cuty's mouth.
Resolution: Robot points at Ria's own hand: "Object located." Ria laughs: "Meri hi toh thi!"
Moral: Sometimes the thing we want help finding is already in our hand.
''',
  ),
  HookIdea(
    id: 'robot-02',
    category: 'Series',
    cover: 'Sabzi Rejection Form',
    opening: 'Mujhe yeh sabzi bilkul nahi chahiye!',
    problem: 'Ria rejects food without trying, wants a formal rejection form from Robot.',
    lesson: 'Robot prints a Sabzi Rejection Form with checkboxes.',
    postFormat: 'Reel',
    strategy: 'Food refusal humor, gentle parenting lesson',
    caption: 'Palak se pehle ek bite, aur suddenly "Mumma, aur thoda dena!" 😂 Har meal time fight ka asan hal. #RiaAndRobot #ToddlerMeals #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'The robot was right — one tiny bite can change everything! 👶',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria: "Mujhe yeh sabzi bilkul nahi chahiye!" She pushes the plate away.
Twist: Robot whirs: "Sabzi Rejection Form — Item Code: Green." Prints a form with checkboxes: too slimy / too green / too much.
Resolution: Ria checks "too green," and Robot replies: "Noted. Try cheese next time." She tries one bite with cheese. "Thik hai!"
Moral: Even rejections can be filed — and sometimes re-tried.
''',
  ),
  HookIdea(
    id: 'robot-03',
    category: 'Series',
    cover: 'Can You Fix My Broken Heart?',
    opening: 'Robot, Rio ne mera heart tod diya!',
    problem: 'Ria\'s sibling damages her favorite toy and doesn\'t apologise, leaving Ria upset.',
    lesson: 'The robot suggested a heart-shaped bandage and helped Ria talk to Rio about sharing and saying sorry.',
    postFormat: 'Reel',
    strategy: 'Emotional expression, sibling dynamics, heart-shaped bandage visual',
    caption: 'Jab bhaiya ne toy kharab kar diya, toh Robot ne diya heart bandage! ❤️ Sibling love, properly patched. #RiaAndRobot #SiblingLove #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'Every broken heart needs a robot and a heart-shaped bandage. ❤️🩹',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio accidentally breaks Ria's favorite toy, and Ria is devastated, declaring her heart is broken.
Twist: The robot takes "broken heart" literally and produces a large adhesive bandage shaped like a heart, applying it to Ria's chest.
Resolution: Seeing the silly bandage, both kids laugh, Rio apologises, and they repair the toy together with the robot's help.
Moral: A little humor and teamwork can mend both toys and feelings.
''',
  ),
  HookIdea(
    id: 'robot-04',
    category: 'Series',
    cover: 'Mera Sab Kharab!',
    opening: 'Mera sab kharab! Robot, ek block hi do.',
    problem: 'Everything feels ruined — Robot offers one block to restart.',
    lesson: 'One block starts a new tower.',
    postFormat: 'Reel',
    strategy: 'Chore avoidance comedy, collaborative cleanup dance',
    caption: 'Mess gayab karne ke liye ek robot nahi… ek dance playlist aur Ria milake hi chahiye! 💃🧹 #RiaAndRobot #CleanUpDance #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'The robot may start, but Ria finishing makes it a win! 10/10 teamwork.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: "Mera sab kharab!" Ria throws her arms up — everything is ruined.
Twist: Robot sits stiffly, holds out one block: "Problem identified. Solution: one block."
Resolution: Ria laughs: "Ek hi block?" Robot: "Ek block se shuru hota hai." They build a tiny tower together.
Moral: A single block can start a new tower — and a robot's deadpan can reset a mood.
''',
  ),
  HookIdea(
    id: 'robot-05',
    category: 'Series',
    cover: 'Ek Chhota Sa Saans',
    opening: 'Tower gir gaya... Rio ne inhale kar li.',
    problem: 'Tower falls and Rio is ready to shout — Robot teaches one tiny breath.',
    lesson: 'One breath before the shout saves the tower.',
    postFormat: 'Reel',
    strategy: 'Overstimulation handling, emotional regulation, breathing exercise',
    caption: 'Jab sabse zindagi mein bahut kuchh ho raha hai... toh ek robot breathing cards ke saath madad karta hai! 🧘‍♀️ #RiaAndRobot #EmotionalRegulation #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'Five minutes of quiet, a breathing card, and Ria was back to her playful self. 💙',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Tower falls. Rio inhales to shout — "NOOOOO!" — but the card he grabbed flies out of his hand.
Twist: "Ek chhota sa saans." Ria whispers. She holds one tiny breath with him — in for two, out for two.
Resolution: Rio tries again. The card lands softly in his palm. They rebuild the tower, one block at a time.
Moral: A breath before the shout can save the whole tower.
''',
  ),
  HookIdea(
    id: 'robot-06',
    archived: true,
    category: 'Series',
    cover: 'Retired',
    opening: 'Retired — adult-only idiom cut.',
    problem: 'Retired content',
    lesson: 'Replaced by better material',
    postFormat: 'Reel',
    strategy: 'Retired',
    caption: 'This content has been retired.',
    pinnedComment: 'Retired — see h05 for bedtime stories.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Retired — adult-only idiom cut)
''',
  ),
  HookIdea(
    id: 'robot-07',
    category: 'Series',
    cover: 'Rio Copy Kar Raha Hai!',
    opening: 'Robot, Rio har cheez copy karta hai!',
    problem: 'Rio copies everything Ria does, escalating to silly robot noises.',
    lesson: 'Robot turns copying into a joint silly pose game.',
    postFormat: 'Reel',
    strategy: 'Sibling mimicry, parallel play setup, individual attention',
    caption: 'Rio har baat copy karta hai, toh Robot ne banaya "me time" aur "Rio time" stations! ✨ #RiaAndRobot #SiblingDynamics #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'A me-station and a Rio-station — problem solved! Everyone gets their own space. 😍',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio copies EVERYTHING — Ria's sip, Ria's walk, Ria's "I'm a big cat!" He escalates to silly robot noises.
Twist: Ria's patience frays. Robot interrupts: "Copy complete. Initiating joint silly pose protocol."
Resolution: Robot strikes a pose — "Left hand broccoli, right hand ice cream." Both kids mirror. Laughter breaks the tension.
Moral: Copying can flip into collaboration when you turn it into a game.
''',
  ),
  HookIdea(
    id: 'robot-08',
    archived: true,
    category: 'Series',
    cover: 'Merged h01',
    opening: 'Merged into h01',
    problem: 'Duplicate shoe independence story',
    lesson: 'Consolidated into h01',
    postFormat: '',
    strategy: 'Retried',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h01 — shoe independence conflict)
''',
  ),
  HookIdea(
    id: 'robot-09',
    category: 'Series',
    cover: 'My Drawing Is Wrong!',
    opening: 'Robot, meri drawing kharab ho gayi!',
    problem: 'Ria compares her drawing to an example and feels she made a mistake.',
    lesson: 'The robot scanned Ria\'s drawing and created a magical animated version showing her unique style.',
    postFormat: 'Reel',
    strategy: 'Artistic confidence, drawing validation, animated gallery',
    caption: 'Jab "kharab" drawing Robot ke saamne magic ban gayi! ✨ Har art perfect hota hai. #RiaAndRobot #ArtConfidence #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'Your unique style is what makes your art special — the robot said so!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria shows her drawing to the robot, upset that it doesn\'t look like the example picture.
Twist: The robot scans the drawing and projects an animated version, highlighting how her unique style brings the picture to life in ways the example never could.
Resolution: Ria beams with pride — "Mere drawings alive hote hain!" — and wants to draw ten more.
Moral: There\'s no "wrong" way to create art — your style is your superpower.
''',
  ),
  HookIdea(
    id: 'robot-10',
    archived: true,
    category: 'Series',
    cover: 'Merged h03',
    opening: 'Merged into h03',
    problem: 'Duplicate tower/feelings story',
    lesson: 'Consolidated into h03',
    postFormat: '',
    strategy: 'Retired',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Merged into h03 — tower collapse emotion processing)
''',
  ),
  HookIdea(
    id: 'robot-11',
    archived: true,
    category: 'Series',
    cover: 'Retired',
    opening: 'Retired — abstract pocket dimension gag cut.',
    problem: 'Retired content',
    lesson: 'Replaced by better material',
    postFormat: '',
    strategy: 'Retired',
    caption: 'This content has been retired.',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Retired — abstract pocket dimension concept)
''',
  ),
  HookIdea(
    id: 'robot-12',
    category: 'Series',
    cover: 'Mumma Sun Leti Hai!',
    opening: 'Robot, Mumma ko peeche bhi dikhta hai kya?',
    problem: 'Ria is caught doing something she shouldn\'t, but it isn\'t magic — Mumma heard the clues',
    lesson: 'The robot shows how parents pick up sounds and signs, not superpowers.',
    postFormat: 'Reel',
    strategy: 'Parental awareness, hearing clues, playful acknowledgment',
    caption: 'Robot ne bataya: "Mumma ne suna — steps, crinkles, timer beep!" 🔄👂 #RiaAndRobot #ParentSuperpower #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'It\'s not magic — it\'s Mumma\'s ears! We hear EVERYTHING. 😉',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria tries to sneak a cookie, but Mumma calls out — "Ruk jao, meri aankh bhi nahi todi!"
Twist: Mumma explains: "Maine tumhare steps suna, aur wrapper ki awaaz li." The robot projects a "clue chart" — footsteps, crinkles, timer beep.
Resolution: Ria laughs instead of protests. "Toh main kabhi bhi nahi chupke se cookie le sakti?"
Moral: Pyaar se bina camera ki zaroorat nahi — sunna hi kaafi hota hai.
''',
  ),
  HookIdea(
    id: 'robot-13',
    category: 'Series',
    cover: 'Ek Haath Ka Space',
    opening: 'Robot, mujhe ek haath ka space chahiye!',
    problem: 'Rio crowds Ria while she builds, knocking puzzle pieces sideways.',
    lesson: 'Robot stretches a ruler to mark each child space.',
    postFormat: 'Reel',
    strategy: 'Personal boundaries, calm-down space, respectful communication',
    caption: 'Jab thoda space chahiye ho... toh Robot banata hai "calm-down tent"! 🏕️ #RiaAndRobot #Boundaries #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'Respecting "I need space" makes everyone calmer — kids and adults alike.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is building a puzzle. Rio looms too close, knocking pieces sideways. "Mujhe thoda space chahiye!"
Twist: Robot stretches a ruler across the table: "Ek haath ka space." Red line for Ria, blue line for Rio.
Resolution: "Line ke andar raho." They both stay in their zones, finish the puzzle together.
Moral: Space to create is peace to create.
''',
  ),
  HookIdea(
    id: 'robot-14',
    archived: true,
    category: 'Series',
    cover: 'Retired',
    opening: 'Retired — abstract spotlight concept cut.',
    problem: 'Retired content',
    lesson: 'Replaced by better material',
    postFormat: '',
    strategy: 'Retired',
    caption: 'This content has been retired.',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Retired — abstract spotlight / sharing spotlight concept)
''',
  ),
  HookIdea(
    id: 'robot-15',
    archived: true,
    category: 'Series',
    cover: 'Retired',
    opening: 'Retired — adult-brain puzzle humour cut.',
    problem: 'Retired content',
    lesson: 'Replaced by better material',
    postFormat: '',
    strategy: 'Retired',
    caption: 'This content has been retired.',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Retired — abstract adult-brain puzzle sorting concept)
''',
  ),
  HookIdea(
    id: 'robot-16',
    category: 'Series',
    cover: 'There Are Butterflies in My Tummy!',
    opening: 'Robot, mere pet mein titliyan udd rahi hain!',
    problem: 'Ria gets pre-performance jitters before showing her artwork or speaking in front of others.',
    lesson: 'The robot explained that "butterflies" are excitement and courage, not fear.',
    postFormat: 'Reel',
    strategy: 'Performance anxiety, excitement vs fear, courage visualization',
    caption: 'Jab "butterflies" ke matlab excitement hota hai, na ki darr... toh Robot ne samjhaana mushkil nahi! 🦋 #RiaAndRobot #Courage #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'Those butterflies? They\'re cheering you on, not warning you away. 💪',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria feels butterflies in her tummy before showing her drawing to the class and says the robot about them.
Twist: The robot scans her and displays "Excitement Detected: 97% — Butterflies = Courage, Not Fear."
Resolution: The robot teaches her a "butterfly breath" and Ria confidently shows her drawing to everyone.
Moral: Butterflies mean you care — and caring is the first step to courage.
''',
  ),
  HookIdea(
    id: 'robot-17',
    category: 'Series',
    cover: 'I\'m Dying of Boredom!',
    opening: 'Main bore ho rai hoon!',
    problem: 'Ria has finished all her activities and declares nothing is left to do.',
    lesson: 'The robot suggested the "boredom jar" — a list of simple activities she can pick from.',
    postFormat: 'Reel',
    strategy: 'Boredom productivity, creativity prompts, activity jar system',
    caption: 'Sirhara pa gaya, Robot ne banaya "boredom jar"! Har ghoont mein naya activity. 🎨 #RiaAndRobot #BoredomHack #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'A boredom jar is a happiness jar waiting to happen. Which activity will you pick? ❤️',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria has finished everything — drawing, puzzle, snack, dance — and declares, "Ab kuchh nahi bacha!"
Twist: The robot produces a "Boredom Jar" filled with tiny scrolls, each with a creative activity she hasn't tried yet.
Resolution: Ria draws a scroll — "Build a blanket fort!" — and spends the afternoon on an epic adventure.
Moral: Boredom is just the moment before creativity kicks in.
''',
  ),
  HookIdea(
    id: 'robot-18',
    archived: true,
    category: 'Series',
    cover: 'Retired',
    opening: 'Retired — abstract cloud visualization cut.',
    problem: 'Retired content',
    lesson: 'Replaced by better material',
    postFormat: '',
    strategy: 'Retired',
    caption: 'This content has been retired.',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: (Retired — abstract cloud nine visualization concept)
''',
  ),
  HookIdea(
    id: 'robot-19',
    category: 'Series',
    cover: 'Rio Ne Surprise Diya!',
    opening: 'Robot, Rio ne ek surprise plan kiya hai!',
    problem: 'Rio tells everyone about a surprise Ria planned for Mumma, but Ria wanted it to stay secret until the big reveal.',
    lesson: 'The robot explains that surprises are meant to share, but secrets that make you uncomfortable must always be told to a trusted grown-up.',
    postFormat: 'Reel',
    strategy: 'Privacy boundaries, secret vs surprise, sibling communication',
    caption: 'Jab Rio ne surprise sabko bata diya... toh Robot ne banaya Surprise vs Secret chart! 🎁 #RiaAndRobot #KidSafety #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'Surprises are fun to share later. Secrets that feel icky? Tell a grown-up right away!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria tells the robot about a surprise she is planning for Mumma. Rio overhears and blurts it out to everyone — "Ria ne Mumma ko surprise gift banaya hai!"
Twist: The robot draws a picture chart in two columns. One side: "Surprise = fun to share later!" Other side: "Secret = if it makes you sad or scared, tell Mumma or Papa right away."
Resolution: Rio understands: surprises are exciting when shared at the right time, and any feeling that feels icky must be told to a trusted grown-up immediately.
Moral: Surprises are sweet to share; secrets that make you uncomfortable must be told to a grown-up right away.
''',
  ),
  HookIdea(
    id: 'robot-20',
    category: 'Series',
    cover: 'I Want to Eat the Whole World!',
    opening: 'Robot, mujhe poori duniya khana hai!',
    problem: 'Ria is curious about every food she sees and wants to try everything at once.',
    lesson: 'The robot created a "world foods adventure map" so Ria could explore tastes one country at a time.',
    postFormat: 'Reel',
    strategy: 'Food curiosity, cultural exploration, adventure map',
    caption: 'Poori duniya khana hai? Robot ne banaya "world foods adventure map!" Har din ek naya desh. 🌍 #RiaAndRobot #WorldFoods #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'One country, one flavor at a time — the robot\'s recipe for culinary courage!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria sees a table full of international foods and declares, "Mujhe poori duniya khana hai!" — she wants to eat everything.
Twist: The robot produces a world map where each country lights up as Ria tastes its cuisine — one bite at a time.
Resolution: Ria marks countries on her adventure map, trying one dish per day and learning about each culture.
    Moral: The world is huge — best to explore it one bite at a time.
''',
  ),
  ...kSafetyHooks,
];

/// Rewritten storyDetail values that replace the originals at runtime.
/// Each value uses the Story:/Twist:/Resolution:/Moral: label format
/// the offline generator expects. Built-in ideas are preferred over
/// the inline storyDetail on the HookIdea so updates can improve the
/// stories without modifying the const list above.
const kRewrittenStories = <String, String>{
  'h01': '''
Story: Bus ka samay ho raha hai; Mumma jhukkar Ria ke joote pehnane lagti hai. Ria haath jhatak deti hai: "Main khud!" Joota ulte pairon lag jaata hai, Ria pengun ban kar chalti hai.
Twist: Mumma apni taraf se koi madad nahi karti. Woh do second ke liye haath jodti hai, phir kehti: "Ek, do, teen, char, paanch."
Resolution: Ria joota theek karti hai, sahi se bandh jaata hai. "Dekho!" Bus ka horn bajta hai, lekin Ria ab pakkar mehsoos karti hai.
Moral: A little patience and a count to five gives Ria a win she earned herself.
''',
  'h02': '''
Story: Cartoon band hone ka waqt. Mumma: "Phone band." Ria: "Bas paanch minute!" Ria royi, lekin asli dikat yeh nahi ki phone band ho raha tha — episode beech mein toot gaya tha.
Twist: Agle din Mumma pehle puchhti: "Ye episode kab khatam hoga?" Ek visual timer lagati hai.
Resolution: Episode khatam hota hai, Ria khud kehti hai "Khatam!" aur phone Mumma ko deti hai. "Kal timer pehle lagayege."
Moral: Beech mein nahi, khatam hone par — par pehle se batana bhi badi baat hai.
''',
  'h03': '''
Story: Rio ka tower teesri baar girta hai. Woh blocks se haath kash karke bolta hai: "Mujhe nahi aata!"
Twist: Ria turant madad karne aati hai, lekin Rio uska haath hata deta hai: "Main karunga!" Ria samajh jaati hai ki madad karne ka matlab haath chhune se nahi, sochne se hai.
Resolution: Ria chupchaap do bade blocks Rio ke paas rakhti hai: "Neece rakho, base bana ke dekho." Rio tower khada kar deta hai. "Dekho, khada hai!"
Moral: Hint do, haath mat lagao — bachcha khud hi seekh jaata hai.
''',
  'h04': '''
Story: Ria shouts, "Cuty kahan gaya?!" The floor is a toy jungle. Every time Rio searches, he starts playing.
Twist: Ria makes a "Cuty rescue basket" — they clear just one path, then spot Cuty asleep under a blanket.
Resolution: Rio whispers, "Hum poora room saaf karne aaye the?" Ria: "Shhh, patient so raha hai."
Moral: Ek chhota sa raasta bhi bada madad karta hai.
''',
  'h05': '''
Story: Lights off. Ria calls out: "Mumma, ek aur paani!" Mumma brings it. Then Ria remembers: "Teddy ko blanket chahiye." Then: "Aur ek hug?" Planned hug. Ria snuggles in.
Twist: Mumma pre-places a small cup and a hug-stuffed animal on the bedside table the next night.
Resolution: When lights go off, Ria reaches for both. "Ab bas... unless Teddy ko paani chahiye."
Moral: Jo roz maanga jaata hai, pehle se rakh do — ek chhota routine, ek calmer bedtime.
''',
  'h07': '''
Story: Ria refuses: "Brush nahi!" Mumma picks up Cuty's brush: "Pehle Cuty ki teeth clean karte hain."
Twist: Tiny circles on Cuty's toy teeth. Ria watches, then grabs a brush. "Cuty ke teeth clean, ab mere!"
Resolution: Mumma helps guide Ria's hand through the last stubborn spot. Ria spits, grins at her sparkly smile.
Moral: Watching a friend get first makes the real thing feel less scary.
''',
  'h08': '''
Story: Papa holds up broccoli: "Dekho, mini tree!" He takes a dinosaur bite first.
Twist: Then the real bite. Ria studies it. "Is tree ka taste kaisa?"
Resolution: She decides — one small bite, then another. Or: "Thoda sa, phir dil se."
Moral: A bite modeled first feels safe enough to try.
''',
  'h12': '''
Story: Mumma sits down — "Bas five minute rest." She lies on the floor with a cushion.
Twist: Ria tucks a blanket over her: "Ab paani nahi maangna, okay?" Mumma: "Main itni bhi dramatic hoon?"
Resolution: Ria: "Mumma, aap hi toh ho." She brings a small cup of water and sits quietly beside her.
Moral: When grown-ups rest, children learn that love doesn't always mean fixing — sometimes just being there.
''',
  'h13': '''
Story: Ria's block tower gets knocked — pieces scatter. Mumma crouches down: "Pehle cuddle ya paani?"
Twist: Ria's body language shifts — shoulders drop, she leans toward Mumma. "Cuddle."
Resolution: One hug, then they rebuild together. "Tower phir se lagega!" Cunty the bunny hops over to sniff a block.
Moral: Meeting feelings first makes solutions stick.
''',
  'h14': '''
Story: Both grab the red car — "Mera pehle!" They argue over whose lap it is for.
Twist: Mumma: "Rio one lap, Ria one lap." They make paper tickets — Rio gets #1, Ria gets #2.
Resolution: Cuty sits as ticket checker. One minute each, then together. "Dono car, do laps!"
Ending line: "Next time? Ek ticket, teen dots!"
Moral: Tickets turn fights into fair turns — everyone wins a lap.
''',
  'h15': '''
Story: Rio is dancing to his favorite song when the music suddenly stops mid-beat. Rio freezes, eyes wide.
Twist: Mumma names the change: "Music bandh ho gayi. Ab kya karein?" She offers: "Ek minute aur dance karo, ya turant room saaf karo?"
Resolution: Rio chooses one more minute of dance, then they clean up the toys together. Mumma restarts soft music.
Ending line: Rio: "Next time phone use karoongi!" Mumma: "Haan, volume button dikha."
Moral: Badlaav ka intezaar karo, phir agla kadam lagao.
''',
  'h16': '''
Story: Papa ke liye cover aaya hai. Rio ka naya robot toy bhi aaya hai. Rio robot ko dekhta bhi nahi aur khaali dabbe mein ghus jaata hai.
Twist: Papa dabba uthaane aate hain: "Ye kabaad mein jayega." Rio: "Ye mera rocket hai!"
Resolution: Papa robot ko dabbe mein bitha dete hain: "Ye astronaut hai." Dono ulti ginti karte hain: "5, 4, 3, 2, 1… chalo!"
Moral: Dabba hi kaafi hai.
''',
  'h17': '''
Story: Light flickers, fan cuts out mid-hum. Ria tugs Mumma's hand: "Bijli ko bolo band ho jaye!"
Twist: Mumma kneels: "Thumbs up if you're worried. Bijli khel rahi thi—ab rest karegi."
Resolution: They sit in the quiet. Ria discovers she can hear her own heartbeat. "Thump-thump!" "It means you're safe."
Moral: Naming the noise makes the fear small enough to hold.
''',
  'h19': '''
Story: Parking mein Mumma: "Rio, mat bhaago!" Rio aur tez bhaagta hai.
Twist: Mumma daud ke pakadti hai aur ab alag bolti hai: "Rio, meri ungli pakdo." Rio ruk jaata hai: "Kyun?"
Resolution: "Gaadi aati hai. Ungli pakdo, hum dono saath cross karenge." Rio ungli kas ke pakad leta hai. Dono dhire dhire chalte hain.
Moral: "Mat" nahi, "ungli pakdo".
''',
  'pal03': '''
Story: Mumma: "Abhi chocolate nahi." Three reactions in three seconds.
Twist: Ria negotiates — "Bas ek piece, maine kal se diet shuru karungi!" Rio drops to the floor — "NO!" Cuty quietly munches a carrot.
Resolution: Mumma: "Carrot nahi? Theek hai." She hands Cuty a cheese cube. Ria gets a story, Rio gets a countdown hug.
Moral: One "no" can meet three different needs — see each before you solve.
''',
  'pal19': '''
Story: Subah ki daud. Mumma: "Joote pehno! Daudo mat! Bottle kahan hai? Idhar aao!" Rio sab sunta rehta hai.
Twist: Rio Cuty ko pakadke bilkul Mumma ki tarah bolta hai: "Joote pehno! Daudo mat! Bottle kahan hai? Idhar aao!"
Resolution: Mumma jam jaati hai, phir hans padti hai: "Main itna bolti hoon?" Rio: "Haan, roz."
Moral: Bachche wahi bolte hain jo roz sunte hain.
''',
};

/// Built-in hooks with [kRewrittenStories] applied where present.
/// Callers use this instead of [kDefaultHooks] so that rewritten story
/// detail is preferred over the inline const value.
final kDefaultHooksWithRewrite = kDefaultHooks
    .map((h) => kRewrittenStories.containsKey(h.id)
        ? h.copyWith(storyDetail: kRewrittenStories[h.id]!)
        : h)
    .toList();

// ── The 14-Day Post Packages ───────────────────────────────────────────────────

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
    mainIdea: 'Four illustrated figures: Ria, Rio, Cuty, and a banana. Which one is different?',
    problem: 'Four illustrated figures side by side: Ria (child), Rio (child), Cuty (bunny), and a yellow banana.',
    lesson: 'The banana — it\'s the only food! (Round 2: pattern game — who holds what?)',
    visualStyle: 'Bright, clean, minimal — 4 large icon-style illustrations on a cream card',
    imagePrompt: 'Create a bright, clean preschool puzzle card, square format, cream pastel background. Four large, simple, colorful illustrations in a row: Ria (pigtails, pink dress), Rio (blue shirt), Cuty (white bunny with pink bow), and a single yellow banana. Rounded card border, soft drop shadow under each figure, minimal clutter, no text inside the image, playful children\'s illustration style.',
    caption: 'Which one doesn\'t belong? 🧩 A simple thinking game for your little explorer — no right or wrong way to try, just fun observation! Save this for your next 5-minute activity with your child. 💛\n\n#FunLearningWithPalak #preschoolactivities #toddlerlearning #earlylearningindia #momsofinstagram',
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
    visualStyle: 'Bright cartoon reel style, soft 3D Pixar aesthetic, cream background, vertical 9:16',
    imagePrompt: 'Soft 3D Disney/Pixar-style render, cream background, vertical 9:16. Scene 1: Ria barefoot holding shoes, "Coming!" speech bubble, 5 min later still barefoot. Scene 2: Rio shrugging, water bottle beside him. Scene 3: Ria and Rio sprinting past, Cuty asleep. Scene 4: Both with angry faces, Cuty still asleep. Scene 5: Parent searching, "COME HERE!" text. No glasses on Ria and Rio.',
    caption: 'Mummas, be honest — how many times did you say this TODAY? 😂 Tag a parent who needs to see this.\n\n#FunLearningWithPalak #parentingmemes #toddlerlife #momsofindia #parentinghumor',
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
    mainIdea: 'Safe kitchen items kids can explore with adult supervision — cold items only, no stove.',
    problem: 'Safe items: plastic bowls, wooden spoons, cold pasta, large spoon — all adult-supervised.',
    lesson: '1. Adult sets out 5 safe items. 2. Child explores textures, makes sounds. 3. "What feels bumpy? What sounds splashy?"',
    visualStyle: 'Soft 3D Pixar/Disney style, warm cozy cream kitchen setting',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream kitchen countertop background, five safe kitchen items (wooden spoon, plastic bowl, cold pasta, large spoon, measuring cup) arranged playfully, a small illustrated child hands exploring them with an adult hand nearby, warm cozy lighting, minimal text, square format.',
    caption: 'No fancy toys needed — just 5 spoons from your drawer! This 5-minute activity builds sorting + counting skills while you finish making dinner. 💛 Save this for later!\n\n#FunLearningWithPalak #preschoolactivities #kitchenlearning #earlylearning #momhacks',
    cta: 'Save this for your next kitchen moment ❤️',
    hashtags: '#preschoolactivities #kitchenlearning #toddleractivities #earlylearning #sortingskills #funlearningwithpalak #momhacks',
    comments: [
      'Tried this yet? Tell us how your little chef did! 🥄',
      'Love that this uses stuff I already have at home!',
      'My 3-year-old turned it into a spoon xylophone instead 😂 still counts as learning right?',
      'Doing this tonight while I cook, thank you!',
      'So simple but so smart.',
    ],
    script: 'Slide 1: "5-MINUTE KITCHEN CHALLENGE 🥄"\nSlide 2: "Safe items only: bowls, spoons, cold pasta — adult stays close!"\nSlide 3: "Step 1: Explore textures — bumpy, smooth, cool."\nSlide 4: "Step 2: Make sounds — splash, clang, tap!"\nSlide 5: "Step 3: Count them together — 1, 2, 3, 4, 5!"\nSlide 6: "Stove = grown-up zone. Save this for safe play! ❤️"',
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
    problem: 'Prompts:\n1. "If your teddy could talk, what would it say?"\n2. "What makes you feel safe?"\n3. "What would you invent today?"\n4. "If you could be any animal at dinner, which one?"',
    lesson: 'Encourages imagination and gives you a window into how your child thinks.',
    visualStyle: 'Cozy, soft evening lighting, warm Pixar aesthetic',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream bedroom background, warm evening lighting. Ria (pigtails with pink bows, pink star dress) sitting on her bed hugging Cuty the white bunny, a small thought bubble above Cuty\'s head with a question mark. Rio (blue-grey t-shirt) peeking in from the doorway curiously. No glasses, no text inside image, gentle cozy mood, square format.',
    caption: 'Tonight, instead of the usual bedtime questions, try this one: "If your teddy could talk, what would it say?" You might be surprised by the answer. 💛\n\n#FunLearningWithPalak #talkwithyourkids #bedtimeroutine #earlychildhood #momlife',
    cta: 'What did they say? Comment below 👇',
    hashtags: '#talkwithyourkids #parentingtips #bedtimeroutine #toddlerconversations #funlearningwithpalak #earlychildhood #momlife',
    comments: [
      'We\'d love to hear what your little one said — share it below! ❤️',
      'My son said his teddy would say "let\'s go on an adventure!" 😍',
      'This made for such a sweet bedtime chat tonight.',
      'She said her teddy would just say "I love you" — I nearly cried 🥹',
      'Trying this tonight, such a lovely idea.',
    ],
    script: 'Slide 1: "ASK YOUR CHILD THIS TONIGHT 🗣️"\nSlide 2: "If your teddy could talk, what would it say?"\nSlide 3: "What makes you feel safe?"\nSlide 4: "What would you invent today?"\nSlide 5: "If you could be any animal at dinner, which one?"\nSlide 6: "Try one question — see what happens 💛"',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background. Ria and Rio standing together pointing at a floating checklist icon relevant to each slide, Cuty sitting nearby. Clean, warm, reassuring tone, no glasses, minimal text inside image, square format.',
    caption: 'Every child grows at their own pace — this is simply a gentle guide, not a race! ❤️ Save this to casually check in with your 3-year-old\'s development.\n\n#FunLearningWithPalak #preschoolmilestones #3yearoldactivities #toddlerdevelopment #parentingindia',
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
    visualStyle: 'Bold, bright, meme-style text overlays, vertical 9:16',
    imagePrompt: 'Bold bright meme-style reel, soft 3D Pixar animation, cream background, vertical 9:16. Scene 1: "1 biscuit = hungry" — Rio holding one biscuit, neutral face. Scene 2: "2 biscuits = still hungry" — same neutral face. Scene 3: "3 biscuits = \'MUMMA, MORE!\'" — dramatic happy face, arms outstretched. Scene 4: Cuty unimpressed, nibbling one carrot. No glasses.',
    caption: 'Toddler mathematics — it\'s a whole different subject 😂 Tag a parent who\'s lived this exact equation.\n\n#FunLearningWithPalak #toddlerlife #parentingmemes #momsofindia #parentinghumor',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render illustrated garden scene, cream and green tones, flowers, bushes, small toys scattered around. Cuty the small white bunny cleverly tucked partially behind a bush or flower pot with only ears and pink bow peeking out. Ria and Rio standing to the side looking around playfully, no glasses, square format, minimal text inside image.',
    caption: 'Cuty is hiding somewhere in this picture! 🐰 Can your little one spot him before you do? Comment when you find him!\n\n#FunLearningWithPalak #hiddenobject #spotthedifference #preschoolgames #kidsgames',
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
    mainIdea: 'Before: laundry basket dumped, socks everywhere. After: all pairs matched and folded.',
    problem: 'Before: socks scattered everywhere, no pairs in sight. After: sorted pairs stacked neatly, Cuty napping on the finished pile.',
    lesson: '1. Dump the basket. 2. Find matches by color/size. 3. Stack pairs together and celebrate!',
    visualStyle: 'Cozy home laundry scene, bright sock colors, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream laundry room background, vertical 9:16. Scene 1: Pile of mismatched colorful socks on floor, Ria and Rio diving in curiously. Scene 2: Rio holds two socks of different colors, shakes head "no match." Scene 3: Ria finds matching pair, holds triumphantly. Scene 4: Montage of pairs stacking, Cuty sitting on finished pile. No glasses on Ria and Rio.',
    caption: 'Turn laundry day into a game! 🧦 This simple sock-matching hunt builds sorting skills and buys you 5 quiet minutes to actually finish the laundry. Win-win. 😂\n\n#FunLearningWithPalak #laundryhacks #preschoollearning #momhacks #parentingtips',
    cta: 'Try this before your next laundry day 😂',
    hashtags: '#laundryhacks #toddleractivities #preschoollearning #momhacks #sortingskills #funlearningwithpalak #parentingtips',
    comments: [
      'Does this actually work in your house too? 😂 Tell us!',
      'Genius, why didn\'t I think of this before 😂',
      'My toddler actually helped me fold today because of this!',
      'Turning chores into games is the real parenting hack.',
      'Trying this literally today, laundry pile is huge 😅',
    ],
    script: 'Before: Laundry basket dumped — pile of mismatched colorful socks on the floor. Ria and Rio both dive in curiously.\nDuring: Rio holds two socks — different colors — shakes head "no match." Ria finds a matching pair, holds them up triumphantly.\nAfter: Small montage — pairs stacking up. Cuty "helps" by sitting on the finished pile.',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, warm evening lighting. Ria and Rio sitting together on the floor in conversation, Cuty curled nearby, gentle cozy family mood, no glasses, minimal text inside image, square format.',
    caption: 'Small questions can open up the biggest conversations. Save this and try asking just one each night this week. 💛\n\n#FunLearningWithPalak #talkwithyourkids #mindfulparenting #familytime #momlife',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background. Rio and Ria standing together pointing at a floating icon relevant to each slide, Cuty sitting nearby. Clean, warm, reassuring tone, no glasses, square format.',
    caption: 'Every child moves at their own pace — this is just a gentle guide! Save this to casually check in with your 4-year-old\'s growth. ❤️\n\n#FunLearningWithPalak #preschoolmilestones #4yearoldactivities #toddlerdevelopment #parentingindia',
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
    visualStyle: 'Three-panel meme layout, bright and simple, soft 3D Pixar render',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, three-panel layout on cream background, dinner table setting. Panel 1: Ria poking curiously at a plate of food, questioning expression. Panel 2: Rio with arms crossed, refusing his plate, stubborn expression. Panel 3: Cuty the white bunny calmly and happily eating a carrot from a small bowl. No glasses, clean simple outlines, minimal text inside image, square format.',
    caption: 'Every family has all three at the dinner table 😂 Which one is your child tonight?\n\n#FunLearningWithPalak #parentingmemes #toddlerdinner #momsofindia #pickyeater',
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
    title: 'What Comes Next? Two Rounds!',
    postType: 'Reel',
    audience: 'Parents of 2-5 year olds',
    contentGoal: 'Early math thinking game',
    mood: 'Curious / Satisfying',
    hook: 'WHAT COMES NEXT? 🟡🔵 Round 1 + Round 2! ❓',
    mainIdea: 'Two pattern rounds — color patterns and shape patterns — for growing minds.',
    problem: 'Round 1: yellow, blue, yellow, blue — then a pause on question mark.\nRound 2: circle, square, circle, square — then a pause.',
    lesson: 'Round 1: Yellow. Round 2: Circle. Build a pattern, then break it — and rebuild!',
    visualStyle: 'Bold, simple shapes, clean animation-style reveal, vertical 9:16',
    imagePrompt: 'Bold simple animation-style reel, soft 3D Pixar style, cream background, vertical 9:16. Yellow and blue circles appear in sequence: 🟡🔵🟡🔵. Then a large question mark where the next circle should go. Ria taps her chin, thinking. Yellow circle slides into place, Ria claps, Cuty hops happily. No glasses.',
    caption: 'Can your child guess what comes next? 🟡🔵🟡🔵❓ A simple pattern game that builds early math thinking!\n\n#FunLearningWithPalak #patternrecognition #preschoolmath #toddlerbrain #kidsactivities',
    cta: 'Did your child guess it before the reveal? 😄',
    hashtags: '#patternrecognition #preschoolmath #earlylearning #toddlerbrain #funlearningwithpalak #kidsactivities #momsofinstagram',
    comments: [
      'Guess before you scroll — what comes next? 👇',
      'Got it right away, yellow obviously! 🟡',
      'My daughter shouted the answer before the reveal, so proud.',
      'Simple but so satisfying to watch.',
      'This is a great one to do out loud with my son.',
    ],
    script: 'Scene 1: Pattern 1 builds on screen one shape at a time — 🟡🔵🟡🔵\nScene 2: Hold on a large "❓" where the next shape should go.\nScene 3: Ria taps her chin, thinking.\nScene 4: Reveal — 🟡 slides into place, Ria claps, Cuty hops happily.\nScene 5: Pattern 2 begins — ⭕□⭕□ — then another "❓"\nScene 6: Rio shouts "Circle!" before the reveal.',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, small icon representing the bucket theme (puzzle piece / speech bubble / house / laughing face / checklist), Ria, Rio, or Cuty featured lightly in the corner depending on tile, clean minimal design, square format.',
    caption: 'This past week, we tried something new — 5 completely different formats instead of just stories! Which one did you enjoy the most? Vote in our Story or tell us below. 💛\n\n#FunLearningWithPalak #newcontent #parentingcommunity #preschoollearning #momsofinstagram',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical carousel format. Consistent Ria (brown eyes, warm skin tone, no glasses) and Rio (brown eyes, warm skin tone, no glasses) appear across all slides with Cuty the white bunny (pink bow). Each slide shows split view: left side "official" mission prop, right side "at-home swap" using household items. Slide 1: broomstick between chairs + dupatta line. Slide 2: wooden spoon mic + steel plates. Slide 3: paper/slate + kitchen chalk. Slide 4: sunglasses/binoculars + cupped hands. Slide 5: laundry basket + dupatta rope. Slide 6: tiffin box with toys. Slide 7: tiffin, water bottle, toothbrush. Warm, practical, encouraging mood.',
    caption: 'Promised, delivered! 🏠 Here\'s exactly what to swap in for each mission using things already in your house. No special toys, no shopping list — just play. Which swap are you trying first? #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #indianmoms',
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
  QuickIdea(
    id: 'day16-voted-mission-won',
    title: 'You Voted! Here\'s Which Mission Won',
    postType: 'Static Image',
    audience: 'Existing followers who commented',
    contentGoal: 'Close the loop + build community + drive comments again',
    mood: 'Fun / Celebratory',
    hook: 'THE VOTES ARE IN! 🏆',
    mainIdea: 'A results reveal based on which mission number got the most comments, turning passive voters into repeat engagers.',
    problem: 'N/A (results format, no puzzle needed)',
    lesson: 'Reveal the winning mission with a small "why this one might be the most popular" note (e.g., "Detective Mission is your favorite — mystery never gets old!")',
    visualStyle: 'Celebratory, confetti, winning mission\'s characters front and center',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, celebratory mood with confetti. Ria and Rio (brown eyes, warm skin tone, no glasses) holding a trophy, Cuty the white bunny (pink bow) cheering. Winning mission number displayed prominently (e.g., "Mission 5 Won!"). Colorful, joyful, vertical 4:5 or square format.',
    caption: 'You voted, and Mission 5 won! 🏆 Detective Mission is your favorite — mystery never gets old! Try it today and show us how it goes! #FunLearningWithPalak #playbasedlearning #toddleractivities #noscreenactivities #montessoriathome',
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
  QuickIdea(
    id: 'day17-mission1-race-track',
    title: 'Mission 1: On Your Mark! 🏁',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Energetic / Fun',
    hook: 'MISSION 1: ON YOUR MARK! 🏁',
    mainIdea: 'Ria & Rio running, jumping a pillow hurdle, walking a line - Mission 1 of the 7 Mission Week.',
    problem: 'Parents need a simple, structured movement activity for toddlers.',
    lesson: 'Race Track builds coordination, listening skills, and gross motor confidence.',
    visualStyle: 'Consistent characters, home setting with pillow hurdle and taped line, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) and Rio (brown eyes, warm skin tone, no glasses) in a home hallway/living room. Scene: Rio jumping over a pillow "hurdle" made from cushions, Ria walking a taped line on floor, Cuty the white bunny (pink bow) cheering from the side. Bright morning light, energetic movement captured in soft 3D Pixar render style.',
    caption: 'Mission 1: Race Track! 🏁 Run, jump, walk — simple gross motor play that builds coordination and confidence. No equipment needed, just pillows and tape! Tag us trying this mission! #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #indianmoms',
    cta: 'Tag us trying this mission! 🏁',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #grossmotorskills',
    comments: [
      'My toddler LOVED the pillow hurdle! 😂',
      'We used couch cushions and it was perfect!',
      'Walking the line was harder than it looked for my 2yo!',
      'Great energy burner before nap time!',
      'Cuty cheering is the best part 🐰💕',
    ],
    script: 'Scene 1: "Mission 1: On Your Mark! 🏁" — Ria and Rio at start line\nScene 2: Rio jumps pillow hurdle — "Jump!"\nScene 3: Ria walks taped line carefully — "Walk the line"\nScene 4: Both run to finish — "Run!"\nScene 5: Cuty hands them a "medal" (spoon) 🏅\nScene 6: "Try Mission 2 today! Tag us 🏁"',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 27),
  ),

  // ── DAY 18 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day18-mission2-concert',
    title: 'Mission 2: Living Room Concert! 🎤',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Energetic / Fun',
    hook: 'MISSION 2: LIVING ROOM CONCERT! 🎤',
    mainIdea: 'Singing into a spoon mic, dancing, clapping to rhythm - Mission 2 of the 7 Mission Week.',
    problem: 'Parents need a simple music and movement activity.',
    lesson: 'Concert builds rhythm awareness, self-expression, and language through song.',
    visualStyle: 'Consistent characters, home setting with wooden spoon mic and steel plate drums, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) singing into a wooden spoon microphone, Rio (brown eyes, warm skin tone, no glasses) clapping and dancing, Cuty the white bunny (pink bow) tapping a steel plate like a drum. Kitchen utensils as instruments visible. Joyful musical chaos, warm family energy.',
    caption: 'Mission 2: Concert! 🎤 Spoon mic, plate drums, living room stage — music time with zero prep. Show us your concert! 🎤 #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #indianmoms',
    cta: 'Show us your concert! 🎤',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #musiceducation',
    comments: [
      'Wooden spoon mic is iconic now! 😂🎤',
      'My daughter performed a 20-minute concert for us!',
      'Steel plate drums = best drums ever 😂',
      'Love how this uses kitchen items as instruments.',
      'Cuty on drums is everything 🐰🥁',
    ],
    script: 'Scene 1: "Mission 2: Living Room Concert! 🎤"\nScene 2: Ria sings into wooden spoon — "La la la!"\nScene 3: Rio dances, claps to rhythm\nScene 4: Cuty taps steel plate — "Drum solo!"\nScene 5: Family bow together 🎭\nScene 6: "Your turn! Show us your concert 🎤"',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 28),
  ),

  // ── DAY 19 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day19-mission3-art-studio',
    title: 'Mission 3: Art Corner Time! 🎨',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Creative / Calm',
    hook: 'MISSION 3: ART CORNER TIME! 🎨',
    mainIdea: 'Drawing round shapes only (circles, wheels, suns) — Mission 3 of the 7 Mission Week, with circle constraint.',
    problem: 'Parents need a fine motor creative activity with a simple constraint.',
    lesson: 'Art Studio builds fine motor skills, shape recognition, and creative confidence — circle shapes only!',
    visualStyle: 'Consistent characters, home art corner with paper, slate, chalk, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) drawing a big yellow sun on paper, Rio (brown eyes, warm skin tone, no glasses) writing his name on a slate with chalk, Cuty the white bunny (pink bow) watching curiously. Kitchen chalk drawing on floor visible. Cozy creative atmosphere, warm light.',
    caption: 'Mission 3: Art Studio! 🎨 Paper, slate, chalk — three ways to create with what you have. Share your child\'s masterpiece! 🎨 #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #indianmoms',
    cta: 'Share your child\'s masterpiece! 🎨',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #fineartforkids',
    comments: [
      'Kitchen chalk on the floor = genius and washable!',
      'Slate writing practice is such a classic for a reason.',
      'My son drew a sun that looked like a blob but he was SO proud 😍',
      'Love the paper + slate + chalk variety.',
      'Art corner doesn\'t need fancy supplies!',
    ],
    script: 'Scene 1: "Mission 3: Art Corner Time! 🎨"\nScene 2: Ria draws sun on paper — "Look, a sun!"\nScene 3: Rio writes name on slate — "R-I-O"\nScene 4: Kitchen chalk on floor — "Big canvas!"\nScene 5: Cuty hops through drawings 🐰\nScene 6: "Show us your masterpiece! 🎨"',
    bucket: 'activity',
    createdAt: DateTime(2026, 9, 29),
  ),

  // ── DAY 20 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day20-mission4-detective',
    title: 'Mission 4: Case Open! 🕵️',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Mysterious / Playful',
    hook: 'MISSION 4: CASE OPEN! 🕵️',
    mainIdea: 'Two fair clues: a footprint in flour, a dropped magnifying glass — solve where Cuty hid the snack.',
    problem: 'Parents need an observation activity with visual clues, not magic.',
    lesson: 'Detective builds observation, logical thinking, and evidence collection — fair clues only!',
    visualStyle: 'Consistent characters, home setting with cardboard tube binoculars or cupped hands, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) looking through cardboard tube binoculars, Rio (brown eyes, warm skin tone, no glasses) with cupped hands around eyes, Cuty the white bunny (pink bow) with a magnifying glass. A "clue" (toy footprint) on floor. Playful mystery mood.',
    caption: 'Mission 4: Detective! 🕵️ Binoculars, listening ears, mystery clues — observation play that builds thinking skills. Did your detective solve it? #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #indianmoms',
    cta: 'Did your detective solve it? 🕵️',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #criticalthinking',
    comments: [
      'Cardboard tube binoculars = best DIY ever!',
      'My son found the "clue" in 3 seconds flat 😂',
      'Cupped hands as binoculars is so cute and free!',
      'Love how this builds real observation skills.',
      'Cuty with magnifying glass 🐰🔍',
    ],
    script: 'Scene 1: "Mission 4: Case Open! 🕵️"\nScene 2: Ria with cardboard binoculars — "I see something!"\nScene 3: Rio cupped hands around eyes — "Looking closely"\nScene 4: Rio closes eyes to listen — "Shhh, I hear it!"\nScene 5: Found the clue! 🎉\nScene 6: "Did your detective solve it? 🕵️"',
    bucket: 'challenge',
    createdAt: DateTime(2026, 9, 30),
  ),

  // ── DAY 21 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day21-mission5-rescue',
    title: 'Mission 5: Rescue Time! 🧸',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Heroic / Teamwork',
    hook: 'MISSION 5: RESCUE TIME! 🧸',
    mainIdea: 'Pushing a laundry basket, pulling a rope, helping tidy up - Mission 5 of the 7 Mission Week.',
    problem: 'Parents need a heavy work / proprioception activity.',
    lesson: 'Rescue Team builds gross motor strength, teamwork, and helpfulness.',
    visualStyle: 'Consistent characters, home setting with laundry basket and dupatta rope, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) pushing a laundry basket with toys inside, Rio (brown eyes, warm skin tone, no glasses) pulling a dupatta rope attached to the basket, Cuty the white bunny (pink bow) riding in the basket. Heavy work play, teamwork energy, warm home setting.',
    caption: 'Mission 5: Rescue Team! 🧸 Push, pull, help — heavy work play that builds strength AND teamwork. Teamwork tip from your house? 🧸 #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #indianmoms',
    cta: 'Teamwork tip from your house? 🧸',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #heavywork #proprioception',
    comments: [
      'Laundry basket rescue is our go-to now!',
      'My kids fight over who gets to pull the rope 😂',
      'Heavy work before bed = better sleep, proven!',
      'Cuty riding in the basket is the cutest 🐰',
      'This turns cleanup into a mission!',
    ],
    script: 'Scene 1: "Mission 5: Rescue Time! 🧸"\nScene 2: Ria pushes laundry basket — "Coming through!"\nScene 3: Rio pulls dupatta rope — "Pulling hard!"\nScene 4: Cuty rides inside — "Rescue complete!"\nScene 5: High five teamwork moment ✋\nScene 6: "Your teamwork tip? 🧸"',
    bucket: 'activity',
    createdAt: DateTime(2026, 10, 1),
  ),

  // ── DAY 22 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day22-mission6-treasure',
    title: 'Mission 6: Treasure Hunt! 🎁',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Exciting / Cozy',
    hook: 'MISSION 6: TREASURE HUNT! 🎁',
    mainIdea: 'Two clues found: a trail of crumbs, then a torn paper. Follow both to find the hidden treasure.',
    problem: 'Parents need an object permanence activity with two clear clues.',
    lesson: 'Treasure Hunt builds fine motor skills, logical sequencing, and nurturing play — two clues!',
    visualStyle: 'Consistent characters, home setting with tiffin box or any box with lid, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) opening a tiffin box to find a small toy, Rio (brown eyes, warm skin tone, no glasses) closing the box carefully, Cuty the white bunny (pink bow) being tucked into a blanket nearby. Cozy bedtime transition energy.',
    caption: 'Mission 6: Treasure Box! 🎁 Open, find, close, tuck in — fine motor + nurturing play with any box. What treasure did you hide? 🎁 #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #indianmoms',
    cta: 'What treasure did you hide? 🎁',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #finemotor #objectpermanence',
    comments: [
      'Tiffin box treasure hunt is brilliant!',
      'My daughter tucks Cuty in every night now 😍',
      'Opening/closing boxes is the best fine motor practice.',
      'We used an old shoebox and it worked perfectly.',
      'The bedtime transition at the end is so smooth!',
    ],
    script: 'Scene 1: "Mission 6: Treasure Hunt! 🎁"\nScene 2: Ria opens tiffin — "What\'s inside?"\nScene 3: Finds toy — "Treasure!"\nScene 4: Rio closes box carefully — "Safe now"\nScene 5: Tucking Cuty in — "Night night bunny" 🐰\nScene 6: "What treasure did you hide? 🎁"',
    bucket: 'age_practice',
    createdAt: DateTime(2026, 10, 2),
  ),

  // ── DAY 23 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'day23-mission7-daily-care',
    title: 'Mission 7: Self-Care Squad! 🍎',
    postType: 'Reel',
    audience: 'Parents of 1.5-4 year olds',
    contentGoal: 'Drive daily engagement + saves',
    mood: 'Warm / Routine',
    hook: 'MISSION 7: SELF-CARE SQUAD! 🍎',
    mainIdea: 'Eating fruit, drinking water, brushing teeth, bedtime routine - Mission 7 of the 7 Mission Week.',
    problem: 'Parents need to build independent self-care routines.',
    lesson: 'Daily Care builds independence, body awareness, and healthy habits. The 5-second wait: child struggles, parent waits about 5 seconds, child tries, parent helps only when needed, child completes the task.',
    visualStyle: 'Consistent characters, home bathroom/kitchen setting, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) eating apple slices from her tiffin, Rio (brown eyes, warm skin tone, no glasses) drinking from his water bottle, both brushing teeth side by side, Cuty the white bunny (pink bow) watching from the counter. Cozy bathroom/kitchen routine atmosphere.',
    caption: 'Mission 7: Daily Care! 🍎 Eat, drink, brush, sleep — the self-care squad routine with your own tiffin, bottle, brush. Which routine is hardest at your house? #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #indianmoms',
    cta: 'Which routine is hardest at your house? 🍎',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #selfcare #routinesforkids',
    comments: [
      'Tiffin for snacks = independence unlocked!',
      'Brushing together makes it way easier.',
      'Water bottle independence = fewer spills 😂',
      'Bedtime routine is still our biggest battle 😭',
      'Cuty watching them brush is too cute 🐰',
    ],
    script: 'Scene 1: "Mission 7: Self-Care Squad! 🍎"\nScene 2: Ria eats apple from tiffin — "Crunch!"\nScene 3: Rio drinks water — "Glug glug"\nScene 4: Ria struggles to brush — Mumma waits 5 seconds — Ria tries — Mumma helps only when needed — "Scrub scrub"\nScene 5: Cuty watches from counter 🐰\nScene 6: "Hardest routine at your house? 🍎"',
    bucket: 'age_practice',
    createdAt: DateTime(2026, 10, 3),
  ),

  // ── DAY 24 ────────────────────────────────────────────────────────────────────
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
    visualStyle: 'Fast cuts (1-2 sec per mission), consistent characters, upbeat music, vertical 9:16',
    imagePrompt: 'Fast-cut vertical 9:16 reel montage, Soft 3D Pixar/Disney-style render, cream background. Quick 1-2 second shots: 1) Ria/Rio jumping pillow hurdle (Race Track) 2) Ria singing into spoon, Rio on plate drums (Concert) 3) Ria drawing sun, Rio on slate (Art Studio) 4) Ria with binoculars, Rio cupped hands (Detective) 5) Pushing laundry basket, pulling rope (Rescue) 6) Opening tiffin box, finding toy (Treasure) 7) Eating fruit, drinking water, brushing (Daily Care). Final frame: All 7 mission icons in a grid, "We Did It!" celebration with Ria, Rio, Cuty. Upbeat, energetic, no glasses on children.',
    caption: '7 screen-free missions, 60 seconds, zero shopping required 🏠✨ Follow along as we play through all of them with Ria & Rio! #FunLearningWithPalak #noscreenactivities #playbasedlearning #montessoriathome #earlylearning',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, square carousel format. Consistent Ria (brown eyes, warm skin tone, no glasses), Rio (brown eyes, warm skin tone, no glasses), Cuty (white bunny, pink bow) across all slides. Celebratory confetti/trophy theme. Slide 1: "WE DID IT — ALL 7 MISSIONS COMPLETE! 🎉" with trophy. Slides 2-8: Each mission with one-line learning note. Slide 9: "What\'s next? Tell us below!" with Ria, Rio, Cuty excited for new adventures.',
    caption: 'A full week of screen-free missions, complete! 🎉 From racing to detective work to bedtime routines, Ria & Rio (and hopefully your little ones too) played through all 7. What should our next mission set be about? #FunLearningWithPalak #playbasedlearning #toddleractivities #noscreenactivities #montessoriathome',
    cta: 'Which mission will you repeat this week? Comment below! 🎉',
    hashtags: '#playbasedlearning #toddleractivities #funlearningwithpalak #noscreenactivities #montessoriathome #milestone',
    comments: [
      'This was such a fun week to follow along with!',
      'Please do a kitchen-themed mission series next!',
      'My daughter asks for "mission time" every day now 😍',
      'Loved seeing this build up all week.',
      'Can\'t wait to see what\'s next!',
    ],
    script: 'Slide 1: "WE DID IT — ALL 7 MISSIONS COMPLETE! 🎉"\nSlide 2: "Race Track → Movement builds confidence 🏁"\nSlide 3: "Concert → Music is self-expression 🎤"\nSlide 4: "Art Studio → Creativity needs no fancy tools 🎨"\nSlide 5: "Detective → Observation is a superpower 🕵️"\nSlide 6: "Rescue Team → Teamwork makes the dream work 🧸"\nSlide 7: "Treasure Box → Small things bring big joy 🎁"\nSlide 8: "Daily Care → Routines build independence 🍎"\nSlide 9: "What\'s next? Tell us below! 🚀"',
    bucket: 'community',
    createdAt: DateTime(2026, 10, 5),
  ),
];

// ── Bulk Parser ───────────────────────────────────────────────────────────────

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
      title.isNotEmpty ||
      hook.isNotEmpty ||
      mainIdea.isNotEmpty ||
      problem.isNotEmpty ||
      lesson.isNotEmpty ||
      caption.isNotEmpty ||
      imagePrompt.isNotEmpty ||
      script.isNotEmpty;

  QuickIdea toQuickIdea(String id) {
    final comments = <String>[];
    if (pinnedComment.isNotEmpty) comments.add(pinnedComment);
    comments.addAll(replyComments.where((c) => c.isNotEmpty));

    // Pad to 5 comments minimum if reply comments are available
    if (replyComments.isNotEmpty) {
      while (comments.length < 5) {
        comments.add(replyComments[comments.length % replyComments.length]);
      }
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
  String? currentKey;
  final currentVal = StringBuffer();

  for (int i = 0; i < headerLines.length; i++) {
    final line = headerLines[i];
    final colonIdx = line.indexOf(':');
    final isNewKey = colonIdx > 0 &&
        line.substring(0, colonIdx).trim().split(' ').length <= 4 &&
        !line.startsWith('---') &&
        !line.startsWith(' ');

    if (isNewKey) {
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
    postType: _normalizePostType(
      readKey('Post Type').isNotEmpty ? readKey('Post Type') : readKey('PostType'),
    ),
    audience: readKey('Audience').isNotEmpty
        ? readKey('Audience')
        : 'Parents of 3-6 year olds',
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
  if (lower.contains('puzzle') ||
      lower.contains('figure') ||
      lower.contains('hidden') ||
      lower.contains('pattern')) {
    return 'challenge';
  }
  if (lower.contains('humor') ||
      lower.contains('funny') ||
      lower.contains('mumma')) {
    return 'humor';
  }
  if (lower.contains('activity') ||
      lower.contains('challenge') ||
      lower.contains('hunt')) {
    return 'activity';
  }
  if (lower.contains('talk') ||
      lower.contains('question') ||
      lower.contains('ask')) {
    return 'conversation';
  }
  if (lower.contains('skill') ||
      lower.contains('year-old') ||
      lower.contains('checklist')) {
    return 'age_practice';
  }
  if (lower.contains('wrap') ||
      lower.contains('favorite') ||
      lower.contains('feedback')) {
    return 'community';
  }
  return '';
}