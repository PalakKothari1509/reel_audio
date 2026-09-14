import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import 'music.dart';

// ── Video settings ────────────────────────────────────────────────────────────

/// Portrait 1080x1920 — the shape Reels, Shorts and TikTok expect.
const int kVideoWidth = 1080;
const int kVideoHeight = 1920;
const int kFps = 30;

/// Shortest a single image may stay on screen, so a fast line can't flash past.
const double kMinClipSeconds = 1.0;

/// Held after the last spoken word so the video doesn't cut on the final syllable.
const double kTailSeconds = 1.5;

/// How long the closing brand card stays up.
///
/// Long enough to read a question and two reasons, short enough that nobody scrolls
/// away during it — an end card people skip teaches Instagram the reel was not finished.
const double kEndCardSeconds = 3.5;

// ── Staying out of Instagram's way ────────────────────────────────────────────
//
// Instagram draws its own things on top of the reel: a header at the top, the
// username, caption and audio ticker along the bottom, and the like/comment/share
// column down the right. Anything of ours underneath is invisible on the phone even
// though the preview looks perfect — which is the worst kind of bug, because nothing
// looks wrong until it is posted.
//
// These are the shares of a 1080x1920 frame that are actually ours to draw in.

const double kSafeTop = 0.13;
const double kSafeBottom = 0.78;

/// Pixels between the top edge of the frame and a caption placed high.
const int kCaptionTopGap = 30;

/// Where the top of the cover hook sits. Below the 240 pixels Instagram's 3:4 profile
/// grid crops off the top of a reel, with a little room, so the hook survives the crop.
const int kCoverTop = 280;

/// Widest a caption may be before its right end slides under the button column.
///
/// The old 0.86 put the last few characters of every caption directly beneath the
/// like button. Nobody reading the reel ever saw the end of a line.
const double kSafeCaptionWidth = 0.72;

/// Where the caption sits down the frame. Which one is right depends on the pictures,
/// so it is a choice rather than a constant — a caption that clears Instagram can
/// still land across somebody's face.
enum CaptionSpot { high, middle, low }

double captionSpotFraction(CaptionSpot spot) {
  switch (spot) {
    case CaptionSpot.high:
      return 0.24;
    case CaptionSpot.middle:
      return 0.50;
    case CaptionSpot.low:
      return 0.68;
  }
}

String captionSpotLabel(CaptionSpot spot) {
  switch (spot) {
    case CaptionSpot.high:
      return 'high';
    case CaptionSpot.middle:
      return 'middle';
    case CaptionSpot.low:
      return 'low';
  }
}

/// One picture drawn in the Moment look: a blurred backdrop, and the tilted photo card
/// that sits on it. Two files so FFmpeg can move the card and leave the backdrop still.
class MomentFrame {
  final String backgroundPng;
  final String cardPng;
  const MomentFrame(this.backgroundPng, this.cardPng);
}

/// How much the picture moves while it is on screen.
///
/// No zoom in the list, and that is deliberate: zooming has to crop to have anywhere
/// to go, which cuts the edges off the picture — the exact thing the fit-not-fill
/// change was made to stop. These all move the whole picture instead.
enum ClipMotion { still, drift, sway }

// Sway is the same idea as drift, just further and slower, and moving sideways as
// well so it does not read as one up-and-down wobble. [swing] flips per picture so a
// long reel does not slide steadily in one direction.

String _motionX(ClipMotion motion, int swing) {
  switch (motion) {
    case ClipMotion.sway:
      return "'(W-w)/2+$swing*20*sin(2*PI*t/11)'";
    case ClipMotion.still:
    case ClipMotion.drift:
      return "'(W-w)/2'";
  }
}

String _motionY(ClipMotion motion, int swing) {
  switch (motion) {
    case ClipMotion.still:
      return "'(H-h)/2'";
    case ClipMotion.drift:
      return "'(H-h)/2+$swing*14*sin(2*PI*t/9)'";
    case ClipMotion.sway:
      return "'(H-h)/2+$swing*32*sin(2*PI*t/14)'";
  }
}

