import 'dart:convert';
import 'dart:io';

import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_library_service.dart';

void main() {
  try {
    verifyExport();
    print('OK');
  } catch (e, st) {
    stderr.writeln('VERIFICATION_FAILED: $e');
    stderr.writeln(st);
    exit(1);
  }
}

void verifyExport({String jsonPath = 'assets/data/content_ideas.json'}) {
  final jsonFile = File(jsonPath);
  if (!jsonFile.existsSync()) {
    throw Exception('MISSING: $jsonPath');
  }

  final jsonData = jsonDecode(jsonFile.readAsStringSync());
  if (jsonData is! Map) {
    throw Exception('INVALID_JSON: root is not an object');
  }

  final ideas = jsonData['ideas'];
  if (ideas is! List) {
    throw Exception('INVALID_JSON: ideas is not a list');
  }

  // Validate we have 122 ideas
  if (ideas.length != 122) {
    throw Exception(
        'COUNT_MISMATCH: expected 122 ideas, got ${ideas.length}');
  }

  // Validate unique IDs
  final expectedIds = <String>{};
  for (final h in ideas) {
    if (expectedIds.contains(h['id'])) {
      throw Exception('DUPLICATE_SOURCE_ID: ${h['id']}');
    }
    expectedIds.add(h['id']);
  }

  // Verify all idea_1 through idea_122 are present
  for (int i = 1; i <= 122; i++) {
    if (!expectedIds.contains('idea_$i')) {
      throw Exception('MISSING_ID: idea_$i not found in JSON');
    }
  }

  // Verify ordering: existing ideas remain in place, followed by ideas 121 and 122
  final expectedOrder = <String>[];
  for (var i = 1; i <= 75; i++) expectedOrder.add('idea_$i');
  expectedOrder.addAll(['idea_76', 'idea_77', 'idea_78', 'idea_117', 'idea_79']);
  for (var i = 80; i <= 116; i++) expectedOrder.add('idea_$i');
  expectedOrder.addAll(['idea_118', 'idea_119', 'idea_120', 'idea_121', 'idea_122']);

  for (var i = 0; i < ideas.length; i++) {
    final actualId = ideas[i]['id'];
    final expectedId = expectedOrder[i];
    if (actualId != expectedId) {
      throw Exception('ORDER_MISMATCH_AT_$i: expected $expectedId, got $actualId');
    }
  }

  // Verify archived set
  final archivedIds = <String>{};
  for (final h in ideas) {
    if (h['archived'] == true) archivedIds.add(h['id']);
  }
  final requiredArchived = {'idea_43', 'idea_44', 'idea_46'};
  if (archivedIds.length != requiredArchived.length) {
    throw Exception('ARCHIVED_COUNT_MISMATCH: expected ${requiredArchived.length}, got ${archivedIds.length}');
  }
  for (final a in requiredArchived) {
    if (!archivedIds.contains(a)) {
      throw Exception('MISSING_ARCHIVED_ID: $a');
    }
  }

  // Verify idea_41 and idea_42 are NOT archived
  final idea41 = ideas.firstWhere((h) => h['id'] == 'idea_41');
  final idea42 = ideas.firstWhere((h) => h['id'] == 'idea_42');
  if (idea41['archived'] == true) {
    throw Exception('idea_41 should not be archived');
  }
  if (idea42['archived'] == true) {
    throw Exception('idea_42 should not be archived');
  }

  // Verify idea_120 is custom=true
  final idea120 = ideas.firstWhere((h) => h['id'] == 'idea_120');
  if (idea120['custom'] != true) {
    throw Exception('idea_120 should have custom=true');
  }

  final idea122 = ideas.firstWhere((h) => h['id'] == 'idea_122');
  if (idea122['custom'] != true) {
    throw Exception('idea_122 should have custom=true');
  }

  print('VERIFIED: 122 ideas with correct ordering, archived flags, and content');
}
