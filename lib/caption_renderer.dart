import 'dart:io';
import 'dart:math' as math;
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
Future<String?> renderBrandCard(
  String outPath, {
  /// What the last screen says, above the brand. One or two paragraphs: the question
  /// first, then the reason to keep the reel.
  ///
  /// One string rather than two named fields because it is one thing you can rewrite,
  /// and splitting it here would mean an edit could only be half applied. The question
  /// leads because a closing screen that asks nothing gets no comments, and comments
  /// are what keep a reel alive after its first hour.
  String message = '',
}) async {
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

  // Split on the blank line between paragraphs, so an edited message keeps the same
  // shape as a generated one without anything here needing to know which it is.
  final parts = message
      .trim()
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim().replaceAll('\n', ' '))
      .where((p) => p.isNotEmpty)
      .toList();

  // The first line biggest. On a closing screen the channel's name is the least
  // interesting thing present — it asks for nothing and gives nothing back.
  final ask = parts.isEmpty ? null : line(parts.first, 58, FontWeight.w800, Colors.white);
  final keep = parts.length < 2
      ? null
      : line(parts.sublist(1).join('  '), 40, FontWeight.w600, Colors.tealAccent);
  final name = line(kBrandName, 46, FontWeight.w800, Colors.white);
  final tagline = line(kBrandTagline, 30, FontWeight.w500, Colors.white70);

  const gapAfterAsk = 40.0;
  const gapAfterKeep = 46.0;
  const gapBeforeName = 14.0;

  var blockHeight = name.height + gapBeforeName + tagline.height;
  if (keep != null) blockHeight += keep.height + gapAfterKeep;
  if (ask != null) blockHeight += ask.height + gapAfterAsk;

  // Sat a little above centre: the eye reads the top half of a frame first, and the
  // bottom of a reel is where Instagram puts its own username and caption.
  var y = h * 0.44 - blockHeight / 2;

  if (ask != null) {
    ask.paint(canvas, Offset((w - ask.width) / 2, y));
    y += ask.height + gapAfterAsk;
  }
  if (keep != null) {
    keep.paint(canvas, Offset((w - keep.width) / 2, y));
    y += keep.height + gapAfterKeep;
  }

  canvas.drawRect(
    Rect.fromLTWH(w / 2 - 70, y - 22, 140, 2),
    Paint()..color = Colors.tealAccent.withOpacity(0.7),
  );

  name.paint(canvas, Offset((w - name.width) / 2, y));
  tagline.paint(canvas, Offset((w - tagline.width) / 2, y + name.height + gapBeforeName));

  final image = await recorder.endRecording().toImage(kVideoWidth, kVideoHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) return null;

  final file = File(outPath);
  if (await file.exists()) await file.delete();
  await file.writeAsBytes(bytes.buffer.asUint8List());
  return outPath;
}

// ── The Moment look ───────────────────────────────────────────────────────────
//
// Each picture becomes a printed photo: shrunk onto a cream card with a thin border,
// tilted a few degrees with a soft shadow, laid over a blurred and washed-out copy of
// the same picture. The caption is written inside the photo in a serif storybook
// face, and the channel's name runs along the bottom of it.
//
// Drawn here rather than in FFmpeg because every part of it is still. Flutter already
// blurs, rotates, shadows and shapes Devanagari properly; doing the same in a filter
// graph would be slower on a phone and would break on any build missing one filter.

/// Photo paper: warm white, not screen white, which looks clinical next to watercolour.
const _paper = Color(0xFFFBF7EF);
const _ink = Color(0xFF3B332B);

