import 'brand_system.dart';
import 'content_generator.dart';

class FormatOutput {
  final ContentFormat format;
  final List<String> copyBlocks;      // Hook, Caption, Hashtags, Pinned, Replies
  final List<SlideContent> slides;    // Adapted slides for this format
  final String script;                // Voiceover script
  final List<String> imagePrompts;    // Format-specific image prompts
  final Map<String, String> copyMap;  // Named copy blocks for easy access

  const FormatOutput({
    required this.format,
    required this.copyBlocks,
    required this.slides,
    required this.script,
    required this.imagePrompts,
    required this.copyMap,
  });

  Map<String, dynamic> toJson() => {
        'format': format.name,
        'copyBlocks': copyBlocks,
        'slides': slides.map((s) => s.toJson()).toList(),
        'script': script,
        'imagePrompts': imagePrompts,
        'copyMap': copyMap,
      };

  factory FormatOutput.fromJson(Map<String, dynamic> json) => FormatOutput(
        format: ContentFormat.values.byName(json['format'] as String),
        copyBlocks: (json['copyBlocks'] as List).cast<String>(),
        slides: (json['slides'] as List).map((s) => SlideContent.fromJson(s)).toList(),
        script: json['script'] as String,
        imagePrompts: (json['imagePrompts'] as List).cast<String>(),
        copyMap: (json['copyMap'] as Map).map((k, v) => MapEntry(k as String, v as String)),
      );
}

class FormatAdapter {
  /// Adapts a ContentPackage to all 4 formats
  static Map<ContentFormat, FormatOutput> adaptAll(ContentPackage pkg) {
    return {
      ContentFormat.carousel: _toCarousel(pkg),
      ContentFormat.reel: _toReel(pkg),
      ContentFormat.trialReel: _toTrialReel(pkg),
      ContentFormat.singleImage: _toSingleImage(pkg),
    };
  }

  /// Adapts to a specific format
  static FormatOutput adapt(ContentPackage pkg, ContentFormat format) {
    switch (format) {
      case ContentFormat.carousel:
        return _toCarousel(pkg);
      case ContentFormat.reel:
        return _toReel(pkg);
      case ContentFormat.trialReel:
        return _toTrialReel(pkg);
      case ContentFormat.singleImage:
        return _toSingleImage(pkg);
    }
  }

  // ==================== CAROUSEL (7 slides, static) ====================
  static FormatOutput _toCarousel(ContentPackage pkg) {
    final slides = _adaptSlidesForCarousel(pkg.slides, pkg.bucket);
    final prompts = slides.map((s) => _staticPrompt(s.visualPrompt, pkg.bucket)).toList();
    
    final copyMap = <String, String>{
      'hook': pkg.hook,
      'caption': pkg.caption,
      'hashtags': pkg.hashtags.join(' '),
      'pinnedComment': pkg.pinnedComment,
      'replyComments': pkg.replyComments.join('\n\n'),
      'script': _carouselScript(pkg),
    };

    return FormatOutput(
      format: ContentFormat.carousel,
      copyBlocks: [
        pkg.hook,
        pkg.caption,
        pkg.hashtags.join(' '),
        pkg.pinnedComment,
        ...pkg.replyComments,
      ],
      slides: slides,
      script: _carouselScript(pkg),
      imagePrompts: prompts,
      copyMap: copyMap,
    );
  }

  static List<SlideContent> _adaptSlidesForCarousel(List<SlideContent> originalSlides, ContentBucket bucket) {
    final targetCount = 7;
    final slides = <SlideContent>[];
    
    // Map original slides to carousel structure
    final template = bucket.slideTemplates;
    
    for (int i = 0; i < targetCount; i++) {
      SlideContent? sourceSlide;
      if (i < originalSlides.length) {
        sourceSlide = originalSlides[i];
      } else if (originalSlides.isNotEmpty) {
        sourceSlide = originalSlides.last;
      }
      
      if (sourceSlide != null) {
        slides.add(SlideContent(
          index: i,
          title: _adaptTitleForCarousel(sourceSlide.title, i, bucket),
          body: _adaptBodyForCarousel(sourceSlide.body, i, bucket),
          visualPrompt: sourceSlide.visualPrompt,
          overlayText: _carouselOverlayText(i, bucket),
        ));
      } else {
        // Generate missing slides from template
        slides.add(_generateCarouselSlide(i, bucket));
      }
    }
    
    return slides;
  }

