import 'dart:convert';

import 'package:http/http.dart' as http;

class IdeaLabRequest {
  final String provider;
  final String topic;
  final String contentType;
  final String goal;
  final List<String> characters;
  final int count;

  const IdeaLabRequest({
    required this.provider,
    required this.topic,
    required this.contentType,
    required this.goal,
    required this.characters,
    required this.count,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'topic': topic,
        'contentType': contentType,
        'goal': goal,
        'characters': characters,
        'count': count,
      };
}

class LabIdea {
  final String provider;
  final String title;
  final String hook;
  final String concept;
  final String character;
  final String contentType;
  final String whyItCouldWork;
  final Map<String, dynamic> scores;

  const LabIdea({
    required this.provider,
    required this.title,
    required this.hook,
    required this.concept,
    required this.character,
    required this.contentType,
    required this.whyItCouldWork,
    required this.scores,
  });

  factory LabIdea.fromJson(Map<String, dynamic> json, String provider) => LabIdea(
        provider: provider,
        title: '${json['title'] ?? ''}',
        hook: '${json['hook'] ?? ''}',
        concept: '${json['concept'] ?? ''}',
        character: '${json['character'] ?? ''}',
        contentType: '${json['contentType'] ?? ''}',
        whyItCouldWork: '${json['whyItCouldWork'] ?? ''}',
        scores: Map<String, dynamic>.from((json['scores'] as Map?) ?? const {}),
      );
}

class IdeaLabResult {
  final String provider;
  final List<LabIdea> ideas;

  const IdeaLabResult({required this.provider, required this.ideas});
}

class IdeaLabApi {
  final String baseUrl;
  final http.Client _client;

  IdeaLabApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  Future<List<IdeaLabResult>> generate(IdeaLabRequest request) async {
    final endpoint = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/*$'), '')}/v1/ideas');
    final response = await _client.post(
      endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('${body is Map ? body['error'] : 'Idea API request failed'}');
    }
    if (body is! Map || body['results'] is! List) {
      throw const FormatException('Idea API returned an invalid response.');
    }

    return (body['results'] as List).whereType<Map>().map((result) {
      final provider = '${result['provider'] ?? 'unknown'}';
      final ideas = (result['ideas'] as List? ?? const [])
          .whereType<Map>()
          .map((idea) => LabIdea.fromJson(Map<String, dynamic>.from(idea), provider))
          .toList();
      return IdeaLabResult(provider: provider, ideas: ideas);
    }).toList();
  }

  void dispose() => _client.close();
}
