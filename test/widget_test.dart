// The default Flutter template test referenced MyApp, which this app does not have,
// so it failed to compile. Replaced with a real check of the script parser — the part
// most likely to break, since Gemini's output is never quite the same twice.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/creator_home.dart';
import 'package:reel_audio/main.dart';
import 'package:reel_audio/quick_content.dart';

void main() {
  testWidgets('home screen opens the promotion comments vault', (tester) async {
    var openedComments = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CreatorHomeScreen(
          onReel: () {},
          onTrialReel: () {},
          onCarousel: () {},
          onSingleImage: () {},
          onMultiFormat: () {},
          onIdeaVault: () {},
          onSavedStories: () {},
          onSettings: () {},
          onPromoComments: () => openedComments = true,
          // Required, and omitting it failed the whole file to compile, so none of
          // these seven tests could run. The dashboard gained a Caption Generator
          // entry and the constructor was widened; nothing updated this file.
          onCaptionGenerator: () {},
        ),
      ),
    );

    expect(find.text('Create Content'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Promotion Comments'),
      250,
      scrollable: find.descendant(
        of: find.byType(CreatorHomeScreen),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Promotion Comments'), findsOneWidget);
    await tester.tap(find.text('Promotion Comments'));
    expect(openedComments, isTrue);
  });

  test('loads promotion comments saved in the legacy string format', () {
    final comments = PromoCommentStore.decode([
      'A legacy comment',
      {'text': 'A bucketed comment', 'bucket': 'reels'},
      '',
      42,
    ]);

    expect(comments, hasLength(2));
    expect(comments.first.text, 'A legacy comment');
    expect(comments.last.text, 'A bucketed comment');
    expect(comments.last.bucket, 'reels');
  });

  testWidgets('promotion vault renders comments as wrapping rows', (
    tester,
  ) async {
    // Seeded, because the vault loads through `path_provider` and that future never
    // completes in a widget test. Without this the screen stays in its loading state
    // and renders no rows at all.
    await tester.pumpWidget(
      MaterialApp(
        home: PromoCommentVaultScreen(
          seed: [
            PromoComment(
              text: 'A comment long enough that it has to wrap across more than one '
                  'line so the wrapping row layout is actually exercised',
              bucket: 'reels',
            ),
            const PromoComment(text: 'Short one'),
          ],
        ),
      ),
    );
    // Bounded pumps, not pumpAndSettle: the vault shows a progress indicator while it
    // reads, and that indicator never resolves under test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('A comment long enough'), findsOneWidget);
    expect(find.text('Short one'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting a promotion comment asks for confirmation first',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PromoCommentVaultScreen(
          seed: [const PromoComment(text: 'A saved line someone relies on')],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Delete comment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The dialog quotes the comment, so the user can confirm they are
    // deleting the line they think they are.
    expect(find.text('Delete this comment?'), findsOneWidget);
    expect(
      find.textContaining('A saved line someone relies on'),
      findsWidgets,
    );

    // Cancel is the safe path: a mis-tap must not remove the comment.
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Delete this comment?'), findsNothing);
    expect(find.text('A saved line someone relies on'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Idea Vault opens the add idea form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IdeaInboxScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Add idea'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Add New Idea'), findsOneWidget);
    expect(find.text('Save Idea'), findsOneWidget);
  });

  test('reads timestamped lines and puts them in order', () {
    final lines = parseScript('0:08 Rio bhi aa gaya\n0:00 Ek baar ki baat hai');

    expect(lines.length, 2);
    expect(lines.first.text, 'Ek baar ki baat hai');
    expect(lines.last.time, const Duration(seconds: 8));
  });

  test('ignores bullets and numbering that Gemini sometimes adds', () {
    final lines = parseScript(
      '* 0:04 Ria ne dekha ek titli\nsome stray explanation',
    );

    expect(lines.length, 1);
    expect(lines.first.text, 'Ria ne dekha ek titli');
  });

  test('splits Hinglish to read from Devanagari to speak', () {
    final lines = parseScript('0:00 Ek baar ki baat hai | एक बार की बात है');

    expect(lines.first.text, 'Ek baar ki baat hai');
    expect(lines.first.spoken, 'एक बार की बात है');
  });

  test('a line with no Devanagari half is spoken as written', () {
    final lines = parseScript('0:00 Once upon a time');

    expect(lines.first.speak, isNull);
    expect(lines.first.spoken, 'Once upon a time');
  });
}
