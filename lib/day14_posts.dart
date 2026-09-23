import 'package:flutter/material.dart';
import 'quick_content.dart';

// ── Content Buckets ────────────────────────────────────────────────────────────
//
// The six content strategies for the 14-day test. Every post belongs to exactly one
// bucket, and the bucket drives which comment style, which visual approach and which
// success metric matters most.
//
// Character bible reminder for every image prompt:
//   Ria (brown eyes, warm skin tone, consistent face — outfit/hair rotates per post)
//   Rio (brown eyes, warm skin tone, consistent face — outfit/hair rotates per post)
//   Cuty (small white bunny, pink bow, unchanged always)
//   No glasses on Ria or Rio, ever.
//   Soft pastel watercolor storybook style, cream background,
//   vertical 9:16 for reels, square or 4:5 for carousel/static.

class ContentBucket {
  final String id;
  final String name;
  final String shortLabel;
  final String description;
  final Color color;
  final Color softColor;

  const ContentBucket({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.description,
    required this.color,
    required this.softColor,
  });
}

const kContentBuckets = [
  ContentBucket(
    id: 'puzzle',
    name: 'Can Your Child Figure It Out',
    shortLabel: 'Puzzle',
    description: 'Observation games, pattern challenges, spot-the-hidden',
    color: Color(0xFFE8A87C),
    softColor: Color(0xFFFDF0EB),
  ),
  ContentBucket(
    id: 'humor',
    name: 'Parent-Relatable Humor',
    shortLabel: 'Humor',
    description: 'Funny relatable parenting moments',
    color: Color(0xFFF4C2C2),
    softColor: Color(0xFFFFF0F3),
  ),
  ContentBucket(
    id: 'activity',
    name: 'Try This at Home',
    shortLabel: 'Activity',
    description: 'Hands-on activities using household items',
    color: Color(0xFFA8D8EA),
    softColor: Color(0xFFEDF7FC),
  ),
  ContentBucket(
    id: 'talk',
    name: 'Talk With Your Child',
    shortLabel: 'Talk',
    description: 'Conversation starters and bonding questions',
    color: Color(0xFFB5E2A9),
    softColor: Color(0xFFF0F7ED),
  ),
  ContentBucket(
    id: 'skill',
    name: 'Age-Based Skill Reference',
    shortLabel: 'Skill',
    description: 'Development milestone checklists',
    color: Color(0xFFD4A5E8),
    softColor: Color(0xFFF7EDFA),
  ),
  ContentBucket(
    id: 'wrap',
    name: 'Wrap-Up / Interactive',
    shortLabel: 'Wrap-Up',
    description: 'Community engagement and feedback posts',
    color: Color(0xFFF0E68C),
    softColor: Color(0xFFFFFAEC),
  ),
];

ContentBucket? bucketById(String id) {
  for (final b in kContentBuckets) {
    if (b.id == id) return b;
  }
  return null;
}

ContentBucket? bucketByName(String name) {
  for (final b in kContentBuckets) {
    if (b.name == name) return b;
  }
  return null;
}

String bucketLabel(String id) {
  final b = bucketById(id);
  return b?.shortLabel ?? id;
}

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
    bucket: 'puzzle',
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
    bucket: 'talk',
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
    bucket: 'skill',
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
    bucket: 'puzzle',
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
    bucket: 'talk',
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
    bucket: 'skill',
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
    bucket: 'puzzle',
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
    bucket: 'wrap',
    createdAt: DateTime(2026, 9, 24),
  ),
];

// ── Bulk Paste Parser ──────────────────────────────────────────────────────────
//
// A single text box where you paste a full post package, and it splits into fields.
// Format:
//   Title: ...
//   Post Type: ...
//   Audience: ...
//   Content Goal: ...
//   Mood: ...
//   Hook: ...
//   Main Idea: ...
//   Problem: ...
//   Lesson: ...
//   Visual Style: ...
//   Bucket: <bucket name>
//   CTA: ...
//
//   --- Image Prompt ---
//   <multi-line prompt>
//
//   --- Caption ---
//   <multi-line caption>
//
//   --- Hashtags ---
//   <hashtags>
//
//   --- Pinned Comment ---
//   <comment>
//
//   --- Reply Comments ---
//   1. <comment 1>
//   2. <comment 2>
//   ...
//
//   --- Script ---
//   <script text>

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
  if (lower.contains('puzzle') || lower.contains('figure') || lower.contains('hidden') || lower.contains('pattern')) return 'puzzle';
  if (lower.contains('humor') || lower.contains('funny') || lower.contains('mumma')) return 'humor';
  if (lower.contains('activity') || lower.contains('challenge') || lower.contains('hunt')) return 'activity';
  if (lower.contains('talk') || lower.contains('question') || lower.contains('ask')) return 'talk';
  if (lower.contains('skill') || lower.contains('year-old') || lower.contains('checklist')) return 'skill';
  if (lower.contains('wrap') || lower.contains('favorite') || lower.contains('feedback')) return 'wrap';
  return '';
}
