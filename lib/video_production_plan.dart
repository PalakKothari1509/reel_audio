
class ClipPlan {
  final int partNumber;
  final String purpose;
  final String setting;
  final String startingState;
  final String action0to4s;
  final String action4to8s;
  final String action8to10s;
  final String dialogue;
  final String textOverlay;
  final String endingState;
  final String continuityFrom;
  final String continuityInto;
  final String negativeInstructions;
  final String fullPrompt;

  ClipPlan({
    required this.partNumber,
    required this.purpose,
    required this.setting,
    required this.startingState,
    required this.action0to4s,
    required this.action4to8s,
    required this.action8to10s,
    required this.dialogue,
    required this.textOverlay,
    required this.endingState,
    required this.continuityFrom,
    required this.continuityInto,
    required this.negativeInstructions,
    required this.fullPrompt,
  });

  Map<String, dynamic> toJson() => {
          'partNumber': partNumber,
          'purpose': purpose,
          'setting': setting,
          'startingState': startingState,
          'action_0_4s': action0to4s,
          'action_4_8s': action4to8s,
          'action_8_10s': action8to10s,
          'dialogue': dialogue,
          'text_overlay': textOverlay,
          'endingState': endingState,
          'continuity_from': continuityFrom,
          'continuity_into': continuityInto,
          'negative_instructions': negativeInstructions,
          'full_prompt': fullPrompt,
        };

  factory ClipPlan.fromJson(Map<String, dynamic> json) => ClipPlan(
        partNumber: (json['partNumber'] as num?)?.toInt() ?? 0,
        purpose: json['purpose'] as String? ?? '',
        setting: json['setting'] as String? ?? '',
        startingState: json['startingState'] as String? ?? '',
        action0to4s: json['action_0_4s'] as String? ?? '',
        action4to8s: json['action_4_8s'] as String? ?? '',
        action8to10s: json['action_8_10s'] as String? ?? '',
        dialogue: json['dialogue'] as String? ?? '',
        textOverlay: json['text_overlay'] as String? ?? '',
        endingState: json['endingState'] as String? ?? '',
        continuityFrom: json['continuity_from'] as String? ?? '',
        continuityInto: json['continuity_into'] as String? ?? '',
        negativeInstructions: json['negative_instructions'] as String? ?? '',
        fullPrompt: json['full_prompt'] as String? ?? '',
      );

  /// Whether this clip has on-screen text for sound-off viewing.
  bool get hasOverlayText => textOverlay.trim().isNotEmpty;

  /// Whether this clip has dialogue.
  bool get hasDialogue => dialogue.trim().isNotEmpty;
}

class VideoProductionPlan {
  final String id;
  final String contentId;
  final String storyTitle;
  final String storyFoundation;
  final String templateId;
  final int templateVersion;
  final List<ClipPlan> clipPlans;
  final String fullNarration;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoProductionPlan({
    required this.id,
    required this.contentId,
    required this.storyTitle,
    required this.storyFoundation,
    required this.templateId,
    required this.templateVersion,
    required this.clipPlans,
    required this.fullNarration,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
          'id': id,
          'contentId': contentId,
          'storyTitle': storyTitle,
          'storyFoundation': storyFoundation,
          'templateId': templateId,
          'templateVersion': templateVersion,
          'clipPlans': clipPlans.map((p) => p.toJson()).toList(),
          'fullNarration': fullNarration,
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': updatedAt.toIso8601String(),
        };

  factory VideoProductionPlan.fromJson(Map<String, dynamic> json) =>
      VideoProductionPlan(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        storyTitle: json['storyTitle'] as String? ?? '',
        storyFoundation: json['storyFoundation'] as String? ?? '',
        templateId: json['templateId'] as String? ?? '',
        templateVersion:
            (json['templateVersion'] as num?)?.toInt() ?? 1,
        clipPlans: (json['clipPlans'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map((p) => ClipPlan.fromJson(p))
                .toList() ??
            [],
        fullNarration: json['fullNarration'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  /// Whether every clip has overlay text or dialogue for sound-off viewing.
  bool get hasSoundOffCoverage => clipPlans.every((p) => p.hasOverlayText || p.hasDialogue);
}
