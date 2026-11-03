import 'dart:convert';
import 'dart:io';

import 'package:reel_audio/content_ideas.dart';

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

  if (ideas.length != kDefaultHooks.length) {
    throw Exception('COUNT_MISMATCH: expected ${kDefaultHooks.length}, got ${ideas.length}');
  }

  final expectedIds = <String>{};
  for (final h in kDefaultHooks) {
    if (expectedIds.contains(h.id)) {
      throw Exception('DUPLICATE_SOURCE_ID: ${h.id}');
    }
    expectedIds.add(h.id);
  }

  if (expectedIds.length != kDefaultHooks.length) {
    throw Exception('DUPLICATE_SOURCE_COUNT');
  }

  final seenIds = <String>{};
  for (var i = 0; i < kDefaultHooks.length; i++) {
    final expected = kDefaultHooks[i];
    final actual = ideas[i];
    if (actual is! Map) {
      throw Exception('INVALID_ITEM_AT_$i');
    }

    final actualId = actual['id'];
    if (actualId != expected.id) {
      throw Exception('ID_MISMATCH_AT_$i: expected ${expected.id}, got $actualId');
    }
    if (seenIds.contains(actualId)) {
      throw Exception('DUPLICATE_ID_IN_JSON: $actualId');
    }
    seenIds.add(actualId);

    if (actual['category'] != expected.category) throw Exception('CATEGORY_MISMATCH_AT_$i:${expected.id}');
    if (actual['title'] != expected.title) throw Exception('TITLE_MISMATCH_AT_$i:${expected.id}');
    if (actual['cover'] != expected.cover) throw Exception('COVER_MISMATCH_AT_$i:${expected.id}');
    if (actual['opening'] != expected.opening) throw Exception('OPENING_MISMATCH_AT_$i:${expected.id}');
    if (actual['problem'] != expected.problem) throw Exception('PROBLEM_MISMATCH_AT_$i:${expected.id}');
    if (actual['lesson'] != expected.lesson) throw Exception('LESSON_MISMATCH_AT_$i:${expected.id}');
    if (actual['forApp'] != expected.forApp) throw Exception('FORAPP_MISMATCH_AT_$i:${expected.id}');
    if (actual['usedOn'] != expected.usedOn) throw Exception('USEDON_MISMATCH_AT_$i:${expected.id}');
    if (actual['custom'] != expected.custom) throw Exception('CUSTOM_MISMATCH_AT_$i:${expected.id}');
    if (actual['archived'] != expected.archived) throw Exception('ARCHIVED_MISMATCH_AT_$i:${expected.id}');
    if (actual['postFormat'] != expected.postFormat) throw Exception('POSTFORMAT_MISMATCH_AT_$i:${expected.id}');
    if (actual['strategy'] != expected.strategy) throw Exception('STRATEGY_MISMATCH_AT_$i:${expected.id}');
    if (actual['caption'] != expected.caption) throw Exception('CAPTION_MISMATCH_AT_$i:${expected.id}');
    if (actual['pinnedComment'] != expected.pinnedComment) throw Exception('PINNED_MISMATCH_AT_$i:${expected.id}');
    if (actual['storyDetail'] != expected.storyDetail) throw Exception('STORYDETAIL_MISMATCH_AT_$i:${expected.id}');
    if (actual['setting'] != expected.setting) throw Exception('SETTING_MISMATCH_AT_$i:${expected.id}');
    if (actual['sceneDetail'] != expected.sceneDetail) throw Exception('SCENEDETAIL_MISMATCH_AT_$i:${expected.id}');
    if (actual['dialogue'] != expected.dialogue) throw Exception('DIALOGUE_MISMATCH_AT_$i:${expected.id}');
    if (actual['mess'] != expected.mess) throw Exception('MESS_MISMATCH_AT_$i:${expected.id}');
    if (actual['innerThought'] != expected.innerThought) throw Exception('INNERTHOUGHT_MISMATCH_AT_$i:${expected.id}');
    if (actual['endingBeat'] != expected.endingBeat) throw Exception('ENDINGBEAT_MISMATCH_AT_$i:${expected.id}');
    if (actual['keepMoralOffScreen'] != expected.keepMoralOffScreen) throw Exception('KEEPMORAL_MISMATCH_AT_$i:${expected.id}');
    if (actual['quote'] != expected.quote) throw Exception('QUOTE_MISMATCH_AT_$i:${expected.id}');
    if (actual['detail'] != expected.detail) throw Exception('DETAIL_MISMATCH_AT_$i:${expected.id}');
    if (actual['punchline'] != expected.punchline) throw Exception('PUNCHLINE_MISMATCH_AT_$i:${expected.id}');
    if (actual['readyPrompt'] != expected.readyPrompt) throw Exception('READYPROMPT_MISMATCH_AT_$i:${expected.id}');
    if (actual['score'] != expected.score) throw Exception('SCORE_MISMATCH_AT_$i:${expected.id}');
    if (actual['band'] != expected.band) throw Exception('BAND_MISMATCH_AT_$i:${expected.id}');
    if (actual['reviewedOn'] != expected.reviewedOn) throw Exception('REVIEWEDON_MISMATCH_AT_$i:${expected.id}');

    if (actual['defaultCast'] is List && expected.defaultCast is List) {
      final aD = (actual['defaultCast'] as List).map((e) => e.toString()).toList();
      final eD = expected.defaultCast;
      if (aD.length != eD.length) throw Exception('DEFAULTCAST_LEN_MISMATCH_AT_$i:${expected.id}');
      for (var j = 0; j < eD.length; j++) {
        if (aD[j] != eD[j]) throw Exception('DEFAULTCAST_MISMATCH_AT_$i:${expected.id}');
      }
    } else if (actual['defaultCast'] != expected.defaultCast) {
      throw Exception('DEFAULTCAST_MISMATCH_AT_$i:${expected.id}');
    }
  }

  if (seenIds.length != kDefaultHooks.length) {
    throw Exception('UNIQUE_COUNT_MISMATCH');
  }
}
