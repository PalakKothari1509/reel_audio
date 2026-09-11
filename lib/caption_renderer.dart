import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'prompts.dart';
import 'video_builder.dart';

// ── Captions ──────────────────────────────────────────────────────────────────
//
// Each caption is drawn by Flutter and saved as a transparent PNG, which FFmpeg then
// lays over the clip.
//
// Not FFmpeg's own drawtext, and the reason matters: drawtext does no complex-script
// shaping unless the build happens to include HarfBuzz. Devanagari needs it — without
// it conjuncts and matras land in the wrong places and "क्यूटी" comes out mangled.
// A caption feature that breaks in the one language it is for is worse than none.
//
// Flutter shapes Devanagari correctly already, and drawing it here also means the
// styling is ordinary Flutter code rather than escaped filter strings.

/// White rounded box with a black border, the style the reels already use.
class CaptionStyle {
  /// Share of the frame width the caption may fill.
  ///
  /// Taken from the safe width rather than set here: it is not a look, it is how wide
  /// the caption can be before Instagram's own buttons cover the end of every line.
  static const double widthFraction = kSafeCaptionWidth;
  static const double fontSize = 54;
  static const double borderWidth = 5;
  static const double cornerRadius = 26;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 34, vertical: 22);
  // Where it sits on screen is CaptionSpot in video_builder.dart — the overlay filter
  // is what actually places it, so the position lives with the filter.
}

/// Draws one caption and returns the PNG path, or null when there's nothing to draw.
Future<String?> renderCaptionPng({
  required String text,
  required String outPath,
}) async {
  final caption = text.trim();
  if (caption.isEmpty) return null;

  final maxTextWidth = kVideoWidth * CaptionStyle.widthFraction -
      CaptionStyle.padding.horizontal;

  final painter = TextPainter(
    text: TextSpan(
      text: caption,
      style: const TextStyle(
        color: Colors.black,
        fontSize: CaptionStyle.fontSize,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    // Four rather than three: the box is narrower now that it has to clear the button
    // column, so the same line of Hinglish wraps once more than it used to and three
    // would start cutting real words off the end.
    maxLines: 4,
    ellipsis: '…',
  )..layout(maxWidth: maxTextWidth);

  final boxWidth = painter.width + CaptionStyle.padding.horizontal;
  final boxHeight = painter.height + CaptionStyle.padding.vertical;

  // Half the border sits outside the rounded rectangle, so leave room or it clips.
  final pad = CaptionStyle.borderWidth;
  final imageWidth = (boxWidth + pad * 2).ceil();
  final imageHeight = (boxHeight + pad * 2).ceil();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final box = RRect.fromRectAndRadius(
    Rect.fromLTWH(pad, pad, boxWidth, boxHeight),
    const Radius.circular(CaptionStyle.cornerRadius),
  );

  canvas.drawRRect(box, Paint()..color = Colors.white);
  canvas.drawRRect(
    box,
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = CaptionStyle.borderWidth,
  );

  painter.paint(
    canvas,
    Offset(pad + CaptionStyle.padding.left, pad + CaptionStyle.padding.top),
  );

  final image = await recorder.endRecording().toImage(imageWidth, imageHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) return null;

  final file = File(outPath);
  if (await file.exists()) await file.delete();
  await file.writeAsBytes(bytes.buffer.asUint8List());
  return outPath;
}

// ── The end card ──────────────────────────────────────────────────────────────

/// The closing card, drawn full frame: name, a rule, tagline, over a dark scrim.
///
/// The scrim is part of the PNG rather than an FFmpeg filter on purpose. Darkening in
/// the filter graph means depending on `eq` being compiled into whichever ffmpeg build
/// ships with the app; drawing it here cannot fail on a device that was built without
/// it, and it costs nothing.
///
/// Same on every reel, which is the entire point of it — a closing card that varies is
/// decoration, one that repeats is a channel people start to recognise.
Future<String?> renderBrandCard(String outPath) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final w = kVideoWidth.toDouble();
  final h = kVideoHeight.toDouble();

  // Not fully opaque: the last picture stays faintly visible behind it, so the reel
  // ends in the story rather than cutting to a title screen.
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
    Paint()..color = Colors.black.withOpacity(0.76));

  TextPainter line(String text, double size, FontWeight weight, Color colour) =>
      TextPainter(
        text: TextSpan(text: text,
          style: TextStyle(color: colour, fontSize: size, fontWeight: weight, height: 1.2)),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w * 0.84);

  final name = line(kBrandName, 74, FontWeight.w900, Colors.white);
  final tagline = line(kBrandTagline, 40, FontWeight.w600, Colors.tealAccent);

  // Sat a little above centre: the eye reads the top half of a frame first, and the
  // bottom of a reel is where Instagram puts its own username and caption.
  final blockHeight = name.height + 34 + tagline.height;
  final top = h * 0.42 - blockHeight / 2;

  name.paint(canvas, Offset((w - name.width) / 2, top));

  final ruleY = top + name.height + 17;
  canvas.drawRect(
    Rect.fromLTWH(w / 2 - 90, ruleY, 180, 3),
    Paint()..color = Colors.tealAccent.withOpacity(0.85),
  );

  tagline.paint(canvas, Offset((w - tagline.width) / 2, ruleY + 17));

  final image = await recorder.endRecording().toImage(kVideoWidth, kVideoHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) return null;

  final file = File(outPath);
  if (await file.exists()) await file.delete();
  await file.writeAsBytes(bytes.buffer.asUint8List());
  return outPath;
}

/// Draws one caption per script line and returns their paths, nulls included so the
/// list still lines up with the lines.
Future<List<String?>> renderCaptions({
  required List<String> lines,
  required String workDir,
}) async {
  final paths = <String?>[];
  for (var i = 0; i < lines.length; i++) {
    paths.add(await renderCaptionPng(
      text: lines[i],
      outPath: '$workDir/caption_$i.png',
    ));
  }
  return paths;
}
