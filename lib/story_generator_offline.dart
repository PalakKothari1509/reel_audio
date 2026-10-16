import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

class StoryTemplate {
  final String title;
  final String problem;
  final String twist;
  final String worse;
  final String solution;
  final String endingLine;
  final String moral;
  final String where;

  const StoryTemplate({
    required this.title,
    required this.problem,
    required this.twist,
    required this.worse,
    required this.solution,
    required this.endingLine,
    required this.moral,
    required this.where,
  });
}

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

  static final List<StoryTemplate> _templates = [
    StoryTemplate(
      title: 'Plate Patana',
      problem: 'Ria plate mein khana rakhti thi, par jab Mumma ne dekha toh plate zameen par gir gayi.',
      twist: 'Rio ne bhi apni plate Rakhi ki, lekin uska bhi gir gaya.',
      worse: 'Cuty ne bhi apni chinti maang ke khana khane ki koshish karni padi.',
      solution: 'Teeno milke plate utha kar khud hi saaf kar liye — bina kisi ladai ke.',
      endingLine: 'Phir se khaana khayenge saaf-majmoon plate par, haan kehte hue, "Theek hai na Mama?"',
      moral: 'Saath milkar kaam karo toh koi bhi problem aasani se hal ho jati hai.',
      where: 'Indian home kitchen, warm morning light',
    ),
    StoryTemplate(
      title: 'Shoe Bandhani',
      problem: 'Rio apni jootiyein paheli pahli pehnna chaaha, lekin dono jooti ek doosre ke saath juite hue the.',
      twist: 'Ria ne bhi apni jooti pehnne ki koshish ki, lekin ek jooti kahaani thi.',
      worse: 'Cuty ne bhi apni bunni chinti se koshish ki, aur woh bhi ek taraf gir gayi.',
      solution: 'Mumma ne do minute mein teeno jooti jod di — ek joota hai, doosra doosre ke saath.',
      endingLine: 'Jab sab milti bante jooti maang liye, Rio haanke maaf karte hue, "Mujhe jooti pehnna ata nahi!"',
      moral: 'Jab saab milkar jooti jod lein, toh koi bhi single joota alag nahi lagta.',
      where: 'Hallway near the shoe rack, afternoon sunlight',
    ),
    StoryTemplate(
      title: 'Toy Sharing',
      problem: 'Ria aur Rio dono ek hi toy car ko pakad kar khushboo mein latke the.',
      twist: 'Jab Mumma ne ek ko diya toh doosre ne usse bhi pakad li.',
      worse: 'Tension badh gayi jab dono sirhathon se lade aur car beech mein gir gayi.',
      solution: 'Cuty ne car ko ghoont aake Ria ke saamne rakh di, phir Rio ke saamneh, phir dono ke beech.',
      endingLine: 'Car khelne lagi jab Cuty ne usse beech mein rakh kar diya — "Ek do pal ke liye, dono ke liye!"',
      moral: 'Share karne se toy gam nahi hota, saath khelne se toh mazaa hi kuchh aur hota hai.',
      where: 'Living room floor, soft evening light through the window',
    ),
    StoryTemplate(
      title: 'Vegetable Drama',
      problem: 'Rio ne bhi kaha — "Gobhi nahi khaoongi!" — jab Mumma ne gobhi rakhi.',
      twist: 'Ria ne bhi gobhi dekhi aur bhi keh li — "Yeh Mummy ke saath nahi khayenge!"',
      worse: 'Cuty bhi gobhi ke saath baithi, jaise usse bhi pakad liya ho.',
      solution: 'Mumma ne ek gobhi ko "Bachcha" ka naam rakha, ek ko "Rider" — dono hi khush ho gaye.',
      endingLine: 'Jab gobhi khate samay Rio haanke poochha, "Bachcha aur Rider kya hote hain?"',
      moral: 'Jab koi bhi cheez thoda maza aa jata hai, tabhi toh woh khayi jati hai.',
      where: 'Dining table, warm afternoon light',
    ),
    StoryTemplate(
      title: 'Brushing Battle',
      problem: 'Ria ne brush pakda, par turant se poochh li — "Mujhe brush nahi karna!"',
      twist: 'Rio ne dekha aur bhi maan li — "Main karenge, main toh badi bacchi hoon!"',
      worse: 'Lekin Rio brush sirf paani mein hi ghoont kar raha tha, paste nahi laga.',
      solution: 'Cuty ne apni chinti se brush utha kar dono ke beech lekar jaa kar dikhali — dono hi brush karni padhi.',
      endingLine: 'Dono brush karne lagi jab Cuty ne dikhaya — "Daant bhi toh brush se saaf hoti hai!"',
      moral: 'Jab koi aur dikhaye gaal, toh brush bhi khelke lag jata hai.',
      where: 'Bathroom, soft morning light from window',
    ),
    StoryTemplate(
      title: 'Park Se Nikalna',
      problem: 'Ria ne kaha — "Main yahan nahi jaungi park se!" jab papa ne time khatam kaha.',
      twist: 'Rio ne rona dala — "Mujhe bhi nahi jaana!" — dono bachche jameen par baith gaye.',
      worse: 'Cuty bhi gir ke gir gaya, jaise sabse pehle hi haar maan liya ho.',
      solution: 'Papa ne ek chhota sa game shuru kiya — "Jiska pehla step niklega, wohi jeeti ka countdown karega."',
      endingLine: 'Jab dono ek saath park ke bahar nikal liye, Rio haanke kaha, "Next time, pehle maine kaha tha!"',
      moral: 'Game toh game hota hai, lekin har game ek nayi baat sunane dega.',
      where: 'Park entrance, golden hour light',
    ),
    StoryTemplate(
      title: 'The Toy Car Share',
      problem: 'Ria and Rio both grabbed the same red-yellow toy car and tugged in opposite directions on the living room rug.',
      twist: 'When Mummy handed it to one, the other grabbed it too — and the car went flying.',
      worse: 'Both children froze in shocked silence as the car rolled away toward the kitchen doorway.',
      solution: 'They took a breath, looked at each other, and agreed to roll the car right down the middle together.',
      endingLine: 'Ria beamed: "Ho gaya! Theek hai na Mama?"',
      moral: 'Sharing something means twice the fun, not twice the fight.',
      where: 'Indian living room, warm morning light',
    ),
    StoryTemplate(
      title: 'The Block Tower',
      problem: 'Rio carefully balanced the final wooden block on a tall colorful tower while afternoon sun streamed through the window.',
      twist: 'Ria toddled over to get a better look, accidentally bumping the base of the tower with her shoe.',
      worse: 'The blocks scattered across the carpet in a wooden thunder, and Cuty instinctively ducked.',
      solution: 'Instead of crying, Rio started giggling — the fallen blocks could become a flat playhouse instead of a tall tower.',
      endingLine: 'Ria clapped: "Mama, humne naya ghar banaya!"',
      moral: 'A mistake is just a new game waiting to be named.',
      where: 'Living room play corner, afternoon sunlight',
    ),
    StoryTemplate(
      title: 'The Snack Reach',
      problem: 'A bright snack box sat just out of reach on the low kitchen counter ledge, and Ria stretched on tiptoes trying to grab it.',
      twist: 'No matter how hard she stretched, her tiptoes barely made it halfway to the box.',
      worse: 'Rio watched from behind, wanting a snack too, but neither could reach alone.',
      solution: 'Rio stepped up behind Ria, placing his hands firmly on her waist to steady her — together they grabbed the snack.',
      endingLine: 'Ria said: "Ho gaya! Theek hai na Mama?"',
      moral: 'When you lift each other up, even high shelves become easy.',
      where: 'Indian kitchen, bright morning sunlight',
    ),
    StoryTemplate(
      title: 'Night Before Annual Day',
      problem: 'At 9:30 PM, Ria casually dropped the bombshell — tomorrow was Annual Day and she needed a yellow costume and cardboard sunflower prop.',
      twist: 'While Papa frantically glued cardboard petals at midnight, Mummy forgot all the dance steps during rehearsal.',
      worse: 'Rio tangled Mummy in the curtain trying to "help," and Cuty scattered yellow paint smudges everywhere.',
      solution: 'By morning, the costume was perfect and the prop stood tall — and the kids took all the credit on stage.',
      endingLine: 'Ria and Rio declared: "Dekho! Hum kitne cute lag rahe hain!"',
      moral: 'Even the messiest all-nighter ends when everyone works as a team.',
      where: 'Indian living room, nighttime warm lamps',
    ),
    StoryTemplate(
      title: 'ASMR Cleaning Reel',
      problem: 'Mummy found the living room in complete chaotic toddler disarray — crayons, blocks, cushions, and snack bowls scattered everywhere.',
      twist: 'As Mummy rolled up her sleeves and began the satisfying deep clean, the soundscape filled with crisp latch clicks and block clatter.',
      worse: 'Mummy sat back on the now-pristine sofa with her chai in pure bliss — only to push open the bedroom door to a brand-new storm.',
      solution: 'Ria and Rio had built a pillow fort wearing saucepan hats, beaming as they announced: "Mumma dekho! Humne naya tent banaya!"',
      endingLine: 'Mummy held her chai frozen: "Maine abhi toh poora ghar saaf kiya tha...!"',
      moral: 'Ten minutes of peace and a lifetime of love — perfectly balanced.',
      where: 'Indian living room and bedroom, soft morning daylight',
    ),
  ];

  GeneratedStory generate({String? customProblem, String? customAge}) {
    final template = _templates[_rng.nextInt(_templates.length)];
    final who = _selectCharacters();
    final hookText = _buildHook(template, who);
    final hookOptions = _buildHookOptions(template, hookText);

    return GeneratedStory(
      title: template.title,
      hook: hookText,
      who: who,
      where: template.where,
      problem: template.problem,
      twist: template.twist,
      worse: template.worse,
      solution: template.solution,
      endingLine: template.endingLine,
      moral: template.moral,
      hookOptions: hookOptions,
    );
  }

  String _selectCharacters() {
    final count = 2 + _rng.nextInt(3);
    final shuffled = List<String>.from(_characters)..shuffle(_rng);
    return shuffled.take(count).join(', ');
  }

  String _buildHook(StoryTemplate t, String who) {
    final hooks = [
      '${t.title} Ne Kya Dekha?!',
      'Mumma Ne Kaha — ${t.title}!',
      '${t.worse.split(" ").first} — Phir Kya Hua?!',
      '${who.split(", ").first} Ne ${t.problem.split(" ").first}!',
    ];
    return hooks[_rng.nextInt(hooks.length)];
  }

  List<Map<String, String>> _buildHookOptions(StoryTemplate t, String hook) {
    final base = hook;
    final seen = <String>{};
    final options = <Map<String, String>>[];

    final candidates = [
      {'type': 'Curiosity', 'text': '${t.title} Ne Kya Dekha?!'},
      {'type': 'Parent relatable', 'text': base},
      {'type': 'Situation', 'text': '${t.worse.split(" ").first} Toh Problem Ho Gayi!'},
      {'type': 'Mystery', 'text': 'Phir Kya Hua?!'},
      {'type': 'Emotional', 'text': 'Dekhte Hi ${t.problem.split(" ").first}...!'},
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
