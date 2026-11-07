import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../utils/constants.dart';

/// Custom exception for TMDB API errors with beginner-friendly messages
class TmdbApiException implements Exception {
  final String message;
  final int? statusCode;

  const TmdbApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Service class responsible for all network interactions with TMDB REST API
class TmdbService {
  final String apiKey;
  final http.Client _client;

  // Cached genre mapping: ID -> Genre Name (e.g. 28 -> "Action")
  static final Map<int, String> _genreCache = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  TmdbService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Check whether an API key has been supplied
  bool get hasApiKey => apiKey.trim().isNotEmpty;

  /// Helper to perform GET request and validate JSON response
  Future<dynamic> _get(String path, [Map<String, String>? queryParams]) async {
    if (!hasApiKey) {
      throw const TmdbApiException(
        'TMDB API key is missing. Please click "Set API Key" in the top bar to provide your free API key.',
        statusCode: 401,
      );
    }

    final Map<String, String> params = {
      'api_key': apiKey.trim(),
      ...?queryParams,
    };

    final Uri uri = Uri.parse('${AppConstants.tmdbBaseUrl}$path').replace(
      queryParameters: params,
    );

    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw const TmdbApiException(
          'Invalid TMDB API key. Please check your key from themoviedb.org.',
          statusCode: 401,
        );
      } else if (response.statusCode == 404) {
        throw const TmdbApiException(
          'The requested movie or resource was not found.',
          statusCode: 404,
        );
      } else {
        throw TmdbApiException(
          'TMDB server returned an error (code ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw TmdbApiException('Network error: ${e.message}');
    } on FormatException {
      throw const TmdbApiException('Failed to parse TMDB response as JSON.');
    }
  }

  /// Parses a list of movies from the TMDB "results" array and enriches genre names
  List<Movie> _parseMovieList(dynamic json) {
    if (json is Map && json['results'] is List) {
      final results = json['results'] as List;
      return results.map((item) {
        final movie = Movie.fromJson(item as Map<String, dynamic>);
        // Enrich genre names from cache if not already populated
        if (movie.genres.isEmpty && movie.genreIds.isNotEmpty) {
          final mappedGenres = movie.genreIds
              .map((id) => _genreCache[id])
              .whereType<String>()
              .toList();
          return movie.copyWith(genres: mappedGenres);
        }
        return movie;
      }).toList();
    }
    return [];
  }

  /// 1. Fetch Trending movies (week)
  Future<List<Movie>> getTrendingMovies({int page = 1}) async {
    final data = await _get('/trending/movie/week', {'page': '$page'});
    return _parseMovieList(data);
  }

  /// 2. Fetch Popular movies
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    final data = await _get('/movie/popular', {'page': '$page'});
    return _parseMovieList(data);
  }

  /// 3. Fetch Top Rated movies
  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    final data = await _get('/movie/top_rated', {'page': '$page'});
    return _parseMovieList(data);
  }

  /// 4. Fetch Upcoming movies
  Future<List<Movie>> getUpcomingMovies({int page = 1}) async {
    final data = await _get('/movie/upcoming', {'page': '$page'});
    return _parseMovieList(data);
  }

  /// 5. Search movies by keyword
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    final data = await _get('/search/movie', {
      'query': query.trim(),
      'page': '$page',
      'include_adult': 'false',
    });
    return _parseMovieList(data);
  }

  /// 6. Fetch full Movie details by ID (includes runtime and explicit genre names)
  Future<Movie> getMovieDetails(int movieId) async {
    final data = await _get('/movie/$movieId');
    if (data is Map<String, dynamic>) {
      return Movie.fromJson(data);
    }
    throw const TmdbApiException('Failed to decode movie details.');
  }

  /// 7. Load and update the genre cache from TMDB
  Future<void> syncGenreList() async {
    try {
      final data = await _get('/genre/movie/list');
      if (data is Map && data['genres'] is List) {
        for (final item in data['genres']) {
          if (item is Map && item['id'] is int && item['name'] is String) {
            _genreCache[item['id'] as int] = item['name'] as String;
          }
        }
      }
    } catch (_) {
      // Non-critical: defaults in _genreCache will continue to be used
    }
  }

  /// Lookup genre name by ID
  static String? getGenreName(int id) => _genreCache[id];
}
