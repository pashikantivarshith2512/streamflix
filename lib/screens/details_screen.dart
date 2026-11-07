import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../utils/constants.dart';

/// Screen or Modal Dialog displaying comprehensive details for a movie
class DetailsScreen extends StatefulWidget {
  final Movie movie;
  final TmdbService tmdbService;
  final bool isWatchlisted;
  final ValueChanged<Movie> onWatchlistToggle;
  final VoidCallback? onClose;

  const DetailsScreen({
    super.key,
    required this.movie,
    required this.tmdbService,
    required this.isWatchlisted,
    required this.onWatchlistToggle,
    this.onClose,
  });

  /// Helper to open the Details screen cleanly in a responsive dialog / modal
  static Future<void> show(
    BuildContext context, {
    required Movie movie,
    required TmdbService tmdbService,
    required bool isWatchlisted,
    required ValueChanged<Movie> onWatchlistToggle,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: DetailsScreen(
            movie: movie,
            tmdbService: tmdbService,
            isWatchlisted: isWatchlisted,
            onWatchlistToggle: onWatchlistToggle,
            onClose: () => Navigator.pop(ctx),
          ),
        );
      },
    );
  }

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Movie _currentMovie;
  late bool _isSaved;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _isSaved = widget.isWatchlisted;
    _fetchEnrichedDetails();
  }

  Future<void> _fetchEnrichedDetails() async {
    // If runtime is already present or no API key, skip
    if (_currentMovie.runtime != null || !widget.tmdbService.hasApiKey) return;

    setState(() => _isLoadingDetails = true);
    try {
      final fullMovie = await widget.tmdbService.getMovieDetails(_currentMovie.id);
      if (mounted) {
        setState(() {
          _currentMovie = _currentMovie.copyWith(
            runtime: fullMovie.runtime,
            genres: fullMovie.genres.isNotEmpty ? fullMovie.genres : _currentMovie.genres,
            overview: fullMovie.overview.isNotEmpty ? fullMovie.overview : _currentMovie.overview,
          );
          _isLoadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  void _handleWatchlistToggle() {
    setState(() => _isSaved = !_isSaved);
    widget.onWatchlistToggle(_currentMovie);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E2E2E), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Scrollable Body
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Backdrop Hero Banner Header
                        _buildBackdropHeader(),

                        // Content (Poster + Metadata + Overview)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildDetailsContent(),
                        ),
                      ],
                    ),
                  ),

                  // Close Button (Top Right)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onClose ?? () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackdropHeader() {
    final backdropUrl = _currentMovie.fullBackdropUrl ?? _currentMovie.fullPosterUrl;

    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backdropUrl != null)
            Image.network(
              backdropUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1B1B1B),
                child: const Icon(Icons.movie, size: 64, color: Colors.white24),
              ),
            )
          else
            Container(color: const Color(0xFF1B1B1B)),

          // Gradient fading into surface background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  AppConstants.surfaceColor.withValues(alpha: 0.6),
                  AppConstants.surfaceColor,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Movie Poster
              _buildPosterCard(width: 180, height: 270),

              const SizedBox(width: 24),

              // Metadata & Synopsis
              Expanded(
                child: _buildMetadataColumn(),
              ),
            ],
          );
        } else {
          // Mobile layout: Vertical Stack
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPosterCard(width: 110, height: 165),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTitleAndBadges(isCompact: true)),
                ],
              ),
              const SizedBox(height: 18),
              _buildWatchlistButton(),
              const SizedBox(height: 20),
              _buildOverviewSection(),
            ],
          );
        }
      },
    );
  }

  Widget _buildPosterCard({required double width, required double height}) {
    final posterUrl = _currentMovie.fullPosterUrl;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: posterUrl != null
            ? Image.network(
                posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPosterFallback(),
              )
            : _buildPosterFallback(),
      ),
    );
  }

  Widget _buildPosterFallback() {
    return Container(
      color: const Color(0xFF222222),
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, size: 40, color: Colors.white24),
      ),
    );
  }

  Widget _buildMetadataColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleAndBadges(isCompact: false),
        const SizedBox(height: 18),
        _buildWatchlistButton(),
        const SizedBox(height: 20),
        _buildOverviewSection(),
      ],
    );
  }

  Widget _buildTitleAndBadges({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          _currentMovie.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isCompact ? 18 : 26,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 10),

        // Metadata Pills (Rating, Year, Runtime)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Rating Badge
            if (_currentMovie.voteAverage > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppConstants.ratingYellow.withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: AppConstants.ratingYellow, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      _currentMovie.formattedRating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Release Year
            if (_currentMovie.releaseYear.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _currentMovie.releaseYear,
                  style: const TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Runtime (if available or loading)
            if (_currentMovie.formattedRuntime != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _currentMovie.formattedRuntime!,
                  style: const TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (_isLoadingDetails)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppConstants.primaryRed,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Genre Chips
        if (_currentMovie.genres.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _currentMovie.genres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWatchlistButton() {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: _handleWatchlistToggle,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isSaved ? AppConstants.cardColor : AppConstants.primaryRed,
          foregroundColor: Colors.white,
          side: BorderSide(
            color: _isSaved ? Colors.white38 : AppConstants.primaryRed,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(
          _isSaved ? Icons.check_circle_outline : Icons.bookmark_add_outlined,
          size: 18,
          color: _isSaved ? Colors.greenAccent : Colors.white,
        ),
        label: Text(
          _isSaved ? 'In My List (Click to Remove)' : 'Add to My List',
          style: TextStyle(
            color: _isSaved ? Colors.greenAccent : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentMovie.overview,
          style: const TextStyle(
            color: AppConstants.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
