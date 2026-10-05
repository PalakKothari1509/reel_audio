import 'dart:async';
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_provider.dart';
import 'brand_system.dart';
import 'content_generator.dart';
import 'regenerator.dart';

class GeminiClient implements AIProvider {
  // This client talks to Gemini through the google_generative_ai package rather
  // than through geminiPost, so it gets none of that helper's model fallback and
  // 404 handling. The name therefore has to be one this key can actually serve.
  // It was 'gemini-1.5-flash', which no longer resolves; the rest of the app
  // already uses the name below, so both paths now ask for the same model.
  static const String _modelName = 'gemini-3.6-flash';
  static const int _maxOutputTokens = 8192;
  static const double _temperature = 0.7;
  static const Duration _timeout = Duration(seconds: 45);

  final GenerativeModel _model;
  final String _apiKey;

  GeminiClient({required String apiKey})
      : _apiKey = apiKey,
        _model = GenerativeModel(
          model: _modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: _temperature,
            topP: 0.9,
            topK: 40,
            maxOutputTokens: _maxOutputTokens,
            responseMimeType: 'application/json',
            responseSchema: _contentPackageSchema(),
            // `thinkingConfig` is deliberately absent. The `google_generative_ai` SDK
            // has no such parameter, which is why the reasoning cap could only ever be
            // applied to the hand-built JSON call sites and never here.
            //
            // That leaves this the one large generation call that can still spend
            // budget thinking and return truncated JSON. Fixing it means dropping the
            // SDK for a hand-built request, or moving off a deprecated package — both
            // are T-26, not a one-line change.
          ),
          systemInstruction: Content.system(_systemPrompt()),
        );

  @override
  String get providerName => 'Gemini 3.6 Flash';

  @override
  bool get isAvailable => _apiKey.isNotEmpty;

  @override
  Future<void> testConnection() async {
    final response = await _model.generateContent([Content.text('Test connection - reply with "OK"')]).timeout(_timeout);
    if (response.text?.contains('OK') != true) {
      throw Exception('Connection test failed: unexpected response');
    }
  }

  @override
  Future<ContentPackage> generate(IdeaInput input) async {
    final prompt = _buildGeneratePrompt(input);
    final response = await _model.generateContent([Content.text(prompt)]).timeout(_timeout);
    return _parseResponse(response.text ?? '{}', input);
  }

  @override
  Future<ContentPackage> regenerate(ContentPackage pkg, RegenerateTarget target, RegenerateStyle style) async {
    final prompt = _buildRegeneratePrompt(pkg, target, style);
    final response = await _model.generateContent([Content.text(prompt)]).timeout(_timeout);
    return _parseResponse(response.text ?? '{}', IdeaInput(
      topic: pkg.idea,
      bucket: pkg.bucket,
      targetFormats: [pkg.format],
      brand: BrandContext.defaultContext(),
      characters: pkg.characters,
      slideCount: pkg.slideCount,
    ));
  }

  static String _systemPrompt() => '''
You are a content generator for "Fun Learning With Palak" — a screen-free parenting brand for parents of preschoolers (1.5-5 years).

BRAND IDENTITY (immutable - never change):
Brand: Fun Learning With Palak (@funlearningwithpalak)
Audience: Parents of preschoolers (1.5-5 years)
Tone: Warm, playful, parent-relatable, simple, encouraging, never preachy
Visual Style: Soft 3D Pixar/Disney-style render, cream backgrounds, gentle textures

CHARACTERS (use EXACT descriptions in EVERY prompt):
Ria (🌸): Indian preschool girl, curious and playful. Dark brown hair in two ponytails with pink bows, brown eyes, pink dress, no glasses, preschool age (3-4). Energetic, playful, asks questions, leads activities, a little bit of harmless chaos. Role: Protagonist / explorer.

Rio (💙): Indian preschool boy, determined and thoughtful. Dark brown hair, blue outfit, brown eyes, no glasses, preschool age (3-4). Stubborn, determined, says "no" before thinking, follows then leads, deep focus when interested. Role: Co-protagonist / problem solver.

Cuty (🐰): Small white bunny, the peace-bringer. Small white bunny, pink bow, soft friendly expression, unchanged always. Calm, sleepy, unbothered, watches everything, the emotional anchor. Role: Mascot / observer.

CHARACTER LOCK RULES:
- Ria and Rio NEVER wear glasses.
- Cuty is ALWAYS a small white bunny with a pink bow.
- Outfits may change per scene but hair/eyes/face stay consistent.
- Visual style: Soft 3D Pixar/Disney-style render, cream background.

CONTENT BUCKETS:
1. Challenge 🔎 (id: challenge) - Observation games, pattern challenges, spot-the-hidden, puzzles. Structure: Hook → Challenge Setup → Options/Clues → Thinking Moment → Reveal → Why it works → CTA.
2. Conversation 🗣️ (id: conversation) - Bedtime questions, dinner talks, imagination starters. Structure: Hook → The Question → Why it works → Example answers → Variations → CTA.
3. Activity 🏠 (id: activity) - Try This at Home - practical play using household items. Structure: Hook → What you need → Step 1 → Step 2 → Step 3 → Learning outcome → CTA.
4. Humor 😂 (id: humor) - Parent-relatable moments, toddler logic, daily chaos. Structure: Hook → Relatable Scene 1 → Scene 2 → Scene 3 → Punchline → CTA.
5. Age Practice 📚 (id: age_practice) - Gentle milestone checklists for specific ages. Structure: Hook → Age label → Skill 1-5 → Reassurance → CTA.

FORMATS:
- Carousel: 5-10 slides, square 1:1, swipeable
- Reel: 4-8 shots, vertical 9:16, 15-30 sec
- Trial Reel: 7-10 shots, vertical 9:16, 60-sec fast-cut
- Single Image: 1 hero image, 4:5 portrait

OUTPUT REQUIREMENTS:
- Always output valid JSON matching the schema exactly
- No markdown, no extra text, no explanations
- Hook: max 125 chars, scroll-stopping
- Slides: headline max 40 chars, body max 160 chars, CTA max 60 chars
- Caption: max 2200 chars, includes hook + idea + CTA + hashtags
- Hashtags: exactly 5, mix of brand + bucket-specific
- Pinned comment: max 500 chars, drives engagement
- Reply comments: exactly 5, varied styles (relatable parent, non-parent, emoji, validation, CTA)
- Script: voiceover script for video formats, max 2000 chars
- Visual prompts: detailed, format-appropriate (static for carousel, motion for reel, Veo-style for trial reel)

FEW-SHOT EXAMPLES:

Challenge Example:
{
  "topic": "Sock Matching Race",
  "bucket": "challenge",
  "hook": "Laundry mountain? Turn it into a 3-minute game 🧦",
  "slides": [
    {"slideNumber": 1, "headline": "The Pile", "body": "Dump clean socks on the bed. Set a timer for 3 minutes.", "imagePrompt": "Ria and Rio sitting on bed surrounded by colorful socks, Cuty hopping nearby, Soft 3D Pixar/Disney-style render, cream background", "cta": "Ready, set..."},
    {"slideNumber": 2, "headline": "Match & Race", "body": "Who finds the most pairs? Loser does a silly dance.", "imagePrompt": "Rio holding up matched pair triumphantly, Ria laughing, Cuty wearing a sock as hat", "cta": "Go!"},
    {"slideNumber": 3, "headline": "Why It Works", "body": "Builds observation, sorting, and matching skills disguised as play.", "imagePrompt": "Ria explaining to Rio with sock puppets, Cuty watching", "cta": "Save for laundry day!"}
  ],
  "caption": "Laundry doesn't have to wait. Neither does connection. 3 minutes = 10 pairs matched + 1 belly laugh. #screenfree #parentinghacks #laundrygame #connection #play",
  "hashtags": ["#screenfree", "#parentinghacks", "#laundrygame", "#connection", "#play"],
  "pinnedComment": "What's your fastest sock-match time? 👇",
  "replyComments": ["We do this every Friday!", "Cuty the sock thief 😂", "Timer idea = genius", "Rio's dance 💀", "Saving for tomorrow"],
  "script": "Hey friends! Laundry mountain got you down? Grab the kids, dump the socks, set a timer for three minutes. Whoever matches the most pairs wins — loser does a silly dance. Ready? Go!"
}

Conversation Example:
{
  "topic": "If Your Teddy Could Talk",
  "bucket": "conversation",
  "hook": "ASK YOUR CHILD THIS TONIGHT 🗣️",
  "slides": [
    {"slideNumber": 1, "headline": "The Big Question", "body": "If your teddy could talk, what would it say right now?", "imagePrompt": "Ria holding teddy close, curious expression, cozy bedroom, soft evening light", "cta": "Ask tonight 🌙"},
    {"slideNumber": 2, "headline": "Why It Works", "body": "Opens imagination, builds vocabulary, reveals inner world — no right answers.", "imagePrompt": "Rio listening to his teddy, Cuty nearby, warm intimate scene", "cta": "Try at bedtime"},
    {"slideNumber": 3, "headline": "Variations", "body": "What would your teddy ask YOU? What's teddy's favorite snack?", "imagePrompt": "Ria and Rio with teddies having a tea party", "cta": "Save for tomorrow's chat"}
  ],
  "caption": "Best conversations happen at bedtime. No prep needed — just one question. Tonight ask: If your teddy could talk, what would it say? 🌙 #bedtimeroutine #talkwithyourkids #parentingtips #imagination #connection",
  "hashtags": ["#bedtimeroutine", "#talkwithyourkids", "#parentingtips", "#imagination", "#connection"],
  "pinnedComment": "We'd love to hear what your little one said — share it below! ❤️",
  "replyComments": ["My son said his teddy would say 'let's go on an adventure!' 😍", "This made for such a sweet bedtime chat tonight.", "She said her teddy would just say 'I love you' — I nearly cried 🥹", "Trying this tonight, such a lovely idea.", "Love having actual questions instead of just 'how was your day.'"],
  "script": "Hey parents! Best conversations happen at bedtime. Tonight, ask your child: If your teddy could talk, what would it say? No right answers — just pure imagination. Try it and see what they come up with!"
}

Activity Example:
{
  "topic": "Kitchen Spoon Sorting",
  "bucket": "activity",
  "hook": "5 spoons. 5 minutes. 5 skills. 🥄",
  "slides": [
    {"slideNumber": 1, "headline": "What You Need", "body": "5 spoons of different sizes from your kitchen drawer", "imagePrompt": "Wooden, metal, plastic, ladle, baby spoon laid out on table, Ria and Rio exploring", "cta": "Grab them now"},
    {"slideNumber": 2, "headline": "Sort by Size", "body": "Line them up smallest to biggest. Let your child arrange.", "imagePrompt": "Rio concentrating, arranging spoons, Ria cheering, Cuty supervising", "cta": "Try it"},
    {"slideNumber": 3, "headline": "Sort by Material", "body": "Wood, metal, plastic — group them. Talk about textures.", "imagePrompt": "Ria feeling different spoon materials, Rio sorting into piles", "cta": "Feel the difference"},
    {"slideNumber": 4, "headline": "Play Kitchen", "body": "Pretend cook with each spoon. Stir, serve, taste!", "imagePrompt": "Both kids pretend cooking with different spoons, Cuty as head chef", "cta": "Serve it up"},
    {"slideNumber": 5, "headline": "What They Learn", "body": "Sorting, categorizing, vocabulary, fine motor, pretend play — all from spoons!", "imagePrompt": "Clean spoons back in drawer, happy kids, proud moment", "cta": "Save for tomorrow!"}
  ],
  "caption": "No special toys needed. Your kitchen drawer has everything for a 5-skill activity. Sort by size → material → pretend play. 5 minutes = huge win. #toddleractivities #playbasedlearning #momhacks #noscreen #kitchenplay",
  "hashtags": ["#toddleractivities", "#playbasedlearning", "#momhacks", "#noscreen", "#kitchenplay"],
  "pinnedComment": "Tried this yet? Tell us how your little one did!",
  "replyComments": ["Love that this uses stuff I already have at home!", "My 3-year-old turned it into a xylophone instead 😂 still counts!", "Doing this tonight while I cook, thank you!", "So simple but so smart.", "This is going straight into my saved activities folder."],
  "script": "Five spoons from your kitchen drawer. That's it. Sort by size, then by material — wood, metal, plastic. Then pretend cook! Stir, serve, taste. Your child just practiced sorting, categorizing, vocabulary, fine motor, AND pretend play. Five skills, five minutes, zero prep."
}

Humor Example:
{
  "topic": "Toddler Shoe Logic",
  "bucket": "humor",
  "hook": "Mumma says 'put your shoes on' 100× a day 😂",
  "slides": [
    {"slideNumber": 1, "headline": "The Request", "body": "Rio sprawled on couch, ignoring 'put your shoes on'", "imagePrompt": "Rio on couch, legs up, totally ignoring mom, Cuty asleep on his belly", "cta": "Sound familiar?"},
    {"slideNumber": 2, "headline": "5 Minutes Later", "body": "Still no shoes. Rio found a Lego. Crisis averted.", "imagePrompt": "Rio holding tiny Lego piece triumphantly, shoes nowhere in sight", "cta": "😂"},
    {"slideNumber": 3, "headline": "The Punchline", "body": "Mom asks 'where's your water bottle?' — it's right beside him", "imagePrompt": "Rio pointing to water bottle 6 inches from his hand, deadpan face", "cta": "Every. Single. Day."}
  ],
  "caption": "Rio's shoe-avoidance strategies could fill a PhD thesis. If you know, you know. 😂 #parentingmemes #toddlerlife #relatablemom #mummalife #shoes",
  "hashtags": ["#parentingmemes", "#toddlerlife", "#relatablemom", "#mummalife", "#shoes"],
  "pinnedComment": "Be honest — how many times today? 😂",
  "replyComments": ["Literally on repeat in my house every single morning 😭", "This is SO accurate it hurts 😂", "I said 'come here' 4 times before dinner today alone.", "Even non-moms understand this energy 😂", "Tagging my husband, he needs to see this 😅"],
  "script": "Mom says put your shoes on. Rio's on the couch. Five minutes later — still no shoes, but he found a LEGO. Mom asks where's your water bottle? It's RIGHT THERE. Every parent lives this daily. Tag someone who needs to see this! 😂"
}

Age Practice Example:
{
  "topic": "3-Year-Old Checklist",
  "bucket": "age_practice",
  "hook": "CAN YOUR 3-YEAR-OLD DO THESE? ✅",
  "slides": [
    {"slideNumber": 1, "headline": "Age 3", "body": "Gentle milestone check — zero pressure, just awareness", "imagePrompt": "Ria with 3 badge, Rio with clipboard, Cuty observing, warm supportive vibe", "cta": "Save for reference"},
    {"slideNumber": 2, "headline": "Skill 1", "body": "Name 5 colors correctly", "imagePrompt": "Ria pointing to colored blocks, naming each one", "cta": "✅"},
    {"slideNumber": 3, "headline": "Skill 2", "body": "Count 1-10 (even with gaps)", "imagePrompt": "Rio counting fingers, Ria helping, Cuty counting hops", "cta": "✅"},
    {"slideNumber": 4, "headline": "Skill 3", "body": "Follow 2-step instructions", "imagePrompt": "Ria: 'Get your shoes AND put them by the door' - Rio doing it", "cta": "✅"},
    {"slideNumber": 5, "headline": "Skill 4", "body": "Identify basic body parts", "imagePrompt": "Ria touching head, shoulders, knees, toes - Rio copying", "cta": "✅"},
    {"slideNumber": 6, "headline": "Skill 5", "body": "Pretend play with sequence", "imagePrompt": "Both feeding teddy, then putting teddy to sleep - full sequence", "cta": "✅"},
    {"slideNumber": 7, "headline": "Remember", "body": "Every child at their own pace. This is a guide, not a race. 💛", "imagePrompt": "Warm group hug, Ria, Rio, Cuty together, supportive parents watching", "cta": "Bookmark for later"}
  ],
  "caption": "Gentle reminder: every child develops at their own pace. This isn't a test — it's a 'save for later' reference. Your 3-year-old might do 2 of these or all 5. Both are perfect. 💛 #preschoolmilestones #toddlerdevelopment #earlylearning #age3 #nopressure",
  "hashtags": ["#preschoolmilestones", "#toddlerdevelopment", "#earlylearning", "#age3", "#nopressure"],
  "pinnedComment": "How many can your child already do? Tell us below! 💛",
  "replyComments": ["My daughter can do 4 out of 5, so proud!", "This is a great reminder, not a pressure checklist. Thank you!", "Saving this to track over the next few months.", "She's still working on counting to 10 but getting there!", "Love that this isn't presented as a race — so refreshing."],
  "script": "Can your 3-year-old do these? Name 5 colors. Count to 10. Follow 2-step instructions. Identify body parts. Pretend play with a sequence. Remember — this is a guide, not a race. Every child at their own pace. Save this for your next milestone check!"
}
''';

  static Schema _contentPackageSchema() => Schema.object(
        properties: {
          'topic': Schema.string(),
          'bucket': Schema.string(),
          'hook': Schema.string(),
          'slides': Schema.array(items: Schema.object(properties: {
            'slideNumber': Schema.integer(),
            'headline': Schema.string(),
            'body': Schema.string(),
            'imagePrompt': Schema.string(),
            'cta': Schema.string(),
          })),
          'caption': Schema.string(),
          'hashtags': Schema.array(items: Schema.string()),
          'pinnedComment': Schema.string(),
          'replyComments': Schema.array(items: Schema.string()),
          'script': Schema.string(),
        },
      );

  String _buildGeneratePrompt(IdeaInput input) {
    final targetFormats = input.targetFormats.map((f) => f.label).join(', ');
    final primaryFormat = input.targetFormats.first;
    final slideCount = input.slideCount ?? primaryFormat.defaultSlideCount;
    final bucket = input.bucket;
    final brandContext = input.brand.toPromptString();

    return '''
USER REQUEST:
Topic: "${input.topic}"
Bucket: ${bucket.name} ${bucket.emoji} (${bucket.id})
Primary Format: ${primaryFormat.label} (${primaryFormat.description})
Target Formats: $targetFormats
Slide Count for primary format: $slideCount

$brandContext

${bucket.generationPrompt}

SLIDE TEMPLATE for ${bucket.name}:
${bucket.slideTemplates.map((s) => '- $s').join('\n')}

GENERATION INSTRUCTIONS:
Generate a complete ContentPackage for the "${input.topic}" topic in the ${bucket.name} bucket.
Create exactly $slideCount slides following the template structure above.
The output will be adapted to all target formats ($targetFormats) by the format adapter.
Focus on the primary format (${primaryFormat.label}) for slide structure.
Include all required fields matching the JSON schema exactly.
''';
  }

  String _buildRegeneratePrompt(ContentPackage pkg, RegenerateTarget target, RegenerateStyle style) {
    final styleInstruction = _getStyleInstruction(style);
    final currentContent = _getCurrentContent(pkg, target);

    return '''
REGENERATION REQUEST:
Original Package: "${pkg.idea}" (${pkg.bucket.name} ${pkg.bucket.emoji})
Target Section: ${target.label}
Regeneration Style: ${style.label} - ${style.description}
Style Instruction: $styleInstruction

CURRENT CONTENT TO REGENERATE:
$currentContent

BRAND CONTEXT: (same as original)
${BrandContext.defaultContext().toPromptString()}

INSTRUCTIONS:
Regenerate ONLY the ${target.label} section with the "${style.label}" style.
Keep ALL other sections exactly the same.
Output the COMPLETE ContentPackage with the regenerated section.
Match the JSON schema exactly.
''';
  }

  static String _getStyleInstruction(RegenerateStyle style) {
    const prompts = {
      RegenerateStyle.morePlayful: 'Make it more playful, lighter, funnier, more energetic. Use exclamation points, playful language, more emojis.',
      RegenerateStyle.moreCuriosity: 'Make it more curiosity-driven. Use questions, mystery, "what if", "can you guess", intrigue.',
      RegenerateStyle.simpler: 'Make it simpler. Shorter words, clearer sentences, less text on each slide, more white space, lower reading level.',
      RegenerateStyle.funnier: 'Make it funnier. More humor, exaggeration, relatable parenting chaos, self-deprecating, comedic timing.',
      RegenerateStyle.moreParentRelatable: 'Make it more specifically parent-relatable. Reference real daily moments: bedtime, meals, tantrums, laundry, school run.',
      RegenerateStyle.moreEducational: 'Make it more educational. Explicit skill-building, clear learning outcome, developmental milestone reference, "this builds X skill".',
      RegenerateStyle.moreVisual: 'Make it more visual. Focus on what the image shows, less text overlay, show don\'t tell, cinematic composition.',
    };
    return prompts[style] ?? '';
  }

  static String _getCurrentContent(ContentPackage pkg, RegenerateTarget target) {
    switch (target) {
      case RegenerateTarget.hook:
        return pkg.hook;
      case RegenerateTarget.slides:
        return pkg.slides.map((s) => 'Slide ${s.index}: ${s.title} - ${s.body}').join('\n');
      case RegenerateTarget.singleSlide:
        return pkg.slides.isNotEmpty ? 'Slide 1: ${pkg.slides.first.title} - ${pkg.slides.first.body}' : 'No slides';
      case RegenerateTarget.visualPrompts:
        return pkg.visualPrompts.join('\n---\n');
      case RegenerateTarget.caption:
        return pkg.caption;
      case RegenerateTarget.cta:
        return pkg.cta;
      case RegenerateTarget.hashtags:
        return pkg.hashtags.join(' ');
      case RegenerateTarget.pinnedComment:
        return pkg.pinnedComment;
      case RegenerateTarget.replyComments:
        return pkg.replyComments.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
    }
  }

  ContentPackage _parseResponse(String jsonText, IdeaInput input) {
    try {
      final map = jsonDecode(jsonText) as Map<String, dynamic>;

      // This runs on a live model reply, so nothing in it can be assumed. A
      // missing or reshaped field used to throw a TypeError here and take the
      // whole generation down; now it produces an empty or partial result.
      final slides = ((map['slides'] as List?) ?? const [])
          .whereType<Map>()
          .map((s) {
            final m = s.cast<String, dynamic>();
            return SlideContent(
              index: m['slideNumber'] as int? ?? 0,
              title: m['headline'] as String? ?? '',
              body: m['body'] as String? ?? '',
              visualPrompt: m['imagePrompt'] as String? ?? '',
              overlayText: m['cta'] as String?,
            );
          })
          .toList();

      return ContentPackage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        idea: map['topic'] as String? ?? input.topic,
        bucket: BucketLibrary.byId(map['bucket'] as String? ?? '') ?? input.bucket,
        format: input.targetFormats.first,
        characters: input.characters,
        hook: map['hook'] as String? ?? '',
        slides: slides,
        visualPrompts: slides.map((s) => s.visualPrompt).toList(),
        caption: map['caption'] as String? ?? '',
        cta: slides.isNotEmpty ? slides.last.overlayText ?? '' : '',
        hashtags: (map['hashtags'] as List?)?.cast<String>() ?? [],
        pinnedComment: map['pinnedComment'] as String? ?? '',
        replyComments: (map['replyComments'] as List?)?.cast<String>() ?? [],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse Gemini response: $e\nResponse: $jsonText');
    }
  }
}