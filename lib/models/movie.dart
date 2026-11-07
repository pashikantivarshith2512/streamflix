import '../utils/constants.dart';

/// Represents a Movie from The Movie Database (TMDB)
class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? releaseDate;
  final List<int> genreIds;
  final List<String> genres;
  final int? runtime; // In minutes, available in detail view

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.releaseDate,
    this.genreIds = const [],
    this.genres = const [],
    this.runtime,
  });

  /// Factory constructor to parse JSON received from TMDB or local storage
  factory Movie.fromJson(Map<String, dynamic> json) {
    // 1. Parse genres: could be List of Maps [{"id": 28, "name": "Action"}]
    // or List of strings if coming from our local watchlist JSON
    final List<String> parsedGenres = [];
    final List<int> parsedGenreIds = [];

    if (json['genres'] is List) {
      for (final item in json['genres']) {
        if (item is Map && item['name'] != null) {
          parsedGenres.add(item['name'].toString());
          if (item['id'] is int) parsedGenreIds.add(item['id'] as int);
        } else if (item is String) {
          parsedGenres.add(item);
        }
      }
    }

    if (json['genre_ids'] is List) {
      for (final id in json['genre_ids']) {
        if (id is int) {
          parsedGenreIds.add(id);
        }
      }
    }

    return Movie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ??
          json['original_title'] as String? ??
          json['name'] as String? ??
          'Untitled',
      overview: json['overview'] as String? ?? 'No synopsis available.',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
      genreIds: parsedGenreIds,
      genres: parsedGenres,
      runtime: json['runtime'] as int?,
    );
  }

  /// Converts a Movie instance to a JSON Map for saving to SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'genres': genres,
      'runtime': runtime,
    };
  }

  /// Returns the full TMDB URL for the poster image (w500 size)
  String? get fullPosterUrl => AppConstants.getPosterUrl(posterPath);

  /// Returns the full TMDB URL for the backdrop banner (original high-res)
  String? get fullBackdropUrl => AppConstants.getBackdropUrl(backdropPath);

  /// Formatted rating (e.g., "7.8")
  String get formattedRating =>
      voteAverage > 0 ? voteAverage.toStringAsFixed(1) : 'NR';

  /// Extracts the 4-digit year from releaseDate (e.g. "2024" from "2024-05-15")
  String get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    final parts = releaseDate!.split('-');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Formats runtime into a human-readable string (e.g., "2h 15m")
  String? get formattedRuntime {
    if (runtime == null || runtime! <= 0) return null;
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Create a copy with modified fields (e.g. enriched genres or runtime)
  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    String? releaseDate,
    List<int>? genreIds,
    List<String>? genres,
    int? runtime,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      genreIds: genreIds ?? this.genreIds,
      genres: genres ?? this.genres,
      runtime: runtime ?? this.runtime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movie && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
