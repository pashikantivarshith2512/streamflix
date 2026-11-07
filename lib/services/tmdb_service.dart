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

  /// Sanitizes raw user input by stripping surrounding quotes, whitespace,
  /// and any accidental "Bearer " or "api_key=" prefixes.
  static String sanitizeToken(String raw) {
    var cleaned = raw.trim();
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }
    if (cleaned.toLowerCase().startsWith('bearer ')) {
      cleaned = cleaned.substring(7).trim();
    } else if (cleaned.toLowerCase().startsWith('api_key=')) {
      cleaned = cleaned.substring(8).trim();
    }
    return cleaned;
  }

  /// Reliably detects whether a credential is a TMDB v4 Read Access Token (JWT format)
  /// or a standard TMDB v3 API Key (32-character hexadecimal).
  static bool isV4Token(String token) {
    final clean = sanitizeToken(token);
    if (clean.startsWith('eyJ')) return true;
    final dotCount = clean.split('.').length;
    if (dotCount == 3) return true;
    return false;
  }

  /// Sanitized active API key
  String get cleanApiKey => sanitizeToken(apiKey);

  /// Check whether an API key has been supplied
  bool get hasApiKey => cleanApiKey.isNotEmpty;

  /// Helper to perform GET request and validate JSON response
  Future<dynamic> _get(String path, [Map<String, String>? queryParams]) async {
    if (!hasApiKey) {
      throw const TmdbApiException(
        'TMDB API key is missing. Please click "Set API Key" in the top bar to provide your free API key.',
        statusCode: 401,
      );
    }

    final cleanKey = cleanApiKey;
    final bool useV4Bearer = isV4Token(cleanKey);

    final Map<String, String> params = {
      if (!useV4Bearer) 'api_key': cleanKey,
      ...?queryParams,
    };

    final Map<String, String> headers = {
      'Accept': 'application/json',
      if (useV4Bearer) 'Authorization': 'Bearer $cleanKey',
    };

    final Uri uri = Uri.parse('${AppConstants.tmdbBaseUrl}$path').replace(
      queryParameters: params.isNotEmpty ? params : null,
    );

    try {
      final response = await _client.get(
        uri,
        headers: headers,
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

  /// Tests an API key against TMDB's /authentication endpoint
  /// to verify whether it is valid before saving.
  Future<bool> validateCredentials([String? testKey]) async {
    final candidate = sanitizeToken(testKey ?? apiKey);
    if (candidate.isEmpty) return false;

    final bool useV4 = isV4Token(candidate);
    final Map<String, String> headers = {
      'Accept': 'application/json',
      if (useV4) 'Authorization': 'Bearer $candidate',
    };
    final Map<String, String> params = {
      if (!useV4) 'api_key': candidate,
    };

    final Uri uri = Uri.parse('${AppConstants.tmdbBaseUrl}/authentication').replace(
      queryParameters: params.isNotEmpty ? params : null,
    );

    try {
      final response = await _client.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map && data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
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
