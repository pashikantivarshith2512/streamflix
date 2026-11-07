import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix/models/movie.dart';

void main() {
  group('Movie Model Tests', () {
    final sampleJson = {
      'id': 550,
      'title': 'Fight Club',
      'overview': 'An insomniac office worker and a devil-may-care soap maker...',
      'poster_path': '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
      'backdrop_path': '/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
      'vote_average': 8.433,
      'release_date': '1999-10-15',
      'genre_ids': [18, 53],
      'runtime': 139,
    };

    test('fromJson correctly parses TMDB json map', () {
      final movie = Movie.fromJson(sampleJson);

      expect(movie.id, 550);
      expect(movie.title, 'Fight Club');
      expect(movie.overview, contains('insomniac'));
      expect(movie.posterPath, '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg');
      expect(movie.voteAverage, closeTo(8.433, 0.001));
      expect(movie.releaseDate, '1999-10-15');
      expect(movie.genreIds, [18, 53]);
      expect(movie.runtime, 139);
    });

    test('Helper getters format dates, ratings, runtimes, and URLs correctly', () {
      final movie = Movie.fromJson(sampleJson);

      expect(movie.releaseYear, '1999');
      expect(movie.formattedRating, '8.4');
      expect(movie.formattedRuntime, '2h 19m');
      expect(
        movie.fullPosterUrl,
        'https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
      );
      expect(
        movie.fullBackdropUrl,
        'https://image.tmdb.org/t/p/original/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
      );
    });

    test('toJson and fromJson roundtrip serialization', () {
      final movie = Movie.fromJson(sampleJson);
      final jsonMap = movie.toJson();
      final reconstructed = Movie.fromJson(jsonMap);

      expect(reconstructed.id, movie.id);
      expect(reconstructed.title, movie.title);
      expect(reconstructed.voteAverage, movie.voteAverage);
      expect(reconstructed.releaseYear, movie.releaseYear);
    });

    test('Handles missing / null fields gracefully', () {
      final emptyJson = <String, dynamic>{};
      final movie = Movie.fromJson(emptyJson);

      expect(movie.id, 0);
      expect(movie.title, 'Untitled');
      expect(movie.overview, 'No synopsis available.');
      expect(movie.posterPath, isNull);
      expect(movie.fullPosterUrl, isNull);
      expect(movie.formattedRating, 'NR');
      expect(movie.releaseYear, '');
      expect(movie.formattedRuntime, isNull);
    });
  });
}
