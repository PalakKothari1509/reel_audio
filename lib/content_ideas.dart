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

  // NEW FIELDS for specificity & anti-AI-smell
  final String setting;        // where/when, Indian-home specific
  final String sceneDetail;    // one physical, imperfect detail
  final String dialogue;       // the line somebody actually says
  final String mess;           // what goes wrong and stays wrong
  final String innerThought;   // what the parent thinks but doesn't say
  final String endingBeat;     // closing image; replaces spoken moral
  final List<String> defaultCast;   // 2–3 max, not all 7
  final bool keepMoralOffScreen;

   // Task 3: quote, detail, punchline
  final String quote;          // exact line of dialogue for the hook
  final String detail;         // one concrete sensory detail
  final String punchline;      // closing image/beat (alternative to endingBeat)

  /// Ready-to-use 20-second viral Reel prompt (Part 1 + Part 2 + on-screen text).
  /// Empty when the hook does not have a pre-built viral prompt.
  final String readyPrompt;

  /// Story quality score (1-10), derived from StoryCheck pass count.
  final int score;

  /// Quality band: 'Ready', 'Improve', or 'Rewrite'. Read from StoryCheck.
  final String band;

  /// ISO date string of when the story was last reviewed.
  final String reviewedOn;

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
    this.setting = '',
    this.sceneDetail = '',
    this.dialogue = '',
    this.mess = '',
    this.innerThought = '',
    this.endingBeat = '',
    this.defaultCast = const ['Ria', 'Rio', 'Cuty'],
    this.keepMoralOffScreen = false,
    this.quote = '',
    this.detail = '',
    this.punchline = '',
    this.readyPrompt = '',
    this.score = 0,
    this.band = '',
    this.reviewedOn = '',
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
    String? setting,
    String? sceneDetail,
    String? dialogue,
    String? mess,
    String? innerThought,
    String? endingBeat,
    List<String>? defaultCast,
    bool? keepMoralOffScreen,
    String? quote,
    String? detail,
    String? punchline,
    String? readyPrompt,
    int? score,
    String? band,
    String? reviewedOn,
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
        setting: setting ?? this.setting,
        sceneDetail: sceneDetail ?? this.sceneDetail,
        dialogue: dialogue ?? this.dialogue,
        mess: mess ?? this.mess,
        innerThought: innerThought ?? this.innerThought,
        endingBeat: endingBeat ?? this.endingBeat,
        defaultCast: defaultCast ?? this.defaultCast,
        keepMoralOffScreen: keepMoralOffScreen ?? this.keepMoralOffScreen,
        quote: quote ?? this.quote,
        detail: detail ?? this.detail,
        punchline: punchline ?? this.punchline,
        readyPrompt: readyPrompt ?? this.readyPrompt,
        score: score ?? this.score,
        band: band ?? this.band,
        reviewedOn: reviewedOn ?? this.reviewedOn,
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
        'setting': setting,
        'sceneDetail': sceneDetail,
        'dialogue': dialogue,
        'mess': mess,
        'innerThought': innerThought,
        'endingBeat': endingBeat,
        'defaultCast': defaultCast,
        'keepMoralOffScreen': keepMoralOffScreen,
        'quote': quote,
        'detail': detail,
        'punchline': punchline,
        'readyPrompt': readyPrompt,
        'score': score,
        'band': band,
        'reviewedOn': reviewedOn,
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
        setting: j['setting'] as String? ?? '',
        sceneDetail: j['sceneDetail'] as String? ?? '',
        dialogue: j['dialogue'] as String? ?? '',
        mess: j['mess'] as String? ?? '',
        innerThought: j['innerThought'] as String? ?? '',
        endingBeat: j['endingBeat'] as String? ?? '',
        defaultCast: (j['defaultCast'] as List?)?.map((e) => e as String).toList() ?? ['Ria', 'Rio', 'Cuty'],
        keepMoralOffScreen: j['keepMoralOffScreen'] as bool? ?? false,
        quote: j['quote'] as String? ?? '',
        detail: j['detail'] as String? ?? '',
        punchline: j['punchline'] as String? ?? '',
        readyPrompt: j['readyPrompt'] as String? ?? '',
        score: j['score'] as int? ?? 0,
        band: j['band'] as String? ?? '',
        reviewedOn: j['reviewedOn'] as String? ?? '',
      );

  /// Laid out as the story form, ready for Write the script.
  /// If [storyDetail] is present, it is the primary source. Otherwise, falls back
  /// to individual fields. If both are empty, marks the idea as "Draft".
  String asStoryText() {
    if (storyDetail.trim().isNotEmpty) {
      return 'Cover hook: $cover\n'
          'Hook: $opening\n'
          'Who: ${defaultCast.join(", ")}\n'
          'Where: $setting\n'
          'What starts it: $problem\n'
          'Scene detail: $sceneDetail\n'
          'Dialogue: $dialogue\n'
          'What goes wrong: $mess\n'
          'Parent inner thought: $innerThought\n'
          'How it is solved: $endingBeat\n'
          'Moral (off-screen): ${keepMoralOffScreen ? "(not spoken)" : lesson}\n'
          'Post format: $postFormat\n'
          'Strategy: $strategy\n'
          'Caption: $caption\n'
          'Pinned comment: $pinnedComment\n'
          '$storyDetail\n'
          'Status: ${usedOn.isEmpty ? "New" : usedOn}';
    }
    // Fallback to individual fields, but mark as Draft if no real content
    final hasContent = setting.isNotEmpty || sceneDetail.isNotEmpty || dialogue.isNotEmpty ||
        mess.isNotEmpty || innerThought.isNotEmpty || endingBeat.isNotEmpty;
    if (!hasContent) {
      return 'Cover hook: $cover\n'
          'Hook: $opening\n'
          'Who: ${defaultCast.join(", ")}\n'
          'Where: $setting\n'
          'What starts it: $problem\n'
          'Status: Draft\n';
    }
    return 'Cover hook: $cover\n'
        'Hook: $opening\n'
        'Who: ${defaultCast.join(", ")}\n'
        'Where: $setting\n'
        'What starts it: $problem\n'
        'Scene detail: $sceneDetail\n'
        'Dialogue: $dialogue\n'
        'What goes wrong: $mess\n'
        'Parent inner thought: $innerThought\n'
        'How it is solved: $endingBeat\n'
        'Moral (off-screen): ${keepMoralOffScreen ? "(not spoken)" : lesson}\n'
        'Post format: $postFormat\n'
        'Strategy: $strategy\n'
        'Caption: $caption\n'
        'Pinned comment: $pinnedComment\n'
        'Status: ${usedOn.isEmpty ? "New" : usedOn}';
  }
}

const kHookCategories = [
  'Relatable',
  'Struggle first',
  'Surprising',
  'Warm lesson',
  'Page & milestone',
  'Navratri',
  'Diwali',
  'Series',
];

