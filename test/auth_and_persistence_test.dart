import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamflix/main.dart';
import 'package:streamflix/screens/home_screen.dart';
import 'package:streamflix/services/tmdb_service.dart';
import 'package:streamflix/utils/constants.dart';

void main() {
  group('TMDB Authentication Format Selection Tests', () {
    test('Sanitizes quotes, Bearer prefixes, and whitespace', () {
      expect(TmdbService.sanitizeToken('  "c45a8b71"  '), 'c45a8b71');
      expect(TmdbService.sanitizeToken("'c45a8b71'"), 'c45a8b71');
      expect(TmdbService.sanitizeToken('Bearer eyJhbGciOi...'), 'eyJhbGciOi...');
      expect(TmdbService.sanitizeToken('api_key=c45a8b71'), 'c45a8b71');
    });

    test('Reliably distinguishes between V3 key and V4 JWT Bearer token', () {
      const v3Key = '15d2ce6754406a61321f9d532f6b3e0b';
      const v4Jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxNWQyY2U2NyIsInN1YiI6IjY2ZWY5YzYxYzZjIn0.signature';

      expect(TmdbService.isV4Token(v3Key), isFalse);
      expect(TmdbService.isV4Token(v4Jwt), isTrue);
      expect(TmdbService.isV4Token('Bearer $v4Jwt'), isTrue);
    });

    test('Sends V3 Key in query parameters and not in Authorization header', () async {
      const v3Key = '15d2ce6754406a61321f9d532f6b3e0b';
      late http.Request capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'page': 1, 'results': []}), 200);
      });

      final service = TmdbService(apiKey: v3Key, client: mockClient);
      await service.getPopularMovies();

      expect(capturedRequest.url.queryParameters['api_key'], v3Key);
      expect(capturedRequest.headers['Authorization'], isNull);
    });

    test('Sends V4 Bearer Token in Authorization header and not in query parameters', () async {
      const v4Jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxNWQyY2U2NyIsInN1YiI6IjY2ZWY5YzYxYzZjIn0.signature';
      late http.Request capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'page': 1, 'results': []}), 200);
      });

      final service = TmdbService(apiKey: v4Jwt, client: mockClient);
      await service.getPopularMovies();

      expect(capturedRequest.url.queryParameters['api_key'], isNull);
      expect(capturedRequest.headers['Authorization'], 'Bearer $v4Jwt');
    });

    test('validateCredentials returns true on 200 success and false on 401', () async {
      final successClient = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'status_code': 1}), 200);
      });
      final failureClient = MockClient((request) async {
        return http.Response(jsonEncode({'success': false, 'status_code': 7}), 401);
      });

      final validService = TmdbService(apiKey: 'key', client: successClient);
      final invalidService = TmdbService(apiKey: 'key', client: failureClient);

      expect(await validService.validateCredentials(), isTrue);
      expect(await invalidService.validateCredentials(), isFalse);
    });
  });

  group('API Key Persistence & Startup Loading Tests', () {
    testWidgets('Waits for SharedPreferences before rendering to prevent race condition', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefApiKey: 'saved_valid_key',
      });

      await tester.pumpWidget(const StreamFlixApp());

      // While initializing, shows loading
      expect(find.text('Loading StreamFlix...'), findsOneWidget);

      await tester.pumpAndSettle();

      // Successfully transitions to main shell without displaying "API Key Required" error
      expect(find.text('STREAMFLIX'), findsOneWidget);
    });
  });

  group('HomeScreen Error Differentiation and Retry Tests', () {
    testWidgets('Differentiates between Missing Key and 401 Authentication Failure', (tester) async {
      // 1. Missing Key state
      final missingService = TmdbService(apiKey: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              tmdbService: missingService,
              onMovieSelected: (_) {},
              onOpenApiKeyDialog: () {},
              isWatchlisted: (_) => false,
              onWatchlistToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('API Key Required'), findsOneWidget);

      // 2. 401 Authentication failure state
      var attempts = 0;
      final failClient = MockClient((request) async {
        attempts++;
        return http.Response(
          jsonEncode({'status_code': 7, 'status_message': 'Invalid API key'}),
          401,
        );
      });

      final authFailService = TmdbService(apiKey: 'bad_key', client: failClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              tmdbService: authFailService,
              onMovieSelected: (_) {},
              onOpenApiKeyDialog: () {},
              isWatchlisted: (_) => false,
              onWatchlistToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Authentication Failed'), findsOneWidget);
      expect(find.textContaining('Invalid TMDB API key'), findsOneWidget);

      // Tap Retry button
      expect(attempts, 4); // Initial parallel 4 requests
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(attempts, 8); // Successfully retried
    });
  });
}
