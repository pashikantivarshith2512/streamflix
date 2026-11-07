import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamflix/main.dart';
import 'package:streamflix/models/movie.dart';
import 'package:streamflix/screens/details_screen.dart';
import 'package:streamflix/services/tmdb_service.dart';

void main() {
  final sampleMovies = List.generate(
    12,
    (index) => Movie(
      id: index + 1,
      title: 'Movie Title ${index + 1}',
      overview: 'Overview for movie ${index + 1} with intriguing plot details.',
      posterPath: '/poster_$index.jpg',
      backdropPath: '/backdrop_$index.jpg',
      voteAverage: 8.0 + (index % 10) * 0.1,
      releaseDate: '2024-0${(index % 9) + 1}-15',
      genres: ['Action', 'Drama'],
      runtime: 120 + index * 5,
    ),
  );

  late http.Client mockClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'page': 1,
          'results': sampleMovies.map((m) => m.toJson()).toList(),
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  });

  group('Responsive Layout Tests Across Viewports', () {
    testWidgets('Desktop Viewport (1440x900) displays full tabs and banner',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const StreamFlixApp());
      await tester.pumpAndSettle();

      // Desktop top nav bar shows full tab items
      expect(find.text('STREAMFLIX'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('My List'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tablet Viewport (768x1024) renders cleanly without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const StreamFlixApp());
      await tester.pumpAndSettle();

      // Tablet uses hamburger menu to preserve space
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mobile Viewport (390x844) renders cleanly and opens drawer',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const StreamFlixApp());
      await tester.pumpAndSettle();

      // Check menu button
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);

      // Open mobile bottom sheet
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify mobile options exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('My List'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('DetailsScreen adapts smoothly on mobile viewport',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final service = TmdbService(apiKey: 'test_key', client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsScreen(
              movie: sampleMovies.first,
              tmdbService: service,
              isWatchlisted: false,
              onWatchlistToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Movie Title 1'), findsOneWidget);
      expect(find.text('Add to My List'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