String clipMotionLabel(ClipMotion motion) {
  switch (motion) {
    case ClipMotion.still:
      return 'still';
    case ClipMotion.drift:
      return 'drift';
    case ClipMotion.sway:
      return 'sway';
  }
}

// ── Probing ───────────────────────────────────────────────────────────────────

/// Length of an audio or video file in seconds; null when it can't be read.
///
/// This has to be FFprobe, not FFmpeg. The old code passed ffprobe-only flags
/// (-show_entries, -of) to FFmpegKit, which rejects them — so the parse always failed
/// and every spoken line was assumed to be 3 seconds. Anything longer pushed the next
/// line late, and the error added up down the script.
Future<double?> getMediaDuration(String path) async {
  final session = await FFprobeKit.getMediaInformation(path);
  final seconds = double.tryParse(session.getMediaInformation()?.getDuration() ?? '');
  return (seconds != null && seconds > 0.05) ? seconds : null;
}

// ── Timing ────────────────────────────────────────────────────────────────────

/// Where each line falls when the whole script was spoken in one pass.
///
/// With no per-line audio to measure, length is the best guide available: a line twice
/// as long takes roughly twice as long to say. It is an estimate, and a line with a
/// long pause in it will drift — but for changing a picture it lands close enough, and
/// it buys a voice that flows instead of one stitched from clips.
List<double> estimatedLineStarts({
  required List<String> texts,
  required double totalSeconds,
}) {
  if (texts.isEmpty || totalSeconds <= 0) return const [];

  // Every line counts for something, so an empty one can't collapse to zero width.
  final weights = texts.map((t) => t.trim().isEmpty ? 1 : t.trim().length).toList();
  final total = weights.fold<int>(0, (sum, w) => sum + w);

  final starts = <double>[];
  var cursor = 0.0;
  for (final weight in weights) {
    starts.add(cursor);
    cursor += totalSeconds * weight / total;
  }
  return starts;
}

// ── Finding the joins by listening ────────────────────────────────────────────
//
// Guessing from line length is only ever close. A short line with an exclamation in
// it takes longer to say than a long flat one, Gemini breathes where it likes, and
// every small error pushes every later picture further out — which is what "the
// pictures don't match the voice" actually is.
//
// The voice itself knows where the joins are: it pauses at the end of each line. So
// rather than estimating, listen for the pauses and put the picture changes there.

/// A stretch of quiet in the narration.
class VoicePause {
  final double start;
  final double end;
  const VoicePause(this.start, this.end);
  double get length => end - start;
}

/// Every pause in the narration longer than [minSeconds], found by FFmpeg.
///
/// -32dB rather than silence: a recording is never truly silent, and a stricter
/// threshold finds nothing at all. Returns an empty list if anything goes wrong,
/// because a failure here should fall back to the estimate, not break the build.
Future<List<VoicePause>> findVoicePauses(String audioPath,
    {double minSeconds = 0.18}) async {
  try {
    final session = await FFmpegKit.executeWithArguments([
      '-hide_banner',
      '-i', audioPath,
      '-af', 'silencedetect=noise=-32dB:d=${minSeconds.toStringAsFixed(2)}',
      '-f', 'null', '-',
    ]);
    final logs = await session.getAllLogsAsString() ?? '';

    final starts = RegExp(r'silence_start:\s*(-?[\d.]+)')
        .allMatches(logs)
        .map((m) => double.tryParse(m.group(1) ?? '') ?? 0.0)
        .toList();
    final ends = RegExp(r'silence_end:\s*([\d.]+)')
        .allMatches(logs)
        .map((m) => double.tryParse(m.group(1) ?? '') ?? 0.0)
        .toList();

    final pauses = <VoicePause>[];
    for (int i = 0; i < starts.length && i < ends.length; i++) {
      // The quiet before the first word is not a join between two lines, and a
      // pause that ends before it starts is a parse that went wrong.
      if (starts[i] < 0.15 || ends[i] <= starts[i]) continue;
      pauses.add(VoicePause(starts[i], ends[i]));
    }
    return pauses;
  } catch (_) {
    return const [];
  }
}