  static String _adaptTitleForCarousel(String title, int index, ContentBucket bucket) {
    final templates = bucket.slideTemplates;
    if (index < templates.length) {
      final template = templates[index].toLowerCase();
      if (template.contains('cover')) return 'Cover';
      if (template.contains('challenge') || template.contains('what you need')) return 'What You Need';
      if (template.contains('step 1')) return 'Step 1';
      if (template.contains('step 2')) return 'Step 2';
      if (template.contains('step 3')) return 'Step 3';
      if (template.contains('think') || template.contains('why')) return 'Why It Works';
      if (template.contains('reveal') || template.contains('answer')) return 'The Answer';
      if (template.contains('variation')) return 'Variation';
      if (template.contains('cta') || template.contains('save') || template.contains('comment')) return 'Take Action';
      if (template.contains('question')) return 'Question ${index + 1}';
      if (template.contains('skill')) return 'Skill ${index + 1}';
      if (template.contains('scene')) return 'Scene ${index + 1}';
      if (template.contains('punchline')) return 'Punchline';
      if (template.contains('tagline')) return 'Tagline';
      if (template.contains('reassurance') || template.contains('remember')) return 'Remember';
    }
    return title;
  }

  static String _adaptBodyForCarousel(String body, int index, ContentBucket bucket) {
    // Keep body but ensure it fits carousel constraints (max ~160 chars)
    if (body.length <= 160) return body;
    return '${body.substring(0, 157)}...';
  }

  static String _carouselOverlayText(int index, ContentBucket bucket) {
    final templates = bucket.slideTemplates;
    if (index < templates.length) {
      final template = templates[index].toLowerCase();
      if (template.contains('cover')) return 'Hook';
      if (template.contains('step')) return 'Step ${index}';
      if (template.contains('think') || template.contains('why')) return 'Why it works';
      if (template.contains('reveal')) return 'Answer';
      if (template.contains('cta') || template.contains('save') || template.contains('comment')) return 'Save / Comment';
    }
    return '';
  }

  static SlideContent _generateCarouselSlide(int index, ContentBucket bucket) {
    final templates = bucket.slideTemplates;
    String title = 'Slide ${index + 1}';
    String body = 'Content for slide ${index + 1}';
    String visualPrompt = '';
    String overlayText = '';
    
    if (index < templates.length) {
      final template = templates[index];
      if (template.toLowerCase().contains('cover')) {
        title = 'Cover';
        body = bucket.exampleHooks.first;
        overlayText = 'Hook';
      } else if (template.toLowerCase().contains('cta')) {
        title = 'Take Action';
        body = 'Save this for later! Try it today and tell us how it went 📌';
        overlayText = 'Save / Comment';
      }
    }
    
    visualPrompt = _staticPrompt('$title - $body', bucket);
    
    return SlideContent(
      index: index,
      title: title,
      body: body,
      visualPrompt: visualPrompt,
      overlayText: overlayText,
    );
  }

  static String _staticPrompt(String base, ContentBucket bucket) {
    final bucketVibe = {
      'challenge': 'puzzle-like, clear challenge state visible, satisfying',
      'conversation': 'cozy, intimate, evening/bedroom setting, warm connection',
      'activity': 'real home setting, items clearly visible, characters doing activity',
      'humor': 'expressive faces, chaotic-cute energy, meme-style relatable',
      'age_practice': 'clean checklist style, consistent icons, warm not clinical',
      'community': 'friendly open energy, choices shown clearly, inviting',
    };
    
    // Use carousel format specs as default for static images
    final formatSpec = ContentFormat.carousel;
    
    return '''
$base
${BrandDefaults.visualStyle}, ${formatSpec.aspectRatio} aspect ratio (${formatSpec.canvasWidth}x${formatSpec.canvasHeight}px).
Safe Zone: Top ${formatSpec.topMargin}px, Bottom ${formatSpec.bottomMargin}px, Left ${formatSpec.leftMargin}px, Right ${formatSpec.rightMargin}px.
${bucketVibe[bucket.id] ?? 'warm, engaging'}
Characters: ${CharacterLibrary.all.map((c) => c.name).join(', ')}.
Character Lock: ${CharacterLibrary.characterLockBlock}
Bucket context: ${bucket.generationPrompt}
High quality, 4K, Soft 3D Pixar/Disney-style render.
'''.trim();
  }

