import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../utils/constants.dart';
import '../widgets/movie_card.dart';

/// Search Screen allowing real-time movie search across TMDB
class SearchScreen extends StatefulWidget {
  final TmdbService tmdbService;
  final ValueChanged<Movie> onMovieSelected;
  final bool Function(Movie) isWatchlisted;
  final ValueChanged<Movie> onWatchlistToggle;
  final VoidCallback onOpenApiKeyDialog;

  const SearchScreen({
    super.key,
    required this.tmdbService,
    required this.onMovieSelected,
    required this.isWatchlisted,
    required this.onWatchlistToggle,
    required this.onOpenApiKeyDialog,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Movie> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentQuery = '';

  // Quick search suggestions
  final List<String> _suggestions = [
    'Inception',
    'Interstellar',
    'Avengers',
    'Batman',
    'Spider-Man',
    'Oppenheimer',
    'Gladiator',
    'Dune',
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _currentQuery = '';
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    if (!widget.tmdbService.hasApiKey) {
      setState(() {
        _errorMessage =
            'Please configure your TMDB API Key in the top navigation bar to perform searches.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _currentQuery = trimmed;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await widget.tmdbService.searchMovies(trimmed);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } on TmdbApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred during search: $e';
          _isLoading = false;
        });
      }
    }
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1200) return 6;
    if (width >= 960) return 5;
    if (width >= 720) return 4;
    if (width >= 480) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Input Header
        _buildSearchBar(),

        // Quick Suggestions Bar
        _buildSuggestionsBar(),

        // Search Results or States
        Expanded(
          child: _buildResultsArea(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(bottom: BorderSide(color: Color(0xFF222222))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search for movies by title, keyword, or franchise...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppConstants.primaryRed),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _executeSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppConstants.cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppConstants.primaryRed, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: AppConstants.backgroundColor,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Popular searches: ',
                style: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              ..._suggestions.map((term) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(term),
                    labelStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    backgroundColor: AppConstants.chipBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    onPressed: () {
                      _searchController.text = term;
                      _executeSearch(term);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppConstants.primaryRed,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Searching TMDB for "$_currentQuery"...',
              style: const TextStyle(color: AppConstants.textMuted),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2E2E2E)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppConstants.primaryRed, size: 40),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppConstants.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget.onOpenApiKeyDialog,
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed),
                icon: const Icon(Icons.vpn_key, color: Colors.white, size: 16),
                label: const Text('Set API Key', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // Initial empty state (before searching)
    if (_currentQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_outlined,
                size: 64, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            const Text(
              'Explore Thousands of Movies',
              style: TextStyle(
                color: AppConstants.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Type in the search bar or choose a suggestion above to start searching.',
              style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Empty results state
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No movies found for "$_currentQuery"',
              style: const TextStyle(
                color: AppConstants.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try checking for spelling errors, using different keywords, or exploring popular titles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Search Results Grid
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.64,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final movie = _searchResults[index];
            final isSaved = widget.isWatchlisted(movie);

            return MovieCard(
              movie: movie,
              isWatchlisted: isSaved,
              onTap: () => widget.onMovieSelected(movie),
              onWatchlistToggle: () => widget.onWatchlistToggle(movie),
            );
          },
        );
      },
    );
  }
}