/// Draws one picture in the Moment look. Returns null if the picture cannot be read.
Future<MomentFrame?> renderMomentFrame({
  required String imagePath,
  required int index,
  required String workDir,
  /// The line for this picture, written inside the photo. Empty for none.
  String caption = '',
  /// The cover hook PNG for the first picture, drawn in place of the caption.
  String? coverPng,
}) async {
  final picture = await _loadImage(imagePath, 1080);
  if (picture == null) return null;

  final w = kVideoWidth.toDouble();
  final h = kVideoHeight.toDouble();

  // ── The backdrop: the same picture, blurred and washed pale ──
  final backRec = ui.PictureRecorder();
  final back = Canvas(backRec);
  back.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _paper);
  back.saveLayer(Rect.fromLTWH(0, 0, w, h),
    Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36));
  _drawCover(back, picture, Rect.fromLTWH(-40, -40, w + 80, h + 80));
  back.restore();
  // Washed out, so the card is the thing you look at and the backdrop is only mood.
  back.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _paper.withOpacity(0.5));

  // ── The card ──
  final cardRec = ui.PictureRecorder();
  final card = Canvas(cardRec);

  const photoW = 800.0;
  const photoH = photoW * 16 / 9;
  const side = 22.0;
  // A slightly deeper bottom edge, like a real print, which also gives the name room.
  const bottom = 58.0;
  const cardW = photoW + side * 2;
  const cardH = photoH + side + bottom;

  // Alternating tilt, so a run of pictures looks like prints laid down by hand rather
  // than the same frame stamped seven times.
  final angle = (index.isEven ? -1 : 1) * 3.5 * math.pi / 180;

  card.save();
  card.translate(w / 2, h / 2);
  card.rotate(angle);
  card.translate(-cardW / 2, -cardH / 2);

  final cardRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, cardW, cardH), const Radius.circular(6));

  card.drawRRect(
    cardRect.shift(const Offset(10, 20)),
    Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
  );
  card.drawRRect(cardRect, Paint()..color = _paper);

  const photo = Rect.fromLTWH(side, side, photoW, photoH);
  card.save();
  card.clipRect(photo);
  card.drawRect(photo, Paint()..color = const Color(0xFFF1EADF));
  // The whole picture, never cropped: the complaint that started fit-not-fill was
  // heads cut off at the edges, and a smaller frame makes that worse, not better.
  _drawContain(card, picture, photo);
  card.restore();

  // A faint line where the print meets the paper.
  card.drawRect(photo, Paint()
    ..color = const Color(0x14000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5);

  // ── Words inside the photo ──
  if (coverPng != null && await File(coverPng).exists()) {
    final cover = await _loadImage(coverPng, null);
    if (cover != null) {
      final scale = (photoW * 0.9) / cover.width;
      final cw = cover.width * scale;
      final ch = cover.height * scale;
      card.drawImageRect(cover,
        Rect.fromLTWH(0, 0, cover.width.toDouble(), cover.height.toDouble()),
        Rect.fromLTWH(side + (photoW - cw) / 2, side + 40, cw, ch),
        Paint()..filterQuality = FilterQuality.high);
      cover.dispose();
    }
  } else if (caption.trim().isNotEmpty) {
    final text = _storybookText(caption.trim(), 46, FontWeight.w600, FontStyle.normal,
      maxWidth: photoW * 0.84, maxLines: 4);
    text.paint(card, Offset(side + (photoW - text.width) / 2, side + 44));
  }

  // The channel's name on every picture, where the screenshot has it: in italics along
  // the bottom of the photo, between two small flowers.
  final name = _storybookText(kBrandName, 36, FontWeight.w500, FontStyle.italic,
    maxWidth: photoW * 0.8, maxLines: 1);
  final nameY = side + photoH - name.height - 28;
  name.paint(card, Offset(side + (photoW - name.width) / 2, nameY));
  final flowerY = nameY + name.height / 2;
  _flower(card, Offset(side + (photoW - name.width) / 2 - 30, flowerY));
  _flower(card, Offset(side + (photoW + name.width) / 2 + 30, flowerY));

  card.restore();

  final bgPath = await _savePng(backRec, kVideoWidth, kVideoHeight,
    '$workDir/moment_bg_$index.png');
  final cardPath = await _savePng(cardRec, kVideoWidth, kVideoHeight,
    '$workDir/moment_card_$index.png');
  picture.dispose();

  if (bgPath == null || cardPath == null) return null;
  return MomentFrame(bgPath, cardPath);
}

