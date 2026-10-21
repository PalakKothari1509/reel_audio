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
    storyDetail: '''
Story: Daadi ke ghar ek rishtedaar uncle aate hain: "Aao Ria, god mein baitho, ek pappi do!" Ria Mumma ke peeche chhup jaati hai: "Nahi."
Twist: Uncle hanke: "Arre, ek hi toh pappi hai!" Ria ka chehra sikud jaata hai. Mumma aage aati hai, Ria ke kandhe par haath rakhke: "Ria ki marzi. Ria, tum high-five doge ya door se bye?"
Resolution: Ria high-five deti hai aur muskurati hai. Raat ko Mumma poochhti hai: "Jab koi touch achha na lage, toh tumhara tummy kya bolta hai?" Ria: "Uh-oh!" "Aur phir kya karte hain?" "Mumma ko batate hain."
Moral: Mera badan, meri marzi. Aur batana kabhi galat nahi hota.
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
    storyDetail: '''
Story: Park mein Ria jhoola jhool rahi hai. Ek aunty paas aake chocolate dikhati hain: "Ria, ye lo. Aao, udhar chalo, aur bhi hai."
Twist: Ria jhoola rokti hai. Woh jaanti hai ki Mumma ne kaha tha: "Jo hume nahi jaante, unse kuch nahi lena." Woh chocolate ko dekhti hai, phir aunty ko, phir bench par baithi Mumma ko.
Resolution: Ria zor se bolti hai: "Nahi!" aur bhaagke Mumma ke paas pahunchti hai. Mumma use godi mein uthati hai: "Shabash, Ria!" Mumma aunty ko door se dekhti hain, aur woh chali jaati hain.
Moral: Mumma ke paas bhaago. Chocolate kal bhi mil jayegi.
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
    storyDetail: '''
Story: Ghar mein Cuty "red light, green light" ka khel khilata hai: Cuty haath uthata hai toh Ria aur Rio ruk jaate hain, haath hilata hai toh daudte hain. Dono kai baar hanste hue haante hain.
Twist: Agle din sadak ke kinare Rio daudne ko hota hai... aur ek second ke liye ruk jaata hai. Woh Mumma ki taraf dekhta hai: "Red light!"
Resolution: Mumma: "Haan. Ab dekho dono taraf. Gaadi aa rahi hai?" Rio dono taraf sar ghumaata hai: "Nahi!" Mumma: "Ab green light." Dono haath pakadke chalte hain.
Moral: Khel mein seekha, sadak par kaam aaya.
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
    storyDetail: '''
Story: Mumma poochhti hai: "Ria, Mumma ka phone number kya hai?" Ria soch mein padti hai: "Ek... do... pata nahi." Rio ko bhi nahi aata.
Twist: Papa ek jaani-pehchani dhun mein number gaate hain, aur har dus ank ko do-teen ke tukdon mein todte hain. Rio hansta hai aur saath mein gaata hai. Cuty taal deta hai.
Resolution: Kuch din baad Mumma phir poochhti hai. Ria seena tanke gaane lagti hai: poora number, dhun ke saath. Mumma ki aankhein chamak jaati hain.
Moral: Number yaad hai, toh madad paas hai.
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
    storyDetail: '''
Story: Mela mein bheed hai. Ria jhoole dekhne mein rukti hai, aur jab palti hai toh Mumma ka haath nahi hai. Aas-paas sirf pair hi pair.
Twist: Ria ka dil zor se dhadakta hai aur uski aankhon mein aansu aa jaate hain. Woh bhaagne ko hoti hai... phir Mumma ki baat yaad aati hai: "Kho jao toh jahaan ho wahin ruko."
Resolution: Ria ruk jaati hai. Woh vardi pehne guard ko ya bachchon ke saath khadi mummy ko dhoondhti hai, aur unke paas jaake kehti hai: "Mera naam Ria hai. Mujhe Mumma ko dhoondhna hai." Phir woh apna gaana wala number gaati hai. Kuch hi der mein Mumma daudkar aati hain.
Moral: Ruko. Guard ya mummy ke paas jao. Apna naam batao.
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
    storyDetail: '''
Story: Mumma kadhai mein kuch tal rahi hain. Ria khilona lekar rasoi ki taraf aati hai: "Mumma, dekho!" Mumma jaldi se: "Garam! Peeche!" Ria chonk jaati hai.
Twist: Agli subah Papa farsh par laal tape se rasoi ke darwaze par ek line chipkate hain: "Ye hai Laal Line. Jab gas jalti hai, yahin tak. Aage Mumma ya Papa ke saath."
Resolution: Shaam ko Ria khilona leke line tak aati hai aur wahin rukkar bolti hai: "Mumma, main yahan hoon! Aao!" Mumma muskuraati hai aur khilona dekhne aati hai.
Moral: Line ke peeche Ria, garam cheezein Mumma ke paas.
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
    cover: 'Main Khud Karungi!',
    opening: 'Ria ne Mumma ka haath jhatak diya... joote khud pehnenge!',
    problem: 'Ria insists on putting her shoes on herself and pushes Mumma away',
    lesson: 'Thoda intezaar, aur bachcha khud seekh jaata hai',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma is getting Ria ready to leave, running late. She tries to put Ria's shoes on for her, but Ria insists on doing it herself. Ria firmly moves Mumma's hand away and struggles — the shoe goes on incorrectly and slips off.