  static String _carouselScript(ContentPackage pkg) {
    final buffer = StringBuffer();
    buffer.writeln(pkg.hook);
    buffer.writeln('');
    
    for (int i = 0; i < pkg.slides.length && i < 7; i++) {
      final slide = pkg.slides[i];
      buffer.writeln('Slide ${i + 1}: ${slide.title}');
      buffer.writeln(slide.body);
      if (slide.overlayText != null && slide.overlayText!.isNotEmpty) {
        buffer.writeln('[Overlay: ${slide.overlayText}]');
      }
      buffer.writeln('');
    }
    
    buffer.writeln(pkg.cta);
    return buffer.toString().trim();
  }

  // ==================== REEL (5 shots, motion) ====================
  static FormatOutput _toReel(ContentPackage pkg) {
    final shots = _condenseToShots(pkg.slides, 5, pkg.bucket);
    final prompts = shots.map((s) => _motionPrompt(s.visualPrompt, pkg.bucket)).toList();
    
    final copyMap = <String, String>{
      'hook': pkg.hook,
      'caption': pkg.caption,
      'hashtags': pkg.hashtags.join(' '),
      'pinnedComment': pkg.pinnedComment,
      'replyComments': pkg.replyComments.join('\n\n'),
      'script': _reelScript(pkg),
    };

    return FormatOutput(
      format: ContentFormat.reel,
      copyBlocks: [pkg.hook, pkg.caption, pkg.hashtags.join(' '), pkg.pinnedComment, ...pkg.replyComments],
      slides: shots,
      script: _reelScript(pkg),
      imagePrompts: prompts,
      copyMap: copyMap,
    );
  }

  static List<SlideContent> _condenseToShots(List<SlideContent> slides, int targetCount, ContentBucket bucket) {
    if (slides.length <= targetCount) return slides;
    
    final shots = <SlideContent>[];
    final step = slides.length / targetCount;
    
    for (int i = 0; i < targetCount; i++) {
      final sourceIndex = (i * step).floor();
      final source = slides[sourceIndex.clamp(0, slides.length - 1)];
      
      shots.add(SlideContent(
        index: i,
        title: _shotTitle(source.title, i, targetCount),
        body: _shotBody(source.body, i, targetCount),
        visualPrompt: source.visualPrompt,
        overlayText: _shotOverlay(i, targetCount),
      ));
    }
    
    return shots;
  }

  static String _shotTitle(String originalTitle, int index, int total) {
    const titles = ['Hook', 'Setup', 'Action', 'Peak', 'CTA'];
    if (index < titles.length) return titles[index];
    return 'Shot ${index + 1}';
  }

  static String _shotBody(String originalBody, int index, int total) {
    if (originalBody.length <= 120) return originalBody;
    return '${originalBody.substring(0, 117)}...';
  }

  static String _shotOverlay(int index, int total) {
    const overlays = ['', '', '', '', 'Follow for more!'];
    return overlays[index % overlays.length];
  }