/// Where each line starts, taken from where the voice actually paused.
///
/// The estimate is still worked out first and used as the map: a pause is only
/// believed to be the join for a line when it falls near where that line was
/// expected. A pause far from any expected join is a breath in the middle of a
/// sentence, and moving a picture onto it would be worse than the estimate.
///
/// Joins with no pause to match keep their estimated share of the time between the
/// two nearest joins that did match — so one missed pause costs one picture, instead
/// of pushing every picture after it out of step.
List<double> alignedLineStarts({
  required List<String> texts,
  required double totalSeconds,
  required List<VoicePause> pauses,
}) {
  final estimate = estimatedLineStarts(texts: texts, totalSeconds: totalSeconds);
  if (estimate.length < 2 || pauses.isEmpty) return estimate;

  // How far a pause may sit from the estimate and still count as that join. Scaled to
  // the reel: a long reel drifts further before the pause turns up.
  final window = (totalSeconds / estimate.length).clamp(0.8, 2.5);

  // The first line always starts at zero; only the joins after it can move.
  final anchors = <int, double>{0: 0.0};
  var lastAnchored = 0.0;
  var next = 0;

  for (int i = 1; i < estimate.length; i++) {
    while (next < pauses.length) {
      final at = pauses[next].end;
      // Too early to be this join, or too close behind the last one to leave a
      // picture any time on screen — skip it and look at the following pause.
      if (at < estimate[i] - window || at <= lastAnchored + kMinClipSeconds) {
        next++;
        continue;
      }
      // Past the window: this pause belongs to a later line, so leave it for one.
      if (at > estimate[i] + window) break;

      anchors[i] = at;
      lastAnchored = at;
      next++;
      break;
    }
  }

  // Nothing matched beyond the opening, so the estimate is all there is.
  if (anchors.length < 2) return estimate;

  final starts = List<double>.filled(estimate.length, 0);
  final indices = anchors.keys.toList()..sort();

  for (int a = 0; a < indices.length; a++) {
    final from = indices[a];
    starts[from] = anchors[from]!;

    // Everything up to the next matched join, or to the end of the narration.
    final hasNext = a + 1 < indices.length;
    final to = hasNext ? indices[a + 1] : estimate.length;
    final endTime = hasNext ? anchors[indices[a + 1]]! : totalSeconds;
    final endEstimate = hasNext ? estimate[indices[a + 1]] : totalSeconds;

    final span = endEstimate - estimate[from];
    for (int i = from + 1; i < to; i++) {
      // Keep the estimate's own shape inside the run, stretched to fit the gap the
      // two matched joins leave.
      final share = span <= 0 ? 0.0 : (estimate[i] - estimate[from]) / span;
      starts[i] = anchors[from]! + (endTime - anchors[from]!) * share;
    }
  }

  // Never let a rounding slip put a picture before the one in front of it.
  for (int i = 1; i < starts.length; i++) {
    if (starts[i] <= starts[i - 1]) starts[i] = starts[i - 1] + 0.05;
  }
  return starts;
}

/// How long each line stays on screen: from its own start to the next line's start,
/// with the last one running to the end of the narration.
List<double> clipDurations({
  required List<double> lineStarts,
  required double totalSeconds,
}) {
  final out = <double>[];
  for (int i = 0; i < lineStarts.length; i++) {
    final end = i + 1 < lineStarts.length ? lineStarts[i + 1] : totalSeconds;
    final span = end - lineStarts[i];
    out.add(span < kMinClipSeconds ? kMinClipSeconds : span);
  }
  return out;
}

// ── Building ──────────────────────────────────────────────────────────────────

/// Builds a portrait slideshow from still images plus a narration track.
///
/// Each image becomes its own short clip before they are joined, rather than one long
/// filter_complex. A single graph would be quicker, but when it fails it fails as one
/// opaque error; this way a failure names the image that caused it. On a phone that
/// difference is worth more than the seconds it costs.
class SlideshowBuilder {
  /// Images are used in order, one per script line, wrapping round when there are
  /// fewer images than lines.
  static String imageForLine(List<String> images, int lineIndex) =>
      images[lineIndex % images.length];