/// Serif, dark, with a soft paper-coloured glow behind it so it reads over a busy
/// patch of the picture without needing the white box the plain captions use.
TextPainter _storybookText(String text, double size, FontWeight weight, FontStyle style,
    {required double maxWidth, required int maxLines}) {
  const glow = Color(0xF2FFFBF3);
  return TextPainter(
    text: TextSpan(text: text, style: TextStyle(
      fontFamily: 'serif',
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      color: _ink,
      height: 1.3,
      shadows: const [
        Shadow(color: glow, blurRadius: 18),
        Shadow(color: glow, blurRadius: 8),
        Shadow(color: glow, blurRadius: 3),
      ],
    )),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
}

/// A small five-petal flower beside the name.
void _flower(Canvas canvas, Offset centre) {
  const petal = Color(0xFFE9A6A6);
  const heart = Color(0xFFE8C26A);
  for (var i = 0; i < 5; i++) {
    final a = i * 2 * math.pi / 5;
    canvas.drawCircle(
      centre + Offset(7 * math.cos(a), 7 * math.sin(a)), 6, Paint()..color = petal);
  }
  canvas.drawCircle(centre, 4.5, Paint()..color = heart);
}

void _drawCover(Canvas canvas, ui.Image image, Rect target) {
  final scale = [target.width / image.width, target.height / image.height]
      .reduce((a, b) => a > b ? a : b);
  _drawScaled(canvas, image, target, scale);
}

void _drawContain(Canvas canvas, ui.Image image, Rect target) {
  final scale = [target.width / image.width, target.height / image.height]
      .reduce((a, b) => a < b ? a : b);
  _drawScaled(canvas, image, target, scale);
}

void _drawScaled(Canvas canvas, ui.Image image, Rect target, double scale) {
  final dw = image.width * scale;
  final dh = image.height * scale;
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(target.left + (target.width - dw) / 2,
      target.top + (target.height - dh) / 2, dw, dh),
    Paint()..filterQuality = FilterQuality.high,
  );
}

/// Reads a picture off disk, shrunk to [width] when given so a 4000-pixel photo from a
/// camera does not take a phone's memory with it.
Future<ui.Image?> _loadImage(String path, int? width) async {
  try {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}

Future<String?> _savePng(
    ui.PictureRecorder recorder, int width, int height, String outPath) async {
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) return null;

  final file = File(outPath);
  if (await file.exists()) await file.delete();
  await file.writeAsBytes(bytes.buffer.asUint8List());
  return outPath;
}

// ── The cover ─────────────────────────────────────────────────────────────────

/// The hook, drawn big across the first picture.
///
/// Its own renderer rather than a bigger caption, because this is the only screen
/// most people ever see: it is the thumbnail. Two to four words at nearly twice the
/// caption size, in a bold panel that survives being shrunk to a grid square.
///
/// Drawn here and not asked of the image generator, for the same reason the captions
/// are: a generator will misspell Hinglish, and a misspelt hook is worse than none.
Future<String?> renderCoverHook(String hook, String outPath) async {
  final text = hook.trim();
  if (text.isEmpty) return null;

  const fontSize = 96.0;
  const padding = EdgeInsets.symmetric(horizontal: 44, vertical: 30);
  const border = 7.0;

  final painter = TextPainter(
    text: TextSpan(text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1.15,
      )),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 3,
    ellipsis: '…',
  )..layout(maxWidth: kVideoWidth * kSafeCaptionWidth - padding.horizontal);

  final boxWidth = painter.width + padding.horizontal;
  final boxHeight = painter.height + padding.vertical;
  final imageWidth = (boxWidth + border * 2).ceil();
  final imageHeight = (boxHeight + border * 2).ceil();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final box = RRect.fromRectAndRadius(
    Rect.fromLTWH(border, border, boxWidth, boxHeight),
    const Radius.circular(30),
  );

  // Dark panel with a white rule, the reverse of the captions, so the cover reads as
  // a different kind of thing at a glance instead of a caption that happens to be big.
  canvas.drawRRect(box, Paint()..color = const Color(0xE6141210));
  canvas.drawRRect(
    box,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = border,
  );

  painter.paint(canvas, Offset(border + padding.left, border + padding.top));

  final image = await recorder.endRecording().toImage(imageWidth, imageHeight);
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
