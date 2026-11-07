import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../utils/constants.dart';
import '../widgets/movie_card.dart';

/// Watchlist ("My List") Screen displaying saved movies persisted across sessions
class WatchlistScreen extends StatelessWidget {
  final List<Movie> watchlist;
  final ValueChanged<Movie> onMovieSelected;
  final ValueChanged<Movie> onRemoveFromWatchlist;
  final VoidCallback onBrowseMovies;

  const WatchlistScreen({
    super.key,
    required this.watchlist,
    required this.onMovieSelected,
    required this.onRemoveFromWatchlist,
    required this.onBrowseMovies,
  });

  int _calculateCrossAxisCount(double width) {
    if (width >= 1200) return 6;
    if (width >= 960) return 5;
    if (width >= 720) return 4;
    if (width >= 480) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    if (watchlist.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Watchlist Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: AppConstants.surfaceColor,
            border: Border(bottom: BorderSide(color: Color(0xFF222222))),
          ),
          child: Row(
            children: [
              const Icon(Icons.bookmark, color: AppConstants.primaryRed, size: 22),
              const SizedBox(width: 8),
              const Text(
                'My List',
                style: TextStyle(
                  color: AppConstants.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.primaryRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.primaryRed.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${watchlist.length} ${watchlist.length == 1 ? "Movie" : "Movies"} Saved',
                  style: const TextStyle(
                    color: AppConstants.primaryRed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid of Saved Movies
        Expanded(
          child: LayoutBuilder(
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
                itemCount: watchlist.length,
                itemBuilder: (context, index) {
                  final movie = watchlist[index];

                  return MovieCard(
                    movie: movie,
                    isWatchlisted: true,
                    onTap: () => onMovieSelected(movie),
                    onWatchlistToggle: () => onRemoveFromWatchlist(movie),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: AppConstants.primaryRed,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Watchlist is Empty',
              style: TextStyle(
                color: AppConstants.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Keep track of movies you want to watch later. Click the bookmark icon on any movie poster or banner to add it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBrowseMovies,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.movie_filter_outlined, color: Colors.white, size: 18),
              label: const Text(
                'Browse Movies Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