  /// Returns the path of the finished video.
  ///
  /// [lineStarts] is one timestamp per script line, in seconds, already sorted.
  static Future<String> build({
    required List<String> imagePaths,
    required List<double> lineStarts,
    required String audioPath,
    required String workDir,
    /// A bundled track already unpacked to a file, or null for no music.
    String? musicPath,
    /// One PNG per line, null for a line with no caption. Empty means no captions.
    List<String?> captionPngs = const [],
    /// The closing brand card, already drawn, or null for no end card. Drawn by the
    /// caller like the captions are, so this file never has to know what it says.
    String? brandPng,
    CaptionSpot captionSpot = CaptionSpot.high,
    ClipMotion motion = ClipMotion.drift,
    /// True when the first caption is the cover hook, which is placed differently.
    bool coverOnFirst = false,
    /// One frame per line in the Moment look, already drawn. When given, these are
    /// used instead of the pictures and captions, which are inside the card already.
    List<MomentFrame>? moment,
    void Function(String message)? onStatus,
  }) async {
    if (imagePaths.isEmpty) throw Exception('Add at least one image first.');
    if (lineStarts.isEmpty) throw Exception('There are no script lines to show images against.');
    if (!await File(audioPath).exists()) throw Exception('Save the voice before building the video.');

    // The narration decides the length of the video, so the two can never disagree.
    final narration = await getMediaDuration(audioPath);
    if (narration == null) throw Exception('Could not read the narration audio.');

    // The end card IS the tail when there is one, so the reel does not sit in silence
    // on the last picture and then sit in silence again on the card.
    final totalSeconds = narration + (brandPng == null ? kTailSeconds : 0.6);

    final durations = clipDurations(lineStarts: lineStarts, totalSeconds: totalSeconds);

    // Anything left from an earlier attempt would be picked up by the concat list below.
    await _deleteWhere(workDir, (name) => name.startsWith('clip_') && name.endsWith('.mp4'));

    final clipPaths = <String>[];
    for (int i = 0; i < durations.length; i++) {
      onStatus?.call('Rendering image ${i + 1} of ${durations.length}...');
      final clipPath = '$workDir/clip_$i.mp4';
      if (moment != null && i < moment.length) {
        await _renderMomentClip(
          frame: moment[i],
          outPath: clipPath,
          seconds: durations[i],
          index: i,
          isFirst: i == 0,
          isLast: brandPng == null && i == durations.length - 1,
          motion: motion,
        );
        clipPaths.add(clipPath);
        continue;
      }
      await _renderClip(
        imagePath: imageForLine(imagePaths, i),
        outPath: clipPath,
        seconds: durations[i],
        index: i,
        isFirst: i == 0,
        // The fade to black belongs on whatever is genuinely last. With an end card
        // following, fading the final picture would black out and then come back.
        isLast: brandPng == null && i == durations.length - 1,
        captionPng: i < captionPngs.length ? captionPngs[i] : null,
        captionSpot: captionSpot,
        motion: motion,
        isCover: coverOnFirst && i == 0,
      );
      clipPaths.add(clipPath);
    }

    if (brandPng != null) {
      onStatus?.call('Adding the end card...');
      final cardPath = '$workDir/clip_end.mp4';
      await _renderEndCard(
        // The last picture, blurred behind the card, so the reel ends inside the story
        // rather than cutting to a title screen.
        imagePath: imageForLine(imagePaths, durations.length - 1),
        brandPng: brandPng,
        outPath: cardPath,
        seconds: kEndCardSeconds,
      );
      clipPaths.add(cardPath);
    }

    onStatus?.call('Joining ${clipPaths.length} clips...');
    final silentPath = '$workDir/slideshow_silent.mp4';
    await _concat(clipPaths: clipPaths, workDir: workDir, outPath: silentPath);

    onStatus?.call('Adding the voice...');
    final finalPath = '$workDir/reel_slideshow.mp4';
    await _addAudio(videoPath: silentPath, audioPath: audioPath,
        outPath: finalPath, musicPath: musicPath);

    return finalPath;
  }

