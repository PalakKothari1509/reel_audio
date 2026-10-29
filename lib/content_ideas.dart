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

  /// Human-readable title for lists, search, and anywhere an id would be
  /// unreadable. Defaults to the cover text when not set separately.
  final String title;

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

  /// Ready-to-use 30-second viral Reel prompt (Part 1 + Part 2 + Part 3 + on-screen text).
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
    this.title = '',
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
    String? title,
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
        title: title ?? this.title,
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
        'title': title,
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
        title: j['title'] as String? ?? '',
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
  'Safety',
  'Learning Lesson',
  'Child Chaos',
  'Ria Chaos',
  'Funny',
  'Festivals',
  'Navratri',
  'Diwali',
  'Series',
];

/// Kids Safety hooks for the shield collection.
/// Each carries a full storyDetail with the Story/Twist/Resolution/Moral
/// labels the offline generator expects.
final kSafetyHooks = <HookIdea>[
// NEEDS EXPERT REVIEW before posting
HookIdea(
    id: 'idea_1',
    category: 'Safety',
    cover: 'Meri Marzi!',
    title: 'Meri Marzi!',
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
Story: At Daadi's house, relatives gather. Daadi opens her arms: "Ria, hug? Ek pappi toh banti hai!" Ria feels the pressure — everyone's eyes are on her. She steps back, hides behind Mumma: "Nahi, mujhe hug nahi chahiye."
Twist: An aunt insists: "Arre beta, itna bhi kya sharm? Daadi pyaar karte hain!" Mumma steps in calmly: "Beta, Ria ne mana kiya. Uske liye kaafi hai." Mumma turns to Ria: "Wave, high-five, ya kuch bhi nahi — tum choose karo." Ria gives a small wave from beside Mumma, shoulders relaxing.
Resolution: Daadi smiles: "Wave bhi accha hai." End card: "Pyaar karne ke liye hug zaroori nahi. Ria ki marzi bhi zaroori hai."
Moral: Body autonomy starts with a simple "no thank you" — and adults who respect it.
''',
    setting: 'Daadi\'s living room, afternoon light, family gathering',
    sceneDetail: 'Daadi with open arms, Ria hiding behind Mumma\'s saree, aunt leaning in with expectant smile',
    dialogue: '"Ria, hug? Ek pappi toh banti hai!" "Nahi, mujhe hug nahi chahiye."',
    mess: 'Relatives keep insisting — "Arre beta, itna bhi kya sharm?" — the pressure builds',
    innerThought: 'I need to show Ria that her "no" has power, without making her fear all touch.',
    endingBeat: 'Daadi accepts the wave. Ria breathes easy. Mumma squeezes her hand — "Main tumhare saath hoon."',
    defaultCast: ['Ria', 'Mumma', 'Daadi'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Daadi's living room, afternoon light, family gathered for a visit. Daadi opens her arms: "Ria, hug? Ek pappi toh banti hai!" Ria steps back, hides behind Mumma's saree: "Nahi, mujhe hug nahi chahiye." Text on screen: "MERI MARZI! 🙅" "NO THANK YOU IS ENOUGH ❤️"

On-Screen Text:
- [0-3s]: "HUG TIME? 🤗"
- [3-7s]: "RIA: NAHI CHAHIYE! 🙅"
- [7-12s]: "PRESSURE BUILDS 😳"
- [12-16s]: "CHOOSE YOUR OWN WAY 💪"
- [16-20s]: "WAVE BHI ACCHA HAI! 👋"

Part 1 (0-10s): 3D Pixar style, 9:16. Daadi opens her arms for a hug. Ria steps back behind Mumma's saree: "Nahi, mujhe hug nahi chahiye." An aunt leans in: "Arre beta, itna bhi kya sharm?" Text: "HUG TIME? 🤗" "RIA: NAHI CHAHIYE! 🙅" "PRESSURE BUILDS 😳"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma steps in calmly: "Beta, Ria ne mana kiya. Uske liye kaafi hai." She turns to Ria: "Wave, high-five, ya kuch bhi nahi — tum choose karo." Ria gives a small wave from beside Mumma, shoulders relaxing. Text: "CHOOSE YOUR OWN WAY 💪"

Audio/Dialogue (Hinglish): Daadi: "Ria, hug? Ek pappi toh banti hai!" Ria: "Nahi, mujhe hug nahi chahiye." Aunt: "Arre beta, itna bhi kya sharm?" Mumma: "Ria ne mana kiya. Uske liye kaafi hai. Wave, high-five, ya kuch bhi nahi — tum choose karo." Ria waves. Daadi: "Wave bhi accha hai."

Part 3 (20-30s): 3D Pixar style, 9:16. Daadi smiles and accepts the wave. Ria's shoulders relax, and Mumma squeezes her hand: "Main tumhare saath hoon." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Pyaar karne ke liye hug zaroori nahi — Ria ki marzi bhi zaroori hai. Body autonomy starts with a simple "no thank you," and adults who respect it.
''',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'idea_2',
    category: 'Safety',
    cover: 'Chocolate Ke Badle Kya? 🍫',
    title: 'Chocolate Ke Badle Kya? 🍫',
    opening: 'Park mein ek anjaan aadmi ne Ria ko chocolate di… Ria kya karegi?',
    problem: 'An unknown adult offers Ria chocolate and asks her to go with him for more, without Mumma\'s permission.',
    lesson: 'Do not accept unexpected treats or go anywhere with someone without your trusted adult\'s permission. Say "Nahi, thank you" if safe. Move away and immediately tell a trusted adult. If the adult persists or you cannot find your trusted adult, seek help from a safe, staffed place or another trusted adult. Unsafe behaviour can come from familiar people too — not every stranger is dangerous, and not every familiar person is safe.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'अनजान व्यक्ति chocolate देकर बुलाए तो "नहीं, पहले मम्मी से पूछूँगी" कहकर दूर हट जाओ। फ़ौरन मम्मी, पापा या टीचर को बताओ। कोई पीछा करे तो सुरक्षित जगह या दूसरे भरोसेमंद adult के पास जाओ। हर अनजान खतरनाक नहीं, पर हर जानकार भी सुरक्षित नहीं। #StrangerSafety #ChildSafety #ParentingTips #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At the society park, a man Ria doesn't know offers her chocolate and says, "Mere saath chalo, aur chocolate milegi." Ria remembers Mumma's rule.
Twist: Ria says, "Nahi, main Mumma se poochhe bina nahi loongi." She moves away instead of following him.
Resolution: Ria goes straight to Mumma and explains what happened. Mumma praises her for coming to tell her and explains that she should never leave with anyone without permission, even if she knows that person.
Moral: Pehle trusted adult se poochho. Unsafe lage toh door jao aur help maango.
''',
    setting: 'Society park, evening, strangers nearby',
    sceneDetail: 'A man offering a wrapped chocolate bar to Ria',
    dialogue: '"Mere saath chalo, aur chocolate milegi." "Nahi, main Mumma se poochhe bina nahi loongi."',
    mess: 'The man takes a step closer, waiting — Ria takes two steps back, looking toward Mumma',
    innerThought: 'Ria remembers the rule: ask a trusted adult before taking anything or going anywhere.',
    endingBeat: 'Ria runs to Mumma: "Mumma! Anjaan uncle ne chocolate di, maine mana kar diya." Mumma hugs her: "Bahut badhiya kiya beta."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Society park, evening, strangers nearby. A man Ria doesn't know holds out a wrapped chocolate bar: "Mere saath chalo, aur chocolate milegi." Ria takes two steps back. Text on screen: "CHOCOLATE KE BADLE KYA? 🍫" "NAHI, PEHLE POOCHUNGI! 🙅"

On-Screen Text:
- [0-3s]: "ANJAAN UNCLE + CHOCOLATE 🍫"
- [3-7s]: "RIA STEPS BACK 🙅"
- [7-12s]: "NAHI, MUMMA SE POOCHUNGI! 🗣️"
- [12-16s]: "MOVE AWAY, TELL MUMMA 🏃"
- [16-20s]: "BAHUT BADHIYA KIYA! ❤️"

Part 1 (0-10s): 3D Pixar style, 9:16. The man offers chocolate: "Mere saath chalo, aur chocolate milegi." Ria takes two steps back, looking toward Mumma: "Nahi, main Mumma se poochhe bina nahi loongi." Text: "ANJAAN UNCLE + CHOCOLATE 🍫" "RIA STEPS BACK 🙅"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria moves further away and runs to Mumma instead of following him. Text: "NAHI, MUMMA SE POOCHUNGI! 🗣️" "MOVE AWAY, TELL MUMMA 🏃"

Audio/Dialogue (Hinglish): Man: "Mere saath chalo, aur chocolate milegi." Ria: "Nahi, main Mumma se poochhe bina nahi loongi." Ria running: "Mumma! Anjaan uncle ne chocolate di, maine mana kar diya." Mumma: "Bahut badhiya kiya beta."

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma hugs Ria tight: "Bahut badhiya kiya beta." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Pehle trusted adult se poochho. Unsafe lage toh door jao aur help maango — unsafe behaviour can come from familiar people too, not just strangers.
''',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'idea_3',
    category: 'Safety',
    cover: 'Ruko, Dekho, Chalo! 🚦',
    title: 'Ruko, Dekho, Chalo! 🚦',
    opening: 'Rio ki ball sadak ke paas chali gayi… kya woh uske peeche bhaagega?',
    problem: 'Young children may impulsively chase a ball or toy toward a road without recognizing the danger.',
    lesson: 'Never chase a ball into the road. Stop at a safe distance and immediately call a trusted adult. Young children must cross roads with an adult holding their hand, using a safe designated crossing when available. Looking both ways does not replace adult supervision.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'कभी भी ball या toy ke peeche sadak par na bhaagen. Ruko, bade ko bulao, aur unka haath pakad kar hi road cross karo. Sadak cross karte waqt bade ka haath hamesha pakad kar rakho — signal green bhi ho toh bhi. #RoadSafety #ChildSafety #ParentingTips #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: "Mat" ki jagah ek clear "do" do — "Ungli pakdo, saath cross karo".',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio and Papa are walking near a society park. Rio's ball rolls toward the roadside. Rio starts moving toward it but stops when Papa says, "Ruko, Rio! Road ke paas mat jao."
Twist: Rio wants to retrieve the ball, but remembers to stay beside Papa and calls him instead.
Resolution: Papa keeps Rio safely away from traffic and retrieves the ball only when safe. They practise stopping, holding hands, and crossing together at a designated crossing.
Moral: Ball ke peeche sadak par nahi bhaagna. Road cross karte waqt bade ka haath pakadna.
''',
    setting: 'Society park footpath near a quiet road, late afternoon',
    sceneDetail: 'A red ball resting on the grass verge, a few metres from the road edge',
    dialogue: '"Ruko, Rio! Road ke paas mat jao." "Papa, ball!" "Main laata hoon, tum yahan rukho."',
    mess: 'Rio steps toward the road edge but freezes when Papa calls out — the ball is just out of reach',
    innerThought: 'One impulsive step toward the road can change everything. The habit of stopping must be stronger than the urge to chase.',
    endingBeat: 'Papa retrieves the ball safely. Rio holds Papa\'s hand, they walk to the crossing together, and cross with Papa\'s hand firmly in his.',
    defaultCast: ['Rio', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Society park footpath near a quiet road, late afternoon. Rio's red ball rolls toward the road edge. Rio steps toward it. Papa: "Ruko, Rio! Road ke paas mat jao." Text on screen: "RUKO, DEKHO, CHALO! 🚦" "BALL KE PEECHE MAT BHAAGO! ❌"

On-Screen Text:
- [0-3s]: "BALL ROLLS TOWARD ROAD 🔴"
- [3-7s]: "RUKO, RIO! ✋"
- [7-12s]: "PAPA LAATA HAI 🏃"
- [12-16s]: "UNGLI PAKDO ✅"
- [16-20s]: "SAATH CROSS KARO 🤝"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio's ball rolls toward the road edge. Rio steps toward it, freezing when Papa calls: "Ruko, Rio! Road ke paas mat jao." Rio: "Papa, ball!" Papa: "Main laata hoon, tum yahan rukho." Text: "BALL ROLLS TOWARD ROAD 🔴" "RUKO, RIO! ✋"

Part 2 (10-20s): 3D Pixar style, 9:16. Papa checks for traffic, retrieves the ball safely. They practise together: stop, hold hands, walk to the designated crossing. Text: "PAPA LAATA HAI 🏃" "UNGLI PAKDO ✅"

Audio/Dialogue (Hinglish): Papa: "Ruko, Rio! Road ke paas mat jao." Rio: "Papa, ball!" Papa: "Main laata hoon, tum yahan rukho." Rio: "Theek hai, Papa." Papa: "Chalo, haath pakdo — saath cross karenge."

Part 3 (20-30s): 3D Pixar style, 9:16. Papa retrieves the ball, holds Rio's hand firmly, and they cross together at the designated crossing. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Ball ke peeche sadak par nahi bhaagna. Road cross karte waqt bade ka haath hamesha pakadna — looking both ways does not replace adult supervision.
''',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'idea_4',
    category: 'Safety',
    cover: 'Ria Ka Safety Song 🎵',
    title: 'Ria Ka Safety Song 🎵',
    opening: 'Agar Ria Mumma se bichhad jaaye, toh help kaise maangegi?',
    problem: 'A preschooler may become confused when separated from a parent in a crowded public place.',
    lesson: 'Practise the child\'s full name, a trusted parent\'s phone number, and how to seek help from a designated trusted adult. Children should not be expected to manage emergencies alone.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'बच्चों को अपना पूरा नाम, भरोसेमंद adult का नंबर और help kaise maangni hai, ye practise karayein. India ka emergency number 112 hai. Lost child plan ghar pe hi bana lo. #EmergencySafety #ChildSafety #ParentingTips #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Emergency number yaad rakhne ke liye ek song banayein — rhythm yaad rahega!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At home, Papa turns safety practice into a simple clapping song. Ria practises saying her full name and repeating a trusted parent's phone number with Papa's help.
Twist: Papa asks, "Agar bheed mein Mumma dikhai na dein, toh kya karogi?" Ria answers, "Main yahin rukungi aur safe adult se help maangungi."
Resolution: Papa explains the family's agreed safety plan, including which adults to approach and how to ask for help. They practise together.
Moral: Naam yaad karo, trusted adult ka number practise karo, aur bichhad jao toh help maango.
''',
    setting: 'Living room, afternoon, Papa and Ria sitting together',
    sceneDetail: 'Papa clapping a rhythm, Ria repeating her name and a pretend phone number',
    dialogue: '"Ria, apna pura naam bolo." "Ria Sharma." "Aur trusted adult ka number?" "XXXXXXXXXX."',
    mess: 'Ria mixes up the digits at first, Papa gently corrects and they try again',
    innerThought: 'The rhythm makes it stick — safety can be playful, not scary.',
    endingBeat: 'Papa and Ria high-five after nailing the song twice. "Ab bichhad jao toh kya karogi?" "Rukungi, help maangungi."',
    defaultCast: ['Ria', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, afternoon, Papa and Ria sitting together clapping a rhythm. Papa: "Ria, apna pura naam bolo." Ria: "Ria Sharma." Text on screen: "RIA KA SAFETY SONG 🎵" "NAAM + NUMBER PRACTISE! 👏"

On-Screen Text:
- [0-3s]: "SAFETY SONG TIME! 🎵"
- [3-7s]: "APNA NAAM BOLO 🗣️"
- [7-12s]: "TRUSTED NUMBER YAAD KARO 📞"
- [12-16s]: "BHEED MEIN KYA KARO? 🤔"
- [16-20s]: "RUKUNGI, HELP MAANGUNGI! ⭐"

Part 1 (0-10s): 3D Pixar style, 9:16. Papa claps a rhythm. Ria repeats: "Ria Sharma." Papa: "Aur trusted adult ka number?" Ria mixes up the digits, Papa gently corrects, they try again. Text: "SAFETY SONG TIME! 🎵" "APNA NAAM BOLO 🗣️"

Part 2 (10-20s): 3D Pixar style, 9:16. Papa asks: "Agar bheed mein Mumma dikhai na dein, toh kya karogi?" Ria answers: "Main yahin rukungi aur safe adult se help maangungi." Text: "BHEED MEIN KYA KARO? 🤔" "RUKUNGI, HELP MAANGUNGI! ⭐"

Audio/Dialogue (Hinglish): Papa: "Ria, apna pura naam bolo." Ria: "Ria Sharma." Papa: "Aur trusted adult ka number?" Ria: "XXXXXXXXXX." Papa: "Agar bheed mein Mumma dikhai na dein, toh kya karogi?" Ria: "Main yahin rukungi aur safe adult se help maangungi."

Part 3 (20-30s): 3D Pixar style, 9:16. Papa and Ria high-five after nailing the song twice. "Ab bichhad jao toh kya karogi?" "Rukungi, help maangungi." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Naam yaad karo, trusted adult ka number practise karo, aur bichhad jao toh wahin ruk kar help maango. Children should never be expected to manage emergencies alone.
''',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'idea_5',
    category: 'Safety',
    cover: 'Mumma Ka Haath Chhoota… Ria Kahan Gayi? 😰',
    title: 'Mumma Ka Haath Chhoota… Ria Kahan Gayi? 😰',
    opening: 'Bas ek beautiful outfit dekhne aage gayi thi Ria… phir Mumma nahi dikhi! 😰',
    problem: 'During Diwali shopping, Ria spots a beautiful festive outfit displayed outside a clothing shop. While Mumma is busy checking prices and talking to the shopkeeper, Ria takes a few steps towards the display. When she turns around, she cannot see Mumma in the crowded market.',
    lesson: 'If a child becomes separated from their parent in a crowded place, they should stay where they are and seek help from a staff member at a nearby counter or a uniformed security guard. They should not wander around searching. Follow the family\'s safety plan.',
    postFormat: 'Reel',
    strategy: 'Uses a familiar festive-shopping distraction, an emotional turning point when Ria realizes Mumma is gone, and a practical safety lesson — stay put and seek help from staff instead of wandering.',
    caption: 'Diwali shopping mein bachche beautiful outfits, toys, decorations dekhke distract ho sakte hain. Crowded market mein jaane se pehle unhe batao: "Mumma na dikhein toh wahi ruko aur staff se help maango." Ye simple plan ghar pe practise karo. #DiwaliShopping #ChildSafety #LostChild #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: "Pehle mera, phir tera" rule lao — turn timer se share karo.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma and Ria are shopping in a busy Diwali market. Mumma is checking the price of diyas at a nearby stall. Ria notices a beautiful lehenga displayed at a clothing shop and takes a few steps closer to see its sparkling details. When she turns around, Mumma is no longer visible in the crowd.

Twist: Ria becomes worried but remembers Mumma's safety rule — she stays where she is instead of wandering through the market. She approaches a staff member at the nearest shop counter and asks for help.

Resolution: The staff member follows the shop's child-safety procedure and helps contact Mumma. Mumma reunites with Ria, comforts her, and calmly explains that they will practise their safety plan before future crowded outings.

Moral: Mumma na dikhein toh wahi ruko, staff se help maango.
''',
    setting: 'A busy Indian Diwali market in the early evening, with festive clothing displays, shoppers, diya stalls, and warm decorative lights.',
    sceneDetail: 'Ria admires a beautiful festive lehenga displayed outside a clothing shop while Mumma is briefly occupied at a nearby shopping stall. Ria turns around and realizes she cannot see Mumma.',
    dialogue: '"Ria, beta, yahin mere paas rehna." "Mumma? Aap kahan ho?" "Mujhe Mumma nahi mil rahi. Please help kariye." "Ria, tum mil gayi! Dar gayi thi na? Chalo, hum apna safety plan phir se yaad karte hain."',
    mess: 'Ria becomes distracted by the beautiful outfit, moves a few steps away, and then cannot see Mumma in the crowded market.',
    innerThought: 'Woh bas outfit dekhne ruki thi… aur ab Mumma nazar nahi aa rahi!',
    endingBeat: 'Ria reunites with Mumma at the shop counter. Mumma comforts her. End with a clear visual safety reminder: "Bheed mein bichhad jao toh wahi ruko aur staff se help maango."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. A busy Indian Diwali market, early evening, festive clothing displays and diya stalls glowing. Ria admires a sparkling lehenga outside a shop while Mumma checks diya prices nearby. Ria turns around — Mumma is gone. Text on screen: "MUMMA KAHAN GAYI?! 😰" "WAHIN RUKO, HELP MAANGO! 🙋"

On-Screen Text:
- [0-3s]: "BEAUTIFUL OUTFIT! ✨"
- [3-7s]: "MUMMA KAHAN GAYI?! 😰"
- [7-12s]: "WAHIN RUKO! 🛑"
- [12-16s]: "STAFF SE HELP MAANGO 🙋"
- [16-20s]: "MUMMA MIL GAYI! ❤️"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria steps closer to admire a lehenga display. Mumma is a few steps away checking prices. Ria turns around — the crowd has swallowed Mumma from view. "Mumma? Aap kahan ho?" Text: "BEAUTIFUL OUTFIT! ✨" "MUMMA KAHAN GAYI?! 😰"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria remembers the family's rule — she stays put instead of wandering, and walks to the nearest shop counter: "Mujhe Mumma nahi mil rahi. Please help kariye." The staff member helps. Text: "WAHIN RUKO! 🛑" "STAFF SE HELP MAANGO 🙋"

Audio/Dialogue (Hinglish): Ria: "Mumma? Aap kahan ho?" Ria to staff: "Mujhe Mumma nahi mil rahi. Please help kariye." Mumma arriving: "Ria, tum mil gayi! Dar gayi thi na?"

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma reunites with Ria at the counter and comforts her: "Chalo, hum apna safety plan phir se yaad karte hain." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Bheed mein bichhad jao toh wahin ruko aur staff se help maango — not wander around searching.
''',
  ),

  // NEEDS EXPERT REVIEW before posting
  HookIdea(
    id: 'idea_6',
    category: 'Safety',
    cover: 'Rasoi Mein Ruko, Ria!',
    title: 'Rasoi Mein Ruko, Ria!',
    opening: 'Mumma gas par khana bana rahi thi… aur Ria apni car lekar rasoi mein aa gayi!',
    problem: 'Ria wants to stay near Mumma and brings her toy into the kitchen while Mumma is cooking. Hot cookware and the active stove create a genuine hazard.',
    lesson: 'Young children must stay out of the cooking area while cooking is underway. Floor markings are not a safety barrier. Adults must supervise children and prevent access to hot stoves, cookware, boiling liquids, and other kitchen hazards. Create a safe play space away from the kitchen during cooking.',
    postFormat: 'Reel',
    strategy: 'Shows the real danger of a child entering an active cooking area, a calm parent redirecting the child, and the practical solution of creating a safe play space away from the stove.',
    caption: 'Bachche cooking area se door rahen jab gas chalu ho. Kitchen se door safe play space bana lo. Floor pe line kaafi nahi — bade ki supervision zaroori hai. #KitchenSafety #ChildSafety #ParentingTips #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Gaadi aane se pehle ek signal lelo — haath pakad kar khade raho, jab tak nahi aayi.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma is preparing lunch on the gas stove. Ria enters the kitchen with her toy car and asks to play beside Mumma.
Twist: Mumma notices Ria near the cooking area, stops what she is doing when safe, and guides Ria out of the kitchen.
Resolution: Mumma sets up a simple play activity in a safe area away from the kitchen. She explains gently, "Jab gas par khana banta hai, tum kitchen ke bahar khelo. Main tumhare paas aakar khelungi."
Moral: Garam rasoi se door raho. Cooking ke waqt bade ki safety rules follow karo.
''',
    setting: 'Kitchen, midday, gas stove with active cooking',
    sceneDetail: 'Ria standing at the kitchen entrance with a toy car, Mumma at the stove with a pot simmering',
    dialogue: '"Mumma, main bhi khelungi yahan!" "Ria, beta, kitchen mein gas chalu hai. Bahar khelo, main aati hoon."',
    mess: 'Ria inches closer to the stove with her car, Mumma turns and sees her just before the hot zone',
    innerThought: 'The kitchen feels warm and inviting, but the stove is no place for a toddler — even for a minute.',
    endingBeat: 'Mumma lifts Ria out, sets up blocks in the living room, and joins her. "Yahan safe hai, Ria."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen, midday, gas stove with a pot simmering. Ria enters with her toy car: "Mumma, main bhi khelungi yahan!" Mumma: "Ria, beta, kitchen mein gas chalu hai. Bahar khelo, main aati hoon." Text on screen: "RASOI MEIN RUKO, RIA! 🚫" "FLOOR LINE KAAFI NAHI, SUPERVISION ZAROORI 👀"

On-Screen Text:
- [0-3s]: "RIA BRINGS HER CAR IN 🚗"
- [3-7s]: "GAS CHALU HAI! 🔥"
- [7-12s]: "BAHAR KHELO 🚫"
- [12-16s]: "SAFE PLAY SPACE 🧱"
- [16-20s]: "YAHAN SAFE HAI! ✅"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria enters the kitchen with her toy car, inching toward the stove. Mumma: "Ria, beta, kitchen mein gas chalu hai. Bahar khelo, main aati hoon." Text: "RIA BRINGS HER CAR IN 🚗" "GAS CHALU HAI! 🔥"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma lifts Ria out of the kitchen and sets up blocks in the living room instead. Text: "BAHAR KHELO 🚫" "SAFE PLAY SPACE 🧱"

Audio/Dialogue (Hinglish): Ria: "Mumma, main bhi khelungi yahan!" Mumma: "Ria, beta, kitchen mein gas chalu hai. Bahar khelo, main aati hoon." Ria: "Theek hai, Mumma." Mumma: "Yahan safe hai, Ria."

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma joins Ria with the blocks in the living room, well away from the stove. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Young children must stay out of the cooking area while cooking is underway — floor markings are not a safety barrier, adult supervision is.
''',
  ),

];

/// The starting list. Merged from several AI suggestions and cut down hard: the same
/// three problems (screen time, shoes, toy fights) appeared four or five times each,
/// and several were written as "I" — a parent speaking — when the reels are told by a
/// storyteller about Ria and Rio.
/// Combined hooks list with safety hooks appended.
List<HookIdea> buildDefaultHooks() {
  final list = <HookIdea>[
    // Relatable: the child's own words, the thing every parent has heard this week.
HookIdea(
    id: 'idea_7',
    category: 'Ria Chaos',
    cover: 'Main Khud! 👟',
    title: 'Main Khud! 👟',
    opening: 'Mumma bas joota pehnane lagi… Ria boli, "MAIN KHUD!" 😤',
    problem: 'Ria insists on putting on her own shoes while the family is getting ready to leave.',
    lesson: 'Give children age-appropriate opportunities to practise independence, allow reasonable time, and offer gentle help when needed.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Preschool ke time pe bachche "main khud!" bolte hain toh dil khush bhi hota hai aur tension bhi hoti hai. Thoda time do, try karne do, zaroorat pade toh pyaar se help karo. 👟 #Independence #ToddlerLife #ParentingHacks #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Time teller ke liye ek simple song ya rhyme banayein!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: It is time to leave for preschool. Mumma bends down to help Ria put on her shoes. Ria pulls her feet back and declares, "Main khud!"
Twist: Ria tries to put on a shoe but gets confused about which foot it belongs on. Mumma pauses and asks gently, "Ek baar phir try karogi, ya meri help chahiye?"
Resolution: Ria checks the shoes, corrects the mistake, and puts them on successfully. Mumma smiles: "Tumne khud try kiya! Shabash." They leave together.
Moral: Khud try karne do. Zaroorat ho toh pyaar se help karo.
''',
    setting: 'Front door area, morning, shoes by the mat',
    sceneDetail: 'A pair of small shoes by the door, Ria sitting down to put them on',
    dialogue: '"Main khud!" "Ek baar phir try karogi, ya meri help chahiye?"',
    mess: 'Ria puts a shoe on the wrong foot, pauses, then looks at the other shoe and self-corrects',
    innerThought: 'Let her try. If she asks, I\'ll help. Either way, she learns.',
    endingBeat: 'Ria puts on both shoes correctly, stands up proud. Mumma gives a quick hug. "Chalo, chalte hain."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Front door area, morning light. Ria (pink star dress, pigtails) sitting by the door, determined: "Main khud!" Mumma (yellow kurti, top bun) starts to help, pauses, smiles: "Ek baar phir try karogi?" Ria looks at the shoes, realizes one is on the wrong foot, switches them, puts both on correctly. Text: "MAIN KHUD! 👟" "TRY KARNE DO" "SHABASH! 🥹❤️"

On-Screen Text:
- [0-3s]: "MAIN KHUD! 👟"
- [3-7s]: "TRY KARNE DO ⏳"
- [7-12s]: "SELF-CORRECT! 💡"
- [12-17s]: "SHABASH! 🥹❤️"
- [17-20s]: "PATIENCE + TRUST = GROWTH 🌱"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria pushes Mumma's hand away at the door, "Main khud!" Mumma steps back, watches. Ria puts shoe on wrong foot, pauses, realizes, switches feet. Text: "MAIN KHUD! 👟" "TRY KARNE DO ⏳". Ria: "Main khud!" Mumma: "Ek baar phir try karogi?"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria corrects the shoe, puts both on right feet, beams with pride. Text: "SELF-CORRECT! 💡" "SHABASH! 🥹❤️". Mumma hugs: "Tumne khud try kiya! Shabash." Both walk out together.

Audio/Dialogue (Hinglish): Ria determined: "Main khud!" Mumma gentle: "Ek baar phir try karogi?" Ria happy: "Ho gaya! Main khud pehen li!" Mumma proud: "Shabash beta!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria puts on both shoes correctly, stands up proud. Mumma gives a quick hug. "Chalo, chalte hain." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Give children age-appropriate opportunities to practise independence, allow reasonable time, and offer gentle help when needed.

''',
  ),
HookIdea(
    id: 'idea_8',
    category: 'Ria Chaos',
    cover: 'Bas 5 Minute Aur?! 📱',
    title: 'Bas 5 Minute Aur?! 📱',
    opening: 'Cartoon beech mein band hua... aur Ria ka rona shuru! 😭',
    problem: 'Ria cries when a cartoon ends mid-song without warning — she needs a predictable transition.',
    lesson: 'A two-minute warning before the agreed stopping point helps Ria choose a calm goodbye. A timer can support the transition but does not guarantee zero tears.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Cartoon beech mein band hua toh rona lena laga. Do minute pehle batado, timer laga do — transition smooth hota hai. Tears kam honge, khatam nahi. 📱 #ScreenTime #TransitionHack #ToddlerEmotions #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Screen time se pehle ek countdown lelo — "5 se 1, phir screen band"! ',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cartoon credits start rolling mid-song. Ria points at the screen: "Wapas! Wapas!" Tears fall. Mumma realises the episode ended mid-song with no warning.
Twist: Next day, Mumma asks, "Ye episode kab khatam hoga?" She sets a visual timer for two minutes before the end. When the timer dings: "Abhi do minute, phir bye-bye."
Resolution: Episode ends. Ria blows a kiss at the screen: "Bye-bye cartoon!" Hands the phone to Mumma. "Kal timer pehle lagayenge."
Moral: Beech mein nahi, khatam hone par — par pehle se batana bhi badi baat hai.
''',
    setting: 'Living room, late afternoon, phone propped on the armrest playing a cartoon',
    sceneDetail: 'Cartoon credits rolling mid-song, phone face-up on the armrest, Ria reaching for it',
    dialogue: '"Bas five minute aur!" "Ye episode kab khatam hoga?" "Abhi do minute, phir bye-bye." "Bye-bye cartoon!"',
    mess: 'Screen pauses mid-song, credits rolling in background, Ria reaches for the phone with tears',
    innerThought: 'Main kab tak ye gaana sun sakti hoon, until even the humming stops. Warning helps — but it is not a magic wand.',
    endingBeat: 'Ria blows a kiss at the phone, then lets the screen go dark. Mumma: "Timer pehle lagayenge kal."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room couch, afternoon light, phone playing cartoon. Ria (sparkly pink star dress, pigtails) suddenly cries, tiny fists shaking. Phone shows credits mid-song. Ria points: "Wapas! Wapas!" Text on screen: "CARTOON BEICH MEIN BAND... 📱" "😭 RONA SHURU!"

On-Screen Text:
- [0-3s]: "CARTOON BEICH MEIN BAND 📱"
- [3-7s]: "RONA SHURU! 😭"
- [7-12s]: "NEXT TIME: 2 MIN WARNING ⏰"
- [12-16s]: "TIMER DING = BYE-BYE 🔔"
- [16-20s]: "WARNING HELPS, NOT MAGIC ✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria cries on the couch, tears pointing at the phone screen showing cartoon credits mid-song. Text: "CARTOON BEICH MEIN BAND 📱" "😭 RONA SHURU!" Mumma looks up from her tea: "Arre, episode beech mein khatam ho gaya!"

Part 2 (10-20s): 3D Pixar style, 9:16. Next day: Mumma sets a visual timer on the phone. Timer dings: "Abhi do minute, phir bye-bye!" Ria blows a kiss at the screen: "Bye-bye cartoon!" Hands phone to Mumma. Text: "NEXT TIME: 2 MIN WARNING ⏰" "TIMER DING = BYE-BYE 🔔" "WARNING HELPS, NOT MAGIC ✨"

Audio/Dialogue (Hinglish): Ria wailing: "Nahi nahi! Wapas chahiye!" Mumma gentle: "Beta, yeh episode kal bhi chalega." Ria still sniffling: "Par aaj nahi!" Mumma: "Theek hai, 2 minute warning se hi shuru karein ge." Next day — timer dings: Ria happy: "Bye-bye cartoon!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria blows a kiss at the phone, then lets the screen go dark. Mumma: "Timer pehle lagayenge kal." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A two-minute warning before the agreed stopping point helps Ria choose a calm goodbye. A timer can support the transition but does not guarantee zero tears.

''',
  ),

HookIdea(
    id: 'idea_9',
    category: 'Child Chaos',
    cover: 'Mujhse Nahi Hoga! 🧱',
    title: 'Mujhse Nahi Hoga! 🧱',
    opening: 'Teesri baar tower gira… Rio bola, "Mujhse nahi hoga!" 😔',
    problem: 'Rio feels genuinely frustrated after his block tower falls repeatedly. He is not being naughty — he just cannot figure out why it keeps collapsing.',
    lesson: 'When a child is stuck, offer a hint without taking over. Let them experiment, fail, and try again — that is how real learning happens.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Bachche ko frustration ho toh haath mat lagao — ek hint do, unhe khud dhundne do. Tower gira toh base bada karo. Seekhne ka maza usi mein hai. #Persistence #LearningThroughPlay #ToddlerPlay #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Har game se pehle ek simple rule samjho — "Yeh kaise khelnge" batao!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio builds a tower. It falls. He builds again — it falls again. Third time, he sits back, eyes welling up: "Mujhse nahi hoga!" He is not giving up to be difficult; he truly feels stuck.
Twist: Ria watches quietly, then asks, "Ek idea try karein?" She does not touch the blocks. Instead, she points: "Neeche ke blocks thode aur phailao, base bana ke dekho." Rio hesitates, then tries.
Resolution: Rio tries a wider base. It still wobbles. He adjusts, adds one more block at the bottom. The tower stands. He looks up, surprised and proud: "Khada hai!" Ria smiles: "Tune khud kiya."
Moral: Hint do, haath mat lagao. Bachcha khud seekhta hai — fail karke, try karke, phir safal hoke.
''',
    setting: 'Play mat in the living room, afternoon sunlight through the window',
    sceneDetail: 'A collapsed tower, scattered blocks, Rio sitting with knees pulled up looking defeated',
    dialogue: '"Mujhse nahi hoga!" "Ek idea try karein?" "Neeche ke blocks thode phailao." "Khada hai!"',
    mess: 'Rio tries the wider base, tower wobbles, he adjusts a block, tries again — frustration turning into focus',
    innerThought: 'The hardest thing for a parent is watching them struggle without fixing it. But that is exactly what they need.',
    endingBeat: 'Rio places the final block on his steady tower. Ria gives a small nod. Cuty hops over nearby, watching — the tower still stands.',
    defaultCast: ['Rio', 'Ria', 'Cuty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Play mat in living room. Rio builds a tower — it collapses. He rebuilds — collapses again. Third time, he slumps: "Mujhse nahi hoga!" Text: "TEESRI BAAR GIRA 😔" "MUJHSE NAHI HOGA"

On-Screen Text:
- [0-3s]: "TEESRI BAAR GIRA 😔"
- [3-6s]: "MUJHSE NAHI HOGA 😤"
- [6-10s]: "EK IDEA? 💡"
- [10-14s]: "BASE BADA KARO 🧱"
- [14-18s]: "KHUD SEEKHA! 🎉"
- [18-20s]: "HINT DO, HAATH MAT LAGAO 🌱"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio builds, tower falls. He tries again — falls. Third time, he gives up: "Mujhse nahi hoga!" Ria watches, then asks gently: "Ek idea try karein?" Points: "Neeche ke blocks phailao." Text: "MUJHSE NAHI HOGA 😤" then "EK IDEA? 💡"

Part 2 (10-20s): 3D Pixar style, 9:16. Rio tries wider base, wobbles, adjusts, adds block. Tower stands. Rio beams: "Khada hai!" Ria nods. Cuty hops over nearby, watches — tower holds. Text: "BASE BADA KARO 🧱" "KHUD SEEKHA! 🎉" "HINT DO, HAATH MAT LAGAO 🌱"

Audio/Dialogue (Hinglish): Rio frustrated: "Mujhse nahi hoga!" Ria calm: "Ek idea try karein? Neeche ke blocks thode phailao." Rio trying: "Hmm... base bada karo." Rio proud: "Khada hai!" Ria: "Tune khud kiya!" Cuty hops: *boop*

Part 3 (20-30s): 3D Pixar style, 9:16. Rio places the final block on his steady tower. Ria gives a small nod. Cuty hops over nearby, watching — the tower still stands. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: When a child is stuck, offer a hint without taking over. Let them experiment, fail, and try again — that is how real learning happens.

''',
  ),

HookIdea(
    id: 'idea_10',
    category: 'Child Chaos',
    cover: 'Cuty Gayab! Toys Ke Jungle Mein 😱',
    title: 'Cuty Gayab! Toys Ke Jungle Mein 😱',
    opening: 'Cuty gayab! Toys ke jungle mein Ria dhundh rahi hai 😱',
    problem: 'Cuty is missing in a living room buried under toys. Ria and Rio start searching together, clearing one area at a time.',
    lesson: 'When the room is a mess, clear one small area at a time and put each toy back in its proper place. Working together makes it faster — and the missing thing shows up when the clutter is gone.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Room messy ho toh Cuty bhi kho jata hai. Ek chhota area saaf karo, toys wapas rakho, aur milkar kaam karo. Cuty mil jayega! 🐰 #TidyUp #SiblingTeamwork #LostAndFound #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: "Pehle mera, phir tera" rule lao — turn timer se share karo.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria gasps, "Cuty kahan gaya?!" The living room floor is a toy jungle — blocks, cars, plushies everywhere. Ria and Rio start searching. Rio picks up a car: "Arre, mera blue car!" and starts vrooming it. Ria sighs, picks up a doll: "Wait, I was looking for Cuty!"
Twist: Ria says firmly, "Ruko. Ek chhota area saaf karte hain. Toys wapas unke box mein, phir Cuty dhundhte hain." They clear one corner together, putting blocks in the block bin, cars in the car basket. Under the couch, they spot Cuty's ears peeking out.
Resolution: They whisper, "Shhh, Cuty so raha hai!" They leave Cuty undisturbed. Then they finish tidying the rest of the room together — each toy finding its home.
Moral: Ek area saaf karo, toys wapas rakho, milkar kaam karo. Clutter door hua toh khoi hui cheez bhi mil jayegi.
''',
    setting: 'Living room floor, afternoon, toys scattered everywhere like a jungle',
    sceneDetail: 'Blocks, cars, plushies covering the floor; Cuty sleeping under the couch with ears visible',
    dialogue: '"Cuty kahan gaya?!" "Arre, mera blue car!" "Ruko, ek area saaf karte hain pehle." "Shhh, Cuty so raha hai!"',
    mess: 'Rio gets distracted by every toy he picks up — cars, blocks, dolls — while Ria tries to keep the search on track',
    innerThought: 'The mess is the problem. Fix the mess, and the missing thing appears.',
    endingBeat: 'They finish tidying together. Cuty wakes up, hops over, and nudges a block into the bin — helping too! Room clean, Cuty found.',
    defaultCast: ['Ria', 'Rio', 'Cuty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, toys everywhere like a jungle. Ria panics: "Cuty kahan gaya?!" Rio picks up a car, vrooms it. Ria: "Ruko, ek area saaf karte hain!" They clear one corner, toys go back in bins. Under the couch — Cuty's ears peek out. They whisper: "Shhh, Cuty so raha hai!" Text: "CUTY GAYAB?! 😱" "EK AREA SAAF KARO 🧸" "TOYS WAPAS RAKHO 📦" "MILKAR KAAM KARO 🤝" "CUTY MIL GAYA! 🐰"

On-Screen Text:
- [0-3s]: "CUTY GAYAB?! 😱"
- [3-6s]: "TOYS KE JUNGLE 🌴"
- [6-10s]: "EK AREA SAAF KARO 🧸"
- [10-14s]: "TOYS WAPAS RAKHO 📦"
- [14-18s]: "MILKAR KAAM KARO 🤝"
- [18-20s]: "CUTY MIL GAYA! 🐰"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria panics, room is a toy jungle. Rio distracted by car, vrooms it. Ria: "Ruko, ek area saaf karte hain!" They clear one corner. Text: "CUTY GAYAB?! 😱" "TOYS KE JUNGLE 🌴" "EK AREA SAAF KARO 🧸"

Part 2 (10-20s): 3D Pixar style, 9:16. They find Cuty under couch, whisper "Shhh!" Finish tidying together. Cuty hops over, nudges block into bin. Text: "TOYS WAPAS RAKHO 📦" "MILKAR KAAM KARO 🤝" "CUTY MIL GAYA! 🐰"

Audio/Dialogue (Hinglish): Ria urgent: "Cuty kahan gaya?!" Rio distracted: "Arre, mera blue car!" Ria firm: "Ruko, ek area saaf karte hain!" Both whisper: "Shhh, Cuty so raha hai!" Ria happy: "Room saaf, Cuty mil gaya!" Cuty hops: *boop*

Part 3 (20-30s): 3D Pixar style, 9:16. They finish tidying together. Cuty wakes up, hops over, and nudges a block into the bin — helping too! Room clean, Cuty found. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: When the room is a mess, clear one small area at a time and put each toy back in its proper place. Working together makes it faster — and the missing thing shows up when the clutter is gone.

''',
  ),

// Siblings: sharing, turn-taking, and the little wars between tiny humans
  // who share a room and a parent.
  HookIdea(
    id: 'idea_11',
    category: 'Child Chaos',
    cover: 'Mere Pair, Mera Game!',
    title: 'Mere Pair, Mera Game!',
    opening: 'Ek hi pair of shoes — Ria aur Rio dono ko pehne ki koshish!',
    problem: 'Only one pair of shoes available, but two siblings need to wear them',
    lesson: 'Share karne ka ek simple rule: timer se ek vyakti pehle pahengi, doosra agla round.',
    postFormat: 'Reel',
    strategy: 'Use a timer for sharing — clear rules prevent fights.',
    caption: 'Ek joota, do bachche — timer se share karo, fight kam karo! ⏱️ #SiblingSharing #TurnTaking #FunLearningWithPalak #IndianParents #ToddlerLife',
    pinnedComment: 'Timer trick try kari? "Gaana khatam, phir tumhari baari!"',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Only one pair of pink sparkly jootis by the door — Ria and Rio both grab for them.
Twist: Mumma: "Jisne pehle pehna, uski 1 minute. Phir switch." Ria: "Mere saath timer!" Mumma sets phone timer.
Resolution: Ria plays "princess walk" for 1 minute, then Rio gets his turn. Both laughing by the switch.
Moral: Clear timer, clear rules — no tears over sharing.
''',
    setting: 'Hallway, one pair of jootis by the door, morning rush',
    sceneDetail: 'Ria and Rio both pulling at the same jooti, Mumma holding a phone timer',
    dialogue: '"Mere pair!" "Mera pair!" "Timer shuru ho gaya!"',
    mess: 'Both grab the same jooti, tug-of-war begins until Mumma intervenes',
    innerThought: 'A timer works better than my pleading voice.',
    endingBeat: 'Rio does his "princess walk" with dramatic flair — both laughing.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Hallway, morning rush. One pair of pink sparkly jootis by the door. Ria (sparkly pink star dress, pigtails) and Rio (blue t-shirt, shorts) both grab for them. Mumma holds phone timer. Text on screen: "EKPairo SHOES 👟" "TIMER TRICK ⏱️" "PRINCESS WALK! 👸"

On-Screen Text:
- [0-3s]: "EK Joota, DO BACCHE 👟"
- [3-7s]: "TUG OF WAR 💪"
- [7-11s]: "TIMER SHURU! ⏱️"
- [11-15s]: "PRINCESS WALK 👸"
- [16-20s]: "SWITCH TIME! 🔄"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria and Rio tug at the same jooti: "Mere pair!" "Mera pair!" Mumma: "Jisne pehle pehna, uski 1 minute. Phir switch." Sets timer. Text: "EK Joota, DO BACCHE 👟" "TUG OF WAR 💪" "TIMER SHURU! ⏱️".

Part 2 (10-20s): 3D Pixar style, 9:16. Ria does a dramatic "princess walk" in the jootis, one minute left. Rio watches, giggling. Timer dings: "Time up, switch!" Text: "PRINCESS WALK 👸" "SWITCH TIME! 🔄".

Audio/Dialogue (Hinglish): Ria: "Mere pair!" Rio: "Mera pair!" Mumma: "Jisne pehle pehna, uski 1 minute." Ria: "Timer ke saath!" Rio: "Mere bhi ek minute!" Ria (princess): "Thumka!" Mumma: "Time up, switch!"

Part 3 (20-30s): 3D Pixar style, 9:16. Switch — Rio puts on jootis, does his own silly walk. Both laughing. Mumma: "See? No tears, just timer." Text: "SWITCH TIME! 🔄". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A clear timer and simple rule — one minute each, then switch — prevents fights and makes sharing fun. When expectations are fair, even toddlers can wait their turn.
''',
  ),

  HookIdea(
    id: 'idea_12',
    category: 'Ria Chaos',
    cover: 'Brush Ka Naam Sunte Hi Ria Kambal Mein Gayab! 🪥',
    title: 'Brush Ka Naam Sunte Hi Ria Kambal Mein Gayab! 🪥',
    opening: 'Brush ka naam sunte hi Ria kambal mein gayab! 🪥',
    problem: 'Ria resists toothbrushing and hides under the blanket. Mumma stays calm instead of rushing or scolding.',
    lesson: 'Playful modelling and patient support can make brushing easier, but not every child will cooperate immediately. Adult supervision and a pea-sized amount of fluoride toothpaste are essential.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Brush ke time pe Ria chhup gayi? Cuty ke daant brush karke dikhao, fir Ria khud try karegi. Pea-sized fluoride paste, bade ki supervision. 🪥 #BrushTime #ToddlerRoutine #ParentingHacks #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Time teller ke liye ek simple song ya rhyme banayein!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma says, "Brush time, Ria!" Ria pulls the blanket over her head: "Nahi!" Mumma stays calm, sits on the floor, and says, "Theek hai. Pehle Cuty ke daant saaf karte hain."
Twist: Mumma takes Cuty's toy teeth (plastic, no real toothbrush in mouth) and gently mimics brushing with a child-sized brush and a pea-sized dab of fluoride toothpaste. She narrates: "Upar, neeche, peeche — dhire dhire." Ria peeks out, curious.
Resolution: Ria pulls the blanket down: "Mere daant bhi?" Mumma hands her a child-sized brush with a pea-sized amount of fluoride paste. "Dhire dhire, upar neeche." Ria brushes; Mumma guides her hand for the back teeth. Ria spits into the sink. "Ho gaya!"
Moral: Khel-khel mein brush seekho. Bade ki madad se bachcha khud brush karta hai — par supervision zaroori hai.
''',
    setting: 'Bathroom, morning, mirror at child height, toothbrushes and fluoride toothpaste on the counter',
    sceneDetail: 'Ria peeking from under the blanket; Cuty sitting on the counter with toy teeth; child-sized brush and pea-sized fluoride paste ready',
    dialogue: '"Brush time, Ria!" "Nahi!" "Theek hai, pehle Cuty ke daant." "Upar, neeche, peeche — dhire dhire." "Mere daant bhi?" "Dhire dhire, upar neeche, peeche." "Ho gaya!"',
    mess: 'Ria hides under blanket, refuses brush. Mumma stays calm, demonstrates on Cuty\'s toy teeth. Ria watches, then asks to brush.',
    innerThought: 'Scolding makes it worse. A calm demo on a toy makes it a game she wants to join.',
    endingBeat: 'Ria spits, rinses, smiles at the mirror. Mumma wipes her chin. "Shining smile!" Cuty sits proudly on the counter.',
    defaultCast: ['Ria', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bathroom, child-height mirror. Ria under blanket: "Nahi!" Mumma calm on floor with Cuty. Demonstrates brushing on Cuty's toy teeth (plastic) with child brush, pea-sized fluoride paste. Narrates: "Upar, neeche, peeche." Ria peeks: "Mere daant bhi?" Text: "BRUSH KA NAAM... 🪥" "CUTY KE DAANT PEHLE 🦷" "AB MERI BAARI! 😁"

On-Screen Text:
- [0-3s]: "BRUSH TIME? CHHUPA GAYI! 😱"
- [3-6s]: "CUTY KE DAANT PEHLE 🦷"
- [6-10s]: "UPAR, NEECHE, PEECHE — DHEERE DHEERE 🪥"
- [10-14s]: "AB MERI BAARI! 😁"
- [14-18s]: "DHEERE DHEERE... SPIT! 💦"
- [18-20s]: "SHINING SMILE! ✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria hides under blanket: "Nahi!" Mumma sits with Cuty, mimics brushing on toy teeth with child brush, pea-sized fluoride paste. Narrates: "Upar, neeche, peeche — dhire dhire." Ria peeks: "Mere daant bhi?" Text: "BRUSH TIME? CHHUPA GAYI! 😱" "CUTY KE DAANT PEHLE 🦷" "UPAR NEECHE PEECHE 🪥"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria gets child brush with pea-sized fluoride paste. "Dhire dhire, upar neeche." Mumma guides hand for back teeth. Ria spits, smiles at mirror. Text: "AB MERI BAARI! 😁" "DHEERE DHEERE... SPIT! 💦" "SHINING SMILE! ✨"

Audio/Dialogue (Hinglish): Mumma gentle: "Brush time, Ria!" Ria: "Nahi!" Mumma calm: "Theek hai, pehle Cuty ke daant saaf karte hain." Mumma narrating: "Upar, neeche, peeche — dhire dhire." Ria curious: "Mere daant bhi?" Mumma: "Dhire dhire, upar neeche." Ria: "Ho gaya!" Mumma: "Shining smile!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria spits, rinses, smiles at the mirror. Mumma wipes her chin. "Shining smile!" Cuty sits proudly on the counter. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Playful modelling and patient support can make brushing easier, but not every child will cooperate immediately. Adult supervision and a pea-sized amount of fluoride toothpaste are essential.

    ''',
  ),

HookIdea(
    id: 'idea_13',
    category: 'Ria Chaos',
    cover: 'Broccoli Dekhte Hi Ria Ne Plate Se Doori Bana Li! 🥦',
    title: 'Broccoli Dekhte Hi Ria Ne Plate Se Doori Bana Li! 🥦',
    opening: 'Broccoli dekhte hi Ria ne plate se doori bana li! 🥦',
    problem: 'Ria refuses the broccoli on her plate. She pushes the plate away and crosses her arms.',
    lesson: 'Repeated low-pressure exposure and calm modelling can help children become familiar with foods, but acceptance is never guaranteed. Never pressure, bargain, or threaten.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Broccoli se Ria bhagi? Papa khud khake dikhaye, pressure nahi. Chhota piece offer kiya, Ria ne soongha, chhua — bite optional. Low-pressure exposure se familiarity aati hai. 🥦 #FoodExploration #PickyEater #ParentingHacks #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Bachcho ko meal banate waqt ek tiny helper bana kar involve karo!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Lunch is served. Broccoli sits on Ria's plate. She makes a face, pushes the plate away: "Nahi chahiye!"
Twist: Papa picks up a floret, takes a bite himself, and says naturally, "Crunchy hai, thoda kadwa bhi." He puts a small piece on the side of Ria's plate: "Chaho toh try karo, warna rehne do." No bargaining, no "ek bite toh lo."
Resolution: Ria stares at the piece. She picks it up, turns it over, smells it. She touches it to her lips. Maybe she takes a tiny taste. Maybe she puts it back. Papa smiles: "Theek hai, kal phir try karenge."
Moral: Dikhana, offer karna, pressure nahi. Baar baar dikhane se familiarity aati hai — swad badalne mein time lagta hai.
''',
    setting: 'Dining table, lunch time, afternoon light',
    sceneDetail: 'Ria\'s plate with broccoli florets; Papa\'s plate with a half-eaten floret; a small extra piece on the side of Ria\'s plate',
    dialogue: '"Nahi chahiye!" "Crunchy hai, thoda kadwa bhi." "Chaho toh try karo, warna rehne do." "Theek hai, kal phir try karenge."',
    mess: 'Ria refuses the broccoli, pushes plate away. Papa models eating without pressure. Ria explores the piece — looks, touches, smells — bite optional.',
    innerThought: 'My job is to offer, not to force. Every exposure counts, even if she does not bite today.',
    endingBeat: 'Ria puts the piece back or takes a tiny taste. Either way, Papa stays calm. "Kal phir try karenge." They continue eating together.',
    defaultCast: ['Ria', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Dining table, lunch time. Ria pushes broccoli away: "Nahi chahiye!" Papa takes a bite: "Crunchy hai." Offers small piece: "Try karo, warna rehne do." No pressure. Text: "BROCCOLI? NAHI! 🥦" "PAPA KHAKE DIKHAYE 🍴" "PRESSURE NAHI 🚫"

On-Screen Text:
- [0-3s]: "BROCCOLI DEKHTE HI... 🥦"
- [3-6s]: "RIA: NAHI CHAHIYE! 😤"
- [6-10s]: "PAPA KHAKE DIKHAYE 🍴"
- [10-14s]: "TRY KARO, WARNA REHNE DO 🤷‍♂️"
- [14-18s]: "EXPLORE: LOOK, TOUCH, SMELL 👃"
- [18-20s]: "PRESSURE NAHI, EXPOSURE HAAN ✅"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria pushes broccoli away: "Nahi chahiye!" Papa calmly eats a floret: "Crunchy hai, thoda kadwa." Places small piece on Ria's plate side: "Chaho toh try karo." Text: "BROCCOLI DEKHTE HI... 🥦" "RIA: NAHI CHAHIYE! 😤" "PAPA KHAKE DIKHAYE 🍴"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria looks at piece, touches, smells, maybe tiny taste or puts back. Papa calm: "Theek hai, kal phir try karenge." Text: "TRY KARO, WARNA REHNE DO 🤷‍♂️" "EXPLORE: LOOK, TOUCH, SMELL 👃" "PRESSURE NAHI, EXPOSURE HAAN ✅"

Audio/Dialogue (Hinglish): Ria firm: "Nahi chahiye!" Papa natural: "Crunchy hai, thoda kadwa." Papa gentle: "Chaho toh try karo, warna rehne do." Ria curious: *sniffs, touches* Papa calm: "Theek hai, kal phir try karenge." Both eat together.

Part 3 (20-30s): 3D Pixar style, 9:16. Ria puts the piece back or takes a tiny taste. Either way, Papa stays calm. "Kal phir try karenge." They continue eating together. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Repeated low-pressure exposure and calm modelling can help children become familiar with foods, but acceptance is never guaranteed. Never pressure, bargain, or threaten.

    ''',
  ),

// New built-in content ideas from Palak's marketing and character plan.
HookIdea(
    id: 'idea_14',
    category: 'Child Chaos',
    cover: 'Park Se Ghar: Teen Bachche, Teen Reactions 😂',
    title: 'Park Se Ghar: Teen Bachche, Teen Reactions 😂',
    opening: 'Park se ghar aane par aapka bachcha kaun sa drama karta hai? 😂',
    problem: 'Ria negotiates for more turns, Rio demands "ek aur slide," and Cuty seeks a quiet moment — all at the same time. Mumma needs to transition all three without a meltdown.',
    lesson: 'Give all children the same clear, fair transition boundary. Adapt your support to each child\'s personality — negotiate timing for the negotiator, offer a choice for the protester, and provide a calm corner for the quiet one. A timer can help but does not guarantee instant calm.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Park se ghar aana hai? Ria negotiate karegi, Rio "ek aur" bolega, Cuty corner dhundhegi. Mumma ki ek hi boundary, teen alag support. 😂 #SiblingPersonalities #ParkToHome #ToddlerTransitions #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At the park, Mumma says, "Chalo, ghar chalna hai." Ria instantly starts negotiating: "Mere saath 5 minute, phir Rio karega!" Rio protests: "Ek aur slide, ek aur!" Cuty silently slides off the swing and hides behind Mumma's leg, eyes half-closed.
Twist: Mumma gives the same boundary to all: "Do minute aur, phir chalenge." For Ria, she adds: "Tum timer set karo." For Rio, she offers: "Ek goodbye song, phir chalo." For Cuty, she just lifts her gently: "Tere liye quiet corner bana ke rakha hai."
Resolution: Ria sets the timer, proud. Rio picks "Happy Birthday" as his goodbye song. Cuty snuggles into Mumma's arms, already half-asleep. All three transition without tears — the timer helps, but the real win is the tailored support.
Moral: Ek hi boundary, teen alag support. Ria, Rio ya Cuty — aapka bachcha kis jaisa hai?
''',
    setting: 'Park with three swings, late afternoon, Mumma standing ready to leave',
    sceneDetail: 'Three swings — Ria on one bargaining, Rio on another protesting, Cuty curled up on the third drowsy',
    dialogue: '"Chalo, ghar chalna hai." "Mere saath 5 minute!" "Ek aur slide!" *Cuty hides silently*',
    mess: 'All three react differently at once — Ria negotiates, Rio protests, Cuty withdraws. Mumma stays calm.',
    innerThought: 'Same boundary, different kids. The magic is in how I adapt, not in changing the rule.',
    endingBeat: 'Timer dings, goodbye song ends, Cuty yawns in Mumma\'s arms. "Ria, Rio ya Cuty — aapka bachcha kis jaisa hai?"',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Park, late afternoon. Mumma: "Chalo, ghar chalna hai." Ria (pink dress): "Mere saath 5 minute!" Rio (blue shirt): "Ek aur slide!" Cuty (tiny, sleepy): *hides behind leg*. Text: "PARK SE GHAR 🏃‍♀️" "TEEN BACHCHE, TEEN REACTIONS 😂"

On-Screen Text:
- [0-3s]: "PARK SE GHAR... DRAMA START! 😂"
- [3-6s]: "RIA: NEGOTIATOR 🤝"
- [6-9s]: "RIO: PROTESTER 😤"
- [9-12s]: "CUTY: QUIET ONE 😴"
- [12-15s]: "EK BOUNDARY, TEEN SUPPORT ✨"
- [15-18s]: "RIA: TIMER SET KARO ⏱️"
- [18-21s]: "RIO: GOODBYE SONG 🎵"
- [21-24s]: "CUTY: QUIET CORNER 😴"
- [24-27s]: "RIA, RIO YA CUTY — AAPKA BACHCHA? 🤔"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma: "Chalo, ghar!" Ria: "5 minute!" Rio: "Ek aur slide!" Cuty hides. Text: "PARK SE GHAR... DRAMA START! 😂" "TEEN BACHCHE, TEEN REACTIONS 😂"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma: "Do minute, same rule for all." Ria sets timer. Rio picks goodbye song. Cuty lifted to quiet corner. Text: "EK BOUNDARY, TEEN SUPPORT ✨" "RIA: TIMER ⏱️ RIO: SONG 🎵 CUTY: QUIET 😴" "RIA, RIO YA CUTY — AAPKA BACHCHA? 🤔"

Audio/Dialogue (Hinglish): Mumma calm: "Chalo, ghar chalna hai." Ria firm: "Mere saath 5 minute, phir Rio karega!" Rio dramatic: "Ek aur slide, ek aur!" Mumma gentle: "Do minute, timer laga lo." Ria happy: "Main timer set karungi!" Rio: "Goodbye song — Happy Birthday!" Mumma lifts Cuty: "Tera quiet corner yahan hai." Cuty sleepy: "Hmm..." All transition. Mumma to camera: "Ria, Rio ya Cuty — aapka bachcha kis jaisa hai?"

Part 3 (20-30s): 3D Pixar style, 9:16. Timer dings, goodbye song ends, Cuty yawns in Mumma's arms. "Ria, Rio ya Cuty — aapka bachcha kis jaisa hai?" Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Give all children the same clear, fair transition boundary. Adapt your support to each child's personality — a timer helps but does not guarantee instant calm.

''',
  ),

HookIdea(
    id: 'idea_15',
    category: 'Funny',
    cover: '7 Things Every Toddler Does 😂',
    title: '7 Things Every Toddler Does 😂',
    opening: 'Says no, wants the same spoon, suddenly needs Mumma — seven tiny dramas in one Reel! 😂',
    problem: 'Seven distinct, relatable toddler behaviors that every parent recognizes but rarely sees compiled together.',
    lesson: 'These tiny, universal behaviors are the funny, exhausting, and heartwarming signs of childhood — not problems to fix.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Har parent in 7 cheezon ko pehchaane ga! 1) "Nahi!" 2) Same spoon 3) Sudden Mumma need 4) Toy drop-pickup loop 5) Bedtime stretch 6) Wrong shoe pride 7) Random fact drop. #ToddlerTruths #ParentingHumor #DailyChaos #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Seven quick vignettes, one after another.
1) "Nahi!" — Ria refuses the green shirt, crosses arms.
2) Same spoon — Rio only eats with the blue spoon, ignores the red one.
3) Sudden Mumma need — Cuty playing happily, then: "Mumma!" for no reason.
4) Toy drop-pickup loop — Ria drops car, picks up, drops again, giggles.
5) Bedtime stretch — "Ek aur paani," "Teddy ko blanket," "Ek aur hug."
6) Wrong shoe pride — Rio puts shoes on wrong feet, walks penguin-style, beams.
7) Random fact drop — Ria: "Mumma, butterfly taste with their feet!"
Moral: These aren't problems — they're proof your child is growing, exploring, and being exactly who they should be.
''',
    setting: 'Montage across home — kitchen, bedroom, playroom, hallway, bedtime',
    sceneDetail: 'Quick cuts: blue spoon rejected, car dropped, blanket tugged, penguin walk, butterfly fact',
    dialogue: '"Nahi!" "Blue spoon!" "Mumma!" *giggle* "Penguin!" "Butterfly taste with feet!"',
    mess: 'Seven rapid-fire toddler moments — spoon refusal, car drop, blanket demand, penguin walk, random fact',
    innerThought: 'Each "problem" is actually a milestone in disguise. The chaos is the childhood.',
    endingBeat: 'Montage ends with all three kids asleep in a pile. Text: "7 things. 1 childhood. 💛"',
    defaultCast: ['Ria', 'Rio', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Fast-paced montage of 7 toddler moments.
Text: "7 THINGS EVERY TODDLER DOES 😂"

On-Screen Text:
- [0-2s]: "1. NAHI! 😤"
- [2-4s]: "2. SAME SPOON 🥄"
- [4-6s]: "3. MUMMA NEED 😭"
- [6-8s]: "4. DROP-PICKUP LOOP 🔄"
- [8-10s]: "5. BEDTIME STRETCH 🛏️"
- [10-12s]: "6. WRONG SHOE PRIDE 🐧"
- [12-14s]: "7. RANDOM FACT 🦋"
- [14-16s]: "7 THINGS. 1 CHILDHOOD. 💛"
- [16-20s]: "THE CHAOS IS THE CHILDHOOD 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Rapid cuts: Ria crosses arms "Nahi!" Rio rejects red spoon. Cuty tugs Mumma. Ria drops car, picks up, giggles. Text: "1. NAHI!" "2. SAME SPOON" "3. MUMMA NEED" "4. DROP-PICKUP" "5. BEDTIME STRETCH"

Part 2 (10-20s): 3D Pixar style, 9:16. Rio waddles in wrong shoes. Ria: "Butterfly taste with feet!" Montage ends with all three asleep in a pile. Text: "6. WRONG SHOE PRIDE 🐧" "7. RANDOM FACT 🦋" "7 THINGS. 1 CHILDHOOD. 💛" "THE CHAOS IS THE CHILDHOOD 💛"

Audio/Dialogue (Hinglish): Ria firm: "Nahi!" Rio: "Blue spoon hi chahiye!" Cuty: "Mumma!" *giggle drop* Rio penguin walk. Ria: "Mumma, butterfly taste with their feet!" Mumma tired: "Haan beta, sahi hai." All asleep: "The chaos is the childhood."

Part 3 (20-30s): 3D Pixar style, 9:16. Montage ends with all three kids asleep in a pile. Text: "7 things. 1 childhood. 💛" Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: These tiny, universal behaviors are the funny, exhausting, and heartwarming signs of childhood — not problems to fix.

''',
  ),

// Tantrums & big feelings: when emotions overflow and a calm reset helps.
  HookIdea(
    id: 'idea_16',
    category: 'Child Chaos',
    cover: 'Bedtime Ki Darr!',
    title: 'Bedtime Ki Darr!',
    opening: 'Cuty: "Bas ek aur story!" ... jab tak aankh band nahi hoti.',
    problem: 'Cuty refuses bedtime, demanding "just one more" story',
    lesson: 'Ek story, phir lamp off. Use a visual timer — when sand runs out, it is sleep time.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ek aur story? No. Ek story phir sleep time. Timer ke saath easy! 😴 #BedtimeBattle #SleepTraining #FunLearningWithPalak #IndianParents #BedtimeStories',
    pinnedComment: 'Tip: "Story timer" with 2-minute sand clock — visual, fair, final.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cuty sits bolt upright in bed: "Ek aur story!" Mumma: "Time up, beta." Cuty: "But I need one more!" Tears welling.
Twist: Mumma shows a 2-minute sand timer: "Jab tak ravaan khatam ho jaye, tab tak ek story. Phir sleep." Cuty watches the sand.
Resolution: Timer runs out. Cuty snuggles down: "The End story?" Mumma: "Goodnight story. Always."
Moral: One more story means one more minute — then it is sleep time.
''',
    setting: 'Cuty\'s bedroom, bedtime, soft night light',
    sceneDetail: 'Cuty clutching her favorite stuffed carrot, sand timer on the nightstand',
    dialogue: '"Ek aur story!" "Jab tak ravaan khatam ho jaye, tab tak ek story."',
    mess: 'Cuty cries, hiccers, asks for "The Very Hungry Caterpillar" again',
    innerThought: 'The timer is the bad guy, not Mumma.',
    endingBeat: 'Cuty whispers "The End story, Mumma?" and snuggles under the blanket.',
    defaultCast: ['Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Cuty's bedroom, bedtime. Soft night light glows. Cuty (fluffy white bunny, pink bow, large dark eyes) sits bolt upright in bed: "Ek aur story!" Mumma (yellow kurti, top bun) holds a 2-minute sand timer. Text on screen: "BEDTIME STORY? 📖" "SAND TIMER ⏰" "ONE MORE MINUTE... THEN SLEEP 💤"

On-Screen Text:
- [0-3s]: "BEDTIME STORY? 📖"
- [3-7s]: "SAND TIMER ⏰"
- [7-11s]: "WATCH THE SAND... ⏳"
- [11-16s]: "STORY TIME IS DONE 📚"
- [16-20s]: "SLEEP MODE ON 💤"

Part 1 (0-10s): 3D Pixar style, 9:16. Cuty: "Ek aur story!" Mumma: "Time up, beta. Jab tak ravaan khatam ho jaye, tab tak ek story." Shows sand timer. Cuty watches sand fall, eyes wide. Text: "BEDTIME STORY? 📖" "SAND TIMER ⏰".

Part 2 (10-20s): 3D Pixar style, 9:16. Last grain of sand falls. Mumma: "Ab sleep time." Cuty tries: "Ek aur?" Mumma: "Kal." Cuty sniffs: "Goodnight story?" Text: "WATCH THE SAND... ⏳" "STORY TIME IS DONE 📚".

Audio/Dialogue (Hinglish): Cuty: "Ek aur story!" Mumma: "Jab tak ravaan khatam ho jaye, tab tak ek story." Cuty watching: "Khatam hone wala hai..." Mumma: "Ab sleep time, beta." Cuty: "Goodnight story?" Mumma: "Always."

Part 3 (20-30s): 3D Pixar style, 9:16. Cuty snuggles under blanket, eyes already heavy. Mumma tucks her in, whispers one line: "Jab tak ravaan khatam... so jao beta." Text: "SLEEP MODE ON 💤". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: One more story means one more minute — then it is sleep time. A visual timer makes the boundary fair and final.
''',
  ),

  HookIdea(
    id: 'idea_17',
    category: 'Ria Chaos',
    cover: 'Neend Ka Evidence 😴',
    title: 'Neend Ka Evidence 😴',
    opening: 'Ria: "Mujhe neend nahi!" ... jab tak aankh band nahi hoti. 😴',
    problem: 'Ria protests sleep loudly, then falls asleep mid-story. Her protest is real, but so is her tiredness.',
    lesson: 'Bedtime protest is normal — it can be a way of staying close. Validate the feeling, keep the routine warm and firm, and trust that sleep will come. Do not promise the protest will stop or that sleep will be instant.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ria: "Mujhe neend nahi!" ... phir aankh band. Protest bhi pyaar hai, neend bhi zaroori. Bedtime protest normal hai — pyaar se handle karo. 😴 #BedtimeStruggles #ToddlerSleep #ParentingHacks #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria sits bolt upright mid-storybook on Mumma's lap, legs kicking. "Mujhe neend nahi!" She pats the pillow: "Thoda aur?"
Twist: Halfway through page two, her eyelids grow heavy. Mumma: "Evidence mil gaya." Ria snaps awake: "Main toh jaag rahi thi!"
Resolution: Mumma tucks the blanket around Ria's shoulders and keeps reading in a whisper. By page three Ria is breathing evenly, one hand still holding the page corner.
Moral: Protest bhi pyaar hai. Neend aayegi — bas pyaar se saath do.
''',
    setting: 'Living room couch, storybook on Mumma lap, dim lamp',
    sceneDetail: 'Half-read storybook, blanket half-draped, one hand holding the page corner',
    dialogue: '"Mujhe neend nahi!" "Evidence mil gaya." "Main toh jaag rahi thi!"',
    mess: 'Ria keeps restarting the story from page one, refusing to stay still',
    innerThought: 'Agar main jaldi so jaoongi toh kal subah uthna padega, and I will anyway',
    endingBeat: 'Mumma tucks the blanket around Ria\'s shoulders, both half-asleep by page three. "Goodnight, beta." "Goodnight, Mumma."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Cozy living room couch, dim lamp, half-read storybook on Mumma's lap. Ria (pajamas, hair messy) sits bolt upright: "Mujhe neend nahi!" Yawns, then pats the pillow: "Thoda aur?" Text on screen: "NEEND KA EVIDENCE" "PROTEST • DETECT • RESOLVE"

On-Screen Text:
- [0-3s]: "NEEND KA EVIDENCE 😴"
- [3-6s]: "PROTEST: 'MUJHE NEEND NHI!' 🛏️"
- [6-10s]: "DETECT: EYELIDS HEAVY 😴"
- [10-14s]: "RESOLVE: BLANKET TUCK STRATEGY ✨"
- [14-18s]: "PROTEST = LOVE 💤"
- [18-20s]: "SLEEP HACKS > POWER STRUGGLES 💤"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria dramatically protests sleep, sits bolt upright mid-story, kicks blanket off. Mumma's eyes twinkle with amusement. Text: "NEEND KA EVIDENCE" "PROTEST: 'MUJHE NEEND NHI!'". Ria: "Mujhe neend nahi!" Mumma: "Ek aur page?"
Part 2 (10-20s): 3D Pixar style, 9:16. Ria's eyelids grow heavy, she pats the pillow: "Thoda aur?" Mumma tucks blanket around Ria's shoulders, continues whispering the story. Ria snoring softly on Mumma's lap. Text: "DETECT: EYELIDS HEAVY" "BLANKET TUCK STRATEGY" "PROTEST = LOVE 💤".

Audio/Dialogue (Hinglish): Ria dramatically: "Maa, mujhe neend nahi!" Mumma smiling: "Ek aur page?" Ria sleepy: "Thoda aur?" Mumma whispering: "Jaane do beta, kal subah nayi kahani."

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma tucks the blanket around Ria's shoulders, both half-asleep by page three. "Goodnight, beta." "Goodnight, Mumma." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Bedtime protest is normal — it can be a way of staying close. Validate the feeling, keep the routine warm and firm, and trust that sleep will come. Do not promise the protest will stop or that sleep will be instant.

''',
  ),

HookIdea(
    id: 'idea_18',
    category: 'Child Chaos',
    cover: 'Morning Checklist: Sock, Shirt, Bottle! ✅',
    title: 'Morning Checklist: Sock, Shirt, Bottle! ✅',
    opening: 'Ek sock missing, shirt ulta, bottle reh gaya — morning checklist se sab theek! ✅',
    problem: 'Morning routine creates scattered chaos — missing sock, inside-out shirt, forgotten water bottle.',
    lesson: 'A visual morning checklist made together turns chaos into teamwork. Kids remember what they help create.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Morning chaos? Sock, shirt, bottle — checklist banao saath milke. Ria, Rio, Cuty sab yaad rakhenge! ✅ #MorningRoutine #ChecklistHack #ToddlerIndependence #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Routine ko ek picture banao — har step ek star ban jaye!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Morning check: one sock by the couch, shirt inside-out, water bottle left on the chair.
Twist: Ria spots her own sock — "Mumma, maine hi gira diya!" — and laughs instead of crying. They turn the chaos into a game: "Morning Checklist — sock, shirt, bottle, smile!"
Resolution: They make a visual checklist together on the fridge: sock ✅ shirt ✅ bottle ✅ smile ✅. Next morning, Ria checks each item off proudly.
Moral: Small things make big mornings — and a checklist made together turns chaos into teamwork.
''',
    setting: 'Hallway by the door, morning, coats on hooks, fridge with visual checklist',
    sceneDetail: 'Visual checklist on fridge with pictures: sock, shirt, bottle, smile — Ria checking off items',
    dialogue: '"Mumma, maine hi gira diya!" "Checklist: sock, shirt, bottle, smile!"',
    mess: 'Morning chaos: sock here, shirt inverted, bottle forgotten on the table — turned into a visual checklist',
    innerThought: 'If we make the checklist together, maybe tomorrow will be smoother — and it is.',
    endingBeat: 'Ria checks off "smile" last, beams. "Checklist complete!" Rio high-fives. Morning sorted.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Hallway by the door, morning. Visual checklist on fridge with pictures: sock, shirt, bottle, smile. Ria checks off each item: sock ✅ shirt ✅ bottle ✅ smile ✅ Text: "MORNING CHECKLIST ✅" "SOCK • SHIRT • BOTTLE • SMILE"

On-Screen Text:
- [0-3s]: "MORNING CHAOS 😵"
- [3-6s]: "CHECKLIST BANAO! ✅"
- [6-10s]: "SOCK ✅ SHIRT ✅ BOTTLE ✅"
- [10-14s]: "SMILE ✅ = MORNING SORTED 😊"
- [14-18s]: "VISUAL CHECKLIST = TEAMWORK 🤝"
- [14-20s]: "KIDS REMEMBER WHAT THEY CREATE 💡"

Part 1 (0-10s): 3D Pixar style, 9:16. Morning chaos: sock on couch, shirt inside-out, bottle on table. Ria: "Mumma, maine hi gira diya!" They make checklist together on fridge. Text: "MORNING CHAOS" "CHECKLIST BANAO!"

Part 2 (10-20s): 3D Pixar style, 9:16. Next morning: Ria checks off sock ✅ shirt ✅ bottle ✅ smile ✅. Rio high-fives. Text: "SOCK ✅ SHIRT ✅ BOTTLE ✅ SMILE ✅" "VISUAL CHECKLIST = TEAMWORK" "KIDS REMEMBER WHAT THEY CREATE"

Audio/Dialogue (Hinglish): Ria: "Mumma, maine hi gira diya!" Mumma: "Chalo checklist banate hain." Ria: "Sock, shirt, bottle, smile!" Next morning: Ria checks off: "Sock done! Shirt done! Bottle done! Smile done!" Mumma: "Morning sorted!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria checks off "smile" last, beams. "Checklist complete!" Rio high-fives. Morning sorted. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A visual morning checklist made together turns chaos into teamwork. Kids remember what they help create.

''',
  ),

HookIdea(
    id: 'idea_19',
    category: 'Ria Chaos',
    cover: 'Ready Captain! Ria Ki Indecision 🎀',
    title: 'Ready Captain! Ria Ki Indecision 🎀',
    opening: 'Ria: "Ready Captain!" Par hair clip teen baar badli... time nikal gaya! 🎀',
    problem: 'Ria declares herself "Ready Captain" but keeps changing her hair clip — blue bow, pink bow, no bow — while time slips away.',
    lesson: 'Being ready first does not mean leaving the team behind. True readiness means helping others get ready too.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ria: "Ready Captain!" Par clip teen baar badli. Rio: "Time khatam!" Ria picks no-bow, helps Cuty. Team first! 🎀 #MorningRoutine #SiblingSupport #ToddlerIndependence #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria declares: "Ready Captain!" — but she changes her hair clip three times: blue bow, pink bow, no bow.
Twist: Rio points at the clock: "Time khatam ho raha hai!" Cuty is still struggling with his second shoe. Ria pauses, sees Cuty struggling.
Resolution: Ria picks "no bow," kneels down, and helps Cuty with his second shoe. "Jab tak sabke saath, tab tak team complete." They walk out together.
Moral: Being first ready doesn't mean you leave everyone behind. True readiness means helping the team cross the finish line together.
''',
    setting: 'Front door, backpacks by the shoe rack, "Ready Captain" badge on Ria\'s shirt, clock on wall',
    sceneDetail: 'Three hair clips on the counter — blue bow, pink bow, plain clip; Cuty struggling with shoe; clock showing time',
    dialogue: '"Ready Captain!" "Blue bow, pink bow, no bow." "Time khatam ho raha hai!" "Team complete!"',
    mess: 'Ria changes her hair clip three times, time slipping away; Cuty struggles with shoe; Rio watches clock',
    innerThought: 'Ready hona kaafi nahi — team ke saath ready hona asli ready hai.',
    endingBeat: 'Ria picks no-bow, helps Cuty with his shoe. "Team complete!" All three walk out together, on time.',
    defaultCast: ['Ria', 'Rio', 'Cuty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Front door, backpacks by shoe rack. Ria with "Ready Captain" badge changes hair clip: blue bow → pink bow → no bow. Clock ticks. Rio: "Time khatam!" Cuty struggles with shoe. Ria picks no-bow, helps Cuty. Text: "READY CAPTAIN! 🎀" "CLIP CHANGES × 3 🔄" "TIME TICKING ⏰" "TEAM FIRST! 🤝"

On-Screen Text:
- [0-3s]: "READY CAPTAIN! 🎀"
- [3-6s]: "CLIP BADLI × 3 🔄"
- [6-10s]: "TIME KHATAM! ⏰"
- [10-14s]: "TEAM FIRST! 🤝"
- [14-18s]: "HELP CUTY 👟"
- [18-20s]: "TEAM COMPLETE! 🤝✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria changes clip: blue → pink → none. Clock ticks. Rio: "Time khatam!" Cuty struggles with shoe. Text: "READY CAPTAIN! 🎀" "CLIP BADLI × 3 🔄" "TIME KHATAM! ⏰"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria picks no-bow, helps Cuty with shoe. "Team complete!" All walk out together. Text: "TEAM FIRST! 🤝" "HELP CUTY 👟" "TEAM COMPLETE! 🤝✨"

Audio/Dialogue (Hinglish): Ria: "Ready Captain!" *changes clip* Rio: "Time khatam!" Ria sees Cuty struggle. Ria: "Team complete!" Helps Cuty. "Jab tak sabke saath, tab tak team complete." All walk out.

Part 3 (20-30s): 3D Pixar style, 9:16. Ria picks no-bow, helps Cuty with his shoe. "Team complete!" All three walk out together, on time. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Being ready first does not mean leaving the team behind. True readiness means helping others get ready too.

''',
  ),

HookIdea(
    id: 'idea_20',
    category: 'Child Chaos',
    cover: 'Kaun Kha Gaya? Mystery! 🕵️‍♀️',
    title: 'Kaun Kha Gaya? Mystery! 🕵️‍♀️',
    opening: 'Fruit pieces everywhere... Ria points at Rio. Asli culprit kaun? 🕵️‍♀️',
    problem: 'A snack plate is empty. Ria immediately blames Rio without checking the evidence.',
    lesson: 'Check the evidence before blaming someone. The real answer is often right in front of you — look first, accuse later.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Plate khali, Ria blame Rio ko kar di! Check karo pehle, blame baad mein. 🕵️‍♀️ #EvidenceFirst #SiblingMystery #ToddlerHumor #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Har tip ko try karo aur comment mein batana — community seekha jayega!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: A plate of apple slices sits empty on the coffee table. Ria gasps: "Mumma, Mumma — koi ne apple kha liye!" Points at Rio: "Rio ne khaya!"
Twist: Mumma: "Check karte hain." She looks at Rio's hands — clean. Then she looks at the rug under the coffee table — apple peels and a few slices tucked there. She looks at Cuty — a small apple piece sits near her paws.
Resolution: Ria giggles: "Oh! Cuty ke paas mila!" She picks up the piece and puts it back on the plate. Rio grins: "Maine nahi khaya."
Moral: Sabse paas ka suspect aksar asli culprit hota hai — check karo pehle, blame baad mein.
''',
    setting: 'Living room, coffee table with empty snack plate, apple peels on rug nearby',
    sceneDetail: 'Empty snack plate, apple peels on rug under table, Cuty sitting nearby with a small apple piece near her paws, Rio with clean hands',
    dialogue: '"Mumma, Mummy — koi ne apple kha liye!" "Rio ne khaya!" "Check karte hain." "Cuty ke paas mila!"',
    mess: 'Ria points at Rio, accusation in her voice, while the evidence trail leads elsewhere',
    innerThought: 'The closest suspect often has the best poker face — check evidence before blaming.',
    endingBeat: 'Ria picks up the apple piece near Cuty, puts it on the plate. "Cuty ke paas mila!" Rio grins: "Maine nahi khaya."',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, empty snack plate on coffee table. Ria points at Rio: "Rio ne khaya!" Mumma: "Check karte hain." Looks at Rio's hands — clean. Finds apple peels on rug, piece near Cuty's paws. Text: "MYSTERY SNACK 🕵️‍♀️" "EVIDENCE FIRST! 🔍"

On-Screen Text:
- [0-3s]: "MYSTERY SNACK 🕵️‍♀️"
- [3-6s]: "RIA BLAMES RIO 👉"
- [6-10s]: "EVIDENCE CHECK! 🔍"
- [10-14s]: "APPLE PEELS ON RUG! 🍎"
- [14-18s]: "CUTY KE PAAS PIECE! 🐰"
- [18-20s]: "CHECK FIRST, BLAME LATER 💡"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria sees empty plate, immediately points at Rio: "Rio ne khaya!" Mumma: "Check karte hain." Rio's hands clean. Finds apple peels on rug under table. Text: "MYSTERY SNACK 🕵️‍♀️" "RIA BLAMES RIO 👉"

Part 2 (10-20s): 3D Pixar style, 9:16. Finds apple piece near Cuty's paws. Ria: "Cuty ke paas mila!" Puts it on plate. Rio grins: "Maine nahi khaya." Text: "EVIDENCE CHECK! 🔍" "FOUND IT! 🍎" "CHECK FIRST, BLAME LATER 💡"

Audio/Dialogue (Hinglish): Ria urgent: "Mumma, koi ne apple kha liye! Rio!" Mumma calm: "Check karte hain." Rio's hands clean. Finds peels: "Cuty ke paas piece!" Ria giggles: "Oh! Cuty ke paas mila!" Rio grins: "Maine nahi khaya."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria picks up the apple piece near Cuty, puts it on the plate. "Cuty ke paas mila!" Rio grins: "Maine nahi khaya." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Check the evidence before blaming someone. The real answer is often right in front of you — look first, accuse later.

''',
  ),

  // Routines: daily rituals that become tiny battles until they become habits.
HookIdea(
    id: 'idea_21',
    category: 'Funny',
    cover: 'Mumma Ne Kaha Tha! 🗣️',
    title: 'Mumma Ne Kaha Tha! 🗣️',
    opening: 'Mumma ne kaha — "Aaj jaldi sona hai." Ria ne Teddy ko bol diya! 🗣️',
    problem: 'Children repeat the exact phrases adults say — often at the most unexpected (and funny) moments.',
    lesson: 'Small phrases stick; what we say becomes their inner voice. Speak the words you want them to repeat.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ria: "Teddy, negotiation band!" Mumma: "Yeh toh maine kaha tha!" Bachche wahi bolte jo sunte hain. 🗣️ #ToddlerQuotes #ParentingMirror #WordsMatter #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma tells Ria at bedtime, "Aaj jaldi sona hai." Later that night, Ria tucks Teddy in and repeats Mumma's exact phrase with a twist: "Teddy, negotiation band — ab so jao!"
Twist: Mumma, sitting nearby on the bed, tries not to laugh — she's heard every word. She realizes: "Yeh toh maine hi kaha tha... lekin alag andaaz mein."
Resolution: Ria whispers, "Mumma ne kaha tha!" and Mumma gives her a quiet, warm hug, thinking about the words she wants Ria to keep.
Moral: Jo baatein hum dete hain, wohi din mein dobara sunai deti hain — par pyaar ke saath.
''',
    setting: 'Bedroom, bedtime, Teddy on the pillow, night light glowing',
    sceneDetail: 'Ria tucking Teddy in, night light casting soft shadows, Mumma watching from the doorway',
    dialogue: '"Aaj jaldi sona hai." "Teddy, negotiation band — ab so jao!" "Mumma ne kaha tha!"',
    mess: 'Ria repeats Mumma\'s exact phrase to Teddy, not knowing she was overheard',
    innerThought: 'That phrase I said in frustration — she made it her own lullaby. What else is she storing?',
    endingBeat: 'Ria whispers "Mumma ne kaha tha!" and Mumma gives her a quiet, warm hug. "Haan beta, maine hi kaha tha. Kal se behtar words choose karungi."',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bedroom, bedtime. Mumma: "Aaj jaldi sona hai." Ria tucks Teddy: "Teddy, negotiation band — ab so jao!" Mumma at doorway smiles. Text: "MUMMA NE KAHA THA! 🗣️" "BACCHE SUNATE HAIN 🎧"

On-Screen Text:
- [0-3s]: "BEDTIME PHRASE 🌙"
- [3-6s]: "RIA TO TEDDY: NEGOTIATION BAND 🗣️"
- [6-10s]: "MUMMA OVERHEARS 👂"
- [10-14s]: "MUMMA NE KAHA THA! 🗣️"
- [14-18s]: "WORDS STICK — CHOOSE WISELY 💡"
- [18-20s]: "SPEAK LOVE, HEAR LOVE 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma at bedtime: "Aaj jaldi sona hai." Ria tucks Teddy: "Teddy, negotiation band — ab so jao!" Mumma at doorway smiles. Text: "BEDTIME PHRASE 🌙" "RIA TO TEDDY: NEGOTIATION BAND 🗣️"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria whispers: "Mumma ne kaha tha!" Mumma gives quiet hug, reflects: "Kal se behtar words choose karungi." Text: "MUMMA NE KAHA THA! 🗣️" "WORDS STICK — CHOOSE WISELY 💡" "SPEAK LOVE, HEAR LOVE 💛"

Audio/Dialogue (Hinglish): Mumma: "Aaj jaldi sona hai." Ria to Teddy: "Teddy, negotiation band — ab so jao!" Mumma at door: *smiles* Ria whispers: "Mumma ne kaha tha!" Mumma hugs: "Haan beta, maine hi kaha tha. Kal se behtar words."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria whispers "Mumma ne kaha tha!" and Mumma gives her a quiet, warm hug. "Haan beta, maine hi kaha tha. Kal se behtar words choose karungi." Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Small phrases stick; what we say becomes their inner voice. Speak the words you want them to repeat.

''',
  ),

HookIdea(
    id: 'idea_22',
    category: 'Child Chaos',
    cover: 'Supermarket Team! 🛒',
    title: 'Supermarket Team! 🛒',
    opening: 'Ria: mangoes! Rio: cereal box! Cuty: list guard! Supermarket team ready! 🛒',
    problem: 'Shopping with three kids — each gets a job suited to their age and energy, with safety first.',
    lesson: 'Give each child an age-appropriate job. They may misunderstand, but the teamwork and inclusion matter more than perfect execution. Safety comes first — no riding on cart handles.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Supermarket team ready! Ria: mangoes 🥭 Rio: cereal box 📦 Cuty: list guard 📝 Jobs diye, teamwork mila! 🛒 #SupermarketTeam #SiblingTeamwork #GroceryWithKids #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Jootey pehne ko ek game bana lo — "Superhero ban jao!"',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: At the supermarket, Mumma gives each a job — Ria: "Pick the yellow fruit." Rio: "Find the cereal box on the shelf." Cuty: "Hold the list clip on the cart."
Twist: Ria returns with mangoes (yellow fruit ✅). Rio finds the cereal box (manageable size ✅). Cuty "guards" the list by sitting safely in the cart basket — "Main list ka rakwala hoon!" Mumma smiles: "Cart handle pe nahi, basket mein baitho."
Resolution: They laugh at the checkout: "Hamari shopping team badi achhi hai!" Ria helps put mangoes on the belt. Rio puts the cereal box up. Cuty waves the receipt from the basket.
Moral: Give them a role suited to them — even if they do it their way, the teamwork is the real win. Safety first!
''',
    setting: 'Supermarket aisle, evening, shopping cart with list clipped on, cart basket safe for Cuty',
    sceneDetail: 'Ria holding mangoes, Rio placing cereal box in cart, Cuty sitting safely in cart basket "guarding" the list',
    dialogue: '"Ria, pick the yellow fruit." "Rio, find the cereal box." "Cuty, hold the list clip!"',
    mess: 'Ria picks mangoes, Rio finds cereal box, Cuty "guards" list from cart basket — each does it their way safely',
    innerThought: 'They misunderstood the brief — but the teamwork is perfect anyway. Safety first!'
,
    endingBeat: 'They laugh: "Hamari shopping team badi achhi hai!" Ria puts mangoes on belt, Rio lifts box, Cuty waves receipt from the basket.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Supermarket aisle, cart with list clipped on. Ria picks mangoes: "Yellow fruit!" Rio grabs cereal box. Cuty sits safely in cart basket: "Main list ka rakwala!" Text: "SUPERMARKET TEAM 🛒" "RIA: MANGOES 🥭 RIO: CEREAL 📦 CUTY: LIST GUARD 📝"

On-Screen Text:
- [0-3s]: "SUPERMARKET TEAM READY! 🛒"
- [3-6s]: "RIA: YELLOW FRUIT 🥭"
- [6-10s]: "RIO: CEREAL BOX 📦"
- [10-14s]: "CUTY: LIST GUARD (IN BASKET!) 📝"
- [14-18s]: "TEAMWORK > PERFECT EXECUTION 🤝"
- [18-20s]: "HAMARI TEAM BADI ACCHI HAI! 🤝"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma assigns jobs. Ria picks mangoes. Rio finds cereal box. Cuty sits safely in cart basket: "Main list ka rakwala!" Text: "SUPERMARKET TEAM 🛒" "RIA: MANGOES 🥭" "RIO: CEREAL 📦" "CUTY: GUARD 📝"

Part 2 (10-20s): 3D Pixar style, 9:16. At checkout: Ria puts mangoes, Rio lifts box, Cuty waves receipt from basket. Text: "RIA: MANGOES 🥭" "RIO: CEREAL 📦" "CUTY: GUARD 📝" "TEAMWORK = WIN 🤝"

Audio/Dialogue (Hinglish): Mumma: "Ria, pick yellow fruit. Rio, cereal box. Cuty, hold list clip." Ria: "Mangoes!" Rio: "Big box!" Cuty: "Main rakwala!" At checkout: Ria: "Hamari team badhi achhi hai!" All laugh.

Part 3 (20-30s): 3D Pixar style, 9:16. They laugh: "Hamari shopping team badi achhi hai!" Ria puts mangoes on belt, Rio lifts box, Cuty waves receipt from the basket. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Give each child an age-appropriate job. They may misunderstand, but the teamwork and inclusion matter more than perfect execution. Safety comes first — no riding on cart handles.

''',
  ),

  // Routines: daily rituals that become tiny battles until they become habits.
  HookIdea(
    id: 'idea_23',
    category: 'Child Chaos',
    cover: 'Brushing Ka Naya Style!',
    title: 'Brushing Ka Naya Style!',
    opening: 'Cuty ne kaha — "Brush nahi, dinosaur chahiye!" Poori bathroom ghoom li.',
    problem: 'Cuty resists brushing teeth, wants to play with the toothbrush instead',
    lesson: 'Brushing ek game banao — "Dinosaur roar, toothpaste foam, sparkly smile!"',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Toothbrush ko dinosaur banao, foam banao, sparkly smile pao! 🦖 #Toothbrushing #ToddlerDental #FunLearningWithPalak #IndianParents #OralHygiene',
    pinnedComment: 'Aapke bachche ka brushing game kya hai?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cuty grabs the toothbrush, puts it in her mouth like a dinosaur. "Rawr! Brush nahi, chew!" Foam floats everywhere. Mumma: "Dinosaur ne toothpaste khaya — sparkly bubbles ban gaye!"
Twist: Cuty spits in the sink: "Dinosaur sparkly now!" She sees her tooth in the foam — a tiny gap where the lost tooth will come out.
Resolution: Mumma: "Ek minute aur brushing, phir nani story." Cuty: "OK OK!" She brushes properly, eyes on the mirror.
Moral: Brushing ek game hai — jab tak mazaa aa raha hai, koi dikkat nahi hoti.
''',
    setting: 'Bathroom sink, morning, toothpaste and dinosaur toothbrush',
    sceneDetail: 'Cuty with toothpaste foam dripping from her mouth, trying to roar like a dinosaur',
    dialogue: '"Rawr! Brush nahi, chew!" "Dinosaur sparkly now!"',
    mess: 'Foam everywhere — sink, mirror, Cuty\'s nose, but she is having fun',
    innerThought: 'If she is laughing while brushing, I am winning.',
    endingBeat: 'Cuty raises her toothbrush like a trophy: "Dinosaur done!"',
    defaultCast: ['Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bathroom sink, morning light. Cuty (white bunny, pink bow) grabs the dinosaur toothbrush, puts it in her mouth: "Rawr! Brush nahi, chew!" Toothpaste foam drips everywhere. Mumma (yellow kurti, top bun) holds a timer. Text on screen: "DINOSAUR MODE! 🦖" "FOAM PARTY! 🧼" "SPARKLY SMILE! ✨"

On-Screen Text:
- [0-3s]: "BRUSHING TIME! 🪥"
- [3-7s]: "DINOSAUR MODE! 🦖"
- [7-12s]: "FOAM PARTY! 🧼"
- [12-16s]: "2 MINUTES! ⏱️"
- [16-20s]: "SPARKLY SMILE! ✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Cuty chews the toothbrush: "Rawr! Brush nahi, chew!" Foam everywhere — sink, mirror, her nose. Mumma: "Dinosaur ne toothpaste khaya!" Cuty giggles. Text: "BRUSHING TIME! 🪥" "DINOSAUR MODE! 🦖".

Part 2 (10-20s): 3D Pixar style, 9:16. Cuty spits in sink: "Dinosaur sparkly now!" Sees her reflection, notices a loose tooth gap. "Nani story ke time?" Mumma shows 2-minute timer: "Abhi do minute." Text: "FOAM PARTY! 🧼" "2 MINUTES! ⏱️".

Audio/Dialogue (Hinglish): Cuty: "Rawr! Brush nahi, chew!" Mumma: "Dinosaur ne toothpaste khaya!" Cuty: "Dinosaur sparkly now!" Mumma: "Ek minute aur brushing, phir nani story." Cuty: "OK OK!" Both: "Sparkly teeth!"

Part 3 (20-30s): 3D Pixar style, 9:16. Cuty brushes properly, eyes on mirror, timer running down. "Dinosaur done!" Raises toothbrush like trophy. Text: "SPARKLY SMILE! ✨". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Brushing is a game when it's fun — if she's laughing, you're winning. A timer gives clear expectations without power struggles.
''',
  ),

  HookIdea(
    id: 'idea_24',
    category: 'Ria Chaos',
    cover: 'Car Bhi Ghar Chalegi! 🚗',
    title: 'Car Bhi Ghar Chalegi! 🚗',
    opening: 'Ria: "Car bhi chalegi!" Mumma: "Seatbelt bachche ke liye, car ke liye travel bag!" 🚗💺',
    problem: 'Ria insists her toy car must come on the road trip. She refuses to leave it behind.',
    lesson: 'Safety first: real seatbelts for children in appropriate car seats. Toys travel safely in a travel bag or pouch — never use a backpack as a car restraint, even for a toy.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ria: "Car bhi chalegi!" Mumma: "Seatbelt bachche ke liye, car ke liye travel bag!" Safety first, imagination second! 🚗💺 #CarSeatSafety #TravelWithKids #ToyTravel #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria packing for a road trip: "Car bhi ghar chalegi!" She clutches her toy car, refusing to let it stay behind.
Twist: Mumma: "Seatbelt ka concept samajh aa gaya?" She shows Ria the car seat: "Tumhara seatbelt yahan — proper car seat, harness sahi se." For the toy car: "Iska alag travel bag." She places the toy car in a small travel pouch and puts it in the seat pocket.
Resolution: Rio checks the pouch — "Safe hai!" — and the toy car rides along in its own travel bag. Ria buckled correctly in her car seat, toy car secure in its pouch. Both safe.
Moral: Real seatbelts for children in car seats. Imaginative travel bags for toys. Safety first, imagination respected.
''',
    setting: 'Living room, packing for a road trip, suitcases open, car seat visible',
    sceneDetail: 'Ria\'s toy car placed in a small travel pouch in the seat pocket; Ria\'s car seat with harness ready',
    dialogue: '"Car bhi ghar chalegi!" "Seatbelt bachche ke liye, car ke liye travel bag!"',
    mess: 'Ria clutches the toy car, refusing to let it stay behind. Mumma explains: seatbelts for kids in car seats, travel pouch for toy.',
    innerThought: 'Safety first — real seatbelt for child in car seat. Imagination for toy — with its own travel solution.',
    endingBeat: 'Ria buckled in car seat, toy car secure in travel pouch. Rio: "Donon safe!" Both ride along safely.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, packing for road trip. Ria: "Car bhi chalegi!" Mumma: "Seatbelt bachche ke liye, car ke liye travel bag!" Buckles Ria in car seat with harness. Places toy car in travel pouch in seat pocket. Text: "CAR BHI CHALEGI! 🚗" "SEATBELT = SAFETY 💺" "TRAVEL BAG = TOY TRAVEL 🎒"

On-Screen Text:
- [0-3s]: "CAR BHI CHALEGI! 🚗"
- [3-6s]: "SEATBELT = SAFETY 💺"
- [6-10s]: "TOY CAR: TRAVEL BAG 🎒"
- [10-14s]: "RIA SAFE ✅ TOY SAFE ✅"
- [14-18s]: "SAFETY FIRST, IMAGINATION SECOND 💡"
- [18-20s]: "DONON SAFE! 🚗💺🎒"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria: "Car bhi ghar chalegi!" Mumma: "Seatbelt bachche ke liye." Buckles Ria in car seat with harness. Ria: "Car ka kya?" Mumma: "Car ke liye travel bag!" Places toy in travel pouch in seat pocket.

Part 2 (10-20s): 3D Pixar style, 9:16. Both secured — Ria in car seat with harness, toy in travel pouch. Rio: "Donon safe!" Text: "SEATBELT = SAFETY 💺" "TRAVEL BAG = TOY TRAVEL 🎒" "SAFETY FIRST, IMAGINATION SECOND 💡"

Audio/Dialogue (Hinglish): Ria: "Car bhi ghar chalegi!" Mumma: "Seatbelt bachche ke liye, car ke liye travel bag!" Ria: "Lock hai!" Rio: "Donon safe!" All safe, ready for road trip.

Part 3 (20-30s): 3D Pixar style, 9:16. Ria buckled in car seat, toy car secure in travel pouch. Rio: "Donon safe!" Both ride along safely. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Safety first: real seatbelts for children in appropriate car seats. Toys travel safely in a travel bag or pouch — never use a backpack as a car restraint, even for a toy.

''',
  ),

HookIdea(
    id: 'idea_25',
    category: 'Learning Lesson',
    cover: 'Big Feelings, Torn Drawing 🎨',
    title: 'Big Feelings, Torn Drawing 🎨',
    opening: 'Ria: "MERI drawing phaa gaya!" — to a child, it feels like the world ended. 🎨💔',
    problem: 'Ria\'s drawing tears — to her, it feels like the world ended. Adults see a torn paper; she sees a lost masterpiece.',
    lesson: 'Validate the feeling first. A torn drawing is a big feeling to a child. Comfort first, then repair together. Do not dismiss the loss or expect instant happiness.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ria ka drawing phata — duniya khatam! Validate karo pehle: "Bada dukh hua." Phir saath repair karo. Big feelings = big love. 🎨💔 #BigFeelings #ToddlerEmotions #ValidateFirst #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria is crying over a torn drawing — "MERI drawing phaa gaya!" The paper is everything to her.
Twist: Mumma kneels: "Dekh rahi hoon. Bada dukh hua na?" She does not say "it is just paper." She validates: "Yeh drawing tumne pyaar se banayi thi. Phatne ka dukh real hai." Then: "Chalo, nayi shuruaat karte hain."
Resolution: They make a new drawing together — "Nayi shuruaat!" — Ria\'s tears slowly turn to giggles as they draw. The new drawing has a heart drawn by Mumma.
Moral: Big feelings over small things are real — and they deserve big love to match. Validate first, repair together.
''',
    setting: 'Drawing table, morning, torn paper on the floor, Ria crying',
    sceneDetail: 'Half-torn drawing in Ria\'s hands, the other half still on the table, tears on cheeks',
    dialogue: '"MERI drawing phaa gaya!" "Bada dukh hua na?" "Chalo, nayi shuruaat karte hain."',
    mess: 'Ria crying, torn paper fragment clutched in her fist — Mumma validates before fixing',
    innerThought: 'This paper feels like it held the whole world together. Validate the loss before offering the fix.',
    endingBeat: 'They make a new drawing together — "Nayi shuruaat!" — Ria\'s tears turn to giggles. New drawing has a heart from Mumma.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Drawing table, torn paper, Ria crying. Mumma kneels: "Bada dukh hua na?" Validates first. Text: "BIG FEELINGS 🎨" "VALIDATE FIRST ❤️"

On-Screen Text:
- [0-3s]: "DRAWING PHAT GAYA! 🎨💔"
- [3-6s]: "RIA CRYING 😭"
- [6-10s]: "VALIDATE FIRST: 'BADA DUKH HUA' ❤️"
- [10-14s]: "REPAIR TOGETHER 🎨"
- [14-18s]: "NAYI SHURUAAT! 💛"
- [18-20s]: "BIG FEELINGS = BIG LOVE ❤️"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria crying over torn drawing: "MERI drawing phaa gaya!" Mumma kneels: "Bada dukh hua na?" Validates the feeling. Text: "DRAWING PHAT GAYA! 🎨💔" "VALIDATE FIRST ❤️"

Part 2 (10-20s): 3D Pixar style, 9:16. They make new drawing together: "Nayi shuruaat!" Heart drawn by Mumma. Ria giggles. Text: "REPAIR TOGETHER 🎨" "NAYI SHURUAAT! 💛" "VALIDATE FIRST, REPAIR TOGETHER ❤️"

Audio/Dialogue (Hinglish): Ria sobbing: "MERI drawing phaa gaya!" Mumma gentle: "Bada dukh hua na? Yeh drawing tumne pyaar se banayi thi." Ria nods. Mumma: "Chalo, nayi shuruaat karte hain." Together drawing: "Nayi shuruaat!" Ria giggles.

Part 3 (20-30s): 3D Pixar style, 9:16. They make a new drawing together — "Nayi shuruaat!" — Ria's tears turn to giggles as they draw. The new drawing has a heart drawn by Mumma. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Validate the feeling first. A torn drawing is a big feeling to a child. Comfort first, then repair together. Do not dismiss the loss or expect instant happiness.

''',
  ),

HookIdea(
    id: 'idea_26',
    category: 'Child Chaos',
    cover: 'Blocks Se Shoes Tak! 🧱👟',
    title: 'Blocks Se Shoes Tak! 🧱👟',
    opening: 'Rio: "Do blocks aur!" Papa: "Ek baar tower complete, phir shoes!" — fair deal done! 🧱👟',
    problem: 'Rio wants more blocks, more time, more everything before putting on shoes. Transition from play to routine needs a clear, fair step — not a food bargain.',
    lesson: 'One clear, fair transition turns "more" into "done" — without food as a reward or screens as bribes.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Rio: "Do blocks aur!" Papa: "Tower complete, phir shoes!" Fair deal, shoes on, sab khush! 🧱👟 #BlocksToShoes #TransitionHack #NoFoodBribes #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio playing with blocks. Papa: "Shoes pehenne ka time." Rio: "Do blocks aur!" Papa: "Theek hai, tower complete karo — phir shoes."
Twist: Rio builds two more blocks, completes the tower, then: "Ab do aur do!" Papa holds the boundary with a smile: "Tower complete hua, ab shoes. Timer set karte hain — do minute."
Resolution: Timer dings. Rio puts on shoes (with a little help). High-fives all around. "Fair deal done!"
Moral: Ek clear, fair transition — blocks ke baad shoes. Food reward nahi, screen time nahi — sirf fair deal.
''',
    setting: 'Living room floor, blocks scattered, Papa kneeling with Rio\'s shoes',
    sceneDetail: 'Block tower in progress, Rio\'s shoes by the door, timer on phone',
    dialogue: '"Do blocks aur, phir shoes." "Ab do aur do!" "Tower complete, ab shoes. Timer do minute." "Theek hai!"',
    mess: 'Rio wants more blocks, more time. Papa offers clear step: tower complete + two-minute timer = shoes on. Fair deal.',
    innerThought: 'Ek clear sa fair transition sabke liye kaam karta hai — food reward bina, screen time bina.',
    endingBeat: 'Timer dings. Rio puts on shoes. High-five! "Fair deal done!" Sab khush, door ke bahar.',
    defaultCast: ['Rio', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, blocks scattered. Rio: "Do blocks aur!" Papa: "Tower complete, phir shoes!" Timer set. Rio completes tower, timer dings, puts on shoes. Text: "BLOCKS → SHOES 🧱👟" "FAIR DEAL 🤝"

On-Screen Text:
- [0-3s]: "BLOCKS SE SHOES TAK 🧱👟"
- [3-6s]: "RIO: DO BLOCKS AUR! 🧱"
- [6-10s]: "FAIR TRANSITION: TOWER COMPLETE 🤝"
- [10-14s]: "TIMER DINGS! SHOES ON ✅"
- [14-18s]: "FAIR DEAL = DONE! 🤝"
- [18-20s]: "NO FOOD BRIBES. JUST FAIR DEAL. 💡"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio building blocks: "Do blocks aur!" Papa: "Tower complete, phir shoes." Timer set. Text: "DO BLOCKS AUR! 🧱" "FAIR TRANSITION 🤝"

Part 2 (10-20s): 3D Pixar style, 9:16. Rio completes tower, timer dings, puts on shoes. High-five! Text: "TIMER DINGS! SHOES ON ✅" "FAIR DEAL = DONE! 🤝" "NO FOOD BRIBES 💡"

Audio/Dialogue (Hinglish): Papa: "Tower complete, phir shoes." Rio: "Ab do aur do!" Papa: "Tower complete hua, ab shoes. Timer do minute." Rio: "Theek hai!" Timer dings. Rio puts shoes on. "Fair deal done!" High-five!

Part 3 (20-30s): 3D Pixar style, 9:16. Timer dings. Rio puts on shoes. High-five! "Fair deal done!" Sab khush, door ke bahar. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: One clear, fair transition turns "more" into "done" — without food as a reward or screens as bribes.

''',
  ),

HookIdea(
    id: 'idea_27',
    category: 'Child Chaos',
    cover: 'No, Mine, Why — Emotion Validated! 🎭',
    title: 'No, Mine, Why — Emotion Validated! 🎭',
    opening: 'Rio: "No! Mine! Why!" Ria echoes. Mumma validates, sets boundary, no mocking! 🎭',
    problem: 'Rio repeats "No! Mine! Why!" in a loop. Ria echoes. The words escalate until both are upset.',
    lesson: 'Validate the emotion behind the words. Set a clear boundary on behavior. Offer a simple, age-appropriate turn-taking approach. No mocking, no broken-record mimicry.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Rio: "No! Mine! Why!" Mumma validates: "Gussa hai?" Sets boundary. Simple turns. No mocking! 🎭 #EmotionValidation #TurnTaking #SiblingConflict #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Isi concept ko real-life situation mein try karo — consistency se results milti hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria: "Mujhe bhi!" Rio: "No!" He grabs the ball. "Mine!" Ria: "Why!" — not asking, just echoing.
Twist: Mumma kneels: "Gussa hai Rio? Theek hai, gussa hota hai." She names the feeling. "Par ball Ria ke paas bhi aayegi." She sets a simple turn: "Ek minute Ria, ek minute Rio — ginti karke."
Resolution: They take turns — one minute Ria, one minute Rio. Cuty watches, then gets a turn too. "Dono ko mila, ginti se!"
Moral: Validate the feeling. Set the boundary. Simple turns win over mocking.
''',
    setting: 'Living room floor, toy ball between them, Mumma close by',
    sceneDetail: 'Both kids\' hands reaching for the same ball, Mumma kneeling with a gentle hand on each shoulder',
    dialogue: '"Mujhe bhi!" "No!" "Mine!" "Why!" "Gussa hai?" "Ek minute Ria, ek minute Rio."',
    mess: 'Rio grabs ball, Ria echoes "Why!" Words escalate — Mumma intervenes with validation + boundary + simple turns',
    innerThought: 'Mocking escalates. Validation + boundary + simple system = resolution.',
    endingBeat: 'Turns work. One minute each. Cuty gets a turn too. "Dono ko mila, ginti se!" Fair play wins.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, one ball between Rio and Ria. Rio: "No! Mine! Why!" Ria echoes. Mumma kneels: "Gussa hai?" Validates. Simple turn-taking: one minute each. Text: "NO! MINE! WHY! 🎭" "VALIDATE FIRST ❤️" "SIMPLE TURNS ⏱️"

On-Screen Text:
- [0-3s]: "NO! MINE! WHY! 🎭"
- [3-6s]: "VALIDATE FIRST: 'GUSSA HAI?' ❤️"
- [6-10s]: "SIMPLE TURNS ⏱️"
- [10-14s]: "ONE MINUTE EACH ⏱️"
- [14-18s]: "FAIR TURNS = NO MOCKING 🤝"
- [18-20s]: "VALIDATE + BOUNDARY = PEACE 🌱"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio grabs ball: "No! Mine! Why!" Ria echoes. Mumma kneels: "Gussa hai?" Validates. Text: "NO! MINE! WHY! 🎭" "VALIDATE FIRST: 'GUSSA HAI?' ❤️"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma sets simple turns: one minute each. They take turns. Cuty gets a turn too. Text: "SIMPLE TURNS ⏱️" "ONE MINUTE EACH ⏱️" "VALIDATE + BOUNDARY = PEACE 🌱"

Audio/Dialogue (Hinglish): Rio: "No! Mine! Why!" Ria: "Why!" Mumma: "Gussa hai Rio? Theek hai." Rio: "Haan." Mumma: "Ek minute Ria, ek minute Rio — ginti karke." Rio: "Theek hai!" Turns taken. "Fair!"

Part 3 (20-30s): 3D Pixar style, 9:16. Turns work. One minute each. Cuty gets a turn too. "Dono ko mila, ginti se!" Fair play wins. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Validate the emotion behind the words. Set a clear boundary on behavior. Offer a simple, age-appropriate turn-taking approach. No mocking, no broken-record mimicry.

''',
  ),

HookIdea(
    id: 'idea_28',
    category: 'Learning Lesson',
    cover: 'Cuty Stays Close — Scrape Care 🐰🩹',
    title: 'Cuty Stays Close — Scrape Care 🐰🩹',
    opening: 'Ria neeche baithi... Cuty saath bhi baithi. Scrape pehle, cuddle baad! 🐰🩹',
    problem: 'Ria scrapes her knee and sulks. Cuty sits beside her, offering quiet companionship while Mumma provides appropriate first aid.',
    lesson: 'Appropriate first aid for the injury, quiet presence from a companion. Cuty never licks or touches wound-care items. Comfort without lectures.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ria ka scrape, Cuty ka saath, Mumma ki first aid. Cuty sirf saath baitha — lick nahi kiya! Presence over lectures. 🐰🩹 #FirstAid #ComfortNotLectures #RabbitSafety #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Gaadi aane se pehle ek signal lelo — haath pakad kar khade raho, jab tak nahi aayi.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria has a scraped knee and sits on the couch, sulking. "Ouch, bada dukh raha hai."
Twist: Cuty sits beside her, nudges a clean tissue box closer with her nose — no licking, just quiet presence. Mumma cleans the scrape with antiseptic wipe, applies a colorful bandaid. "Pehle saaf karte hain, phir bandaid."
Resolution: They wrap the knee together — no lectures, no "it's okay" speeches. Just quiet presence, proper first aid, and a colorful bandaid. Cuty sits proudly beside the finished job.
Moral: Pehle first aid, phir pyaar. Cuty sirf saath baitha — usne kaam kiya, lick nahi kiya.
''',
    setting: 'Living room floor, Cuty beside Ria on the couch, first aid kit nearby',
    sceneDetail: 'One clean tissue box on the coffee table, Ria\'s scraped knee visible, colorful bandaid ready, Cuty sitting quietly beside her',
    dialogue: '"Ouch, bada dukh raha hai." "Pehle saaf karte hain, phir bandaid." "Cuty, tujhe pata hai?"',
    mess: 'Ria refuses to look at the scrape, keeps pulling her sleeve down. Cuty sits quietly, nudges tissue box — no licking.',
    innerThought: 'The scrape hurts more when she thinks about it. Cuty\'s quiet presence helps more than words.',
    endingBeat: 'They wrap the knee together with a colorful bandaid. Cuty sits proudly beside the finished job. "Good job, Cuty!" Ria smiles.',
    defaultCast: ['Ria', 'Cuty', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, Ria on couch with scraped knee. Cuty sits beside her, nudges tissue box — no licking! Mumma cleans with antiseptic wipe, applies colorful bandaid. Text: "SCRAPE CARE 🩹" "CUTY: QUIET PRESENCE 🐰" "FIRST AID FIRST 🩹"

On-Screen Text:
- [0-3s]: "SCRAPED KNEE 🩹"
- [3-6s]: "CUTY: QUIET PRESENCE 🐰"
- [6-10s]: "FIRST AID FIRST: CLEAN → BANDAID 🩹"
- [10-14s]: "NO LECTURES, JUST PRESENCE 🐰"
- [14-18s]: "NO LICKING! 🚫👅"
- [18-20s]: "FIRST AID + PRESENCE = HEALING 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria sulking with scraped knee. Cuty sits beside her, nudges tissue box — no licking! Mumma cleans with antiseptic wipe. Text: "SCRAPE CARE 🩹" "CUTY: QUIET PRESENCE 🐰" "FIRST AID FIRST 🩹"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma applies colorful bandaid. Cuty sits proudly beside finished job. Text: "NO LECTURES, JUST PRESENCE 🐰" "NO LICKING! 🚫👅" "FIRST AID + PRESENCE = HEALING 💛"

Audio/Dialogue (Hinglish): Ria: "Ouch, bada dukh raha hai!" Mumma calm: "Pehle saaf karte hain, phir bandaid." Ria: "Cuty, tujhe pata hai?" Cuty: *nudges tissue* Mumma: "Good job, Cuty! No licking!" Ria: "Shukriya Mumma, shukriya Cuty!"

Part 3 (20-30s): 3D Pixar style, 9:16. They wrap the knee together with a colorful bandaid. Cuty sits proudly beside the finished job. "Good job, Cuty!" Ria smiles. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Appropriate first aid for the injury, quiet presence from a companion. Cuty never licks or touches wound-care items. Comfort without lectures.

''',
  ),

HookIdea(
    id: 'idea_29',
    category: 'Child Chaos',
    cover: 'Morning Mix-Up: Socks & Bow! 🧦🎀',
    title: 'Morning Mix-Up: Socks & Bow! 🧦🎀',
    opening: 'Sock kahaan? Bow kahaan? Sab kuchh ulta ho gaya — but no sharing personal items! 🧦🎀',
    problem: 'Ria\'s favorite sock is missing. Rio\'s hair bow is missing. A funny morning mix-up — but no sharing personal items.',
    lesson: 'Morning mix-ups happen. Keep personal items separate. Find the right item for the right person — no sharing socks, bows, or other personal items!',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Sock kho gayi, bow kho gaya! Morning mix-up hua par personal items alag rakho. Apna apna, alag alag! 🧦🎀 #MorningMixUp #PersonalItems #SiblingFun #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Tip: Har tip ko try karo aur comment mein batana — community seekha jayega!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria\'s favorite striped sock is missing — "Meri striped sock kahaan hai?" — but it\'s not in the drawer. Rio\'s blue hair bow is missing too — he\'s been wearing Ria\'s pink bow as a wristband (just pretending!).
Twist: Mumma spots the mix-up: "Rio, yeh Ria ka bow hai — baalon ke liye, haath ke liye nahi!" Rio giggles, takes it off. They find Ria\'s striped sock in Rio\'s shoe.
Resolution: "Ab dono milenge!" Bow goes back to Ria\'s hair. Sock goes on Ria\'s foot. Everyone laughs at the mix-up — but no real sharing of personal items.
Moral: Morning mix-ups are funny — but personal items stay personal. Your bow, your sock, your things!
''',
    setting: 'Bedroom, morning, socks in drawer, bows on dresser, shoes by the door',
    sceneDetail: 'Rio wearing Ria\'s pink bow as wristband (gently), Ria\'s striped sock found in Rio\'s shoe, Rio\'s blue bow on dresser',
    dialogue: '"Meri striped sock kahaan hai?" "Rio, yeh Ria ka bow hai — baalon ke liye!" "Meri sock mil gayi!"',
    mess: 'Rio wears Ria\'s pink bow as wristband. Ria\'s striped sock found in Rio\'s shoe. Rio\'s blue bow on dresser. No actual sharing of personal items.',
    innerThought: 'Morning confusion is real — but personal items have their place. Your bow, your sock, your things.',
    endingBeat: 'Bow back in Ria\'s hair. Sock on Ria\'s foot. Everyone laughs. "Apna apna, alag alag!"',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bedroom, morning. Rio wearing Ria\'s pink bow as wristband (gently). Mumma: "Rio, yeh Ria ka bow — baalon ke liye!" Rio giggles, takes it off. Finds Ria\'s striped sock in Rio\'s shoe. Text: "MORNING MIX-UP! 🧦🎀" "BOW = HAIR 🎀" "SOCK = FOOT 🧦"

On-Screen Text:
- [0-3s]: "MORNING MIX-UP! 🧦🎀"
- [3-6s]: "SOCK KAHAAAN? 🧦"
- [6-10s]: "RIO: RIA KA BOW? 😂"
- [10-14s]: "MUMMA: BOW = HAIR ONLY! 🎀🚫"
- [14-18s]: "SOCK = FOOT ONLY 🧦"
- [18-20s]: "PERSONAL ITEMS STAY PERSONAL 💡"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria: "Meri striped sock kahaan hai?" Rio has Ria\'s pink bow on wrist (pretending). Mumma: "Rio, yeh Ria ka bow — baalon ke liye!" Rio giggles, takes bow off. Text: "MORNING MIX-UP! 🧦🎀" "SOCK KAHAAAN? 🧦"

Part 2 (10-20s): 3D Pixar style, 9:16. Finds Ria\'s striped sock in Rio\'s shoe. Puts it on. Text: "BOW = HAIR 🎀🚫" "SOCK = FOOT 🧦" "PERSONAL ITEMS STAY PERSONAL 💡"

Audio/Dialogue (Hinglish): Ria: "Meri striped sock kahaan hai?" Mumma: "Rio, yeh Ria ka bow — baalon ke liye, haath ke liye nahi!" Rio: "Haan, mazaak tha!" Finds sock: "Meri sock yahan thi!" Mumma: "Bow baalon ke liye, sock pairon ke liye!"

Part 3 (20-30s): 3D Pixar style, 9:16. Bow back in Ria's hair. Sock on Ria's foot. Everyone laughs. "Apna apna, alag alag!" Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Morning mix-ups happen. Keep personal items separate. Find the right item for the right person — no sharing socks, bows, or other personal items!

''',
  ),

// Struggle first: open on the moment it goes wrong.
  HookIdea(
    id: 'idea_30',
    category: 'Child Chaos',
    cover: '1 Galti, Bada Mess!',
    title: '1 Galti, Bada Mess!',
    opening: 'Rio ke haath se saare rang gir gaye...',
    problem: 'Rio spills paint everywhere by accident',
    lesson: 'Galti pe gussa nahi, saath mein saaf karo',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Bachche se galti ho jaye toh gussa nahi, saath saaf karo. "Table ko blue dress chahiye thi!" 🎨 #ToddlerMess #ParentingHacks #FunLearningWithPalak #IndianParents #MessyPlay',
    pinnedComment: 'Tip: Damp cloth ready rakho — paint smears fast!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio is painting at the art table. He reaches for the blue cup and it tips over — blue paint spreads across the clean white tablecloth. "Arre, blue paint!" A napkin only smears it wider.
Twist: Mumma moves the paint cup away, gives Rio a damp cloth. "Table ko blue dress chahiye thi." She doesn't scold — she helps.
Resolution: Rio scrubs, watches the blue disappear. The table is clean again, but Rio's hands and cheeks are streaked with blue. He grins: "Main ne saaf kiya!"
Moral: A spill can look huge — but a little help makes it manageable.
''',
    setting: 'Art table, morning, paint cups lined up',
    sceneDetail: 'Blue paint tips onto a clean white tablecloth, napkin smears it wider',
    dialogue: '"Arre, blue paint!" "Table ko blue dress chahiye thi."',
    mess: 'Blue paint spreads across the table, Rio watches wide-eyed',
    innerThought: 'How do you contain a flood with one napkin?',
    endingBeat: 'Rio scrubs, watches blue disappear, ends up streaked with blue himself.',
    defaultCast: ['Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Art table, morning, paint cups lined up. Rio (blue t-shirt, shorts) reaches for blue paint cup, it tips over — blue paint spreads across white tablecloth. Mumma (yellow kurti, top bun) moves the cup away, gives Rio a damp cloth. Text on screen: "OH NO! BLUE! 🎨" "NO SCOld, NO BLAME ❤️" "SAATH MILKE SAAF!"

On-Screen Text:
- [0-3s]: "PAINT SPILL ALERT! 🎨"
- [3-7s]: "BLUE PAINT FLOOD 💙"
- [7-11s]: "DAMP CLOTH TRICK 🧽"
- [11-15s]: "WATCH BLUE DISAPPEAR 💧"
- [15-20s]: "TEAM CLEANUP CHAMPIONS 🏆"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio paints at the art table, reaches for blue cup — it tips! Blue paint spreads across white tablecloth. "Arre, blue paint!" Napkin only smears wider. Text: "PAINT SPILL ALERT! 🎨" "BLUE PAINT FLOOD 💙".

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma moves paint cup away, kneels beside Rio: "Table ko blue dress chahiye thi — let's clean together." Gives damp cloth. Rio scrubs. Text: "DAMP CLOTH TRICK 🧽" "WATCH BLUE DISAPPEAR 💧" "TEAM CLEANUP CHAMPIONS 🏆".

Audio/Dialogue (Hinglish): Rio: "Arre, blue paint!" Mumma: "Table ko blue dress chahiye thi." Rio: "Mujhe maaf karo!" Mumma: "Koi baat nahi — saath milke saaf karte hain." Rio: "Maine saaf kiya!" Mumma: "Haan, achhe se kiya!"

Part 3 (20-30s): 3D Pixar style, 9:16. Table clean but Rio streaked with blue paint, grinning. "Main ne saaf kiya!" Mumma: "Haan, bohot achha!" Text: "TEAM CLEANUP CHAMPIONS 🏆". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A spill can look huge, but a little help together makes it manageable. No scolding — just cleaning side by side.
''',
  ),

  HookIdea(
    id: 'idea_31',
    category: 'Ria Chaos',
    cover: 'Store Mein Badi Mushkil!',
    title: 'Store Mein Badi Mushkil!',
    opening: 'Ria ne kaha — "I want it, I want it!" Poora supermarket ghoom liya.',
    problem: 'Ria has a full meltdown in the grocery store when denied a snack',
    lesson: 'Acknowledge feelings first, then offer the next step: "I see you want chips. We have fruit at home."',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Store mein rona hone ka asar bhi hota hai — pehle bola "main dekhi, tumhara gussa samajh gaya, phir nahi." 🛒 #ToddlerMeltdown #PublicTantrum #FunLearningWithPalak #IndianParents #StayCalm',
    pinnedComment: 'Tip: Floor par baith kar bhi baat chaleti hai — bachcha turant sambhal leta hai.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria spots a packet of chips at the checkout. "Mummy, chips chahiye!" Mumma says no — it's almost lunch. Ria drops to the floor: "I WANT IT!"
Twist: Mumma kneels beside her: "Main dekhi, tumhara gussa samajh gaya. Ab yeh nahi hoga, lekin fruit ke saath kuchh aur chahiye?"
Resolution: Ria cries for two minutes, then sniffles: "Apple?" Mumma: "Haan, apple." They walk out, chips forgotten.
Moral: A meltdown is information — listen first, then guide.
''',
    setting: 'Grocery store checkout lane, afternoon',
    sceneDetail: 'Ria on the floor, crumpled chips packet in hand, Mumma kneeling at eye level',
    dialogue: '"I WANT IT! I WANT IT!" "Main dekhi, tumhara gussa samajh gaya..."',
    mess: 'Ria wails loudly enough that other shoppers look over, Mumma stays calm',
    innerThought: 'The floor is not the enemy — the unmet need is.',
    endingBeat: 'Ria takes the apple, walks out holding Mumma\'s hand, no chips.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Grocery store checkout lane, afternoon. Ria (sparkly pink star dress, pigtails) spots chips at checkout: "Mummy, chips chahiye!" Mumma says no — almost lunch. Ria drops to floor: "I WANT IT!" Text on screen: "CHIPS WANT 💔" "FEELINGS FIRST ❤️" "APPLE TRADE-OFF 🍎"

On-Screen Text:
- [0-3s]: "CHIPS WANT 💔"
- [3-7s]: "FLOOR DROP MELTDOWN 😱"
- [7-11s]: "FEELINGS FIRST ❤️"
- [11-15s]: "APPLE TRADE-OFF 🍎"
- [16-20s]: "HAND IN HAND 🤝"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria grabs chips packet at checkout: "Mummy, chips chahiye!" Mumma: "Nahi beta, lunch lagbhag ho raha hai." Ria drops to floor: "I WANT IT!" Other shoppers glance over. Text: "CHIPS WANT 💔" "FLOOR DROP MELTDOWN 😱".

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma kneels beside her: "Main dekhi, tumhara gussa samajh gaya. Ab chips nahi hoga, lekin fruit ke saath kuchh aur chahiye?" Ria cries two minutes, then sniffles: "Apple?" Mumma: "Haan, apple." Text: "FEELINGS FIRST ❤️" "APPLE TRADE-OFF 🍎".

Audio/Dialogue (Hinglish): Mumma: "Nahi beta, lunch lagbhag ho raha hai." Ria: "I WANT IT! I WANT IT!" Mumma: "Main dekhi, tumhara gussa samajh gaya." Ria (crying): "Chips chahiye!" Ria (sniffling): "Apple?" Mumma: "Haan, apple." Both: "Theek hai!"

Part 3 (20-30s): 3D Pixar style, 9:16. They walk out, Ria holding Mumma's hand, apple in hand, chips forgotten. Text: "HAND IN HAND 🤝". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A meltdown is information — listen first, then guide. Validating feelings before offering alternatives makes transitions smoother.
''',
  ),

  HookIdea(
    id: 'idea_32',
    category: 'Learning Lesson',
    cover: 'Mumma Bhi Thak Gayi!',
    title: 'Mumma Bhi Thak Gayi!',
    opening: 'Mumma: "Bas 5 minute rest." Lies down. Ria tucks her in.',
    problem: 'Mumma needs rest but asks Ria to respect it',
    lesson: 'Thoda sa pause, poori family ke liye',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Mumma ko bhi break chahiye — Ria ne samjha! "Ab paani nahi maangna, okay?" 😴 #MomNeedsRest #ParentingTruth #FunLearningWithPalak #IndianParents #SelfCare',
    pinnedComment: 'Kabhi aapne apne bachche se "5 minute rest" maangi? 😂',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma sits down — "Bas five minute rest." She lies on the floor with a cushion. Ria watches, then tucks a blanket over her: "Ab paani nahi maangna, okay?" Mumma smiles: "Main itni bhi dramatic hoon?"
Twist: Ria says seriously: "Mumma, aap hi toh ho." She brings a small cup of water and sits quietly beside her.
Resolution: Ria stays close without demanding anything. Mumma gets her five minutes, and Ria learns that caring means giving space too.
Moral: When grown-ups rest, children learn that love doesn't always mean fixing — sometimes just being there.
''',
    setting: 'Living room floor, afternoon, cushions scattered',
    sceneDetail: 'One cushion has a small tear on the seam',
    dialogue: '"Ria, pehle cuddle ya paani?" "Ab paani nahi maangna, okay?"',
    mess: 'Ria watches Mumma lie down, unsure if she should disturb her',
    innerThought: 'If I say one word right now, I become part of it.',
    endingBeat: 'Ria sits beside her, brings a small cup of water, sits quietly.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, afternoon, cushions scattered. Mumma lies on the floor with a cushion: "Bas five minute rest." Ria watches, tucks a blanket over her: "Ab paani nahi maangna, okay?" Text on screen: "MUMMY TIRED 😴" "RIA NOTICES 👀" "QUIET TOGETHERNESS 🧘"

On-Screen Text:
- [0-4s]: "MUMMY TIRED 😴"
- [4-8s]: "RIA NOTICES 👀"
- [8-12s]: "GENTLE BOUNDARY SETTER 💛"
- [12-16s]: "QUIET TOGETHERNESS 🧘"
- [16-20s]: "GIVING SPACE IS LOVE ❤️"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma sits down — "Bas five minute rest." Lies on the floor with a cushion. Ria watches, then tucks a blanket over her: "Ab paani nahi maangna, okay?" Mumma: "Main itni bhi dramatic hoon?" Text: "MUMMY TIRED 😴" "RIA NOTICES 👀".

Part 2 (10-20s): 3D Pixar style, 9:16. Ria says: "Mumma, aap hi toh ho." She brings a small cup of water and sits quietly beside her. Text: "GENTLE BOUNDARY SETTER 💛" "QUIET TOGETHERNESS 🧘" "GIVING SPACE IS LOVE ❤️".

Audio/Dialogue (Hinglish): Mumma: "Bas five minute rest... [lies down on floor cushion]" Ria: "Mumma, aap thak gayi ho." Mumma: "Beta, main saambhaa lungi." Ria: "Nahi, main madad karungi. Yeh lo paani." Mumma: "Shukriya beta." Ria: "Haan, bas itna hi kehna tha." Both whisper: "Shhh..." [ticking clock] "Main tumhe samajh sakti hoon."

Part 3 (20-30s): 3D Pixar style, 9:16. Five minutes pass. Mumma sits up, Ria pats the cushion beside her. "Phir se promise?" "Haan." Text: "GIVING SPACE IS LOVE ❤️". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: When grown-ups rest, children learn that love doesn't always mean fixing — sometimes just being there quietly makes all the difference.
''',
  ),

  HookIdea(
    id: 'idea_33',
    category: 'Child Chaos',
    cover: 'Tod Diya!',
    title: 'Tod Diya!',
    opening: 'Car ke do tukde... aur dono ek doosre ko blame kar rahe hain.',
    problem: 'The shared toy breaks and both children blame each other',
    lesson: 'Kaun jeeta nahi, saath mein kaise theek karein',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Toy toota toh blame game nahi — saath theek karo! "Dono car, do laps!" 🚗 #SiblingConflict #ProblemSolving #FunLearningWithPalak #IndianParents #Teamwork',
    pinnedComment: 'Paper tickets trick — try it! One minute each, then together.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Both grab the red car — "Mera pehle!" They argue over whose lap it is for. The car snaps in two.
Twist: Mumma: "Rio one lap, Ria one lap." They make paper tickets — Rio gets #1, Ria gets #2.
Resolution: Cuty sits as ticket checker. One minute each, then together. "Dono car, do laps!"
Ending line: "Next time? Ek ticket, teen dots!"
Moral: Tickets turn fights into fair turns — everyone wins a lap.
''',
    setting: 'Living room floor, red toy car between them, broken in two',
    sceneDetail: 'Paper ticket #1 in Rio\'s hand, ticket #2 in Ria\'s hand, Cuty sits beside the car',
    dialogue: '"Mera pehle!" — "Toh main aakhir mein bhi thi!"',
    mess: 'Both grab the red car, arguing whose lap it is for — it snaps',
    innerThought: 'A ticket system — will it actually work?',
    endingBeat: 'Paper tickets, one minute each, then together — "Dono car, do laps!"',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, red toy car between them, broken in two. Ria (sparkly pink star dress, pigtails) and Rio (blue t-shirt, shorts) both grabbed the car — it snapped. Paper ticket #1 in Rio's hand, #2 in Ria's hand. Cuty the bunny sits beside the car. Text on screen: "CAR BREAK 💔" "TICKET SYSTEM! 🎫" "TEAMWORK WINS 🏆"

On-Screen Text:
- [0-3s]: "CAR TORE IN HALF 💔"
- [3-7s]: "ARGUMENT OVER 🔥"
- [7-11s]: "TICKET SYSTEM! 🎫"
- [11-15s]: "ONE MINUTE EACH ⏱️"
- [16-20s]: "TOGETHER LAPS 🏁"

Part 1 (0-10s): 3D Pixar style, 9:16. Both grab the red car: "Mera pehle!" Arguing over whose lap it is. The car snaps in two. Mumma: "Rio one lap, Ria one lap." Makes paper tickets. Text: "CAR TORE IN HALF 💔" "ARGUMENT OVER 🔥" "TICKET SYSTEM! 🎫".

Part 2 (10-20s): 3D Pixar style, 9:16. Cuty sits as ticket checker. Rio gets #1, Ria gets #2. One minute each, then together. Text: "ONE MINUTE EACH ⏱️" "TOGETHER LAPS 🏁".

Audio/Dialogue (Hinglish): Ria: "Mera pehle!" Rio: "Nahi, mera pehle!" Car snaps: "Crack!" Mumma: "Rio ticket #1, Ria ticket #2." Rio: "Mere round first!" Ria: "Phir mera turn!" Cuty: "Hop!" Both: "Dono car, do laps!"

Part 3 (20-30s): 3D Pixar style, 9:16. Both drive cars together, one lap each. "Dono car, do laps!" Text: "TOGETHER LAPS 🏁". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Tickets turn fights into fair turns — everyone wins a lap. When conflict has a clear system, siblings discover they work better as a team.
''',
  ),

  HookIdea(
    id: 'idea_34',
    category: 'Funny',
    cover: 'Music Sudden Ruko!',
    title: 'Music Sudden Ruko!',
    opening: 'Music bandh ho gayi... Rio freezz!',
    problem: 'Music suddenly stops mid-play, and Rio freezes or protests',
    lesson: 'Name the change, then offer the next step',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Music bandh hui toh bachcha freeze kare? Badlaav name karo, agla kadam dikhao! 🎵 #TransitionTips #ToddlerPlay #FunLearningWithPalak #IndianParents #ParentingHacks',
    pinnedComment: 'Music bandh hone ka signal bana lo — "Gaana khatam, pack up time!"',
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
    sceneDetail: 'Phone playing music on the couch, song cuts off suddenly mid-beat',
    dialogue: '"Music bandh ho gayi. Ab kya karein?"',
    mess: 'Rio freezes, then says "one more minute" instead of crying',
    innerThought: 'This transition is harder than I thought.',
    endingBeat: 'They clean up toys together, soft music restarts.',
    defaultCast: ['Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, afternoon, song playing from phone on the couch. Rio (blue t-shirt, shorts) dancing to his favorite song — music suddenly stops mid-beat. Rio freezes, eyes wide. Mumma kneels: "Music bandh ho gayi. Ab kya karein?" Text on screen: "MUSIC STOPS! 🔇" "FREEZE MODE 😵" "NAME THE CHANGE 🗣️"

On-Screen Text:
- [0-3s]: "MUSIC STOPS! 🔇"
- [3-7s]: "DANCE FREEZE! 😵"
- [7-11s]: "NAME THE CHANGE 🗣️"
- [11-15s]: "CHOICE OFFERED 💡"
- [16-20s]: "TRANSITION WIN! ✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio dancing, phone music cuts off suddenly mid-beat. Rio freezes, eyes wide. Mumma: "Music bandh ho gayi. Ab kya karein?" Text: "MUSIC STOPS! 🔇" "DANCE FREEZE! 😵".

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma offers: "Ek minute aur dance karo, ya turant room saaf karo?" Rio: "Ek minute!" They clean up toys together. Text: "NAME THE CHANGE 🗣️" "CHOICE OFFERED 💡".

Audio/Dialogue (Hinglish): Rio dancing: "La la la!" [music cuts] Rio: "Aaaah!" Mumma: "Music bandh ho gayi. Ab kya karein?" Rio: "Ek minute aur dance karo!" Mumma: "Theek hai — ek minute." Rio: "Phir room saaf karenge!" Both: "Done!"

Part 3 (20-30s): 3D Pixar style, 9:16. Soft music restarts, room clean. "Next time phone use karoongi!" Text: "TRANSITION WIN! ✨". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Badlaav ka intezaar karo, phir agla kadam lagao — naming the change and offering a choice turns disruption into cooperation.
''',
  ),

  HookIdea(
    id: 'idea_35',
    category: 'Funny',
    cover: 'Dabba Ban Gaya Rocket!',
    title: 'Dabba Ban Gaya Rocket!',
    opening: 'Itne saare khilone... aur Rio ko chahiye khaali dabba?',
    problem: 'Expensive toys are ignored; an empty box becomes a spaceship',
    lesson: 'Kam khilone, zyada kalpana',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Mahenga toy ignore, khaala dabba = rocket! 🚀 Imagination > toys. #ImaginationWins #ToddlerPlay #FunLearningWithPalak #IndianParents #OpenEndedPlay',
    pinnedComment: 'Aapke bachche ka "favorite toy" kya hai — box ya toy? 😂',
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
    setting: 'Kitchen, morning, delivery boxes on the counter',
    sceneDetail: 'Empty cardboard box on the kitchen floor, Rio crawling toward it, Robot toy ignored nearby',
    dialogue: '"Papa ke liye cover aaya. Rio ka naya robot bhi aaya."',
    mess: 'Rio ignores the robot and crawls into the empty box',
    innerThought: 'The box is bigger than he is.',
    endingBeat: 'They count down together, "5, 4, 3, 2, 1... chalo!"',
    defaultCast: ['Rio', 'Robot', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen, morning, delivery boxes on the counter. Empty cardboard box on the floor, Robot toy (silver, blue LED eyes) ignored nearby. Rio (blue t-shirt, shorts) crawls toward the box, ignoring the new robot toy. Papa enters. Text on screen: "BOX > ROBOT! 📦" "COUNTDOWN! 5-4-3-2-1" "IMAGINATION WINS 🎉"

On-Screen Text:
- [0-3s]: "NEW ROBOT! 🤖"
- [3-7s]: "BUT THE BOX! 📦"
- [7-11s]: "COUNTDOWN READY! 🔢"
- [11-15s]: "5-4-3-2-1... BLAST OFF! 🚀"
- [16-20s]: "IMAGINATION WINS 🎉"

Part 1 (0-10s): 3D Pixar style, 9:16. Delivery boxes arrive. Papa brings out new Robot toy, but Rio ignores it, crawls into the empty box. Papa: "Ye kabaad mein jayega." Rio: "Ye mera rocket hai!" Text: "NEW ROBOT! 🤖" "BUT THE BOX! 📦".

Part 2 (10-20s): 3D Pixar style, 9:16. Papa puts Robot in the box: "Ye astronaut hai." They count down: "5, 4, 3, 2, 1..." Text: "COUNTDOWN READY! 🔢" "5-4-3-2-1... BLAST OFF! 🚀".

Audio/Dialogue (Hinglish): Papa: "Papa ke liye cover aaya. Rio ka naya robot bhi aaya." Rio (in box): "Mere saath bhi aayega!" Papa: "Abhi toh ye kabaad hi lag raha hai." Rio: "Nahi! Ye mera rocket hai! Aur ye Robot astronaut banega!" Papa: "Bilkul! Chalo, countdown karte hain!" All: "5, 4, 3, 2, 1... Chalo!"

Part 3 (20-30s): 3D Pixar style, 9:16. Box launches (Rio's imagination), Robot inside. Text: "IMAGINATION WINS 🎉". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Kam khilone, zyada kalpana — the best toy costs nothing and takes up no space. An empty box becomes a rocket when imagination drives the play.
''',
  ),

  HookIdea(
    id: 'idea_36',
    category: 'Funny',
    cover: 'Bijli Band Ho Gayi!',
    title: 'Bijli Band Ho Gayi!',
    opening: 'Light flicker, fan ruka. Ria: "Bijli band ho jaye!"',
    problem: 'Power cuts out suddenly and Ria is startled',
    lesson: 'Naam dekar dar ko chhota karna',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Bijli gayi toh bachcha dar gaya? Naam do, dar chhota karo! "Bijli khel rahi thi — ab rest karegi." 💡 #PowerCut #ToddlerFears #FunLearningWithPalak #IndianParents #ValidateFeelings',
    pinnedComment: 'Power cut par aapke bachche ka reaction kaisa hota hai?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Light flickers, fan cuts out mid-hum. Ria tugs Mumma's hand: "Bijli ko bolo, band ho jaye!"
Twist: Mumma kneels: "Thumbs up if you're worried. Bijli khel rahi thi—ab rest karegi."
Resolution: They sit in the quiet. Ria discovers she can hear her own heartbeat. "Thump-thump!" "It means you're safe."
Moral: Naming the noise makes the fear small enough to hold.
''',
    setting: 'Bedroom, bedtime, night light casting soft shadows',
    sceneDetail: 'Night light still glowing, Ria clinging to Mumma in the sudden dark',
    dialogue: '"Bijli band ho gayi! Ab kya karein?"',
    mess: 'Power cuts at bedtime, Ria is afraid of the dark',
    innerThought: 'I should have checked the inverter earlier.',
    endingBeat: 'They sit in the quiet, Ria hears her own heartbeat.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bedroom, bedtime, night light casting soft shadows. Ria (sparkly pink star dress, pigtails) clinging to Mumma. Light flickers, fan cuts out mid-hum. Power gone. Mumma kneels: "Bijli khel rahi thi — ab rest karegi." Text on screen: "DARKNESS FALLS 🌙" "NAAMKARAN ❤️" "SAFE WITH LOVE 💛"

On-Screen Text:
- [0-3s]: "BIJLI BAND! ⚡"
- [3-7s]: "DARKNESS FALLS 🌙"
- [7-11s]: "NAAMKARAN NAME IT 🗣️"
- [11-15s]: "HEARTBEAT FOUND 💓"
- [16-20s]: "SAFE WITH LOVE 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Light flickers, fan cuts out. Ria: "Bijli band ho gayi!" Tugs Mumma's hand. Mumma: "Thumbs up if you're worried." Text: "BIJLI BAND! ⚡" "DARKNESS FALLS 🌙".

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma: "Bijli khel rahi thi — ab rest karegi." Kneels: "Thump-thump!" Ria listens to her own heartbeat. Text: "NAAMKARAN NAME IT 🗣️" "HEARTBEAT FOUND 💓".

Audio/Dialogue (Hinglish): Ria: "Bijli band ho gayi!" Mumma: "Thumbs up if worried." Ria: "Mujhe dar lag raha hai." Mumma: "Bijli khel rahi thi — ab rest karegi." Ria (listening): "Thump-thump!" Mumma: "That means you're safe and strong." Both: "Main theek hoon."

Part 3 (20-30s): 3D Pixar style, 9:16. Night light still glows. They sit in quiet, hand in hand. "Main theek hoon." Text: "SAFE WITH LOVE 💛". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Naming the noise makes the fear small enough to hold — when we acknowledge what frightens them, children discover their own strength and feel safe.
''',
  ),

  HookIdea(
    id: 'idea_37',
    category: 'Learning Lesson',
    cover: 'Blocks Box Mein!',
    title: 'Blocks Box Mein!',
    opening: 'Rio ne saare blocks phailaye... Mumma ne name dia.',
    problem: 'Rio dumps blocks; Mumma names the cleanup action',
    lesson: 'Specific praise builds confidence',
    postFormat: 'Reel',
    strategy: '',
    caption: '"Tumne saare blocks box mein rakhe — thank you!" Specific praise works! 🙌 #SpecificPraise #ToddlerCleanup #FunLearningWithPalak #IndianParents #PositiveParenting',
    pinnedComment: '"Good job" ki jagah "Tumne X kiya" bolo — dekhna farak!',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, box of blocks half-empty, pieces everywhere. Rio (blue t-shirt, shorts) dumps blocks all over the floor. One block hides behind the couch. Mumma points: "Tumne saare blocks box mein rakhe — thank you!" Text on screen: "BLOCK EXPLOSION! 🧱" "NAMED PRAISE! 👏" "TEAM CLEANUP! ✨"

On-Screen Text:
- [0-3s]: "BLOCK EXPLOSION! 🧱"
- [3-7s]: "CHAOTIC FLOOR 😱"
- [7-11s]: "NAMED PRAISE! 👏"
- [11-15s]: "HIDDEN BLOCK HUNT 🔍"
- [16-20s]: "TEAM CLEANUP! ✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio dumps box of blocks everywhere. Mumma points: "Tumne saare blocks box mein rakhe — thank you!" Rio beams. Text: "BLOCK EXPLOSION! 🧱" "CHAOTIC FLOOR 😱" "NAMED PRAISE! 👏".

Part 2 (10-20s): 3D Pixar style, 9:16. Rio spots block behind couch: "Mummy, yeh bhi!" They pick it up together. Papa claps. Text: "HIDDEN BLOCK HUNT 🔍" "TEAM CLEANUP! ✨".

Audio/Dialogue (Hinglish): Rio dumping: "Blocks everywhere!" Mumma: "Tumne saare blocks box mein rakhe — thank you!" Rio beaming: "Maine dekha!" Rio: "Mummy, yeh bhi!" Mumma: "Haan, saath milke." Papa: "Box full, heart full!"

Part 3 (20-30s): 3D Pixar style, 9:16. Empty box, full hearts. Papa: "Box full, heart full." Text: "TEAM CLEANUP! ✨". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: "Tumne saare blocks box mein rakhe — thank you!" — specific praise that names what they did builds confidence and turns cleanup into a team win.
''',
  ),

  HookIdea(
    id: 'idea_38',
    category: 'Learning Lesson',
    cover: 'Bhaago Mat? Dheere Chalo!',
    title: 'Bhaago Mat? Dheere Chalo!',
    opening: 'Mumma ne "mat bhaago" bola... Rio aur tez bhaaga!',
    problem: 'A child ignores "don\'t" but follows a clear "do"',
    lesson: 'Kya nahi karna, nahi — kya karna hai, woh batao',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Bachche "mat bhaago" sunta nahi magar "karo" sun leta hai — ek word ka fark poora behavior badalta hai! ❤️ #ToddlerTips #ParentingHack #FunLearningWithPalak #IndianParents #PositiveDiscipline',
    pinnedComment: 'Tip: "Mat bhaago!" ka jawab "Ungli pakdo!" do — ek word change se hi behavior badalta hai! ❤️',
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
PROMPT: 3D Pixar animation style, vertical 9:16. Society parking lot, afternoon, red car stopped at a crossing line. Rio (blue t-shirt, shorts) runs ahead toward the road. Mumma calls out: "Rio, mat bhaago!" Text on screen: "MAT BHAAGO ❌" "UNGLI PAKDO ✅"

On-Screen Text:
- [0-3s]: "RIO, MAT BHAAGO! ❌"
- [3-7s]: "AUR TEZ BHAAGA! 🏃"
- [7-12s]: "UNGLI PAKDO ✅"
- [12-16s]: "GAADI AATI HAI! 🚗"
- [16-20s]: "SAATH CROSS KARO 🤝"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio runs ahead toward the parking exit. Mumma: "Rio, mat bhaago!" Rio runs even faster. Mumma catches up, kneels to his level: "Rio, meri ungli pakdo." Rio pauses: "Kyun?" Text: "RIO, MAT BHAAGO! ❌" "AUR TEZ BHAAGA! 🏃"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma: "Gaadi aati hai. Ungli pakdo, hum dono saath cross karenge." Rio grips her hand tightly. They walk slowly together toward the red car, which waits for them. Text: "UNGLI PAKDO ✅" "GAADI AATI HAI! 🚗"

Audio/Dialogue (Hinglish): Mumma: "Rio, mat bhaago!" Rio keeps running. Mumma: "Rio, meri ungli pakdo." Rio: "Kyun?" Mumma: "Gaadi aati hai. Ungli pakdo, hum dono saath cross karenge." Rio grips her hand: "Theek hai, Mumma."

Part 3 (20-30s): 3D Pixar style, 9:16. Both cross the road together, hand in hand, the red car waiting patiently. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Kya nahi karna hai, woh batana kaafi nahi — kya karna hai, woh batao. Telling a child what to do works better than telling them what not to do.
''',
  ),


  // Warm lesson: gentle stories that end on something a parent wants to keep.
  HookIdea(
    id: 'idea_39',
    category: 'Learning Lesson',
    cover: 'Pyaar Bhi, Rule Bhi',
    title: 'Pyaar Bhi, Rule Bhi',
    opening: 'Rio ne phir se rule toda... par Mumma ne chillaaya nahi.',
    problem: 'Holding a boundary kindly instead of giving in or shouting',
    lesson: 'Pyaar ke saath rule, bachcha safe mehsoos karta hai',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Boundary todi toh chillaaye nahi — pyaar se samjhaya! "Haan beta, tumne kara. Par main tumhe pyar karti hoon." ❤️ #GentleBoundaries #ParentingWithLove #FunLearningWithPalak #IndianParents #RespectfulParenting',
    pinnedComment: 'Rule + pyaar = bachcha safe feel karta hai. Try karo!',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen counter, morning, cookie jar on the table. Rio (blue t-shirt, shorts, holding cookie) sneaks from the jar again. Mumma kneels: "Haan beta, tumne kara. Par main tumhe pyar karti hoon." Text on screen: "COOKIE SNATCH! 🍪" "LOVE BOUNDARY ❤️" "ASK NEXT TIME 💛"

On-Screen Text:
- [0-3s]: "COOKIE SNATCH! 🍪"
- [3-7s]: "CAUGHT RED-HANDED 😳"
- [7-11s]: "BOUNDARY WITH LOVE ❤️"
- [11-15s]: "ASK NEXT TIME 💛"
- [16-20s]: "PROMISE MADE 🌱"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio sneaks another cookie from the jar. Mumma catches him: "Haan beta, tumne kara." Instead of shouting, Mumma kneels: "Par main tumhe pyar karti hoon." Text: "COOKIE SNATCH! 🍪" "CAUGHT RED-HANDED 😳" "BOUNDARY WITH LOVE ❤️".

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma: "Kal se pehle puchna — theek hai?" Rio: "Haan Mummy, promise!" Text: "ASK NEXT TIME 💛".

Audio/Dialogue (Hinglish): Rio (mouth half-full): "Bas ek hi chhota sa..." Mumma gentle: "Haan beta, tumne kara. Par main tumhe pyar karti hoon." Rio: "Mujhe maaf karo!" Mumma: "Kal se pehle puchna — theek hai?" Rio: "Promise! Next time I'll ask pehle!" Both: "Phir se promise!"

Part 3 (20-30s): 3D Pixar style, 9:16. Cookie jar closed. "Phir se promise?" "Haan." Text: "PROMISE MADE 🌱". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Pyaar ke saath rule set karna — when boundaries are held with love instead of anger, children learn safety and respect. A simple promise becomes a moment of connection.
''',
  ),

  HookIdea(
    id: 'idea_40',
    category: 'Learning Lesson',
    cover: 'Bag On Floor!',
    title: 'Bag On Floor!',
    opening: 'Mumma ke saath bag gir gaya, Ria ne turant pick up kiya.',
    problem: 'Ria sees Mumma tired and picks up the bag from the floor',
    lesson: 'A child noticing and helping without being asked',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ria ne dekha Mumma thak gayi — bag uthaya bina puchhe! "Tum itni thak gayi ho!" ❤️ #ChildEmpathy #UnaskedHelp #FunLearningWithPalak #IndianParents #LittleHelpers',
    pinnedComment: 'Aapka bachcha kab aapki madad kiya bina puchhe? 🥹',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, afternoon. Mumma slumped on the couch, bag beside her. Ria (sparkly pink star dress, pigtails) notices, picks up the bag from the floor and hands it. Mumma starts to take it back: "Maine kaha tha, main saambhaa lunga." Text on screen: "NOTICED TIREDNESS 👀" "SMALL HELP 💛" "GIVING SPACE TO LOVE ❤️"

On-Screen Text:
- [0-3s]: "MUMMA TIRED 😴"
- [3-7s]: "NOTICED WITHOUT WORDS 👀"
- [7-11s]: "SMALL HELP 💛"
- [11-15s]: "ALLOWING LOVE ❤️"
- [16-20s]: "QUIET TOGETHERNESS 🧘"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria sees Mumma tired, picks up bag from floor. "Tum itni thak gayi ho!" Mumma tries to take it back: "Maine kaha tha, main saambhaa lunga." Text: "MUMMA TIRED 😴" "NOTICED WITHOUT WORDS 👀".

Part 2 (10-20s): 3D Pixar style, 9:16. Ria: "Mere saath chalo, main saambhal ke rakhti hoon." Mumma lets her help, ruffles her hair. Text: "SMALL HELP 💛" "ALLOWING LOVE ❤️".

Audio/Dialogue (Hinglish): Ria: "Tum itni thak gayi ho!" Mumma: "Main saambhaa lunga." Ria: "Nahi Mummy, main khud karke doonga." Mumma: "Shukriya beta." Ria: "Tumhara saath hi toh maza aata hai." Both: "Shukriya."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria sits beside Mumma, hands her the bag. "Tumhara saath hi toh maza aata hai." Text: "QUIET TOGETHERNESS 🧘". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Children see tiredness before we admit it, and small hands can still hold a big bag — unasked help is the purest form of love in action.
''',
  ),


  // Navratri: Problem → Jugaad → Result → Moral.
HookIdea(
    id: 'idea_41',
    category: 'Navratri',
    cover: 'Garba Se Ghar Kaise Laayein?',
    title: 'Garba Se Ghar Kaise Laayein?',
    opening: 'Ria nach rahi thi Garba mein... Mumma boli "Chalo ghar!" Ria: "Nahi!"',
    problem: 'Child refuses to leave a fun event when it\'s time to go',
    lesson: 'Give a warning, offer a small keepsake, and make the goodbye a promise to return',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Garba mein bachcha ghar nahi jaana chahta? Ek warning, ek sticker, aur "kal phir milenge!" 🪔 #NavratriWithKids #ParentingHack #FunLearningWithPalak #IndianParents #GarbaTime',
    pinnedComment: 'Tip: Garba se pehle 5 minute "one more song" sunao — phir packup signal dikhao',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: true,
    storyDetail: '''
Story: Ria is dancing happily at Garba, but when Mumma says it's time to leave, she protests — "Nahi, aur ghoomna hai!"
Twist: Ria spots other parents also packing up their kids — "Dekho, sab bachche yahan se jaa rahe hain!"
Resolution: Mumma gives Ria a "Garba star" sticker and lets her put her tiny bangles in her pocket to keep for home — "Kal phir milenge!"
Moral: One more song, then it's time to go — goodbyes feel easier with a small promise.
''',
    setting: 'Garba ground, evening, fairy lights strung, Ria in chaniya choli',
    sceneDetail: 'Garba circle mid-dance, fairy lights overhead, other families already packing up at the edges',
    dialogue: '"Nahi, aur ghoomna hai!" "Kal phir milenge!"',
    mess: 'Ria plants her feet mid-circle, refusing to stop even as the music winds down',
    innerThought: 'One more song always turns into five. Tonight I need a plan, not a fight.',
    endingBeat: 'Ria pockets her Garba star sticker and tiny bangles, waving goodbye to the circle. "Kal phir milenge!"',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Garba ground, evening, fairy lights overhead. Mumma: "Chalo ghar!" Ria plants her feet: "Nahi, aur ghoomna hai!" Text on screen: "GARBA SE GHAR KAISE LAAYEIN? 🪔" "EK WARNING, EK STICKER! ⭐"

On-Screen Text:
- [0-3s]: "CHALO GHAR! 🏠"
- [3-7s]: "NAHI, AUR GHOOMNA HAI! 🙅"
- [7-12s]: "SAB BACHCHE JAA RAHE HAIN 👀"
- [12-16s]: "GARBA STAR STICKER! ⭐"
- [16-20s]: "KAL PHIR MILENGE! 👋"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma: "Chalo ghar!" Ria protests: "Nahi, aur ghoomna hai!" Ria spots other families packing up too: "Dekho, sab bachche yahan se jaa rahe hain!" Text: "CHALO GHAR! 🏠" "NAHI, AUR GHOOMNA HAI! 🙅"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma gives Ria a Garba star sticker and lets her pocket her tiny bangles to keep: "Kal phir milenge!" Text: "GARBA STAR STICKER! ⭐" "KAL PHIR MILENGE! 👋"

Audio/Dialogue (Hinglish): Mumma: "Chalo ghar!" Ria: "Nahi, aur ghoomna hai!" Ria noticing: "Dekho, sab bachche yahan se jaa rahe hain!" Mumma: "Ye sticker tumhare liye, aur bangles pocket mein rakh lo. Kal phir milenge!" Ria: "Theek hai, Mumma!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria pockets her sticker and bangles, waving goodbye to the circle: "Kal phir milenge!" Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: One more song, then it's time to go — goodbyes feel easier with a small promise.
''',
  ),

  HookIdea(
    id: 'idea_42',
    category: 'Navratri',
    cover: 'Garba Mein Bachcha Roye? Quiet Corner!',
    title: 'Garba Mein Bachcha Roye? Quiet Corner!',
    opening: 'Garba ka dhol baj raha tha... Cuty apne kaan duba ke ro rahi thi.',
    problem: 'Loud music and crowds overwhelm a sensitive child at a festival',
    lesson: 'Find a quiet spot beforehand; let the child celebrate at their own pace',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Garba mein bachcha roye toh? Quiet corner dhundho, uske pace pe celebrate karo! 🪔 #NavratriTips #ToddlerLife #FunLearningWithPalak #IndianParents #SensoryFriendly',
    pinnedComment: 'Tip: Venue par pehle se quiet family corner dhoondh ke rakhein!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: true,
    storyDetail: '''
Story: Ria and Rio are excited for Garba, but the loud dhol and flashing lights make Cuty cover her ears and cry.
Twist: Mumma moves the kids to the quiet corner where Daadi is sitting — "Yahan se bhi Garba dikhai dega!"
Resolution: Daadi teaches Cuty to clap along to a softer beat, and soon Cuty is smiling and joining in her own way.
Moral: Every child celebrates differently — finding their comfort rhythm is its own kind of joy.
''',
    setting: 'Garba ground, evening, loud dhol, Cuty covering ears',
    sceneDetail: 'Garba ground at peak volume, dhol drums thumping, flashing string lights, Cuty with paws over her ears',
    dialogue: '"Yahan se bhi Garba dikhai dega!"',
    mess: 'Cuty presses her paws to her ears and curls up, overwhelmed by the drums and flashing lights',
    innerThought: 'The noise that thrills Ria and Rio is too much for Cuty — she needs a different way in, not a push through.',
    endingBeat: 'Daadi claps a softer beat beside Cuty; Cuty uncurls, smiles, and claps along at her own pace.',
    defaultCast: ['Ria', 'Mumma', 'Daadi'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Garba ground, evening, dhol drums thumping, string lights flashing. Ria and Rio dance excitedly. Cuty presses her paws over her ears and curls up. Text on screen: "GARBA MEIN BACHCHA ROYE? 😢" "QUIET CORNER! 🤫"

On-Screen Text:
- [0-3s]: "LOUD DHOL! 🥁"
- [3-7s]: "CUTY OVERWHELMED 😢"
- [7-12s]: "QUIET CORNER MILA! 🪑"
- [12-16s]: "SOFTER BEAT 👏"
- [16-20s]: "APNE PACE SE JOY! 🌱"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria and Rio dance excitedly to the loud dhol. Cuty curls up, paws over ears, overwhelmed by the noise and flashing lights. Text: "LOUD DHOL! 🥁" "CUTY OVERWHELMED 😢"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma moves the kids to the quiet corner where Daadi sits: "Yahan se bhi Garba dikhai dega!" Daadi claps a softer beat beside Cuty. Text: "QUIET CORNER MILA! 🪑" "SOFTER BEAT 👏"

Audio/Dialogue (Hinglish): Mumma: "Yahan se bhi Garba dikhai dega!" Daadi claps softly: "Dekho, hum yahan se bhi dekh sakte hain." Cuty slowly uncurls, claps along. Daadi: "Tumhara apna pace, apna joy."

Part 3 (20-30s): 3D Pixar style, 9:16. Cuty uncurls, smiles, and claps along at her own pace beside Daadi. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Every child celebrates differently — finding their comfort rhythm is its own kind of joy.
''',
  ),

  HookIdea(
    id: 'idea_43',
    category: 'Navratri',
    cover: 'Garba Snack Boundary!',
    title: 'Garba Snack Boundary!',
    opening: 'Ria Garba ke liye taiyaar... par "Mummy, chips chahiye!"',
    problem: 'Child asks for unhealthy snacks before a festival event',
    lesson: 'Pack a healthy snack box; allow one small treat after the first activity — no shaming',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Garba jaate waqt bachche ke snack tantrums? Lunch box mein favorite healthy snack saath le jao! 🥜 #NavratriFood #ToddlerTips #FunLearningWithPalak #IndianParents #HealthySnacks',
    pinnedComment: 'Tip: Small snack pouch — 5 bites before Garba, 5 after. Tantrum-free!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: true,
    storyDetail: '''
Story: Ria is ready for Garba but keeps asking for chips and sweets, saying "Mummy, bhookh lagi hai!"
Twist: Mumma offers the healthy snack box she packed — "Pehle yeh khao, phir Garba!" — but Ria still wants the chips.
Resolution: Mumma lets Ria choose one small sweet after the first round of Garba — balancing treat and fun.
Moral: Hunger at parties is often excitement — redirect with healthy fuel, then a small treat.
''',
    setting: 'Society compound, afternoon snack time before Garba',
    sceneDetail: 'Society compound, snack box open on the table, chips packet visible nearby',
    dialogue: '"Mummy, bhookh lagi hai! Chips chahiye!" "Pehle yeh khao, phir Garba!"',
    mess: 'Ria keeps pointing at the chips packet even after the healthy snack box is opened in front of her',
    innerThought: 'She is not really hungry for chips — she is hungry for the excitement starting around her.',
    endingBeat: 'After the first round of Garba, Ria picks one small sweet from the treat box, happy and full.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Society compound, afternoon, snack box open on the table, a chips packet visible nearby. Ria: "Mummy, bhookh lagi hai! Chips chahiye!" Text on screen: "GARBA SNACK BOUNDARY! 🥜" "PEHLE YEH, PHIR GARBA! ✅"

On-Screen Text:
- [0-3s]: "CHIPS CHAHIYE! 🍟"
- [3-7s]: "PEHLE YEH KHAO 🥜"
- [7-12s]: "PHIR BHI CHIPS MAANGTI HAI 👀"
- [12-16s]: "FIRST ROUND GARBA! 🪔"
- [16-20s]: "EK SWEET, HAPPY AUR FULL! 😊"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria points at the chips packet: "Mummy, bhookh lagi hai! Chips chahiye!" Mumma opens the healthy snack box: "Pehle yeh khao, phir Garba!" Ria keeps pointing at the chips anyway. Text: "CHIPS CHAHIYE! 🍟" "PEHLE YEH KHAO 🥜"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria eats from the snack box and dances through the first round of Garba. Text: "FIRST ROUND GARBA! 🪔"

Audio/Dialogue (Hinglish): Ria: "Mummy, bhookh lagi hai! Chips chahiye!" Mumma: "Pehle yeh khao, phir Garba!" Ria eating: "Theek hai..." Mumma after the first round: "Ab ek chhota sweet le lo." Ria: "Yay!"

Part 3 (20-30s): 3D Pixar style, 9:16. After the first round of Garba, Ria picks one small sweet from the treat box, happy and full. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Hunger at parties is often excitement — redirect with healthy fuel, then a small treat.
''',
  ),

  HookIdea(
    id: 'idea_44',
    category: 'Navratri',
    cover: 'Late Night Garba Vs Neend!',
    title: 'Late Night Garba Vs Neend!',
    opening: 'Raat 10 baje... Ria nach rahi thi, phir achanak: "Mummy, thak gayi!"',
    problem: 'Child enjoys late-night festivities but gets overtired and cranky',
    lesson: 'Set a clear end time; bring a comfort item; transition gently to bedtime',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Late-night Garba vs bachche ki sleep! 9 baje tak enjoy karo, phir cozy bedtime. 🌙 #LateNightParenting #Navratri #FunLearningWithPalak #IndianParents #BedtimeRoutine',
    pinnedComment: 'Tip: Toddler ka comfort item (chhoti blanket ya soft toy) zaroor saath rakhein.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: true,
    storyDetail: '''
Story: It's 10 PM and Ria is enjoying Garba, but suddenly she yawns and says, "Mummy, main thak gayi hoon."
Twist: Mumma checks the clock — only one more song left, but Ria is already sleepy and cranky.
Resolution: Mumma whispers, "Ek last dance, then straight to bed" — Ria dances one more time, then happily goes home.
Moral: Late nights are okay sometimes, but knowing the end is near helps kids say goodbye.
''',
    setting: 'Garba ground, 10 PM, party music still audible, Ria yawning',
    sceneDetail: 'Garba ground near the exit, 10 PM, Ria\'s eyelids drooping between claps',
    dialogue: '"Mummy, main thak gayi hoon." "Ek last dance, phir seedha bed."',
    mess: 'Ria rubs her eyes between dance steps, caught between wanting to stay and needing to sleep',
    innerThought: 'She would dance through exhaustion all night if I let her. Naming the end helps her let go of it.',
    endingBeat: 'Ria dances her last song with a sleepy grin, then walks out holding Mumma\'s hand, already half-asleep.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Garba ground near the exit, 10 PM, party music still audible. Ria's eyelids droop between claps. "Mummy, main thak gayi hoon." Text on screen: "LATE NIGHT GARBA VS NEEND! 🌙" "EK LAST DANCE, PHIR BED! 😴"

On-Screen Text:
- [0-3s]: "10 PM, STILL DANCING! 🪔"
- [3-7s]: "MAIN THAK GAYI HOON 😴"
- [7-12s]: "EK LAST DANCE 💃"
- [12-16s]: "PHIR SEEDHA BED 🛏️"
- [16-20s]: "HAPPILY GHAR CHALO 🏠"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria yawns mid-step: "Mummy, main thak gayi hoon." Mumma checks the clock, kneels beside her. Text: "10 PM, STILL DANCING! 🪔" "MAIN THAK GAYI HOON 😴"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma whispers: "Ek last dance, phir seedha bed." Ria dances one more time with a sleepy grin. Text: "EK LAST DANCE 💃" "PHIR SEEDHA BED 🛏️"

Audio/Dialogue (Hinglish): Ria: "Mummy, main thak gayi hoon." Mumma: "Ek last dance, phir seedha bed." Ria sleepy: "Theek hai..." Mumma: "Chalo, ghar chalte hain."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria walks out holding Mumma's hand, already half-asleep, happy. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Late nights are okay sometimes, but knowing the end is near helps kids say goodbye.
''',
  ),

  HookIdea(
    id: 'idea_45',
    category: 'Navratri',
    cover: 'Outfit Pehante Hi Rona Shuru? Comfort First!',
    title: 'Outfit Pehante Hi Rona Shuru? Comfort First!',
    opening: 'Outfit toh cute hai... par bachcha sirf "nikal do, nikal do" bol raha hai!',
    problem: 'Fancy clothes, tight waistbands, or heavy accessories irritate a toddler',
    lesson: 'Cute outfit se pehle comfortable outfit!',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Navratri outfit pehna diya, ab bachcha chidchid kar raha hai? Comfort pe focus karo — style apne aap aayega! 👗 #NavratriFashion #ToddlerLife #FunLearningWithPalak #IndianParents #ComfortFirst',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Changing room, pre-party, mirror lit. Ria tugs at her new lehenga: "Nikal do, nikal do!" One strap keeps slipping. Text on screen: "OUTFIT PEHANTE HI RONA SHURU? 👗" "COMFORT FIRST! ✅"

On-Screen Text:
- [0-3s]: "NEW LEHENGA! ✨"
- [3-7s]: "NIKAL DO, NIKAL DO! 😣"
- [7-12s]: "OPTION ONE OR TWO? 🤔"
- [12-16s]: "COMFY CHANIYA! 👗"
- [16-20s]: "MAIN KHOOBSURAT LAG RAHI HOON! 💃"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria tugs at her itchy lehenga: "Nikal do, nikal do!" One strap keeps slipping. Mumma kneels: "Option one, lehenga without the heavy dupatta. Option two, comfortable chaniya." Text: "NEW LEHENGA! ✨" "NIKAL DO, NIKAL DO! 😣"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria picks Option 2 — comfy chaniya and light jhumkas. She twirls in front of the mirror, grinning. Text: "COMFY CHANIYA! 👗" "MAIN KHOOBSURAT LAG RAHI HOON! 💃"

Audio/Dialogue (Hinglish): Ria: "Yeh bahut tight hai, Mumma!" Mumma: "Option one, lehenga without the heavy dupatta. Option two, comfortable chaniya." Ria picking: "Yeh wala!" Ria twirling: "Maa, main khoobsurat lag rahi hoon!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria sits on the bed with Mumma, comfortable and happy, ready for the party. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Comfort before style — when kids feel good, they shine.
''',
  ),

  HookIdea(
    id: 'idea_46',
    category: 'Navratri',
    cover: 'Archived — Generic Content',
    title: 'Archived — Generic Content',
    opening: 'Archived — generic content.',
    problem: 'Archived: no real child problem',
    lesson: 'No real child problem',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Chhote bachchon ko Garba mein kaise include karein? Simple steps aur extra smiles — perfection se zyada khushi zaroori hai. #InclusiveGarba #KidsDance #FunLearningWithPalak #NavratriTips #ToddlerRoutine',
    pinnedComment: 'Tip: Toddler ke saath simple 2-step taali banayein — kids energy copy karte hain!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: true,
    storyDetail: '''
Story: Ria sees older kids dancing and wants to join, but she can't follow the complex steps — "Mummy, main nahi kar paa rahi!"
Twist: Papa joins her with a simple 2-step twist — "Ria-style dance, papa-style dance!" — and soon Rio and Cuty copy them.
Resolution: Ria's simple steps become the hit of the circle — everyone wants to learn the "toddler twist."
Moral: You don't need to follow — it's better to create your own way to celebrate.
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
    id: 'idea_47',
    category: 'Navratri',
    cover: 'Late For Garba, Toddler Not Ready!',
    title: 'Late For Garba, Toddler Not Ready!',
    opening: 'Garba ke liye sab taiyyar the... par bachcha joote pehan hi nahi raha tha!',
    problem: 'Parents are ready but the toddler refuses to get dressed or put on shoes',
    lesson: 'Ready hone ka pressure kam, routine simple rakho — game banao!',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Garba party ke liye late ho rahe hain aur bachcha ready hi nahi? Game banao, pressure nahi! 👟 #LastMinuteGarba #ToddlerRoutine #FunLearningWithPalak #IndianParents #ParentingHack',
    pinnedComment: 'Tip: Shoes pehne ke baad "Garba star" sticker challenge try karke dekhiye!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Garba is starting in 5 minutes, but Ria is still struggling with her jootey — "Jootey pehne mein dikkat ho rahi hai!"
Twist: Papa turns it into a game — "Jootey pehne, superhero ban jao!" — Ria giggles and slips them on.
Resolution: Ria runs to join the Garba circle just in time, her "superhero jootey" clicking as she dances.
Moral: Rushing creates resistance — transform the race into play and everything falls into place.
''',
    setting: 'Bedroom, evening, outfit laid out on the bed, shoes by the door',
    sceneDetail: 'One shoe strap keeps slipping, Ria tugging at it in frustration',
    dialogue: '"Jootey pehne mein dikkat ho rahi hai!" "Jootey pehne, superhero ban jao!"',
    mess: 'Ria struggles with her shoe strap while the clock ticks down to Garba time',
    innerThought: 'We will miss the first aarti.',
    endingBeat: 'Ria runs to join the Garba circle just in time, her "superhero jootey" clicking as she dances.',
    defaultCast: ['Ria', 'Mumma', 'Papa'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bedroom, evening, outfit laid out on the bed, shoes by the door. Garba starts in 5 minutes. Ria tugs at her shoe strap: "Jootey pehne mein dikkat ho rahi hai!" Text on screen: "GARBA MEIN LATE?! ⏰" "GAME BANAO, PRESSURE NAHI! 🦸"

On-Screen Text:
- [0-3s]: "5 MINUTE MEIN GARBA! ⏰"
- [3-7s]: "JOOTEY NAHI PEHEN PAA RAHI! 👟"
- [7-12s]: "SUPERHERO BAN JAO! 🦸"
- [12-16s]: "GIGGLING, SLIPS THEM ON 😄"
- [16-20s]: "GARBA CIRCLE MEIN! 🪔"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria struggles with her shoe strap, frustrated: "Jootey pehne mein dikkat ho rahi hai!" Papa kneels beside her. Text: "5 MINUTE MEIN GARBA! ⏰" "JOOTEY NAHI PEHEN PAA RAHI! 👟"

Part 2 (10-20s): 3D Pixar style, 9:16. Papa turns it into a game: "Jootey pehne, superhero ban jao!" Ria giggles and slips them on. They run out together. Text: "SUPERHERO BAN JAO! 🦸" "GIGGLING, SLIPS THEM ON 😄"

Audio/Dialogue (Hinglish): Ria: "Jootey pehne mein dikkat ho rahi hai!" Papa: "Jootey pehne, superhero ban jao!" Ria giggling: "Main superhero hoon!" Papa: "Chalo, Garba shuru hone wala hai!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria runs to join the Garba circle just in time, her "superhero jootey" clicking as she dances. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Rushing creates resistance — transform the race into play and everything falls into place.
''',
  ),

  HookIdea(
    id: 'idea_48',
    category: 'Navratri',
    cover: 'Garba Crowd Mein Bachcha Safe!',
    title: 'Garba Crowd Mein Bachcha Safe!',
    opening: 'Garba floor packed tha... Ria ko dhakka laga, woh Mumma se chipak gayi.',
    problem: 'Crowded festival overwhelm a toddler; child gets bumped and scared',
    lesson: 'Pre-identify a family meeting spot; hold hands; lift child for a better view',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Crowded Garba mein toddler ko safe kaise rakhein? Family boundary banayein, sides mein enjoy karein! 🪔 #SafeGarba #CrowdedEvents #FunLearningWithPalak #IndianParents #CrowdSafety',
    pinnedComment: 'Tip: Event entry par hi family corner aur quiet spot pehle dekh lein.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: true,
    storyDetail: '''
Story: The Garba floor is packed and Ria gets accidentally bumped — she looks scared and clings to Mumma.
Twist: Mumma lifts Ria onto her shoulders so she can see over the crowd — "Ab dekho, yeh sab kuch badiya lag raha hai!"
Resolution: From above, Ria sees the beautiful lights and starts waving at other dancers — her fear turns to wonder.
Moral: A new perspective can turn overwhelm into magic — sometimes elevation helps us see the beauty.
''',
    setting: 'Garba ground, peak hour, crowd moving, Ria on Mumma\'s shoulders',
    sceneDetail: 'Garba ground at peak hour, a dense crowd of dancers, Mumma lifting Ria onto her shoulders',
    dialogue: '"Ria, mere paas aao!" "Ab dekho, yeh sab kuch badiya lag raha hai!"',
    mess: 'Ria gets jostled by the crowd, loses her footing for a second, and clings tight to Mumma\'s leg',
    innerThought: 'From down here the crowd feels like a wall. She just needs a different view of it.',
    endingBeat: 'From Mumma\'s shoulders, Ria waves at the dancers below, fear melted into delight.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Garba ground at peak hour, a dense crowd of dancers. Ria gets jostled, clings tight to Mumma's leg, scared. Text on screen: "GARBA CROWD MEIN BACHCHA SAFE! 🪔" "NAYA PERSPECTIVE! 👀"

On-Screen Text:
- [0-3s]: "CROWD DENSE HO GAYA! 👥"
- [3-7s]: "RIA SCARED, CLINGS TIGHT 😨"
- [7-12s]: "MUMMA KE SHOULDERS PE! 🙆"
- [12-16s]: "AB DEKHO, BADIYA LAG RAHA HAI! ✨"
- [16-20s]: "FEAR TO WONDER! 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. The crowd presses close, Ria gets jostled and clings tight to Mumma's leg, scared. Text: "CROWD DENSE HO GAYA! 👥" "RIA SCARED, CLINGS TIGHT 😨"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma lifts Ria onto her shoulders: "Ab dekho, yeh sab kuch badiya lag raha hai!" Ria sees the lights from above and starts waving at the dancers. Text: "MUMMA KE SHOULDERS PE! 🙆" "AB DEKHO, BADIYA LAG RAHA HAI! ✨"

Audio/Dialogue (Hinglish): Ria scared: "Mumma!" Mumma lifting her up: "Ria, mere paas aao! Ab dekho, yeh sab kuch badiya lag raha hai!" Ria delighted: "Wow, kitna pretty hai!"

Part 3 (20-30s): 3D Pixar style, 9:16. From Mumma's shoulders, Ria waves at the dancers below, fear melted into delight. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A new perspective can turn overwhelm into magic — sometimes elevation helps us see the beauty.
''',
  ),


  HookIdea(
    id: 'idea_49',
    category: 'Navratri',
    cover: 'Festival Prep Mein Bachche Ko Kaise Sambhalein?',
    title: 'Festival Prep Mein Bachche Ko Kaise Sambhalein?',
    opening: 'Mumma decoration mein busy thi... aur bachcha bola "mere saath khelo na!"',
    problem: 'Parents are busy with festival preparations and the toddler seeks constant attention',
    lesson: 'Har baar alag playtime zaroori nahi — bachche ko apne saath chhote kaamo mein shaamil karo',
    postFormat: 'Reel',
    strategy: 'parenting-relatability',
    caption: 'Navratri preparations mein bachche ko time nahi mil raha? Unhe helping hands banaiye! 🪔 #MomLife #NavratriPrep #FunLearningWithPalak #IndianParents #FestivalPrep',
    pinnedComment: 'Tip: Decor items arrange karne ya phool ginne ka task dijiye — bachcha khush!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma is setting the Navratri thali, but Ria keeps grabbing things. "Mere saath khelo!"
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen, morning, Navratri thali prep in progress. Ria keeps grabbing things: "Mere saath khelo!" Mumma hands her a stack of napkins. Text on screen: "FESTIVAL PREP MEIN BACHCHE KO KAISE SAMBHALEIN? 🪔" "HELPER BANO! 🤝"

On-Screen Text:
- [0-3s]: "MUMMA BUSY, RIA WANTS PLAY 🎀"
- [3-7s]: "MERE SAATH KHELO! 🙋"
- [7-12s]: "TUM BHI HELPER HO! 🧻"
- [12-16s]: "NAPKINS GHOOMAO ✅"
- [16-20s]: "MAINNE MADAD KI! 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma sets the Navratri thali while Ria grabs at things: "Mumma sirf Mumma ko hi dhyan do!" Mumma hands her a stack of napkins: "Tum bhi Maa ki helper ho, napkins ghoomao." Text: "MUMMA BUSY, RIA WANTS PLAY 🎀" "TUM BHI HELPER HO! 🧻"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria carefully places each napkin beside a plate, proud of her job. Mumma smiles: "Perfect!" Text: "NAPKINS GHOOMAO ✅" "MAINNE MADAD KI! 💛"

Audio/Dialogue (Hinglish): Ria: "Mere saath khelo!" Mumma: "Tum bhi Maa ki helper ho, napkins ghoomao." Ria placing each one: "Mainne madad ki!" Mumma: "Perfect, beta."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria sits on the counter, "teaching" Cuty to stir the dal, happily included in the prep. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Invitations beat interruptions — when kids feel helpful, they don't compete for attention.
''',
  ),


  // ── New 30s Reel Stories ──
  HookIdea(
    id: 'idea_50',
    category: 'Funny',
    cover: 'Plate Patana!',
    title: 'Plate Patana!',
    opening: 'Ria plate mein khana rakhti thi — phir "Mumma, sab mix ho gaya!"',
    problem: 'Plate mein dal, rice, aur vegetable sab mix ho gaya.',
    lesson: 'Ek chhota sa separation — dal ka swimming pool.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Dal chawal mix ho gaya? Ek chhoti bowl lao, alag karo — mood fix! 🍚 #PlatePatana #ToddlerMeals #ParentingHack #FunLearningWithPalak #IndianParents',
    pinnedComment: 'Aapke bachche ko bhi pasand nahi mix khana?',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Dining table, lunch time. Ria looks down at her plate — dal swimming into the rice, vegetable pieces floating through both. "Mumma, sab mix ho gaya!" Text on screen: "PLATE PATANA! 🍚" "EK CHHOTA SA SEPARATION ✅"

On-Screen Text:
- [0-3s]: "SAB MIX HO GAYA! 😣"
- [3-7s]: "DAL KA SWIMMING POOL 🏊"
- [7-12s]: "EK MINUTE, MAARO ALAG 🥣"
- [12-16s]: "CHAWAL PHIR SE! 🍚"
- [16-20s]: "ENGINEERING SHURU! 🛠️"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria pushes dal away from chawal with her spoon — it mixes more, not less. "Mumma, sab mix ho gaya!" Rio watches from across the table. Text: "SAB MIX HO GAYA! 😣" "DAL KA SWIMMING POOL 🏊"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma brings a small extra bowl: "Ek minute, maaro ek alag." She spoons the dal into it, separate from the rice. Text: "EK MINUTE, MAARO ALAG 🥣" "CHAWAL PHIR SE! 🍚"

Audio/Dialogue (Hinglish): Ria: "Mumma, sab mix ho gaya!" Mumma: "Ek minute, maaro ek alag." Rio watching: "Woah." Ria looking at her now-separated plate: "Yay!"

Part 3 (20-30s): 3D Pixar style, 9:16. Dal in its own bowl, rice clean again. Mumma laughs: "Bachcha ne engineering shuru kar di!" Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Ek minute separation, poora mood badal jaata hai.
''',
  ),

  HookIdea(
    id: 'idea_51',
    category: 'Child Chaos',
    cover: 'He grabbed her car.',
    title: 'He grabbed her car.',
    opening: '"Yeh mera hai!" — and the whole park turns around to look at me.',
    problem: 'Sunday morning, society park. Rio pulls the red car out of Ria\'s hand mid-race. Ria screams. Four mothers turn around.',
    lesson: 'Turn-taking needs a handle the child can hold — a timer, a song, a hand.',
    postFormat: 'Reel',
    strategy: 'Public-meltdown shame hook',
    caption: 'The car has one broken wheel, so it always veers left. So do most of my parenting solutions. 🚗 #ToySharing #PublicMeltdown #ParentingReality #FunLearningWithPalak #IndianParents',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Society park, Sunday morning, 8:40am. Rio pulls the red toy car — missing one wheel, always veering left — out of Ria's hand mid-race. Ria screams. Text on screen: "YEH MERA HAI! 🚗" "GAANA KHATAM HONE TAK... 🎵"

On-Screen Text:
- [0-3s]: "MID-RACE GRAB! 🚗"
- [3-7s]: "RIA SCREAMS 😱"
- [7-12s]: "FOUR MOTHERS TURN AROUND 👀"
- [12-16s]: "GAANA KHATAM HONE TAK 🎵"
- [16-20s]: "STILL CRYING... 😢"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio pulls the wobbly red car out of Ria's hand mid-race. Ria screams. Four mothers nearby turn to look. Text: "MID-RACE GRAB! 🚗" "RIA SCREAMS 😱" "FOUR MOTHERS TURN AROUND 👀"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma steps in: "Gaana khatam hone tak. Phir tumhari baari." Ria keeps crying for several more minutes anyway. Mumma ends up holding one hand of each kid, standing between them. Text: "GAANA KHATAM HONE TAK 🎵" "STILL CRYING... 😢"

Audio/Dialogue (Hinglish): Ria: "Yeh mera hai!" Rio: "Mera bhi chahiye!" Mumma: "Gaana khatam hone tak. Phir tumhari baari." Ria still sniffling: "Theek nahi hai..."

Part 3 (20-30s): 3D Pixar style, 9:16. Both kids end up on the same swing, the car lying between them, nobody holding it anymore. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Turn-taking needs a handle the child can hold — a timer, a song, a hand. It doesn't always work on the first try, and that's okay.
''',
  ),

  HookIdea(
    id: 'idea_52',
    category: 'Child Chaos',
    cover: 'It took her 9 minutes.',
    title: 'It took her 9 minutes.',
    opening: 'Nine minutes of building. Two seconds to fall.',
    problem: 'Cuty the bunny stacks six blocks on the biscuit tin. Rio walks past and flattens it with one arm.',
    lesson: 'Rebuilding together is sometimes the whole repair — the apology comes later.',
    postFormat: 'Reel',
    strategy: 'Countdown-to-disaster hook',
    caption: 'The second crash was her own doing. I have stopped intervening in that one. 🧱 #BlockTower #SiblingDynamics #ToddlerPlay #FunLearningWithPalak #IndianParents',
    pinnedComment: 'How many minutes does your child build before someone in the family destroys it? Ours is 9.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cuty the bunny stacks six blocks on the biscuit tin. Rio walks past and flattens it with one arm.
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Hall floor, after lunch, TV off, Papa's socks on the sofa. Cuty carefully stacks the sixth block onto a tower balanced on the Britannia biscuit tin. Rio walks past and flattens it with one arm. Text on screen: "9 MINUTES OF BUILDING 🧱" "2 SECONDS TO FALL 💥"

On-Screen Text:
- [0-3s]: "NINE MINUTES... ⏱️"
- [3-7s]: "RIOOO! 💥"
- [7-12s]: "CUTY CRIES... THEN REBUILDS 🧱"
- [12-16s]: "KNOCKS IT DOWN HERSELF 😂"
- [16-20s]: "PAPA GETS BLAMED ANYWAY 🤷"

Part 1 (0-10s): 3D Pixar style, 9:16. Cuty stacks block after block on the wobbly biscuit-tin base. Rio walks past and flattens it with one arm: "Ek... do... teen... RIOOO!" Text: "NINE MINUTES... ⏱️" "RIOOO! 💥"

Part 2 (10-20s): 3D Pixar style, 9:16. Cuty cries briefly, then rebuilds the tower herself — and knocks it down herself, laughing. Everyone looks confused. Papa gets blamed anyway. Text: "CUTY CRIES... THEN REBUILDS 🧱" "KNOCKS IT DOWN HERSELF 😂"

Audio/Dialogue (Hinglish): Rio: "Oops!" Cuty sniffling, then rebuilding: "Phir se." Cuty knocking it down herself, giggling. Papa: "Maine kuch nahi kiya!" Rio: "Papa ne kiya!"

Part 3 (20-30s): 3D Pixar style, 9:16. Cuty sits inside the collapsed pile of blocks, looking very proud of herself. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Rebuilding together is sometimes the whole repair — the apology comes later.
''',
  ),

  HookIdea(
    id: 'idea_53',
    category: 'Child Chaos',
    cover: 'She got the tin... but got stuck!',
    title: 'She got the tin... but got stuck!',
    opening: 'Cuty wants the Parle-G tin on the top shelf. She drags the blue plastic stool over.',
    problem: 'Cuty wants the Parle-G tin kept on the top shelf. She drags the blue plastic stool over but can\'t reach and gets scared to climb down.',
    lesson: 'The skill was asking for help — and staying calm while waiting.',
    postFormat: 'Reel',
    strategy: 'Half-success hook (child wins, then loses)',
    caption: 'Cuty tin tak pahunch gayi par neeche nahi utar paayi! "Mumma! Main khud uthaya!" — stay calm, ask for help. 🍪 #SnackReach #ToddlerIndependence #AskForHelp #FunLearningWithPalak #IndianParents',
    pinnedComment: 'What is the one shelf in your house that your child has conquered?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Cuty wants the Parle-G tin kept on the top shelf. Nobody is in the kitchen. She drags the blue plastic stool over, climbs up, and grabs the tin — but it\'s one shelf higher than she can reach even on the stool.
Twist: She is stranded on the stool with the tin in one hand, too scared to climb down, and refuses to put it back.
Resolution: Mumma\'s hand appears, holding the tin; Cuty\'s legs still dangling off the stool. "Mumma! Main khud uthaya!" Mumma smiles: "Badiya kiya! Ab neeche utro."
Moral: The skill wasn't just reaching — it was asking for help and staying calm.
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen, 5pm, atta still out from lunch. Cuty drags the blue plastic stool to the counter, climbs up, and stretches for the Parle-G tin on the top shelf — one shelf higher than even the stool reaches. Text on screen: "SHE GOT THE TIN... 🍪" "BUT GOT STUCK! 😬"

On-Screen Text:
- [0-3s]: "TOP SHELF MISSION 🍪"
- [3-7s]: "GOT IT! ✋"
- [7-12s]: "BUT NOW... STUCK! 😬"
- [12-16s]: "MUMMA! MAIN KHUD UTHAYA! 🙋"
- [16-20s]: "BADIYA KIYA! NEECHE UTRO ❤️"

Part 1 (0-10s): 3D Pixar style, 9:16. Cuty drags the stool over, climbs up, and grabs the Parle-G tin with a stretch. Nobody is in the kitchen. Text: "TOP SHELF MISSION 🍪" "GOT IT! ✋"

Part 2 (10-20s): 3D Pixar style, 9:16. Cuty is now stranded on the stool, tin in one hand, too scared to climb down, refusing to put it back. "Mumma! I got it MYSELF." Text: "BUT NOW... STUCK! 😬" "MUMMA! MAIN KHUD UTHAYA! 🙋"

Audio/Dialogue (Hinglish): Cuty proudly: "Mumma! Main khud uthaya!" Mumma arriving, steadying the tin: "Badiya kiya! Ab neeche utro." Cuty, legs still dangling: "Main yahin hoon..."

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma's hand holds the tin steady while Cuty's legs still dangle off the stool, both laughing a little. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: The skill wasn't just reaching — it was asking for help and staying calm while waiting.
''',
  ),

  HookIdea(
    id: 'idea_54',
    category: 'Ria Chaos',
    cover: '11:40pm. Still stitching.',
    title: '11:40pm. Still stitching.',
    opening: 'The costume is a bedsheet. Her annual day is in eight hours.',
    problem: 'Ria announces at bedtime that she is a butterfly tomorrow and needs wings "in blue". The shops shut at 9.',
    lesson: 'Sometimes the win is just that she walks in wearing something on her back — preparation helps but perfection isn\'t required.',
    postFormat: 'Reel',
    strategy: 'Deadline-panic hook (no resolution shown)',
    caption: 'Every year I say I will prepare in advance. Every year it is a bedsheet, a safety pin, and me. 🪡 #AnnualDayPrep #ParentingReality #FunLearningWithPalak #IndianParents #LastMinuteParenting',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bedroom, 11:40pm, one bedside lamp on. Ria announced at bedtime that she's a butterfly tomorrow and needs wings "in blue" — the shops shut at 9. Mumma is cutting a bedsheet into wing shapes. Text on screen: "11:40PM. STILL STITCHING. 🪡" "EIGHT HOURS TO GO. ⏰"

On-Screen Text:
- [0-3s]: "BUTTERFLY TOMORROW?! 🦋"
- [3-7s]: "SHOPS SHUT AT 9 🚫"
- [7-12s]: "BEDSHEET IT IS 🪡"
- [12-16s]: "PIN SNAPS... 😬"
- [16-20s]: "6:00 AM ⏰"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria, half-asleep, watches Mumma cut wing shapes from a bedsheet. The safety pin snaps halfway through the second wing. Text: "BUTTERFLY TOMORROW?! 🦋" "SHOPS SHUT AT 9 🚫" "BEDSHEET IT IS 🪡"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria, drifting off: "Mumma, blue neela nahi hota na?" Mumma keeps stitching quietly in the lamp light. The second wing is still unfinished. Text: "PIN SNAPS... 😬"

Audio/Dialogue (Hinglish): Ria sleepily: "Mumma, blue neela nahi hota na?" Mumma, softly: "Haan beta, sona ja. Main dekh leti hoon."

Part 3 (20-30s): 3D Pixar style, 9:16. Midnight: one wing finished on the chair, one still a plain bedsheet. Ria is asleep. The phone alarm glows: 6:00am. No stage shot, no proud finish shown — the reel ends here. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Sometimes the win is just that she walks in wearing something on her back — preparation helps, but perfection isn't required.
''',
  ),

  HookIdea(
    id: 'idea_55',
    category: 'Ria Chaos',
    cover: 'She is "helping" — ASMR style!',
    title: 'She is "helping" — ASMR style!',
    opening: 'The atta was on the floor. She has now added water.',
    problem: 'Ria spills the atta, decides to clean it herself, and reaches for the water mug because that is what cleaning looks like to her.',
    lesson: 'Toddler help is often just mess with better intentions — and that\'s okay.',
    postFormat: 'Reel',
    strategy: 'ASMR-hook inversion (calm setup, chaos payoff)',
    caption: 'Sound on. The squelch at 0:06 is the reason I own a second mop. 🧹 #ToddlerCleaning #ASMR #MessyPlay #FunLearningWithPalak #IndianParents',
    pinnedComment: 'What has your child "cleaned" for you this week? Be honest about the floor.',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria spills the atta, decides to clean it herself, and reaches for the water mug because that is what cleaning looks like.
Twist: The dry atta turns into a sticky paste. Ria's hands are covered in flour, and Mumma starts laughing instead of scolding.
Resolution: Mumma kneels down: "Let me show you the right way — dry wipe first, then damp cloth." Together they clean it properly.
Moral: Toddler help is often just mess with better intentions — guide gently, don't shame.
''',
    setting: 'Kitchen floor, right after rolling rotis, steel plate still on the counter',
    sceneDetail: 'The atta was dry, sweepable, and is now a sticky paste that needs proper cleaning',
    dialogue: '"Dekho Mumma, saaf!"',
    mess: 'Ria tries to mop with a dry cloth, but the wet atta sticks to everything — her hands and the cloth',
    innerThought: 'My grandmother would have shouted. I am laughing because I have no other option left.',
    endingBeat: 'Mumma shows Ria the proper technique: dry brush first, then damp cloth.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''PROMPT: A warm, soft 3D Pixar-style kitchen (cream walls, wooden countertops, natural window light) at toddler scale. Vertical 9:16, 30 seconds total. Characters: Ria (3-year-old girl, pink star dress, pigtails with two pink bows, curious eyes), Mumma (yellow kurta, gentle smile). ASMR-style sound design: atta rustling, water pouring, soft cloth swishing.

On-Screen Text: [0-3s] "MUMMA, MAIN MADAD KAR SAKTI HOON!" [4-7s] "AAG LAGI THI!" [8-11s] "PAANI DAAL DIYA!" [12-15s] "DRY BRUSH PEHLE" [16-19s] "PHIR DAMP CLOTH" [20-23s] "SAATH MILKE SAAF" [24-27s] "MUMMA KA GUIDANCE ❤️" [28-30s] "LEARNING IS A HABIT"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria reaches for the rolling pin. Atta spills across the counter and floor. Ria's eyes light up — she wants to help. She grabs a dry dish brush and starts sweeping. Text: "MUMMA, MAIN MADAD KAR SAKTI HOON!" "AAG LAGI THI!"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria reaches for the water mug to make sweeping easier. *plop* — water hits the dry atta. It turns into a sticky paste. Flour splatters onto her hands and dress. The squelch at 0:16 is the payoff. Text: "PAANI DAAL DIYA!" "DRY BRUSH PEHLE" "PHIR DAMP CLOTH".

Audio/Dialogue (Hinglish): Ria: "Atta ghir gaya! Main saaf karoongi!" *splat* "Yay! Paani daal diya!" Mumma: *soft laugh* "Beta, thoda mushkil ho gaya!"

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma kneels, not scolding — laughing. She takes Ria's flour-covered hands: "Pehle dry brush, phir damp cloth." Together they clean: brush sweeps dry bits, then damp cloth glides over the sticky spots. The counter shines. Ria beams, matching her star dress. Text: "SAATH MILKE SAAF" "MUMMA KA GUIDANCE ❤️". Final text overlay: Toddler help is just mess with better intentions, guide gently don't shame, LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Toddler help is often just mess with better intentions — guide gently, don't shame.
''',
  ),

  HookIdea(
    id: 'idea_56',
    category: 'Child Chaos',
    cover: 'Ghar Mein 2 Minute Ki Shanti... DANGER!',
    title: 'Ghar Mein 2 Minute Ki Shanti... DANGER!',
    opening: 'Mummy heard two minutes of dead silence from the toddlers.',
    problem: 'When toddlers are suddenly quiet for two minutes, creative chaos is unfolding.',
    lesson: 'Check on quiet toddlers — creative chaos always follows.',
    postFormat: 'Reel',
    strategy: 'Suspense hook, then reveal',
    caption: 'Ghar mein 2 minute ki shanti... DANGER! 😱 Jab bachche bilkul silent ho jaate hain, toh bura haal hota hai. Watched the full video to see what Cuty was up to! #ToddlerChaos #IndianParents #FunLearningWithPalak #PreschoolMeltdown #ToddlerHumor',
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
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen, evening, flour bag tipped over. Mumma notices two full minutes of dead silence and tiptoes toward the kitchen. Flour footprints — tiny bare feet, Cuty's paw prints — lead across the floor. Text on screen: "2 MINUTE KI SHANTI... 😱" "DANGER?! 🚨"

On-Screen Text:
- [0-3s]: "DEAD SILENCE... 🤫"
- [3-7s]: "SUSPICIOUSLY QUIET 👀"
- [7-12s]: "FLOUR FOOTPRINTS?! 🦶"
- [12-16s]: "ROUND THE CORNER... 😳"
- [16-20s]: "CREATIVE CHAOS CONFIRMED! ❄️"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma pauses — two minutes of total silence. She tiptoes toward the kitchen, following a trail of flour footprints and paw prints. Text: "DEAD SILENCE... 🤫" "SUSPICIOUSLY QUIET 👀" "FLOUR FOOTPRINTS?! 🦶"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma rounds the corner — Ria and Rio, flour-covered, sitting in a cloud of spilled wheat, building a "snowman." Text: "ROUND THE CORNER... 😳"

Audio/Dialogue (Hinglish): Mumma whispering to herself: "Itni shanti kyun hai?" Ria, flour-covered, proud: "Dekho, snowman banaya!" Rio: "Bahut bada hai!"

Part 3 (20-30s): 3D Pixar style, 9:16. They stand up, the snowman wobbles, flour explodes everywhere. Mumma just sighs and laughs. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: The most suspicious silences always end with creative chaos to clean up — check on quiet toddlers.
''',
  ),

  HookIdea(
    id: 'idea_57',
    category: 'Child Chaos',
    cover: 'Ek Joota Gayab — 7:55 AM Panic!',
    title: 'Ek Joota Gayab — 7:55 AM Panic!',
    opening: 'School van honking downstairs, but one shoe has vanished.',
    problem: 'At 7:55 AM school rush, one shoe disappears into another dimension.',
    lesson: 'The things we lose are just having their own adventure — check the stroller first!',
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
Twist: Visual clues only: tiny footprint in flour (Rio), a trail of blocks (Cuty the bunny), and a doll stroller with one shoe tucked inside.
Resolution: With seconds to spare, they pull the shoe from the stroller. "Doll ne bhi date ki hai!" Rio grins.
Moral: Lost things usually have simple explanations — check the stroller.
''',
    setting: 'Bedroom floor, morning, backpack by the door',
    sceneDetail: 'One shoe is missing, the other is kicked under the bed, doll stroller nearby',
    dialogue: '"Joota kahan hai?" — "Main jaanta hoon, beta."',
    mess: 'Flour footprint, trail of blocks, and a trail toward the stroller — clues everywhere',
    innerThought: 'Clues first, panic second — the stroller always holds secrets.',
    endingBeat: 'They pull the shoe from the stroller — "Doll ne bhi date ki hai!" Rio grins.',
    defaultCast: ['Ria', 'Rio', 'Cuty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bedroom floor, 7:55am, backpack by the door, school van honking downstairs. One shoe is missing — the other kicked under the bed. "Joota kahan hai?" Text on screen: "EK JOOTA GAYAB! 👟" "7:55 AM PANIC! 🚐"

On-Screen Text:
- [0-3s]: "VAN HONKING DOWNSTAIRS! 🚐"
- [3-7s]: "EK JOOTA GAYAB! 👟"
- [7-12s]: "CLUES EVERYWHERE 🔍"
- [12-16s]: "DOLL STROLLER?! 🧸"
- [16-20s]: "FOUND IT! 🎉"

Part 1 (0-10s): 3D Pixar style, 9:16. The van honks outside. Ria searches frantically: "Joota kahan hai?" Visual clues only — a flour footprint from Rio, a trail of blocks from Cuty. Text: "VAN HONKING DOWNSTAIRS! 🚐" "EK JOOTA GAYAB! 👟" "CLUES EVERYWHERE 🔍"

Part 2 (10-20s): 3D Pixar style, 9:16. The trail of blocks leads to a doll stroller — with the shoe tucked inside. "Main jaanta hoon, beta." Text: "DOLL STROLLER?! 🧸"

Audio/Dialogue (Hinglish): Ria panicked: "Joota kahan hai?" Rio following the clues: "Main jaanta hoon, beta." Rio pulling the shoe from the stroller: "Doll ne bhi date ki hai!" Ria: "Chalo, van aa gayi!"

Part 3 (20-30s): 3D Pixar style, 9:16. They pull the shoe from the stroller with seconds to spare. Rio grins. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Lost things usually have simple explanations — check the stroller first.
''',
  ),

  HookIdea(
    id: 'idea_58',
    category: 'Ria Chaos',
    cover: 'Biscuit Toota — Duniya Khatam!',
    title: 'Biscuit Toota — Duniya Khatam!',
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
    defaultCast: ['Ria', 'Mumma', 'Cuty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen, afternoon snack, biscuit tin open. Mumma snaps a big round cookie in half to share. Ria gasps as if the world has shattered: "Yeh toh doosri poori tarah se toot gaya!" Text on screen: "BISCUIT TOOTA! 🍪" "DUNIYA KHATAM?! 😭"

On-Screen Text:
- [0-3s]: "SNAP! 🍪"
- [3-7s]: "DUNIYA KHATAM! 😭"
- [7-12s]: "DOCTOR RIO ARRIVES 👨‍⚕️"
- [12-16s]: "CUTY TAKES A NIBBLE 🐰"
- [16-20s]: "BELLY LAUGHS! 😂"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma snaps the cookie in half. Ria reacts with full dramatic despair: "Yeh toh doosri poori tarah se toot gaya!" and refuses the other half. Text: "SNAP! 🍪" "DUNIYA KHATAM! 😭"

Part 2 (10-20s): 3D Pixar style, 9:16. "Doctor Rio" dips his finger in warm milk, trying to glue the two halves back together — but Cuty sneaks a nibble right on the seam. Text: "DOCTOR RIO ARRIVES 👨‍⚕️" "CUTY TAKES A NIBBLE 🐰"

Audio/Dialogue (Hinglish): Ria wailing: "Yeh toh doosri poori tarah se toot gaya!" Rio, serious: "Doctor Rio aa gaya!" *nibble sound* Cuty: "Yum!" Both kids burst out laughing.

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma breaks another biscuit in half: "Ab dono match karte hain." Ria eats both pieces happily. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A shared laugh turns every broken thing into something sweet.
''',
  ),


  // ── Ria Talking to AI Robot Series ──
  HookIdea(
    id: 'idea_59',
    category: 'Series',
    cover: 'Phone Rakh Do!',
    title: 'Phone Rakh Do!',
    opening: 'Robot, phone rakh do — par haath mein hi hai!',
    problem: 'Ria asks Robot to put her phone away, but she is still holding it.',
    lesson: 'Robot scans literally and finds the phone in Ria\'s own hand — a gentle reminder to check your own hands first.',
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
Twist: Robot: "Object is resting. Hand is still attached." Robot scans behind couch, under pillows, in Cuty's bed.
Resolution: Robot points at Ria's own hand: "Object located." Ria laughs: "Meri hi toh thi!"
Moral: Sometimes the thing we want help finding is already in our hand.
''',
    setting: 'Living room, afternoon, Robot charging on dock',
    sceneDetail: 'One LED on Robot\'s chest blinking erratically',
    dialogue: '"Robot, phone rakh do!"',
    mess: 'Ria asks Robot to put the phone away, but she\'s still holding it — Robot scans everywhere',
    innerThought: 'Sometimes the thing we want found is already in our hand.',
    endingBeat: 'Robot points at Ria\'s own hand: "Object located." Ria laughs.',
    defaultCast: ['Ria', 'Robot', 'Cuty'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room afternoon. Ria (sparkly pink star dress, pigtails, no glasses) sits on the floor playing. Robot charging dock glows nearby. Ria: "Robot, phone rakh do!" but her hand still grips the phone. Text on screen: "PHONE RAKH DO? 📱" "LEKIN HAATH MEIN HAI 🤖"

On-Screen Text:
- [0-3s]: "PHONE RAKH DO? 📱"
- [3-7s]: "LEKIN HAATH MEIN HAI 🤖"
- [7-12s]: "SCAN EVERYWHERE!"
- [12-16s]: "EK PAL MILTAA HAI!"
- [16-20s]: "SELF-CHECK SUCCESS 💡"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria sitting cross-legged on the rug: "Robot, phone rakh do!" Her hand still holds it. Robot's LED blinks erratically. The phone is right where it was. Text: "PHONE RAKH DO? 📱" "LEKIN HAATH MEIN HAI 🤖" Robot: "Acknowledged. Scanning for misplaced object."

Part 2 (10-20s): 3D Pixar style, 9:16. Robot extends its arm, scanning under the couch, behind pillows, checking Cuty's bed. "Object not detected. Expanding search radius." Cuty hides a toy phone, looks innocent. Ria watches, confused. Text: "SCAN EVERYWHERE!" "EK PAL MILTAA HAI!" Robot: "Searching: behind couch, under pillows, inside Cuty's bed."

Audio/Dialogue (Hinglish): Ria: "Robot, phone rakh do!" Robot monotone: "Scanning for phone." Robot: "Not found behind couch." "Not found under pillows." "Not found in Cuty's bed." Ria: "Par yehi tho hai!"

Part 3 (20-30s): 3D Pixar style, 9:16. Robot's hand extends, points at Ria's own hand: "Object located." Ria looks, sees the phone in her grip, laughs: "Meri hi toh thi!" Text: "EK PAL MILTAA HAI!" "SELF-CHECK SUCCESS 💡". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Check your own hands first — sometimes the thing you want help finding is already in your possession.
''',
  ),

  HookIdea(
    id: 'idea_60',
    category: 'Series',
    cover: 'Sabzi Rejection Form',
    title: 'Sabzi Rejection Form',
    opening: 'Mujhe yeh sabzi bilkul nahi chahiye!',
    problem: 'Ria rejects food without trying, wants a formal rejection form from Robot.',
    lesson: 'Robot prints a Sabzi Rejection Form with checkboxes — a playful way to give the child agency while encouraging one tiny bite.',
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
Twist: Robot whirs: "Sabzi Rejection Form — Item Code: Green." Prints a form with checkboxes: too slimy / too green / too much. Ria checks "too green."
Resolution: Robot replies: "Noted. Try cheese next time." She tries one bite with cheese. "Thik hai!"
Moral: Even rejections can be filed — and sometimes re-tried with a tiny twist.
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Dining table, lunch time. Ria (sparkly pink star dress, pigtails) pushes away her plate: "Mujhe yeh sabzi bilkul nahi chahiye!" Robot (silver box-shaped body, blue LED eyes) whirs and extends a printer head. Text on screen: "REJECTION FORM 📝" "TOO GREEN ✅" "TRY CHEESE! 🧀"

On-Screen Text:
- [0-3s]: "SABZI REJECTION FORM 📝"
- [3-7s]: "TOO GREEN ✅"
- [7-12s]: "CHEESE TIME! 🧀"
- [12-16s]: "ONE BITE = MAGIC ✨"
- [16-20s]: "FILING SUCCESS 📁"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria pushes her plate away: "Mujhe yeh sabzi bilkul nahi chahiye!" Robot whirs, extends printer: "Sabzi Rejection Form — Item Code: Green." Prints checkboxes. Ria points: "Too green!" Robot nods. Text: "SABZI REJECTION FORM 📝" "TOO GREEN ✅". 

Part 2 (10-20s): 3D Pixar style, 9:16. Robot prints a new card: "Noted. Try cheese next time." Places a tiny cheese cube on her spoon. Ria eyes it. "Ek bite?" She tries: "Thik hai!" Text: "CHEESE TIME! 🧀" "ONE BITE = MAGIC ✨".

Audio/Dialogue (Hinglish): Ria: "Mujhe yeh sabzi bilkul nahi chahiye!" Robot monotone: "Initiating Sabzi Rejection Form." Ria: "Too green!" Robot: "Form printed. Suggestion: cheese." Ria trying: "Thik hai!" Robot: "Data recorded. Taste preference updated."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria happily eats more of the cheese-topped sabzi. Robot's LED blinks green with approval. Text: "ONE BITE = MAGIC ✨" "FILING SUCCESS 📁". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Even rejections can be filed — and sometimes re-tried with a tiny twist. Offer agency through choice while gently encouraging one small bite.
''',
  ),

  HookIdea(
    id: 'idea_61',
    category: 'Series',
    cover: 'Can You Fix My Broken Heart?',
    title: 'Can You Fix My Broken Heart?',
    opening: 'Robot, Rio ne mera heart tod diya!',
    problem: 'Ria\'s sibling damages her favorite toy and doesn\'t apologise, leaving Ria upset.',
    lesson: 'Robot suggests a heart-shaped bandage and helps Ria talk to Rio about sharing and saying sorry — humor helps healing.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, toy pieces scattered. Rio (blue t-shirt, shorts) accidentally knocks over Ria's tower. Ria's eyes well up: "Mera heart toot gaya!" Robot (blue LED eyes softening) extends a large heart-shaped bandage. Text on screen: "BROKEN HEART 🫀" "HEART BANDAGE ❤️🩹" "TEAM REPAIR 🔧"

On-Screen Text:
- [0-3s]: "BROKEN HEART 🫀"
- [3-7s]: "ROBOT RESPONSE 🤖"
- [7-11s]: "HEART BANDAGE ❤️🩹"
- [11-15s]: "APLOGY + TEAMWORK 🤝"
- [15-19s]: "REPAIR COMPLETE! 🔧"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio accidentally bumps Ria's tower — pieces scatter. Ria: "Mera heart toot gaya!" Crying, clutching her broken toy. Robot's LED shifts from neutral to concern: "Emotional distress detected." Text: "BROKEN HEART 🫀" "ROBOT RESPONSE 🤖".

Part 2 (10-20s): 3D Pixar style, 9:16. Robot extends a heart-shaped adhesive bandage, places it on Ria's chest: "Prescribing laughter therapy." Ria snorts, then giggles. Rio: "Sorry didi!" They both look at the bandage. Text: "HEART BANDAGE ❤️🩹" "APOLOGY + TEAMWORK 🤝".

Audio/Dialogue (Hinglish): Ria: "Mera heart toot gaya!" Robot: "Heart bandage protocol: initiating." Ria: "Ye kya hai?" Robot: "Humor injection. Side effect: laughter." Rio: "Mujhe maaf kar dena!" Ria: "Theek hai... phir se khelo?"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria and Rio rebuild the tower together, Robot handing blocks. Text: "REPAIR COMPLETE! 🔧". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A little humor and teamwork can mend both toys and feelings. When siblings repair together, the bond grows stronger.
''',
  ),

  HookIdea(
    id: 'idea_62',
    category: 'Series',
    cover: 'Mera Sab Kharab!',
    title: 'Mera Sab Kharab!',
    opening: 'Mera sab kharab! Robot, ek block hi do.',
    problem: 'Everything feels ruined — Robot offers one block to restart.',
    lesson: 'One block starts a new tower — small steps rebuild big things.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, scattered blocks. Ria (sparkly pink star dress, pigtails) throws her arms up: "Mera sab kharab!" Robot (stiff posture, blue LED eyes) extends a single block on its tray. Text on screen: "SAB KHARAB! 💥" "EK BLOCK SE SHURU 🎯" "RESET! 🔄"

On-Screen Text:
- [0-3s]: "SAB KHARAB! 💥"
- [3-7s]: "ROBOT DEADLANGS 😐"
- [7-11s]: "EK BLOCK SE SHURU 🎯"
- [11-15s]: "TOGETHER BUILD 🤝"
- [15-19s]: "RESET! 🔄"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria declares "Mera sab kharab!" throwing arms up. Robot sits stiffly, extends one block: "Problem identified. Solution: one block." Text: "SAB KHARAB! 💥" "ROBOT DEADLANGS 😐".

Part 2 (10-20s): 3D Pixar style, 9:16. Ria: "Ek hi block?" Robot: "Ek block se shuru hota hai." They place the block together. More blocks appear as they build. Text: "EK BLOCK SE SHURU 🎯" "TOGETHER BUILD 🤝".

Audio/Dialogue (Hinglish): Ria: "Mera sab kharab!" Robot monotone: "Solution: one block." Ria: "Ek hi block?" Robot: "Ek block se shuru hota hai." Ria: "Theek hai!" Both placing: "Ek saath!"

Part 3 (20-30s): 3D Pixar style, 9:16. A tiny tower stands, both kids beaming. Robot's LED blinks green. Text: "RESET! 🔄". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A single block can start a new tower — sometimes the smallest reset is all it takes.
''',
  ),

  HookIdea(
    id: 'idea_63',
    category: 'Series',
    cover: 'Ek Chhota Sa Saans',
    title: 'Ek Chhota Sa Saans',
    opening: 'Tower gir gaya... Rio ne saans li.',
    problem: 'Tower falls and Rio is ready to shout — Robot teaches one tiny breath.',
    lesson: 'One breath before the shout saves the tower — a simple regulation tool.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Floor scattered with blocks, purple breathe cards fanned out. Tower lies in pieces. Rio (blue t-shirt, shorts) inhales to shout: "NOOOO!" — but Ria (sparkly pink star dress, pigtails) holds up a purple card: "Ek chhota sa saans." Text on screen: "TOWER FELL 💥" "BREATH BEFORE SHOUT 🌬️" "REBUILD TOGETHER 🧱"

On-Screen Text:
- [0-3s]: "TOWER FELL 💥"
- [3-7s]: "NOOOO! 😤"
- [7-11s]: "EK CHHOTA SA SAANS 🌬️"
- [11-15s]: "BREATHE + REBUILD 🧱"
- [15-19s]: "TOWER STANDS! 🎉"

Part 1 (0-10s): 3D Pixar style, 9:16. Tower crashes, blocks fly. Rio inhales for a huge shout. Ria holds up purple card: "Ek chhota sa saans." Inhale for two counts, exhale for two. Text: "TOWER FELL 💥" "NOOOO! 😤" "EK CHHOTA SA SAANS 🌬️".

Part 2 (10-20s): 3D Pixar style, 9:16. Robot nods, projects counting: "Do... do..." Ria and Rio mirror the breath. The flying card lands softly in Rio's palm. Text: "BREATHE + REBUILD 🧱" "CARD CATCH ✨".

Audio/Dialogue (Hinglish): Rio loud: "NOOOOO!" Ria gentle: "Ek chhota sa saans." Robot: "Inhale... two. Exhale... two." Rio: "Phir se?" Ria: "Phir se." Both: "Ek... do..."

Part 3 (20-30s): 3D Pixar style, 9:16. Tower rebuilt, block by block, as they count breaths. Rio high-fives the camera. Text: "TOWER STANDS! 🎉". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: A breath before the shout can save the whole tower — and give the mind a calm moment between feeling and acting.
''',
  ),

  HookIdea(
    id: 'idea_64',
    category: 'Series',
    cover: 'Rio Copy Kar Raha Hai!',
    title: 'Rio Copy Kar Raha Hai!',
    opening: 'Robot, Rio har cheez copy karta hai!',
    problem: 'Rio copies everything Ria does, escalating to silly robot noises.',
    lesson: 'Robot turns copying into a joint silly pose game — mimicry becomes collaboration.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, afternoon. Rio (blue t-shirt, shorts) copying Ria (sparkly pink star dress, pigtails) — mirroring sip, walk, big-cat growl. Ria's face showing patience, then slight strain. Robot (blue LED eyes whirring) steps between them. Text on screen: "COPY COPY COPY! 🤖" "COPY COMPLETE! 🔄" "JOINT POSE! 🤝"

On-Screen Text:
- [0-3s]: "COPY COPY COPY! 🤖"
- [3-7s]: "PATIENCE FRAWS 💪"
- [7-11s]: "COPY COMPLETE! 🔄"
- [11-15s]: "JOINT POSE! 🤝"
- [15-19s]: "LAUGHTER WINS! 😂"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio mimics Ria: "Mmm sip sip!" copying her drink, her walk, her big-cat growl. Ria's smile starts to fade — patience fraying. Robot steps between: "Copy complete. Initiating joint silly pose protocol." Text: "COPY COPY COPY! 🤖" "PATIENCE FRAWS 💪".

Part 2 (10-20s): 3D Pixar style, 9:16. Robot strikes a pose: "Left hand broccoli, right hand ice cream!" Both kids mirror — broccoli, ice cream, wobbling. Robot: "Hold position!" Text: "COPY COMPLETE! 🔄" "JOINT POSE! 🤝".

Audio/Dialogue (Hinglish): Rio mimicking: "Mmm sip sip!" Ria: "(internal sigh)" Robot: "Copy complete. Initiating joint pose." Ria: "Broccoli?" Robot: "Ice cream!" Both: "Left hand broccoli, right hand ice cream!" Ria: "Haan!"

Part 3 (20-30s): 3D Pixar style, 9:16. Both kids hold the silly pose, laughing, Robot's LED blinking in rhythm. Text: "LAUGHTER WINS! 😂". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Copying can flip into collaboration when you turn it into a game — mimicry becomes shared creativity.
''',
  ),

  HookIdea(
    id: 'idea_65',
    category: 'Series',
    cover: 'My Drawing Is Wrong!',
    title: 'My Drawing Is Wrong!',
    opening: 'Robot, meri drawing kharab ho gayi!',
    problem: 'Ria compares her drawing to an example and feels she made a mistake.',
    lesson: 'The robot scans Ria\'s drawing and highlights her unique style — there\'s no "wrong" in art, only your style.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Drawing table, afternoon. Ria (sparkly pink star dress, pigtails) shows her lopsided drawing to Robot: "Robot, meri drawing kharab ho gayi!" Robot (blue LED eyes brightening) scans it and projects an animated version. Text on screen: "KHARAB? NAHIN! ✨" "YOUR STYLE = SUPERPOWER 🎨" "ART ALIVE! 🖼️"

On-Screen Text:
- [0-3s]: "KHARAB? NAHIN! ✨"
- [3-7s]: "SCAN IN PROGRESS 🖌️"
- [7-12s]: "YOUR STYLE! 🎨"
- [12-16s]: "ART ALIVE! 🖼️"
- [16-20s]: "DRAW 10 MORE! 📝"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria holds up her drawing: "Robot, meri drawing kharab ho gayi!" comparing it to an example. Robot scans: "Lopsided sun = radiant. Crooked tree = dancing. Wobbly house = full of life." Text: "KHARAB? NAHIN! ✨" "SCAN IN PROGRESS 🖌️".

Part 2 (10-20s): 3D Pixar style, 9:16. Robot projects Ria's drawing as animation — sun beams smile, tree sways, house winks. Ria's eyes widen: "Mere drawings alive hote hain!" Text: "YOUR STYLE! 🎨" "ART ALIVE! 🖼️".

Audio/Dialogue (Hinglish): Ria: "Robot, meri drawing kharab ho gayi!" Robot: "Negative. Style detected: radiant sun, dancing tree, wiggly house." Ria: "Really?" Robot: "Really." Ria: "Mere drawings alive hote hain!" Robot: "Initiating next canvas."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria grabs a fresh sheet: "Do I get ten more?" Robot extends a new crayon: "Ten. Go." Text: "DRAW 10 MORE! 📝". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: There's no "wrong" way to create art — your style is your superpower. Let confidence follow curiosity, not comparison.
''',
  ),

  HookIdea(
    id: 'idea_66',
    category: 'Series',
    cover: 'Mumma Sun Leti Hai!',
    title: 'Mumma Sun Leti Hai!',
    opening: 'Robot, kya Mumma ko bhi peeche dikta hai?',
    problem: 'Ria is caught doing something she shouldn\'t, but it isn\'t magic — Mumma heard the clues.',
    lesson: 'The robot shows how parents pick up sounds and signs, not superpowers — "sunna hi kaafi hota hai."',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen corner, afternoon. Ria (sparkly pink star dress, pigtails) sneaking toward the cookie jar. Robot (blue LED eyes scanning) projects a floating clue chart — footsteps, crinkles, timer beep. Mumma (yellow kurti, top bun) watches with a knowing smile. Text on screen: "COOKIE HEIST? 🍪" "CLUE CHART! 🕵️‍♀️" "LOVE > MAGIC ❤️"

On-Screen Text:
- [0-3s]: "COOKIE HEIST? 🍪"
- [3-7s]: "MUMMA EARS 👂"
- [7-11s]: "CLUE CHART! 🕵️‍♀️"
- [11-15s]: "Busted with love 😍"
- [16-20s]: "NO MAGIC, JUST LOVE"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria tiptoes toward the cookie jar, wrapper crinkling under her foot. Robot: "Unauthorized access detected." Text: "COOKIE HEIST? 🍪" "MUMMA EARS 👂".

Part 2 (10-20s): 3D Pixar style, 9:16. Robot projects clue chart: "Footsteps: detected. Crinkles: detected. Timer beep: no." Mumma: "Ruk jao, meri aankh bhi nahi todegi!" Ria stops, grinning. Text: "CLUE CHART! 🕵️‍♀️" "Busted with love 😍".

Audio/Dialogue (Hinglish): Ria sneaky: "Thodaa sa cookie..." Robot: "Footsteps detected." Ria: (quiet) "Crinkle..." Robot: "Crinkles detected." Mumma: "Ruk jao beta, maine tumhe sun liya." Ria: "Mumma ne suna!"

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma kneels, offers a tiny cookie on a proper plate: "Ek cookie, proper plate." Ria beaming: "Bas ek?" Text: "NO MAGIC, JUST LOVE". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Love needs no camera — a parent's awareness is enough. Pyaar se bina camera ki zaroorat nahi — sunna hi kaafi hota hai.
''',
  ),

  HookIdea(
    id: 'idea_67',
    category: 'Series',
    cover: 'Ek Haath Ka Space',
    title: 'Ek Haath Ka Space',
    opening: 'Robot, mujhe ek haath ka space chahiye!',
    problem: 'Rio crowds Ria while she builds, knocking puzzle pieces sideways.',
    lesson: 'Robot stretches a ruler to mark each child\'s space — boundaries can be visual and respectful.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room table, puzzle in progress. Rio leans in too close, knocking pieces sideways. Ria: "Mujhe thoda space chahiye!" Robot (blue LED eyes) extends a ruler across the table. Text on screen: "EK HAATH KA SPACE 📏" "RESPECTFUL BOUNDARIES! 🤝"

On-Screen Text:
- [0-3s]: "RIO TOO CLOSE! 😤"
- [3-7s]: "MUJHE SPACE CHAHIYE! 🙋"
- [7-12s]: "RULER STRETCHES OUT 📏"
- [12-16s]: "RED LINE, BLUE LINE 🔴🔵"
- [16-20s]: "PUZZLE TOGETHER! 🧩"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio looms over Ria's puzzle, knocking pieces sideways. Ria: "Mujhe thoda space chahiye!" Robot extends a ruler across the table: "Ek haath ka space." Text: "RIO TOO CLOSE! 😤" "RULER STRETCHES OUT 📏"

Part 2 (10-20s): 3D Pixar style, 9:16. Robot marks a red line for Ria, a blue line for Rio: "Line ke andar raho." Both stay in their zones. Text: "RED LINE, BLUE LINE 🔴🔵" "PUZZLE TOGETHER! 🧩"

Audio/Dialogue (Hinglish): Ria: "Mujhe thoda space chahiye!" Robot: "Ek haath ka space. Line ke andar raho." Rio: "Theek hai." Both work on their own side.

Part 3 (20-30s): 3D Pixar style, 9:16. Both finish the puzzle together, each staying inside their own line. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Space to create is peace to create — boundaries can be visual and respectful.
''',
    quote: '',
    detail: '',
    punchline: '',
  ),

  HookIdea(
    id: 'idea_68',
    category: 'Series',
    cover: 'There Are Butterflies in My Tummy!',
    title: 'There Are Butterflies in My Tummy!',
    opening: 'Robot, mere pet mein titliyan udd rahi hain!',
    problem: 'Ria gets pre-performance jitters before showing her artwork or speaking in front of others.',
    lesson: 'The robot explains that "butterflies" are excitement and courage, not fear — a simple reframe.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Classroom, afternoon. Ria (sparkly pink star dress, pigtails) clutching her drawing, stomach visibly fluttery. Robot (blue LED eyes gentle) scans her: "Excitement Detected: 97%." Projects: "Butterflies = Courage, Not Fear." Text on screen: "BUTTERFLIES 🦋" "COURAGE = EXCITEMENT 💪" "SHOW YOUR ART! 🎨"

On-Screen Text:
- [0-3s]: "BUTTERFLIES 🦋"
- [3-7s]: "97% EXCITEMENT ⚡"
- [7-11s]: "NOT FEAR!"
- [11-15s]: "BUTTERFLY BREATH 🌬️"
- [15-19s]: "SHOW YOUR ART! 🎨"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria's stomach fluttery with jitters: "Mere pet mein titliyan udd rahi hain!" She clutches drawing. Classmates wait. Robot: "Butterflies = courage, not fear." Text: "BUTTERFLIES 🦋" "97% EXCITEMENT ⚡".

Part 2 (10-20s): 3D Pixar style, 9:16. Robot teaches "butterfly breath": "Inhale... imagine wings. Exhale... they carry worry away." Ria breathes, shoulders relax. Text: "NOT FEAR!" "BUTTERFLY BREATH 🌬️".

Audio/Dialogue (Hinglish): Ria nervous: "Mere pet mein titliyan udd rahi hain!" Robot: "Excitement detected: 97%." Ria: "Par darr lag raha hai..." Robot: "Butterflies = courage. Try butterfly breath." Ria: "Ek... do..." Robot: "Show them your garden!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria confidently: "This is my butterfly garden!" Classmates clap. Robot's LED glows proud blue. Text: "SHOW YOUR ART! 🎨". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Butterflies mean you care — and caring is the first step to courage. A simple breath can turn nervous energy into brave action.
''',
  ),

  HookIdea(
    id: 'idea_69',
    category: 'Series',
    cover: 'I\'m Dying of Boredom!',
    title: 'I\'m Dying of Boredom!',
    opening: 'Main bore ho rahi hoon!',
    problem: 'Ria has finished all her activities and declares nothing is left to do.',
    lesson: 'The robot suggests the "boredom jar" — a list of simple activities she can pick from. Boredom is the spark for creativity.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, afternoon, a jar full of tiny scrolls on the table. Ria flops down: "Ab kuchh nahi bacha!" Robot extends the jar toward her: "Boredom Jar se ek scroll." Text on screen: "I'M DYING OF BOREDOM! 😩" "BOREDOM JAR! 🫙"

On-Screen Text:
- [0-3s]: "AB KUCHH NAHI BACHA! 😩"
- [3-7s]: "DRAWING, PUZZLE, SNACK, DANCE — DONE 📋"
- [7-12s]: "BOREDOM JAR! 🫙"
- [12-16s]: "SCROLL REVEALED 📜"
- [16-20s]: "BLANKET FORT! 🏰"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria lists everything she's already done: "Drawing, puzzle, snack, dance — sab kar liya!" Robot extends the Boredom Jar: "Boredom Jar se ek scroll." Text: "AB KUCHH NAHI BACHA! 😩" "BOREDOM JAR! 🫙"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria reaches in and unrolls a scroll: "Build a blanket fort!" Her eyes light up. Text: "SCROLL REVEALED 📜" "BLANKET FORT! 🏰"

Audio/Dialogue (Hinglish): Ria: "Ab kuchh nahi bacha!" Robot: "Boredom Jar se ek scroll." Ria unrolling it: "Blanket fort?!" Robot: "Adventure awaits."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria spends the afternoon building an epic blanket fort, completely absorbed. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Boredom is just the moment before creativity kicks in.
''',
  ),

  HookIdea(
    id: 'idea_70',
    category: 'Series',
    cover: 'Rio Ne Surprise Diya!',
    title: 'Rio Ne Surprise Diya!',
    opening: 'Robot, Rio ne ek surprise plan kiya hai!',
    problem: 'Rio tells everyone about a surprise Ria planned for Mumma, but Ria wanted it to stay secret until the big reveal.',
    lesson: 'The robot explains that surprises are meant to share, but secrets that make you uncomfortable must always be told to a trusted grown-up — a safety lesson.',
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
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, afternoon. Half-wrapped gift box, ribbons scattered. Rio (blue t-shirt, shorts) blurts out: "Ria ne Mumma ko surprise gift banaya hai!" Ria (sparkly pink star dress, pigtails) face falls. Robot (blue LED eyes flickering) projects a two-column chart. Text on screen: "SURPRISE? ✨" "SECRET = TELL GROWN-UP! 🚨" "RIGHT TIME = RIGHT! ⏰"

On-Screen Text:
- [0-3s]: "SURPRISE! ✨"
- [3-7s]: "SPOILED! 😱"
- [7-11s]: "ROBOT INTERVENTION 🤖"
- [11-15s]: "CHART EXPLAINED 📊"
- [15-19s]: "RIRO UNDERSTANDS! 💡"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio blurts out the surprise. Ria's face falls — "Mera plan kharab!" Mumma overhears. Robot's eyes whirl: "Privacy protocol activated." Text: "SURPRISE! ✨" "SPOILED! 😱".

Part 2 (10-20s): 3D Pixar style, 9:16. Robot projects chart: left side "Surprise = fun to share later!" right side "Secret = if sad or scary, tell grown-up." Ria reads both sides. Text: "ROBOT INTERVENTION 🤖" "CHART EXPLAINED 📊".

Audio/Dialogue (Hinglish): Rio blurting: "Ria ne Mumma ko surprise gift banaya hai!" Ria: "Rio! Kya kar diya tune!" Robot: "Drawing distinction." Charts: "Surprise = share later. Secret = tell grown-up." Rio: "Samajh gaya!" Ria: "Theek hai."

Part 3 (20-30s): 3D Pixar style, 9:16. Rio: "Mujhe pata hai, main dhyaan rakhunga!" Ria hands him tape: "Pack up." Gift box wrapped. Text: "RIRO UNDERSTANDS! 💡". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Surprises are sweet to share at the right time; secrets that make you uncomfortable must always be told to a trusted grown-up immediately.
''',
  ),

  HookIdea(
    id: 'idea_71',
    category: 'Series',
    cover: 'I Want to Eat the Whole World!',
    title: 'I Want to Eat the Whole World!',
    opening: 'Robot, mujhe poori duniya khana hai!',
    problem: 'Ria is curious about every food she sees and wants to try everything at once.',
    lesson: 'The robot creates a "world foods adventure map" so Ria could explore tastes one country at a time — one bite at a time.',
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Dining table, afternoon. Rainbow of international dishes arranged. Ria (sparkly pink star dress, pigtails) pointing at everything: "Mujhe poori duniya khana hai!" Robot (blue LED eyes whirring) produces a world map where each country lights up. Text on screen: "WORLD MENU 🌍" "ONE BITE AT A TIME! 🍽️" "ADVENTURE MAP! 🗺️"

On-Screen Text:
- [0-3s]: "WORLD MENU 🌍"
- [3-7s]: "EVERYTHING! 🍜🍕🌮"
- [7-12s]: "ONE COUNTRY PER DAY 📅"
- [12-16s]: "TINY BITES ONLY 🍴"
- [16-20s]: "FLAVOR ADVENTURE! ✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria overwhelmed by dishes: "Mujhe poori duniya khana hai!" Robot scans each dish: "Too much data for one meal cycle." Projects world map — countries blinking. Text: "WORLD MENU 🌍" "EVERYTHING! 🍜🍕🌮" "ONE COUNTRY PER DAY 📅".

Part 2 (10-20s): 3D Pixar style, 9:16. Robot: "Protocol: one bite at a time." Places a single samosa: "Today: India." Ria takes a careful bite: "Mmm!" Text: "TINY BITES ONLY 🍴" "FLAVOR ADVENTURE! ✨".

Audio/Dialogue (Hinglish): Ria: "Mujhe poori duniya khana hai!" Robot: "All dishes detected. Recommendation: one country per day." Ria: "Ek bite?" Robot: "Start with familiar. India first." Ria: "Mmm! Swadisht!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria marks "India" on her adventure map with a gold star. Robot hands her a new dish: "Tomorrow: Mexico." Text: "FLAVOR ADVENTURE! ✨". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: The world is huge — best to explore it one bite at a time. Tiny tastes build big curiosity.
''',
  ),

  // Real mess parenting stories.
HookIdea(
    id: 'idea_72',
    category: 'Funny',
    cover: 'Plan: Perfect!',
    title: 'Plan: Perfect!',
    opening: 'Ria presents a crumpled blueprint: "Maine plan banaya hai!"',
    problem: 'Child confidently solves a family problem in the wrong way',
    lesson: 'The child\'s solution is creative but completely misses the brief — listen to what they actually need',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Ria ka plan: "Step 1: Papa ko gulaab do." Mast plan, par Papa allergic hain! 😂 #ToddlerPlans #ParentingHumor #FunLearningWithPalak #IndianParents #ToddlerLogic',
    pinnedComment: 'Aapke bachche ne kab "perfect plan" banaya jo galat nikla? 😂',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria: "Dekho plan!" She unfolds a paper: "Step 1: Papa ko gulaab do." "Step 2: Mummy ko paani do." "Step 3: Rio ko TV chalu karo." "Step 4: Sab milke — PROBLEM SOLVED!" Mumma: "Ria beta, yeh kya plan hai?" Ria: "Galti kya hogi agar sabko pyaar milta hai?"
Twist: Papa: "Beta, main gulaab se allergic hoon." Rio: "Main TV nahi dekhna chahta, book maanga hai." Mumma: "Main paani nahi peeti, darrakchunni hai."
Resolution: Ria crumples the plan: "Toh... naya plan?" She draws a new one: "Step 1: Papa tofa mile." "Step 2: Mummy book mile." "Step 3: Rio dinosaur mile." "Step 4: Sab khush hain." Everyone laughs.
Moral: Bachche apni tareeke se solution dhoondhte hain — unki creativity ko encourage karo, par unki zaroorat pucho.
''',
    setting: 'Living room floor, scattered toys, crumpled paper plan',
    sceneDetail: 'Ria\'s blueprint with "STEP 4: PROBLEM SOLVED!" in wobbly letters',
    dialogue: 'Maine plan banaya hai!',
    mess: 'Ria keeps adding steps — "Step 5: Cake cut" "Step 6: Everyone nap" — each more elaborate',
    innerThought: 'Agar maine yeh plan suna toh sab theek ho jayega, why do adults always need to change it',
    endingBeat: 'Ria\'s new plan with everyone getting what they actually asked for — crumpled again',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, scattered toys, crumpled paper plan in Ria's hands. Ria (sparkly pink star dress, pigtails) proudly unfolds blueprint: "Step 1: Papa ko gulaab do!" "Step 2: Mummy ko paani do." "Step 3: Rio ko TV chalu karo." Papa: "Beta, main gulaab se allergic hoon!" Text on screen: "PERFECT PLAN! 📋" "ALLERGY ALERT! 🌹" "REVISE & RESUBMIT! ✨"

On-Screen Text:
- [0-3s]: "PLAN PRESENTATION! 📋"
- [3-7s]: "PERFECT PLAN! ✨"
- [7-11s]: "ALLERGY ALERT! 🌹"
- [11-15s]: "MISSED THE BRIEF 😅"
- [16-20s]: "REVISED PLAN! ✅"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria presents plan: "Dekho plan!" Steps: roses for Papa, water for Mummy, TV for Rio — "PROBLEM SOLVED!" Text: "PLAN PRESENTATION! 📋" "PERFECT PLAN! ✨".

Part 2 (10-20s): 3D Pixar style, 9:16. Papa: "Gulaab se allergic hoon!" Rio: "Main TV nahi dekhna chahta." Mumma: "Main paani nahi peeti, darrakchunni hai." Ria crumples plan. Text: "ALLERGY ALERT! 🌹" "MISSED THE BRIEF 😅".

Audio/Dialogue (Hinglish): Ria: "Maine plan banaya hai!" Papa: "Beta, gulaab se allergic hoon." Rio: "Main TV nahi dekhna chahta, book maanga hai." Mumma: "Main paani nahi peeti." Ria: "Toh... naya plan?" New plan: "Step 1: Papa tofa mile." "Step 2: Mummy book mile." "Step 3: Rio dinosaur mile." All: "Sab khush hain!"

Part 3 (20-30s): 3D Pixar style, 9:16. Everyone gets what they actually wanted. Ria: "Mere plan ka final version — sab khush!" Text: "REVISED PLAN! ✅". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Bachche apni tareeke se solution dhoondhte hain, unki creativity ko encourage karo, par unki zaroorat pucho.
''',
  ),

  HookIdea(
    id: 'idea_73',
    category: 'Child Chaos',
    cover: 'Park Se Nikalna!',
    title: 'Park Se Nikalna!',
    opening: 'Ria ne kaha — "Main yahan nahi jaungi park se!" jab Papa ne time khatam kaha.',
    problem: 'Child refuses to leave the park when playtime ends',
    lesson: 'Turn the transition into a game — first step wins the countdown!',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Park se nikalna hai? Game banao — "Jiska pehla step niklega, wohi countdown karega!" 🏃‍♂️ #ParkTransition #ToddlerTantrum #ParentingHack #FunLearningWithPalak #IndianParents',
    pinnedComment: 'Timer ya countdown game try kariye — transition smooth hota hai!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Park time is over. Papa checks his watch — "Time to go." Ria plants her feet — "Main yahan nahi jaungi park se!"
Twist: Rio joins the protest — "Mujhe bhi nahi jaana!" — both sit on the ground.
Resolution: Papa turns it into a game — "Jiska pehla step niklega, wohi jeeti ka countdown karega." First step taken, countdown begins.
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Society park exit, morning. Ria (sparkly pink star dress, pigtails) and Rio (blue t-shirt, shorts) both sitting on the bench, arms crossed. Papa checking watch: "Time to go." Text on screen: "PARK EXIT DRAMA! 🏃" "GAME OVER DEMANDS! 🏁" "FIRST STEP WINS! 🏆"

On-Screen Text:
- [0-3s]: "PLAYTIME OVER! ⏰"
- [3-7s]: "PARK EXIT DRAMA! 🏃"
- [7-11s]: "GAME ON! 🎮"
- [11-15s]: "FIRST STEP WINS! 🏆"
- [16-20s]: "MISSION COMPLETE! ✅"

Part 1 (0-10s): 3D Pixar style, 9:16. Papa: "Time to go." Ria plants feet: "Main yahan nahi jaungi park se!" Rio joins: "Mujhe bhi nahi jaana!" Both sit. Text: "PLAYTIME OVER! ⏰" "PARK EXIT DRAMA! 🏃".

Part 2 (10-20s): 3D Pixar style, 9:16. Papa: "Game banao — jiska pehla step niklega, wohi countdown karega!" Ria takes first step. Text: "GAME ON! 🎮" "FIRST STEP WINS! 🏆".

Audio/Dialogue (Hinglish): Papa: "Time to go — park se nikalna padega." Ria: "Main yahan nahi jaungi park se!" Rio: "Mujhe bhi nahi jaana!" Papa: "Game banao — pehla step, countdown karega." Ria: "Main jee lungi!" Rio: "Mere saath bhi!" Both: "Phir kal phir milenge!"

Part 3 (20-30s): 3D Pixar style, 9:16. Both walk out, hand in hand with Papa. "Mission complete!" Text: "MISSION COMPLETE! ✅". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Game toh game hota hai, lekin har game ek nayi baat sunane dega — turning transitions into games beats demanding compliance every time.
''',
  ),

HookIdea(
    id: 'idea_74',
    category: 'Funny',
    cover: 'Wohi Toh Tha!',
    title: 'Wohi Toh Tha!',
    opening: 'Ria freezes mid-bite. "Arre... yehi toh tha jo tumne kaha tha!"',
    problem: 'Rio copies Mumma exact words at the worst possible moment',
    lesson: 'Toddlers are walking tape recorders — speak carefully',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Rio ne Mumma ke alfaaz dohra diye — "Mummy ne kaha..." 😂 Bachche tape recorder hain! #ToddlerQuotes #ParentingMirror #FunLearningWithPalak #IndianParents #ToddlerLife',
    pinnedComment: 'Aapke bachche ne kab aapki baat dohra di? 😂',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma to Papa in the hallway: "Aaj tak nahi dekhna, tumhe samajh aa jayega." Rio, eating breakfast, looks up. "Mummy ne kaha — aaj tak nahi dekhna." Papa: "Kya?" Mumma's face goes white.
Twist: Mumma: "Maine kaha tha tumhe? Kisko bhi nahi kaha." Papa: "Tumne kaha tha — " Rio, matter-of-fact: "Mummy ne kaha tha tumhe — tumhare saath nahi dekhna."
Resolution: Mumma pinches her own arm: "Rio, tumhara breakfast khatam karo." Rio: "Wohi toh tha jo tumne kaha!" Mumma: "Haan bhi kaha."
Moral: Bachche har baat yaad rakhte hain — bolo soch ke.
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
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kitchen, breakfast table, morning light. Half-eaten dosa on Rio's plate. Mumma's dupatta caught on the door handle. Mumma: "Aaj tak nahi dekhna, tumhe samajh aa jayega." Rio freezes mid-bite: "Arre... yehi toh tha jo tumne kaha tha!" Text on screen: "TAPE RECORDER! 🎙️" "BACKTRACK FAIL! ❌" "LISTEN FIRST 👂"

On-Screen Text:
- [0-3s]: "OVERHEARD! 👂"
- [3-7s]: "TAPE RECORDER! 🎙️"
- [7-11s]: "BACKTRACK FAIL! ❌"
- [11-15s]: "ADMIT MISTAKE 🤦"
- [16-20s]: "LAUGHTER WINS! ❤️"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma to Papa in hallway: "Aaj tak nahi dekhna, tumhe samajh aa jayega." Rio eating breakfast: "Mummy ne kaha — aaj tak nahi dekhna." Papa: "Kya?" Mumma's face goes white. Text: "OVERHEARD! 👂" "TAPE RECORDER! 🎙️".

Part 2 (10-20s): 3D Pixar style, 9:16. Ria: "Wohi toh tha jo tumne kaha!" Mumma pinches her arm: "Rio, tumhara breakfast khatam karo." Text: "BACKTRACK FAIL! ❌" "ADMIT MISTAKE 🤦".

Audio/Dialogue (Hinglish): Mumma: "Aaj tak nahi dekhna, tumhe samajh aa jayega." Rio: "Mummy ne kaha — aaj tak nahi dekhna!" Papa: "Kya? Kisko bhi kaha?" Mumma: "Arre bachche, galt baat nahi kahi." Rio: "Wohi toh tha jo tumne kaha!" Mumma: "Maine toh kaha tha koi mat karo..." Rio: "Bas yehi toh tha."

Part 3 (20-30s): 3D Pixar style, 9:16. Mumma laughs: "Beta, tumne samajh gaya!" Rio grins, takes another bite. "Phir bhi yehi toh tha." Text: "LAUGHTER WINS! ❤️". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Bachche har baat yaad rakhte hain — bolde soch ke, because walking tape recorders are always on.
''',
  ),

  HookIdea(
    id: 'idea_75',
    category: 'Funny',
    cover: 'Secret Agent Cuty!',
    title: 'Secret Agent Cuty!',
    opening: 'Cuty trots between Mumma\'s legs, nose twitching — something is wrong.',
    problem: 'Child misunderstands a private adult conversation about money',
    lesson: 'Overheard snippets become a child\'s own private soap opera — explain simply',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Bachche bade ki baatein sun ke apni duniya bana lete hain! "Budget? Main bhi budget ke andar hoon!" 💰 #ToddlerLogic #MisunderstoodConversations #FunLearningWithPalak #IndianParents #MoneyTalk',
    pinnedComment: 'Aapke bachche ne kab aapki baat ka apna matlab nikala?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma on the phone: "Nahi, yeh month toh budget mein nahi aayega." Ria: "Budget? Kya budget?" Mumma: "Apna ghar ka budget." Ria: "Ghar ka budget? Par main toh ghar ka part hoon!" Cuty sniffs Mumma's purse and trots away.
Twist: Ria: "Toh kya main budget se bahar hoon?" Mumma: "Nahi beta..." Rio: "Main bhi budget se bahar hoon?" Mumma, defeated: "Sab koi budget ke andar hi hoon."
Resolution: Cuty emerges with a single coin from the purse. Drops it at Ria's feet. Everyone stares at the coin.
Moral: Bachche bade ki baatein apne tareeke se samajhte hain — unhe simple shabdon mein samjhao.
''',
    setting: 'Hallway outside the bedroom, morning',
    sceneDetail: 'Mumma\'s purse on the floor, single coin glinting',
    dialogue: 'Par main toh ghar ka part hoon!',
    mess: 'Ria keeps asking "kitna budget hai?" and "kiska share hai"',
    innerThought: 'Agar main bahar hoon toh kya main free hoon... kya mujhe pyar ki jayegi?',
    endingBeat: 'Cuty drops the coin, everyone stares at it like it just solved everything',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: true,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Hallway outside bedroom, morning. Mumma's purse on the floor, single coin glinting. Mumma on phone: "Nahi, yeh month budget mein nahi aayega." Ria: "Par main toh ghar ka part hoon!" Cuty sniffs the purse. Text on screen: "BUDGET CONFUSION! 💰" "COIN LOGIC! 🪙" "SIMPLE WORDS MATTER! 💬"

On-Screen Text:
- [0-3s]: "BUDGET CONFUSION! 💰"
- [3-7s]: "AM I IN OR OUT? 🤔"
- [7-11s]: "TODDLER ECONOMICS 📊"
- [11-15s]: "COIN LOGIC! 🪙"
- [16-20s]: "SIMPLE WORDS MATTER! 💬"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma: "Nahi, budget mein nahi aayega." Ria: "Budget? Kya budget?" Mumma: "Ghar ka budget." Ria: "Par main toh ghar ka part hoon!" Rio: "Main bhi budget se bahar hoon?" Text: "BUDGET CONFUSION! 💰" "AM I IN OR OUT? 🤔".

Part 2 (10-20s): 3D Pixar style, 9:16. Cuty sniffs Mumma's purse, trots away. Emerges with single coin, drops it at Ria's feet. Text: "COIN LOGIC! 🪙".

Audio/Dialogue (Hinglish): Mumma: "Nahi, yeh month budget mein nahi aayega." Ria: "Par main toh ghar ka part hoon!" Rio: "Main bhi budget se bahar hoon?" Mumma: "Sab koi budget ke andar hi hoon." Cuty: "Yip!" [drops coin] Ria: "Cuty ne solve kar diya!"

Part 3 (20-30s): 3D Pixar style, 9:16. Everyone stares at the coin. "Evidence hai — hair on the floor!" Text: "SIMPLE WORDS MATTER! 💬". Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Bachche bade ki baatein apne tareeke se samajhte hain, unhe simple shabdon mein samjhaana padta hai.
''',
  ),

  // New ideas (added by hand; blanks to be filled later)
  HookIdea(
    id: 'idea_76',
    category: 'Diwali',
    cover: 'Safety First, Sparkle Always!',
    title: 'Safety First, Sparkle Always!',
    opening: 'Phataka jalaane se pehle, safety checklist dikhana zaroori hai.',
    problem: 'Diwali fireworks safety — children must not light fireworks independently',
    lesson: 'Adult supervision is mandatory. Teach one safety rule before each firework: safe distance, water bucket ready, cotton clothes only.',
    postFormat: 'Reel',
    strategy: 'Teach one safety rule before lighting any firework.',
    caption: 'Safety first, Diwali second ✨🪔 Bacche kabhi khud phataka na jalayein — adult supervision zaroori! #DiwaliSafety #FireworkSafety #FunLearningWithPalak #IndianParents #SafeDiwali',
    pinnedComment: 'What safety rule do you teach your kids before Diwali?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria ke saamne Diwali phataka jalaane se pehle, Mumma safety rules samjhati hai — kya doori rakhna hai, paani ki balti taiyaar, soot ke kapde pehenne hain. Ria ek safe zone banane ki koshish karti hai lekin Mumma kehta hai ki kuch bhi safe zone nahi banata — sirf adult hi handle karta hai.
Twist: Ria phataka ke saath ghoomne ki koshish karti hai, par Mumma use rukna padta hai. "Beta, phataka sirf adult ke haath mein!" kehkar Mumma sparkler apni ungli pakad ke jalaati hai — Ria paas se dekhti hai.
Resolution: Har safety rule follow karne ke baad, Ria ek Safety Star badge paati hai. Do ladke — ek jo safe raha, ek jo unsafe ki koshish ki — dono Mumma ke saath phataka dekhte hain.
Moral: Safety rules follow karne se hi Diwali ka maza safe rehta hai. Bacche kabhi khud phataka na jalayein.
''',
    setting: 'Courtyard at dusk, fireworks laid out on the ground, water bucket nearby',
    sceneDetail: 'Mumma stands behind the safe distance line, holding sparkler in her own hand. Ria watches from the marked spot beside her.',
    dialogue: '"Pehle safety samjho, phir phataka jalao!"',
    mess: 'Ria tries to reach the sparkler but remembers the rule and stops. Mumma holds it safely, showing Ria how to watch without touching.',
    innerThought: 'How do I make safety fun and not boring?',
    endingBeat: 'Ria wears her "Safety Star" badge while Mumma lights sparklers at a safe distance.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Safe kids light up Diwali brighter — with adult help.',
    detail: 'Teach one rule before every firework. Adult lights, child watches from safe distance.',
    punchline: 'Safety first, sparkle always — with adult help!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Courtyard at dusk. Mumma behind safe distance line, holding sparkler in her own hand. Ria watches from the marked spot beside her. "Pehle safety samjho, phir phataka jalao!" Text on screen: "SAFETY FIRST! 🪔" "ADULTS HANDLE IT!"

On-Screen Text:
- [0-3s]: "DIWALI KE PHATE! 🪔"
- [3-7s]: "BUZZ WORD: ADULT SUPERVISION 🔥"
- [7-12s]: "SAFE DISTANCE = SAFETY ✨"
- [12-16s]: "WATCH & WONDER 🌟"
- [16-20s]: "SAFETY STAR BADGE! ⭐"

Part 1 (0-10s): 3D Pixar style, 9:16. Courtyard at dusk. Mumma stands behind the safe distance line, holding sparkler in her own hand. Ria watches from the marked spot beside her. "Pehle safety samjho, phir phataka jalao!" Text: "DIWALI KE PHATE! 🪔" "BUZZ WORD: ADULT SUPERVISION 🔥". Ria tries to reach the sparkler but remembers the rule and stops.

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma holds the sparkler safely, showing Ria how to watch without touching. "Beta, phataka sirf adult ke haath mein!" Ria's eyes wide with wonder. Water bucket ready nearby. Text: "SAFE DISTANCE = SAFETY ✨" "WATCH & WONDER 🌟".

Audio/Dialogue (Hinglish): Mumma: "Pehle safety samjho, phir phataka jalao!" Ria curious: "Mumma, main khud jalayegi?" Mumma: "Beta, phataka sirf adult ke haath mein! Tum dekho, main kaise jalaati hoon." Ria: "Wow! Kitni chamak rahi hai!" Mumma: "Safe distance raho, beta. Dekho, par chuhne mat."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria wears her "Safety Star" badge while Mumma lights sparklers at a safe distance. Ria claps with joy, eyes sparkling. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Safety rules follow karne se hi Diwali ka maza safe rehta hai. Bacche kabhi khud phataka na jalayein. Adults always handle fireworks.

''',
  ),
  HookIdea(
    id: 'idea_77',
    category: 'Diwali',
    cover: 'Saf Safai = Happy Diwali!',
    title: 'Saf Safai = Happy Diwali!',
    opening: 'Diwali se pehle saf safai ki dhun bajna shuru ho jaati hai.',
    problem: 'Diwali cleaning chaos at home — making it a family game',
    lesson: '5-minute cleanup race with timer before decorating. Teamwork makes cleaning fun.',
    postFormat: 'Reel',
    strategy: '5-minute cleanup race with timer before decorating.',
    caption: 'Clean house, happy house 🪔🧹 5-minute timer laga ke saath saaf karo! #DiwaliCleaning #FamilyTeamwork #FunLearningWithPalak #IndianParents #DiwaliPrep',
    pinnedComment: 'Tag your cleanup partner!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria aur Mumma Diwali se pehle poore ghar ki saf safai shuru karti hai. Cheezein har jagah phaili ho jaati hain, par dono ek saath kaam karte ho toh maza aa jaata hai.
Twist: Mumma ek 5-minute timer laga deti hai: "Race against time, Mumma! 5 min yaar!" Rio apne toys bhi jaldi se jaldi apni jagah rakhta hai.
Resolution: Sab milkar 5 minute mein poora ghar saf kar liya, aur phir diya jalane lagi.
Moral: Ek saath kaam karo, toh safai bhi game ban jaati hai.
''',
    setting: 'Living room, Diwali decorations half-unpacked',
    sceneDetail: 'A toy racing track scattered with diyas and ribbons',
    dialogue: '"Race against time, Mumma! 5 min yaar!"',
    mess: 'Toys, diyas, and ribbons scattered everywhere before the 5-minute timer starts',
    innerThought: 'How do I keep this fun without making more mess?',
    endingBeat: 'Ria hangs the last diya on the cleaned window, glowing in the evening light.',
    defaultCast: ['Ria', 'Mumma', 'Rio'],
    keepMoralOffScreen: false,
    quote: 'Clean together, celebrate together.',
    detail: 'Use a 5-minute timer to make cleanup a game.',
    punchline: '5 minutes mein ghar bhi, khushi bhi!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room, Diwali decorations half-unpacked, diyas and ribbons scattered over a toy racing track. Mumma sets a timer: "Race against time, Mumma! 5 min yaar!" Text on screen: "SAF SAFAI = HAPPY DIWALI! 🧹" "5 MINUTE TIMER! ⏱️"

On-Screen Text:
- [0-3s]: "DIWALI CLEANUP TIME! 🪔"
- [3-7s]: "RACE AGAINST TIME! ⏱️"
- [7-12s]: "TOYS, DIYAS, RIBBONS! 🧸"
- [12-16s]: "5 MINUTES — GO! 🏃"
- [16-20s]: "GHAR SAAF, DIYA ON! ✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Decorations and toys scattered everywhere. Ria: "Race against time, Mumma! 5 min yaar!" Mumma starts the timer. Rio races to put his toys away. Text: "DIWALI CLEANUP TIME! 🪔" "RACE AGAINST TIME! ⏱️"

Part 2 (10-20s): 3D Pixar style, 9:16. All three race around, tidying ribbons and diyas. The timer dings — the room is clean. Text: "5 MINUTES — GO! 🏃" "GHAR SAAF, DIYA ON! ✨"

Audio/Dialogue (Hinglish): Ria: "Race against time, Mumma! 5 min yaar!" Mumma: "Chalo, timer shuru!" Rio: "Mera toy pehle!" All: "Done!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria hangs the last diya on the cleaned window, glowing in the evening light. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Ek saath kaam karo, toh safai bhi game ban jaati hai — teamwork makes cleaning fun.
''',
  ),
  HookIdea(
    id: 'idea_78',
    category: 'Diwali',
    cover: 'Rangoli Ki Rani — Imperfect Perfect!',
    title: 'Rangoli Ki Rani — Imperfect Perfect!',
    opening: 'Mumma kehti hain — rangoli perfect hone se pehle, pyaar ka mauka.',
    problem: 'Diwali rangoli chaos — colors everywhere, but made with love',
    lesson: 'Messy rangoli bhi wahi pyara lagta hai jab usse banane waala pyaar se banaye — perfect imperfection.',
    postFormat: 'Reel',
    strategy: 'Make rangoli with hands, not tools — kids love the mess. Washable colors, adult supervision.',
    caption: 'Imperfect rangoli, perfect memories 💐 Adult supervision, washable colors only! #RangoliLove #DiwaliMess #FunLearningWithPalak #IndianParents #CreativeKids',
    pinnedComment: 'Show us your messy rangoli!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria rangoli banane ki koshish karti hai, lekin rang sab jagah phail jaata hai — star, floor, even her nose tak pahunche.
Twist: Jab sab soch rahe hain ki rangoli ab kharab ho gayi, Rio kehta hai ki yeh "abstract art" hai.
Resolution: Ghar wale rangoli ke saath khush hokar photo le li, kyunki asli rangoli toh family ka pyaar hota hai. Mumma wipes colors off Ria's nose.
Moral: Jo bhi ban raha ho, agar pyaar ke saath ban raha ho, toh wahi perfect hai — colors wash off, memories stay.
''',
    setting: 'Front courtyard, rangoli powder scattered everywhere, washable colors',
    sceneDetail: 'Pink powder all over Ria\'s nose and ears, rainbow spillage on the floor',
    dialogue: '"Yeh abstract art hai na, Mumma?"',
    mess: 'Ria\'s nose and ears covered in pink powder — washes off easily',
    innerThought: 'Maybe messy is the best kind of messy.',
    endingBeat: 'Ria gives a thumbs up, covered in colors, holding her "masterpiece". Mumma cleans up together.',
    defaultCast: ['Ria', 'Mumma', 'Rio'],
    keepMoralOffScreen: false,
    quote: 'Messy hands, happy heart — washable colors, adult nearby.',
    detail: 'Use washable colors and let kids go wild. Adult supervises cleanup.',
    punchline: 'Rangoli nahi, rang-birangi baat ban gayi — imperfect perfect!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Front courtyard, washable rangoli colors scattered everywhere. Ria tries to make rangoli — color spreads to the floor, her nose, her ears. Text on screen: "RANGOLI KI RANI! 💐" "IMPERFECT = PERFECT! ✨"

On-Screen Text:
- [0-3s]: "RANGOLI TIME! 🎨"
- [3-7s]: "RANG EVERYWHERE! 😅"
- [7-12s]: "YEH ABSTRACT ART HAI! 🖼️"
- [12-16s]: "PYAAR SE BANAYA! ❤️"
- [16-20s]: "COLORS WASH OFF, MEMORIES STAY 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria spreads rangoli color — it ends up on the floor, her nose, her ears. Everyone thinks it's ruined. Text: "RANGOLI TIME! 🎨" "RANG EVERYWHERE! 😅"

Part 2 (10-20s): 3D Pixar style, 9:16. Rio declares: "Yeh abstract art hai!" Ria beams: "Yeh abstract art hai na, Mumma?" The family takes a photo with the messy rangoli. Text: "YEH ABSTRACT ART HAI! 🖼️" "PYAAR SE BANAYA! ❤️"

Audio/Dialogue (Hinglish): Rio: "Yeh abstract art hai!" Ria: "Yeh abstract art hai na, Mumma?" Mumma laughing, wiping her nose: "Haan beta, bilkul hai." All pose for a photo.

Part 3 (20-30s): 3D Pixar style, 9:16. Ria gives a thumbs up, covered in colors, holding her "masterpiece." Mumma cleans up with her together. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Jo bhi pyaar ke saath banaya jaaye, wahi perfect hai — colors wash off, memories stay.
''',
  ),
  HookIdea(
    id: 'idea_79',
    category: 'Ria Chaos',
    cover: 'Baal Ka Mahasangram!',
    title: 'Baal Ka Mahasangram!',
    opening: 'Jab bhi Mumma haath jodne lage, Ria udas ho jaati thi.',
    problem: 'Ria gets upset when Mumma tries to braid her hair — sitting still is hard.',
    lesson: 'Sing a hair-braiding song to make the wait fun. Patience makes pretty braids.',
    postFormat: 'Reel',
    strategy: 'Sing a hair-braiding song to make the wait fun.',
    caption: 'Patience is the prettiest hairstyle 💁‍♀️ #HairTime #ToddlerRoutine #FunLearningWithPalak #IndianParents #Patience',
    pinnedComment: 'What song do you sing while braiding?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria ke baal banate time bahut hi zyada hilne lagti thi aur Mumma ke haath thok deti thi. Mumma ko ek geet gana padta tha taaki woh aaram se baal bana sake.
Twist: Beech mein Ria ne ek chhoti si dua maangi — woh chahti thi ki uske baal "zyada lambe" hon.
Resolution: Mumma ne geet gaate hue baal banaye aur Ria ko ek "badi behen" bankar dikhaya.
Moral: Thoda intezaar aur ek geet, toh baal bhi sundar ho jaate hain.
''',
    setting: 'Bedroom in the morning, hair clip and rubber bands ready',
    sceneDetail: 'A half-braided pigtail dangling from Ria\'s head',
    dialogue: '"Mumma, yeh itna der kyun lag raha hai?!"',
    mess: 'Rubber bands snap and fly across the room',
    innerThought: 'Why does braiding take so long with three helpers?',
    endingBeat: 'Ria runs her fingers through the finished braids and strikes a pose.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Good hair days come after patience plays.',
    detail: 'Use a timer and reward stickers for sitting still.',
    punchline: 'Baal bhi, patience bhi — dono mil gaye!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bedroom, morning, hair clips and rubber bands ready. Ria fidgets as Mumma starts braiding: "Mumma, yeh itna der kyun lag raha hai?!" A rubber band snaps and flies across the room. Text on screen: "BAAL KA MAHASANGRAM! 💁" "EK GEET, SAB THEEK! 🎵"

On-Screen Text:
- [0-3s]: "BRAID TIME! 💁"
- [3-7s]: "ITNA DER KYUN?! 😤"
- [7-12s]: "RUBBER BAND FLIES! 😂"
- [12-16s]: "MUMMA SINGS A SONG 🎵"
- [16-20s]: "BAAL READY! ✨"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria fidgets, half a braid dangling: "Mumma, yeh itna der kyun lag raha hai?!" A rubber band snaps and flies. Text: "BRAID TIME! 💁" "ITNA DER KYUN?! 😤"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma starts singing a hair-braiding song to make the wait fun. Ria settles, humming along, sitting still at last. Text: "MUMMA SINGS A SONG 🎵" "BAAL READY! ✨"

Audio/Dialogue (Hinglish): Ria: "Mumma, yeh itna der kyun lag raha hai?!" Mumma singing: "Baal baal, chaahe kitna bhi lambe ho..." Ria giggling, humming along. Mumma: "Ho gaya!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria runs her fingers through the finished braids and strikes a proud pose. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Thoda intezaar aur ek geet, toh baal bhi sundar ho jaate hain — patience makes pretty braids.
''',
  ),
  HookIdea(
    id: 'idea_80',
    category: 'Ria Chaos',
    cover: 'Outfit Drama!',
    title: 'Outfit Drama!',
    opening: 'Ria poora closet khali kar rahi thi... phir Mumma ne sirf teen outfit nikale, aur 1 minute mein decision ho gaya!',
    problem: 'With her whole closet to choose from, Ria can\'t decide what to wear — too many options lead to endless indecision.',
    lesson: 'Give 3 outfit choices and let the child pick. Fewer options mean faster, more confident decisions.',
    postFormat: 'Reel',
    strategy: 'Give 3 outfit choices and let the child pick.',
    caption: 'Let them choose, let them shine 👗✨ #OutfitChoice #ToddlerIndependence #FunLearningWithPalak #IndianParents #DecisionMaking',
    pinnedComment: 'How many outfits does your little one try before deciding?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria stands in front of her overflowing closet, pointing at dress after dress, changing her mind every few seconds — "Yeh? Nahi, woh? Nahi..."
Twist: Mumma pulls out just three options — red, blue, green — and lays them on the bed: "Teen mein se ek choose karo."
Resolution: Ria looks at all three for a moment, then grabs the green one: "Mumma, yehi pasand aaya!" No more flip-flopping.
Moral: Fewer choices, faster decisions — three options give enough freedom without the overwhelm.
''',
    setting: 'Bedroom, clothes all over the bed',
    sceneDetail: 'Ria holding 3 different colored dresses, spinning in each',
    dialogue: '"Yeh red? Nahi, blue? Haan, haan — green!"',
    mess: 'Ria points at dress after dress from the closet before Mumma narrows it down to three',
    innerThought: 'Why does picking one thing take forever?',
    endingBeat: 'Ria gives herself a final twirl in the chosen outfit, confident and happy.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'A choice made with confidence is always right.',
    detail: 'Use the "3 choices" trick to cut decision fatigue.',
    punchline: 'Teen options, ek decision — full power!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bedroom, clothes all over the bed. Ria stands in front of her overflowing closet, pointing at dress after dress: "Yeh? Nahi, woh? Nahi..." Text on screen: "OUTFIT DRAMA! 👗" "TEEN CHOICES, EK DECISION! ✨"

On-Screen Text:
- [0-3s]: "ITNE SAARE KAPDE! 👗"
- [3-7s]: "YEH? NAHI... WOH? NAHI... 😩"
- [7-12s]: "TEEN MEIN SE EK CHOOSE KARO 🔴🔵🟢"
- [12-16s]: "YEHI PASAND AAYA! 💚"
- [16-20s]: "CONFIDENT TWIRL! 💃"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria flips through her overflowing closet, changing her mind every few seconds: "Yeh? Nahi, woh? Nahi..." Mumma watches, then pulls out just three outfits. Text: "ITNE SAARE KAPDE! 👗" "YEH? NAHI... WOH? NAHI... 😩"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma lays out red, blue, and green on the bed: "Teen mein se ek choose karo." Ria looks at all three for a moment, then grabs the green one: "Mumma, yehi pasand aaya!" Text: "TEEN MEIN SE EK CHOOSE KARO 🔴🔵🟢" "YEHI PASAND AAYA! 💚"

Audio/Dialogue (Hinglish): Ria: "Yeh red? Nahi, blue? Haan, haan — green!" Mumma: "Teen mein se ek choose karo." Ria grabbing green: "Mumma, yehi pasand aaya!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria gives herself a final twirl in the green outfit, confident and happy. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Fewer choices, faster decisions — three options give enough freedom without the overwhelm.
''',
  ),
HookIdea(
    id: 'idea_81',
    category: 'Learning Lesson',
    cover: 'The Family Tree Surprise!',
    title: 'The Family Tree Surprise!',
    opening: 'Jab Mumma ne ek purani book di, Ria ki curiosity ka level 100 ho gaya.',
    problem: 'Ria receives a surprise gift of a family tree book — where does she fit?',
    lesson: 'Apni jadon ko jaanna hi apni pehchaan banane ka pehla kadam hai. Family tree dikhata hai tum kahan se aaye ho — aur khaali jagah dikhati hai tum kahan jaa sakti ho.',
    postFormat: 'Reel',
    strategy: 'Use a visual family tree chart to make connections.',
    caption: 'We are branches, we are roots 🌳❤️ #FamilyTree #RootsAndWings #FunLearningWithPalak #IndianParents #FamilyHistory',
    pinnedComment: 'Tag your family tree buddy!',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria ko ek purani book mili jisme uska family tree likha tha. Har photo aur naam uski zindagi ka hissa tha — Mumma ke bachpan se lekar Ria ke pehle school din tak.
Twist: Ria ne dekha ki uske saath ek photo bhi hai jisme ek khaali jagah tha — "Future Ria" ke liye.
Resolution: Ria decides she'll fill that empty space herself, one day, as whoever she grows up to be — her own choice, not anyone else's.
Moral: Apni jadon ko jaanna hi pehchaan ki shuruaat hai — aur khaali jagah tumhara apna safar likhne ke liye hai.
''',
    setting: 'Grandparent\'s attic, old photo albums open',
    sceneDetail: 'A large family tree chart with photos in tiny frames',
    dialogue: '"Yeh toh main hun... par future?"',
    mess: 'Photos fall off the tree chart when Ria touches it eagerly',
    innerThought: 'I want to know who I really am.',
    endingBeat: 'Ria pins her own photo into the empty spot on the tree, smiling.',
    defaultCast: ['Ria', 'Mumma', 'Daadi'],
    keepMoralOffScreen: false,
    quote: 'Roots don\'t hold us back - they lift us forward.',
    detail: 'Create a living family tree with new photos every year.',
    punchline: 'Main bhi toh ek branch hoon!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Grandparent's attic, old photo albums open. Mumma hands Ria an old book — a large family tree chart with photos in tiny frames. Ria's curiosity lights up. Text on screen: "THE FAMILY TREE SURPRISE! 🌳" "WHERE DO I FIT? 🔍"

On-Screen Text:
- [0-3s]: "PURANI BOOK MILI! 📖"
- [3-7s]: "FAMILY TREE! 🌳"
- [7-12s]: "YEH TOH MAIN HUN! 😮"
- [12-16s]: "EK KHAALI JAGAH... 🤔"
- [16-20s]: "MAIN BHI EK BRANCH HOON! 🌱"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria flips through the family tree chart — Mumma's childhood, Ria's first school day, Daadi's wedding photo. Photos flutter as she touches the chart eagerly. Text: "PURANI BOOK MILI! 📖" "FAMILY TREE! 🌳"

Part 2 (10-20s): 3D Pixar style, 9:16. Ria spots an empty frame labeled "Future Ria": "Yeh toh main hun... par future?" Daadi smiles: "Woh jagah tumhare liye hai, jo tum banogi." Text: "YEH TOH MAIN HUN! 😮" "EK KHAALI JAGAH... 🤔"

Audio/Dialogue (Hinglish): Ria: "Yeh toh main hun... par future?" Daadi: "Woh jagah tumhare liye hai, jo tum banogi — apni marzi se." Ria: "Main bhi toh ek branch hoon!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria pins her own photo into the empty spot on the tree, smiling. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Apni jadon ko jaanna hi pehchaan ki shuruaat hai — aur khaali jagah tumhara apna safar likhne ke liye hai.
''',
  ),
  HookIdea(
    id: 'idea_82',
    category: 'Ria Chaos',
    cover: 'Shopping Ka Jungle!',
    title: 'Shopping Ka Jungle!',
    opening: 'Jab bhi mall jaate hain, Ria keh deti hai — main sirf ek chiz mangti hoon.',
    problem: 'Ria wants everything at the mall — makeup, clothes, accessories, even a toy for Rio.',
    lesson: 'Set a limit: one item per shopping trip. Limits create freedom.',
    postFormat: 'Reel',
    strategy: 'One-item rule: pick only one thing per shopping trip.',
    caption: 'One is plenty 💝 #ShoppingLimit #ToddlerWants #FunLearningWithPalak #IndianParents #ShoppingWithKids',
    pinnedComment: 'What\'s your one essential?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria ko mall mein jaate hi sab kuch chahiye — makeup, clothes, accessories, Rio ke liye toy bhi. Mumma thak jaati hai.
Twist: Ria ne ek "wish list" banayi — par sirf 3 lines tak hi likhne di.
Resolution: Woh ek cheez pakad kar khush hi thi — ek sparkly hair clip.
Moral: Limitation create karni padti hai freedom ki tarah.
''',
    setting: 'Mall corridor, toy aisle',
    sceneDetail: 'Ria holding 5 different items, wide eyes scanning every shelf',
    dialogue: '"Mumma, yeh bhi toh chahiye! Aur yeh bhi!"',
    mess: 'Everything ends up in the cart before the limit is explained',
    innerThought: 'Why can\'t I have just one of everything?',
    endingBeat: 'Ria walks out with her one hair clip, already planning what to buy next time.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'One thing chosen with joy beats everything half-wanted.',
    detail: 'Use a "3 wishes" rule for younger kids, "1 item" for older.',
    punchline: 'Ek hi chiz, pura pyaar!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Mall corridor, toy aisle. Ria scans every shelf, wide-eyed, grabbing item after item: "Mumma, yeh bhi toh chahiye! Aur yeh bhi!" Text on screen: "SHOPPING KA JUNGLE! 🛍️" "ONE ITEM RULE! ✅"

On-Screen Text:
- [0-3s]: "SAB KUCH CHAHIYE! 🛍️"
- [3-7s]: "5 ITEMS IN HAND! 😅"
- [7-12s]: "WISH LIST — 3 LINES ONLY! 📝"
- [12-16s]: "EK SPARKLY HAIR CLIP! ✨"
- [16-20s]: "LIMITS = FREEDOM! 💝"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria grabs item after item from the shelves: "Mumma, yeh bhi toh chahiye! Aur yeh bhi!" Mumma looks tired. Text: "SAB KUCH CHAHIYE! 🛍️" "5 ITEMS IN HAND! 😅"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma hands her a tiny notepad: "Sirf teen lines ki wish list." Ria writes three things, then picks just one — a sparkly hair clip. Text: "WISH LIST — 3 LINES ONLY! 📝" "EK SPARKLY HAIR CLIP! ✨"

Audio/Dialogue (Hinglish): Ria: "Mumma, yeh bhi toh chahiye! Aur yeh bhi!" Mumma: "Sirf teen lines ki wish list." Ria writing, then choosing: "Yehi lungi!"

Part 3 (20-30s): 3D Pixar style, 9:16. Ria walks out holding her one hair clip, happy, already planning what she'll pick next time. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Limitation create karni padti hai freedom ki tarah — limits create freedom.
''',
  ),
HookIdea(
    id: 'idea_83',
    category: 'Learning Lesson',
    cover: 'Office Wali Mumma vs WFH Mumma!',
    title: 'Office Wali Mumma vs WFH Mumma!',
    opening: '"Work from home" kehti hoon, par office wali jaisi lagti hoon.',
    problem: 'Office going mom vs work from home moms — both work hard, just differently.',
    lesson: 'Dono tarah ki mummy hoti hain — ek doosre ki help ke liye hamesha maujood.',
    postFormat: 'Reel',
    strategy: 'Split-screen comparison of both moms\' daily routines.',
    caption: 'All moms are superhero moms 🦸‍♀️ #OfficeMomVsWFHMom #SuperheroMoms #FunLearningWithPalak #IndianParents #MomLife',
    pinnedComment: 'Which type of mom are you?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria ko do Mummies dikhai de rahi hain — ek office jati hai, ek home pe kaam karti hai. Dono ka apna alag tarah ka swag hai.
Twist: Office wali Mumma ka lunch break Rio ke saath video call pe hota hai, jisme WFH wali Mumma bhi join hoti hai.
Resolution: Dono mammi mil kar ek "Hybrid mom" ban jati hain — best of both worlds.
Moral: It's not about where you work — it's about how much you love.
''',
    setting: 'Two sides of the same kitchen, split-screen',
    sceneDetail: 'One side has a laptop and coffee mug, the other has a sari and diya',
    dialogue: 'Office Mumma: "5 PM deadline, but I\'m still your mom first." WFH Mumma: "3 PM soccer pickup, but I\'m still your hero."',
    mess: 'A spilled coffee lands on the WFH mom\'s work shirt',
    innerThought: 'Why does everyone think I have it "easier"?',
    endingBeat: 'Both moms laugh over spilled coffee, trading places for a day.',
    defaultCast: ['Ria', 'Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Whether in heels or slippers, every mom walks the same path.',
    detail: 'Celebrate both work styles — they both matter.',
    punchline: 'Jahan bhi ho, mummy hi toh hai!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Split-screen of the same kitchen, two different days. Left side: Mumma at a laptop with a coffee mug — an office day. Right side: Mumma in a sari near a diya — a work-from-home day. Text on screen: "OFFICE WALI MUMMA VS WFH MUMMA! 🦸" "BOTH ARE SUPERHEROES! 💛"

On-Screen Text:
- [0-3s]: "TWO KINDS OF MUMMA DAYS 🦸"
- [3-7s]: "OFFICE DAY: LAPTOP + COFFEE 💻"
- [7-12s]: "WFH DAY: SARI + DIYA 🪔"
- [12-16s]: "LUNCH BREAK VIDEO CALL! 📱"
- [16-20s]: "HYBRID MOM = BEST OF BOTH! 🌟"

Part 1 (0-10s): 3D Pixar style, 9:16. Split screen shows Mumma on an office day (laptop, coffee mug) and a WFH day (sari, diya) — same person, two different routines. Text: "TWO KINDS OF MUMMA DAYS 🦸" "OFFICE DAY: LAPTOP + COFFEE 💻" "WFH DAY: SARI + DIYA 🪔"

Part 2 (10-20s): 3D Pixar style, 9:16. On the office day, Mumma's lunch break becomes a video call with Rio. Coffee spills a little in the rush, and she laughs it off. Text: "LUNCH BREAK VIDEO CALL! 📱"

Audio/Dialogue (Hinglish): Office-day Mumma: "5 PM deadline, but I'm still your mom first." WFH-day Mumma: "3 PM soccer pickup, but I'm still your hero." Rio on the call: "Mumma, aap kab aayengi?"

Part 3 (20-30s): 3D Pixar style, 9:16. Both versions of Mumma's day merge into one proud "hybrid mom" moment. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: It's not about where you work — it's about how much you love.
''',
  ),
  HookIdea(
    id: 'idea_84',
    category: 'Child Chaos',
    cover: 'Game Mode: Busy!',
    title: 'Game Mode: Busy!',
    opening: 'Jab bhi phone uthate hain, Rio kehta hai — "Papa call aa raha hai, par main game mein hoon!".',
    problem: 'Rio refuses to pause his game to take a call from Papa.',
    lesson: 'Game bhi time hote hain, call bhi time hote hain — dono important hain. Timer laga ke transition banao.',
    postFormat: 'Reel',
    strategy: 'Set an alarm for game switch — when it dings, it\'s phone time.',
    caption: 'Balance, baby! 🎮📞 #GameTimeVsFamilyTime #ParentingHacks #FunLearningWithPalak #IndianParents #ScreenTimeBalance',
    pinnedComment: 'How do you handle game time vs family time?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Rio ka favorite game chal raha hota hai jab Papa se call aata hai. Woh call khatam hone tak nahi janta — "Bas ek aur level!".
Twist: Papa ne ek naya trick ki — usne apne voice message ke saath ek mini game bheja: "Call karo jab game over ho."
Resolution: Rio ne apne game se bahar nikal kar call liya — aur dono together ek level complete kiya.
Moral: Time boundaries without punishment = happy kids.
''',
    setting: 'Living room floor, console glowing',
    sceneDetail: 'Rio with headphones, controller in hands, Papa\'s call flashing on screen',
    dialogue: '"5 more minutes, Papa! Just one more level!"',
    mess: 'Controller throws when Rio loses a level right before the call',
    innerThought: 'Why does Papa always call when I am about to win?',
    endingBeat: 'Rio pauses the game, calls Papa back, and explains his strategy between levels.',
    defaultCast: ['Rio', 'Papa', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'The pause button is a powerful tool.',
    detail: 'Use a kitchen timer for game-to-call transitions.',
    punchline: 'Level up, then call up!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, console glowing. Rio, headphones on, controller in hand, deep in his game. Papa's call flashes on screen. Rio: "5 more minutes, Papa! Just one more level!" Text on screen: "GAME MODE: BUSY! 🎮" "TIMER FOR TRANSITIONS! ⏱️"

On-Screen Text:
- [0-3s]: "PAPA CALLING! 📞"
- [3-7s]: "BAS EK AUR LEVEL! 🎮"
- [7-12s]: "MINI GAME MESSAGE! 📩"
- [12-16s]: "CALL KARO JAB GAME OVER HO ⏱️"
- [16-20s]: "LEVEL UP, THEN CALL UP! 🏆"

Part 1 (0-10s): 3D Pixar style, 9:16. Papa's call flashes on screen. Rio: "5 more minutes, Papa! Just one more level!" He loses the level right before the call, controller nearly flying. Text: "PAPA CALLING! 📞" "BAS EK AUR LEVEL! 🎮"

Part 2 (10-20s): 3D Pixar style, 9:16. Papa sends a voice message with a mini challenge: "Call karo jab game over ho." Rio pauses his game and calls back. Text: "MINI GAME MESSAGE! 📩" "CALL KARO JAB GAME OVER HO ⏱️"

Audio/Dialogue (Hinglish): Rio: "5 more minutes, Papa! Just one more level!" Papa's message: "Call karo jab game over ho." Rio pausing: "Theek hai, Papa!" Rio on call: "Dekho, maine kya strategy use ki!"

Part 3 (20-30s): 3D Pixar style, 9:16. Rio and Papa complete a level together over the call, both laughing. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Time boundaries without punishment = happy kids.
''',
  ),
  HookIdea(
    id: 'idea_85',
    category: 'Learning Lesson',
    cover: 'Calm Down Corner!',
    title: 'Calm Down Corner!',
    opening: 'Jab Ria koi cheez ke liye bahut zaroorat mehsoos karti hai — like wanting a specific snack or needing a hug — Mumma calm corner le aati hai.',
    problem: 'Ria communicates big needs through gentle persistence, and Mumma guides her to a calm-down space with comfort items instead of saying no.',
    lesson: 'Big feelings are okay. A calm-down space with comfort items helps little ones reset with gentle guidance.',
    postFormat: 'Reel',
    strategy: 'The "calm-down corner": 3 deep breaths, 2 comfort items, 1 reconnect hug.',
    caption: 'Connection before correction 💛 #EmotionalRegulation #CalmDownCorner #FunLearningWithPalak #IndianParents #GentleParenting',
    pinnedComment: 'What works for your child\'s big feelings?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Jab Ria ko koi badi chahat hoati hai — jaise ek specific snack chahiye ya ek hug — Mumma dekhti hai. Ria nudge karti hai Mumma's hand gently, then sits by her calm-down corner with her soft cushion.

Twist: Har deep breath ke baad Ria aur bhi soft ho jaati hai, aur last step tak usey pata chalta hai ki sab theek ho jayega — par pehle ek chhota sa hug bhi zaroori hai.

Resolution: Ria kehti hai (softly, in her quiet way) — nudge, nudge — and Mumma hugs her tight. The storm has passed. Ria is ready for a new game.

Moral: Connection before correction. A calm space with comfort beats any timeout chair.
''',
    setting: 'Corner of the room where tantrums happen, calm-down corner with cushion and favorite toy',
    sceneDetail: 'Ria nudging Mumma\'s hand, sitting by her calm-down corner with soft cushion',
    dialogue: '"Beta, chalo calm down corner mein chalte hain. Teen deep breaths lete hain."',
    mess: 'Ria nudges Mumma\'s hand again and again, gently insistent, before settling into the calm-down corner',
    innerThought: 'This looks simple, but it is working.',
    endingBeat: 'Ria rests her head on Mumma\'s shoulder after breathing, then sits up ready for a new game.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Deep breaths and a hug can deflate anger faster than any timeout chair.',
    detail: 'Always kneel to eye level — no "above" positioning. Create a calm-down corner with soft items.',
    punchline: 'Gussa bhi, pyaar bhi — breathing se mit jaye!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Corner of the room, a calm-down corner with a soft cushion and favorite toy. Ria nudges Mumma's hand gently, again and again. Mumma kneels to her eye level: "Beta, chalo calm down corner mein chalte hain. Teen deep breaths lete hain." Text on screen: "CALM DOWN CORNER! 💛" "CONNECTION BEFORE CORRECTION ❤️"

On-Screen Text:
- [0-3s]: "RIA NUDGES MUMMA'S HAND 🤏"
- [3-7s]: "CALM DOWN CORNER TIME 🧘"
- [7-12s]: "TEEN DEEP BREATHS 🌬️"
- [12-16s]: "AUR SOFT HO JAATI HAI 💛"
- [16-20s]: "HUG, THEN READY TO PLAY! 🤗"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria nudges Mumma's hand gently, insistently. Mumma kneels to her eye level: "Beta, chalo calm down corner mein chalte hain. Teen deep breaths lete hain." They sit together with the soft cushion. Text: "RIA NUDGES MUMMA'S HAND 🤏" "CALM DOWN CORNER TIME 🧘"

Part 2 (10-20s): 3D Pixar style, 9:16. With each deep breath, Ria grows calmer. At the last step, she leans in for a small hug — that part matters too. Text: "TEEN DEEP BREATHS 🌬️" "AUR SOFT HO JAATI HAI 💛"

Audio/Dialogue (Hinglish): Mumma: "Beta, chalo calm down corner mein chalte hain. Teen deep breaths lete hain." Ria breathing along, softly: "Mujhe hug chahiye." Mumma hugs her tight.

Part 3 (20-30s): 3D Pixar style, 9:16. Ria rests her head on Mumma's shoulder after breathing, then sits up, ready for a new game. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Connection before correction. A calm space with comfort beats any timeout chair.
''',
  ),
  HookIdea(
    id: 'idea_86',
    category: 'Ria Chaos',
    cover: 'Mehfil vs Mess!',
    title: 'Mehfil vs Mess!',
    opening: 'Mumma ki mehndi khatam hone se pehle, Ria ki messy hair ka kya fasana?',
    problem: 'Mummy spends 20 minutes on hairstyle, Ria messes it up in 2 minutes.',
    lesson: 'Mehenat ki koshish, par results kabhi perfect nahi hota. Embrace the mess!',
    postFormat: 'Reel',
    strategy: 'Embrace the 2-minute mess — quick ponytail and go!',
    caption: 'Perfect is boring — messy is magnetic 💁‍♀️ #MessyHair #MomLife #FunLearningWithPalak #IndianParents #MessyIsBeautiful',
    pinnedComment: 'How fast can YOU do a ponytail?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma ko 20 minute lagti hai apni Mehndi aur hairstyle banane mein, lekin Ria sirf 2 minute mein sab kuch bigaad sakti hai.
Twist: Jab sab soch rahe hain ki kuchh bhi nahi bacha, Ria ne ek "messy look" ko ek naye fashion trend kehte hain.
Resolution: Mumma ne accept kar liya ki messy hairstyle bhi ek tarah ki beauty hai.
Moral: Effort matters more than perfection.
''',
    setting: 'Bathroom counter, Mumma\'s dupatta and Ria\'s toys everywhere',
    sceneDetail: 'Ria\'s hair full of bows, clips, and one random lollipop stick',
    dialogue: '"Mumma, look! I am a fairy princess mess!"',
    mess: 'Hair gel spills on Mumma\'s dupatta',
    innerThought: 'Why does it take me 20 minutes but her just 2 to ruin it?',
    endingBeat: 'Both Mumma and Ria walk out together, hair messy but hearts full.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: 'Effort with love always looks better than flawless with none.',
    detail: 'Use a "messy bun" rule for quick mornings.',
    punchline: 'Mehfilon ki shag, messy hair ka swag!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Bathroom counter, Mumma's dupatta and Ria's toys everywhere. Mumma spent 20 minutes on her mehndi and hairstyle. Ria's hair is now full of bows, clips, and a random lollipop stick. Text on screen: "MEHFIL VS MESS! 💁" "EFFORT > PERFECTION! 💛"

On-Screen Text:
- [0-3s]: "20 MINUTES OF STYLING! ⏱️"
- [3-7s]: "RIA: 2 MINUTES TO UNDO IT! 😅"
- [7-12s]: "FAIRY PRINCESS MESS! 🧚"
- [12-16s]: "MESSY LOOK = NEW TREND? ✨"
- [16-20s]: "HEARTS FULL, HAIR MESSY! 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Mumma finishes her careful hairstyle. Ria, in just two minutes, has bows, clips, and a lollipop stick tangled in her hair: "Mumma, look! I am a fairy princess mess!" Text: "20 MINUTES OF STYLING! ⏱️" "RIA: 2 MINUTES TO UNDO IT! 😅"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma laughs instead of fixing it, calling it a new "messy look" fashion trend. Text: "FAIRY PRINCESS MESS! 🧚" "MESSY LOOK = NEW TREND? ✨"

Audio/Dialogue (Hinglish): Ria: "Mumma, look! I am a fairy princess mess!" Mumma laughing: "Yeh toh naya fashion hai!" Both giggle.

Part 3 (20-30s): 3D Pixar style, 9:16. Both Mumma and Ria walk out together, hair messy but hearts full. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Effort matters more than perfection.
''',
  ),
HookIdea(
    id: 'idea_87',
    category: 'Learning Lesson',
    cover: 'Team Siblings!',
    title: 'Team Siblings!',
    opening: 'Jab koi bhi badi problem aaye, toh Ria-Rio-Cuty ek saath mil kar solve karte hain.',
    problem: 'Ria, Rio, Cuty fight with each other, but whenever anyone else tries to bother one of them, they become a team.',
    lesson: 'Jab tak bhai-behen mil kar khade rahte hain, toh koi bhi problem hal ho sakti hai. Unity is strength.',
    postFormat: 'Reel',
    strategy: 'Use sibling teamwork to help someone in need at the park.',
    caption: 'United we stand 💪👧👦 #SiblingTeamwork #FamilyUnity #FunLearningWithPalak #IndianParents #SiblingLove',
    pinnedComment: 'What\'s your sibling super-power?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria, Rio, Cuty hamesha ek dusre se ladte rehte hain — par jab koi stranger unse baat karta hai, toh ve ek team ban jaate hain.
Twist: Auntie at the park looks confused, pointing around: "Kya koi bachcha dekha? Main apna dog kho diya hai!" Ria sees her distress.
Resolution: Teenon milkar ek proper search team ban gaye — Ria tracks footprints, Rio checks under benches, Cuty uses her keen ears. After a few minutes, they find the lost dog wagging its tail near the swings.
Moral: Unity is strength — when siblings work together, even strangers feel safe.
''',
    setting: 'Neighborhood park, afternoon',
    sceneDetail: 'Three kids forming a line, then switching to a triangle formation',
    dialogue: 'Ria: "We don\'t fight outsiders - we fight FOR each other."',
    mess: 'Their own toy fight ends when a lost auntie needs help — the siblings unite.',
    innerThought: 'Why do we only unite when someone else is in trouble?',
    endingBeat: 'The three siblings bow together with the auntie and her dog after a happy reunion.',
    defaultCast: ['Ria', 'Rio', 'Cuty'],
    keepMoralOffScreen: false,
    quote: 'When siblings unite, even giants look small.',
    detail: 'Teach the "Buddy System" early — always look out for each other.',
    punchline: 'Teenon mile toh team, bina toh dream!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Neighborhood park, afternoon. Ria, Rio, and Cuty are mid-squabble over a toy when a worried auntie approaches, pointing around: "Kya koi bachcha dekha? Main apna dog kho diya hai!" Text on screen: "TEAM SIBLINGS! 💪" "UNITY IS STRENGTH! 🤝"

On-Screen Text:
- [0-3s]: "SIBLINGS FIGHTING... 😤"
- [3-7s]: "AUNTIE NEEDS HELP! 🐕"
- [7-12s]: "TEAM FORMS INSTANTLY! 🔺"
- [12-16s]: "FOOTPRINTS, BENCHES, EARS! 🔍"
- [16-20s]: "DOG FOUND! 🎉"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria, Rio, and Cuty are squabbling over a toy when the worried auntie approaches: "Kya koi bachcha dekha? Main apna dog kho diya hai!" Ria notices her distress immediately. Text: "SIBLINGS FIGHTING... 😤" "AUNTIE NEEDS HELP! 🐕"

Part 2 (10-20s): 3D Pixar style, 9:16. The three instantly form a search team — Ria tracks footprints, Rio checks under benches, Cuty listens with her keen ears. Text: "TEAM FORMS INSTANTLY! 🔺" "FOOTPRINTS, BENCHES, EARS! 🔍"

Audio/Dialogue (Hinglish): Auntie: "Kya koi bachcha dekha? Main apna dog kho diya hai!" Ria: "Hum madad karenge!" Ria: "We don't fight outsiders — we fight FOR each other." Rio: "Mil gaya!"

Part 3 (20-30s): 3D Pixar style, 9:16. They find the lost dog wagging its tail near the swings. The three siblings bow together with the auntie and her dog after a happy reunion. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Unity is strength — when siblings work together, even strangers feel safe.
''',
  ),
  HookIdea(
    id: 'idea_88',
    category: 'Learning Lesson',
    cover: 'Confidence Hack Pack!',
    title: 'Confidence Hack Pack!',
    opening: 'Har ek trick batane ka maza aata hai jab bachche use khud se try karte hain.',
    problem: 'Tricks which we can try to make kids confident and learn life skills',
    lesson: 'Confidence build karne ke liye sabse best trick hai — "try karo, fail mat socho".',
    postFormat: 'Carousel',
    strategy: '5 daily confidence-builders: mirror talk, small wins, "I did it" moment.',
    caption: 'Confidence is a muscle — flex it daily 💪 #ConfidenceBuilding #KidsConfidence #FunLearningWithPalak #IndianParents #LifeSkills',
    pinnedComment: 'Start with one today. Which trick will you try?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Mumma ko 5 life skill tricks pata chali hain jo bachchon ko confident banati hain: mirror self-talk, small daily wins, "I can" affirmations, safe failure zones, aur celebration rituals.
Twist: Rio ne pehla try kiya — mirror talk. Pehle bahut hi awkward laga, par dusre din usne khud se compete karna shuru kar diya.
Resolution: Teenon children ne apni confidence diary banayi — har din ek nayi skill try karte hue.
Moral: Confidence grows in the soil of consistent small actions.
''',
    setting: 'Kids\' room mirror, morning routine time',
    sceneDetail: 'A "Confidence Jar" filled with small notes — "Today I tied my shoes"',
    dialogue: '"Main yeh kar sakta hun!" — Rio to his reflection.',
    mess: 'The mirror gets foggy during the emotional talk',
    innerThought: 'What if they laugh at me?',
    endingBeat: 'All three kids add their daily win to the jar before bedtime.',
    defaultCast: ['Ria', 'Rio', 'Cuty'],
    keepMoralOffScreen: false,
    quote: 'Confidence isn\'t about never failing — it\'s about trying anyway.',
    detail: 'Create a "Wins Wall" with sticky notes for every small victory.',
    punchline: 'Confidence = small steps, big heart!',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Kids' room mirror, morning routine time, a "Confidence Jar" filled with small notes nearby. Rio stands in front of the mirror: "Main yeh kar sakta hun!" It feels awkward at first. Text on screen: "CONFIDENCE HACK PACK! 💪" "5 DAILY BUILDERS! 🌟"

On-Screen Text:
- [0-3s]: "MIRROR TALK! 🪞"
- [3-7s]: "MAIN YEH KAR SAKTA HUN! 💪"
- [7-12s]: "AWKWARD AT FIRST... 😅"
- [12-16s]: "SMALL WINS JAR! 🏆"
- [16-20s]: "CONFIDENCE GROWS! 🌱"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio looks at his reflection, feeling awkward: "Main yeh kar sakta hun!" His voice wavers at first. Text: "MIRROR TALK! 🪞" "MAIN YEH KAR SAKTA HUN! 💪" "AWKWARD AT FIRST... 😅"

Part 2 (10-20s): 3D Pixar style, 9:16. By the next day, Rio is competing with himself, trying a little harder each time. Ria and Cuty join in with their own small wins. Text: "SMALL WINS JAR! 🏆" "CONFIDENCE GROWS! 🌱"

Audio/Dialogue (Hinglish): Rio to mirror: "Main yeh kar sakta hun!" Next day, more confident: "Aaj maine khud joote pehne!" Ria: "Maine bhi kuch kiya!" Cuty hops in, adding her own note.

Part 3 (20-30s): 3D Pixar style, 9:16. All three kids add their daily win to the Confidence Jar before bedtime. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Confidence grows in the soil of consistent small actions.
''',
  ),

  // New ideas (added by hand)
  HookIdea(
    id: 'idea_89',
    category: 'Learning Lesson',
    cover: 'Mumma Ke Chappal Mein Dhamaal! 👡',
    title: 'Mumma Ke Chappal Mein Dhamaal! 👡',
    opening: 'Ria ne pehen li Mumma ki badi chappal… aur dhup-dhup chalne lagi!',
    problem: 'Ria insists on walking around in Mumma\'s oversized chappals for fun. Mumma warns her they are too big and she could trip, but Ria does not listen.',
    lesson: 'Jab bade log warning dete hain, usse sunna zaroori hai — apni marzi se zyada important hota hai safe rehna.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Bade logo ki chappal mein chalna maza toh aata hai, par size match na ho toh girne ka risk bhi hota hai! Mumma-Papa ki warning ko pehli baar mein hi sun lo. #ListenToMumma #ToddlerSafety #IndianParents #ParentingTips #FunLearningWithPalak',
    pinnedComment: 'Kya aapka bachcha bhi bade logo ke jhoote/chappal pehenne ki koshish karta hai? 😂',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria spots Mumma's flip-flops by the door and slides her tiny feet in, clip-clopping around proudly: "Dekho, main bhi bada ho gayi!" Mumma watches, amused but cautious: "Ria, woh chappal tumhare liye bade hain, gir jaogi — utaar do."
Twist: Ria ignores her, speeding up to show off a "dance" in the oversized chappals — and her foot slips right out mid-step. She tumbles onto the rug, chappal flying off.
Resolution: Mumma rushes over, checks her knee — just a small scare, no real injury — and holds her close: "Dekho, Mumma ne pehle hi bola tha. Jab main warning deti hoon, usko sunna padta hai." Ria nods, lip trembling: "Sorry Mumma, ab sunoongi."
Moral: Mumma-Papa ki baat pehli baar mein sun lena — warning ignore karne ka result girna bhi ho sakta hai.
''',
    setting: 'Living room near the front door, afternoon, Mumma\'s chappals left by the shoe rack',
    sceneDetail: 'Mumma\'s flip-flops, way too big for Ria\'s small feet, flopping loosely with every step',
    dialogue: '"Dekho, main bhi bada ho gayi!" "Ria, woh chappal tumhare liye bade hain, gir jaogi — utaar do."',
    mess: 'Ria speeds up to show off instead of stopping, chappal slips, she tumbles onto the rug',
    innerThought: 'I warned her once — I should have taken the chappals away the moment she picked them up.',
    endingBeat: 'Ria sits in Mumma\'s lap, then puts the chappals back neatly by the door herself.',
    defaultCast: ['Ria', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room near the front door, afternoon light. Ria slides her feet into Mumma's oversized flip-flops and clip-clops around proudly: "Dekho, main bhi bada ho gayi!" Mumma watches, cautious: "Ria, woh chappal tumhare liye bade hain, gir jaogi — utaar do." Text on screen: "MUMMA KE CHAPPAL MEIN DHAMAAL! 👡" "WARNING: BADE CHAPPAL! ⚠️"

On-Screen Text:
- [0-3s]: "RIA BORROWS MUMMA'S CHAPPAL 👡"
- [3-7s]: "MUMMA WARNS: GIR JAOGI! ⚠️"
- [7-12s]: "RIA DOESN'T LISTEN… 🙈"
- [12-16s]: "OOPS — GIR GAYI! 😳"
- [16-20s]: "AB SE SUNOONGI! 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria clip-clops around in Mumma's oversized chappals, delighted. Mumma warns her calmly: "Ria, woh chappal tumhare liye bade hain, gir jaogi — utaar do." Ria ignores her and speeds up to show off. Text: "RIA BORROWS MUMMA'S CHAPPAL 👡" "MUMMA WARNS: GIR JAOGI! ⚠️"

Part 2 (10-20s): 3D Pixar style, 9:16. Mid-step, the chappal slips off and Ria tumbles onto the rug. Mumma rushes over, checks her knee, and holds her close: "Dekho, Mumma ne pehle hi bola tha." Text: "RIA DOESN'T LISTEN… 🙈" "OOPS — GIR GAYI! 😳"

Audio/Dialogue (Hinglish): Ria: "Dekho, main bhi bada ho gayi!" Mumma: "Ria, woh chappal tumhare liye bade hain, gir jaogi — utaar do." Ria falls. Mumma: "Jab main warning deti hoon, usko sunna padta hai." Ria: "Sorry Mumma, ab sunoongi."

Part 3 (20-30s): 3D Pixar style, 9:16. Ria sits in Mumma's lap, then carefully places the chappals back by the door herself. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Mumma-Papa ki baat pehli baar mein sun lena — warning ignore karne ka result girna bhi ho sakta hai.
''',
  ),

  HookIdea(
    id: 'idea_90',
    category: 'Funny',
    cover: 'Towel Race: Mumma Vs Rio! 🏃🛁',
    title: 'Towel Race: Mumma Vs Rio! 🏃🛁',
    opening: 'Nahane ke baad towel mein lipta Rio bhaagta hua nikla… race shuru!',
    problem: 'Rio refuses to get dressed after his bath and instead turns it into a running race with Mumma around the house, towel flying.',
    lesson: 'Routine kaamo ko game banane se sabka mood accha ho jaata hai — aur kaam bhi ho jaata hai!',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Nahane ke baad kapde pehnana sabse mushkil kaam? Isse race bana do! 🏃 #AfterBathFun #ToddlerGames #MummaAndRio #IndianParents #FunLearningWithPalak',
    pinnedComment: 'Aapke ghar mein bhi after-bath towel-race hota hai? 😂',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Bath done, Rio wraps his towel around himself like a cape and bolts out of the bathroom: "Pakad ke dikhao, Mumma!" Mumma calls after him: "Pehle kapde pehno, Rio!" — but he is already sprinting down the hallway.
Twist: Instead of chasing in frustration, Mumma turns it into a game: "Teen tak counting — jo pehle sofa tak pahunchega!" Both race down the hallway, Mumma slowing just enough near the end.
Resolution: Rio reaches the sofa first, arms up in victory: "Main jeet gaya!" Breathless and happy, he lets Mumma dress him right away, no fuss at all.
Moral: Ek chhota sa race se sabse mushkil kaam bhi asaan ho gaya — play se hi parenting kabhi kabhi sabse simple hoti hai.
''',
    setting: 'Hallway between the bathroom and living room, evening, towel still damp',
    sceneDetail: 'Rio\'s towel trailing behind him like a cape, small wet footprints on the floor',
    dialogue: '"Pakad ke dikhao, Mumma!" "Teen tak counting — jo pehle sofa tak pahunchega!"',
    mess: 'Wet footprints across the hallway floor, towel nearly slipping off mid-sprint',
    innerThought: 'If I chase him annoyed, this turns into a fight. If I race him, it turns into a memory.',
    endingBeat: 'Rio, still catching his breath, lifts his arms for Mumma to dress him — proud and cooperative.',
    defaultCast: ['Rio', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Hallway between bathroom and living room, evening. Rio, wrapped in a towel like a cape, bolts out of the bathroom: "Pakad ke dikhao, Mumma!" Mumma calls: "Pehle kapde pehno, Rio!" Text on screen: "TOWEL RACE: MUMMA VS RIO! 🏃🛁" "READY, SET, GO! 🏁"

On-Screen Text:
- [0-3s]: "BATH DONE, TOWEL CAPE ON! 🛁"
- [3-7s]: "RIO BOLTS DOWN THE HALLWAY! 🏃"
- [7-12s]: "MUMMA TURNS IT INTO A RACE! 🏁"
- [12-16s]: "RIO WINS! 🏆"
- [16-20s]: "KAPDE PEHNO, NO FUSS! 😄"

Part 1 (0-10s): 3D Pixar style, 9:16. Rio sprints down the hallway in his towel cape: "Pakad ke dikhao, Mumma!" Mumma: "Teen tak counting — jo pehle sofa tak pahunchega!" They both start running. Text: "BATH DONE, TOWEL CAPE ON! 🛁" "MUMMA TURNS IT INTO A RACE! 🏁"

Part 2 (10-20s): 3D Pixar style, 9:16. Mumma slows just enough near the end. Rio reaches the sofa first, arms up: "Main jeet gaya!" Breathless and grinning. Text: "RIO WINS! 🏆"

Audio/Dialogue (Hinglish): Rio: "Pakad ke dikhao, Mumma!" Mumma: "Teen tak counting — jo pehle sofa tak pahunchega!" Rio: "Main jeet gaya!" Mumma: "Chalo ab champion ko kapde pehnate hain."

Part 3 (20-30s): 3D Pixar style, 9:16. Rio lifts his arms up for Mumma to dress him, happy and cooperative. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Ek chhota sa race se sabse mushkil kaam bhi asaan ho gaya — play se hi parenting kabhi kabhi sabse simple hoti hai.
''',
  ),

  HookIdea(
    id: 'idea_91',
    category: 'Funny',
    cover: 'Papa Ka Makeover! 💄👨',
    title: 'Papa Ka Makeover! 💄👨',
    opening: 'Ria ne nikala apna makeup kit… aur Papa ban gaye aaj ke model!',
    problem: 'Ria loves playing makeup artist and insists on putting her toy makeup on Papa\'s face, who good-naturedly lets her.',
    lesson: 'Kabhi kabhi silly moments hi sabse pyaare memories banti hain — bachche ko lead karne dena unki confidence badhata hai.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Jab Papa ban jaaye Ria ka makeup client! 💄😂 Silly moments, sabse pyaare memories. #DaddyDaughter #MakeupArtist #FunLearningWithPalak #IndianParents #PapaLove',
    pinnedComment: 'Aapke Papa bhi aise "makeover" ke liye ready rehte hain? 😂',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria pulls out her toy makeup kit: "Papa, aaj main tumhe pretty banaungi!" Papa sits down on the floor, feigning seriousness: "Theek hai, Doctor Ria, main ready hoon."
Twist: Pink lipstick smeared past the lips, blue eyeshadow up to the eyebrows, glitter everywhere — Papa looks in the mirror and gasps dramatically: "Main toh superstar lag raha hoon!"
Resolution: Mumma walks in laughing and clicks a photo for the family album. Papa wears the "makeover" proudly the rest of the evening, even answering the door like that.
Moral: Bachcho ko silly play mein lead karne dena unki creativity aur confidence dono badhata hai — aur banata hai memories jo hamesha yaad rahengi.
''',
    setting: 'Living room floor, evening, Ria\'s toy makeup kit spread out on a towel',
    sceneDetail: 'Pink lipstick smeared past the lips, blue eyeshadow up to the eyebrows, glitter scattered on the floor',
    dialogue: '"Papa, aaj main tumhe pretty banaungi!" "Theek hai, Doctor Ria, main ready hoon."',
    mess: 'Glitter and loose powder scattered across the towel and Papa\'s shirt',
    innerThought: 'I look ridiculous — and this is the best five minutes of my day.',
    endingBeat: 'Papa answers the front door still fully "made over," making the delivery guy laugh too.',
    defaultCast: ['Ria', 'Papa', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Living room floor, evening, toy makeup kit spread on a towel. Ria kneels in front of Papa with a toy lipstick: "Papa, aaj main tumhe pretty banaungi!" Papa sits patiently: "Theek hai, Doctor Ria, main ready hoon." Text on screen: "PAPA KA MAKEOVER! 💄👨" "CLIENT: PAPA 😂"

On-Screen Text:
- [0-3s]: "RIA'S MAKEUP KIT IS OUT! 💄"
- [3-7s]: "PAPA, AAJ MAIN TUMHE PRETTY BANAUNGI! 🙋"
- [7-12s]: "LIPSTICK, EYESHADOW, GLITTER! ✨"
- [12-16s]: "SUPERSTAR LOOK COMPLETE! 🌟"
- [16-20s]: "MUMMA CAN'T STOP LAUGHING! 😂"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria carefully applies pink lipstick past Papa's lips and blue eyeshadow up to his eyebrows. Papa holds still, eyes closed, playing along. Text: "RIA'S MAKEUP KIT IS OUT! 💄" "LIPSTICK, EYESHADOW, GLITTER! ✨"

Part 2 (10-20s): 3D Pixar style, 9:16. Papa opens his eyes, looks in a hand mirror, gasps dramatically: "Main toh superstar lag raha hoon!" Mumma walks in, bursts out laughing, grabs her phone for a photo. Text: "SUPERSTAR LOOK COMPLETE! 🌟" "MUMMA CAN'T STOP LAUGHING! 😂"

Audio/Dialogue (Hinglish): Ria: "Papa, aaj main tumhe pretty banaungi!" Papa: "Theek hai, Doctor Ria, main ready hoon." Papa looking in mirror: "Main toh superstar lag raha hoon!" Mumma laughing: "Yeh toh family album mein jaayega!"

Part 3 (20-30s): 3D Pixar style, 9:16. Papa, still fully made-over, answers the front door — even the delivery guy laughs. Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Bachcho ko silly play mein lead karne dena unki creativity aur confidence dono badhata hai.
''',
  ),

  HookIdea(
    id: 'idea_92',
    category: 'Learning Lesson',
    cover: 'Fatela Pant Vs Daadi Ki Silai! 🧵',
    title: 'Fatela Pant Vs Daadi Ki Silai! 🧵',
    opening: 'Ria ka favorite pant ghutne se fat gaya… "Yeh toh kharab ho gaya!"',
    problem: 'Ria\'s favorite pants tear at the knee while playing, and she assumes they are ruined and will be thrown away.',
    lesson: 'Purani cheezein phenkne se pehle, unhe theek karne ka tareeka sochna chahiye — Daadi ki silai jaisi purani skills aaj bhi kaam aati hain.',
    postFormat: 'Reel',
    strategy: '',
    caption: 'Fatela pant = kharab pant? Nahi! Daadi ki silai ne banaya usse aur bhi special. 🧵❤️ #DaadiKiSilai #FixItDontThrowIt #IndianParents #FunLearningWithPalak #FamilySkills',
    pinnedComment: 'Kya aapke ghar mein bhi Daadi/Nani purane kapde silkar naye jaisa bana deti hain?',
    forApp: true,
    usedOn: '',
    custom: false,
    archived: false,
    storyDetail: '''
Story: Ria trips while playing and her favorite star-print pant tears at the knee. She bursts into tears: "Yeh toh kharab ho gaya, phenk do!" Mumma: "Ek minute, chalo Daadi ke paas."
Twist: Daadi pulls out her old sewing box, threads a needle with practiced hands, and patches the tear with a tiny embroidered star right over the hole: "Dekho, ab yeh aur bhi special ho gaya!"
Resolution: Ria stares at the patch, delighted: "Mera favorite pant ban gaya extra favorite!" She wears it the very next day, showing off the star patch to everyone.
Moral: Daadi ki purani silai ka hunar naye cheezon se kam nahi — kabhi kabhi repair karna, phenkne se zyada better hota hai.
''',
    setting: 'Daadi\'s room, afternoon, an old wooden sewing box with colourful threads',
    sceneDetail: 'A small torn hole at the knee of Ria\'s star-print pant, Daadi\'s needle and thread ready',
    dialogue: '"Yeh toh kharab ho gaya, phenk do!" "Dekho, ab yeh aur bhi special ho gaya!"',
    mess: 'Loose threads on the floor, Ria sniffling and holding the torn pant out to Daadi',
    innerThought: 'Everything doesn\'t need to be new to be loved — sometimes it just needs a little care.',
    endingBeat: 'Ria proudly points out her star patch to Rio and Cuty: "Daadi ne banaya, special hai!"',
    defaultCast: ['Ria', 'Daadi', 'Mumma'],
    keepMoralOffScreen: false,
    quote: '',
    detail: '',
    punchline: '',
    readyPrompt: '''
PROMPT: 3D Pixar animation style, vertical 9:16. Daadi's room, afternoon light, an old wooden sewing box with colourful threads on the table. Ria holds out her torn star-print pant, tearful: "Yeh toh kharab ho gaya, phenk do!" Daadi reaches for her sewing box. Text on screen: "FATELA PANT VS DAADI KI SILAI! 🧵" "DAADI KO DO, UDAHARAN DEKHO! 🪡"

On-Screen Text:
- [0-3s]: "RIA'S PANT TEARS AT THE KNEE! 😢"
- [3-7s]: "YEH TOH KHARAB HO GAYA! 😭"
- [7-12s]: "DAADI KI SILAI SHURU! 🪡"
- [12-16s]: "A TINY STAR PATCH! ⭐"
- [16-20s]: "EXTRA FAVORITE NOW! 💛"

Part 1 (0-10s): 3D Pixar style, 9:16. Ria shows Daadi her torn pant, upset: "Yeh toh kharab ho gaya, phenk do!" Daadi calmly opens her old sewing box and threads a needle. Text: "RIA'S PANT TEARS AT THE KNEE! 😢" "DAADI KI SILAI SHURU! 🪡"

Part 2 (10-20s): 3D Pixar style, 9:16. Daadi stitches a tiny embroidered star right over the hole: "Dekho, ab yeh aur bhi special ho gaya!" Ria's eyes widen with delight. Text: "A TINY STAR PATCH! ⭐" "EXTRA FAVORITE NOW! 💛"

Audio/Dialogue (Hinglish): Ria: "Yeh toh kharab ho gaya, phenk do!" Mumma: "Ek minute, chalo Daadi ke paas." Daadi: "Dekho, ab yeh aur bhi special ho gaya!" Ria: "Mera favorite pant ban gaya extra favorite!"

Part 3 (20-30s): 3D Pixar style, 9:16. The next day, Ria proudly shows off her star patch to Rio and Cuty: "Daadi ne banaya, special hai!" Final text overlay: LEARNING IS A HABIT, SMALL WINS BIG HEARTS. Moral: Daadi ki purani silai ka hunar naye cheezon se kam nahi — kabhi kabhi repair karna, phenkne se zyada better hota hai.
''',
  ),
];

  // Safety hooks are appended at the end.
  list.addAll(kSafetyHooks);
  return list;
}

/// Combined hooks list with safety hooks appended.
final kDefaultHooks = buildDefaultHooks();

/// Built-in hooks with all rewrites and moments applied.
/// Since [kRewrittenStories] and [kMomentUpgrades] have been merged
/// directly into [kDefaultHooks], this is now a simple alias.
final kDefaultHooksWithRewrite = kDefaultHooks;

// ── The 14-Day Post Packages ───────────────────────────────────────────────────

final kDay14Posts = <QuickIdea>[
  // ── DAY 2 ────────────────────────────────────────────────────────────────────
  QuickIdea(
    id: 'idea_93',
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
    hashtags: '#preschoolactivities #toddlerlearning #kidsbrainbooster #earlylearningindia #funlearningwithpalak',
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
    id: 'idea_94',
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
    hashtags: '#parentingmemes #toddlerlife #momsofindia #relatablemom #funlearningwithpalak',
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
    id: 'idea_95',
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
    hashtags: '#preschoolactivities #kitchenlearning #toddleractivities #earlylearning #sortingskills',
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
    id: 'idea_96',
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
    hashtags: '#talkwithyourkids #parentingtips #bedtimeroutine #toddlerconversations #funlearningwithpalak',
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
    id: 'idea_97',
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
    hashtags: '#preschoolmilestones #3yearoldactivities #toddlerdevelopment #earlylearning #parentingindia',
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
    id: 'idea_98',
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
    hashtags: '#toddlerlife #parentingmemes #momsofindia #relatablehumor #funlearningwithpalak',
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
    id: 'idea_99',
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
    hashtags: '#hiddenobject #spotthedifference #preschoolgames #observationskills #toddleractivities',
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
    id: 'idea_100',
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
    hashtags: '#laundryhacks #toddleractivities #preschoollearning #momhacks #sortingskills',
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
    id: 'idea_101',
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
    hashtags: '#talkwithyourkids #parentingtips #mindfulparenting #toddlerconversations #funlearningwithpalak',
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
    id: 'idea_102',
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
    hashtags: '#preschoolmilestones #4yearoldactivities #toddlerdevelopment #earlylearning #parentingindia',
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
    id: 'idea_103',
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
    hashtags: '#parentingmemes #toddlerdinner #relatablehumor #momsofindia #pickyeater',
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
    id: 'idea_104',
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
    hashtags: '#patternrecognition #preschoolmath #earlylearning #toddlerbrain #funlearningwithpalak',
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
    id: 'idea_105',
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
    hashtags: '#newcontent #parentingcommunity #preschoollearning #funlearningwithpalak #momsofinstagram',
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
    id: 'idea_106',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_107',
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
    id: 'idea_108',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_109',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_110',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_111',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_112',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_113',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_114',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_115',
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
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak',
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
    id: 'idea_116',
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
    hashtags: '#playbasedlearning #toddleractivities #funlearningwithpalak #noscreenactivities #montessoriathome',
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