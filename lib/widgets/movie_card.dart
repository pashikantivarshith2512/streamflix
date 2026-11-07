import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../utils/constants.dart';

/// Reusable Movie Poster Card with hover animation and fallback handling
class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool isWatchlisted;
  final VoidCallback? onWatchlistToggle;
  final double width;
  final double height;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.isWatchlisted = false,
    this.onWatchlistToggle,
    this.width = 160,
    this.height = 240,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final posterUrl = widget.movie.fullPosterUrl;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppConstants.primaryRed.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Poster Image or Fallback
                  if (posterUrl != null)
                    Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingPlaceholder();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFallbackPoster();
                      },
                    )
                  else
                    _buildFallbackPoster(),

                  // Dark gradient overlay at the bottom for readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.9),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Rating Badge (Top Right)
                  if (widget.movie.voteAverage > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppConstants.ratingYellow.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppConstants.ratingYellow,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.movie.formattedRating,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Watchlist Bookmark Button (Top Left)
                  if (widget.onWatchlistToggle != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onWatchlistToggle,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isWatchlisted
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 16,
                              color: widget.isWatchlisted
                                  ? AppConstants.primaryRed
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Title and Year Overlay (Bottom)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (widget.movie.releaseYear.isNotEmpty)
                              Text(
                                widget.movie.releaseYear,
                                style: const TextStyle(
                                  color: AppConstants.textMuted,
                                  fontSize: 10.5,
                                ),
                              ),
                            if (widget.movie.releaseYear.isNotEmpty &&
                                widget.movie.genres.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: AppConstants.textMuted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            if (widget.movie.genres.isNotEmpty)
                              Expanded(
                                child: Text(
                                  widget.movie.genres.first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppConstants.textMuted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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

  /// Shimmering/Spinning Loading Indicator
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppConstants.cardColor,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppConstants.primaryRed,
          ),
        ),
      ),
    );
  }

  /// Fallback card when no poster is available
  Widget _buildFallbackPoster() {
    return Container(
      color: const Color(0xFF222222),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 36,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            widget.movie.title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
