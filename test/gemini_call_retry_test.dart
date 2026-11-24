import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:reel_audio/gemini_call.dart';

void main() {
  group('geminiPost connection retry', () {
    test('returns success on first try without retry', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response('{"ok": true}', 200);
      });

      final response = await geminiPost(
        model: 'gemini-test',
        apiKey: 'test-key',
        body: '{"test": true}',
        timeout: const Duration(seconds: 5),
        httpClient: client,
      );

      expect(response.statusCode, 200);
      expect(response.body, '{"ok": true}');
    });

    test('retries on SocketException then succeeds', () async {
      var callCount = 0;
      final client = http_testing.MockClient((request) async {
        callCount++;
        if (callCount == 1) throw SocketException('Connection lost');
        return http.Response('{"ok": true}', 200);
      });

      var waitMessage = '';
      final response = await geminiPost(
        model: 'gemini-test',
        apiKey: 'test-key',
        body: '{"test": true}',
        timeout: const Duration(seconds: 5),
        httpClient: client,
        onWait: (msg) => waitMessage = msg,
      );

      expect(callCount, 2);
      expect(response.statusCode, 200);
      expect(waitMessage, contains('Connection lost'));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('retries on HttpException then succeeds', () async {
      var callCount = 0;
      final client = http_testing.MockClient((request) async {
        callCount++;
        if (callCount == 1) throw HttpException('DNS failed');
        return http.Response('{"ok": true}', 200);
      });

      final response = await geminiPost(
        model: 'gemini-test',
        apiKey: 'test-key',
        body: '{"test": true}',
        timeout: const Duration(seconds: 5),
        httpClient: client,
      );

      expect(callCount, 2);
      expect(response.statusCode, 200);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('retries on generic connection error then succeeds', () async {
      var callCount = 0;
      final client = http_testing.MockClient((request) async {
        callCount++;
        if (callCount == 1) throw Exception('Network unreachable');
        return http.Response('{"ok": true}', 200);
      });

      final response = await geminiPost(
        model: 'gemini-test',
        apiKey: 'test-key',
        body: '{"test": true}',
        timeout: const Duration(seconds: 5),
        httpClient: client,
      );

      expect(callCount, 2);
      expect(response.statusCode, 200);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('rethrows after exhausting all retries on SocketException', () async {
      var callCount = 0;
      final client = http_testing.MockClient((request) async {
        callCount++;
        throw SocketException('Always fails');
      });

      await expectLater(
        geminiPost(
          model: 'gemini-test',
          apiKey: 'test-key',
          body: '{"test": true}',
          timeout: const Duration(seconds: 1),
          httpClient: client,
        ),
        throwsA(isA<SocketException>()),
      );

      // 1 initial + 4 retries = 5 total attempts (backoffDurations has 4 entries)
      expect(callCount, 5);
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('does not retry on TimeoutException', () async {
      var callCount = 0;
      final client = http_testing.MockClient((request) async {
        callCount++;
        throw TimeoutException('Request timed out', Duration(seconds: 5));
      });

      await expectLater(
        geminiPost(
          model: 'gemini-test',
          apiKey: 'test-key',
          body: '{"test": true}',
          timeout: const Duration(seconds: 1),
          httpClient: client,
        ),
        throwsA(isA<TimeoutException>()),
      );

      // Should only try once, no retries on timeout
      expect(callCount, 1);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('uses backoff between retries', () async {
      var callCount = 0;
      final client = http_testing.MockClient((request) async {
        callCount++;
        if (callCount <= 3) throw SocketException('Fail $callCount');
        return http.Response('{"ok": true}', 200);
      });

      final stopwatch = Stopwatch()..start();
      final response = await geminiPost(
        model: 'gemini-test',
        apiKey: 'test-key',
        body: '{"test": true}',
        timeout: const Duration(seconds: 5),
        httpClient: client,
      );
      stopwatch.stop();

      expect(response.statusCode, 200);
      expect(callCount, 4);
      // 4s + 10s + 20s = 34s of backoff delays
      expect(stopwatch.elapsed.inSeconds, greaterThanOrEqualTo(33));
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}
