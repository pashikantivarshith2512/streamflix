import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:streamflix/services/tmdb_service.dart';

void main() {
  group('TmdbService Tests', () {
    test('Throws TmdbApiException when API key is empty', () async {
      final service = TmdbService(apiKey: '');
      expect(
        () => service.getTrendingMovies(),
        throwsA(isA<TmdbApiException>().having(
          (e) => e.message,
          'message',
          contains('missing'),
        )),
      );
    });

    test('Throws TmdbApiException on 401 Unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status_code': 7,
            'status_message': 'Invalid API key',
            'success': false,
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = TmdbService(apiKey: 'invalid_key', client: mockClient);
      expect(
        () => service.getPopularMovies(),
        throwsA(isA<TmdbApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });

    test('getTrendingMovies parses response and populates genres', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/trending/movie/week');
        expect(request.url.queryParameters['api_key'], 'valid_test_key');

        final payload = {
          'page': 1,
          'results': [
            {
              'id': 101,
              'title': 'Interstellar',
              'overview': 'A team of explorers travel through a wormhole...',
              'poster_path': '/interstellar.jpg',
              'vote_average': 8.7,
              'release_date': '2014-11-07',
              'genre_ids': [878, 18], // Sci-Fi, Drama
            }
          ]
        };

        return http.Response(
          jsonEncode(payload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = TmdbService(apiKey: 'valid_test_key', client: mockClient);
      final movies = await service.getTrendingMovies();

      expect(movies.length, 1);
      expect(movies[0].title, 'Interstellar');
      expect(movies[0].releaseYear, '2014');
      // Should automatically enrich cached genre names for 878 and 18
      expect(movies[0].genres, containsAll(['Sci-Fi', 'Drama']));
    });

    test('searchMovies returns empty list on empty query without network call', () async {
      var called = false;
      final mockClient = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final service = TmdbService(apiKey: 'valid_test_key', client: mockClient);
      final results = await service.searchMovies('   ');

      expect(results, isEmpty);
      expect(called, isFalse);
    });
  });
}
