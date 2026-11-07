import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../utils/constants.dart';
import '../widgets/movie_card.dart';

enum MovieCategory { popular, topRated, upcoming, trending }

/// Movies Screen showing a responsive catalog grid with category filters
class MoviesScreen extends StatefulWidget {
  final TmdbService tmdbService;
  final ValueChanged<Movie> onMovieSelected;
  final bool Function(Movie) isWatchlisted;
  final ValueChanged<Movie> onWatchlistToggle;
  final VoidCallback onOpenApiKeyDialog;

  const MoviesScreen({
    super.key,
    required this.tmdbService,
    required this.onMovieSelected,
    required this.isWatchlisted,
    required this.onWatchlistToggle,
    required this.onOpenApiKeyDialog,
  });

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  MovieCategory _selectedCategory = MovieCategory.popular;
  List<Movie> _movies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void didUpdateWidget(covariant MoviesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbService.apiKey != widget.tmdbService.apiKey) {
      _loadMovies();
    }
  }

  Future<void> _loadMovies() async {
    if (!widget.tmdbService.hasApiKey) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Configure your TMDB API Key to browse the movie catalog.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Movie> fetched;
      switch (_selectedCategory) {
        case MovieCategory.popular:
          fetched = await widget.tmdbService.getPopularMovies();
          break;
        case MovieCategory.topRated:
          fetched = await widget.tmdbService.getTopRatedMovies();
          break;
        case MovieCategory.upcoming:
          fetched = await widget.tmdbService.getUpcomingMovies();
          break;
        case MovieCategory.trending:
          fetched = await widget.tmdbService.getTrendingMovies();
          break;
      }

      if (mounted) {
        setState(() {
          _movies = fetched;
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
          _errorMessage = 'Failed to load movies: $e';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Filter Bar
        _buildFilterHeader(),

        // Catalog Grid or State Placeholders
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(bottom: BorderSide(color: Color(0xFF222222))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Browse:',
              style: TextStyle(
                color: AppConstants.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            _buildCategoryChip('Popular', MovieCategory.popular),
            const SizedBox(width: 8),
            _buildCategoryChip('Top Rated', MovieCategory.topRated),
            const SizedBox(width: 8),
            _buildCategoryChip('Upcoming', MovieCategory.upcoming),
            const SizedBox(width: 8),
            _buildCategoryChip('Trending', MovieCategory.trending),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, MovieCategory category) {
    final bool isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        if (_selectedCategory != category) {
          setState(() => _selectedCategory = category);
          _loadMovies();
        }
      },
      selectedColor: AppConstants.primaryRed,
      backgroundColor: AppConstants.chipBackground,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppConstants.textWhite,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppConstants.primaryRed : Colors.white12,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryRed,
          strokeWidth: 3,
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
              const Icon(Icons.error_outline,
                  color: AppConstants.primaryRed, size: 40),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppConstants.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget.onOpenApiKeyDialog,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryRed),
                icon: const Icon(Icons.vpn_key, color: Colors.white, size: 16),
                label: const Text('Set API Key',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Center(
        child: Text(
          'No movies found in this category.',
          style: TextStyle(color: AppConstants.textMuted),
        ),
      );
    }

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
          itemCount: _movies.length,
          itemBuilder: (context, index) {
            final movie = _movies[index];
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