  /// One still image as a clip: the whole picture, on a blurred version of itself.
  ///
  /// The old version scaled each image to FILL the frame and cropped the overflow, so
  /// anything not already portrait lost its edges — heads and sides cut off. Now the
  /// picture is scaled to FIT, so nothing is ever lost, and the empty space is filled
  /// with a soft blurred copy of the same image instead of black bars.
  ///
  /// It drifts slowly rather than zooming. A zoom has to crop to have anywhere to go;
  /// a few pixels of movement keeps it alive without touching the edges.
  static Future<void> _renderClip({
    required String imagePath,
    required String outPath,
    required double seconds,
    required int index,
    required bool isFirst,
    required bool isLast,
    String? captionPng,
    CaptionSpot captionSpot = CaptionSpot.high,
    ClipMotion motion = ClipMotion.drift,
    /// True when [captionPng] is the cover hook rather than an ordinary caption.
    bool isCover = false,
  }) async {
    if (!await File(imagePath).exists()) {
      throw Exception('Image ${index + 1} is missing: $imagePath');
    }
    await _deleteIfExists(outPath);

    // A caption whose file has gone is skipped rather than failing the whole build —
    // a reel without one caption still beats no reel.
    final caption = (captionPng != null && await File(captionPng).exists())
        ? captionPng
        : null;

    // Fading every clip in and out meant the video blinked to black between each
    // picture. Only the very start and the very end fade now; the rest cut straight.
    final fades = <String>[];
    if (isFirst) fades.add('fade=t=in:st=0:d=0.5');
    if (isLast) {
      final from = (seconds - 0.6) < 0 ? 0.0 : seconds - 0.6;
      fades.add('fade=t=out:st=${from.toStringAsFixed(2)}:d=0.6');
    }
    final fadePart = fades.isEmpty ? '' : ',${fades.join(',')}';

    // The backdrop is the same picture shrunk to thumbnail size and scaled back up.
    // Blowing up 64 pixels to 1080 IS the blur — no blur filter needed, which keeps
    // this working on ffmpeg builds that leave gblur out, and costs almost nothing.
    // Movement alternates direction per image so a long reel doesn't slide one way.
    final swing = index.isEven ? 1 : -1;

    final moveX = _motionX(motion, swing);
    final moveY = _motionY(motion, swing);

    // The caption comes in as input 1 and goes on AFTER the movement, so it stays put
    // while the picture moves behind it — a caption that floats is hard to read. The
    // fade still covers both, because it is applied after this.
    //
    // min/max keep it inside the band Instagram leaves alone whatever height it turns
    // out to be: a three-line caption placed low would otherwise hang down into the
    // username and audio ticker and lose its bottom line.
    final spot = captionSpotFraction(captionSpot);
    final String captionY;
    if (isCover) {
      // The cover sits lower than the captions on purpose. Instagram's profile grid
      // shows a reel as a 3:4 crop from the middle, which cuts the top 240 pixels off —
      // a hook placed where the captions go would be missing from the one view where
      // the cover is the whole point.
      captionY = "'$kCoverTop'";
    } else if (captionSpot == CaptionSpot.high) {
      // Right at the top, a fixed gap from the edge, as asked. A fixed number of
      // pixels rather than a share of the frame so it lands in the same place on
      // every reel whatever the caption's height.
      captionY = "'$kCaptionTopGap'";
    } else {
      // min/max keep it inside the band Instagram leaves alone whatever height it
      // turns out to be: a three-line caption placed low would otherwise hang down
      // into the username and audio ticker and lose its bottom line.
      captionY = "'max(H*$kSafeTop,min(H*$spot-h/2,H*$kSafeBottom-h))'";
    }
    final captionPart = caption == null
        ? ''
        : "[withpic];[withpic][1:v]overlay=x='(W-w)/2':y=$captionY";

    final filter =
        '[0:v]split=2[bg][fg];'
        '[bg]scale=64:114:force_original_aspect_ratio=increase,crop=64:114,'
        'scale=$kVideoWidth:$kVideoHeight:flags=bilinear,setsar=1[back];'
        '[fg]scale=$kVideoWidth:$kVideoHeight:force_original_aspect_ratio=decrease,'
        'scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=1[front];'
        '[back][front]overlay=x=$moveX:y=$moveY'
        '$captionPart$fadePart,format=yuv420p[v]';

    final session = await FFmpegKit.executeWithArguments([
      '-loop', '1',
      '-i', imagePath,
      if (caption != null) ...['-i', caption],
      '-t', seconds.toStringAsFixed(3),
      '-filter_complex', filter,
      '-map', '[v]',
      '-r', '$kFps',
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-crf', '26',
      '-pix_fmt', 'yuv420p',
      '-y', outPath,
    ]);

    await _check(session, 'Rendering image ${index + 1} failed');
    if (!await File(outPath).exists()) {
      throw Exception('Image ${index + 1} produced no clip.');
    }
  }