  static String _motionPrompt(String base, ContentBucket bucket) {
    final bucketVibe = {
      'challenge': 'clear puzzle state, satisfying reveal motion',
      'conversation': 'intimate, slow zoom, cozy atmosphere',
      'activity': 'hands-on action, process visible, real movement',
      'humor': 'expressive reactions, comedic timing, zoom on faces',
      'age_practice': 'clean progression, checkmark animations, warm',
      'community': 'friendly poll energy, options appear one by one, inviting',
    };
    
    final formatSpec = ContentFormat.reel;
    
    return '''
$base
${BrandDefaults.visualStyle}, ${formatSpec.aspectRatio} aspect ratio (${formatSpec.canvasWidth}x${formatSpec.canvasHeight}px).
Safe Zone: Top ${formatSpec.topMargin}px, Bottom ${formatSpec.bottomMargin}px, Left ${formatSpec.leftMargin}px, Right ${formatSpec.rightMargin}px.
${bucketVibe[bucket.id] ?? 'engaging motion'}
Characters: ${CharacterLibrary.all.map((c) => c.name).join(', ')}.
Character Lock: ${CharacterLibrary.characterLockBlock}
Bucket context: ${bucket.generationPrompt}
CINEMATIC VIDEO: Smooth camera movement (gentle pan/zoom/push), 2-3 second shot, 30fps, high quality.
'''.trim();
  }

  static String _reelScript(ContentPackage pkg) {
    final buffer = StringBuffer();
    buffer.writeln('0:00 ${pkg.hook}');
    buffer.writeln('');
    
    final shots = _condenseToShots(pkg.slides, 5, pkg.bucket);
    const timings = ['0:03', '0:07', '0:11', '0:15', '0:19'];
    
    for (int i = 0; i < shots.length; i++) {
      buffer.writeln('${timings[i]} ${shots[i].body}');
    }
    
    buffer.writeln('');
    buffer.writeln('0:22 ${pkg.cta}');
    return buffer.toString().trim();
  }

  // ==================== TRIAL REEL (8 shots, Veo-style) ====================
  static FormatOutput _toTrialReel(ContentPackage pkg) {
    final shots = _expandToShots(pkg.slides, 8, pkg.bucket);
    final prompts = shots.asMap().entries.map((e) => veoPrompt(e.value, e.key, pkg.bucket)).toList();
    
    final copyMap = <String, String>{
      'hook': pkg.hook,
      'caption': pkg.caption,
      'hashtags': pkg.hashtags.join(' '),
      'pinnedComment': pkg.pinnedComment,
      'replyComments': pkg.replyComments.join('\n\n'),
      'script': _trialReelScript(pkg),
      'shotPlan': _shotPlanText(shots),
    };

    return FormatOutput(
      format: ContentFormat.trialReel,
      copyBlocks: [pkg.hook, pkg.caption, pkg.hashtags.join(' '), pkg.pinnedComment, ...pkg.replyComments],
      slides: shots,
      script: _trialReelScript(pkg),
      imagePrompts: prompts,
      copyMap: copyMap,
    );
  }

  static List<SlideContent> _expandToShots(List<SlideContent> slides, int targetCount, ContentBucket bucket) {
    if (slides.length >= targetCount) {
      return slides.take(targetCount).toList();
    }
    
    final shots = <SlideContent>[];
    shots.addAll(slides);
    
    // Add intermediate shots to reach target count
    while (shots.length < targetCount) {
      final lastIdx = shots.length - 1;
      final last = shots[lastIdx];
      final nextIdx = (lastIdx + 1) % slides.length;
      final next = slides[nextIdx];
      
      shots.add(SlideContent(
        index: shots.length,
        title: _interpolateTitle(last.title, next.title, shots.length),
        body: _interpolateBody(last.body, next.body),
        visualPrompt: _interpolatePrompt(last.visualPrompt, next.visualPrompt),
        overlayText: '',
      ));
    }
    
    return shots;
  }

  static String _interpolateTitle(String a, String b, int index) {
    const connectors = ['Then', 'Next', 'Meanwhile', 'After that', 'Finally'];
    return '${connectors[index % connectors.length]}: $b';
  }

  static String _interpolateBody(String a, String b) {
    return 'Transition: $a → $b';
  }

  static const List<String> cameraMoves = [
    'slow push in',
    'gentle pan right', 
    'subtle tilt up',
    'slow pull back',
    'static with subtle parallax',
    'dolly left',
    'crane up slightly',
    'push in to detail',
  ];
  
  static const List<String> lightingOptions = [
    'morning golden hour',
    'soft window light',
    'warm ambient glow',
    'gentle side lighting',
    'soft overhead',
    'window light from left',
    'golden hour warmth',
    'soft diffused',
  ];
  
  static const List<int> durations = [2, 3, 2, 3, 2, 3, 2, 3];
  
