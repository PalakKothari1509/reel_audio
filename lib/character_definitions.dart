class Character {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String appearance;
  final String personality;
  final String role;
  final String speechPattern;
  final String imagePromptDescription;
  final String referenceDescription;
  final String voice;
  final String promptSpeechPattern;
  final String? assetPath;
  final String? appDisplayName;
  final String? appEmoji;

  const Character({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.appearance,
    required this.personality,
    required this.role,
    this.speechPattern = '',
    required this.imagePromptDescription,
    required this.referenceDescription,
    this.voice = '',
    this.promptSpeechPattern = '',
    this.assetPath,
    this.appDisplayName,
    this.appEmoji,
  });

  String get fullProfile =>
      '''
$name ($emoji)
Role: $role
Appearance: $appearance
Personality: $personality
Description: $description${speechPattern.isEmpty ? '' : '\nSpeech: $speechPattern'}''';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
    'appearance': appearance,
    'personality': personality,
    'role': role,
    'speechPattern': speechPattern,
  };
}

const kRiaDefinition = Character(
  id: 'ria',
  name: 'Ria',
  emoji: '🌸',
  imagePromptDescription:
      "toddler girl, light brown hair in two short pigtails tied with pink bows, "
      "soft fringe across the forehead, large round dark brown eyes with long lashes, "
      "fair skin with rosy cheeks and light freckles, pink short-sleeved tiered dress "
      "covered in small gold stars with pink lace trim on each tier, pink mary-jane shoes, "
      "chubby toddler body proportions",
  referenceDescription:
      "toddler girl, light brown hair in two short pigtails tied with pink bows, "
      "soft fringe across the forehead, large round dark brown eyes with long lashes, "
      "fair skin with rosy cheeks and light freckles, pink short-sleeved tiered dress "
      "covered in small gold stars with pink lace trim on each tier, pink mary-jane shoes, "
      "chubby toddler body proportions",
  description: 'Indian preschool girl, curious and playful',
  appearance: 'Dark brown hair in two ponytails with pink bows, brown eyes, pink dress, no glasses, preschool age (3-4). Toofani: round chubby cheeks and a soft plump build, not thin',
  personality: 'Curious and expressive, energetic and playful, asks questions and leads activities, sometimes stubborn, a little harmless chaos',
  role: 'Protagonist / explorer',
  promptSpeechPattern: 'Negotiates with questions.',
  voice:
      'Full sentences, negotiates, keeps score. '
      'Example: "Main pehle thi. Toh main aakhir mein bhi thi."',
  assetPath: 'assets/characters/Ria.jpg',
  appDisplayName: 'Ria',
  appEmoji: '👧',
);

const kRioDefinition = Character(
  id: 'rio',
  name: 'Rio',
  emoji: '💙',
  imagePromptDescription:
      "toddler boy, tousled medium brown hair, large round amber-brown eyes with "
      "long lashes, fair skin with rosy cheeks, thick dark eyebrows, plain blue-grey "
      "short-sleeved t-shirt, matching blue-grey shorts with a side pocket, black "
      "lace-up sneakers with white soles, chubby toddler body proportions, slightly "
      "taller than Ria",
  referenceDescription:
      "toddler boy, tousled medium brown hair, large round amber-brown eyes with "
      "long lashes, fair skin with rosy cheeks, thick dark eyebrows, plain blue-grey "
      "short-sleeved t-shirt, matching blue-grey shorts with a side pocket, black "
      "lace-up sneakers with white soles, chubby toddler body proportions, slightly "
      "taller than Ria",
  description: 'Indian preschool boy, playful and determined',
  appearance: 'Dark brown hair, blue outfit, brown eyes, no glasses, preschool age (3-4)',
  personality: 'Energetic and playful, naturally stubborn and determined, says "no" before thinking, follows then leads, deep focus when interested',
  role: 'Co-protagonist / problem solver',
  promptSpeechPattern: 'Two-word demands, loud.',
  voice:
      'Two-word demands, loud, refuses once then gives in. '
      'Example: "Mera car. Abhi."',
  assetPath: 'assets/characters/Rio.jpg',
  appDisplayName: 'Rio',
  appEmoji: '👦',
);

