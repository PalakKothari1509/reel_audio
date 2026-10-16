import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import 'content_ideas.dart';

class GeneratedStory {
  final String title;
  final String hook;
  final String who;
  final String where;
  final String problem;
  final String twist;
  final String worse;
  final String solution;
  final String endingLine;
  final String moral;
  final List<Map<String, String>> hookOptions;

  GeneratedStory({
    required this.title,
    required this.hook,
    required this.who,
    required this.where,
    required this.problem,
    required this.twist,
    required this.worse,
    required this.solution,
    required this.endingLine,
    required this.moral,
    required this.hookOptions,
  });

  GeneratedStory copyWith({
    String? title,
    String? hook,
    String? who,
    String? where,
    String? problem,
    String? twist,
    String? worse,
    String? solution,
    String? endingLine,
    String? moral,
    List<Map<String, String>>? hookOptions,
  }) =>
      GeneratedStory(
        title: title ?? this.title,
        hook: hook ?? this.hook,
        who: who ?? this.who,
        where: where ?? this.where,
        problem: problem ?? this.problem,
        twist: twist ?? this.twist,
        worse: worse ?? this.worse,
        solution: solution ?? this.solution,
        endingLine: endingLine ?? this.endingLine,
        moral: moral ?? this.moral,
        hookOptions: hookOptions ?? this.hookOptions,
      );

  Map<String, dynamic> toJson() => {
    'title': title,
    'hook': hook,
    'who': who,
    'where': where,
    'problem': problem,
    'twist': twist,
    'worse': worse,
    'solution': solution,
    'ending_line': endingLine,
    'moral': moral,
    'hook_options': hookOptions,
  };
}

class StoryGenerator {
  final Random _rng = Random();
  final List<String> _characters = [
    'Ria', 'Rio', 'Cuty', 'Mumma', 'Papa', 'Daadi', 'Teacher'
  ];
  final List<String> _hookTypes = [
    'Curiosity',
    'Parent relatable',
    'Situation',
    'Mystery',
    'Emotional',
  ];

  List<HookIdea> get _available =>
      kDefaultHooks.where((h) => h.forApp && h.storyDetail.trim().isNotEmpty).toList();

  static String _extractLine(String detail, String label) {
    final lines = detail.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith(label)) {
        return trimmed.substring(label.length).trim();
      }
    }
    return '';
  }

  GeneratedStory generate({String? customProblem, String? customAge}) {
    final hooks = _available;
    final h = hooks[_rng.nextInt(hooks.length)];
    final who = _selectCharacters();
    final problem = _extractLine(h.storyDetail, 'Story:');
    final twist = _extractLine(h.storyDetail, 'Twist:');
    final worse = _extractLine(h.storyDetail, 'Resolution:');
    final hookText = _buildHook(h, who);
    final hookOptions = _buildHookOptions(h, hookText);

    return GeneratedStory(
      title: h.cover,
      hook: hookText,
      who: who,
      where: 'at home',
      problem: problem.isNotEmpty ? problem : h.problem,
      twist: twist.isNotEmpty ? twist : _fallbackTwist(h.problem),
      worse: worse.isNotEmpty ? worse : _fallbackWorse(h.problem),
      solution: h.lesson,
      endingLine: _extractLine(h.storyDetail, 'Moral:'),
      moral: h.lesson,
      hookOptions: hookOptions,
    );
  }

  String _fallbackTwist(String problem) {
    final firstWord = problem.split(' ').firstWhere((w) => w.length > 3, orElse: () => 'Something');
    return "But then $firstWord didn't go as planned, making things even harder.";
  }

  String _fallbackWorse(String problem) {
    return "Just when it seemed like it could work, everything fell apart at once.";
  }

  String _selectCharacters() {
    final count = 2 + _rng.nextInt(3);
    final shuffled = List<String>.from(_characters)..shuffle(_rng);
    return shuffled.take(count).join(', ');
  }

  String _buildHook(HookIdea h, String who) {
    final hooks = [
      '${h.cover} Ne Kya Dekha?!',
      'Mumma Ne Kaha — ${h.cover}!',
      '${who.split(", ").first} Ne ${h.problem.split(" ").first}!',
      '${h.cover} — Phir Kya Hua?!',
    ];
    return hooks[_rng.nextInt(hooks.length)];
  }

  List<Map<String, String>> _buildHookOptions(HookIdea h, String hook) {
    final base = hook;
    final seen = <String>{};
    final options = <Map<String, String>>[];

    final candidates = [
      {'type': 'Curiosity', 'text': '${h.cover} Ne Kya Dekha?!'},
      {'type': 'Parent relatable', 'text': base},
      {'type': 'Situation', 'text': '${_firstWord(h.problem)} Toh Problem Ho Gayi!'},
      {'type': 'Mystery', 'text': 'Phir Kya Hua?!'},
      {'type': 'Emotional', 'text': 'Dekhte Hi ${_firstWord(h.problem)}...!'},
    ];

    for (final c in candidates) {
      if (c['text']!.trim().isNotEmpty && seen.add(c['text']!.toLowerCase())) {
        options.add(c);
      }
    }

    while (options.length < 5 && _hookTypes.length > options.length) {
      final idx = options.length;
      options.add({
        'type': _hookTypes[idx % _hookTypes.length],
        'text': base,
      });
    }

    return options.take(5).toList();
  }

  String _firstWord(String s) => s.split(' ').firstWhere((w) => w.length > 3, orElse: () => 'Something');
}

class StoryGeneratorScreen extends StatefulWidget {
  const StoryGeneratorScreen({super.key});

  @override
  State<StoryGeneratorScreen> createState() => _StoryGeneratorScreenState();
}

class _StoryGeneratorScreenState extends State<StoryGeneratorScreen> {
  final StoryGenerator _generator = StoryGenerator();
  GeneratedStory? _story;
  bool _loading = false;

  void _generate() {
    setState(() => _loading = true);
    final story = _generator.generate();
    setState(() {
      _story = story;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story Generator (Offline)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _story == null
              ? Center(
                  child: ElevatedButton(
                    onPressed: _generate,
                    child: const Text('Generate Story (No Internet Needed)'),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_story!.title,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Hook: ${_story!.hook}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _buildField('Who', _story!.who),
                      _buildField('Where', _story!.where),
                      _buildField('Problem', _story!.problem),
                      _buildField('Twist', _story!.twist),
                      _buildField('Worse', _story!.worse),
                      _buildField('Solution', _story!.solution),
                      _buildField('Ending Line', _story!.endingLine),
                      _buildField('Moral', _story!.moral),
                      const SizedBox(height: 16),
                      const Text('Hook Options:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      for (final h in _story!.hookOptions)
                        ListTile(
                            title: Text(h['text']!),
                            subtitle: Text(h['type']!)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _generate,
                        child: const Text('Generate Another')),
                      ElevatedButton(
                        onPressed: () {
                          final json = jsonEncode(_story!.toJson());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('JSON: $json')),
                          );
                        },
                        child: const Text('Export JSON')),
                    ],
                  ),
                ),
    );
  }

  Widget _buildField(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value),
            ],
          ),
        ),
      );
}