/// Kids Safety hooks for the shield collection.
/// Each carries a full storyDetail with the Story/Twist/Resolution/Moral
/// labels the offline generator expects.
const kSafetyHooks = <HookIdea>[
// NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'safety-good-touch',
    category: 'Warm lesson',
    cover: 'Meri Marzi!',
    opening: 'Ria ne sabke saamne Uncle ko mana kar diya! 😳',
    problem: 'A relative insists on a hug and kiss, but Ria does not want to — and the adults are watching.',
    lesson: 'Pyaar karne ke liye hug zaroori nahi. Ria ki marzi bhi zaroori hai.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'जब कोई भी touch अच्छा न लगे, तो तुरंत किसी भरोसेमंद adult (मम्मी, पापा, टीचर) के पास जाओ। अगर पहली बार कोई न सुने, तो दुबारा बोलो — तब तक बोलो जब तक कोई मदद न करे। #ChildSafety #GoodTouchBadTouch #BodyAutonomy #IndianParents #FunLearningWithPalak',
    pinnedComment: 'क्या बाचों को relatives को hug करने के लिए force करना चाहिए?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At Daadi's house, relatives gather. Uncle opens his arms: "Ria, hug? Ek pappi toh banti hai!" Ria feels the pressure — everyone's eyes are on her. She steps back, hides behind Mumma: "Nahi, mujhe hug nahi chahiye."
Twist: An aunt insists: "Arre beta, itna bhi kya sharm? Uncle pyaar karte hain!" Mumma steps in calmly: "Beta, Ria ne mana kiya. Uske liye kaafi hai." Mumma turns to Ria: "Wave, high-five, ya kuch bhi nahi — tum choose karo." Ria gives a small wave from beside Mumma, shoulders relaxing.
Resolution: Uncle smiles: "Wave bhi accha hai." End card: "Pyaar karne ke liye hug zaroori nahi. Ria ki marzi bhi zaroori hai."
Moral: Body autonomy starts with a simple "no thank you" — and adults who respect it.
''',
    setting: 'Daadi\'s living room, afternoon light, family gathering',
    sceneDetail: 'Uncle with open arms, Ria hiding behind Mumma\'s saree, aunt leaning in with expectant smile',
    dialogue: '"Ria, hug? Ek pappi toh banti hai!" "Nahi, mujhe hug nahi chahiye."',
    mess: 'Relatives keep insisting — "Arre beta, itna bhi kya sharm?" — the pressure builds',
    innerThought: 'I need to show Ria that her "no" has power, without making her fear all touch.',
    endingBeat: 'Uncle accepts the wave. Ria breathes easy. Mumma squeezes her hand — "Main tumhare saath hoon."',
    defaultCast: ['Ria', 'Mumma', 'Daadi', 'Uncle'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'safety-stranger',
    category: 'Warm lesson',
    cover: 'Chocolate Nahi!',
    opening: 'Park mein aunty ne chocolate di... Ria ne kya kiya?',
    problem: 'A person Ria does not know offers her a chocolate at the park',
    lesson: 'Jo hume nahi jaanta, uske saath nahi jaate',
    postFormat: 'Reel',
    strategy: '',
    caption: 'जो हम नहीं जानते, उनसे कुछ नहीं लेना सीखाएं। पहले हमेशा मम्मी या पापा के पास चले आओ। #StrangerSafety #ChildSafety #SafetyTips #IndianParents #FunLearningWithPalak',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At park, stranger offers Ria chocolate: "Mere saath chalo, aur milegi."
Twist: Ria takes two steps back: "Mumma!" She runs to Mumma and tells her everything.
Resolution: Mumma thanks Ria for telling her right away. They practice saying no to strangers.
Moral: "Mere saath chalo" — but only with people you know and trust. पहले परिवार वालों को बताओ।
''',
    setting: 'Society park, evening, strangers nearby',
    sceneDetail: 'A man offering a wrapped chocolate bar to Ria',
    dialogue: '"Mere saath chalo, aur milegi."',
    mess: 'The stranger persists, taking two steps closer as Ria looks for Mumma',
    innerThought: 'My code-word only works if I teach it before the moment arrives.',
    endingBeat: 'Ria runs to Mumma: "Mumma! Stranger ne chocolate di!"',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'safety-road',
    category: 'Warm lesson',
    cover: 'Ruko, Dekho, Chalo!',
    opening: 'Zebra crossing par Rio ruk gaya... kisi ne bola nahi tha!',
    problem: 'Toddlers run toward the road without stopping or looking',
    lesson: 'Red light, green light ka khel ghar par seekho',
    postFormat: 'Reel',
    strategy: '',
    caption: 'सड़क पार करते समय हमेशा adult के साथ चलें। कभी सड़क पर न जाएँ, बिना बुलाए। #RoadSafety #ChildSafety #CrossingSafety #IndianParents #FunLearningWithPalak',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ball rolls toward the gate. Rio starts after it, takes two steps — "Ruko—road!"
Twist: Mumma grabs his hand: "Stop, look, listen." They count cars together. "Ab green light?"
Resolution: Mumma: "Jab grown-up kahe aur saaf ho." They hold hands and cross together.
Moral: Khel mein seekha — sadak par bhi kaam aayega.
''',
    setting: 'Crossroads near the school gate, 3pm, honking in the distance',
    sceneDetail: 'A red ball rolls into the street',
    dialogue: '"Stop! Hold my hand — ek, do, teen."',
    mess: 'The ball bounces once and keeps rolling, just past the curb',
    innerThought: 'I said "look both ways" seventeen times this week.',
    endingBeat: 'Ria stands at the curb, hand still held, watching the ball.',
    defaultCast: ['Ria', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'safety-emergency-number',
    category: 'Warm lesson',
    cover: 'Mera Number Gaana',
    opening: 'Ria ko Mumma ka number yaad nahi tha... phir gaana bana.',
    problem: 'A preschooler cannot recall a parent\'s phone number when asked',
    lesson: 'Gaane mein yaad karna aasaan hota hai',
    postFormat: 'Reel',
    strategy: '',
    caption: 'अपना नाम और नंबर याद रखें — लेकिन कोई गुमनाम बातों में नम्बर न दें। हमेशा परिवार वाले या पुलिस के पास जाएं। #EmergencySafety #ChildSafety #SafetyTip #IndianParents #FunLearningWithPalak',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Papa makes a clapping rhythm with family contact details — name first, number made of pretend digits on screen. Ria remembers her name first.
Twist: The family practises: "Agar mummy nahi ho toh — Dada, ya neighbor?" Ria points to Dada.
Resolution: "Pura number yaad rakho," Papa says, "lekin pehle apna naam bolo." Ria: "Main Ria hoon."
Moral: Name pehle, number baad mein — safety starts with identity.
''',
    setting: 'Phone charging on the kitchen counter, juice spill on the floor',
    sceneDetail: 'Juice dripping from the phone case onto the tiles',
    dialogue: '"Mumma, 1-0-0 pe phir se khel liya!"',
    mess: 'The sticky floor makes the phone slip again as she reaches',
    innerThought: 'Why does the only number she remembers need an ambulance?',
    endingBeat: 'Cuty licking the juice off the floor, phone now dry on the counter.',
    defaultCast: ['Rio', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'safety-lost-crowd',
    category: 'Warm lesson',
    cover: 'Mela Mein Kho Gayi',
    opening: 'Bheed mein Mumma ka haath chhoot gaya... ab kya?',
    problem: 'Ria loses her parents\' hand in a crowded fair',
    lesson: 'Kho jao toh ruk jao, aur sahi insaan se madad maango',
    postFormat: 'Reel',
    strategy: '',
    caption: 'खो जाओ तो रुक जाओ और सुरक्षित adult या मददगार से पूछो। #LostChild #CrowdSafety #ChildSafety #IndianParents #FunLearningWithPalak',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At mela, Ria can't see Mumma. She stops near a help desk — stays put.
Twist: A uniformed worker asks: "Kya tumhari mummy dhundh rahi ho?" Ria tells the helper her own name and where she was standing.
Resolution: In minutes, Mumma rushes over. "Ria! Are you here?" Mumma hugs her tight. "Always hold my hand."
Moral: Stop, stay, tell — and trust a uniformed helper. कभी स्ट्रेंजर से नहीं, हमेशा मददगार से पूछो।
''',
    setting: 'Melas at the community center, loudspeakers, 1pm',
    sceneDetail: 'A red balloon tied to a stroller, drifting away',
    dialogue: 'Ria tells the helper her own name and where she was standing.',
    mess: 'The balloon pops against the ceiling fan as she runs',
    innerThought: 'I told her to hold my sari end, not the balloon string.',
    endingBeat: 'Ria is reunited with Mumma, says "Main kabhi sirf help desk ke paas rukti hoon."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'safety-kitchen-line',
    category: 'Warm lesson',
    cover: 'Laal Line Ke Peeche',
    opening: 'Rasoi mein Ria ko aage jaana tha... par ek line thi.',
    problem: 'A toddler keeps wandering into the kitchen while the stove is on',
    lesson: 'Garam jagah ke liye ek clear line banao',
    postFormat: 'Reel',
    strategy: '',
    caption: 'गर्म जगह के पास न जाना — लाल line हमेशा मानें। कभी घंटे में न जाएँ, बिना बुलाए मम्मी या पापा से पूछें। #KitchenSafety #ChildSafety #SafetyFirst #IndianParents #FunLearningWithPalak',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Gas jal rahi hai — Ria yahin rukegi. Mumma is cooking; Ria carries a toy car toward the stove.
Twist: Mumma: "Gas jal rahi hai—Ria yahin rukegi." Ria stops where the red line is drawn.
Resolution: Papa adds a floor marker the next day: "Laal line = safe boundary." Ria stays behind it, watching safely.
Moral: Grown-up present, boundary clear — safety needs both.
''',
    setting: 'Small kitchen, morning, pressure cooker warming up',
    sceneDetail: 'A yellow tape line drawn on the floor with chalk',
    dialogue: '"Yeh line hai, bachche! Ussi taraf khade raho."',
    mess: 'Rio steps over with one tiny toe and it crumbles into powder',
    innerThought: 'Do I really need to use masking tape?',
    endingBeat: 'Rio sits cross-legged just inside the line, building with dal.',
    defaultCast: ['Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Bus ka samay ho raha hai; Mumma jhukkar Ria ke joote pehnane lagti hai. Ria haath jhatak deti hai: "Main khud!" Joota ulte pairon lag jaata hai, Ria pengun ban kar chalti hai.

Twist: Mumma apni taraf se koi madad nahi karti. Woh do second ke liye haath jodthi hai, phir kehti: "Ek, do, teen, char, paach."
Resolution: Ria joota theek karti hai, sahi se bandh jaata hai. "Dekho!" Bus ka horn bajta hai, lekin Ria ab pakkar mehsoos karti hai.
Moral: A little patience and a count to five gives Ria a win she earned herself.
''',
    setting: 'Front door, shoes scattered, keys jangling in Mumma pocket',
    sceneDetail: 'One shoe on wrong foot, heel caught on the doorframe',
    dialogue: 'Main khud!',
    mess: 'Ria keeps switching feet mid-step, shoe keeps slipping',
    innerThought: 'Mumma jaldi karegi, but she is not moving, and I am almost done',
    endingBeat: 'Shoe finally on right foot, both smiling at the near-miss',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16 aspect ratio. Living room hallway near the door, morning sunlight, shoes scattered. Ria in a sparkly pink star dress and pigtails stubbornly plants her feet, pushing Mumma's hand away with a dramatic pout: "Main khud pehnungi!" Mumma (yellow embroidered kurti, top bun) sighs, steps back, and counts on her fingers: "1, 2, 3, 4, 5." Ria struggles, putting a sneaker on the wrong foot and waddling like a penguin, heel catching the frame. After a funny wiggle, she flips it onto the right foot, beams proudly, and points down: "Dekha? Direct fit!"

On-Screen Text:
- [0-3s]: "MAIN KHUD PEHNUNGI! 👟😤"
- [3-7s]: "MOM PATIENCE LEVEL: 100 ⏳"
- [7-10s]: "WRONG FOOT WADDLE 🐧😂"
- [10-15s]: "JOOTAA TAYYAR! 🎉✨"
- [15-20s]: "PROUD MOMENT 🥹❤️"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria in pink star dress pushes Mumma's hand away at the front door, shouting "Main khud!" Text on screen: "MAIN KHUD! 👟😤" and "MOM PATIENCE LEVEL: 100 ⏳". Mumma in yellow kurti counts on fingers while Ria tries to jam a shoe on the wrong foot and waddles like a penguin. Comedic Hinglish dubbed voice.

Part 2 (10-20s): 3D Pixar style, 9:16. Ria wiggles her foot, flips the shoe onto the right foot with a triumphant grin. Text on screen: "WRONG FOOT WADDLE 🐧😂" then "JOOTAA TAYYAR! 🎉✨". Ria stands tall showing both shoes tied, Mumma claps proudly. Energetic comedic payoff.

Audio/Dialogue (Hinglish): Toddler girl sassy voice: "Mumma hato, main khud karungi!" Mumma laughs gently: "Achha baba, try karo!" Ria triumphant: "Told you! I am a big girl now!"
    ''',
  ),

  HookIdea(
    id: 'h02',
    category: 'Relatable',
    cover: 'Bas 5 Minute Aur?!',
    opening: 'Phone band hua... aur Ria ka rona shuru!',
    problem: 'Ria cries when cartoon ends mid-song without warning',
    lesson: 'Two-minute warning helps Ria choose a calm goodbye',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cartoon band hone ka waqt. Mumma: "Phone band." Ria: "Bas paanch minute!" Ria royi, lekin asli dikat yeh nahi ki phone band ho raha tha — episode beech mein toot gaya tha.
Twist: Agle din Mumma pehle puchhti: "Ye episode kab khatam hoga?" Ek visual timer lagati hai.
Resolution: Episode khatam hota hai, Ria khud kehti hai "Khatam!" aur phone Mumma ko deti hai. "Kal timer pehle lagayege."
Moral: Beech mein nahi, khatam hone par — par pehle se batana bhi badi baat hai.
''',
    setting: 'Living room, late afternoon sun, phone on the armrest',
    sceneDetail: 'TV credits rolling mid-song, phone face-down on the armrest',
    dialogue: 'Bas five minute aur!',
    mess: 'Screen is paused mid-song, credits still rolling in the background',
    innerThought: 'Main kab tak ye gaana sun sakti hoon, until even the humming stops',
    endingBeat: 'Ria blows a kiss at the TV, then lets the screen go dark',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room couch, afternoon light, cartoon paused mid-song. Ria (sparkly pink star dress, pigtails) suddenly collapses into tears, tiny fists shaking. Mumma (yellow kurti, top bun) looks up from her phone. Ria points at the silent screen: "Wapas! Wapas!" Text on screen: "PHONE BAND HUA..." then "😭 RONA SHURU!"

On-Screen Text:
- [0-3s]: "PHONE BAND HUA... 😭"
- [3-7s]: "RONA SHURU! 💧💦"
- [7-12s]: "MOM'S PHONE = EMOTIONAL SUPPORT 📱😢"
- [12-16s]: "5-MINUTE-WARNING IS NOT IN THE SCRIPT 📜"
- [16-20s]: "NEXT TIME: SET TIMER! ⏰⏰"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria melodramatically cries on the couch, tears like a water fountain, pointing at the paused TV. Text: "PHONE BAND HUA... 😭" "RONA SHURU! 💧💦". Mumma pretends to be surprised: "Arre, cartoon band ho gaya!" 

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma sits beside Ria, gives her a gentle hug. Text: "MOM'S PHONE = EMOTIONAL SUPPORT 📱" then "5-MINUTE-WARNING IS NOT IN THE SCRIPT". Ria's tears slow, she sniffs and gives the TV a tiny kiss. Text: "NEXT TIME: SET TIMER! ⏰".

Audio/Dialogue (Hinglish): Ria wailing: "Nahi nahi! Wapas chahiye!" Mumma gently: "Beta, yeh episode kal bhi chalega." Ria still sniffling: "Par aaj nahi!" Mumma: "Theek hai, 5 minute warning se hi shuru karein ge."
    ''',
  ),

  HookIdea(
    id: 'h03',
    category: 'Relatable',
    cover: 'Mujhe Nahi Aata!',
    opening: 'Rio ka tower teesri baar gira... aur usne haar maan li.',
    problem: 'Rio gives up when his block tower keeps falling',
    lesson: 'Galti se hi seekhte hain, phir se try karo',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio ka tower teesri baar girta hai. Woh blocks se haath kash karke bolta hai: "Mujhe nahi aata!"
Twist: Ria turant madad karne aati hai, lekin Rio uska haath hata deta hai: "Main karunga!" Ria samajh jaati hai ki madad karne ka matlab haath chhune se nahi, sochne se hai.
Resolution: Ria chupchaap do bade blocks Rio ke paas rakhti hai: "Neece rakho, base bana ke dekho." Rio tower khada kar deta hai. "Dekho, khada hai!"
Moral: Hint do, haath mat lagao — bachcha khud hi seekh jaata hai.
''',
    setting: 'Play mat in the living room, afternoon sunlight through the window',
    sceneDetail: 'Tower leans at a 45-degree angle, blocks scattered',
    dialogue: '"Mujhe nahi aata!" Rio throws his hands up.',
    mess: 'Rio refuses help, Rio refuses to try, Rio lies on the floor',
    innerThought: 'Why does he fight every offer but never accept defeat?',
    endingBeat: 'Rio builds a two-block wide base and succeeds.',
    defaultCast: ['Rio', 'Ria', 'Cuty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h04',
    category: 'Relatable',
    cover: 'Cuty Kahan Gaya?!',
    opening: 'Ria ki awaaz tezi — "Cuty kahan gaya?!"',
    problem: 'Room so messy they keep getting distracted',
    lesson: 'Clear one small path at a time',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria shouts, "Cuty kahan gaya?!" The floor is a toy jungle. Every time Rio searches, he starts playing.
Twist: Ria makes a "Cuty rescue basket" — they clear just one path, then spot Cuty asleep under a blanket.
Resolution: Rio whispers, "Hum poora room saaf karne aaye the?" Ria: "Shhh, patient so raha hai."
Moral: Ek chhota sa raasta bhi bada madad karta hai.
''',
    setting: 'Living room floor, morning sunlight through window',
    sceneDetail: 'Toys scattered everywhere, one clear path leads to the couch',
    dialogue: '"Cuty kahan gaya?!" "Arre Ram! Yahan se kitna bhi ghusaaye..."',
    mess: 'Rio starts playing with blocks mid-search, Ria redirects him to clearing one path',
    innerThought: 'One path at a time — we can do this.',
    endingBeat: 'Rio spots Cuty under a blanket, they both tiptoe to rescue her quietly.',
    defaultCast: ['Rio', 'Cuty', 'Ria'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h05',
    category: 'Relatable',
    cover: 'Ek Aur Paani!',
    opening: 'Lights band... aur Ria phir se paani maang rahi hai.',
    problem: 'Bedtime stretches on with one more water, one more story, one more hug',
    lesson: 'A small cup on the bedside table ends the loop',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Lights off. Ria calls out: "Mumma, ek aur paani!" Mumma brings it. Then Ria remembers: "Teddy ko blanket chahiye." Then: "Aur ek hug?" Planned hug. Ria snuggles in.
Twist: Mumma pre-places a small cup and a hug-stuffed animal on the bedside table the next night.
Resolution: When lights go off, Ria reaches for both. "Ab bas... unless Teddy ko paani chahiye."
Moral: Jo roz maanga jaata hai, pehle se rakh do — ek chhota routine, ek calmer bedtime.
''',
    setting: 'Bedroom nightstand, single bedside lamp on',
    sceneDetail: 'Water cup and Teddy bear already on the nightstand',
    dialogue: 'Maa, ek aur paani!',
    mess: 'Ria keeps inventing things Teddy might need — blanket, spoon, story',
    innerThought: 'Ek baar toh mujhe bhi sochne ka time milega, when does the asking stop',
    endingBeat: 'Ria reaches for both cup and Teddy, then hugs them both',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Cozy bedroom, single lamp on nightstand, nighttime glow. Ria (pink star dress, pigtails in pajamas) sits bolt upright: "Maa, ek aur paani!" Mumma (yellow kurti, sleepy top bun) walks over with a tiny cup. Text on screen: "BEDTIME STRETCH 🤍" "1 MORE WATER • 1 MORE HUG • 1 MORE TEDDY"

On-Screen Text:
- [0-3s]: "BEDTIME STRETCH 🤍"
- [3-7s]: "1 MORE WATER • 1 MORE HUG • 1 MORE TEDDY"
- [7-10s]: "THE LOOP IS REAL 💧🔄"
- [10-15s]: "PREVENTION > REACTION ✅"
- [15-20s]: "TODDLER PRO TIP: NIGHTSTAND PREP 🌙✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria asking for water in bed, Mumma bringing tiny cup. Ria finishes, pats Teddy: "Teddy ko pani do." Mumma: "Teddy toh nahi peeta beta." Ria: "Ek hug?" Mumma hugs her goodnight. Text: "BEDTIME STRETCH 🤍" "1 MORE WATER • 1 MORE HUG • 1 MORE TEDDY".

Part 2 (10-20s): 3D Pixar style, 9:16. Next night: Mumma puts cup AND Teddy on nightstand before lights out. Ria reaches, pats both, hugs them, settles. Text: "PREVENTION > REACTION ✅" "TODDLER PRO TIP: NIGHTSTAND PREP 🌙✨". Ria whispers: "Goodnight Teddy. Goodnight paani."

Audio/Dialogue (Hinglish): Ria sleepy: "Maa, ek aur paani please." Mumma gentle: "Thoda sa piya beta, ab so jao." Ria patting Teddy: "Teddy bhi pyaas lagi hai." Mumma smiling: "Teddy toh khaali hai, tu piya." Ria hugging both: "Par Kalia ka paani bhi do?" Mumma: "Kalia toh khaali hai." Ria giggling: "Theek hai, main khud karungi!"
    ''',
  ),

  HookIdea(
    id: 'h07',
    category: 'Relatable',
    cover: 'Brush Nahi Karungi!',
    opening: 'Ria kambal ke andar chhup gayi... brush ke dar se!',
    problem: 'Ria hides under the blanket to avoid brushing her teeth',
    lesson: 'Khel banao, zidd khud chali jaati hai',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria refuses: "Brush nahi!" Mumma picks up Cuty's brush: "Pehle Cuty ki teeth clean karte hain."
Twist: Tiny circles on Cuty's toy teeth. Ria watches, then grabs a brush. "Cuty ke teeth clean, ab mere!"
Resolution: Mumma helps guide Ria's hand through the last stubborn spot. Ria spits, grins at her sparkly smile.
Moral: Watching a friend get first makes the real thing feel less scary.
''',
    setting: 'Bathroom, toothbrushes lined up, mirror foggy',
    sceneDetail: 'Ria\'s toothbrush is missing one bristle',
    dialogue: '"Brush karlo, Ria. Jaldi karo, time lag gaya!"',
    mess: 'Cuty has the toothpaste and is squeezing it all over the sink',
    innerThought: 'The "just brush" part is never just brush.',
    endingBeat: 'All three toothbrushes in mouths, foam mustaches everywhere.',
    defaultCast: ['Ria', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h08',
    category: 'Relatable',
    cover: 'Broccoli? Bilkul Nahi!',
    opening: 'Plate aage aayi... aur Ria ne haath baandh liye.',
    problem: 'Ria refuses vegetables at the table',
    lesson: 'Khud banaya khaana, khud khaane ka mann',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Papa holds up broccoli: "Dekho, mini tree!" He takes a dinosaur bite first.
Twist: Then the real bite. Ria studies it. "Is tree ka taste kaisa?"
Resolution: She decides — one small bite, then another. Or: "Thoda sa, phir dil se."
Moral: A bite modeled first feels safe enough to try.
''',
    setting: 'Dining table, lunch plates half full, afternoon',
    sceneDetail: 'One broccoli floret has fallen onto the tablecloth',
    dialogue: '"Yeh mini tree khaane se pehle photo bhi khaate ho?"',
    mess: 'Ria makes a face but the broccoli doesn\'t disappear',
    innerThought: 'I\'ve tried everything except just eating it myself.',
    endingBeat: 'Ria picks it up with her fork, one bite, then asks for more.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h09',
    category: 'Relatable',
    cover: 'Half-Ready Hoon!',
    opening: 'Joote pehenlo... park jaana hai. Rio ne ulta laga diya.',
    problem: 'Ria wants to leave but Rio shoes are on wrong feet',
    lesson: 'Chhote galtiyan, saath mein theek ban jaati hain',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: "Shoes pehen lo, park jaana hai." Ria: "Main half-ready hoon!" Rio sits with one shoe on, one off.
Twist: Mumma: "Rio full-ready nahi, full-confused hai!" She kneels, points to toes.
Resolution: They fix both shoes together. Ria helps Rio tie his lace. "Partner ban gayi!"
Moral: Getting ready is faster when you help each other put things right.
''',
    setting: 'Front door, shoes scattered by the mat, park visible through the window',
    sceneDetail: 'Rio sitting with one shoe on, one off — the left is on the right foot',
    dialogue: '"Shoes pehen lo, park jaana hai." "Main half-ready hoon!"',
    mess: 'Rio wiggles his feet, shoes keep slipping off as Ria tries to help',
    innerThought: 'Getting ready is a team sport when laces fight back.',
    endingBeat: 'They fix both shoes together, Ria helps Rio tie his lace — "Partner ban gayi!"',
    defaultCast: ['Rio', 'Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // New built-in content ideas from Palak's marketing and character plan.
  HookIdea(
    id: 'pal01',
    category: 'Relatable',
    cover: 'Which Kid Is Yours?',
    opening: 'Ria = tofani, Rio = ziddi, Cuty = sleep lover.',
    problem: 'Parents want to recognise their child in a playful character style',
    lesson: 'Every child has a personality and every family sees themselves in it',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At the park, three swings — three personalities.
Slide 1 (Negotiator): Ria — "Mere saath 5 minute, phir Rio karega!" She bargains for extra turns.
Slide 2 (One-more-minute kid): Rio — "Ek aur slide, ek aur!" He protests every transition.
Slide 3 (Escape artist): Cuty — slides off, hides behind Mumma's leg, sneaks away mid-count.
Twist: Mumma gives each a match: Ria negotiates timing, Rio picks a goodbye song, Cuty gets a quiet corner.
Resolution: Three swings, three needs — and Mumma's voice stays calm through them all.
Moral: Your kid will sit in any of these seats. Which one is yours?
''',
    setting: 'Park with three swings, morning, Mumma watching from a bench',
    sceneDetail: 'Three swings moving at different speeds — one slow, one fast, one empty',
    dialogue: '"Mere saath 5 minute, phir Rio karega!" "Ek aur slide!"',
    mess: 'All three kids want to swing at once — Ria negotiates timing, Rio protests, Cuty sneaks off',
    innerThought: 'One child, three strategies — which one am I solving today.',
    endingBeat: 'Mumma gives each a match: Ria gets extra turns, Rio gets a goodbye song, Cuty gets a quiet corner.',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal02',
    category: 'Relatable',
    cover: '7 Things Every Toddler Does',
    opening: 'Says no, wants the same spoon, and suddenly needs Mumma.',
    problem: 'Parents need a humorous way to see their own daily chaos reflected back',
    lesson: 'The tiny behaviours are the funny little signs of childhood',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Slide 1 — Parent says: "Time to clean up!" Toddler hears: "Fun stopped forever."
Twist: Slide 2 — Parent says: "Just put the blocks in the box." Toddler hears: "I failed my life's work."
Resolution: Slide 3 — Parent: "You choose one more tower, then 2 minutes cleanup?" Toddler hears: "I get a say!"
Moral: Toddler subtitles are fiction — but what they actually hear matters more than what you said.
''',
    setting: 'Playroom floor, blocks scattered, toy bin nearby',
    sceneDetail: 'One block tower stands next to a crumpled tower that was just rebuilt',
    dialogue: '"Time to clean up!" "Just put the blocks in the box."',
    mess: 'All the blocks are spread across the room, child protests every cleanup word',
    innerThought: 'My words are heard exactly as they are said — not as I intended.',
    endingBeat: 'Child picks a goodbye song and sings it while putting blocks away.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal03',
    category: 'Relatable',
    cover: 'Three Kids, One No',
    opening: 'Ria protests, Rio refuses, Cuty quietly gives in.',
    problem: 'The same parent boundary can trigger three very different reactions',
    lesson: 'Kids react differently, but all of them need patience and clarity',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma: "Abhi chocolate nahi." Three reactions in three seconds.
Twist: Ria negotiates — "Bas ek piece, maine kal se diet shuru karungi!" Rio drops to the floor — "NO!" Cuty quietly munches a carrot.
Resolution: Mumma: "Carrot nahi? Theek hai." She hands Cuty a cheese cube. Ria gets a story, Rio gets a countdown hug.
Moral: One "no" can meet three different needs — see each before you solve.
''',
    setting: 'Kitchen counter after lunch, afternoon light',
    sceneDetail: 'Half-open chocolate bar on the counter, Cuty chewing a carrot',
    dialogue: 'Bas ek piece!',
    mess: 'Ria keeps negotiating ("diet shuru karungi"), Rio melts down',
    innerThought: 'Ek nahi toh teen, when will the chocolate negotiation end',
    endingBeat: 'Cuty trades cheese for raisin, Rio sees it and asks to share too',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen counter, afternoon light, half-open chocolate bar. Mom: "No chocolate." Ria: "Bas ek piece!" Rio immediately drops to floor, "NO!" Cuty quietly chews a carrot. Text on screen: "THREE KIDS, ONE NO" "RIA PROTESTS • RIO REFUSES • CUTY GIVES IN"

On-Screen Text:
- [0-3s]: "THREE KIDS, ONE NO 🍫❌"
- [3-7s]: "RIA PROTESTS • RIO REFUSES • CUTY GIVES IN"
- [7-10s]: "NEGOTIATION STARTS: 'BAS EK PIECE!' 📿"
- [10-14s]: "RIO DRAMATIC: 'MUJHE BHI!' 💧"
- [14-18s]: "CUTY TRADE SECRET 🤫"
- [18-20s]: "SHARE = TEAM SPORT ❤️"

Part 1 (0-10s): 3D Pixar style, 9:16. Mom at kitchen counter. Ria dramatically protests: "Bas ek piece!" Rio throws himself on the floor: "NO!" Cuty quietly chews carrot. Text: "THREE KIDS, ONE NO" "RIA PROTESTS • RIO REFUSES • CUTY GIVES IN".

Part 2 (10-20s): 3D Pixar style, 9:16. Mom gives Cuty a cheese cube. Cuty trades it for a raisin. Rio sees this, face falls. Text: "CUTY TRADE SECRET 🤫" then "SHARE = TEAM SPORT ❤️". Rio sniffles: "Mujhe bhi!" Mom: "Share karta hai toh tu bhi share karega na?"
Audio/Dialogue (Hinglish): Mom firm: "Chocolate nahi beta." Ria pleading: "Bas ek piece, I promise!" Rio melodramatic: "NO! Main nahi khana!" Cuty quietly: "Carrot khaa sakti hoon." Mom to Rio: "Tumhara turn kab hai?" Cuty trading: "Raisin? Cheese?" Rio realizing: "Oh... share karte ho na?"
    ''',
  ),

  HookIdea(
    id: 'pal05',
    category: 'Relatable',
    cover: 'Neend Ka Evidence',
    opening: 'Ria: "Mujhe neend nahi!" ... jab tak aankh band nahi hoti.',
    problem: 'Ria protests sleep loudly, then falls asleep mid-story',
    lesson: 'Protest ke baad bhi mamla sul jata hai',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria sits bolt upright mid-storybook on Mumma's lap, legs kicking. "Mujhe neend nahi!" She pats the pillow: "Thoda aur?"
Twist: Halfway through page two, her eyelids grow heavy. Mumma: "Evidence mil gaya." Ria snaps awake: "Main toh jaag rahi thi!"
Resolution: Mumma tucks the blanket around Ria's shoulders and keeps reading in a whisper. By page three Ria is breathing evenly, one hand still holding the page corner.
Moral:
''',
    setting: 'Living room couch, storybook on Mumma lap, dim lamp',
    sceneDetail: 'Half-read storybook, blanket half-draped, one hand holding the page corner',
    dialogue: 'Mujhe neend nahi!',
    mess: 'Ria keeps restarting the story from page one, refusing to stay still',
    innerThought: 'Agar main jaldi so jaoongi toh kal subah uthna padega, and I will anyway',
    endingBeat: 'Mumma tucks the blanket around just Ria shoulders, both half-asleep by page three',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal06',
    category: 'Relatable',
    cover: 'Ek Sock Gir Gaya!',
    opening: 'Socks missing, shirt reversed, bottle abandoned. Morning chaos.',
    problem: 'Morning routine creates scattered chaos across the house',
    lesson: 'Ek checklist, ek family banati hai',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Morning check: one sock by the couch, shirt inside-out, water bottle left on the chair.
Twist: Ria spots her own sock—"Mumma, maine hi girana diya!"—and laughs instead of crying.
Resolution: They make a "morning checklist" together: sock, shirt, bottle. Rio adds "smile" at the end.
Moral: Small things make big mornings — and finding your own lost sock feels like winning.
''',
    setting: 'Hallway by the door, morning, coats on hooks',
    sceneDetail: 'One sock on the couch cushion, shirt hanging inside-out on the chair',
    dialogue: '"Mumma, maine hi girana diya!"',
    mess: 'Morning chaos: sock here, shirt inverted, bottle forgotten on the table',
    innerThought: 'If I make the checklist, maybe tomorrow will be smoother.',
    endingBeat: 'They make a morning checklist together, Rio adds "smile" at the end.',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal07',
    category: 'Relatable',
    cover: 'Ready Captain!',
    opening: 'Ria: "Done!" Par hair clip wapas badal rahi hai.',
    problem: 'Ria is ready but keeps fussing over small details',
    lesson: 'Tumse pehle ready hone se matlab nahi, team chhod dena',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria: "Ready Captain!" — but she changes her hair clip three times: blue bow, pink bow, no bow.
Twist: Rio points at the clock: "Time khatam ho raha hai!" Cuty is still tying his shoes.
Resolution: Ria picks "no bow" and helps Cuty with his second shoe. "Jab tak sabke saath, tab tak team complete."
Moral: Being first ready doesn't mean you leave everyone behind.
''',
    setting: 'Front door, backpacks by the shoe rack, ready Captain badge on Ria\'s shirt',
    sceneDetail: 'Three hair clips on the counter — blue bow, pink bow, plain clip',
    dialogue: '"Ready Captain!" "Blue bow, pink bow, no bow."',
    mess: 'Ria changes her hair clip three times, time slipping away',
    innerThought: 'My team waits, and my shoes are still by the couch.',
    endingBeat: 'Ria picks no-bow and helps Cuty tie his second shoe.',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal08',
    category: 'Relatable',
    cover: 'Cuty\'s Nose',
    opening: 'Crumbs everywhere... Ria points at Rio.',
    problem: 'Crumbs on Cuty nose, Ria blames wrong suspect',
    lesson: 'Sabse pyaara baccha sabse zyada blame kamaati hai',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Crumbs on Cuty's nose. Ria: "Mumma, Mumma — koi ne cookies khaaye!" Points at Rio.
Twist: Mumma: "Let's check." Cuty's nose — cookie crumbs. Rio's mouth — clean.
Resolution: Ria: "Mujhe pata hai!" She wipes Cuty's nose with a tissue. "Innocent rabbit!"
Moral: The most obvious suspect is often the cutest.
''',
    setting: 'Living room floor, cookie crumbs on the rug',
    sceneDetail: 'Crumbs dotted across Cuty\'s black nose like confetti',
    dialogue: '"Mumma, Mummy — koi ne cookies khaaye!"',
    mess: 'Ria points at Rio, accusation in her voice, while Cuty licks his nose clean',
    innerThought: 'The most innocent-looking suspect always has the best poker face.',
    endingBeat: 'Ria wipes Cuty\'s nose with a tissue — "Innocent rabbit!"',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal10',
    category: 'Relatable',
    cover: 'Mumma Ne Kaha Tha!',
    opening: 'Mumma ne kaha — "Aaj jaldi sona hai."',
    problem: 'Children repeat the smallest things adults say — often at exactly the wrong moment',
    lesson: 'Small phrases stick; what we say becomes their inner voice',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma tells Ria at bedtime, "Aaj jaldi sona hai." Later that night, Ria tucks Teddy in and repeats Mumma's phrase: "Teddy, negotiation band."
Twist: Mumma, sitting nearby on the bed, tries not to laugh — she's heard every word.
Resolution: Ria whispers, "Mumma ne kaha tha!" and Mumma gives her a quiet hug.
Moral: Jo baatein hum dete hain, wohi din mein dobara sunai deti hain — par pyaar ke saath.
''',
    setting: 'Bedroom, bedtime, Teddy on the pillow',
    sceneDetail: 'Night light casting soft shadows, Ria tucking Teddy in',
    dialogue: '"Teddy, negotiation band."',
    mess: 'Ria repeats Mumma\'s exact phrase, not knowing she was overheard',
    innerThought: 'That phrase I said in frustration — she made it her own lullaby.',
    endingBeat: 'Ria whispers "Mumma ne kaha tha!" and Mumma gives her a quiet hug.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal11',
    category: 'Relatable',
    cover: 'At The Supermarket',
    opening: 'Ria wants everything, Rio wants the toy, Cuty is already ready to go home.',
    problem: 'Shopping turns into a mini-lesson in patience, negotiation and excitement',
    lesson: 'Every child brings a different energy into the same space',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At the supermarket, Mumma gives each a job — Ria: "Pick the yellow fruit." Rio: "Find the big box." Cuty: "Carry the list."
Twist: Ria comes back with a yellow choochoo train, Rio drags a giant cereal box twice his size, and Cuty "carries" the list by sitting on it.
Resolution: They all crack up — "Hamari shopping team badi achhi hai!" — and Ria trades the train for mangoes.
Moral: Give them a role, even if they misunderstand — the practical result is still teamwork.
''',
    setting: 'Supermarket aisle, evening, shopping cart half-full',
    sceneDetail: 'Ria with yellow mangoes, Rio dragging a cereal box, Cuty sitting on the list',
    dialogue: '"Ria, pick the yellow fruit." "Rio, find the big box." "Cuty, carry the list."',
    mess: 'Ria returns with a yellow train, Rio struggles with the giant box, Cuty "guards" the list',
    innerThought: 'They misunderstood the brief — but the teamwork is perfect anyway.',
    endingBeat: 'They laugh: "Hamari shopping team badi achhi hai!" — Ria trades the train for mangoes.',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal13',
    category: 'Struggle first',
    cover: 'Car Bhi Ghar Chalegi!',
    opening: 'Car ko bhi le jaane ka plan ban gaya.',
    problem: 'Child insists favorite toy must come along for outings',
    lesson: 'Buckle the toy into the trip, not the argument',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria wants the toy car to go on the road trip — "Car bhi ghar chalegi!"
Twist: "Seatbelt ka concept samajh aa gaya?" Mumma buckles the car into a backpack: "Tumhara travel bag, car ke saath!"
Resolution: Rio inspects the backpack — "Lock hai!" — and the car rides along, buckled and safe.
Moral: Two choices beat a fight — one for the car, one for the journey.
''',
    setting: 'Living room, packing for a road trip, suitcases open',
    sceneDetail: 'Ria\'s toy car buckled into a small backpack like a seatbelt',
    dialogue: '"Car bhi ghar chalegi!" "Seatbelt ka concept samajh aa gaya?"',
    mess: 'Ria clutches the toy car, refusing to let it stay behind',
    innerThought: 'Two choices beat a fight — one for the car, one for the journey.',
    endingBeat: 'Rio inspects the backpack — "Lock hai!" — and the car rides along, buckled.',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal14',
    category: 'Warm lesson',
    cover: 'Big Feelings, Little Problems',
    opening: 'To a child, a broken biscuit or a missing sock feels enormous.',
    problem: 'Little problems can feel huge when your child is overwhelmed',
    lesson: 'What seems small to us is often a big emotion to them',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria is crying over a torn drawing—"MERI drawing phaa gaya!"
Twist: Mumma kneels: "Yeh paper toh gaya, lekin yeh drawing tumhara saath nibhaati hai."
Resolution: They make a new drawing together — "Nayi shuruaat!" — and Ria's tears turn to giggles.
Moral: Big feelings over small things are real — and they deserve big love to match.
''',
    setting: 'Drawing table, morning, torn paper on the floor',
    sceneDetail: 'Half-torn drawing in Ria\'s hands, the other half still on the table',
    dialogue: '"MERI drawing phaa gaya!"',
    mess: 'Ria is crying, the torn paper fragment clutched in her fist',
    innerThought: 'This paper feels like it held the whole world together.',
    endingBeat: 'They make a new drawing together — "Nayi shuruaat!" — Ria\'s tears turn to giggles.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal15',
    category: 'Relatable',
    cover: 'Do Aur Do!',
    opening: 'Papa: "Do blocks aur, phir shoes." Rio: "Ab do aur do!"',
    problem: 'Toddler insists on more — more blocks, more time, more everything',
    lesson: 'One small bargain can turn "more" into "done"',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Papa: "Do blocks aur, phir shoes." Rio: "Ab do aur do!"
Twist: Papa holds firm: "Ek bite dal, phir do-minute phone." Rio stomps but the timer starts.
Resolution: They settle at "Ek bite dal, phir do-minute phone." Rio gets the timer and phone, then takes his bite of dal — everyone wins a high-five.
Moral: Ek chhota sa bargain sabke liye badi khushiyon ka source.
''',
    setting: 'Living room floor, blocks scattered, Papa kneeling with a shoe',
    sceneDetail: 'One block tower stands next to Rio\'s shoe, both in progress',
    dialogue: '"Do blocks aur, phir shoes." "Ab do aur do!"',
    mess: 'Rio stomps, demanding more — more blocks, more time, more everything',
    innerThought: 'Ek chhota sa bargain sabke liye badi khushiyon ka source.',
    endingBeat: 'They settle at "Ek bite dal, phir do-minute phone" — Rio gets the timer and phone, everyone wins.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal16',
    category: 'Relatable',
    cover: 'No, Mine, Why!',
    opening: 'Rio kehte hain: No! Mine! Why!',
    problem: 'One word repeated drives parents to the edge of sanity',
    lesson: 'Lean into the word — count it, echo it, then watch it lose its power',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria: "Mujhe bhi!" Rio: "No!" He grabs the ball. "Mine!" Ria: "Why!" — not even asking, just echo.
Twist: Mumma pretends to be a broken record: "No, Mine, Why" — three times, flat. Both kids stop. Ria: "Arey, that was me!"
Resolution: Rio hands Cuty the ball: "Tumhara bhi." Cuty drops it immediately. Both kids stare. "Oops."
Moral:
''',
    setting: 'Living room floor, toy ball between them',
    sceneDetail: "Both kids' hands reaching for the same ball, Mumma half-hidden behind the couch",
    dialogue: 'No! Mine! Why!',
    mess: 'The three words repeat — louder, faster, until both kids are crying',
    innerThought: 'Maine kya bigaara, when did my words become the only thing they hear',
    endingBeat: 'Rio hands the ball to Cuty, Cuty drops it, both kids say "oops" at the same time',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, one ball between Ria, Rio, and Cuty. The three words echo like a broken record: "No! Mine! Why!" Each repeat faster, louder, both kids crying. Mumma (half-hidden behind couch) pretends to be a malfunctioning robot. Text on screen: "BROKEN RECORD MODE 🤖" "NO • MINE • WHY × 3"

On-Screen Text:
- [0-3s]: "BROKEN RECORD MODE 🤖"
- [3-8s]: "NO • MINE • WHY × 3 🔄"
- [8-13s]: "PARENT SANITY: CRITICAL ⚠️"
- [13-16s]: "ECHO STRATEGY: DE-ESCALATE 💡"
- [16-20s]: "DROPPED BALL SYNDROME 🏈😂"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria and Rio fighting over ball. "No! Mine! Why!" Repeats louder, faster, both crying. Mumma steps out from behind couch like a broken robot: "No. Mine. Why." Flat, robotic voice. Text: "BROKEN RECORD MODE 🤖" "NO • MINE • WHY × 3". Both kids stop mid-cry. Ria: "Arey, that was me!"

Part 2 (10-20s): 3D Pixar style, 9:19. Rio hands ball to Cuty: "Tumhara bhi." Cuty drops it immediately. Both stare at the floor. "Oops." at the same time. Text: "PARENT SANITY: CRITICAL ⚠️" "ECHO STRATEGY" "DROPPED BALL SYNDROME 🏈". Both kids giggling now.

Audio/Dialogue (Hinglish): Ria echoing: "Mujhe bhi!" Rio grabbing ball: "No! Mine!" Ria: "Why!" Mumma robot voice: "No. Mine. Why." (3x flat) Ria: "Arey, that was me!" Rio (surprised): "Haan... thoda maza aa gaya!" Cuty dropping ball: "Oops." Both together: "Oops."
    ''',
  ),

  HookIdea(
    id: 'pal17',
    category: 'Warm lesson',
    cover: 'Cuty Stays Close',
    opening: 'Ria neeche baithi... Cuty saath bhi baithi.',
    problem: 'Child sulks after injury; comfort comes from quiet presence',
    lesson: 'Cuddle, no lecture — presence over words',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria has a scraped knee and sits on the couch, sulking.
Twist: Cuty sits beside her, nudges a fresh sheet of paper over. "Napkins please," Ria whispers.
Resolution: They wrap the knee together — no lectures, no "it's okay" speeches. Just quiet presence.
Moral: Sometimes the best help is sitting close with a clean sheet.
''',
    setting: 'Living room floor, Cuty beside Ria on the couch',
    sceneDetail: 'One clean napkin on the coffee table, Ria\'s scraped knee visible',
    dialogue: '"Napkins please," Ria whispers.',
    mess: 'Ria refuses to look at the scrape, keeps pulling her sleeve down',
    innerThought: 'The scrape hurts more when she thinks about it.',
    endingBeat: 'They wrap the knee together, Cuty licks the napkin clean.',
    defaultCast: ['Ria', 'Cuty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal18',
    category: 'Relatable',
    cover: 'Brush vs Shoes!',
    opening: 'Brush kahaan? Shoes kahan? Sab kuchh ulta ho gaya.',
    problem: 'Cuty brush and Rio shoes get swapped in the morning',
    lesson: 'Misplaced items lead to funny mix-ups',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cuty's brush is missing — "Cuty brush kahaan hai?" — but it's not under the bed.
Twist: Rio's shoes are missing too — he's been wearing Cuty's brush like a hairbrush in his hair.
Resolution: "Ab dono milenge!" — brush goes back to Cuty, shoes to Rio. Everyone laughs at the mix-up.
Moral: Lost things are usually found in the wrong place — and the wrong place is often hilarious.
''',
    setting: 'Bathroom, morning, toothbrushes in the holder, Cuty\'s brush missing',
    sceneDetail: 'Rio with Cuty\'s brush stuck in his hair like a hairbrush',
    dialogue: '"Cuty brush kahaan hai?"',
    mess: 'Cuty searches under the bed, Rio refuses to give back the brush from his hair',
    innerThought: 'He thinks it makes him look fancy.',
    endingBeat: 'They trade back — brush to Cuty, shoes to Rio — and everyone laughs at the mix-up.',
    defaultCast: ['Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'pal19',
    category: 'Relatable',
    cover: 'Mumma Says This Daily',
    opening: 'Put your shoes on, stop running, where is your bottle, and come here.',
    problem: 'Parents repeat the same phrases each day because the day repeats itself',
    lesson: 'Even the hard repeated words are part of the family rhythm',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Subah ki daud. Mumma: "Joote pehno! Daudo mat! Bottle kahan hai? Idhar aao!" Rio sab sunta rehta hai.
Twist: Rio Cuty ko pakadke bilkul Mumma ki tarah bolta hai: "Joote pehno! Daudo mat! Bottle kahan hai? Idhar aao!"
Resolution: Mumma jam jaati hai, phir hans padti hai: "Main itna bolti hoon?" Rio: "Haan, roz."
Moral: Bachche wahi bolte hain jo roz sunte hain.
''',
    setting: 'Morning living room, backpacks by the door',
    sceneDetail: 'Rio\'s hair is sticking up in three different directions',
    dialogue: '"Joote pehno! Daudo mat! Bottle kahan hai? Idhar aao!"',
    mess: 'Rio repeats every command back but backwards, everyone laughs',
    innerThought: 'He mimics me to delay, and it works every time.',
    endingBeat: 'Rio finally puts shoes on correctly, grinning at his own echo.',
    defaultCast: ['Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Morning living room, backpacks scattered by door, sunlight streaming in. Mumma (yellow kurti, top bun) rushing: "Joote pehno! Daudo mat! Bottle kahan hai? Idhar aao!" Every instruction echoes back from Rio (pajamas, hair sticking up in 3 directions). Text on screen: "MORNING MADNESS 📚" "MUMMA COMMAND CENTER"

On-Screen Text:
- [0-3s]: "MORNING MADNESS 📚"
- [3-8s]: "MUMMA: COMMAND CENTER 🎮"
- [8-14s]: "RIO: PARROT MODE 🦜"
- [14-17s]: "MIMIC = DELAY TACTIC 💡"
- [17-20s]: "MISSION: BACKPACK READY 🎒✅"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma rushing around getting ready, shouting instructions: "Joote pehno! Daudo mat! Bottle kahan hai?" Rio mimics every instruction back perfectly, causing everyone to pause. Text: "MORNING MADNESS 📚" "MUMMA: COMMAND CENTER" "RIO: PARROT MODE 🦜". Ria rolls eyes, Cuty hides behind sofa.

Part 2 (10-20s): 3D Pixar style, 9:19. Mumma stops, looks at Rio. "Parrot mode band karo... thoda seriously bhi baat karo." Rio: "Haan Mummy!" puts shoes on properly. Text: "MIMIC = DELAY TACTIC 💡" "SHOE CHECK ✅" "MISSION: BACKPACK READY 🎒✅". Everyone laughs, backpacks grabbed, ready to go.

Audio/Dialogue (Hinglish): Mumma rushing: "Joote pehno! Daudo mat! Bottle kahan hai? Idhar aao!" Rio echo: "Joote pehno! Daudo mat! Bottle kahan hai!" Mumma turning: "Rio, parrot band karo!" Rio: "Haan, serious mode!" Mumma laughing: "Mission accomplished, baby."
    ''',
  ),

  HookIdea(
    id: 'pal20',
    category: 'Relatable',
    cover: 'Notice the Bag!',
    opening: 'Mumma neeche gir gaya bag, Ria ne notice kiya.',
    problem: 'Children see when parents are tired — and can offer small help without being asked',
    lesson: 'A small gesture needs no speech; noticing is already love in action',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: true,
    storyDetail: '''
Story: Mumma comes home tired, bag on floor. Ria notices, picks up bag, hands it over. Small believable gesture.
Twist: Mumma starts to take the bag back — "Beta, I've got it."
Worse: Ria insists: "Tum bahut thak gayi ho. Main help kar sakta hun."
Resolution: Mumma lets Ria help. They sit together — Mumma with her tea, Ria with a small drawing. No words about growing up; just two people being quiet.
Ending line: "Mumma: Shukriya beta. Ria: Tumhara saath hi toh maza aata hai."
Moral: Sometimes noticing is the gift.
''',
    setting: 'Car, stuck in traffic, afternoon sun slanting',
    sceneDetail: 'One street performer\'s balloon is half-deflated',
    dialogue: '"Mumma, woh balloon wala khel raha hai!"',
    mess: 'Ria points at everything outside for twenty minutes straight',
    innerThought: 'I left the tablet in my other bag.',
    endingBeat: 'Ria spots her own reflection in the window and points at herself.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // Struggle first: open on the moment it goes wrong.
  HookIdea(
    id: 'h10',
    category: 'Struggle first',
    cover: '1 Galti, Bada Mess!',
    opening: 'Rio ke haath se saare rang gir gaye...',
    problem: 'Rio spills paint everywhere by accident',
    lesson: 'Galti pe gussa nahi, saath mein saaf karo',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Blue paint tips onto a perfectly clean white table — "Arre, blue paint!" Napkin smears it wider.
Twist: Mumma moves the paint cup away, gives a damp cloth. "Table ko blue dress chahiye thi."
Resolution: Rio scrubs, watches the blue disappear. Table is clean again, but Rio is streaked with blue.
Moral: A spill can look huge — but a little help makes it manageable.
''',
    setting: 'Art table, morning, paint cups lined up',
    sceneDetail: 'Blue paint tips onto a clean white tablecloth, napkin smears it wider',
    dialogue: '"Arre, blue paint!"',
    mess: 'Blue paint spreads across the table, Rio watches wide-eyed',
    innerThought: 'How do you contain a flood with one napkin?',
    endingBeat: 'Rio scrubs, watches blue disappear, ends up streaked with blue himself.',
    defaultCast: ['Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h12',
    category: 'Struggle first',
    cover: 'Mumma Bhi Thak Gayi!',
    opening: 'Mumma: "Bas 5 minute rest." Lies down. Ria tucks her in.',
    problem: 'Mumma needs rest but asks Ria to respect it',
    lesson: 'Thoda sa pause, poori family ke liye',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma sits down — "Bas five minute rest." She lies on the floor with a cushion.
Twist: Ria tucks a blanket over her: "Ab paani nahi maangna, okay?" Mumma: "Main itni bhi dramatic hoon?"
Resolution: Ria: "Mumma, aap hi toh ho." She brings a small cup of water and sits quietly beside her.
Moral: When grown-ups rest, children learn that love doesn't always mean fixing — sometimes just being there.
''',
    setting: 'Living room floor, afternoon, cushions scattered',
    sceneDetail: 'One cushion has a small tear on the seam',
    dialogue: '"Ria, pehle cuddle ya paani?"',
    mess: 'Ria watches Mumma lie down, unsure if she should disturb her',
    innerThought: 'If I say one word right now, I become part of it.',
    endingBeat: 'Ria sits beside her, brings a small cup of water, sits quietly.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h13',
    category: 'Struggle first',
    cover: 'Pehle Cuddle Ya Paani!',
    opening: 'Tower gir gaya... Mumma crouch karti hain.',
    problem: 'Child upset after tower falls; needs feeling-first response',
    lesson: 'Body language se pehle baat karo',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria's block tower gets knocked — pieces scatter. Mumma crouches down: "Pehle cuddle ya paani?"
Twist: Ria's body language shifts — shoulders drop, she leans toward Mumma. "Cuddle."
Resolution: One hug, then they rebuild together. "Tower phir se lagega!" Cunty the bunny hops over to sniff a block.
Moral: Meeting feelings first makes solutions stick.
''',
    setting: 'Living room floor, blocks scattered after the tower fell',
    sceneDetail: 'Block pieces scattered, one lone block standing beside Cunty the bunny',
    dialogue: '"Pehle cuddle ya paani?"',
    mess: 'Pieces of the tower spread everywhere, Ria looks up with tear-streaked face',
    innerThought: 'Feelings first, then solutions. I can do this.',
    endingBeat: 'One hug, then they rebuild together — "Tower phir se lagega!"',
    defaultCast: ['Ria', 'Mumma', 'Cunty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h14',
    category: 'Struggle first',
    cover: 'Tod Diya!',
    opening: 'Car ke do tukde... aur dono ek doosre ko blame kar rahe hain.',
    problem: 'The shared toy breaks and both children blame each other',
    lesson: 'Kaun jeeta nahi, saath mein kaise theek karein',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Both grab the red car — "Mera pehle!" They argue over whose lap it is for.
Twist: Mumma: "Rio one lap, Ria one lap." They make paper tickets — Rio gets #1, Ria gets #2.
Resolution: Cuty sits as ticket checker. One minute each, then together. "Dono car, do laps!"
Ending line: "Next time? Ek ticket, teen dots!"
Moral: Tickets turn fights into fair turns — everyone wins a lap.
''',
    setting: 'Living room floor, red toy car between them',
    sceneDetail: 'Paper ticket #1 in Rio\'s hand, ticket #2 in Ria\'s hand, Cuty sits beside the car',
    dialogue: '"Mera pehle!" — "Toh main aakhir mein bhi thi!"',
    mess: 'Both grab the red car, arguing whose lap it is for',
    innerThought: 'A ticket system — will it actually work?',
    endingBeat: 'Paper tickets, one minute each, then together — "Dono car, do laps!"',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // Surprising: says the opposite of what a parent expects, then shows it.
  HookIdea(
    id: 'h15',
    category: 'Surprising',
    cover: 'Music Sudden Ruko!',
    opening: 'Music bandh ho gayi... Rio freezz!',
    problem: 'Music suddenly stops mid-play, and Rio freezes or protests',
    lesson: 'Name the change, then offer the next step',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio is dancing to his favorite song when the music suddenly stops mid-beat. Rio freezes, eyes wide.
Twist: Mumma names the change: "Music bandh ho gayi. Ab kya karein?" She offers: "Ek minute aur dance karo, ya turant room saaf karo?"
Resolution: Rio chooses one more minute of dance, then they clean up the toys together. Mumma restarts soft music.
Ending line: Rio: "Next time phone use karoongi!" Mumma: "Haan, volume button dikha."
Moral: Badlaav ka intezaar karo, phir agla kadam lagao.
''',
    setting: 'Living room, afternoon, song playing from phone',
    sceneDetail: 'One earbud is missing from the pair',
    dialogue: '"Music bandh ho gayi. Ab kya karein?"',
    mess: 'Rio freezes, then says "one more minute" instead of crying',
    innerThought: 'This transition is harder than I thought.',
    endingBeat: 'They clean up toys together, soft music restarts.',
    defaultCast: ['Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h16',
    category: 'Surprising',
    cover: 'Dabba Ban Gaya Rocket!',
    opening: 'Itne saare khilone... aur Rio ko chahiye khaali dabba?',
    problem: 'Expensive toys are ignored; an empty box becomes a spaceship',
    lesson: 'Kam khilone, zyada kalpana',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Papa ke liye cover aaya hai. Rio ka naya robot toy bhi aaya hai. Rio robot ko dekhta bhi nahi aur khaali dabbe mein ghus jaata hai.
Twist: Papa dabba uthaane aate hain: "Ye kabaad mein jayega." Rio: "Ye mera rocket hai!"
Resolution: Papa robot ko dabbe mein bitha dete hain: "Ye astronaut hai." Dono ulti ginti karte hain: "5, 4, 3, 2, 1… chalo!"
Moral: Dabba hi kaafi hai.
''',
    setting: 'Kitchen, morning, lunch boxes on the counter',
    sceneDetail: 'One dabba is blue, the other is red — swapped by accident',
    dialogue: '"Papa ke liye cover aaya. Rio ka naya robot bhi aaya."',
    mess: 'Rio ignores the robot and crawls into the empty box',
    innerThought: 'The box is bigger than he is.',
    endingBeat: 'They count down together, "5, 4, 3, 2, 1... chalo!"',
    defaultCast: ['Rio', 'Robot', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h17',
    category: 'Surprising',
    cover: 'Bijli Band Ho Gayi!',
    opening: 'Light flicker, fan ruka. Ria: "Bijli band ho jaye!"',
    problem: 'Power cuts out suddenly and Ria is startled',
    lesson: 'Naam dekar dar ko chhota karna',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Light flickers, fan cuts out mid-hum. Ria tugs Mumma's hand: "Bijli ko bolo band ho jaye!"
Twist: Mumma kneels: "Thumbs up if you're worried. Bijli khel rahi thi—ab rest karegi."
Resolution: They sit in the quiet. Ria discovers she can hear her own heartbeat. "Thump-thump!" "It means you're safe."
Moral: Naming the noise makes the fear small enough to hold.
''',
    setting: 'Bedroom, bedtime, night light casting soft shadows',
    sceneDetail: 'One sock is missing, the other is paired on the radiator',
    dialogue: '"Bijli band ho gayi! Ab kya karein?"',
    mess: 'Power cuts at bedtime, Rio is afraid of the dark',
    innerThought: 'I should have checked the inverter earlier.',
    endingBeat: 'They sit in the quiet, Rio hears his own heartbeat.',
    defaultCast: ['Rio', 'Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h18',
    category: 'Surprising',
    cover: 'Blocks Box Mein!',
    opening: 'Rio ne saare blocks phailaye... Mumma ne name dia.',
    problem: 'Rio dumps blocks; Mumma names the cleanup action',
    lesson: 'Specific praise builds confidence',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio dumps a box of blocks everywhere. Mumma points: "Tumne saare blocks box mein rakhe—thank you!"
Twist: Rio beams, then spots one block hiding behind the couch. "Mummy, yeh bhi!"
Resolution: They put the last block in together. Papa claps. "Box full, heart full."
Moral: Cleaning up becomes a team win when the praise names what they did.
''',
    setting: 'Living room floor, box of blocks half-empty, pieces everywhere',
    sceneDetail: 'One block hiding behind the couch, Mumma pointing at it',
    dialogue: '"Tumne saare blocks box mein rakhe—thank you!"',
    mess: 'Rio dumps the box of blocks everywhere, then beams when praised for picking up',
    innerThought: 'The praise named what they did — not just "good job".',
    endingBeat: 'Papa claps: "Box full, heart full." Rio grins at the empty box.',
    defaultCast: ['Rio', 'Mumma', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h19',
    category: 'Surprising',
    cover: 'Bhaago Mat? Dheere Chalo!',
    opening: 'Mumma ne "mat bhaago" bola... Rio aur tez bhaaga!',
    problem: 'A child ignores "don\'t" but follows a clear "do"',
    lesson: 'Kya nahi karna, nahi — kya karna hai, woh batao',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Parking mein Mumma: "Rio, mat bhaago!" Rio aur tez bhaagta hai.
Twist: Mumma daud ke pakadti hai aur ab alag bolti hai: "Rio, meri ungli pakdo." Rio ruk jaata hai: "Kyun?"
Resolution: "Gaadi aati hai. Ungli pakdo, hum dono saath cross karenge." Rio ungli kas ke pakad leta hai. Dono dhire dhire chalte hain.
Moral: "Mat" nahi, "ungli pakdo".
''',
    setting: 'Society parking, afternoon, cars entering',
    sceneDetail: 'One red car stops at the line, others pass',
    dialogue: '"Rio, meri ungli pakho."',
    mess: 'Rio starts to run, then stops when he feels Mumma\'s hand',
    innerThought: 'He\'s faster than me, but safer with me.',
    endingBeat: 'Both cross the road together, hand in hand.',
    defaultCast: ['Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Society parking lot, afternoon, red car stopped at crossing line. Rio (yellow sundress, pigtails, holding Mumma's hand) tugs toward the road. "Rio, meri ungli pakho!" Rio hesitates, looks back, grabs her hand. Text on screen: "PAHLI UNGli 🎵" "MAT BHAAGO vs UNGULI PAKHO"

On-Screen Text:
- [0-3s]: "ROAD SAFETY KI LINE 🎵"
- [3-7s]: "MAT BHAAGO ❌ → UNGULI PAKHO ✅"
- [7-12s]: "HAND HOLD TECHNIQUE 💪"
- [12-16s]: "SMALL HANDS, BIG SAFETY 🌟"
- [16-20s]: "CROSS TOGETHER, ALWAYS 🤝"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio at parking lot crossing, tugging toward road. Cars rushing past. Text: "ROAD SAFETY KI LINE 🎵" "MAT BHAGA ❌ → UNGULI PAKHO ✅". Rio: "Rio, meri ungli pakho!" Rio stops, looks back, takes her hand. Comedic tension with fast cars approaching.

Part 2 (10-20s): 3D Pixar style, 9:19. Both walk slowly, hand in hand, red car waiting. Text: "HAND HOLD TECHNIQUE 💪" "SMALL HANDS, BIG SAFETY 🌟" "CROSS TOGETHER, ALWAYS 🤝". Rio: "Theek hai, main tumhari saath hoon." Mumma: "Haan, hum dono milke teerahon."

Audio/Dialogue (Hinglish): Rio urgent: "Rio, meri ungli pakho!" Mumma hesitant: "Par thoda maza aa raha tha..." Rio: "Ruk jao beta, ek second." Rio reassuring: "Main tumhe saaf pakad hoon gi." Mumma: "Haan, chalo... saath milkar." Both crossing: "Ek dusre ki ungli pakad ke chal rahe hain!"
    ''',
  ),


  // Warm lesson: gentle stories that end on something a parent wants to keep.
  HookIdea(
    id: 'h20',
    category: 'Warm lesson',
    cover: 'Pyaar Bhi, Rule Bhi',
    opening: 'Rio ne phir se rule toda... par Mumma ne chillaaya nahi.',
    problem: 'Holding a boundary kindly instead of giving in or shouting',
    lesson: 'Pyaar ke saath rule, bachcha safe mehsoos karta hai',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio takes cookie from the jar again—"Mummy, maine bas ek hi liya tha!"
Twist: Instead of shouting, Mumma kneels down—"Haan beta, tumne kara. Par main tumhe pyar karti hoon."
Resolution: Rio hugs her—"Next time I'll ask pehle!"—and puts the cookie back in the jar.
Ending line: "Phir se promise, Mummy?" "Haan, phir se promise."
Moral: Pyaar ke saath rule set karna, bachcha safe mehsoos karta hai.
''',
    setting: 'Kitchen counter, morning, cookie jar on the table',
    sceneDetail: 'Rio with cookie in hand, Mumma watching from the sink',
    dialogue: '"Haan beta, tumne kara. Par main tumhe pyar karti hoon."',
    mess: 'Rio looks guilty, cookie halfway to his mouth, Mumma kneeling down',
    innerThought: 'A boundary held with love — not a shout, not a give-in.',
    endingBeat: 'Rio puts the cookie back in the jar: "Next time I\'ll ask pehle!"',
    defaultCast: ['Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h21',
    category: 'Warm lesson',
    cover: 'Bag On Floor!',
    opening: 'Mumma ke saath bag gir gaya, Ria ne turant pick up kiya.',
    problem: 'Ria sees Mumma tired and picks up the bag from the floor',
    lesson: 'A child noticing and helping without being asked',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria notices Mumma tired, picks up bag from floor and hands it.
Twist: Mumma starts to refuse — "Maine kaha tha, main saambhaa lunga."
Resolution: Ria: "Tum itni thak gayi ho!" Mumma lets her help, ruffles her hair.
Ending line: "Mumma: Shukriya beta. Ria: Tumhara saath hi toh maza aata hai."
Moral: Children see tiredness before we admit it — and small hands can still hold a big bag.
''',
    setting: 'Living room floor, Mumma slumped on the couch, bag beside her',
    sceneDetail: 'Ria standing, looking from the bag to Mumma\'s tired face',
    dialogue: '"Tum itni thak gayi ho!"',
    mess: 'Mumma starts to take the bag back — "Maine kaha tha, main saambhaa lunga."',
    innerThought: 'She\'s been carrying it all day. Let me help.',
    endingBeat: 'Ria hands it over: "Mere saath chalo, main saambhal ke rakhti hoon."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // Milestone posts: complete concepts for the 100th Instagram post.
  HookIdea(
    id: 'p05',
    category: 'Page & milestone',
    cover: 'New Here?',
    opening: '1-4 saal ke bachchon ke liye screen-free ideas.',
    problem: 'New visitors need a 30-second hook that explains the whole page',
    lesson: 'Box = car = house — one toy, infinite play',
    postFormat: 'Reel / Pinned intro',
    strategy: 'Milestone + brand introduction + character introduction + discovery. Use a 25-35 second reel with Ria, Rio and Cuty, then test two hooks as Trial Reels: 100 POSTS ❤️ and Meet Our Little World 👀.',
    caption: '100 posts. ❤️\n\nWhat started as little ideas slowly became our little world — Ria, Rio, Cuty and so many tiny stories, laughs and lessons. 🌸💙🐰\n\nThank you for being here.\n\nLittle Stories. Big Lessons. 🌱\n\nAre you Team Ria, Team Rio or Team Cuty? 👇',
    pinnedComment: 'Okay, important question 😂👇\n🌸 Ria = Tofani\n💙 Rio = Ziddi\n🐰 Cuty = Sleep Lover\nWhich one is most like your little one?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: New here? 1-4 saal ke bachchon ke liye screen-free play ideas, tiny stories aur everyday parenting moments.
Twist: Ria wants the box, Rio wants the lid, Cuty wants the packing peanuts. Mumma: "Sabko ek minute."
Resolution: They discover the box becomes a car, a house, a cave — and three imaginations fill it.
Moral: The best toy costs nothing and takes up no space.
''',
    setting: '',
    sceneDetail: '',
    dialogue: '',
    mess: '',
    innerThought: '',
    endingBeat: '',
    defaultCast: [],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'p07',
    category: 'Page & milestone',
    cover: 'Aapke Ghar Kaun Hai?',
    opening: 'Ria negotiates, Rio says NO, Cuty quietly eats everything.',
    problem: 'Non-followers need a quick intro to the three characters and their distinct reactions',
    lesson: 'Meet the negotiator, the no-expert, the silent observer',
    postFormat: 'Reel / Discovery',
    strategy: 'Use the funniest version for discovery. Ria claims credit, Rio argues, Cuty keeps sleeping, and the final card reveals POST #100 🎉.',
    caption: 'Who made it to Post #100? 😂\n\nRia says it was her. Rio says NO. Cuty is sleeping through the celebration.\n\nStill causing trouble, one little story at a time. ❤️',
    pinnedComment: 'Who is most like your little one: Tofani Ria, Ziddi Rio or sleepy Cuty? 😂',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: "Aapke ghar kaun hai?" Ria is the negotiator — "Ek aur slide, phir packup!"
Twist: Rio is the "NO!" expert — "Bahar nahi jaana!" Floor meltdown. Cuty just observes, chewing a crumb.
Resolution: Mumma gives Ria a countdown, offers Rio a goodbye sticker, and lets Cuty finish his crumb. "Tum sab ke saath."
Moral: Three kids, three reactions — one family solution fits all.
''',
    setting: '',
    sceneDetail: '',
    dialogue: '',
    mess: '',
    innerThought: '',
    endingBeat: '',
    defaultCast: [],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'p08',
    category: 'Page & milestone',
    cover: 'Naya Drama Har Din!',
    opening: 'Screen-free play, short stories, everyday learning for ages 1-4.',
    problem: 'New followers need a clear pinned introduction to the page promise',
    lesson: 'Problem + playful solution = every reel',
    postFormat: 'Reel / Pinned brand introduction',
    strategy: 'Pin this after Post 100. Introduce each character in one quick beat, then show learning, masti, family and everyday childhood.',
    caption: 'Welcome to our little world. 🌸💙🐰\n\nRia is Tofani, Rio is Ziddi, and Cuty is our sleep lover. Together they bring little stories, little lessons and lots of masti.\n\nFun Learning With Palak ❤️',
    pinnedComment: 'Which one are you: Team Ria, Team Rio or Team Cuty? 👇',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: "Toddler ke saath roz naya drama?" That's the page promise in one line.
Twist: Ria tries the "no" button, Rio tests boundaries, Cuty naps through it all — and Mumma stays calm.
Resolution: Problem + playful solution. Screen-free play, short stories, everyday learning for ages 1-4.
Moral: Tiny moments, big lessons — and every day brings a new reel.
''',
    setting: '',
    sceneDetail: '',
    dialogue: '',
    mess: '',
    innerThought: '',
    endingBeat: '',
    defaultCast: [],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // Page posts: need your own footage, so the app lists them but cannot build them.
  HookIdea(
    id: 'p03',
    category: 'Page & milestone',
    cover: 'Ek Reel Kaise Banti Hai',
    opening: '30 second ki ek kahani ke peeche kitna kaam hai...',
    problem: 'Behind the scenes of making one story',
    lesson: 'Shows the care that goes into every story',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: false,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '',
    setting: '',
    sceneDetail: '',
    dialogue: '',
    mess: '',
    innerThought: '',
    endingBeat: '',
    defaultCast: [],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'p04',
    category: 'Page & milestone',
    cover: 'Jab Humne Shuru Kiya',
    opening: 'Pehli kahani post ki thi... pata nahi tha koi dekhega bhi.',
    problem: 'How the page started',
    lesson: 'Honest start builds trust',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: false,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '',
    setting: '',
    sceneDetail: '',
    dialogue: '',
    mess: '',
    innerThought: '',
    endingBeat: '',
    defaultCast: [],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // Navratri: Problem → Jugaad → Result → Moral.
  HookIdea(
    id: 'navratri-garba-ghar',
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
    custom: false,
    archived: true,
    storyDetail: '''
Story: Ria is dancing happily at Garba, but when Mumma says it's time to leave, she protests—"Nahi, aur ghoomna hai!"
Twist: Ria spots other parents also packing up their kids—"Dekho, sab bachche yahan se jaa rahe hain!"
Resolution: Mumma gives Ria a "Garba star" sticker and lets her put her tiny bangles in her pocket to keep for home—"Kal phir milenge!"
Moral: One more song, then it's time to go—good-byes feel easier with a small promise.
''',
    setting: 'Living room, evening, fairy lights strung',
    sceneDetail: 'One chaniya choli is missing a mirror piece',
    dialogue: '"Ria, thoda sa ghoom lo — ghoonghat yahan tak!"',
    mess: 'Ria trips on the dupatta but keeps dancing',
    innerThought: 'I forgot to tie the dupatta properly.',
    endingBeat: 'Ria adjusts it herself, continues dancing without stopping.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'navratri-bachcha-roye',
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
    custom: false,
    archived: true,
    storyDetail: '''
Story: Ria and Rio are excited for Garba, but the loud dhol and flashing lights make Cuty cover her ears and cry.
Twist: Mumma moves the kids to the quiet corner where Daadi is sitting—"Yahan se bhi Garba dikhai dega!"
Resolution: Daadi teaches Cuty to clap along to a softer beat, and soon Cuty is smiling and joining in her own way.
Moral: Every child celebrates differently—finding their comfort rhythm is its own kind of joy.
''',
    setting: 'Bedroom, bedtime, Garba outfit laid out',
    sceneDetail: 'One bangle is cracked from yesterday\'s play',
    dialogue: '"Ria, tum itni si baat pe ro rahi ho!"',
    mess: 'Ria cries over not getting the "good" bangle',
    innerThought: 'She has seven other bangles. This is about the one.',
    endingBeat: 'Daadi ties the cracked bangle, "this one held prayers.",',
    defaultCast: ['Ria', 'Mumma', 'Daadi'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'navratri-junk-food',
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
    custom: false,
    archived: true,
    storyDetail: '''
Story: Ria is ready for Garba but keeps asking for chips and sweets, saying "Mummy, bhookh lagi hai!"
Twist: Mumma offers the healthy snack box she packed—"Pehle yeh khao, phir Garba!"—but Ria still wants the chips.
Resolution: Mumma lets Ria choose one small sweet after the first round of Garba—balancing treat and fun.
Moral: Hunger at parties is often excitement—redirect with healthy fuel, then a small treat.
''',
    setting: 'Society compound, afternoon snack time',
    sceneDetail: 'One jalebi is half-eaten, the other whole',
    dialogue: '"Mumma, ek aur de dijiye!"',
    mess: 'Rio finishes his jalebi, points at Ria\'s untouched one',
    innerThought: 'I said one. He will ask for ten.',
    endingBeat: 'Rio offers half, Ria says "no thank you" and means it.',
    defaultCast: ['Ria', 'Rio'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'navratri-late-night',
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
    custom: false,
    archived: true,
    storyDetail: '''
Story: It's 10 PM and Ria is enjoying Garba, but suddenly she yawns and says, "Mummy, main thak gayi hoon."
Twist: Mumma checks the clock—only one more song left, but Ria is already sleepy and cranky.
Resolution: Mumma whispers, "Ek last dance, then straight to bed"—Ria dances one more time, then happily goes home.
Moral: Late nights are okay sometimes, but knowing the end is near helps kids say goodbye.
''',
    setting: 'Bedroom, 11pm, party music still audible',
    sceneDetail: 'One earplug is missing from the pair',
    dialogue: '"Thoda sa music sunne do — bas paanch minute!"',
    mess: 'Ria keeps dancing instead of sleeping',
    innerThought: 'The neighbors will complain by midnight.',
    endingBeat: 'Ria yawns, turns off the music, pulls the blanket up.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria's new lehenga is itchy — "Nikal do, nikal do!" She refuses to wear it at all.
Twist: Mumma offers two options: "Option one, lehenga without the heavy dupatta. Option two, comfortable chaniya."
Resolution: Ria picks Option 2 — comfy chaniya and light jhumkas. She twirls and grins. "Maa, main khoobsurat lag rahi hoon!"
Moral: Comfort before style — when kids feel good, they shine.
''',
    setting: 'Changing room, pre-party, mirror lit',
    sceneDetail: 'One strap of the lehenga keeps slipping',
    dialogue: '"Yeh bahut tight hai, Mumma!"',
    mess: 'Ria walks with tiny steps, adjusting the outfit every three steps',
    innerThought: 'Two more hours. Can I survive two more hours?',
    endingBeat: 'Ria sits on the bed, "comfort over couture" with Mumma.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'navratri-no-partner',
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
    custom: false,
    archived: true,
    storyDetail: '''
Story: Ria sees older kids dancing and wants to join, but she can't follow the complex steps—"Mummy, main nahi kar paa rahi!"
Twist: Papa joins her with a simple 2-step twist—"Ria-style dance, papa-style dance!"—and soon Rio and Cuty copy them.
Resolution: Ria's simple steps become the hit of the circle—everyone wants to learn the "toddler twist."
Moral: You don't need to follow—it's better to create your own way to celebrate.
''',
    setting: 'Garba ground, evening, lights strung overhead',
    sceneDetail: 'One partner has a broken jhumka',
    dialogue: '"Koi nahi hai meri saath ghoomne ke liye!"',
    mess: 'Ria looks for a partner, all her friends have pairs',
    innerThought: 'I should have arranged pairs in advance.',
    endingBeat: 'Daadi says "main hoon na", both dance without looking for pairs.',
    defaultCast: ['Ria', 'Daadi', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Garba is starting in 5 minutes, but Ria is still struggling with her jootneys—"Jootey pehne mein dikkat ho rahi hai!"
Twist: Papa turns it into a game—"Jootey pehne, superhero ban jao!"—Ria giggles and slips them on.
Resolution: Ria runs to join the Garba circle just in time, her "superhero jootneys" clicking as she dances.
Moral: Rushing creates resistance—transform the race into play and everything falls into place.
''',
    setting: 'Bedroom, 9pm, outfit laid out on the bed',
    sceneDetail: 'One bangle rolled under the bed, unreachable',
    dialogue: '"Jacket kahan hai? Dupatta kahan hai?"',
    mess: 'Everything is ready except one small thing that takes ten minutes',
    innerThought: 'We will miss the first aarti.',
    endingBeat: 'Rio finds the bangle, they leave with two minutes to spare.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'navratri-bumped-crowd',
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
    custom: false,
    archived: true,
    storyDetail: '''
Story: The Garba floor is packed and Ria gets accidentally bumped—she looks scared and clings to Mumma.
Twist: Mumma lifts Ria onto her shoulders so she can see over the crowd—"Ab dekho, yeh sab kuch badiya lag raha hai!"
Resolution: From above, Ria sees the beautiful lights and starts waving at other dancers—her fear turns to wonder.
Moral: A new perspective can turn overwhelm into magic—sometimes elevation helps us see the beauty.
''',
    setting: 'Garba ground, peak hour, crowd moving',
    sceneDetail: 'One woman\'s dupatta is caught on a chair leg',
    dialogue: '"Ma\'am, aapke pichhe se nikal lijiye!"',
    mess: 'Ria gets pushed, loses balance, the dupatta tangles more',
    innerThought: 'I should have arrived early.',
    endingBeat: 'A stranger helps untangle, Ria offers her a sip from her water bottle.',
    defaultCast: ['Ria', 'Mumma', 'Crowd member'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'navratri-phone-at-event',
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
    custom: false,
    archived: true,
    storyDetail: '''
Story: Garba has started but Ria keeps asking for her phone—"Mummy, phone dikhao, videos banana hai!"
Twist: Mumma gives Ria a small bag with crayons and stickers—"Garba mein draw kar lo kya dekh rahe ho!"
Resolution: Ria is busy drawing her Garba scene and forgets about the phone—she shows Mumma her artwork happily.
Moral: Engagement beats screen time—small offline activities keep little hands busy during big moments.
''',
    setting: 'Garba ground, evening, phone in hand',
    sceneDetail: 'One notification light is blinking',
    dialogue: '"Mumma kehti hain — phone mat Deewali tak band!"',
    mess: 'Ria takes 50 photos but none capture the moment',
    innerThought: 'She\'s five. She wants to show me everything.',
    endingBeat: 'Ria puts the phone away, starts clapping with her hands.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'navratri-attention-prep',
    category: 'Diwali',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma is setting the Diwali table, but Ria keeps grabbing things. "Mere saath khelo!"
Twist: Mumma hands Ria a stack of napkins: "Tum bhi Maa ki helper ho, napkins ghoomao."
Resolution: Ria carefully places each napkin beside a plate. "Mainne madad ki!" "Perfect," Mumma says.
Moral: Invitations beat interruptions — when kids feel helpful, they don't compete for attention.
''',
    setting: 'Kitchen, morning, Garba prep in progress',
    sceneDetail: 'One pot of dal is boiling over',
    dialogue: '"Mumma sirf Mumma ko hi dhyan do!"',
    mess: 'Ria competes with every household task for attention',
    innerThought: 'I can\'t be everywhere at once.',
    endingBeat: 'Ria sits on the counter, "teaching" Cuty to stir the dal.',
    defaultCast: ['Ria', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // ── New 30s Reel Stories ──
  HookIdea(
    id: 'plate-patana',
    category: 'Relatable',
    cover: 'Plate Patana',
    opening: 'Ria plate mein khana rakhti thi — phir "Mumma, sab mix ho gaya!"',
    problem: 'Plate mein dal, rice, aur vegetable sab mix ho gaya.',
    lesson: 'Ek chhota sa separation — dal ka swimming pool.',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria plate mein khana rakhti thi — phir "Mumma, sab mix ho gaya!" Dal, chawal, aur vegetable sab ek saath ghubhrey.
Twist: Mumma ek chhota sa bowl le aati hain: "Ek minute, maaro ek alag." Rio bhi dekh rahe hain.
Resolution: Dal ka swimming pool alag, chawal phir se — "Bachcha ne engineering shuru kar di!"
Moral: Ek minute separation, poora mood badal jaata hai.
''',
    setting: 'Dining table, lunch time, dal and chawal in the same plate',
    sceneDetail: 'Dal swimming in the rice, vegetable pieces floating',
    dialogue: '"Mumma, sab mix ho gaya!"',
    mess: 'Ria pushes dal away from chawal with her spoon, more mixing happens',
    innerThought: 'One small bowl, one big calm.',
    endingBeat: 'Dal ka swimming pool alag, chawal phir se — "Bachcha ne engineering shuru kar di!"',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'toy-sharing',
    category: 'Relatable',
    cover: 'Toy Sharing',
    opening: 'Ria aur Rio dono ek hi toy car ko pakad kar khushboo mein latke the.',
    problem: 'Ria aur Rio dono ek hi toy car ko pakad kar khushboo mein latke the.',
    lesson: 'Share karne se toy gam nahi hota, saath khelne se toh mazaa hi kuchh aur hota hai.',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria and Rio both grab the same red-yellow toy car and tug in opposite directions on the living room rug. The car wobbles between them.
Twist: When Mummy hands it to one, the other grabs it too — and the car goes flying across the room.
Resolution: Cuty pushes the car down the middle between them — "Ek do pal ke liye, dono ke liye!"
Moral: Share karne se toy gam nahi hota, saath khelne se toh mazaa hi kuchh aur hota hai.
''',
    setting: 'Living room floor, afternoon, toys everywhere',
    sceneDetail: 'One car has a wheel missing',
    dialogue: '"Yeh mera hai!" — "Mera bhi!"',
    mess: 'Both grab for the same car, the missing wheel rolls away',
    innerThought: 'I should have bought two identical cars.',
    endingBeat: 'They push the car together, Rio steering, Ria pushing.',
    defaultCast: ['Ria', 'Rio'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'park-se-nikalna',
    category: 'Relatable',
    cover: 'Park Se Nikalna',
    opening: 'Ria ne kaha — "Main yahan nahi jaungi park se!" jab papa ne time khatam kaha.',
    problem: 'Ria ne kaha — "Main yahan nahi jaungi park se!" jab papa ne time khatam kaha.',
    lesson: 'Game toh game hota hai, lekin har game ek nayi baat sunane dega.',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Park time is over. Papa checks his watch — "Time to go." Ria plants her feet — "Main yahan nahi jaungi park se!"
Twist: Rio joins the protest — "Mujhe bhi nahi jaana!" — both sit on the ground.
Resolution: Papa turns it into a game — "Jiska pehla step niklega, wohi jeeti ka countdown karega."
Moral: Game toh game hota hai, lekin har game ek nayi baat sunane dega.
''',
    setting: 'Society park exit, morning, Papa checking his watch',
    sceneDetail: 'Ria sitting on the bench, arms crossed, refusing to move',
    dialogue: '"Main yahan nahi jaungi park se!" "Time to go."',
    mess: 'Ria plants her feet, Rio joins in protest, both sit on the ground',
    innerThought: 'A game beats a demand — every time.',
    endingBeat: 'First step to the gate, then countdown begins: "Jiska pehla step niklega, wohi jeeti ka countdown karega!"',
    defaultCast: ['Ria', 'Rio', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'the-toy-car-share',
    category: 'Relatable',
    cover: 'He grabbed her car.',
    opening: '"Yeh mera hai!" — and the whole park turns around to look at me.',
    problem: 'Sunday morning, society park. Rio pulls the red car out of Ria\'s hand mid-race. Ria screams. Four mothers turn around.',
    lesson: 'Turn-taking needs a handle the child can hold — a timer, a song, a hand.',
    postFormat: 'Reel',
    strategy: 'Public-meltdown shame hook',
    caption: 'The car has one broken wheel, so it always veers left. So do most of my parenting solutions.',
    pinnedComment: '"Gaana khatam hone tak" is the only line that has ever worked in this house. What\'s yours?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Sunday morning, society park. Rio pulls the red car out of Ria's hand mid-race. Ria screams. Four mothers turn around.
Twist: Mumma steps in: "Gaana khatam hone tak. Phir tumhari baari."
Resolution: Ria still cries for another ten minutes. Mumma ends up holding one hand of each kid, standing between them.
Moral: Turn-taking needs a handle the child can hold — a timer, a song, a hand.
''',
    setting: 'Society park, Sunday, 8:40am, Ria on the last free swing',
    sceneDetail: 'The car is missing one wheel, so it always veers left.',
    dialogue: '"Gaana khatam hone tak. Phir tumhari baari."',
    mess: 'Ria still cries for another ten minutes. Mumma ends up holding one hand of each kid, standing between them.',
    innerThought: 'I want to just hand the car back and walk home.',
    endingBeat: 'Both kids on the same swing, the car lying between them, nobody holding it.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'the-block-tower',
    category: 'Warm lesson',
    cover: 'It took her 9 minutes.',
    opening: 'Nine minutes of building. Two seconds to fall.',
    problem: 'Cuty stacks six blocks on the biscuit tin. Rio walks past and flattens it with one arm.',
    lesson: 'Rebuilding together is sometimes the whole repair — the apology comes later.',
    postFormat: 'Reel',
    strategy: 'Countdown-to-disaster hook',
    caption: 'The second crash was her own doing. I have stopped intervening in that one.',
    pinnedComment: 'How many minutes does your child build before someone in the family destroys it? Ours is 9.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cuty stacks six blocks on the biscuit tin. Rio walks past and flattens it with one arm.
Twist: Cuty cries, then rebuilds it herself, then knocks it down herself and laughs. Everyone is confused. Papa gets blamed anyway.
Resolution: Cuty sitting inside the collapsed pile of blocks, looking very proud.
Moral: Rebuilding together is sometimes the whole repair — the apology comes later.
''',
    setting: 'Hall floor, after lunch, TV off, Papa\'s socks on the sofa',
    sceneDetail: 'The tower sits on the Britannia biscuit tin, so it wobbles before it even starts.',
    dialogue: '"Ek... do... teen... RIOOO!"',
    mess: 'Cuty cries, then rebuilds it herself, then knocks it down herself and laughs. Everyone is confused. Papa gets blamed anyway.',
    innerThought: 'If I say one word right now, I become part of it.',
    endingBeat: 'Cuty sitting inside the collapsed pile of blocks, looking very proud.',
    defaultCast: ['Cuty', 'Rio', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'the-snack-reach',
    category: 'Warm lesson',
    cover: 'She got the tin.',
    opening: 'She climbed the stool, got the biscuit tin, and then could not get down.',
    problem: 'Cuty wants the Parle-G tin kept on the top shelf. Nobody is in the kitchen. She drags the blue plastic stool over.',
    lesson: 'The skill wasn\'t asking for help. It was staying calm while stuck.',
    postFormat: 'Reel',
    strategy: 'Half-success hook (child wins, then loses)',
    caption: 'She was stuck for four minutes and never once called me. I am choosing to see that as growth.',
    pinnedComment: 'What is the one shelf in your house that your child has conquered?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cuty wants the Parle-G tin kept on the top shelf. Nobody is in the kitchen. She drags the blue plastic stool over.
Twist: She is stranded on the stool with the tin in one hand, too scared to climb down, and refuses to put it back.
Resolution: Mumma's hand holding the tin; Cuty's legs still dangling off the stool.
Moral: The skill wasn't asking for help. It was staying calm while stuck.
''',
    setting: 'Kitchen, 5pm, atta still out from lunch',
    sceneDetail: 'The tin is one shelf higher than she can reach even standing on the stool',
    dialogue: '"Mumma! I got it MYSELF."',
    mess: 'She is stranded on the stool with the tin, too scared to climb down',
    innerThought: 'This is entirely my fault for moving the tin up last week.',
    endingBeat: 'Mumma\'s hand holding the tin; Cuty\'s legs still dangling off the stool.',
    defaultCast: ['Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'night-before-annual-day',
    category: 'Relatable',
    cover: '11:40pm. Still stitching.',
    opening: 'The costume is a bedsheet. Her annual day is in eight hours.',
    problem: 'Ria announces at bedtime that she is a butterfly tomorrow and needs wings "in blue". The shops shut at 9.',
    lesson: 'Sometimes the win is just that she walks in wearing something on her back.',
    postFormat: 'Reel',
    strategy: 'Deadline-panic hook (no resolution shown)',
    caption: 'Every year I say I will prepare in advance. Every year it is a bedsheet, a safety pin, and me.',
    pinnedComment: 'Annual day, fancy dress, Diwali function — which one has cost you the most sleep?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria announces at bedtime that she is a butterfly tomorrow and needs wings "in blue". The shops shut at 9.
Twist: The safety pin snaps halfway through the second wing. Ria, half asleep: "Mumma, blue neela nahi hota na?"
Resolution: The wing is still unfinished at midnight. Ria is asleep. There is no stage shot, no proud moment, no payoff — the reel ends before the morning.
Moral: Sometimes the win is just that she walks in wearing something on her back.
''',
    setting: 'Bedroom, 11:40pm, one bedside lamp on, Ria asleep in the middle of the bed',
    sceneDetail: 'The safety pin snaps halfway through the second wing.',
    dialogue: 'Ria, half asleep: "Mumma, blue neela nahi hota na?"',
    mess: 'The wing is still unfinished at midnight. Ria is asleep. There is no stage shot, no proud moment, no payoff — the reel ends before the morning.',
    innerThought: 'I will fix this and she will not even remember it tomorrow.',
    endingBeat: 'One wing finished on the chair, one still a bedsheet; phone alarm visible: 6:00am.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'asmr-cleaning-reel',
    category: 'Relatable',
    cover: 'She is "helping".',
    opening: 'The atta was on the floor. She has now added water.',
    problem: 'Cuty spills the atta, decides to clean it herself, and reaches for the water mug because that is what cleaning looks like.',
    lesson: 'Toddler help is often just mess with better intentions.',
    postFormat: 'Reel',
    strategy: 'ASMR-hook inversion (calm setup, chaos payoff)',
    caption: 'Sound on. The squelch at 0:06 is the reason I own a second mop.',
    pinnedComment: 'What has your child "cleaned" for you this week? Be honest about the floor.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cuty spills the atta, decides to clean it herself, and reaches for the water mug because that is what cleaning looks like.
Twist: The paste spreads. Cuty is now sitting in it. The floor becomes worse than it was, and Mumma starts laughing instead of scolding.
Resolution: The paste-covered floor, with two small handprints in it.
Moral: Toddler help is often just mess with better intentions.
''',
    setting: 'Kitchen floor, right after rolling rotis, steel plate still on the counter',
    sceneDetail: 'The atta was dry, sweepable, and is now a paste that has to be scraped.',
    dialogue: '"Dekho Mumma, saaf!"',
    mess: 'The paste spreads. Cuty is now sitting in it. The floor becomes worse than it was, and Mumma starts laughing instead of scolding.',
    innerThought: 'My grandmother would have shouted. I am laughing because I have no other option left.',
    endingBeat: 'The paste-covered floor, with two small handprints in it.',
    defaultCast: ['Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Two minutes of dead silence from the toddlers. Mummy tiptoes toward the kitchen — suspiciously quiet.
Twist: Flour footprints lead across the floor: tiny bare feet, Cuty's paw prints, and a trail of white dust.
Resolution: Round the corner — Ria and Rio, flour-covered, sitting in a cloud of spilled wheat, building a "snowman."
Moral: The most suspicious silences always end with creative chaos to clean up.
''',
    setting: 'Kitchen, evening, flour bag tipped over',
    sceneDetail: 'Flour footprints — tiny bare feet, Cuty\'s paw prints, white dust trail',
    dialogue: '"Mummy heard two minutes of dead silence..."',
    mess: 'Ria and Rio, flour-covered, sitting in a cloud of spilled wheat, building a "snowman"',
    innerThought: 'The silence was too good to be true.',
    endingBeat: 'They stand up, snowman wobbles, flour explodes — creative chaos confirmed.',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: School van at 7:55 AM, but one shoe has vanished into another dimension.
Twist: Visual clues only: tiny footprint in flour (Rio), a trail of blocks (Cuty), and a doll stroller with one shoe tucked inside.
Resolution: With seconds to spare, they pull the shoe from the stroller. "Doll ne bhi date ki hai!" Rio grins.
Moral: Lost things usually have simple explanations — check the stroller.
''',
    setting: 'Bedroom floor, morning, backpack by the door',
    sceneDetail: 'One shoe is missing, the other is kicked under the bed, doll stroller nearby',
    dialogue: '"Joota kahan hai?" — "Main jaanta hoon, beta."',
    mess: 'Flour footprint, trail of blocks, and a trail toward the stroller — clues everywhere',
    innerThought: 'Clues first, panic second — the stroller always holds secrets.',
    endingBeat: 'They pull the shoe from the stroller — "Doll ne bhi date ki hai!" Rio grins.',
    defaultCast: ['Ria', 'Rio'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mummy snapped a big round cookie in half to share, and Ria acted dramatic shock as if the world itself had shattered.
Twist: Rio became "Doctor Rio," dipping his finger in warm milk to glue the broken halves back together, but Cuty took a nibble right on the seam.
Resolution: Instead of tears, both kids burst into uncontrollable belly laughs — the broken biscuit became the funniest thing ever.
Moral: A shared laugh turns every broken thing into something sweet.
''',
    setting: 'Kitchen, afternoon snack, biscuit tin open',
    sceneDetail: 'One biscuit is broken perfectly in half',
    dialogue: '"Yeh toh doosri poori tarah se toot gaya!"',
    mess: 'Ria has a meltdown over the broken biscuit, refuses the other half',
    innerThought: 'I should have bought more biscuits.',
    endingBeat: 'Mumma breaks another biscuit, "now they match", Ria eats both.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // ── Ria Talking to AI Robot Series ──
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria: "Robot, phone rakh do!" But her hand is still gripping it.
Twist: Robot: "Object is resting. Hand is still attached." Robot scans behind couch, under pillows, in Cuty's mouth.
Resolution: Robot points at Ria's own hand: "Object located." Ria laughs: "Meri hi toh thi!"
Moral: Sometimes the thing we want help finding is already in our hand.
''',
    setting: 'Living room, afternoon, Robot charging on dock',
    sceneDetail: 'One LED on Robot\'s chest blinking erratically',
    dialogue: '"Robot, phone rakh do!"',
    mess: 'Ria asks Robot to put the phone away, but she\'s still holding it — Robot scans everywhere',
    innerThought: 'Sometimes the thing we want found is already in our hand.',
    endingBeat: 'Robot points at Ria\'s own hand: "Object located." Ria laughs.',
    defaultCast: ['Ria', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria: "Mujhe yeh sabzi bilkul nahi chahiye!" She pushes the plate away.
Twist: Robot whirs: "Sabzi Rejection Form — Item Code: Green." Prints a form with checkboxes: too slimy / too green / too much.
Resolution: Ria checks "too green," and Robot replies: "Noted. Try cheese next time." She tries one bite with cheese. "Thik hai!"
Moral: Even rejections can be filed — and sometimes re-tried.
''',
    setting: 'Dining table, lunch time, Ria\'s plate in front of her',
    sceneDetail: 'Green sabzi on the plate, Ria pushing it away with her spoon',
    dialogue: '"Mujhe yeh sabzi bilkul nahi chahiye!"',
    mess: 'Ria rejects the sabzi, refuses to try, wants a formal rejection form',
    innerThought: 'Even rejections can be filed — and sometimes re-tried.',
    endingBeat: 'Ria checks "too green" on the form, tries cheese, says "Thik hai!"',
    defaultCast: ['Ria', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio accidentally breaks Ria's favorite toy, and Ria is devastated, declaring her heart is broken.
Twist: The robot takes "broken heart" literally and produces a large adhesive bandage shaped like a heart, applying it to Ria's chest.
Resolution: Seeing the silly bandage, both kids laugh, Rio apologises, and they repair the toy together with the robot's help.
Moral: A little humor and teamwork can mend both toys and feelings.
''',
    setting: 'Living room floor, toy pieces scattered',
    sceneDetail: 'Ria\'s favorite toy blocks, one piece cracked in the middle',
    dialogue: '"Mera heart toot gaya!"',
    mess: 'Ria holds the broken toy, tears streaming, Rio looks guilty beside it',
    innerThought: 'A little humor can mend both toys and feelings.',
    endingBeat: 'Heart bandage applied, toy repaired, both kids laughing.',
    defaultCast: ['Ria', 'Rio', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: "Mera sab kharab!" Ria throws her arms up — everything is ruined.
Twist: Robot sits stiffly, holds out one block: "Problem identified. Solution: one block."
Resolution: Ria laughs: "Ek hi block?" Robot: "Ek block se shuru hota hai." They build a tiny tower together.
Moral: A single block can start a new tower — and a robot's deadpan can reset a mood.
''',
    setting: 'Living room floor, scattered blocks, Ria throwing her arms up',
    sceneDetail: 'Robot holding out one block, tray extended',
    dialogue: '"Mera sab kharab!" — "Ek block se shuru hota hai."',
    mess: 'Ria declares everything ruined, Robot sits stiffly holding one block',
    innerThought: 'A robot\'s deadpan can reset a mood.',
    endingBeat: 'They build a tiny tower together — one block at a time.',
    defaultCast: ['Ria', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'robot-05',
    category: 'Series',
    cover: 'Ek Chhota Sa Saans',
    opening: 'Tower gir gaya... Rio ne saans li.',
    problem: 'Tower falls and Rio is ready to shout — Robot teaches one tiny breath.',
    lesson: 'One breath before the shout saves the tower.',
    postFormat: 'Reel',
    strategy: 'Overstimulation handling, emotional regulation, breathing exercise',
    caption: 'Jab sabse zindagi mein bahut kuchh ho raha hai... toh ek robot breathing cards ke saath madad karta hai! 🧘‍♀️ #RiaAndRobot #EmotionalRegulation #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'Five minutes of quiet, a breathing card, and Ria was back to her playful self. 💙',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Tower falls. Rio inhales to shout — "NOOOOO!" — but the card he grabbed flies out of his hand.
Twist: "Ek chhota sa saans." Ria whispers. She holds one tiny breath with him — in for two, out for two.
Resolution: Rio tries again. The card lands softly in his palm. They rebuild the tower, one block at a time.
Moral: A breath before the shout can save the whole tower.
''',
    setting: 'Drawing room floor, blocks scattered, breathing cards fanned out',
    sceneDetail: 'One tower block lies alone, a purple "breathe" card beside it',
    dialogue: '"NOOOO!" — then "Ek chhota sa saans."',
    mess: 'Rio stomps, tower crumbles a second time, blocks flying everywhere',
    innerThought: 'My lungs feel like they are going to explode.',
    endingBeat: 'They rebuild the tower together, one block at a time, counting breaths.',
    defaultCast: ['Rio', 'Ria', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio copies EVERYTHING — Ria's sip, Ria's walk, Ria's "I'm a big cat!" He escalates to silly robot noises.
Twist: Ria's patience frays. Robot interrupts: "Copy complete. Initiating joint silly pose protocol."
Resolution: Robot strikes a pose — "Left hand broccoli, right hand ice cream." Both kids mirror. Laughter breaks the tension.
Moral: Copying can flip into collaboration when you turn it into a game.
''',
    setting: 'Living room floor, Ria and Rio side by side',
    sceneDetail: 'Rio mirroring Ria\'s every move — sip, walk, big cat impression',
    dialogue: '"Left hand broccoli, right hand ice cream."',
    mess: 'Rio escalates to silly robot noises, Ria\'s patience frays',
    innerThought: 'Copying can flip into collaboration when you turn it into a game.',
    endingBeat: 'Robot strikes a pose, both kids mirror — laughter breaks the tension.',
    defaultCast: ['Ria', 'Rio', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria shows her drawing to the robot, upset that it doesn't look like the example picture.
Twist: The robot scans the drawing and projects an animated version, highlighting how her unique style brings the picture to life in ways the example never could.
Resolution: Ria beams with pride — "Mere drawings alive hote hain!" — and wants to draw ten more.
Moral: There's no "wrong" way to create art — your style is your superpower.
''',
    setting: 'Drawing table, afternoon, Ria\'s drawing beside an example picture',
    sceneDetail: 'Ria\'s drawing — a lopsided sun, crooked tree, wobbly house',
    dialogue: '"Mere drawings alive hote hain!"',
    mess: 'Ria compares her drawing to the example, upset that hers looks different',
    innerThought: 'There\'s no "wrong" way to create art — your style is your superpower.',
    endingBeat: 'Robot projects Ria\'s drawing as animation, she beams with pride.',
    defaultCast: ['Ria', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'robot-12',
    category: 'Series',
    cover: 'Mumma Sun Leti Hai!',
    opening: 'Robot, kya Mumma ko bhi peeche dikta hai?',
    problem: 'Ria is caught doing something she shouldn\'t, but it isn\'t magic — Mumma heard the clues',
    lesson: 'The robot shows how parents pick up sounds and signs, not superpowers.',
    postFormat: 'Reel',
    strategy: 'Parental awareness, hearing clues, playful acknowledgment',
    caption: 'Robot ne bataya: "Mumma ne suna — steps, crinkles, timer beep!" 🔄👂 #RiaAndRobot #ParentSuperpower #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'It\'s not magic — it\'s Mumma\'s ears! We hear EVERYTHING. 😉',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria tries to sneak a cookie, but Mumma calls out — "Ruk jao, meri aankh bhi nahi todegi!"
Twist: Mumma explains: "Maine tumhare steps suna, aur wrapper ki awaaz li." The robot projects a "clue chart" — footsteps, crinkles, timer beep.
Resolution: Ria laughs instead of protests. "Toh main kabhi bhi nahi chupke se cookie le sakti?"
Moral: Pyaar se bina camera ki zaroorat nahi — sunna hi kaafi hota hai.
''',
    setting: 'Kitchen corner, afternoon, cookie jar on the counter',
    sceneDetail: 'Ria sneaking toward the jar, a wrapper crinkling under her foot',
    dialogue: '"Ruk jao, meri aankh bhi nahi todegi!"',
    mess: 'Ria tries to sneak a cookie, steps creak, wrapper crinkles — Mumma ears are open',
    innerThought: 'Pyaar se bina camera ki zaroorat nahi — sunna hi kaafi hota hai.',
    endingBeat: 'Mumma explains the clue chart: "Maine tumhare steps suna." Ria laughs instead of protests.',
    defaultCast: ['Ria', 'Mumma', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria is building a puzzle. Rio looms too close, knocking pieces sideways. "Mujhe thoda space chahiye!"
Twist: Robot stretches a ruler across the table: "Ek haath ka space." Red line for Ria, blue line for Rio.
Resolution: "Line ke andar raho." They both stay in their zones, finish the puzzle together.
Moral: Space to create is peace to create.
''',
    setting: 'Living room table, puzzle in progress, Ria concentrating',
    sceneDetail: 'Puzzle pieces scattered, Rio looming too close, pieces knocked sideways',
    dialogue: '"Mujhe thoda space chahiye!" "Ek haath ka space."',
    mess: 'Rio crowds Ria while she builds, knocking puzzle pieces everywhere',
    innerThought: 'Line ke andar raho — both stay in their zones.',
    endingBeat: 'Red line for Ria, blue line for Rio — they finish the puzzle together.',
    defaultCast: ['Ria', 'Rio', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria feels butterflies in her tummy before showing her drawing to the class and says the robot about them.
Twist: The robot scans her and displays "Excitement Detected: 97% — Butterflies = Courage, Not Fear."
Resolution: The robot teaches her a "butterfly breath" and Ria confidently shows her drawing to everyone.
Moral: Butterflies mean you care — and caring is the first step to courage.
''',
    setting: 'Classroom, afternoon, Ria clutching her drawing',
    sceneDetail: 'Ria\'s drawing pinned on the wall, her stomach visibly fluttery',
    dialogue: '"Mere pet mein titliyan udd rahi hain!"',
    mess: 'Ria is paralyzed with jitters, classmates waiting to see her artwork',
    innerThought: 'Butterflies = excitement. Not fear.',
    endingBeat: 'Ria confidently shows her drawing — "This is my butterfly garden!"',
    defaultCast: ['Ria', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'robot-17',
    category: 'Series',
    cover: 'I\'m Dying of Boredom!',
    opening: 'Main bore ho rahi hoon!',
    problem: 'Ria has finished all her activities and declares nothing is left to do.',
    lesson: 'The robot suggested the "boredom jar" — a list of simple activities she can pick from.',
    postFormat: 'Reel',
    strategy: 'Boredom productivity, creativity prompts, activity jar system',
    caption: 'Boredom se pa gaya, Robot ne banaya "boredom jar"! Har ghoont mein naya activity. 🎨 #RiaAndRobot #BoredomHack #FunLearningWithPalak #IndianMoms #KidsComedy',
    pinnedComment: 'A boredom jar is a happiness jar waiting to happen. Which activity will you pick? ❤️',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria has finished everything — drawing, puzzle, snack, dance — and declares, "Ab kuchh nahi bacha!"
Twist: The robot produces a "Boredom Jar" filled with tiny scrolls, each with a creative activity she hasn't tried yet.
Resolution: Ria draws a scroll — "Build a blanket fort!" — and spends the afternoon on an epic adventure.
Moral: Boredom is just the moment before creativity kicks in.
''',
    setting: 'Living room, afternoon, boredom jar on the table',
    sceneDetail: 'Scrolls peeking out of the jar, Ria\'s hand reaching in',
    dialogue: '"Ab kuchh nahi bacha!" "Boredom Jar se ek scroll!"',
    mess: 'Ria declares nothing left to do — drawing, puzzle, snack, dance all finished',
    innerThought: 'Boredom is just the moment before creativity kicks in.',
    endingBeat: 'Ria draws "Build a blanket fort!" — epic adventure begins.',
    defaultCast: ['Ria', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria tells the robot about a surprise she is planning for Mumma. Rio overhears and blurts it out to everyone — "Ria ne Mumma ko surprise gift banaya hai!"
Twist: The robot draws a picture chart in two columns. One side: "Surprise = fun to share later!" Other side: "Secret = if it makes you sad or scared, tell Mumma or Papa right away."
Resolution: Rio understands: surprises are exciting when shared at the right time, and any feeling that feels icky must be told to a trusted grown-up immediately.
Moral: Surprises are sweet to share; secrets that make you uncomfortable must be told to a grown-up right away.
''',
    setting: 'Living room, afternoon, gift wrapping paper and ribbons',
    sceneDetail: 'Half-wrapped gift box, ribbons and tape scattered',
    dialogue: '"Ria ne Mumma ko surprise gift banaya hai!"',
    mess: 'Rio blurts out the surprise to everyone, Ria face falls',
    innerThought: 'Some secrets are meant to be shared at the right time.',
    endingBeat: 'Robot draws a two-column chart — surprise vs secret — Rio understands.',
    defaultCast: ['Ria', 'Rio', 'Robot', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
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
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria sees a table full of international foods and declares, "Mujhe poori duniya khana hai!" — she wants to eat everything.
Twist: The robot produces a world map where each country lights up as Ria tastes its cuisine — one bite at a time.
Resolution: Ria marks countries on her adventure map, trying one dish per day and learning about each culture.
  Moral: The world is huge — best to explore it one bite at a time.
''',
    setting: 'Dining table, afternoon, world foods map spread out',
    sceneDetail: 'International dishes arranged like a rainbow on the table',
    dialogue: '"Mujhe poori duniya khana hai!" "Ek bite at a time."',
    mess: 'Ria points at everything on the table, wanting to try all at once',
    innerThought: 'The world is huge — best to explore it one bite at a time.',
    endingBeat: 'Ria marks her first country on the adventure map, takes one careful bite.',
    defaultCast: ['Ria', 'Robot'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),


  // Real mess parenting stories.
  HookIdea(
    id: 'h22',
    category: 'Relatable',
    cover: 'Papa Jaldi Aao!',
    opening: 'Phone uthate hue — "Papa jaldi aao, Mumma phone pe baat karti hai!"',
    problem: 'Ria overhears a snippet of adult conversation and thinks it is an emergency',
    lesson: 'Sometimes kids connect the dots and create the drama for us',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria dials Papa at the office. "Papa jaldi aao, Mummy bahut pareshan hain!" Papa: "Kya hua beta?" Ria: "Mummy kehti hain, phone pe — 'biwi change kar lo!'" Papa crashes through the door — "Main hoon na!" Mumma: "Arre beta, woh toh Mummy ka meeting tha — client ka naam 'Biwi' hai."
Twist: Ria: "Toh... aap change kar li?" Mumma: "Nahi beta, company change ki." Ria, relieved: "Mummy bhi toh change kar sakti hai, na?" Both parents freeze.
Resolution: Papa: "Kal subhi phir se kahoongi." Ria: "Theek hai, lekin Mummy kal subhi bhi kuch change karegi?" They all three stare. Papa: "Shayad."
Moral:
''',
    setting: 'Living room, afternoon light through the window',
    sceneDetail: 'Phone on the coffee table, Ria standing on tiptoes to reach the receiver',
    dialogue: 'Papa jaldi aao, Mumma phone pe baat karti hai!',
    mess: 'Ria keeps adding details — "Mummy ro rahi thi!" "Mummy ne pani bhi nahi piya!" — each lie more dramatic',
    innerThought: 'Agar main itni badi baat karoongi toh Papa mujhe believe karega and maybe Mumma too',
    endingBeat: 'All three frozen in the doorway, nobody sure who is changing what',
    defaultCast: ['Ria', 'Papa', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h23',
    category: 'Relatable',
    cover: 'Wohi Toh Tha!',
    opening: 'Ria freezes mid-bite. "Arre... yehi toh tha jo tumne kaha tha!"',
    problem: 'Rio copies Mumma exact words at the worst possible moment',
    lesson: 'Toddlers are walking tape recorders — speak carefully',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma to Papa in the hallway: "Aaj tak nahi dekhna, tumhe samajh aa jayega." Rio, eating breakfast, looks up. "Mummy ne kaha — aaj tak nahi dekhna." Papa: "Kya?" Mumma's face goes white.
Twist: Mumma: "Maine kaha tha tumhe? Kisko bhi nahi kaha." Papa: "Tumne kaha tha — " Rio, matter-of-fact: "Mummy ne kaha tha tumhe — tumhare saath nahi dekhna."
Resolution: Mumma pinches her own arm: "Rio, tumhara breakfast khatam karo." Rio: "Wohi toh tha jo tumne kaha!" Mumma: "Haan bhi kaha."
Moral:
''',
    setting: 'Kitchen, breakfast table, morning light',
    sceneDetail: 'Half-eaten dosa on Rio\'s plate, Mumma\'s dupatta caught on the door handle',
    dialogue: 'Wohi toh tha jo tumne kaha tha!',
    mess: 'Rio keeps repeating "Mummy ne kaha" every time Mumma tries to backtrack',
    innerThought: 'Maine kya bigaara, when did my offhand comment become a courtroom testimony',
    endingBeat: 'Rio shrugs, takes another bite, and says "Bas yehi toh tha" for the last time',
    defaultCast: ['Rio', 'Mumma', 'Papa'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h24',
    category: 'Relatable',
    cover: 'Secret Agent Cuty',
    opening: 'Cuty trots between Mumma\'s legs, tail twitching — something is wrong.',
    problem: 'Child misunderstands a private adult conversation about money',
    lesson: 'Overheard snippets become a child\'s own private soap opera',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma on the phone: "Nahi, yeh month toh budget mein nahi aayega." Ria: "Budget? Kya budget?" Mumma: "Apna ghar ka budget." Ria: "Ghar ka budget? Par main toh ghar ka part hoon!" Cuty sniffs Mumma's purse and trots away.
Twist: Ria: "Toh kya main budget se bahar hoon?" Mumma: "Nahi beta..." Rio: "Main bhi budget se bahar hoon?" Mumma, defeated: "Sab koi budget ke andar hi hoon."
Resolution: Cuty emerges with a single coin from the purse. Drops it at Ria's feet. Everyone stares at the coin.
Moral:
''',
    setting: 'Hallway outside the bedroom, morning',
    sceneDetail: 'Mumma\'s purse on the floor, single coin glinting',
    dialogue: 'Par main toh ghar ka part hoon!',
    mess: 'Ria keeps asking "kitna budget hai?" and "kiska share hai"',
    innerThought: 'Agar main bahar hoon toh kya main free hoon, and then will they still love me',
    endingBeat: 'Cuty drops the coin, everyone stares at it like it just solved everything',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h25',
    category: 'Relatable',
    cover: 'Cuty\'s Investigation',
    opening: 'Cuty stands on his hind legs, nose twitching like a tiny detective.',
    problem: 'Child confidently "solves" a household mystery in the wrong way',
    lesson: 'Kids notice everything, even when adults think they haven\'t',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria marches to the kitchen: "Cuty ne problem dhundh li!" She holds up a magnifying glass. "Kaunne ne Mumma ki favourite chappal girayi?" Cuty sits innocent. Ria: "Evidence hai — hair on the floor, scuff mark on the wall."
Twist: Mumma: "Ria... maine khud hi toh girayi thi." Ria: "Phir bhi, koi aur problem hogi!" She points at the sink. "Dabbe nahi dhule — THAT is the mystery!"
Resolution: Cuty trots over, picks up a single dirty spoon, drops it at Rio's feet. Rio: "Mein bhi madad kar sakta hoon?" Ria: "Detective Cuty ne kaha — team banao."
Moral:
''',
    setting: 'Kitchen floor, morning light through window',
    sceneDetail: 'Magnifying glass on the counter, hair strand and scuff mark on the wall',
    dialogue: 'Evidence hai — hair on the floor!',
    mess: 'Ria keeps finding "clues" everywhere — missing spoon, untied shoelace, half-eaten breakfast',
    innerThought: 'Maine kuchh bhi nahi kara par sabse badi investigation main hogi, when the adults are not looking',
    endingBeat: 'Cuty drops the spoon at Rio\'s feet, all three kids form a tiny detective team',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  HookIdea(
    id: 'h26',
    category: 'Relatable',
    cover: 'Plan: Perfect!',
    opening: 'Ria presents a crumpled blueprint: "Maine plan banaya hai!"',
    problem: 'Child confidently solves a family problem in the wrong way',
    lesson: 'The child\'s solution is creative but completely misses the brief',
    postFormat: 'Reel',
    strategy: '',
    caption: '',
    pinnedComment: '',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria: "Dekho plan!" She unfolds a paper: "Step 1: Papa ko gulaab do." "Step 2: Mummy ko paani do." "Step 3: Rio ko TV chalu karo." "Step 4: Sab milke — PROBLEM SOLVED!" Mumma: "Ria beta, yeh kya plan hai?" Ria: "Galti kya hogi agar sabko pyaar milta hai?"
Twist: Papa: "Beta, main gulaab se allergic hoon." Rio: "Main TV nahi dekhna chahta, book maanga hai." Mumma: "Main paani nahi peeti, darrakchunni hai."
Resolution: Ria crumples the plan: "Toh... naya plan?" She draws a new one: "Step 1: Papa tofa mile." "Step 2: Mummy book mile." "Step 3: Rio dinosaur mile." "Step 4: Sab khush hain." Everyone laughs.
Moral:
''',
    setting: 'Living room floor, scattered toys, crumpled paper plan',
    sceneDetail: 'Ria\'s blueprint with "STEP 4: PROBLEM SOLVED!" in wobbly letters',
    dialogue: 'Maine plan banaya hai!',
    mess: 'Ria keeps adding steps — "Step 5: Cake cut" "Step 6: Everyone nap" — each more elaborate',
    innerThought: 'Agar maine yeh plan suna toh sab theek ho jayega, why do adults always need to change it',
    endingBeat: 'Ria\'s new plan with everyone getting what they actually asked for — crumpled again',
    defaultCast: ['Ria', 'Papa', 'Mumma', 'Rio'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '',
  ),

  // ── New ideas (added by hand; blanks to be filled later) ─────────────────────

  HookIdea(
    id: 'h27',
    category: 'Diwali',
    cover: 'Safety First, Sparkle Always!',
    opening: 'Phataka kholne se pehle, safety checklist dikhana zaroori hai.',
    problem: 'Diwali phataka safety',
    lesson: 'Safety rules banane se maza bhi hoga, bachcha bhi safe rahega.',
    postFormat: 'Reel',
    strategy: 'Teach one safety rule before lighting any firework.',
    caption: 'Safety first, Diwali second ✨🪔',
    pinnedComment: 'What safety rule do you teach your kids?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria ke saamne phataka jalaane ka waqt, Mumma pehle safety rules samjhati hai — kya doori rakhna hai, kis cheez se dhoop rukwani hai.
Twist: Ria phataka ko turant light karne ki koshish karti hai, par safety rule yaad karti hai aur rukni padti hai.
Resolution: Har safety rule follow karne ke baad, phataka jalaane ka maza do gunnah hone lagta hai.
Moral: Safety rules nahi todne se hi Diwali ka maza hota hai.
''',
    setting: 'Courtyard at dusk, fireworks laid out on the ground',
    sceneDetail: 'A small chalk-drawn circle marking the safe zone',
    dialogue: '"Pehle safety samjho, phir phataka jalao!"',
    mess: 'A spark lands on a curtain and starts to smolder',
    innerThought: 'How do I make safety fun and not boring?',
    endingBeat: 'Ria wears her "Safety Star" badge while lighting the phataka.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Safe kids light up Diwali brighter.',
    detail: 'Teach one rule before every firework.',
    punchline: 'Safety first, sparkle always!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h28',
    category: 'Diwali',
    cover: 'Saf Safai = Happy Diwali!',
    opening: 'Diwali se pehle saf safai ki dhun bajna shuru ho jaati hai.',
    problem: 'Diwali saf safai chaos at home',
    lesson: 'Thodi si safai, zyada saara khushi ka mahsos.',
    postFormat: 'Reel',
    strategy: '5-minute cleanup race with timer before decorating.',
    caption: 'Clean house, happy house 🪔🧹',
    pinnedComment: 'Tag your cleanup partner!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria aur Mumma Diwali se pehle poore ghar ki saf safai shuru karti hai. Cheezein har jagah phaili ho jaati hain, par dono ek saath kaam karte ho toh maza aa jaata hai.
Twist: Rio apni neele color ki bottle se doodh ki taraf badal diya — par woh doodh nahi, saf ka paani tha!
Resolution: Sab milkar 5 minute mein poora ghar saf kar liya, aur phir diyara jalaane lagi.
Moral: Ek saath kaam karo, toh double murgi, double aalgi ban jaye.
''',
    setting: 'Living room, Diwali decorations half-unpacked',
    sceneDetail: 'A toy racing track scattered with diyas and ribbons',
    dialogue: '"Race against time, Mumma! 5 min yaar!"',
    mess: 'Colored water spills on the new white curtain',
    innerThought: 'How do I keep this fun without making more mess?',
    endingBeat: 'Ria hangs the last diya on the cleaned window, glowing in the evening light.',
    defaultCast: ['Ria', 'Mumma', 'Rio'],
    keepMoralOffScreen: false,
    quote: 'Clean together, celebrate together.',
    detail: 'Use a 5-minute timer to make cleanup a game.',
    punchline: '5 minutes mein ghar bhi, khushi bhi!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h29',
    category: 'Diwali',
    cover: 'Diwali Ka Jashn Hai!',
    opening: 'Ria ki aankhon mein diyon ka chamke jashn hai.',
    problem: 'Diwali festival excitement',
    lesson: 'Thoda intezaar rakhna, toh sabse achha lagega.',
    postFormat: 'Reel',
    strategy: 'Count down to the big diya lighting together.',
    caption: 'Countdown to Diwali magic 🪔✨',
    pinnedComment: 'How many diyas did YOU light this Diwali?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria subse zyada excited hai Diwali ka din, lekin sabhi badiyon ke saath thoda intezaar karte hai. Rangoli banane se lekar diyara jalane tak, har pal wait karna padta hai.
Twist: Ria apni excitement ko ek diye ki roshni mein badal deti hai — har moment ek spark ban jaata hai.
Resolution: Jab sab thek kar liye, Ria ne apni pehli diya khud jalaayi, aur poora ghar chamke laga.
Moral: Jitna intezaar karo, utna hi maza hota hai.
''',
    setting: 'Courtyard at sunset, rangoli half-finished',
    sceneDetail: 'Ria holding a tiny diya in her palms, waiting for the signal',
    dialogue: '"Ab tak? Ab tak?"',
    mess: 'Oil spills from the diya onto the rangoli',
    innerThought: 'I want it to light NOW!',
    endingBeat: 'Ria blows out the diya, lights it again, and the whole courtyard glows.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Excitement tastes sweeter after waiting.',
    detail: 'Teach counting to 10 while waiting.',
    punchline: 'Intezaar bhi Diwali ka hissa hota hai!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h30',
    category: 'Diwali',
    cover: 'Rangoli Ki Rani!',
    opening: 'Mumma kehti hain — rangoli perfect hone se pehle, perfection ka kya mauka?',
    problem: 'Diwali rangoli chaos',
    lesson: 'Messy rangoli bhi wahi pyara lagta hai jab usse banane waala pyara ho.',
    postFormat: 'Reel',
    strategy: 'Make rangoli with hands, not tools — kids love the mess.',
    caption: 'Imperfect rangoli, perfect memories 💐',
    pinnedComment: 'Show us your messy rangoli!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria rangoli banane ki koshish karti hai, lekin rang sab jagah phail jaata hai — star, floor, even her nose tak pahunche.
Twist: Jab sab soch rahe hain ki rangoli ab kharab ho gayi, Rio kehti hai ki yeh "abstract art" hai.
Resolution: Ghar wale rangoli ke saath khush hokar photo le li, kyunki asli rangoli toh family ka pyaar hota hai.
Moral: Jo bhi ban raha ho, agar pyaar ke saath ban raha ho, toh wahi perfect hai.
''',
    setting: 'Front courtyard, rangoli powder scattered everywhere',
    sceneDetail: 'Ria sitting in a rainbow of colored powder, looking like a painting herself',
    dialogue: '"Yeh abstract art hai na, Mumma?"',
    mess: 'Pink powder all over Ria"s nose and ears',
    innerThought: 'Maybe I should just let her go full color.',
    endingBeat: 'Ria gives a thumbs up, covered in colors, holding her "masterpiece".',
    defaultCast: ['Ria', 'Mumma', 'Rio'],
    keepMoralOffScreen: false,
    quote: 'Messy hands, happy heart.',
    detail: 'Use washable colors and let kids go wild.',
    punchline: 'Rangoli nahi, rang-birangi baat ban gayi!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h31',
    category: 'Relatable',
    cover: 'Baal Ka Mahasangram!',
    opening: 'Jab bhi Mumma ne haath jodne lage, Ria ki peshab ki dikkat bhi lagti thi.',
    problem: 'Ria के बाल बनाते समय उनका टैंट्रम',
    lesson: 'Baalon ko bandhne se pehle, do minute ki "mehnat" ka maza le.',
    postFormat: 'Reel',
    strategy: 'Sing a hair-braiding song to make the wait fun.',
    caption: 'Patience is the prettiest hairstyle 💁‍♀️',
    pinnedComment: 'What song do you sing while braiding?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria के बाल बनाते समय वह बहुत ही ज़्यादा झपटने लगती है और मुम्मा के हाथ ठोक देती है। मुम्मा को एक गीत गाना पड़ता है ताकि वह आराम से बाल बना सके।
Twist: बीच में रिया ने एक छोटी सी दुआ माँगी — वह चाहती थी कि उसके बाल "ज्यादा दीर्घ" हों।
Resolution: मुम्मा ने गीत गाते हुए बाल बनाए और रिया को एक "बड़ी बहन" बनकर दिखाया।
Moral: थोड़ा इंतज़ार और एक गीत, तो बाल भी सुंदर हो जाते हैं।
''',
    setting: 'Bedroom in the morning, hair clip and rubber bands ready',
    sceneDetail: 'A half-braided pigtail dangling from Ria"s head',
    dialogue: '"Mumma, yeh itna dera kyun lag raha hai?!"',
    mess: 'Rubber bands snap and fly across the room',
    innerThought: 'Why does braiding take so long with three helpers?',
    endingBeat: 'Ria runs her fingers through the finished braids and strikes a pose.',
    defaultCast: ['Ria'],
    keepMoralOffScreen: false,
    quote: 'Good hair days come after patience plays.',
    detail: 'Use a timer and reward stickers for sitting still.',
    punchline: 'Baal bhi, patience bhi — dono mili jodी!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h32',
    category: 'Relatable',
    cover: 'Outfit Drama!',
    opening: 'Ria ne li 15 minute, par sirf 1 minute ke liye decide kar diya.',
    problem: "Ria's clothes tantrum",
    lesson: 'Jab bhi koi bhi kapda select karta hai, toh uski koi reason hoti hai.',
    postFormat: 'Reel',
    strategy: 'Give 3 outfit choices and let the child pick.',
    caption: 'Let them choose, let them shine 👗✨',
    pinnedComment: 'How many outfits do you own?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria को लगभग 15 kapdon में से चुनना पड़ता है, लेकिन वह सिर्फ 1 minute में तार्किक सोच कर चुन लेती है। हर कपड़े को पहनकर एक नई पहचान बनाती है।
Twist: अंत में वह वही कपड़ा पहन लेती है जो पहले से साफ है और जल्दी से पहने लिए तैयार है।
Resolution: Ria ने उसे खुद select किया और कहा — "Mumma, yehi pasand aaya!"
Moral: Speed isn't always the enemy of fun — sometimes it's the friend of efficiency.
''',
    setting: 'Bedroom, clothes all over the bed',
    sceneDetail: 'Ria holding 3 different colored dresses, spinning in each',
    dialogue: '"Yeh red? Nahi, blue? Haan, haan — green!"',
    mess: 'All the clothes fall off the hanger when Ria spins',
    innerThought: 'Why does picking one thing take forever?',
    endingBeat: 'Ria gives herself a final twirl in the chosen outfit, confident and happy.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'A choice made with confidence is always right.',
    detail: 'Use the "3 choices" trick to cut decision fatigue.',
    punchline: 'Fifteen minutes, one decision — full power!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h33',
    category: 'Warm lesson',
    cover: 'The Family Tree Surprise!',
    opening: 'Jab Mumma ne ek purani book di, Ria ki curiosity ka level 100 ho gaya.',
    problem: 'Ria received a surprise gift of family tree',
    lesson: 'Jab tak tumne apni jaat kho jati ho, tab tak tum kisipe bhi nahi jaati.',
    postFormat: 'Reel',
    strategy: 'Use a visual family tree chart to make connections.',
    caption: 'We are branches, we are roots 🌳❤️',
    pinnedComment: 'Tag your family tree buddy!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria को एक purani book मिली जिसमें उसका family tree likha tha. Har photo और नाम उसके zindagi का hissa tha — from Mumma's childhood to Ria's first day of school.
Twist: Ria ne dekha ki uske saath ek photo bhi hai jisme ek khaali jagah tha — "Future Ria" ke liye.
Resolution: Ria ने promise kardi — vah wohi person banegi jo apne saare log expected karte the.
Moral: Jaat kho jana matlab sirf photo yaad nahi hona — apna naam lena.
''',
    setting: 'Grandparent"s attic, old photo albums open',
    sceneDetail: 'A large family tree chart with photos in tiny frames',
    dialogue: '"Yeh toh main hun... par future?"',
    mess: 'Photos fall off the tree chart when Ria touches it eagerly',
    innerThought: 'I want to know who I really am.',
    endingBeat: 'Ria pins her own photo into the empty spot on the tree, smiling.',
    defaultCast: ['Ria', 'Mumma', 'Dadi', 'Daddy'],
    keepMoralOffScreen: false,
    quote: 'Roots don\'t hold us back - they lift us forward.',
    detail: 'Create a living family tree with new photos every year.',
    punchline: 'Main bhi toh ek branch hoon!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h34',
    category: 'Relatable',
    cover: 'Shopping Ka Jungle!',
    opening: 'Jab bhi mall jaate hai, Ria keh deti hai — main sirf ek chiz mangti hun.',
    problem: "Ria's tantrum when going out for copy mumma everything for makeup clothes and accessories",
    lesson: 'Ek limit set karna, tantrum ko samajne ka best tareeka hai.',
    postFormat: 'Reel',
    strategy: 'One-item rule: pick only one thing per shopping trip.',
    caption: 'One is plenty 💝',
    pinnedComment: 'What"s your one essential?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria को mall में जाते ही सब कुछ की माँग लग जाती है — makeup, clothes, accessories, even a toy for Rio. Mumma को थक जाता है।
Twist: Ria ने ek "wish list" banayi — par sirf 3 lines tak hi likhne di.
Resolution: वह ek chiz pakad kar khush hi thi — ek sparkly hair clip.
Moral: Limitation create karni padti hai freedom ki tarah.
''',
    setting: 'Mall corridor, toy aisle',
    sceneDetail: 'Ria holding 5 different items, wide eyes scanning every shelf',
    dialogue: '"Mumma, yeh bhi toh chahiye! Aur yeh bhi!"',
    mess: 'Everything ends up in the cart before the limit is explained',
    innerThought: 'Why can"t I have just one of everything?',
    endingBeat: 'Ria walks out with her one hair clip, already planning what to buy next time.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'One thing chosen with joy beats everything half-wanted.',
    detail: 'Use a "3 wishes" rule for younger kids, "1 item" for older.',
    punchline: 'Ek hi chiz, pura pyaar!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h35',
    category: 'Relatable',
    cover: 'Office Wali Mumma vs WFH Mumma!',
    opening: '"Work from home" kehti hoon, par office walli jaisa lagti hoon.',
    problem: 'Office going mom v/s work from home moms',
    lesson: 'Dono tarah ki mummy hoti hain — ek doosre ki help ke liye hamesha maujood.',
    postFormat: 'Reel',
    strategy: 'Split-screen comparison of both moms" daily routines.',
    caption: 'All moms are superhero moms 🦸‍♀️',
    pinnedComment: 'Which type of mom are you?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria को two Mummies dikhai de rahi hain — ek office jati hai, ek home pe kaam karti hai. Dono ka apna alag tarah ka swag hai.
Twist: Office wali Mumma का lunch break Rio ke saath video call pe hota hai, jisme WFH wali Mumma bhi join hoti hai.
Resolution: Dono mammi mil kar ek "Hybrid mom" ban jati hain — best of both worlds.
Moral: It"s not about where you work — it"s about how much you love.
''',
    setting: 'Two sides of the same kitchen, split-screen',
    sceneDetail: 'One side has a laptop and coffee mug, the other has a sari and diya',
    dialogue: 'Office Mumma: "5 PM deadline, but I\'m still your mom first." WFH Mumma: "3 PM soccer pickup, but I\'m still your hero."',
    mess: 'A spilled coffee lands on the WFH mom"s work shirt',
    innerThought: 'Why does everyone think I have it "easier"?',
    endingBeat: 'Both moms laugh over spilled coffee, trading places for a day.',
    defaultCast: ['Ria', 'Mummy', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Whether in heels or slippers, every mom walks the same path.',
    detail: 'Celebrate both work styles — they both matter.',
    punchline: 'Jahan bhi ho, mummy hi toh hai!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h36',
    category: 'Relatable',
    cover: 'Game Mode: Busy!',
    opening: 'Jab bhi phone uthate hain, Rio kehti — "Daddy call aa raha hai, par main game mein hoon!".',
    problem: 'Rio is not allowing me to answer any calls from his father as he was playing game',
    lesson: 'Game bhi time hote hain, call bhi time hote hain — dono important hain.',
    postFormat: 'Reel',
    strategy: 'Set an alarm for game switch — when it dings, it"s phone time.',
    caption: 'Balance, baby! 🎮📞',
    pinnedComment: 'How do you handle game time vs family time?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio का favorite game chal raha hota hai jab daddy se call aata hai. वह call khatam hone tak nahi janta — "Bas ek aur level!".
Twist: Daddy ने ek naya trick ki — usne apne voice message ke saath ek mini game bheja: "Call karo jab game over ho."
Resolution: Rio ने apne game से बाहर निकलकर call लिया — और दोनों together एक level complete किया.
Moral: Time boundaries without punishment = happy kids.
''',
    setting: 'Living room floor, console glowing',
    sceneDetail: 'Rio with headphones, controller in hands, Daddy"s call flashing on screen',
    dialogue: '"5 more minutes, Dad! Just one more level!"',
    mess: 'Controller throws when Rio loses a level right before the call',
    innerThought: 'Why does Daddy always call when I am about to win?',
    endingBeat: 'Rio pauses the game, calls Daddy back, and explains his strategy between levels.',
    defaultCast: ['Rio'],
    keepMoralOffScreen: false,
    quote: 'The pause button is a powerful tool.',
    detail: 'Use a kitchen timer for game-to-call transitions.',
    punchline: 'Level up, then call up!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h37',
    category: 'Relatable',
    cover: 'The Kiss Strategy!',
    opening: 'Jab bhi Cuty ka gussa chadhne lagta hai, kiss karke sab theek ho jaata hai.',
    problem: 'A strategy that I am using to calm my kid down when she is angry: try kissing her until she calms down',
    lesson: 'Pyaar se gussa kabhi badi badi hota hai.',
    postFormat: 'Reel',
    strategy: 'The "kiss countdown": 3 kisses calm, 2 kisses reset, 1 kiss reconnect.',
    caption: 'Love is the best pacifier 💋',
    pinnedComment: 'Which strategy works for you?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Jab Cuty ka gussa chadhne lagta haim — toys, words, sab kuch udaane ki koshish. Mumma ne ek secret strategy try kari — bas ek kiss shuru karti, phir dusra, phir teesra.
Twist: Har kiss ke baad gussa thoda sa kam ho jaata hai, lekin last kiss tak poora maza nahi aata — usse zaroori hai ki "hug" bhi mile.
Resolution: Cuty ki gussa poori tarah se kiss-hug se nikal aa gaya, aur ab woh ek naye game ke liye taiyyar thi.
Moral: Affection is not coddling — it"s connection before correction.
''',
    setting: 'Corner of the room where tantrums happen',
    sceneDetail: 'Cuty with tears streaming, Mumma kneeling at her level',
    dialogue: '"Beta, let Mumma kiss away the angry storm..."',
    mess: 'Toys scattered everywhere during the tantrum',
    innerThought: 'This looks ridiculous, but it is working.',
    endingBeat: 'Cuty snuggles into Mumma"s shoulder, the storm now just a whisper.',
    defaultCast: ['Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'A kiss can deflate anger faster than any timeout chair.',
    detail: 'Always kneel to eye level — no "above" positioning.',
    punchline: 'Gussa bhi, pyaae bhi — kiss se mit jaye!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h38',
    category: 'Relatable',
    cover: 'Mehfil vs Mess!',
    opening: 'Mumma ki mehndi khatam hone se pehle, Ria ki messy hair ka kya fasana?',
    problem: "Mummy's hairstyle mehnat vs Ria's messy hair in 2 minutes after the mehnat",
    lesson: 'Mehenat ki koshish, par results kabhi perfect nahi hota.',
    postFormat: 'Reel',
    strategy: 'Embrace the 2-minute mess — quick ponytail and go!',
    caption: 'Perfect is boring — messy is magnetic 💁‍♀️',
    pinnedComment: 'How fast can YOU do a ponytail?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma को 20 minute lagti hai apni Mehndi aur hairstyle banane mein, lekin Ria sirf 2 minute mein sab kuch bigaad sakti hai.
Twist: Jab sab soch rahe hain ki kuchh bhi nahi bacha, Ria ne ek "messy look" ko ek naye fashion trend kehte hain.
Resolution: Mumma ने accept kar liya ki messy hairstyle bhi ek tarah ki beauty hai.
Moral: Effort matters more than perfection.
''',
    setting: 'Bathroom counter, Mumma"s dupatta and Ria"s toys everywhere',
    sceneDetail: 'Ria"s hair full of bows, clips, and one random lollipop stick',
    dialogue: '"Mumma, look! I am a fairy princess mess!"',
    mess: 'Hair gel spills on Mumma"s dupatta',
    innerThought: 'Why does it take me 20 minutes but her just 2 to ruin it?',
    endingBeat: 'Both Mumma and Ria walk out together, hair messy but hearts full.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Effort with love always looks better than flawless with none.',
    detail: 'Use a "messy bun" rule for quick mornings.',
    punchline: 'Mehfilon ki shag, messy hair ka swag!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h39',
    category: 'Warm lesson',
    cover: 'Team Siblings!',
    opening: 'Jab koi bhi badi problem aaye, toh Ria-Rio-Cuty ek saath mil kar solve karte hain.',
    problem: 'Ria Rio Cuty fight too much, but whenever any other person tries to harass anyone they become a team',
    lesson: 'Jab tak bhai-bahan mil kar khada rheta hai, toh koi bhi problem hal ho sakti hai.',
    postFormat: 'Reel',
    strategy: 'Use sibling teamwork to solve stranger danger situations.',
    caption: 'United we stand 💪👧👦',
    pinnedComment: 'What"s your sibling super-power?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria, Rio, Cuty हमेशा ek dusse ki tarah ladati rehti hain — par jab koi stranger unse baat karta hai, toh वे ek team ban jaati hain।
Twist: Stranger ने unhe ek problem ke baare mein poocha — lost and needs help finding their dog।
Resolution: Teenon milkar ek proper search team ban gaye — Ria tracks footsteps, Rio checks the street, Cuty uses her keen ears。
Moral: Unity is strength, especially when it"s family.
''',
    setting: 'Neighborhood park, afternoon',
    sceneDetail: 'Three kids forming a line, then switching to a triangle formation',
    dialogue: 'Ria: "We don\'t fight outsiders - we fight FOR each other."',
    mess: 'A ball rolls into traffic and the siblings must work together to retrieve it safely',
    innerThought: 'Why do we only unite when someone else is in trouble?',
    endingBeat: 'The three siblings bow together after helping the stranger find their dog.',
    defaultCast: ['Ria', 'Rio', 'Cuty'],
    keepMoralOffScreen: false,
    quote: 'When siblings unite, even giants look small.',
    detail: 'Teach the "Buddy System" early — always look out for each other.',
    punchline: 'Teenon mile toh team, bina toh dream!',
    readyPrompt: '',
  ),
  HookIdea(
    id: 'h40',
    category: 'Warm lesson',
    cover: 'Confidence Hack Pack!',
    opening: 'Har ek trick batane ka maza aata hai jab bachche use khud se try karte hain.',
    problem: 'Tricks which we can try to make kids confident and learn life skills',
    lesson: 'Confidence build karne ke liye sabse best trick hai — "try karo, fail mat socho".',
    postFormat: 'Carousel',
    strategy: '5 daily confidence-builders: mirror talk, small wins, "I did it" moment.',
    caption: 'Confidence is a muscle — flex it daily 💪',
    pinnedComment: 'Start with one today. Which trick will you try?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Main को 5 life skill tricks pata chali hain jo bachchon ko confident banati hain: mirror self-talk, small daily wins, "I can" affirmations, safe failure zones, aur celebration rituals.
Twist: Rio ne pehla try kiya — mirror talk. पहले bahut hi awkward laga, par dusre din usne khud se compete karna shuru kar diya.
Resolution: तीनों children ne apni confidence diary banayi — har din ek nayi skill try karte hue।
Moral: Confidence grows in the soil of consistent small actions.
''',
    setting: 'Kids" room mirror, morning routine time',
    sceneDetail: 'A "Confidence Jar" filled with small notes — "Today I tied my shoes"',
    dialogue: '"Main yeh kar sakta hun!" — Rio to his reflection.',
    mess: 'The mirror gets foggy during the emotional talk',
    innerThought: 'What if they laugh at me?',
    endingBeat: 'All three kids add their daily win to the jar before bedtime.',
    defaultCast: [],
    keepMoralOffScreen: false,
    quote: 'Confidence isn"t about never failing — it"s about trying anyway.',
    detail: 'Create a "Wins Wall" with sticky notes for every small victory.',
    punchline: 'Confidence = small steps, big heart!',
    readyPrompt: '',
  ),

  // Safety hooks are spread in at the end.
  ...kSafetyHooks,
];

/// Built-in hooks with all rewrites and moments applied.
/// Since [kRewrittenStories] and [kMomentUpgrades] have been merged
/// directly into [kDefaultHooks], this is now a simple alias.
final kDefaultHooksWithRewrite = kDefaultHooks;

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
      'So clever! Kids love these simple observations.',
      'This is such a simple but smart activity, saving it!',
      '😂 The banana logic made me laugh!',
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
      'Replace biscuit with chocolate and this is EVERY household.',
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
      'Love these hidden object activities for focus!',
      'So good for observation skills at this age.',
      'My toddler spotted it right away, great game!',
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
      'Love how this builds slowly — keeps kids engaged!',
      'Simple but so satisfying to watch.',
      'This is a great one to do out loud with kids.',
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

  // Moment fields for story detail
  final String opening;
  final String sceneDetail;
  final String dialogue;
  final String mess;
  final String innerThought;
  final String endingBeat;
  final bool keepMoralOffScreen;

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
    this.opening = '',
    this.sceneDetail = '',
    this.dialogue = '',
    this.mess = '',
    this.innerThought = '',
    this.endingBeat = '',
    this.keepMoralOffScreen = false,
  });

  bool get hasAnyContent =>
      title.isNotEmpty ||
      hook.isNotEmpty ||
      mainIdea.isNotEmpty ||
      problem.isNotEmpty ||
      lesson.isNotEmpty ||
      caption.isNotEmpty ||
      imagePrompt.isNotEmpty ||
      script.isNotEmpty ||
      dialogue.isNotEmpty ||
      endingBeat.isNotEmpty;

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
    opening: readKey('Opening'),
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
    sceneDetail: _sectionText(sections, ['scene detail', 'scene']),
    dialogue: _sectionText(sections, ['dialogue', 'dialog']),
    mess: _sectionText(sections, ['mess']),
    innerThought: _sectionText(sections, ['inner thought', 'inner', 'thought']),
    endingBeat: _sectionText(sections, ['ending beat', 'ending']),
    keepMoralOffScreen: readKey('Keep Moral Off Screen').toLowerCase() == 'true',
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