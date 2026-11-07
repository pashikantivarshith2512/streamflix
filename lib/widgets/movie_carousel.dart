import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../utils/constants.dart';
import 'movie_card.dart';

/// Horizontal carousel displaying a list of movies with category heading
class MovieCarousel extends StatefulWidget {
  final String title;
  final List<Movie> movies;
  final ValueChanged<Movie>? onMovieSelected;
  final bool Function(Movie)? isWatchlisted;
  final ValueChanged<Movie>? onWatchlistToggle;

  const MovieCarousel({
    super.key,
    required this.title,
    required this.movies,
    this.onMovieSelected,
    this.isWatchlisted,
    this.onWatchlistToggle,
  });

  @override
  State<MovieCarousel> createState() => _MovieCarouselState();
}

class _MovieCarouselState extends State<MovieCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollIndicators);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
  }

  @override
  void didUpdateWidget(covariant MovieCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movies.length != widget.movies.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    final canLeft = currentScroll > 10;
    final canRight = currentScroll < (maxScroll - 10);

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + offset)
          .clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppConstants.primaryRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppConstants.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // Carousel Scroll Area with Arrow Buttons
        SizedBox(
          height: 255,
          child: Stack(
            children: [
              ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.touch,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  itemCount: widget.movies.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final movie = widget.movies[index];
                    final isSaved = widget.isWatchlisted?.call(movie) ?? false;

                    return MovieCard(
                      movie: movie,
                      isWatchlisted: isSaved,
                      onTap: () => widget.onMovieSelected?.call(movie),
                      onWatchlistToggle: widget.onWatchlistToggle != null
                          ? () => widget.onWatchlistToggle!(movie)
                          : null,
                    );
                  },
                ),
              ),

              // Left Desktop Navigation Arrow
              if (_canScrollLeft)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildScrollButton(
                    icon: Icons.chevron_left,
                    onTap: () => _scrollBy(-400),
                    alignment: Alignment.centerLeft,
                  ),
                ),

              // Right Desktop Navigation Arrow
              if (_canScrollRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildScrollButton(
                    icon: Icons.chevron_right,
                    onTap: () => _scrollBy(400),
                    alignment: Alignment.centerRight,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollButton({
    required IconData icon,
    required VoidCallback onTap,
    required Alignment alignment,
  }) {
    return Container(
      width: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
          begin: alignment == Alignment.centerLeft
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: alignment == Alignment.centerLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
        ),
      ),
      child: Center(
        child: Material(
          color: Colors.black.withValues(alpha: 0.6),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
