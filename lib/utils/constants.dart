import 'package:flutter/material.dart';

/// App-wide constants for StreamFlix
class AppConstants {
  // App Branding
  static const String appName = 'StreamFlix';
  static const String appTagline = 'Discover Movies & Series';
  static const String tmdbAttribution =
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  // Theme Colors
  static const Color backgroundColor = Color(0xFF141414); // Netflix Dark Canvas
  static const Color primaryRed = Color(0xFFE50914);       // Netflix Red Accent
  static const Color primaryRedHover = Color(0xFFB80710);  // Darker Red on hover
  static const Color cardColor = Color(0xFF1F1F1F);        // Dark Card Surface
  static const Color surfaceColor = Color(0xFF181818);     // Navigation / Modal
  static const Color textWhite = Colors.white;             // High emphasis text
  static const Color textMuted = Color(0xFFAAAAAA);        // Secondary info text
  static const Color ratingYellow = Color(0xFFFFC107);     // Star rating color
  static const Color chipBackground = Color(0xFF2A2A2A);   // Genre chips

  // TMDB API Endpoints
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbPosterBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbBackdropBaseUrl = 'https://image.tmdb.org/t/p/original';

  // TMDB API Key: Can be passed at compile-time via --dart-define=TMDB_API_KEY=...
  // or set dynamically in the application.
  static const String defaultTmdbApiKey =
      String.fromEnvironment('TMDB_API_KEY', defaultValue: '3f035567eeff0222efd4c3246f82fa63');

  // SharedPreferences Keys
  static const String prefWatchlistKey = 'streamflix_watchlist';
  static const String prefApiKey = 'streamflix_tmdb_api_key';

  /// Helper to build poster image URL with fallback validation
  static String? getPosterUrl(String? posterPath) {
    if (posterPath == null || posterPath.trim().isEmpty) return null;
    return '$tmdbPosterBaseUrl$posterPath';
  }

  /// Helper to build backdrop image URL with fallback validation
  static String? getBackdropUrl(String? backdropPath) {
    if (backdropPath == null || backdropPath.trim().isEmpty) return null;
    return '$tmdbBackdropBaseUrl$backdropPath';
  }
}