  static const List<String> audioCues = [
    'gentle whoosh transition',
    'soft pop sound effect',
    'curious chime',
    'satisfying click',
    'gentle transition',
    'playful boing',
    'warm hum',
    'final resolve note',
  ];
  
  static const List<String> transitions = [
    'smooth cut',
    'smooth cut',
    'match cut',
    'smooth cut',
    'whip pan',
    'smooth cut',
    'match cut',
    'fade to logo',
  ];

  static String _interpolatePrompt(String a, String b) {
    return '$a\n\nTRANSITION TO: $b';
  }

  static String veoPrompt(SlideContent slide, int shotIndex, ContentBucket bucket) {
    final formatSpec = ContentFormat.trialReel;
    
    final move = cameraMoves[shotIndex % cameraMoves.length];
    final light = lightingOptions[shotIndex % lightingOptions.length];
    final duration = durations[shotIndex % durations.length];
    final audio = audioCues[shotIndex % audioCues.length];
    final transition = transitions[shotIndex % transitions.length];
    
    return '''
SHOT ${shotIndex + 1}/8: ${slide.title}
═══════════════════════════════════
VISUAL: ${slide.visualPrompt}
CAMERA: $move, $light
DURATION: ${duration}s
AUDIO CUE: $audio
TRANSITION: $transition
CHARACTERS: ${CharacterLibrary.all.map((c) => c.name).join(', ')}
STYLE: ${BrandDefaults.visualStyle}, ${formatSpec.aspectRatio} aspect ratio (${formatSpec.canvasWidth}x${formatSpec.canvasHeight}px)
Safe Zone: Top ${formatSpec.topMargin}px, Bottom ${formatSpec.bottomMargin}px, Left ${formatSpec.leftMargin}px, Right ${formatSpec.rightMargin}px
QUALITY: 4K, 30fps, high detail
'''.trim();
  }