Twist: Mumma is tempted to take over completely, but realizes that doing it for Ria will not give her a chance to practice.
Resolution: Mumma sits beside Ria instead of taking the shoe away. She turns the shoe correctly, points to where toes go, and lets Ria try again with guidance.
Moral: Children need opportunities to practise everyday skills, even when it takes longer — patience and support build confidence.
''',
  ),
  HookIdea(
    id: 'h02',
    category: 'Relatable',
    cover: 'Bas 5 Minute Aur?!',
    opening: 'Phone band hua... aur Ria ka rona shuru!',
    problem: 'Ria cries when the cartoon is cut off mid-episode.',
    lesson: 'Achanak nahi, pehle se bataakar band karo',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is watching a cartoon on a phone. Mumma tells her screen time is over and switches it off without warning. Ria immediately protests and demands "five more minutes."
Twist: Ria becomes genuinely upset — not just protesting, but really distressed by the sudden stop.
Resolution: Mumma acknowledges Ria's disappointment instead of arguing, introduces a visual timer for next time, and offers building blocks as an alternative activity. Ria gradually transitions.
Moral: Advance warnings, predictable routines, and an appealing alternative may make transitions easier.
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
Story: Rio builds a tall tower from blocks. It falls. He tries again — it falls again. On his third attempt, Rio is frustrated and declares, "I can't do it!" Ria tries to help by building the tower herself, but Rio is more upset because he wanted to succeed on his own.
Twist: Ria takes over the building, unintentionally making Rio feel worse.
Resolution: Ria stops and sits beside him. Cuty nudges a wide base block toward Rio, and Ria suggests "let's put the big blocks on the bottom." Rio rebuilds with a broad base and succeeds.
Moral: Mistakes can help children discover a different approach — support means helping them think, not doing it for them.
''',
  ),
  HookIdea(
    id: 'h04',
    category: 'Relatable',
    cover: 'Cuty Kahan Gaya?!',
    opening: 'Poore kamre mein khilone... aur Cuty gayab!',
    problem: 'Cuty is lost in the messy room; tidying turns into a treasure hunt',
    lesson: 'Saaf kamra, sab kuch saamne',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria and Rio have toys scattered all over the room. When Ria wants Cuty, she cannot find him. They search everywhere but keep getting distracted by other toys, making the room even messier.
Twist: The search creates more clutter instead of finding Cuty.
Resolution: Rio suggests clearing the floor first. They sort toys into baskets one area at a time, and finally find Cuty peacefully sleeping underneath a blanket in a cleared space.
Moral: Putting things in predictable places makes them easier to find — and tidying can be a team effort.
''',
  ),
  HookIdea(
    id: 'h05',
    category: 'Relatable',
    cover: 'Mumma Bhi Hairaan!',
    opening: 'Lights band... aur Ria ko phir se paani chahiye.',
    problem: 'Bedtime stretches on with one more water, one more story, one more hug',
    lesson: 'Roz ek jaisa routine, neend jaldi aati hai',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma has finished Ria's bedtime routine — story read, lights dimmed, Ria tucked in. But Ria keeps asking for more: water, another hug, teddy moved closer. Mumma is patient but exhausted.
Twist: The same requests repeat every night, and Mumma realizes she can prepare for the usual needs in advance.
Resolution: The next evening, Mumma and Ria create a bedtime checklist — water placed, teddy chosen, hug given, story read. Ria participates and the routine feels calmer. The final request becomes a happy "good night!" instead of another demand.
Moral: Predictable routines may reduce repeated requests and help children know what comes next.
''',
  ),
  HookIdea(
    id: 'h06',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria and Rio both want to sit in the driver's seat of the toy car—"Mera pehle, mera pehle!"
Twist: They start pushing each other, and the car almost falls over—Cuty tries to squeeze in too.
Resolution: Mumma says, "Ek minute Ria, ek minute Rio"—they take turns, and the car is happy too.
Moral: Sharing means everyone gets their turn—and the fun lasts longer.
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
Story: Ria hides under the blanket to avoid brushing her teeth—"Nahi! Mujhe brush karne ka maza nahi aata!"
Twist: Papa starts singing a funny tooth-brushing song, and Rio copies him with a silly dance.
Resolution: Ria joins in laughing, and before she knows it, her teeth are clean and sparkling.
Moral: Turning routines into play makes even stubborn tasks feel like fun.
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
Story: Ria pushes the broccoli on her plate away—"Broccoli? Bilkul nahi!"
Twist: Mumma says, "Broccoli ke bhi best friends hote hain"—she makes a silly face with the broccoli.
Resolution: Ria giggles and tries a tiny bite—then asks for more with a big smile.
Moral: A little creativity on the plate can turn a stubborn "no" into a happy "yes."
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
Story: Ria wants to wear mismatched winter boots in summer—"Mummy, yeh hi pasand hai!"
Twist: Mumma lets her try, but after 2 minutes Ria says, "Thandi lag rahi hain!"
Resolution: They compromise—"Boots ghar mein, jootey bahar"—and Ria happily agrees.
Moral: Small choices give big confidence—even if the boots don't last all day.
''',
    cover: 'Apne Kapde Khud!',
    opening: 'Garmi mein bhi Ria ko winter boots hi pehenne hain!',
    problem: 'Ria wants to choose her own mismatched outfit',
    lesson: 'Chhote faisle, bada confidence',
  ),

  // New built-in content ideas from Palak's marketing and character plan.
  HookIdea(
    id: 'pal01',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: At the park, Ria races straight to the swings and starts pumping—"Mere saath koi nahi sahi!"
Twist: Rio copies her but keeps falling off—"Main bhi kar sakta hoon!"—while Cuty sits quietly watching a ladybug.
Resolution: Mumma points—"Ria tez, Rio mazak, Cuty dhyan"—and realises her three are right there in their own style.
Moral: Tumhara bachcha kaunse character jaisa hai?
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
Story: Ria says "no" to broccoli, wants the same spoon every time, and suddenly needs Mumma—all in one morning.
Twist: Mumma realizes each behavior is a tiny adventure—"Maine socha, maine maan liya, maine kar liya!"
Resolution: Ria turns her 7 behaviors into a "Very Busy Day" song that makes the whole family laugh.
Moral: Toddler behaviors aren't chaos—they're curiosity in motion.
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
Story: Ria wants to wear her princess dress to the grocery store—"Mummy, main princess banungi!"
Twist: Mumma says no, Ria's face falls—"Par mujhe bahut pasand hai!"
Resolution: Mumma offers a deal—"Jab ghar aayenge, toh princess dress pehn lo"—Ria agrees with a smile.
Moral: Not all "no"s are endings—sometimes they're "not now" in disguise.
''',
    cover: 'When Mumma Says No',
    opening: 'Ria protests, Rio refuses, Cuty quietly gives in.',
    problem: 'The same parent boundary can trigger three very different reactions',
    lesson: 'Kids react differently, but all of them need patience and clarity',
  ),
  HookIdea(
    id: 'pal04',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is playing and doesn't want to stop—"Bas 5 minute aur!"
Twist: Papa sets a timer—"5 minute hai, phir cleanup time."
Resolution: Ria cleans up exactly when the timer dings—"Maine kiya!"—and gets a hug.
Moral: A countdown is better than a command—kids can own their transitions.
''',
    cover: '5 Minute Warning!',
    opening: 'Five minutes left and suddenly every child hears a different story.',
    problem: 'Screen time transitions create a dramatic meltdown in most homes',
    lesson: 'Warning helps, but a gentle transition still matters most',
  ),
  HookIdea(
    id: 'pal05',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: It's bedtime, and Ria says—"Maine kaha tha na Mummy, maine kaha tha!"—then suddenly mumbles and her head nods.
Twist: Rio whispers—"Cuty bhi aise hi so jaati hai!"—but Cuty is wide awake, humming.
Resolution: Mumma tiptoes in, Ria is asleep with the book still open—"Theek hai beta, sweet dreams."
Moral: Jab tak nahi so jata, tab tak sunate rehna padta hai.
''',
    cover: 'Things Kids Say',
    opening: 'Mumma, I am not sleepy and then five seconds later, snores.',
    problem: 'Kids say the funniest things right before bedtime and during chaos',
    lesson: 'A little laughter makes the hard moments easier to handle',
  ),
  HookIdea(
    id: 'pal06',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is a "Sunshine Sprinter," Rio is a "Sleepy Cuddlebug," Cuty is a "Quiet Observer."
Twist: Mumma tries to rush them all the same way—"Jaldi utho, jaldi khao!"
Resolution: When Mumma adapts to each child's rhythm—"Ria, your energy! Rio, slow and steady! Cuty, take your time!"—everyone is ready.
Moral: Morning is not a race—meeting each child where they are saves everyone stress.
''',
    cover: 'Morning Personalities',
    opening: 'Ria wakes up ready to play, Rio wants five more minutes, and Cuty is still sleeping.',
    problem: 'Morning energy can look very different across siblings and personalities',
    lesson: 'The family routine works better when personalities are respected',
  ),
  HookIdea(
    id: 'pal07',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is ready in 2 minutes—"Maine sab kuch kar liya!"—but Rio forgot his shoes and Cuty is still in pajamas.
Twist: Ria helps Rio find shoes and reminds Cuty—"Chalo, hum sab milkar nikalenge."
Resolution: They leave the house together, Ria holding both hands—"Team complete!"
Moral: Being ready means helping others who aren't—and that makes you a leader.
''',
    cover: 'Ready to Go?',
    opening: 'One child is ready, one is searching for a toy, and one is still half asleep.',
    problem: 'Leaving the house is a daily family-level circus',
    lesson: 'A little planning makes the morning calmer for everyone',
  ),
  HookIdea(
    id: 'pal08',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Something is missing—"Mumma, Ria ki pink bottle kahan hai?"—toys everywhere and Cuty has "borrowed" them.
Twist: Mumma and Ria retrace the day—"Pehle yahan tha, phir wahan."
Resolution: They find the bottle under the couch—"Haan! Cuty ne chhupayi thi!"—and Ria beams with pride.
Moral: Every little detective deserves a magnifying glass—and a hug when they solve the case.
''',
    cover: "Mumma's Little Detective",
    opening: 'Who did it? Toys everywhere, crumbs on the floor, and one very innocent rabbit.',
    problem: 'Kids create chaos and then deny it with talent',
    lesson: 'The grown-up always knows, even when they try to act innocent',
  ),
  HookIdea(
    id: 'pal09',
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria insists on putting on her own shoes—"Main khud karungi!"—but the shoes are on the wrong feet.
Twist: Papa fake-thinks about it—"Kya pata chal gaya ki yeh galat side pe hain?"
Resolution: Ria tries again, gets them right, and runs out—"Dekho, sahi hai!"—and Papa cheers.
Moral: Doing things yourself is worth the struggle—even if they're backwards first.
''',
    cover: 'Main Khud Karungi',
    opening: 'Let me do it myself and I will do it my way.',
    problem: 'Kids want independence even when the task is small',
    lesson: 'Support effort and trust them to learn through trying',
  ),
  HookIdea(
    id: 'pal10',
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Cuty suddenly says, "Mumma, tumne mujhe kal chocolate diya tha!"—referring to an event from 3 weeks ago.
Twist: Ria adds, "Aur mujhe Saturday ko extra stories padhne wale!"
Resolution: Mumma realizes kids remember the small moments—"Haan, maine tumhe suna tha."
Moral: Children store up tiny kindness like treasures—you never know what they'll recall.
''',
    cover: 'Little Things Kids Remember',
    opening: 'The bedtime story, the silly dance, the hug after a bad day.',
    problem: 'Parents often forget that tiny everyday moments become the memories children hold',
    lesson: 'Love is built in the little, repeated moments of the day',
  ),
  HookIdea(
    id: 'pal11',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: At the supermarket, Ria wants everything in sight—"Mummy, yeh lelo!"—Rio grabs the toy, and Cuty just wants to go home.
Twist: Mumma gives each one a task—"Ria, pick one treat. Rio, find the cereal. Cuty, carry the list."
Resolution: The kids focus on their missions and forget the chaos—"Hamari shopping team badi achhi hai!"
Moral: Engaging kids in a role turns shopping into teamwork.
''',
    cover: 'At The Supermarket',
    opening: 'Ria wants everything, Rio wants the toy, Cuty is already ready to go home.',
    problem: 'Shopping turns into a mini-lesson in patience, negotiation and excitement',
    lesson: 'Every child brings a different energy into the same space',
  ),
  HookIdea(
    id: 'pal12',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria wants one more story—"Ek aur, Mummy!"—Rio keeps asking for water—"Paani chaiye!"—and Cuty just crawls into bed.
Twist: Mumma does one round: story, then water for Rio, then tuck Cuty in, then back to Ria.
Resolution: Ria finally says—"Theek hai, abhi so jaoongi"—and Rio snores on his pillow.
Moral: Jo bhi order ho, sabse pehle pyar hi chahiye.
''',
    cover: 'Bedtime Personalities',
    opening: 'One child wants one more story, one wants one more screen, one is already asleep.',
    problem: 'Bedtime is always different inside the same house',
    lesson: 'Night routines work best when they match the child who is in them',
  ),
  HookIdea(
    id: 'pal13',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria's toy car has a broken wheel—"Nahi! Yeh toot gaya!"
Twist: Papa takes it—"Kuchh fixing ki koshish kartey hain"—he tries superglue.
Resolution: The car doesn't drive perfectly, but Ria says—"Ab yeh toh special car ban gayi!"—and pushes it with pride.
Moral: Broken things don't lose their magic—just gain a new kind of charm.
''',
    cover: 'Toy Broke!',
    opening: 'The toy breaks, everyone reacts differently, and then they learn together.',
    problem: 'Small losses feel huge when a child is attached to a favourite thing',
    lesson: 'A bad moment can become a calm lesson if we slow down and help',
  ),
  HookIdea(
    id: 'pal14',
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is crying over a torn drawing—"MERI drawing phaa gaya!"
Twist: Mumma kneels down—"Yeh paper toh gaya, lekin tumhara rishta kabhi nahi jayega."
Resolution: They make a new drawing together—"Nayi shuruaat!"—and Ria's tears turn to giggles.
Moral: Big feelings over small things are real—and they deserve big love to match.
''',
    cover: 'Big Feelings, Little Problems',
    opening: 'To a child, a broken biscuit or a missing sock feels enormous.',
    problem: 'Little problems can feel huge when your child is overwhelmed',
    lesson: 'What seems small to us is often a big emotion to them',
  ),
  HookIdea(
    id: 'pal15',
    category: 'Surprising',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria wants to set her own house rules—"Mummy, main banaungi rule!"—she declares "No vegetables" and "24-hour dessert."
Twist: Papa fake-thinks about it—"Kya pata chal gaya ki yeh kaam nahi karega?"
Resolution: They negotiate—"Sabse pehle vegetables, phir dessert"—and Ria agrees with a high-five.
Moral: Letting kids set their own rules teaches them to think before they demand.
''',
    cover: "Ria's House Rules",
    opening: "Ria's five rules for fun, chaos and completely valid family drama.",
    problem: 'Kids often create their own rules and logic in the middle of daily life',
    lesson: 'Playful routines and family humour keep the home feeling lighter',
  ),
  HookIdea(
    id: 'pal16',
    category: 'Surprising',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio's vocabulary for the day is just "BALL!"—and he says it 47 times.
Twist: Everyone echoes "ball"—"Haan, ball!"—and Cuty gets confused—"Toh kya ball sabse achcha hai?"
Resolution: They count all the balls in the house—"1, 2, 3, 4... ball hi ball!"—and Rio is satisfied.
Moral: One word can fill a whole day with fun—when you lean into it together.
''',
    cover: "Rio's Vocabulary",
    opening: "Rio's top words are no, mine, why, and one more time.",
    problem: 'The toddler vocabulary is often very short but very intense',
    lesson: 'A little repetition and a lot of parenting grace go a long way',
  ),
  HookIdea(
    id: 'pal17',
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Cuty is quietly watching everyone—"Sab log kuchh kar rahe hain, par main kyunkar?"
Twist: When Ria falls down, Cuty toddles over first—"Chaliye, main madad karungi!"
Resolution: Cuty's quiet observation helps Ria feel better—"Cuty ne toh samajh liya!"—and Mumma smiles.
Moral: The quietest voice often speaks the loudest truth.
''',
    cover: 'Cuty Knows Best',
    opening: 'Cuty believes in naps, calm, and never rushing through life.',
    problem: 'Some children are highly sensitive to noise, pressure and movement',
    lesson: 'Rest and calm are not lazy; they are part of healthy growth',
  ),
  HookIdea(
    id: 'pal18',
    category: 'Relatable',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria, Rio, and Cuty are all getting ready at the same time—"Mujhe brush karna hai, mujhe shoes pana hai, mujhe breakfast chahiye!"
Twist: Mumma is running in three directions—"Thoda sa, thoda sa, thoda sa!"
Resolution: They line up—"Ek ek karke"—and by the time Cuty is dressed, Ria is eating and Rio has shoes.
Moral: Three kids, one mom—one line, one by one, makes everyone happy.
''',
    cover: 'One House, Three Kids',
    opening: 'Same house, different universes: Ria, Rio and Cuty all live in their own rhythm.',
    problem: 'Each child has a different personality, energy level and way of reacting',
    lesson: 'Family life works when we learn to love the differences, not fight them',
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
    category: 'Warm lesson',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Cuty is asleep on the couch, and Mumma thinks—"Abhi bhi mere saath hai." But Ria is taller now—"Mummy, maine apni chaddi khud pehni!"
Resolution: Mumma wraps her arms around both—"Tumhe pyar karti hoon, har pal ka."
Ending line: "Thoda sa waqt jyada pad raha, par yehi toh haim."
''',
    cover: 'Parent Memory',
    opening: "One day they won't ask you to carry them, and they won't need the same little routines.",
    problem: 'Parents need a reminder to value the current chaos before it changes',
    lesson: 'Enjoy the little moments while they are still happening',
  ),

  // Struggle first: open on the moment it goes wrong.
  HookIdea(
    id: 'h10',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio spills paint everywhere by accident—"Arre, badi galti ho gayi!"
Twist: Mumma hands him a napkin—"Chhote bachcho ki badi badi galtiyan sabse achhi hoti hain."
Resolution: Together they clean up, and Rio learns how easy it is to fix small messes.
Moral: Mistakes happen—but cleaning up together makes them less scary.
''',
    cover: '1 Galti, Bada Mess!',
    opening: 'Rio ke haath se saare rang gir gaye...',
    problem: 'Rio spills paint everywhere by accident',
    lesson: 'Galti pe gussa nahi, saath mein saaf karo',
  ),
  HookIdea(
    id: 'h11',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio builds a tall block tower—"Dekho, kitni badi hai!"—then Ria accidentally knocks it down.
Twist: Rio's face crumples, but Cuty hands him a block—"Phir se banayenge na?"
Resolution: They rebuild together, making it even taller this time—with Rio, Ria, and Cuty each adding a floor.
Moral: What falls down can always be built back up—especially when friends help.
''',
    cover: 'Tower Gir Gaya!',
    opening: 'Rio zameen pe lot gaya... sirf blocks ke liye?',
    problem: 'Rio has a big tantrum when his tower breaks',
    lesson: 'Pehle gale lagao, phir samjhao',
  ),
  HookIdea(
    id: 'h12',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Morning is chaotic—Ria wants her blue dress, Rio lost his favorite toy, Cuty won't brush.
Twist: Mumma takes a deep breath—"Ek minute sabko, chai peene ka time."
Resolution: One by one, they get ready, and by the time Mumma sips her chai, everyone is smiling.
Moral: A calm minute in the morning saves a hundred rushed minutes later.
''',
    cover: 'Subah Ka Drama',
    opening: 'School ka time... aur Ria abhi tak bistar mein!',
    problem: 'Morning school prep turns into a battle',
    lesson: 'Jaldbaazi kam, zidd bhi kam',
  ),
  HookIdea(
    id: 'h13',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is deep in her drawing—"Mummy, main painting kar rahi hoon!"—and ignores Mumma calling her for lunch.
Twist: Mumma sits beside her and quietly adds a dot to the painting—"Ek nayi star hai tumhari painting mein."
Resolution: Ria looks up and smiles—"Mummy bhi artist ban gayi!"—and follows her to lunch hand in hand.
Moral: Sometimes quiet presence is louder than loud reminders.
''',
    cover: 'Suno Na, Ria!',
    opening: 'Mumma teesri baar bulaa rahi hain... Ria sun hi nahi rahi.',
    problem: 'Ria ignores instructions called from across the room',
    lesson: 'Paas jaakar, aankhon mein dekhkar bolo',
  ),
  HookIdea(
    id: 'h14',
    category: 'Struggle first',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria and Rio both grab the same toy car—"Mera pehle!"—and in the tug-of-war it snaps in half.
Twist: Both stare at the broken pieces—"Mera car toota!"—"Mera bhi toota!"
Resolution: Rio holds out one half—"Tum lo,"—and Ria says, "Nahi, dono milke banayenge."
Ending line: Ria: "Dekho, do car bhi toh do car ban gaye!"
Moral: Toote cheez pe gussa nahi, saath mein kaise theek karein.
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
Story: Mumma is on the phone, and Ria keeps tugging her dupatta—"Mummy, phone dikhao!"
Twist: Mumma puts the phone down—"Abhi nahi, Ria ke saath baitho"—but Ria grabs her own toy phone.
Resolution: They play "phone" together—Ria answers her toy—"Hello, Mummy ke saath baitho!"
Ending line: Ria into toy phone: "Hello? Haan, abhi mil rahi hoon."
Moral: Dhyaan toh do, phone khud hi wapas aayega.
''',
    cover: 'Phone Asli Problem Nahi',
    opening: 'Ria ko phone se nahi, phone chhinne se gussa aata hai.',
    problem: 'The upset is about the sudden stop, not the screen itself',
    lesson: 'Timer lagao, badlaav aasaan ho jaata hai',
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
Story: Ria begs to play in the rain—"Mummy, bahaar khelo!"
Twist: Mumma says no—"Abhi nahi, baad mein"—Ria thinks Mumma is being mean.
Resolution: Later, Mumma shows her the rain boots—"Ab khelo, yeh paani pakadne ke liye!"
Moral: Sometimes "no" means "wait"—the answer often comes with preparation.
''',
    cover: 'Mumma Ne NO Kyun Bola?',
    opening: 'Baarish mein bahar jaana tha... Mumma ne mana kar diya!',
    problem: 'Ria thinks Mumma is mean for saying no to playing in the rain',
    lesson: 'NO ka matlab kabhi nahi — kabhi kabhi bas ruko',
  ),
  HookIdea(
    id: 'h18',
    category: 'Surprising',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria shows off her drawing—"Mummy, maine khud banaya!"
Twist: Mumma notices the crayon is broken—"Tumhe pata hai, yeh bhi toot gaya."
Resolution: Ria says, "Par maine khud kiya!"—and Mumma realizes effort matters more than perfection.
Moral: Praise the doing, not just the done—process builds confidence.
''',
    cover: 'Tumne Khud Kiya!',
    opening: 'Ria ko "good girl" nahi... kuch aur sunna tha.',
    problem: 'Praising the effort instead of calling the child good',
    lesson: 'Mehnat ki taareef, himmat badhaati hai',
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
Story: Ria watches Mumma struggle with the grocery bags—"Mummy, thak gayi ho?"
Twist: Ria brings her tiny stool—"Mummy, baith jao, main saaf karti hoon."
Resolution: They sit together—"Tum toh meri help karo gi!"—and the floor is clean in minutes.
Moral: Children teach us as much as we teach them—sometimes they see our weariness first.
''',
    cover: 'Ria Ne Samjhaaya!',
    opening: 'Aaj Ria ne Mumma ko ek baat sikha di...',
    problem: 'A small child says something that makes the adult rethink',
    lesson: 'Bachche humse zyada samajhte hain',
  ),

  // Milestone posts: complete concepts for the 100th Instagram post.
  HookIdea(
    id: 'p05',
    category: 'Page & milestone',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria, Rio, and Cuty discover the 100th post card on the wall—"Dekho, humara 100th post!"
Twist: Ria claims she made it—"Maine banaya!"—Rio says NO—"Nahi, maine kaha tha!"—and Cuty is sleeping on the camera.
Resolution: Mumma shows them a slideshow of all 100 posts, ending with all three of them at the center—"Tum log hi toh hain hamari duniya."
Moral: Every post is a team effort—stories, learning, masti, and everyday childhood all grown from one small idea.
''',
    cover: '100 Posts. One World.',
    opening: '100 posts. ❤️ But who are we? Ria jumps in, Rio says NO, and Cuty is sleeping.',
    problem: 'A new visitor should understand Fun Learning With Palak, the three characters, and the page world in one reel',
    lesson: 'Little stories, learning, masti and everyday childhood can grow into one warm little world',
    postFormat: 'Reel / Trial Reel',
    strategy: 'Milestone + brand introduction + character introduction + discovery. Use a 25-35 second reel with Ria, Rio and Cuty, then test two hooks as Trial Reels: 100 POSTS ❤️ and Meet Our Little World 👀.',
    caption: '100 posts. ❤️\n\nWhat started as little ideas slowly became our little world — Ria, Rio, Cuty and so many tiny stories, laughs and lessons. 🌸💙🐰\n\nThank you for being here.\n\nLittle Stories. Big Lessons. 🌱\n\nAre you Team Ria, Team Rio or Team Cuty? 👇',
    pinnedComment: 'Okay, important question 😂👇\n🌸 Ria = Tofani\n💙 Rio = Ziddi\n🐰 Cuty = Sleep Lover\nWhich one is most like your little one?',
  ),
  HookIdea(
    id: 'p06',
    category: 'Page & milestone',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma opens a time-lapse video—"100 posts pehle yehi soch rahi thi..." showing one empty wall where Ria's first drawing was taped.
Twist: Rio points at the screen—"Woh toh sirf ek drawing thi!" and Cuty toddles over to see—"Ab toh bohot saari hain!"
Resolution: The video ends with all three characters waving at the camera—"From one idea to our little world. ❤️"
Moral: One small idea can grow into a little family and a community that learns together.
''',
    cover: '100 Posts Ago...',
    opening: '100 posts ago, there was no big world — just one little idea and one little character.',
    problem: 'The page journey and its characters need an emotional introduction for new visitors',
    lesson: 'One small idea can grow into a little family and a community that learns together',
    postFormat: 'Reel / Emotional milestone',
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
Story: Ria, Rio, and Cuty are excited about Post 100—"Mere saath photo lelo, maine banaya hai!"
Twist: Each one claims they made it—Ria says she did, Rio says NO, Cuty is sleeping through it.
Resolution: The final card reveals "POST #100" with all three of them—"Hum logon ne milkar banaya!"
Moral: Milestones are team achievements—even the sleeping teammate deserves credit.
''',
    cover: 'Who Made Post 100?',
    opening: 'Ria says she made Post 100. Rio says NO. Cuty says wake me up at Post 200.',
    problem: 'A milestone announcement can feel too formal unless the characters make it funny and memorable',
    lesson: "Ria\'s masti, Rio's zidd and Cuty's neend are what make this little world special",
    postFormat: 'Funny Reel / Trial Reel',
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
Story: Ria, Rio, and Cuty give a tour of their house—"Yeh meri room, yeh rhi Rio ki, yeh Cuty ka play zone!"
Twist: Each room has a special memory—"Yahan pe Ria ne pehli baar bike ki," "Yahan pe Rio ne pehli baar painting banayi."
Resolution: The tour ends in the family room—"Yeh sab hamara hai, aur ham sab milke isse banaenge stories."
Moral: Your little world is the biggest world—when you live inside it with love.
''',
    cover: 'Meet Our Little World',
    opening: 'Meet Ria, Rio and Cuty — one is Tofani, one is Ziddi, and one just wants to sleep.',
    problem: 'New followers need a simple pinned introduction to the characters and the page promise',
    lesson: 'Together they make Fun Learning With Palak: cute preschool stories, learning, laughter and little lessons',
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
    cover: '1,000 Ke Paas!',
    opening: 'Ruko... hum 1,000 dost hone wale hain?!',
    problem: 'Milestone reel as you approach 1,000 followers',
    lesson: 'Thank the parents who came first',
  ),
  HookIdea(
    id: 'p02',
    category: 'Page & milestone',
    forApp: false,
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
    category: 'Navratri',
    cover: 'Navratri mein Bachche Ghar Kaise Laayein?',
    opening: 'Garba shuru hua, masti shuru ho gayi... lekin bachcha ghar jaane se mana kar raha hai!',
    problem: 'Toddler refuses to leave the Garba after the party is over',
    lesson: 'Suddenly stop nahi—pehle se batao, phir goodbye karo',
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
    category: 'Navratri',
    cover: 'Garba Par Bachcha Rota Hai?',
    opening: 'Sab Garba kar rahe the... lekin mera bachcha sirf ro raha tha!',
    problem: 'Loud music, crowd, or lights overwhelm a toddler at a Garba event',
    lesson: 'Har bachche ka festival enjoy karne ka apna tareeka hota hai',
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
    category: 'Navratri',
    cover: 'Garba Jaate Waqt Junk Food Ka Kya Karein?',
    opening: 'Garba jaane ka time aaya... par bachcha sirf chips maang raha hai!',
    problem: 'Toddler wants chips and sweets instead of healthy dinner',
    lesson: 'Thodi si planning, aur outing mein kam tension',
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
    category: 'Navratri',
    cover: 'Late-Night Garba Vs Sleep!',
    opening: 'Raat ko Garba chal raha tha... aur bachcha cranky hone laga!',
    problem: 'Toddler gets sleepy and cranky at a late-night Garba event',
    lesson: 'Har raat late tak rukna zaroori nahi. Happy memories chhoti outing mein bhi banti hain',
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
Story: Ria is excited to wear her new Navratri lehenga, but as soon as the heavy dupatta touches her shoulders, she starts fussing — "Nikal do, nikal do!"
Twist: Mumma tries to distract her with the mirror and bangles, but the tight waistband makes it worse — "Mumma yeh dard hai!"
Resolution: Mumma swaps the heavy dupatta for a light organza one and lets Ria help pick comfortable jhumkas — suddenly Ria is twirling and smiling.
Moral: Comfort before style — when kids feel good, they shine.
''',
  ),
  HookIdea(
    id: 'navratri-no-partner',
    category: 'Navratri',
    cover: 'Chhote Bachchon Ko Garba Mein Kaise Include Karein?',
    opening: 'Bade log Garba kar rahe the... par chhota bachcha bola "mujhe bhi aana hai!"',
    problem: 'Toddler wants to dance but cannot follow the steps or keep up',
    lesson: 'Steps simple rakho, participation special banao',
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
    category: 'Navratri',
    cover: 'Crowded Garba Mein Toddler Safety Ka Kya Karein?',
    opening: 'Garba mein bheed bahut thi... aur bachcha darr kar seham gaya!',
    problem: 'Crowded Garba spaces lead to sensory overload and accidental bumps',
    lesson: 'Festival ka maza tabhi hai, jab bachcha safe aur relax ho',
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
    category: 'Navratri',
    cover: 'Garba Mein Phone Ke Bina Toddler Busy?',
    opening: 'Event shuru hua... par bachcha aate hi phone maangne laga!',
    problem: 'Toddler gets bored at adult events and demands the smartphone',
    lesson: 'Bachche ko sirf mana mat karo, engaging options bhi do',
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
Story: Mumma is decorating the house for Navratri, but Ria keeps interrupting—"Mere saath khelo, Mummy!"
Twist: Mumma hands Ria a small basket—"Tum bhi Maa ki helper ho, phool lagao!"—Ria takes it seriously.
Resolution: Ria carefully places marigolds around the space, proud of her contribution—"Mainne madad ki!"
Moral: Invitations beat interruptions—when kids feel helpful, they don't need to compete for attention.
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
    opening: 'Ria plate mein khana rakhti thi, par jab Mumma ne dekha toh plate zameen par gir gayi.',
    problem: 'Ria plate mein khana rakhti thi, par jab Mumma ne dekha toh plate zameen par gir gayi.',
    lesson: 'Saath milkar kaam karo toh koi bhi problem aasani se hal ho jati hai.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Ria places her plate with care on the dining table, but as she steps back, her foot catches the edge of a rug. The plate tilts — then crashes to the floor in slow motion.
Twist: Before Mumma can react, Rio rushes in and bumps the table reaching for the same plate.
Resolution: Mumma kneels down calmly and says, "It's okay, beta. We clean it together."
Moral: Saath milkar kaam karo toh koi bhi problem aasani se hal ho jati hai.
''',
  ),
  HookIdea(
    id: 'shoe-bandhani',
    category: 'Relatable',
    cover: 'Shoe Bandhani',
    opening: 'Rio ne apni jootiyein pehli baar khud pehnne ki koshish ki, lekin dono jooti ek doosre se juite hue the.',
    problem: 'Rio ne apni jootiyein pehli baar khud pehnne ki koshish ki, lekin dono jooti ek doosre se juite hue the.',
    lesson: 'Jab saab milkar jooti jod lein, toh koi bhi single joota alag nahi lagta.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Rio squats by the shoe rack, holding one sneaker in each hand. They are tangled together — left and right, laces crossed. He tugs, they don't separate.
Twist: Ria tries to help by grabbing the other end, but now both shoes are tangled around both their hands.
Resolution: Mumma gently untangles them in two minutes — "Ek joota tumhara, doosra tumhara."
Moral: Jab saab milkar jooti jod lein, toh koi bhi single joota alag nahi lagta.
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
    category: 'Relatable',
    cover: 'Vegetable Drama',
    opening: 'Rio ne kaha — "Gobhi nahi khaoonga!" — jab Mumma ne gobhi rakhi.',
    problem: 'Rio ne kaha — "Gobhi nahi khaoonga!" — jab Mumma ne gobhi rakhi.',
    lesson: 'Jab koi bhi cheez thoda maza aa jata hai, tabhi toh woh khayi jati hai.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Mumma places a plate of gobhi on the dining table. Rio pushes it away dramatically — "Gobhi nahi khaoonga!"
Twist: Ria sees the protest and joins in — "Yeh Mummy ke saath nahi khayenge!" Cuty even backs away.
Resolution: Mumma names the gobhi "Bachcha" and "Rider" — suddenly both want to try.
Moral: Jab koi bhi cheez thoda maza aa jata hai, tabhi toh woh khayi jati hai.
''',
  ),
  HookIdea(
    id: 'brushing-battle',
    category: 'Relatable',
    cover: 'Brushing Battle',
    opening: 'Ria ne brush pakda, par turant se poochh li — "Mujhe brush nahi karna!"',
    problem: 'Ria ne brush pakda, par turant se poochh li — "Mujhe brush nahi karna!"',
    lesson: 'Jab koi aur dikhaye gaal, toh brush bhi khelke lag jata hai.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Ria grabs her toothbrush but immediately protests — "Mujhe brush nahi karna!" She drops it in the sink.
Twist: Rio says "Main karenge, main toh bada hoon!" but he just swirls the brush in water — no paste.
Resolution: Cuty picks up the brush and trots between them — both siblings start brushing, giggling.
Moral: Jab koi aur dikhaye gaal, toh brush bhi khelke lag jata hai.
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
    opening: 'A bright snack box sat just out of reach on the low kitchen counter ledge.',
    problem: 'A bright snack box sat just out of reach on the low kitchen counter ledge, and Ria stretched on tiptoes trying to grab it.',
    lesson: 'When you lift each other up, even high shelves become easy.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
PART 1: Ria stretches on tiptoes to grab a snack box on the low kitchen counter, but her tiptoes barely reach halfway.
Twist: Rio watches from behind — he wants a snack too, but neither can reach alone.
Resolution: Rio steps up behind Ria, placing his hands firmly on her waist to steady her — together they grab the snack.
Moral: When you lift each other up, even high shelves become easy.
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
    caption: 'Ghar mein 2 minute ki shanti... DANGER! 😱 Jab bachche bilkul silent ho jaate hain, toh bura haal hota hai. Watched the full video to see what Cuty was up to! #toddlermeltdown #indianparents #funlearningwithpalak',
    pinnedComment: 'Tip: The silence is always louder than the chaos that came before. Check on them! 🐰',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mummy heard two minutes of dead silence from the toddlers — a sound so suspicious it sent her tiptoeing toward the kitchen hallway on high alert.
Twist: She found Ria and Rio sitting cross-legged in a massive cloud of spilled wheat flour, treating the floor like their own personal canvas.
Resolution: Mummy crossed her arms, suppressing a smile, as Cuty hopped in with a tiny dustpan — "Theek hai na Mama?"
Moral: The most suspicious silences always end with something creative to clean up.
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
    caption: 'School van neeche aa gayi... aur ek joota gayab! 🚐 Joota kho gaya, par kahaan gaya? Full video dekho. #morningrush #toddlerlife #funlearningwithpalak #indianparents',
    pinnedComment: 'Tip: Always check the balcony curtains — shoes love to hide there! 👟',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: School van was honking downstairs at 7:55 AM, but one shoe had vanished into another dimension.
Twist: The house-wide search operation comically failed — Mummy checked the fridge crisper, Papa crawled under the sofa, and Cuty had curled up inside the shoe taking a peaceful nap.
Resolution: With seconds to spare, Rio gently lifted Cuty out, slipped his foot into the shoe, and dashed toward the door as the bell rang.
Moral: Sometimes the things we lose are just having their own adventure.
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
    caption: 'Biscuit toota matlab duniya khatam! 🍪😭 Doctor Rio ne banaya jugaad repair, par Cuty ne bhi ek nibble liya! #toddlerlogic #biscuitcrisis #funlearningwithpalak',
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
    cover: 'Robot, Mumma Has Lost Her Mind!',
    opening: 'Robot, mujhe lagta hai Mumma ka dimaag kho gaya!',
    problem: 'Mumma cannot find her phone while it is already in her hand.',
    lesson: 'The robot literally scanned every room and handed the phone back, helping Mumma realise she was holding it all along.',
    postFormat: 'Reel',
    strategy: 'AI comedy misunderstanding, family situation, physical comedy payoff',
    caption: 'Jab Mumma ka phone haath mein hai lekin woh kho dhundh rahi hai... aur Robot ne phone wapas dedi! 😂 Har mummy ko yehi dekhna chahiye. #RiaAndRobot #IndianMomLife #FunLearningWithPalak',
    pinnedComment: 'We all need a personal robot who tells us the truth — and hands back our phone from our own hand! 🤖',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma frantically pats her pockets, checks every surface, asks everyone — her phone is lost. But she is holding it in her hand the whole time.
Twist: Ria calls the robot for help. The robot takes her request literally: "Mumma has lost her mind — scanning for lost objects in the vicinity."  It starts waving sensors and scanning Mumma's head.
Resolution: The robot\'s scanner beeps and points at Mumma's own hand — the phone was there the entire time.  Mumma laughs at the absurdity.
Moral: Sometimes the simplest solution is right in front of you — and a robot\'s logic can remind you.
''',
  ),
  HookIdea(
    id: 'robot-02',
    category: 'Series',
    cover: 'My Tummy Doesn\'t Like Palak!',
    opening: 'Robot, meri tummy ko palak bilkul pasand nahi!',
    problem: 'A child rejects dinner before even trying it, pushing the plate away.',
    lesson: 'The robot suggested a tiny bite first, and Ria discovered palak was actually yummy with a little cheese.',
    postFormat: 'Reel',
    strategy: 'Food refusal humor, gentle parenting lesson',
    caption: 'Palak se pehle ek bite, aur suddenly "Mumma, aur thoda dena!" 😂 Har meal time fight ka asan hal. #RiaAndRobot #ToddlerMeals #FunLearningWithPalak',
    pinnedComment: 'The robot was right — one tiny bite can change everything! 👶',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria pushes her dinner plate away, declaring her tummy hates palak and refusing to even try it.
Twist: The robot interprets "tummy doesn't like palak" as a medical emergency and starts a gentle diagnostic routine — checking temperature, offering a tiny spoon.
Resolution: After one small bite with cheese, Ria grins and asks for more — "Mumma, palak actually tasty hai!"
Moral: Sometimes you have to try before you decide you don't like something.
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
    caption: 'Jab bhaiya ne toy kharab kar diya, toh Robot ne diya heart bandage! ❤️ Sibling love, properly patched. #RiaAndRobot #SiblingLove #FunLearningWithPalak',
    pinnedComment: 'Every broken heart needs a robot and a heart-shaped bandage. ❤️🩹',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio accidentally breaks Ria\'s favorite toy, and Ria is devastated, declaring her heart is broken.
Twist: The robot takes "broken heart" literally and produces a large adhesive bandage shaped like a heart, applying it to Ria\'s chest.
Resolution: Seeing the silly bandage, both kids laugh, Rio apologises, and they repair the toy together with the robot\'s help.
Moral: A little humor and teamwork can mend both toys and feelings.
''',
  ),
  HookIdea(
    id: 'robot-04',
    category: 'Series',
    cover: 'Make My Mess Disappear!',
    opening: 'Robot, meri room ki mess gayab kar do!',
    problem: 'Ria wants a clean room instantly without doing any cleanup herself.',
    lesson: 'The robot started tidying, but Ria joined in and realized cleanup can be fun with a dance playlist.',
    postFormat: 'Reel',
    strategy: 'Chore avoidance comedy, collaborative cleanup dance',
    caption: 'Mess gayab karne ke liye ek robot nahi… ek dance playlist aur Ria milake hi chahiye! 💃🧹 #RiaAndRobot #CleanUpDance #FunLearningWithPalak',
    pinnedComment: 'The robot may start, but Ria finishing makes it a win! 10/10 teamwork.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria demands the robot make her room\'s mess disappear instantly, refusing to lift a finger.
Twist: The robot starts tidying up efficiently, but Ria realises she is still standing there.  She tries to avoid cleaning by hiding behind the robot.
Resolution: The robot puts on a cheery song and starts dancing while tidying — Ria joins in, and soon both are cleaning to the beat.
Moral: Work feels lighter when you do it together — even if a robot started the dance.
''',
  ),
  HookIdea(
    id: 'robot-05',
    category: 'Series',
    cover: 'Give Me a Break!',
    opening: 'Robot, mujhe bas ek break chahiye!',
    problem: 'Ria feels overwhelmed by too many instructions and needs space to breathe.',
    lesson: 'The robot suggested a 5-minute quiet corner with breathing cards that helped Ria reset.',
    postFormat: 'Reel',
    strategy: 'Overstimulation handling, emotional regulation, breathing exercise',
    caption: 'Jab sabse zindagi mein bahut kuchh ho raha hai... toh ek robot breathing cards ke saath madad karta hai! 🧘‍♀️ #RiaAndRobot #EmotionalRegulation #FunLearningWithPalak',
    pinnedComment: 'Five minutes of quiet, a breathing card, and Ria was back to her playful self. 💙',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Overloaded by multiple instructions from adults, Ria throws her hands up and demands "just one break."
Twist: The robot interprets it as a request for scheduled downtime and creates a mini "quiet pod" with breathing cards and a timer.
Resolution: After five minutes of calm breathing in the quiet corner, Ria returns to her activities refreshed and able to focus.
Moral: Everyone needs a break — and a robot can help create the right moment to reset.
''',
  ),
  HookIdea(
    id: 'robot-06',
    category: 'Series',
    cover: 'I Want to Sleep Like a Baby!',
    opening: 'Robot, mujhe baby ki tarah sona hai!',
    problem: 'Ria uses the idiom "sleep like a baby" expecting peaceful rest.',
    lesson: 'The robot misunderstood and brought a baby monitor, a rattler, and scheduled 2 AM "baby feeding" checks.',
    postFormat: 'Reel',
    strategy: 'Idiom misunderstanding, baby paraphernalia comedy',
    caption: 'Jab "sleep like a baby" ka matlab pata nahi hota... toh robot leke aata hai baby monitor! 🤖🍼 #RiaAndRobot #IdiomFail #FunLearningWithPalak',
    pinnedComment: 'Pro tip: never say "sleep like a baby" to a robot that takes everything literally!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria says "I want to sleep like a baby!" expecting peaceful, deep sleep.
Twist: The robot takes it literally and brings a baby monitor, rattler, and a feeding schedule — it starts checking on her every two hours "for the baby routine."
Resolution: Ria clarifies she means sleeping peacefully, and the robot sets up a cozy nest with soft music instead.
Moral: Words matter — especially when a robot is listening!
''',
  ),
  HookIdea(
    id: 'robot-07',
    category: 'Series',
    cover: 'Rio Is Driving Me Crazy!',
    opening: 'Robot, Rio mujhe crazy kar raha hai!',
    problem: 'Rio constantly copies everything Ria does, driving her slightly mad.',
    lesson: 'The robot suggested a "me time" station and a "Rio time" station so both get individual play space.',
    postFormat: 'Reel',
    strategy: 'Sibling mimicry, parallel play setup, individual attention',
    caption: 'Rio har baat copy karta hai, toh Robot ne banaya "me time" aur "Rio time" stations! ✨ #RiaAndRobot #SiblingDynamics #FunLearningWithPalak',
    pinnedComment: 'A me-station and a Rio-station — problem solved! Everyone gets their own space. 😍',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Rio relentlessly copies everything Ria does — her poses, her words, her drawing style — and Ria reaches her limit.
Twist: The robot sets up two parallel stations labeled "Ria Time" and "Rio Time" to give each child individual play space.
Resolution: Ria discovers that Rio copying her can also mean copying her creativity, and they start a collaborative game instead.
Moral: A little space helps, but shared creativity can turn copying into collaboration.
''',
  ),
  HookIdea(
    id: 'robot-08',
    category: 'Series',
    cover: 'Mumma Said Keep Your Shoes On!',
    opening: 'Robot, sab mujhe jaldi-jaldi kyun bolte hain?',
    problem: 'Everyone is rushing to leave, but Ria insists on putting her shoes on herself, causing delays.',
    lesson: 'The robot suggested a shoe timer game — if Ria puts shoes on in 2 minutes, they get to choose the car song.',
    postFormat: 'Reel',
    strategy: 'Independence conflict, shoe timer game, family car song choice',
    caption: 'Jaldi-jaldi ka time, par Ria apne joote khud pehengi! Robot ne banaya shoe timer game. ⏰👟 #RiaAndRobot #ShoeRace #FunLearningWithPalak',
    pinnedComment: 'Two minutes to put on shoes = choosing the car song. Ria always wins! 😂',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Everyone is ready to leave except Ria, who insists on putting her shoes on herself — and taking forever to do it.
Twist: The robot turns it into a game: "If you put your shoes on in two minutes, you choose the car song."  Ria agrees.
Resolution: Racing against the timer, Ria gets her shoes on just as the doorbell rings — and gets to pick the song.
Moral: A little game can turn a rush into fun — and independence into teamwork.
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
    caption: 'Jab "kharab" drawing Robot ke saamne magic ban gayi! ✨ Har art perfect hota hai. #RiaAndRobot #ArtConfidence #FunLearningWithPalak',
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
    category: 'Series',
    cover: 'Catch My Feelings!',
    opening: 'Robot, main pehle happy thi... ab gussa aa raha hai!',
    problem: 'Ria\'s block tower falls down and she suddenly feels angry, confused, and sad.',
    lesson: 'The robot taught Ria the "feelings weather" method to name and process changing emotions.',
    postFormat: 'Reel',
    strategy: 'Emotional literacy, feelings weather chart, tower rebuilt together',
    caption: 'Block tower gir gaya, feelings badal liye... lekin Robot ne sikhaaya feelings weather! 🌦️ #RiaAndRobot #FeelingsFirst #FunLearningWithPalak',
    pinnedComment: 'Feelings are like weather — they change. But tower can always be rebuilt. ❤️',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria watches her carefully built block tower collapse and instantly feels happy \u2192 angry \u2192 sad all in five seconds.
Twist: The robot shows a "feelings weather" chart and explains that emotions change like the weather — it\'s normal.
Resolution: Ria identifies "stormy mad" then "sunny calm," and together they rebuild an even taller tower.
Moral: Feelings come and go — what matters is learning to name them and keep building.
''',
  ),
  HookIdea(
    id: 'robot-11',
    category: 'Series',
    cover: 'My Hands Are Full!',
    opening: 'Robot, mere haath bahut full hai!',
    problem: 'Ria is juggling too many items and needs help carrying them all at once.',
    lesson: 'The robot demonstrated the "one trip at a time" method so Ria could carry things efficiently.',
    postFormat: 'Reel',
    strategy: 'Task overload, efficient carrying method, priority sorting',
    caption: 'Jab haath itne full ho jaye ki kuchh girne wala hai... Robot ne sikhaaya efficient method! 💪 #RiaAndRobot #LittleHelper #FunLearningWithPalak',
    pinnedComment: 'One trip at a time — the robot\'s golden rule for busy little hands. ✨',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria tries to carry snacks, toys, and a book all at once — her hands are completely full and things start to fall.
Twist: The robot takes everything literally and produces an absurdly large pocket dimension bag, overwhelming her further.
Resolution: The robot simplifies: "One trip at a time." It helps Ria sort items by priority and carry them in batches.
Moral: Sometimes doing less at once means getting more done.
''',
  ),
  HookIdea(
    id: 'robot-12',
    category: 'Series',
    cover: 'Mumma Has Eyes in the Back of Her Head!',
    opening: 'Robot, Mumma ke saamne wala dimaag bhi dekhti hai!',
    problem: 'Ria is caught doing something she shouldn\'t because Mumma "always knows."',
    lesson: 'The robot explained the science of peripheral vision and how parents develop super-senses for their children.',
    postFormat: 'Reel',
    strategy: 'Parental sixth sense, peripheral vision science, playful acknowledgment',
    caption: 'Robot ne bataya science: "Mumma ke aankhon mein 360 degree vision hoti hai!" 🔄👀 #RiaAndRobot #ParentSuperpower #FunLearningWithPalak',
    pinnedComment: 'It\'s not magic — it\'s parental peripheral vision. We see EVERYTHING. 😉',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria tries to sneak a cookie but Mumma catches her instantly — "How did you see that?!"
Twist: The robot scans Mumma and displays "Parental Super-Senses v2.0 — Peripheral Vision: ACTIVE" on its screen.
Resolution: The robot explains how parents develop 360-degree awareness for their children, and Ria laughs instead of protests.
Moral: Parents may not have literal eyes in the back of their heads — but their love sees everything.
''',
  ),
  HookIdea(
    id: 'robot-13',
    category: 'Series',
    cover: 'I Need Some Space!',
    opening: 'Robot, mujhe thoda space chahiye!',
    problem: 'Ria feels crowded by siblings or adults and needs breathing room.',
    lesson: 'The robot suggested a physical "space bubble" marked with tape on the floor for quiet time.',
    postFormat: 'Reel',
    strategy: 'Personal boundaries, calm-down space, respectful communication',
    caption: 'Jab thoda space chahiye ho... toh Robot banata hai "calm-down tent"! 🏕️ #RiaAndRobot #Boundaries #FunLearningWithPalak',
    pinnedComment: 'Respecting "I need space" makes everyone calmer — kids and adults alike.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria feels overwhelmed by too many people crowding her — siblings, adults, even Cuty — and demands space.
Twist: The robot interprets this literally and draws a large chalk circle on the floor: "One-person zone activated."
Resolution: Everyone waits their turn to enter the space, and Ria emerges refreshed, understanding that asking for space is healthy.
Moral: Needing space is normal — and respecting it helps everyone.
''',
  ),
  HookIdea(
    id: 'robot-14',
    category: 'Series',
    cover: 'Rio Stole My Thunder!',
    opening: 'Robot, Rio ne mera thunder chura liya!',
    problem: 'Ria had planned a special moment, but Rio accidentally or intentionally upstaged her.',
    lesson: 'The robot helped Ria rehearse her "big moment" so she could shine even with an interruption.',
    postFormat: 'Reel',
    strategy: 'Sibling competition, sharing spotlight, confidence building',
    caption: 'Jab bhaiya ne steal kar diya tha your thunder... toh Robot ne diya confidence booster! ⚡ #RiaAndRobot #BigSister #FunLearningWithPalak',
    pinnedComment: 'Ria\'s moment was still magical — and Rio learned to be a supportive big brother.',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria had planned to show her dance routine at the family gathering, but Rio runs in singing the same song first.
Twist: The robot helps Ria turn it into a duet — "Two stars shine brighter than one."
Resolution: Ria performs with Rio, and they both get applause for being amazing teammates.
Moral: Someone else\'s spotlight doesn\'t dim yours — it can even make yours brighter.
''',
  ),
  HookIdea(
    id: 'robot-15',
    category: 'Series',
    cover: 'My Brain Is Not Working!',
    opening: 'Robot, meri soch toh bandh ho gayi!',
    problem: 'Ria is frustrated she can\'t solve a puzzle or remember something she knows.',
    lesson: 'The robot suggested a "brain reboot" — five minutes of movement, water, and a fresh start.',
    postFormat: 'Reel',
    strategy: 'Cognitive fatigue, brain reboot method, growth mindset',
    caption: 'Jab dil bhi soch raha hai ki soch bandh ho gayi... toh Robot ka "brain reboot" chalega! 🧠✨ #RiaAndRobot #BrainBreak #FunLearningWithPalak',
    pinnedComment: 'Movement + water + reset = brain works again. The robot knows best! 💧',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria is stuck on a puzzle — she knows the answer but her brain "says stop." She declares, "Meri soch bandh ho gayi!"
Twist: The robot literally scans her head and shows a "Brain Busy" warning, then suggests a "brain reboot" protocol.
Resolution: After five minutes of jumping, drinking water, and a fresh start, Ria solves the puzzle with a grin.
Moral: Sometimes your brain needs a break — not a forced push.
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
    caption: 'Jab "butterflies" ke matlab excitement hota hai, na ki darr... toh Robot ne samjhaana mushkil nahi! 🦋 #RiaAndRobot #Courage #FunLearningWithPalak',
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
    opening: 'Robot, sirhara pa gaya!',
    problem: 'Ria has finished all her activities and declares nothing is left to do.',
    lesson: 'The robot suggested the "boredom jar" — a list of simple activities she can pick from.',
    postFormat: 'Reel',
    strategy: 'Boredom productivity, creativity prompts, activity jar system',
    caption: 'Sirhara pa gaya, Robot ne banaya "boredom jar"! Har ghoont mein naya activity. 🎨 #RiaAndRobot #BoredomHack #FunLearningWithPalak',
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
    category: 'Series',
    cover: 'Mumma Is on Cloud Nine!',
    opening: 'Robot, Mumma badi khush hai... jaise koi clouds pile ho rahe hain!',
    problem: 'Mumma is beaming with happiness after receiving good news, and Ria wants to understand her joy.',
    lesson: 'The robot showed Ria a visual "happiness cloud" that matched Mumma\'s mood and how joy multiplies.',
    postFormat: 'Reel',
    strategy: 'Emotional contagion, happiness visualization, parent-child bonding',
    caption: 'Jab Mumma khush hai, toh Ria ke saath bhi clouds pile ho jaate hain! ☁️☁️ #RiaAndRobot #HappyFamily #FunLearningWithPalak',
    pinnedComment: 'Joy is contagious — when Mumma smiles, the whole family floats. ❤️',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Mumma comes home glowing with happiness from good news, and Ria asks the robot why Mumma looks like she\'s on "cloud nine."
Twist: The robot projects a visual happiness cloud above Mumma, showing how her positive energy spreads.
Resolution: Ria joins the cloud, and both laugh as the robot measures "Family Joy: 150% capacity."
Moral: Happiness shared is happiness multiplied.
''',
  ),
  HookIdea(
    id: 'robot-19',
    category: 'Series',
    cover: 'Rio Has a Big Mouth!',
    opening: 'Robot, Rio ne meri baat sabko bata di!',
    problem: 'Rio blurts out something private that Ria whispered in confidence.',
    lesson: 'The robot helped Ria explain her boundaries to Rio using a "secret vs surprise" chart.',
    postFormat: 'Reel',
    strategy: 'Privacy boundaries, secret vs surprise, sibling communication',
    caption: 'Jab Rio ne secret sabko bata diya... toh Robot ne banaya "secret vs surprise" chart! 🔐 #RiaAndRobot #Boundaries #FunLearningWithPalak',
    pinnedComment: 'Secrets stay with you, surprises are meant to share — Ria learned the difference!',
    forApp: true,
    usedOn: '',
    storyDetail: '''
Story: Ria whispers a secret to the robot, but Rio overhears and tells everyone — "Ria ne kaha ki Mumma ko surprise gift chahiye!"
Twist: The robot creates a "Secret vs Surprise" chart explaining that secrets are private, but surprises are meant to share.
Resolution: Rio understands the difference and promises to be a "secret keeper," earning Ria\'s forgiveness.
Moral: Words have power — choose to protect or share wisely.
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
    caption: 'Poori duniya khana hai? Robot ne banaya "world foods adventure map!" Har din ek naya desh. 🌍 #RiaAndRobot #WorldFoods #FunLearningWithPalak',
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
Story: Bus ka samay ho raha hai, Mumma jhukkar Ria ke joote pehnane lagti hai. Ria haath jhatak deti hai: "Main khud karungi!" Joota ulte pairon lag jaata hai, Ria pengun ban kar chalti hai.
Twist: Mumma apni taraf se joota theek karni ka mashwara deti hai, par Ria kehti hai: "Mumma, ye ulta hai?"
Resolution: Ria joote badalta hai, saahi se bandh jaata hai. Bus ka horn bajta hai. Ria khadi hoti hai, haath jod kar: "Dekho!"
Moral: Paanch second ruk jao, baaki Ria kar legi.
''',
  'h02': '''
Story: Cartoon band hone ka waqt. Mumma: "Phone band." Ria: "Bas paanch minute!" Ria royi, lekin asli dikat yeh nahi ki phone band ho raha tha — episode beech mein toot gaya tha.
Twist: Agle din Mumma pehle puchhti: "Ye episode kab khatam hoga?" Ek visual timer lagati hai.
Resolution: Episode khatam hota hai, Ria khud kehti hai "Khatam!" aur phone Mumma ko deti hai. "Kal timer pehle lagayege.
Moral: Beech mein nahi, khatam hone par — par pehle se batana bhi badi baat hai.
''',
  'h03': '''
Story: Rio ka tower teesri baar girta hai. Woh blocks se haath kash karke bolta hai: "Mujhe nahi aata!"
Twist: Ria turant madad karne aati hai, lekin Rio uska haath hata deta hai: "Main karunga!" Ria samajh jaati hai ki madad karne ka matlab haath chhune se nahi, sochne se hai.
Resolution: Ria chupchaap do bade blocks Rio ke paas rakhti hai: "Neece rakho, base bana ke dekho." Rio tower khada kar deta hai. "Dekho, khada hai!"
Moral: Hint do, haath mat lagao — bachcha khud hi seekh jaata hai.
''',
  'h04': '''
Story: Ria ne Cuty dhundhna hai, lekin khilone pooray kamre mein phail gaye hain. Har cheez dekhkar Ria distract ho jaati hai.
Twist: Rio kehti hai, "Hum Cuty dhoondh rahe hain ya aur toys bana rahe hain?" Dono dusre toys ko bhi dekhkar mushkil seprate karte hain.
Resolution: Ek chhote area ko saaf karte hain, toys ko baskets mein daalte hain. Cuty blanked ko neeche patti ke andar sone wala pata hai.
Moral: Ek chhota area, ek basket — saaf kamra, sab kuch saamne.
''',
  'h05': '''
Story: Lights band hone ke baad, Ria ne phir se paani maanga. Fir teddy ko adjust kiya. Fir ek aur hugg chahiye.
Twist: Mumma samajh jaati hai ki ye har raat dobara hota hai. Agli raat woh ek chhota bedtime checklist banati hai — paani, teddy, story, hug.
Resolution: Ria checklist ko khud tick karti hai. "Ab sab ready. Good night, Mumma!" Cuty pehle se hi sone wala hai.
Moral: Jo roz maanga jaata hai, pehle se rakh do — ek chhota routine, ek calmer bedtime.
''',
  'h07': '''
Story: Ria kambal ke andar chhup gayi hai: "Brush nahi karungi!" Mumma ke haath mein brush hai.
Twist: Mumma kambal ko haath nahi lagati. Woh Cuty ko uthake kehti hai: "Cuty ke daant bahut gande hain. Ria, tum saaf karogi?"
Resolution: Ria kambal se sar nikalti hai, chhota brush leti hai, aur Cuty ke daat saaf karti hai. Phir kehti hai: "Ab meri baari."
Moral: Pehle Cuty, phir Ria.
''',
  'h08': '''
Story: Plate mein broccoli. Ria haath baandhke baithi hai. Mumma kuch nahi bolti.
Twist: Papa ek broccoli uthake bolta hai: "Ye chhota ped hai. Main giant hoon." Woh "gap" karke kha leta hai. Ria hasne lagti hai.
Resolution: Ria ek chhota ped uthati hai, thoda kutarti hai, chehra banati hai… chabati hai. "Theek hai." Mumma kuch nahi kehti, bas plate mein ek aur rakh deti hai.
Moral: Ek bite bhi jeet hai.
''',
  'h12': '''
Story: Saat bajke das minute. Ria abhi tak kambal mein hai. Mumma teen baar utha chuki hai.
Twist: Mumma kehti hai: "Theek hai, main bhi so jaati hoon." Woh Ria ke bagal mein let jaati hai aur aankhein band kar leti hai. Ria ek aankh kholti hai: "Mumma, uthho! School late ho jayega!"
Resolution: Ria Mumma ko kheench kar uthati hai. Dono das minute mein ready ho jaate hain.
Moral: Kabhi kabhi role badal do.
''',
  'h13': '''
Story: Ria zameen par drawing bana rahi hai. Mumma rasoi se bulati hai: "Khana!" Phir: "Ria, khana!" Teesri baar awaaz oonchi hoti hai. Ria ko kuch sunai hi nahi deta.
Twist: Mumma aati hai, ghutnon par baithti hai, aur dheere se kehti hai: "Ria." Ria turant sar uthati hai.
Resolution: Mumma: "Khana ready hai. Drawing yahin rahegi, promise." Ria: "Kitni der?" "Paanch minute." Ria uthke chal padti hai.
Moral: Paas jaake bolo, chillao mat.
''',
  'h16': '''
Story: Papa ke liye couver aaya hai. Rio ka naya robot toy bhi aaya hai. Rio robot ko dekhta bhi nahi aur khaali dabbe mein ghus jaata hai.
Twist: Papa dabba uthaane aate hain: "Ye kabaad mein jayega." Rio: "Ye mera rocket hai!"
Resolution: Papa robot ko dabbe mein bitha dete hain: "Ye astronaut hai." Dono ulti ginti karte hain: "5, 4, 3, 2, 1… chalo!"
Moral: Dabba hi kaafi hai.
''',
  'h17': '''
Story: Khidki ke paas Ria: "Mumma, baarish mein khelna hai!" Mumma: "Abhi nahi, bijli chamak rahi hai." Ria: "Toh bijli ko bolo band ho jaye!"
Twist: Mumma: "Bijli mere kehne se nahi ruki." Ria khidki par udaas chehra banati hai. Peeth karke baithi, par har gadgadahat par chaunk jaati hai aur dikhayi nahi deti ki nahi chaunki.
Resolution: Bijli ruk jaati hai. Mumma: "Boots lao." Ria ulte pairon mein boots pehenke daudti hai. Dono puddle mein kudte hain: "Ek, do, teen… kood!"
Moral: Bijli ne sun li, boots se nahi.
''',
  'h19': '''
Story: Parking mein Mumma: "Rio, mat bhaago!" Rio aur tez bhaagta hai.
Twist: Mumma daud ke pakadti hai aur ab alag bolti hai: "Rio, meri ungli pakdo." Rio ruk jaata hai: "Kyun?"
Resolution: "Gaadi aati hai. Ungli pakdo, hum dono saath cross karenge." Rio ungli kaske pakad leta hai. Dono dhire dhire chalte hain.
Moral: "Mat" nahi, "ungli pakdo".
''',
  'pal03': '''
Story: Mumma: "Aaj chocolate nahi." Ria: "Kyun nahi?!" Rio zameen par baith jaata hai, haath baandhke: "Mujhe chahiye!" Cuty dono ko dekta hai.
Twist: Mumma fridge kholti hai: "Aaj do choice: kela ya seb." Ria aur Rio kela aur seb par ladne lagte hain.
Resolution: Cuty chupchaap Mumma ke paas jaata hai, gajar uthata hai aur kutarne lagta hai. Dono bachche dekhte rehte hain aur phir jaldi se apna fal utha lete hain.
Moral: Do option do, teen nahi.
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
    visualStyle: 'Bright cartoon reel style, soft 3D Pixar aesthetic, cream background, vertical 9:16',
    imagePrompt: 'Soft 3D Disney/Pixar-style render, cream background, vertical 9:16. Scene 1: Ria barefoot holding shoes, "Coming!" speech bubble, 5 min later still barefoot. Scene 2: Rio shrugging, water bottle beside him. Scene 3: Ria and Rio sprinting past, Cuty asleep. Scene 4: Both with angry faces, Cuty still asleep. Scene 5: Parent searching, "COME HERE!" text. No glasses on Ria and Rio.',
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
    visualStyle: 'Soft 3D Pixar/Disney style, warm cozy cream kitchen setting',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream kitchen countertop background, five spoons of varying sizes arranged playfully, a small illustrated child\'s hand reaching toward them, warm cozy lighting, minimal text, square format.',
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
    visualStyle: 'Cozy, soft evening lighting, warm Pixar aesthetic',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream bedroom background, warm evening lighting. Ria (pigtails with pink bows, pink star dress) sitting on her bed hugging Cuty the white bunny, a small thought bubble above Cuty\'s head with a question mark. Rio (blue-grey t-shirt) peeking in from the doorway curiously. No glasses, no text inside image, gentle cozy mood, square format.',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background. Ria and Rio standing together pointing at a floating checklist icon relevant to each slide, Cuty sitting nearby. Clean, warm, reassuring tone, no glasses, minimal text inside image, square format.',
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
    visualStyle: 'Bold, bright, meme-style text overlays, vertical 9:16',
    imagePrompt: 'Bold bright meme-style reel, soft 3D Pixar animation, cream background, vertical 9:16. Scene 1: "1 biscuit = hungry" — Rio holding one biscuit, neutral face. Scene 2: "2 biscuits = still hungry" — same neutral face. Scene 3: "3 biscuits = \'MUMMA, MORE!\'" — dramatic happy face, arms outstretched. Scene 4: Cuty unimpressed, nibbling one carrot. No glasses.',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render illustrated garden scene, cream and green tones, flowers, bushes, small toys scattered around. Cuty the small white bunny cleverly tucked partially behind a bush or flower pot with only ears and pink bow peeking out. Ria and Rio standing to the side looking around playfully, no glasses, square format, minimal text inside image.',
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
    visualStyle: 'Cozy home laundry scene, bright sock colors, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream laundry room background, vertical 9:16. Scene 1: Pile of mismatched colorful socks on floor, Ria and Rio diving in curiously. Scene 2: Rio holds two socks of different colors, shakes head "no match." Scene 3: Ria finds matching pair, holds triumphantly. Scene 4: Montage of pairs stacking, Cuty sitting on finished pile. No glasses on Ria and Rio.',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, warm evening lighting. Ria and Rio sitting together on the floor in conversation, Cuty curled nearby, gentle cozy family mood, no glasses, minimal text inside image, square format.',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background. Rio and Ria standing together pointing at a floating icon relevant to each slide, Cuty sitting nearby. Clean, warm, reassuring tone, no glasses, square format.',
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
    visualStyle: 'Three-panel meme layout, bright and simple, soft 3D Pixar render',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, three-panel layout on cream background, dinner table setting. Panel 1: Ria poking curiously at a plate of food, questioning expression. Panel 2: Rio with arms crossed, refusing his plate, stubborn expression. Panel 3: Cuty the white bunny calmly and happily eating a carrot from a small bowl. No glasses, clean simple outlines, minimal text inside image, square format.',
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
    visualStyle: 'Bold, simple shapes, clean animation-style reveal, vertical 9:16',
    imagePrompt: 'Bold simple animation-style reel, soft 3D Pixar style, cream background, vertical 9:16. Yellow and blue circles appear in sequence: 🟡🔵🟡🔵. Then a large question mark where the next circle should go. Ria taps her chin, thinking. Yellow circle slides into place, Ria claps, Cuty hops happily. No glasses.',
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
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, small icon representing the bucket theme (puzzle piece / speech bubble / house / laughing face / checklist), Ria, Rio, or Cuty featured lightly in the corner depending on tile, clean minimal design, square format.',
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
    visualStyle: 'Consistent characters, home setting with pillow hurdle and taped line, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) and Rio (brown eyes, warm skin tone, no glasses) in a home hallway/living room. Scene: Rio jumping over a pillow "hurdle" made from cushions, Ria walking a taped line on floor, Cuty the white bunny (pink bow) cheering from the side. Bright morning light, energetic movement captured in soft 3D Pixar render style.',
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
    visualStyle: 'Consistent characters, home setting with wooden spoon mic and steel plate drums, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) singing into a wooden spoon microphone, Rio (brown eyes, warm skin tone, no glasses) clapping and dancing, Cuty the white bunny (pink bow) tapping a steel plate like a drum. Kitchen utensils as instruments visible. Joyful musical chaos, warm family energy.',
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
    visualStyle: 'Consistent characters, home art corner with paper, slate, chalk, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) drawing a big yellow sun on paper, Rio (brown eyes, warm skin tone, no glasses) writing his name on a slate with chalk, Cuty the white bunny (pink bow) watching curiously. Kitchen chalk drawing on floor visible. Cozy creative atmosphere, warm light.',
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
    visualStyle: 'Consistent characters, home setting with cardboard tube binoculars or cupped hands, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) looking through cardboard tube binoculars, Rio (brown eyes, warm skin tone, no glasses) with cupped hands around eyes, Cuty the white bunny (pink bow) with a magnifying glass. A "clue" (toy footprint) on floor. Playful mystery mood.',
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
    visualStyle: 'Consistent characters, home setting with laundry basket and dupatta rope, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) pushing a laundry basket with toys inside, Rio (brown eyes, warm skin tone, no glasses) pulling a dupatta rope attached to the basket, Cuty the white bunny (pink bow) riding in the basket. Heavy work play, teamwork energy, warm home setting.',
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
    visualStyle: 'Consistent characters, home setting with tiffin box or any box with lid, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) opening a tiffin box to find a small toy, Rio (brown eyes, warm skin tone, no glasses) closing the box carefully, Cuty the white bunny (pink bow) being tucked into a blanket nearby. Cozy bedtime transition energy.',
    caption: 'Mission 7: Treasure Box! 🎁 Open, find, close, tuck in — fine motor + nurturing play with any box. What treasure did you hide? 🎁 #FunLearningWithPalak',
    cta: 'What treasure did you hide? 🎁',
    hashtags: '#noscreenactivities #playbasedlearning #montessoriathome #toddleractivities #funlearningwithpalak #indianmoms #ahmedabadmoms #2yearoldactivities #3yearoldactivities #finemotor #objectpermanence',
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
    lesson: 'Daily Care builds independence, body awareness, and healthy habits. The 5-second wait: child struggles, parent waits about 5 seconds, child tries, parent helps only when needed, child completes the task.',
    visualStyle: 'Consistent characters, home bathroom/kitchen setting, vertical 9:16',
    imagePrompt: 'Soft 3D Pixar/Disney-style render, cream background, vertical 9:16 reel format. Ria (brown eyes, warm skin tone, no glasses) eating apple slices from her tiffin, Rio (brown eyes, warm skin tone, no glasses) drinking from his water bottle, both brushing teeth side by side, Cuty the white bunny (pink bow) watching from the counter. Cozy bathroom/kitchen routine atmosphere.',
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
    script: 'Scene 1: "Mission 8: Self-Care Squad! 🍎"\nScene 2: Ria eats apple from tiffin — "Crunch!"\nScene 3: Rio drinks water — "Glug glug"\nScene 4: Ria struggles to brush — Mumma waits 5 seconds — Ria tries — Mumma helps only when needed — "Scrub scrub"\nScene 5: Cuty watches from counter 🐰\nScene 6: "Hardest routine at your house? 🍎"',
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