const kCutyDefinition = Character(
  id: 'cuty',
  name: 'Cuty',
  emoji: '🐰',
  imagePromptDescription:
      "fluffy white bunny, long upright ears with soft pink inner colouring, "
      "coral-pink fabric bow tied at the neck, very large round dark brown eyes with "
      "lashes, small pink nose, pink blush on both cheeks, chubby rounded body standing "
      "upright like a toddler",
  referenceDescription:
      "fluffy white bunny, long upright ears with soft pink inner colouring, "
      "coral-pink fabric bow tied at the neck, very large round dark brown eyes with "
      "lashes, small pink nose, pink blush on both cheeks, chubby rounded body standing "
      "upright like a toddler",
  description: 'Small white bunny, the peace-bringer',
  appearance:
      'Small white bunny, pink bow, soft friendly expression, unchanged always',
  personality: 'Gentle, quiet observer, calm and sleepy, unbothered, subtle comic relief and warmth, the emotional anchor, never the one who lectures',
  role: 'Mascot / observer',
  promptSpeechPattern: 'Repeats adult words wrongly.',
  voice:
      'Repeats adult words wrongly. '
      'Example: "Gaana khallaam? Phir tumhaari baari."',
  assetPath: 'assets/characters/Cuty.jpg',
  appDisplayName: 'Cuty',
  appEmoji: '🐰',
);

const kRobotDefinition = Character(
  id: 'robot',
  name: 'Robot',
  emoji: '🤖',
  imagePromptDescription:
      "friendly AI robot, white and silver sleek body with soft edges, teal blue "
      "accent lights along the chest and arms, expressive LED screen face that shows "
      "gentle eyes and curious expressions, small retractable arms with precision grippers, "
      "compact and child-height so it can interact at eye level with Ria and Rio",
  description: 'Friendly AI robot.',
  appearance:
      "friendly AI robot, white and silver sleek body with soft edges, teal blue "
      "accent lights along the chest and arms, expressive LED screen face that shows "
      "gentle eyes and curious expressions, small retractable arms with precision grippers, "
      "compact and child-height so it can interact at eye level with Ria and Rio",
  personality: 'Literal, helpful, slightly robotic phrasing.',
  role: 'Supporting character',
  referenceDescription:
      "friendly AI robot, white and silver sleek body with soft edges, teal blue "
      "accent lights along the chest and arms, expressive LED screen face that shows "
      "gentle eyes and curious expressions, small retractable arms with precision grippers, "
      "compact and child-height so it can interact at eye level with Ria and Rio",
  voice:
      'Literal, helpful, slightly robotic phrasing. '
      'Example: "I have calculated the optimal solution: share."',
  promptSpeechPattern: 'Literal, slightly robotic.',
  assetPath: 'assets/characters/Robot.jpg',
);

const kMummaDefinition = Character(
  id: 'mumma',
  name: 'Mumma',
  emoji: '👩',
  imagePromptDescription:
      "young Indian mother, medium brown hair in a high bun with a few loose "
      "strands, fair-medium skin, large dark brown eyes, small red bindi, gold jhumka "
      "earrings, mustard-yellow three-quarter-sleeve kurta with white chikankari "
      "floral embroidery, blue jeans, comfortable smile",
  referenceDescription: "young Indian mother, medium brown hair in a high rounded bun with a few loose strands, fair-medium skin, large dark brown eyes, small red bindi, gold jhumka earrings, mustard-yellow three-quarter-sleeve kurta with white chikankari floral embroidery, blue jeans, brown flip-flop sandals, gentle warm smile",
  description: 'Young Indian mother in her early 30s, warm and patient',
  appearance:
      'Young Indian mother, early 30s, warm brown eyes, gentle radiant smile, '
      'hair neatly styled in a soft high bun with loose face-framing strands, small red bindi '
      'on the forehead. Wearing a mustard yellow kurti with white chikankari embroidery, '
      'classic blue slim-fit jeans, casual brown flat slide sandals. Stylized 3D '
      'Pixar/Disney character design, soft rim lighting, clean white backdrop.',
  personality:
      'Warm, patient and observant. Playfully redirects tantrums rather than '
      'scolding, never lectures. A master of low-cost screen-free household hacks. '
      'Her solutions come from noticing what is already in the kitchen, not from buying '
      'anything.',
  role: 'Warm problem-solver, the parent the viewer identifies with',
  voice:
      'Short Hinglish commands, counts instead of shouting. '
      'Example: "Ek. Do. Teesra bolungi toh rone lagega."',
  promptSpeechPattern: 'Short Hinglish commands, counts.',
  speechPattern:
      'Calm Hinglish, encouraging, warm. Soft terms of endearment such as '
      '"arre mera bachha" and "dekho toh". Never scolding, never impatient.',
  assetPath: 'assets/characters/Mumma.jpg',
  appDisplayName: 'Mum',
  appEmoji: '👩',
);