  static String _shotPlanText(List<SlideContent> shots) {
    final buffer = StringBuffer();
    buffer.writeln('TRIAL REEL SHOT PLAN (8 shots)');
    buffer.writeln('════════════════════════════════');
    buffer.writeln('');
    
    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];
      buffer.writeln('SHOT ${i + 1}: ${shot.title}');
      buffer.writeln('  Visual: ${shot.body}');
      buffer.writeln('  Duration: ${_shotDuration(shot)}s');
      buffer.writeln('  Camera: ${_cameraForShot(i)}');
      buffer.writeln('  Lighting: ${_lightingForShot(i)}');
      buffer.writeln('  Audio: ${_audioForShot(i)}');
      buffer.writeln('  Transition: ${i < shots.length - 1 ? "smooth cut" : "fade to logo"}');
      buffer.writeln('');
    }
    
    buffer.writeln('TOTAL: ~${shots.fold(0, (sum, s) => sum + _shotDuration(s))} seconds');
    return buffer.toString();
  }

  static int _shotDuration(SlideContent shot) {
    final wordCount = shot.body.split(' ').length;
    return (wordCount / 3).clamp(2, 4).round();
  }

  static String _cameraForShot(int index) {
    const cameras = ['slow push in', 'gentle pan right', 'subtle tilt up', 'slow pull back', 'static', 'dolly left', 'crane up', 'push in'];
    return cameras[index % cameras.length];
  }

  static String _lightingForShot(int index) {
    const lights = ['morning golden hour', 'soft window light', 'warm ambient', 'gentle side light', 'soft overhead', 'window light', 'golden hour', 'soft diffused'];
    return lights[index % lights.length];
  }

  static String _audioForShot(int index) {
    const audio = ['whoosh', 'pop', 'chime', 'click', 'transition', 'boing', 'hum', 'resolve'];
    return audio[index % audio.length];
  }

  static String _trialReelScript(ContentPackage pkg) {
    final buffer = StringBuffer();
    buffer.writeln('TRIAL REEL SCRIPT (60-second fast-cut)');
    buffer.writeln('════════════════════════════════════');
    buffer.writeln('');
    
    final shots = _expandToShots(pkg.slides, 8, pkg.bucket);
    var time = 0;
    
    for (int i = 0; i < shots.length; i++) {
      final duration = _shotDuration(shots[i]);
      final mins = (time ~/ 60).toString().padLeft(2, '0');
      final secs = (time % 60).toString().padLeft(2, '0');
      
      buffer.writeln('$mins:$secs SHOT ${i + 1}: ${shots[i].title}');
      buffer.writeln('      ${shots[i].body}');
      buffer.writeln('      [${duration}s] ${_cameraForShot(i)}, ${_lightingForShot(i)}');
      buffer.writeln('      Audio: ${_audioForShot(i)}');
      buffer.writeln('');
      
      time += duration;
    }
    
    final endMins = (time ~/ 60).toString().padLeft(2, '0');
    final endSecs = (time % 60).toString().padLeft(2, '0');
    buffer.writeln('$endMins:$endSecs LOGO + CTA: ${pkg.cta}');
    buffer.writeln('      Follow @funlearningwithpalak for daily play ideas!');
    
    return buffer.toString().trim();
  }

  // ==================== SINGLE IMAGE (1 hero) ====================
  static FormatOutput _toSingleImage(ContentPackage pkg) {
    final heroSlide = pkg.slides.isNotEmpty 
        ? pkg.slides.firstWhere((s) => s.index == 0, orElse: () => pkg.slides.first)
        : _generateCarouselSlide(0, pkg.bucket);
    
    final prompt = _heroPrompt(heroSlide.visualPrompt, pkg.bucket);
    
    final copyMap = <String, String>{
      'hook': pkg.hook,
      'caption': pkg.caption,
      'hashtags': pkg.hashtags.join(' '),
      'pinnedComment': pkg.pinnedComment,
      'replyComments': pkg.replyComments.join('\n\n'),
      'altText': _generateAltText(heroSlide, pkg.bucket),
    };

    return FormatOutput(
      format: ContentFormat.singleImage,
      copyBlocks: [pkg.hook, pkg.caption, pkg.hashtags.join(' '), pkg.pinnedComment, ...pkg.replyComments],
      slides: [heroSlide],
      script: '',
      imagePrompts: [prompt],
      copyMap: copyMap,
    );
  }

  static String _heroPrompt(String base, ContentBucket bucket) {
    final bucketVibe = {
      'challenge': 'hero composition, puzzle clearly visible, inviting curiosity',
      'conversation': 'intimate eye-level, cozy connection moment, warm',
      'activity': 'hands-on process shot, materials visible, action frozen',
      'humor': 'expressive faces, comedic timing frozen, relatable chaos',
      'age_practice': 'clean checklist aesthetic, skill in progress, encouraging',
      'community': 'friendly open energy, options side by side, inviting',
    };
    
    final formatSpec = ContentFormat.singleImage;
    
    return '''
$base
${BrandDefaults.visualStyle}, ${formatSpec.aspectRatio} aspect ratio (${formatSpec.canvasWidth}x${formatSpec.canvasHeight}px).
Safe Zone: Top ${formatSpec.topMargin}px, Bottom ${formatSpec.bottomMargin}px, Left ${formatSpec.leftMargin}px, Right ${formatSpec.rightMargin}px.
${bucketVibe[bucket.id] ?? 'engaging, warm'}
Characters: ${CharacterLibrary.all.map((c) => c.name).join(', ')}.
Character Lock: ${CharacterLibrary.characterLockBlock}
Bucket context: ${bucket.generationPrompt}
HIGH DETAIL: 4K, professional photography quality, Soft 3D Pixar/Disney-style render.
Perfect for Instagram single image post.
'''.trim();
  }

  static String _generateAltText(SlideContent slide, ContentBucket bucket) {
    return '${slide.title}: ${slide.body}. ${BrandDefaults.visualStyle} featuring Ria, Rio, and Cuty.';
  }
}

// Extension for generating format-specific content from any ContentPackage
extension FormatAdapterExt on ContentPackage {
  Map<ContentFormat, FormatOutput> toAllFormats() => FormatAdapter.adaptAll(this);
  
  FormatOutput toFormat(ContentFormat format) => FormatAdapter.adapt(this, format);
}