  /// One picture in the Moment look: the photo card laid over its blurred backdrop.
  ///
  /// All the drawing already happened in Flutter, so this is two still images and one
  /// overlay — no blur, rotate or blend filters, and nothing a phone's FFmpeg can be
  /// missing. The card moves with the Movement setting; the backdrop stays put, which
  /// is what makes it read as a print held over a table rather than a zooming picture.
  static Future<void> _renderMomentClip({
    required MomentFrame frame,
    required String outPath,
    required double seconds,
    required int index,
    required bool isFirst,
    required bool isLast,
    ClipMotion motion = ClipMotion.drift,
  }) async {
    for (final f in [frame.backgroundPng, frame.cardPng]) {
      if (!await File(f).exists()) {
        throw Exception('Picture ${index + 1} was not framed: $f is missing.');
      }
    }
    await _deleteIfExists(outPath);

    final fades = <String>[];
    if (isFirst) fades.add('fade=t=in:st=0:d=0.5');
    if (isLast) {
      final from = (seconds - 0.6) < 0 ? 0.0 : seconds - 0.6;
      fades.add('fade=t=out:st=${from.toStringAsFixed(2)}:d=0.6');
    }
    final fadePart = fades.isEmpty ? '' : ',${fades.join(',')}';

    final swing = index.isEven ? 1 : -1;
    final filter =
        '[0:v]scale=$kVideoWidth:$kVideoHeight,setsar=1[back];'
        '[back][1:v]overlay=x=${_motionX(motion, swing)}:y=${_motionY(motion, swing)},'
        'format=yuv420p$fadePart[v]';

    final session = await FFmpegKit.executeWithArguments([
      '-loop', '1', '-i', frame.backgroundPng,
      '-loop', '1', '-i', frame.cardPng,
      '-t', seconds.toStringAsFixed(3),
      '-filter_complex', filter,
      '-map', '[v]',
      '-r', '$kFps',
      // Identical to the plain clips, because the join is a stream copy and a clip
      // encoded differently breaks it at the seam.
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-crf', '26',
      '-pix_fmt', 'yuv420p',
      '-y', outPath,
    ]);

    await _check(session, 'Rendering picture ${index + 1} failed');
    if (!await File(outPath).exists()) {
      throw Exception('Picture ${index + 1} produced no clip.');
    }
  }

