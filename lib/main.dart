import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/movie.dart';
import 'screens/details_screen.dart';
import 'screens/home_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/search_screen.dart';
import 'screens/watchlist_screen.dart';
import 'services/tmdb_service.dart';
import 'services/watchlist_service.dart';
import 'utils/constants.dart';
import 'widgets/app_nav_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StreamFlixApp());
}

/// Root Application Widget
class StreamFlixApp extends StatelessWidget {
  const StreamFlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        primaryColor: AppConstants.primaryRed,
        cardColor: AppConstants.cardColor,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryRed,
          surface: AppConstants.surfaceColor,
          onPrimary: Colors.white,
          onSurface: AppConstants.textWhite,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.surfaceColor,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppConstants.textWhite,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: AppConstants.textWhite),
          bodyMedium: TextStyle(color: AppConstants.textMuted),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

/// Main Shell holding top navigation bar and active screen
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  NavTab _activeTab = NavTab.home;
  String _tmdbApiKey = AppConstants.defaultTmdbApiKey;
  late TmdbService _tmdbService;
  final WatchlistService _watchlistService = const WatchlistService();

  // Watchlist state synced with SharedPreferences
  final Set<int> _watchlistedMovieIds = {};
  final List<Movie> _watchlistMovies = [];

  @override
  void initState() {
    super.initState();
    _tmdbService = TmdbService(apiKey: _tmdbApiKey);
    _loadSavedApiKey();
    _loadWatchlist();
  }

  Future<void> _loadSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(AppConstants.prefApiKey);
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      setState(() {
        _tmdbApiKey = savedKey.trim();
        _tmdbService = TmdbService(apiKey: _tmdbApiKey);
      });
    }
  }

  Future<void> _loadWatchlist() async {
    final saved = await _watchlistService.loadWatchlist();
    if (mounted) {
      setState(() {
        _watchlistMovies.clear();
        _watchlistMovies.addAll(saved);
        _watchlistedMovieIds.clear();
        _watchlistedMovieIds.addAll(saved.map((m) => m.id));
      });
    }
  }

  Future<void> _saveApiKey(String newKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefApiKey, newKey.trim());
    setState(() {
      _tmdbApiKey = newKey.trim();
      _tmdbService = TmdbService(apiKey: _tmdbApiKey);
    });
  }

  bool _isMovieWatchlisted(Movie movie) {
    return _watchlistedMovieIds.contains(movie.id);
  }

  Future<void> _toggleWatchlist(Movie movie) async {
    final isAlreadySaved = _watchlistedMovieIds.contains(movie.id);

    if (isAlreadySaved) {
      final updated = await _watchlistService.removeMovie(movie.id);
      if (mounted) {
        setState(() {
          _watchlistMovies.clear();
          _watchlistMovies.addAll(updated);
          _watchlistedMovieIds.remove(movie.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${movie.title}" from My List'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppConstants.cardColor,
          ),
        );
      }
    } else {
      final updated = await _watchlistService.addMovie(movie);
      if (mounted) {
        setState(() {
          _watchlistMovies.clear();
          _watchlistMovies.addAll(updated);
          _watchlistedMovieIds.add(movie.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${movie.title}" to My List'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppConstants.primaryRed,
          ),
        );
      }
    }
  }

  void _onMovieSelected(Movie movie) {
    DetailsScreen.show(
      context,
      movie: movie,
      tmdbService: _tmdbService,
      isWatchlisted: _isMovieWatchlisted(movie),
      onWatchlistToggle: _toggleWatchlist,
    );
  }

  void _showApiKeyDialog() {
    final TextEditingController controller =
        TextEditingController(text: _tmdbApiKey);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: AppConstants.primaryRed),
              SizedBox(width: 8),
              Text(
                'TMDB API Configuration',
                style: TextStyle(color: AppConstants.textWhite, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your free TMDB API Key (v3 auth) below to fetch real movies, posters, and details from The Movie Database:',
                style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppConstants.textWhite),
                decoration: InputDecoration(
                  labelText: 'TMDB API Key',
                  labelStyle: const TextStyle(color: AppConstants.textMuted),
                  hintText: 'e.g. 15d2ce6754406a61321f...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: AppConstants.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppConstants.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: As a client-side Flutter Web application, API keys are stored in your browser local storage and communicated directly with api.themoviedb.org.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppConstants.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveApiKey(controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('TMDB API Key updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
              ),
              child: const Text('Save Key', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sticky Top Navigation Bar
          AppNavBar(
            activeTab: _activeTab,
            onTabSelected: (tab) => setState(() => _activeTab = tab),
            onApiKeyPressed: _showApiKeyDialog,
            hasApiKey: _tmdbApiKey.isNotEmpty,
          ),

          // Active View Body
          Expanded(
            child: _buildCurrentScreen(),
          ),

          // Footer with TMDB Attribution
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_activeTab) {
      case NavTab.home:
        return HomeScreen(
          tmdbService: _tmdbService,
          onMovieSelected: _onMovieSelected,
          onOpenApiKeyDialog: _showApiKeyDialog,
          isWatchlisted: _isMovieWatchlisted,
          onWatchlistToggle: _toggleWatchlist,
        );
      case NavTab.movies:
        return MoviesScreen(
          tmdbService: _tmdbService,
          onMovieSelected: _onMovieSelected,
          isWatchlisted: _isMovieWatchlisted,
          onWatchlistToggle: _toggleWatchlist,
          onOpenApiKeyDialog: _showApiKeyDialog,
        );
      case NavTab.search:
        return SearchScreen(
          tmdbService: _tmdbService,
          onMovieSelected: _onMovieSelected,
          isWatchlisted: _isMovieWatchlisted,
          onWatchlistToggle: _toggleWatchlist,
          onOpenApiKeyDialog: _showApiKeyDialog,
        );
      case NavTab.watchlist:
        return WatchlistScreen(
          watchlist: _watchlistMovies,
          onMovieSelected: _onMovieSelected,
          onRemoveFromWatchlist: _toggleWatchlist,
          onBrowseMovies: () => setState(() => _activeTab = NavTab.movies),
        );
    }
  }



  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(top: BorderSide(color: Color(0xFF222222))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 14, color: AppConstants.textMuted),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              AppConstants.tmdbAttribution,
              style: TextStyle(color: AppConstants.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
