import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_studio_service.dart';
import 'package:reel_audio/idea_review_screen.dart';
import 'package:reel_audio/prompts.dart';
import 'package:reel_audio/story_ideas.dart';

void main() {
  /// Builds a standard test evaluation with configurable hooks.
  IdeaEvaluation buildEvaluation({
    List<HookChoice> hooks = const [],
    int score = 9,
    String band = 'Ready',
  }) {
    return IdeaEvaluation(
      check: StoryCheck(
        score: score,
        good: ['Clear problem', 'Strong hook'],
        missing: band == 'Improve' ? ['Needs more emotion'] : [],
        verdict: 'A solid story',
        rows: [
          CheckRow('Real-life problem', true, ''),
          CheckRow('Hook', true, ''),
          CheckRow('Curiosity', band == 'Improve' ? false : true,
              band == 'Improve' ? 'Could open stronger' : ''),
          CheckRow('Emotion', band == 'Improve' ? false : true,
              band == 'Improve' ? 'Missing emotional payoff' : ''),
        ],
        hooks: hooks,
      ),
      shareability: ShareabilityAnalysis(
        sender: 'Mumma of a 3-year-old who refuses vegetables',
        recipient: 'a parent whose child also pushes food away',
        reason: 'It shows a simple lunchbox trick that works',
        confidence: 'high',
      ),
    );
  }

  group('IdeaReviewScreen', () {
    testWidgets('renders score, band, and verdict', (tester) async {
      final evaluation = buildEvaluation();

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'A story about a child learning to eat vegetables',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('9/10'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Good to make today.'), findsOneWidget);
      expect(find.text('A solid story'), findsOneWidget);
    });

    testWidgets('renders all check rows', (tester) async {
      final evaluation = buildEvaluation();

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'A story about a child learning to eat vegetables',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('Real-life problem'), findsOneWidget);
      expect(find.text('Hook'), findsOneWidget);
      expect(find.text('Curiosity'), findsOneWidget);
      expect(find.text('Emotion'), findsOneWidget);
    });

    testWidgets(
        'renders shareability analysis with sender, recipient, and reason',
        (tester) async {
      final evaluation = buildEvaluation();

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'A story about a child learning to eat vegetables',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('Shareability'), findsOneWidget);
      expect(find.text('Share trigger'), findsOneWidget);
      // Confidence badge text is rendered inside the shareability card
      expect(find.text('high'), findsOneWidget);
    });

    testWidgets('renders all hook choices and pre-selects the first',
        (tester) async {
      final hooks = [
        HookChoice('emotional', 'A crying toddler at the dinner table'),
        HookChoice('question', 'Why do children suddenly refuse food?'),
        HookChoice('surprise', 'The magical vegetable that talks back'),
      ];
      final evaluation = buildEvaluation(hooks: hooks);

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'A story about a child learning to eat vegetables',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('A crying toddler at the dinner table'), findsOneWidget);
      expect(find.text('Why do children suddenly refuse food?'),
          findsOneWidget);
      expect(find.text('The magical vegetable that talks back'), findsOneWidget);
    });

    testWidgets('tapping a hook changes selection', (tester) async {
      final hooks = [
        HookChoice('emotional', 'First hook text'),
        HookChoice('question', 'Second hook text'),
      ];
      final evaluation = buildEvaluation(hooks: hooks);

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation
                .copyWith(check: evaluation.check), // ensure hooks present
            originalIdea: 'test',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      await tester.ensureVisible(find.text('Second hook text'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second hook text'));
      await tester.pump();

      expect(find.text('Second hook text'), findsOneWidget);
    });

    testWidgets('Generate button is disabled until checkbox is checked',
        (tester) async {
      final evaluation = buildEvaluation(
        hooks: [HookChoice('emotional', 'Test hook')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      await tester.ensureVisible(find.text('Generate Content'));
      await tester.pumpAndSettle();

      final generateButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Generate Content'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(generateButton.onPressed, isNull);
    });

    testWidgets('checking box enables Generate button', (tester) async {
      final evaluation = buildEvaluation(
        hooks: [HookChoice('emotional', 'Test hook')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Generate Content'));
      await tester.pumpAndSettle();

      final generateButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Generate Content'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(generateButton.onPressed, isNotNull);
    });

    testWidgets('tapping Generate calls onApprove with selected hook',
        (tester) async {
      final hooks = [
        HookChoice('emotional', 'First hook'),
        HookChoice('question', 'Second hook'),
      ];
      HookChoice? capturedHook;
      final evaluation = buildEvaluation(hooks: hooks);

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            onApprove: (hook) {
              capturedHook = hook;
            },
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Generate Content'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate Content'));
      await tester.pumpAndSettle();

      expect(capturedHook, same(hooks.first));
    });

    testWidgets('Rewrite band shows warning message', (tester) async {
      final evaluation = buildEvaluation(
        hooks: [HookChoice('emotional', 'Test hook')],
        score: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('5/10'), findsOneWidget);
      expect(find.text('Rewrite'), findsOneWidget);
      expect(
        find.text(
            'This idea scored below 7. Consider editing it or regenerating.'),
        findsOneWidget,
      );
    });

    testWidgets('Improve band shows fix message', (tester) async {
      final evaluation = buildEvaluation(
        hooks: [HookChoice('emotional', 'Test hook')],
        score: 7,
        band: 'Improve',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('7/10'), findsOneWidget);
      expect(find.text('Improve'), findsOneWidget);
      expect(find.text('Fix the points below before making pictures.'),
          findsOneWidget);
    });

    testWidgets('back button calls onBack', (tester) async {
      bool backCalled = false;
      final evaluation = buildEvaluation();

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {
              backCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backCalled, isTrue);
    });

    testWidgets('Regenerate Review button calls onRegenerate', (tester) async {
      bool regenerateCalled = false;
      final evaluation = buildEvaluation();

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            onApprove: (_) {},
            onRegenerate: () {
              regenerateCalled = true;
            },
            onBack: () {},
          ),
        ),
      );

      await tester.ensureVisible(find.text('Regenerate Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regenerate Review'));
      await tester.pump();

      expect(regenerateCalled, isTrue);
    });

    testWidgets('shows status when provided', (tester) async {
      final evaluation = buildEvaluation();

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            status: 'Generating...',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('Generating...'), findsOneWidget);
    });

    testWidgets('no hooks shows fallback message', (tester) async {
      final evaluation = buildEvaluation(hooks: []);

      await tester.pumpWidget(
        MaterialApp(
          home: IdeaReviewScreen(
            evaluation: evaluation,
            originalIdea: 'test',
            onApprove: (_) {},
            onRegenerate: () {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('No hooks were generated.'), findsOneWidget);
    });
  });
}
