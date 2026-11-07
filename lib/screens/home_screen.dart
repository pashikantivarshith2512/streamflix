import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../utils/constants.dart';
import '../widgets/movie_carousel.dart';

/// Home Screen featuring Billboard banner and category carousels
class HomeScreen extends StatefulWidget {
  final TmdbService tmdbService;
  final ValueChanged<Movie> onMovieSelected;
  final VoidCallback onOpenApiKeyDialog;
  final bool Function(Movie) isWatchlisted;
  final ValueChanged<Movie> onWatchlistToggle;

  const HomeScreen({
    super.key,
    required this.tmdbService,
    required this.onMovieSelected,
    required this.onOpenApiKeyDialog,
    required this.isWatchlisted,
    required this.onWatchlistToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Movie> _trendingMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _upcomingMovies = [];
  Movie? _featuredMovie;

  @override
  void initState() {
    super.initState();
    _loadAllMovies();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbService.apiKey != widget.tmdbService.apiKey) {
      _loadAllMovies();
    }
  }

  Future<void> _loadAllMovies() async {
    if (!widget.tmdbService.hasApiKey) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Please configure your TMDB API Key in the top navigation bar to stream real movie data.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch in parallel for high speed
      final results = await Future.wait([
        widget.tmdbService.getTrendingMovies(),
        widget.tmdbService.getPopularMovies(),
        widget.tmdbService.getTopRatedMovies(),
        widget.tmdbService.getUpcomingMovies(),
      ]);

      final trending = results[0];
      final popular = results[1];
      final topRated = results[2];
      final upcoming = results[3];

      // Pick a featured movie with a high-resolution backdrop
      Movie? featured;
      for (final m in [...trending, ...popular]) {
        if (m.backdropPath != null && m.backdropPath!.isNotEmpty) {
          featured = m;
          break;
        }
      }
      featured ??= trending.isNotEmpty ? trending.first : null;

      if (mounted) {
        setState(() {
          _trendingMovies = trending;
          _popularMovies = popular;
          _topRatedMovies = topRated;
          _upcomingMovies = upcoming;
          _featuredMovie = featured;
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
          _errorMessage = 'An unexpected error occurred while loading movies: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    return RefreshIndicator(
      onRefresh: _loadAllMovies,
      color: AppConstants.primaryRed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Billboard Hero Banner
            if (_featuredMovie != null)
              _buildFeaturedBanner(_featuredMovie!),

            const SizedBox(height: 16),

            // Carousels
            MovieCarousel(
              title: 'Trending This Week',
              movies: _trendingMovies,
              onMovieSelected: widget.onMovieSelected,
              isWatchlisted: widget.isWatchlisted,
              onWatchlistToggle: widget.onWatchlistToggle,
            ),

            const SizedBox(height: 16),

            MovieCarousel(
              title: 'Popular on StreamFlix',
              movies: _popularMovies,
              onMovieSelected: widget.onMovieSelected,
              isWatchlisted: widget.isWatchlisted,
              onWatchlistToggle: widget.onWatchlistToggle,
            ),

            const SizedBox(height: 16),

            MovieCarousel(
              title: 'Top Rated Classics & Hits',
              movies: _topRatedMovies,
              onMovieSelected: widget.onMovieSelected,
              isWatchlisted: widget.isWatchlisted,
              onWatchlistToggle: widget.onWatchlistToggle,
            ),

            const SizedBox(height: 16),

            MovieCarousel(
              title: 'Upcoming Releases',
              movies: _upcomingMovies,
              onMovieSelected: widget.onMovieSelected,
              isWatchlisted: widget.isWatchlisted,
              onWatchlistToggle: widget.onWatchlistToggle,
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  /// Featured Billboard Hero Banner
  Widget _buildFeaturedBanner(Movie movie) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 768;
    final backdropUrl = movie.fullBackdropUrl ?? movie.fullPosterUrl;
    final isSaved = widget.isWatchlisted(movie);

    return Container(
      width: double.infinity,
      height: isDesktop ? 480 : 380,
      decoration: const BoxDecoration(color: AppConstants.cardColor),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // High-Res Backdrop Image
          if (backdropUrl != null)
            Image.network(
              backdropUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1B1B1B),
                child: const Icon(Icons.movie, size: 80, color: Colors.white24),
              ),
            )
          else
            Container(color: const Color(0xFF1B1B1B)),

          // Cinematic Dark Gradients (Top, Left, and Bottom fade to #141414)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    AppConstants.backgroundColor.withValues(alpha: 0.8),
                    AppConstants.backgroundColor,
                  ],
                  stops: const [0.0, 0.3, 0.8, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Billboard Movie Content
          Positioned(
            left: isDesktop ? 48 : 20,
            right: isDesktop ? 100 : 20,
            bottom: isDesktop ? 40 : 20,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Featured Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FEATURED TODAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 36 : 24,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Metadata Badges (Rating, Year, Genres)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      if (movie.voteAverage > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppConstants.ratingYellow, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 13, color: AppConstants.ratingYellow),
                              const SizedBox(width: 4),
                              Text(
                                movie.formattedRating,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (movie.releaseYear.isNotEmpty)
                        Text(
                          movie.releaseYear,
                          style: const TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (movie.genres.isNotEmpty)
                        Text(
                          movie.genres.take(3).join(' • '),
                          style: const TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Overview Synopsis
                  Text(
                    movie.overview,
                    maxLines: isDesktop ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: isDesktop ? 14 : 12.5,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action Buttons (More Info + Add to Watchlist)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => widget.onMovieSelected(movie),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text(
                          'More Info',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => widget.onWatchlistToggle(movie),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54, width: 1.2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: Icon(
                          isSaved ? Icons.check : Icons.add,
                          size: 18,
                          color: isSaved ? Colors.greenAccent : Colors.white,
                        ),
                        label: Text(
                          isSaved ? 'In My List' : 'Add to My List',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmering Loading Skeleton
  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppConstants.primaryRed,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Connecting to TMDB...',
            style: TextStyle(
              color: AppConstants.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fetching trending movies and high-res posters',
            style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Error & Configuration State
  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.primaryRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppConstants.primaryRed,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection Required',
              style: TextStyle(
                color: AppConstants.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppConstants.textMuted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onOpenApiKeyDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.vpn_key, color: Colors.white, size: 16),
                  label: const Text(
                    'Configure API Key',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _loadAllMovies,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
