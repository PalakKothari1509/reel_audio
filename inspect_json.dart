import 'dart:convert';
import 'dart:io';

void main() {
  final raw = File('assets/data/content_ideas.json').readAsStringSync();
  final d = jsonDecode(raw) as Map<String, dynamic>;
  final ideas = (d['ideas'] as List).cast<Map<String, dynamic>>();
  final ids = ideas.map((i) => i['id'] as String).toList();
  print('count ${ids.length}');
  print('custom ${ideas.where((i) => i['custom'] == true).map((i) => i['id']).toList()}');
  print('archived ${ideas.where((i) => i['archived'] == true).map((i) => i['id']).toList()}');
  print('last5 ${ids.sublist(ids.length - 5)}');
  print('first3 ${ids.sublist(0, 3)}');
  print('has117 at ${ids.indexOf('idea_117')}');
}