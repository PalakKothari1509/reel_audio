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

/// Where a caption sits, as a share of frame height from the top. Low enough to clear
/// a face, high enough to stay above Instagram's own overlay at the bottom.
const double kCaptionFromTop = 0.70;

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
    void Function(String message)? onStatus,
  }) async {
    if (imagePaths.isEmpty) throw Exception('Add at least one image first.');
    if (lineStarts.isEmpty) throw Exception('There are no script lines to show images against.');
    if (!await File(audioPath).exists()) throw Exception('Save the voice before building the video.');

    // The narration decides the length of the video, so the two can never disagree.
    final narration = await getMediaDuration(audioPath);
    if (narration == null) throw Exception('Could not read the narration audio.');
    final totalSeconds = narration + kTailSeconds;

    final durations = clipDurations(lineStarts: lineStarts, totalSeconds: totalSeconds);

    // Anything left from an earlier attempt would be picked up by the concat list below.
    await _deleteWhere(workDir, (name) => name.startsWith('clip_') && name.endsWith('.mp4'));

    final clipPaths = <String>[];
    for (int i = 0; i < durations.length; i++) {
      onStatus?.call('Rendering image ${i + 1} of ${durations.length}...');
      final clipPath = '$workDir/clip_$i.mp4';
      await _renderClip(
        imagePath: imageForLine(imagePaths, i),
        outPath: clipPath,
        seconds: durations[i],
        index: i,
        isFirst: i == 0,
        isLast: i == durations.length - 1,
        captionPng: i < captionPngs.length ? captionPngs[i] : null,
      );
      clipPaths.add(clipPath);
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
    // Drift alternates direction per image so a long reel doesn't slide one way.
    final drift = index.isEven ? 1 : -1;

    // The caption comes in as input 1 and goes on AFTER the drift, so it stays still
    // while the picture moves behind it — a caption that floats is hard to read. The
    // fade still covers both, because it is applied after this.
    final captionPart = caption == null
        ? ''
        : "[withpic];[withpic][1:v]overlay=x='(W-w)/2':"
          "y='H*$kCaptionFromTop-h/2'";

    final filter =
        '[0:v]split=2[bg][fg];'
        '[bg]scale=64:114:force_original_aspect_ratio=increase,crop=64:114,'
        'scale=$kVideoWidth:$kVideoHeight:flags=bilinear,setsar=1[back];'
        '[fg]scale=$kVideoWidth:$kVideoHeight:force_original_aspect_ratio=decrease,'
        'scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=1[front];'
        "[back][front]overlay=x='(W-w)/2':"
        "y='(H-h)/2+$drift*14*sin(2*PI*t/9)'"
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
