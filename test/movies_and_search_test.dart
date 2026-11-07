import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:streamflix/models/movie.dart';
import 'package:streamflix/screens/movies_screen.dart';
import 'package:streamflix/screens/search_screen.dart';
import 'package:streamflix/services/tmdb_service.dart';
import 'package:streamflix/widgets/movie_card.dart';

void main() {
  final sampleMovie = Movie(
    id: 10,
    title: 'Interstellar',
    overview: 'Mankind was born on Earth...',
    posterPath: '/interstellar.jpg',
    voteAverage: 8.6,
    releaseDate: '2014-11-05',
    genres: ['Sci-Fi'],
  );

  group('MoviesScreen Widget Tests', () {
    testWidgets('Renders category filter chips and catalog grid', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'page': 1,
            'results': [sampleMovie.toJson()],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = TmdbService(apiKey: 'test_key', client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoviesScreen(
              tmdbService: service,
              onMovieSelected: (_) {},
              isWatchlisted: (_) => false,
              onWatchlistToggle: (_) {},
              onOpenApiKeyDialog: () {},
            ),
          ),
        ),
      );

      // Loading spinner first
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Check chips
      expect(find.text('Popular'), findsOneWidget);
      expect(find.text('Top Rated'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);

      // Check that movie card was rendered
      expect(find.byType(MovieCard), findsOneWidget);
    });
  });

  group('SearchScreen Widget Tests', () {
    testWidgets('Renders search field, suggestions, and executes search', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/movie')) {
          return http.Response(
            jsonEncode({
              'page': 1,
              'results': [sampleMovie.toJson()],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final service = TmdbService(apiKey: 'test_key', client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchScreen(
              tmdbService: service,
              onMovieSelected: (_) {},
              isWatchlisted: (_) => false,
              onWatchlistToggle: (_) {},
              onOpenApiKeyDialog: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify search bar and prompt
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Explore Thousands of Movies'), findsOneWidget);

      // Type in search query
      await tester.enterText(find.byType(TextField), 'Interstellar');
      // Wait for debounce timer (400ms)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify search results rendered as MovieCard
      expect(find.byType(MovieCard), findsOneWidget);
    });

    testWidgets('Displays meaningful empty state when no search matches found', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'page': 1, 'results': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = TmdbService(apiKey: 'test_key', client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchScreen(
              tmdbService: service,
              onMovieSelected: (_) {},
              isWatchlisted: (_) => false,
              onWatchlistToggle: (_) {},
              onOpenApiKeyDialog: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonexistentMovieXYZ');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('No movies found for "NonexistentMovieXYZ"'), findsOneWidget);
    });
  });
}
