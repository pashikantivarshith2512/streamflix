import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../utils/constants.dart';

/// Service responsible for persisting the user's Watchlist in browser localStorage via SharedPreferences
class WatchlistService {
  final SharedPreferences? _prefs;

  const WatchlistService([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Loads all saved movies from local storage
  Future<List<Movie>> loadWatchlist() async {
    final prefs = await _getPrefs();
    final List<String>? jsonList = prefs.getStringList(AppConstants.prefWatchlistKey);
    if (jsonList == null || jsonList.isEmpty) return [];

    final List<Movie> movies = [];
    for (final itemStr in jsonList) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(itemStr);
        movies.add(Movie.fromJson(jsonMap));
      } catch (_) {
        // Skip corrupted entries safely
      }
    }
    return movies;
  }

  /// Saves the complete list of movies to local storage
  Future<bool> saveWatchlist(List<Movie> movies) async {
    final prefs = await _getPrefs();
    final List<String> encodedList =
        movies.map((m) => jsonEncode(m.toJson())).toList();
    return prefs.setStringList(AppConstants.prefWatchlistKey, encodedList);
  }

  /// Adds a movie to the watchlist if not already present
  Future<List<Movie>> addMovie(Movie movie) async {
    final current = await loadWatchlist();
    if (!current.any((m) => m.id == movie.id)) {
      current.insert(0, movie); // Put newest at the front
      await saveWatchlist(current);
    }
    return current;
  }

  /// Removes a movie from the watchlist by ID
  Future<List<Movie>> removeMovie(int movieId) async {
    final current = await loadWatchlist();
    current.removeWhere((m) => m.id == movieId);
    await saveWatchlist(current);
    return current;
  }

  /// Checks if a movie is already present in the watchlist
  Future<bool> isMovieSaved(int movieId) async {
    final current = await loadWatchlist();
    return current.any((m) => m.id == movieId);
  }
}
