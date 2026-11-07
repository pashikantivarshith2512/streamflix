import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamflix/models/movie.dart';
import 'package:streamflix/screens/watchlist_screen.dart';
import 'package:streamflix/services/watchlist_service.dart';
import 'package:streamflix/widgets/movie_card.dart';

void main() {
  final sampleMovie = Movie(
    id: 101,
    title: 'Pulp Fiction',
    overview: 'A burger-loving hit man, his philosophical partner...',
    posterPath: '/pulp_fiction.jpg',
    voteAverage: 8.9,
    releaseDate: '1994-09-10',
    genres: ['Crime', 'Thriller'],
  );

  group('WatchlistService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('addMovie, loadWatchlist, isMovieSaved, and removeMovie work with persistence',
        () async {
      final service = WatchlistService(await SharedPreferences.getInstance());

      expect(await service.loadWatchlist(), isEmpty);
      expect(await service.isMovieSaved(101), isFalse);

      // Add movie
      await service.addMovie(sampleMovie);

      expect(await service.isMovieSaved(101), isTrue);
      final loaded = await service.loadWatchlist();
      expect(loaded.length, 1);
      expect(loaded.first.title, 'Pulp Fiction');

      // Adding the same movie again should not duplicate
      await service.addMovie(sampleMovie);
      expect((await service.loadWatchlist()).length, 1);

      // Remove movie
      await service.removeMovie(101);
      expect(await service.isMovieSaved(101), isFalse);
      expect(await service.loadWatchlist(), isEmpty);
    });
  });

  group('WatchlistScreen Widget Tests', () {
    testWidgets('Displays empty state and calls onBrowseMovies', (tester) async {
      var browseClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchlistScreen(
              watchlist: const [],
              onMovieSelected: (_) {},
              onRemoveFromWatchlist: (_) {},
              onBrowseMovies: () => browseClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Your Watchlist is Empty'), findsOneWidget);
      expect(find.text('Browse Movies Now'), findsOneWidget);

      await tester.tap(find.text('Browse Movies Now'));
      expect(browseClicked, isTrue);
    });

    testWidgets('Displays saved movie cards and counter badge', (tester) async {
      var movieSelected = false;
      var movieRemoved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchlistScreen(
              watchlist: [sampleMovie],
              onMovieSelected: (_) => movieSelected = true,
              onRemoveFromWatchlist: (_) => movieRemoved = true,
              onBrowseMovies: () {},
            ),
          ),
        ),
      );

      expect(find.text('My List'), findsOneWidget);
      expect(find.text('1 Movie Saved'), findsOneWidget);
      expect(find.byType(MovieCard), findsOneWidget);

      // Tap card
      await tester.tap(find.byType(MovieCard));
      expect(movieSelected, isTrue);

      // Tap bookmark to remove
      await tester.tap(find.byIcon(Icons.bookmark_rounded));
      expect(movieRemoved, isTrue);
    });
  });
}
