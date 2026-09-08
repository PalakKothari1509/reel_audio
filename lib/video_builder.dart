import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

// ── Video settings ────────────────────────────────────────────────────────────

/// Portrait 1080x1920 — the shape Reels, Shorts and TikTok expect.
const int kVideoWidth = 1080;
const int kVideoHeight = 1920;
const int kFps = 30;

/// Shortest a single image may stay on screen, so a fast line can't flash past.
const double kMinClipSeconds = 1.0;

/// Held after the last spoken word so the video doesn't cut on the final syllable.
const double kTailSeconds = 1.5;

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
      );
      clipPaths.add(clipPath);
    }

    onStatus?.call('Joining ${clipPaths.length} clips...');
    final silentPath = '$workDir/slideshow_silent.mp4';
    await _concat(clipPaths: clipPaths, workDir: workDir, outPath: silentPath);

    onStatus?.call('Adding the voice...');
    final finalPath = '$workDir/reel_slideshow.mp4';
    await _addAudio(videoPath: silentPath, audioPath: audioPath, outPath: finalPath);

    return finalPath;
  }

  /// One still image as a clip, with a slow zoom so it never looks frozen.
  static Future<void> _renderClip({
    required String imagePath,
    required String outPath,
    required double seconds,
    required int index,
  }) async {
    if (!await File(imagePath).exists()) {
      throw Exception('Image ${index + 1} is missing: $imagePath');
    }
    await _deleteIfExists(outPath);

    final frames = (seconds * kFps).round().clamp(kFps, 100000);
    final fadeOutAt = (seconds - 0.4) < 0 ? 0.0 : seconds - 0.4;

    // Scaled to double size before zoompan on purpose: zooming a 1080-wide source
    // straight to 1080 output makes the pan judder, because zoompan can only step in
    // whole source pixels. Alternate images zoom in and out so a long reel doesn't
    // feel like it's marching in one direction.
    final zoomIn = index.isEven;
    final zoomExpr = zoomIn
        ? "'min(zoom+0.0007,1.25)'"
        : "'if(lte(zoom,1.0),1.25,max(1.001,zoom-0.0007))'";

    final filter = 'scale=${kVideoWidth * 2}:${kVideoHeight * 2}'
        ':force_original_aspect_ratio=increase,'
        'crop=${kVideoWidth * 2}:${kVideoHeight * 2},'
        'zoompan=z=$zoomExpr'
        ":x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)'"
        ':d=$frames:s=${kVideoWidth}x$kVideoHeight:fps=$kFps,'
        'fade=t=in:st=0:d=0.4,'
        'fade=t=out:st=${fadeOutAt.toStringAsFixed(2)}:d=0.4,'
        'format=yuv420p';

    final session = await FFmpegKit.executeWithArguments([
      '-loop', '1',
      '-i', imagePath,
      '-t', seconds.toStringAsFixed(3),
      '-vf', filter,
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

  /// Lays the narration over the silent slideshow.
  static Future<void> _addAudio({
    required String videoPath,
    required String audioPath,
    required String outPath,
  }) async {
    await _deleteIfExists(outPath);

    final session = await FFmpegKit.executeWithArguments([
      '-i', videoPath,
      '-i', audioPath,
      '-map', '0:v:0',
      '-map', '1:a:0',
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-b:a', '128k',
      // Video runs a little past the audio by design (the tail), so don't use -shortest.
      '-movflags', '+faststart',
      '-y', outPath,
    ]);

    await _check(session, 'Adding the voice failed');
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
