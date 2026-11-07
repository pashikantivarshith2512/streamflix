import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix/models/movie.dart';
import 'package:streamflix/screens/home_screen.dart';
import 'package:streamflix/services/tmdb_service.dart';
import 'package:streamflix/widgets/movie_card.dart';
import 'package:streamflix/widgets/movie_carousel.dart';

void main() {
  final sampleMovie = Movie(
    id: 1,
    title: 'Inception',
    overview: 'A thief who steals corporate secrets through dream-sharing technology...',
    posterPath: '/inception_poster.jpg',
    backdropPath: '/inception_backdrop.jpg',
    voteAverage: 8.8,
    releaseDate: '2010-07-16',
    genres: ['Action', 'Sci-Fi'],
  );

  group('MovieCard Widget Tests', () {
    testWidgets('Renders title, rating, and handles tap', (tester) async {
      var tapped = false;
      var watchlistToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieCard(
              movie: sampleMovie,
              onTap: () => tapped = true,
              isWatchlisted: false,
              onWatchlistToggle: () => watchlistToggled = true,
            ),
          ),
        ),
      );

      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('8.8'), findsOneWidget);
      expect(find.text('2010'), findsOneWidget);

      await tester.tap(find.text('Inception'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      expect(watchlistToggled, isTrue);
    });
  });

  group('MovieCarousel Widget Tests', () {
    testWidgets('Renders category title and movie list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieCarousel(
              title: 'Trending This Week',
              movies: [sampleMovie],
            ),
          ),
        ),
      );

      expect(find.text('Trending This Week'), findsOneWidget);
      expect(find.text('Inception'), findsOneWidget);
    });
  });

  group('HomeScreen Widget Tests', () {
    testWidgets('Prompts user to configure API key when missing', (tester) async {
      final service = TmdbService(apiKey: '');
      var dialogOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              tmdbService: service,
              onMovieSelected: (_) {},
              onOpenApiKeyDialog: () => dialogOpened = true,
              isWatchlisted: (_) => false,
              onWatchlistToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connection Required'), findsOneWidget);
      expect(find.text('Configure API Key'), findsOneWidget);

      await tester.tap(find.text('Configure API Key'));
      expect(dialogOpened, isTrue);
    });
  });
}