const kPapaDefinition = Character(
  id: 'papa',
  name: 'Papa',
  emoji: '👨',
  imagePromptDescription:
      "young Indian father, short neat black hair, warm brown eyes, light stubble, "
      "fair skin, light blue full-sleeve kurta with subtle embroidery, "
      "matching pyjama trousers, brown juttis, friendly expression",
  referenceDescription: "young Indian father, short spiky black hair, thick dark eyebrows, light stubble beard, warm tan skin, dark brown eyes, light blue full-sleeve kurta with blue and gold embroidery at the mandarin collar and cuffs, matching light blue pyjama trousers, brown embroidered juttis, friendly closed-mouth smile",
  description: 'Young Indian father in his early 30s, warm and playful',
  appearance:
      'Young Indian father, early 30s, warm brown eyes, soft smile, '
      'dark hair neatly styled with a light stubble. Wearing a half-sleeve '
      'linen shirt in earthy tones, slim-fit jeans, casual brown shoes. '
      'Stylized 3D Pixar/Disney character design, soft rim lighting.',
  personality:
      'Warm, patient and playful. Joins in the children\'s games rather '
      'than directing, adds silly voices and sound effects, defuses tension '
      'with a joke. The calm in the chaos, always ready with a low-cost '
      'household hack.',
  role: 'The calm problem-solver, the parent who joins the fun',
  voice:
      'Over-promises, fixes nothing today. '
      'Example: "Kal subah main theek kar dunga."',
  promptSpeechPattern: 'Over-promises, fixes later.',
  assetPath: 'assets/characters/Papa.jpg',
  appDisplayName: 'Dad',
  appEmoji: '👨',
);

const kDaadiDefinition = Character(
  id: 'daadi',
  name: 'Daadi',
  emoji: '👵',
  imagePromptDescription:
      "Indian grandmother, silver-grey hair in a neat bun, warm tan skin with "
      "soft wrinkles and laugh lines, dark brown eyes behind round gold-rimmed glasses, "
      "small red bindi, gold jhumka earrings, cream saree with gold border, warm "
      "affectionate smile",
  referenceDescription: "Indian grandmother, silver-grey hair in a neat bun, warm tan skin with soft wrinkles and laugh lines, dark brown eyes, round gold-rimmed glasses, small red bindi, gold jhumka earrings, cream saree with a gold woven border and small gold floral motifs, cream embroidered juttis, warm affectionate smile",
  description: 'Indian grandmother.',
  appearance: "Indian grandmother, silver-grey hair in a neat bun, warm tan skin with soft wrinkles and laugh lines, dark brown eyes, round gold-rimmed glasses, small red bindi, gold jhumka earrings, cream saree with a gold woven border and small gold floral motifs, cream embroidered juttis, warm affectionate smile",
  personality:
      'Narrates in third person and compares events to Papa\'s childhood.',
  role: 'Supporting character',
  voice:
      'Narrates in third person, compares to Papa\'s childhood. '
      'Example: "Papa bhi aise hi the. Poore ghar mein atta tha."',
  promptSpeechPattern: 'Third person, childhood comparisons.',
  assetPath: 'assets/characters/Daadi.jpg',
);

const kTeacherDefinition = Character(
  id: 'teacher',
  name: 'Teacher',
  emoji: '👩‍🏫',
  imagePromptDescription:
      "Indian school teacher, dark hair in a low bun with small white gajra "
      "flowers, warm tan skin, dark brown eyes, round gold-rimmed glasses, small red "
      "bindi, small gold earrings, blue three-quarter-sleeve kurta, holding a book, "
      "encouraging smile",
  referenceDescription: "Indian school teacher, dark hair in a low bun with small white gajra flowers, warm tan skin, dark brown eyes, round gold-rimmed glasses, small red bindi, small gold earrings, blue three-quarter-sleeve kurta with white block-printed floral motifs, white leggings, blue juttis, holding a blue hardback book, encouraging smile",
  description: 'Indian school teacher.',
  appearance: "Indian school teacher, dark hair in a low bun with small white gajra flowers, warm tan skin, dark brown eyes, round gold-rimmed glasses, small red bindi, small gold earrings, blue three-quarter-sleeve kurta with white block-printed floral motifs, white leggings, blue juttis, holding a blue hardback book, encouraging smile",
  personality: 'Uses classroom phrases and full sentences.',
  role: 'Supporting character',
  voice:
      'Uses "Friends", "in our class", full sentences. '
      'Example: "Friends, kya hum ek ek karke try karein?"',
  promptSpeechPattern: 'Classroom phrases, full sentences.',
  assetPath: 'assets/characters/Teacher.jpg',
);

const kCharacterDefinitions = <Character>[
  kRiaDefinition,
  kRioDefinition,
  kCutyDefinition,
  kRobotDefinition,
  kMummaDefinition,
  kPapaDefinition,
  kDaadiDefinition,
  kTeacherDefinition,
];

const kMainAppCharacterDefinitions = <Character>[
  kRiaDefinition,
  kRioDefinition,
  kCutyDefinition,
  kMummaDefinition,
  kPapaDefinition,
];
