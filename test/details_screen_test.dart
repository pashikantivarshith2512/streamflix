import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:streamflix/models/movie.dart';
import 'package:streamflix/screens/details_screen.dart';
import 'package:streamflix/services/tmdb_service.dart';

void main() {
  final sampleMovie = Movie(
    id: 99,
    title: 'The Dark Knight',
    overview: 'Batman raises the stakes in his war on crime...',
    posterPath: '/dark_knight_poster.jpg',
    backdropPath: '/dark_knight_backdrop.jpg',
    voteAverage: 9.0,
    releaseDate: '2008-07-18',
    genres: ['Action', 'Crime'],
    runtime: null, // Will test enrichment
  );

  group('DetailsScreen Widget Tests', () {
    testWidgets('Renders movie title, rating, overview, and enriches runtime',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/99')) {
          return http.Response(
            jsonEncode({
              'id': 99,
              'title': 'The Dark Knight',
              'overview': 'Batman raises the stakes in his war on crime...',
              'runtime': 152,
              'genres': [
                {'id': 28, 'name': 'Action'},
                {'id': 80, 'name': 'Crime'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final service = TmdbService(apiKey: 'test_key', client: mockClient);
      var watchlistToggled = false;
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsScreen(
              movie: sampleMovie,
              tmdbService: service,
              isWatchlisted: false,
              onWatchlistToggle: (_) => watchlistToggled = true,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      // Verify immediate content rendered from existing movie object
      expect(find.text('The Dark Knight'), findsOneWidget);
      expect(find.text('9.0'), findsOneWidget);
      expect(find.text('2008'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Add to My List'), findsOneWidget);

      // Await enrichment from TMDB API
      await tester.pumpAndSettle();

      // Enriched runtime (152 min = 2h 32m)
      expect(find.text('2h 32m'), findsOneWidget);

      // Test Watchlist toggle
      await tester.tap(find.text('Add to My List'));
      await tester.pump();
      expect(watchlistToggled, isTrue);
      expect(find.text('In My List (Click to Remove)'), findsOneWidget);

      // Test Close button
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });
  });
}
