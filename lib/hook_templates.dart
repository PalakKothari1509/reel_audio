import 'dart:math';

class HookTemplate {
  final String id;
  final String name;
  final String pattern;
  final String trigger;
  final String replacement;

  const HookTemplate({
    required this.id,
    required this.name,
    required this.pattern,
    required this.trigger,
    required this.replacement,
  });

  String apply(String childName, String detail) {
    return pattern
        .replaceAll('{child}', childName)
        .replaceAll('{detail}', detail);
  }

  @override
  String toString() => '$name ($id): $pattern';
}

const kHookTemplates = <HookTemplate>[
  HookTemplate(
    id: 'refusal',
    name: 'THE REFUSAL',
    pattern: '{child} ne {detail} dekhke bola \'Nahi!\'',
    trigger: 'Recognition',
    replacement: '[Bachcha] ne [cheez] dekhke bola \'Nahi!\'',
  ),
  HookTemplate(
    id: 'exact_quote',
    name: 'THE EXACT QUOTE',
    pattern: '\'{detail}\' — roz ka drama',
    trigger: 'Specificity',
    replacement: '\'[Bachche ki exact line]\' — roz ka drama',
  ),
  HookTemplate(
    id: 'expectation_vs_reality',
    name: 'EXPECTATION VS REALITY',
    pattern: '{detail} vs Reality',
    trigger: 'Recognition',
    replacement: '[Plan] vs [Reality]',
  ),
  HookTemplate(
    id: 'dont_do_this',
    name: 'DON\'T DO THIS',
    pattern: '{detail} mat karo. {replacement} karo.',
    trigger: 'Loss aversion',
    replacement: '{detail} mat karo. [Alternative] karo.',
  ),
  HookTemplate(
    id: 'the_small_time',
    name: 'THE SMALL TIME',
    pattern: 'Sirf {detail}, ek step se: [outcome]',
    trigger: 'Specificity',
    replacement: 'Sirf [N] minute, [cheez] se: [outcome]',
  ),
  HookTemplate(
    id: 'twist_open',
    name: 'THE TWIST OPEN',
    pattern: '{child} ne {detail} kaha\u2026 aur phir [unexpected]',
    trigger: 'Curiosity gap',
    replacement: '{child} ne [X] kaha... aur phir [unexpected]',
  ),
  HookTemplate(
    id: 'confession',
    name: 'THE CONFESSION',
    pattern: 'Maine {detail} ki\u2026 [result]',
    trigger: 'Social proof',
    replacement: 'Maine [relatable mistake] ki... [result]',
  ),
  HookTemplate(
    id: 'tag_a_parent',
    name: 'TAG A PARENT',
    pattern: 'Us [role] ko bhejo jo {detail}',
    trigger: 'Tag-a-person',
    replacement: 'Us [role] ko bhejo jiska [situation]',
  ),
  HookTemplate(
    id: 'the_test',
    name: 'THE TEST',
    pattern: 'Kya aapka {detail} ka bachcha [skill] kar sakta hai?',
    trigger: 'Curiosity + identity',
    replacement: 'Kya aapka [age] saal ka bachcha [skill] kar sakta hai?',
  ),
  HookTemplate(
    id: 'silent_pov',
    name: 'SILENT POV',
    pattern: 'POV: {detail}',
    trigger: 'Pattern interrupt',
    replacement: 'POV: [time], aap [situation]',
  ),
  HookTemplate(
    id: 'rule_reversal',
    name: 'THE RULE REVERSAL',
    pattern: '{detail} galat ho sakta hai?',
    trigger: 'Surprise',
    replacement: '[Common rule] galat ho sakta hai? Dekho [result]',
  ),
  HookTemplate(
    id: 'case_file',
    name: 'CASE FILE',
    pattern: 'Case #{id}: {detail}?',
    trigger: 'Series open loop',
    replacement: 'Case #[N]: [Small mystery]?',
  ),
];

class HookGenerator {
  final Random _rng = Random();

  List<String> generateAll(String childName, String detail, String alternative,
      String role, String skill, int age, String time, String situation,
      String result, String mysteryNumber) {
    final hooks = <String>[];
    for (final t in kHookTemplates) {
      String hook = t.pattern;
      hook = hook.replaceAll('{child}', childName);
      hook = hook.replaceAll('{detail}', detail);
      hook = hook.replaceAll('{replacement}', alternative);
      hook = hook.replaceAll('{alternative}', alternative);
      hook = hook.replaceAll('{role}', role);
      hook = hook.replaceAll('{skill}', skill);
      hook = hook.replaceAll('{age}', age.toString());
      hook = hook.replaceAll('{time}', time);
      hook = hook.replaceAll('{situation}', situation);
      hook = hook.replaceAll('{result}', result);
      hook = hook.replaceAll('{id}', mysteryNumber.toString());
      hooks.add(hook);
    }
    return hooks;
  }

  String generateRandom(String childName, String detail) {
    final templates = kHookTemplates;
    final t = templates[_rng.nextInt(templates.length)];
    return t.apply(childName, detail);
  }

  List<String> getTemplateNames() =>
      kHookTemplates.map((t) => t.name).toList();

  List<String> getTriggers() =>
      kHookTemplates.map((t) => t.trigger).toSet().toList();
}

const kPowerWordsUse = [
  'Abhi', 'Sirf', 'Bas', 'Roz', 'Zero', 'Free',
  'Ruko', 'Dekho', 'Sach', 'Galti', 'Jugaad',
  'Save karo', 'Bhejo', 'Pehle', 'Phir',
];

const kPowerWordsAvoid = [
  'Guaranteed', '100% works', 'doctor-approved',
  'viral', 'amazing', 'life-changing',
];