  /// The closing card: the brand PNG over a blurred copy of the last picture.
  ///
  /// Encoder settings are copied from _renderClip word for word, and have to be — the
  /// join below is a stream copy, and a clip encoded even slightly differently either
  /// fails the concat or plays as a glitch at the seam.
  static Future<void> _renderEndCard({
    required String imagePath,
    required String brandPng,
    required String outPath,
    required double seconds,
  }) async {
    await _deleteIfExists(outPath);

    final fadeOutFrom = (seconds - 0.6) < 0 ? 0.0 : seconds - 0.6;

    // Same shrink-and-blow-up trick as the picture clips use for their backdrop, so
    // this needs no blur filter either.
    final filter =
        '[0:v]scale=64:114:force_original_aspect_ratio=increase,crop=64:114,'
        'scale=$kVideoWidth:$kVideoHeight:flags=bilinear,setsar=1[back];'
        '[back][1:v]overlay=x=0:y=0,'
        'fade=t=in:st=0:d=0.4,'
        'fade=t=out:st=${fadeOutFrom.toStringAsFixed(2)}:d=0.6,'
        'format=yuv420p[v]';

    final session = await FFmpegKit.executeWithArguments([
      '-loop', '1', '-i', imagePath,
      '-loop', '1', '-i', brandPng,
      '-t', seconds.toStringAsFixed(3),
      '-filter_complex', filter,
      '-map', '[v]',
      '-r', '$kFps',
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-crf', '26',
      '-pix_fmt', 'yuv420p',
      '-y', outPath,
    ]);

    await _check(session, 'Rendering the end card failed');
  }

  /// Joins the clips. They all come out of the step above with identical settings,
  /// so this is a stream copy — no re-encoding, and quick even on a phone.
  static Future<void> _concat({
    required List<String> clipPaths,
    required String workDir,
    required String outPath,
  }) async {
    final listPath = '$workDir/clips.txt';
    // The concat demuxer reads its inputs from a text file, one quoted path per line.
    // These are all our own temp files, so the paths can't contain anything awkward.
    final lines = clipPaths.map((p) => "file '$p'").join('\n');
    await File(listPath).writeAsString('$lines\n');
    await _deleteIfExists(outPath);

    final session = await FFmpegKit.executeWithArguments([
      '-f', 'concat',
      '-safe', '0',
      '-i', listPath,
      '-c', 'copy',
      '-y', outPath,
    ]);

    await _check(session, 'Joining the clips failed');
  }

  /// Lays the narration over the silent slideshow, with music under it when chosen.
  static Future<void> _addAudio({
    required String videoPath,
    required String audioPath,
    required String outPath,
    String? musicPath,
  }) async {
    await _deleteIfExists(outPath);

    final music = (musicPath != null && await File(musicPath).exists())
        ? musicPath
        : null;

    // normalize=0 matters more than it looks: amix divides every input by the number
    // of inputs by default, so adding music would quietly halve the narration. The
    // usual "why did the voice go quiet when I added music" bug.
    //
    // aloop keeps a short track going for a longer reel; duration=first ties the mix
    // to the narration, which is already what decides the video's length.
    final mixFilter = '[1:a]volume=1.0[voice];'
        '[2:a]aloop=loop=-1:size=2e9,volume=$kMusicGain[music];'
        '[voice][music]amix=inputs=2:duration=first:'
        'dropout_transition=0:normalize=0[out]';

    final session = await FFmpegKit.executeWithArguments([
      '-i', videoPath,
      '-i', audioPath,
      if (music != null) ...['-i', music],
      '-map', '0:v:0',
      if (music != null) ...['-filter_complex', mixFilter, '-map', '[out]']
      else ...['-map', '1:a:0'],
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-b:a', '128k',
      // Video runs a little past the audio by design (the tail), so don't use -shortest.
      '-movflags', '+faststart',
      '-y', outPath,
    ]);

    await _check(session, music == null
        ? 'Adding the voice failed'
        : 'Mixing the voice and music failed');
  }

  /// FFmpeg reports failure through the return code, not an exception — without this
  /// a failed step carries on silently and the error only shows up as a missing file.
  static Future<void> _check(dynamic session, String what) async {
    final rc = await session.getReturnCode();
    if (!ReturnCode.isSuccess(rc)) {
      final logs = await session.getAllLogsAsString() ?? '';
      final tail = logs.length > 1200 ? logs.substring(logs.length - 1200) : logs;
      throw Exception('$what.\n$tail');
    }
  }

  static Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  static Future<void> _deleteWhere(String dir, bool Function(String name) match) async {
    final directory = Directory(dir);
    if (!await directory.exists()) return;
    await for (final entity in directory.list()) {
      if (entity is File && match(entity.uri.pathSegments.last)) {
        await entity.delete();
      }
    }
  }
}
