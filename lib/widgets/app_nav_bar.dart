import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Navigation item definition
enum NavTab { home, movies, search, watchlist }

/// Responsive Top Navigation Bar
class AppNavBar extends StatelessWidget {
  final NavTab activeTab;
  final ValueChanged<NavTab> onTabSelected;
  final VoidCallback onApiKeyPressed;
  final bool hasApiKey;

  const AppNavBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onApiKeyPressed,
    required this.hasApiKey,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Show full horizontal tabs only on wide screens (>= 850px)
    final bool isDesktop = screenWidth >= 850;
    final bool isCompact = screenWidth < 500;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF222222), width: 1),
        ),
      ),
      child: Row(
        children: [
          // StreamFlix Logo
          _buildLogo(context, isCompact: isCompact),

          const SizedBox(width: 16),

          // Desktop Navigation Tabs
          if (isDesktop) ...[
            _buildNavItem('Home', NavTab.home),
            const SizedBox(width: 8),
            _buildNavItem('Movies', NavTab.movies),
            const SizedBox(width: 8),
            _buildNavItem('Search', NavTab.search),
            const SizedBox(width: 8),
            _buildNavItem('My List', NavTab.watchlist),
          ],

          const Spacer(),

          // API Key status / button
          _buildApiKeyAction(context, isCompact: isCompact),

          // Mobile Drawer Hamburger Menu
          if (!isDesktop) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.menu, color: AppConstants.textWhite),
              onPressed: () => _openMobileMenu(context),
              tooltip: 'Navigation Menu',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, {required bool isCompact}) {
    return InkWell(
      onTap: () => onTabSelected(NavTab.home),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.primaryRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (!isCompact)
              const Text(
                'STREAMFLIX',
                style: TextStyle(
                  color: AppConstants.primaryRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, NavTab tab) {
    final bool isSelected = activeTab == tab;

    return InkWell(
      onTap: () => onTabSelected(tab),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppConstants.textWhite : AppConstants.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyAction(BuildContext context, {required bool isCompact}) {
    return Tooltip(
      message: hasApiKey ? 'TMDB API Key configured' : 'Configure TMDB API Key',
      child: OutlinedButton.icon(
        onPressed: onApiKeyPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: hasApiKey ? Colors.green.shade700 : AppConstants.primaryRed,
            width: 1,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          backgroundColor: hasApiKey
              ? Colors.green.shade900.withValues(alpha: 0.2)
              : AppConstants.primaryRed.withValues(alpha: 0.15),
        ),
        icon: Icon(
          hasApiKey ? Icons.check_circle_outline : Icons.vpn_key_outlined,
          size: 15,
          color: hasApiKey ? Colors.greenAccent : AppConstants.textWhite,
        ),
        label: Text(
          hasApiKey
              ? (isCompact ? 'Active' : 'TMDB Active')
              : (isCompact ? 'API Key' : 'Set API Key'),
          style: TextStyle(
            color: hasApiKey ? Colors.greenAccent : AppConstants.textWhite,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _openMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _buildMobileListTile(ctx, 'Home', Icons.home_outlined, NavTab.home),
              _buildMobileListTile(ctx, 'Movies', Icons.movie_outlined, NavTab.movies),
              _buildMobileListTile(ctx, 'Search', Icons.search_outlined, NavTab.search),
              _buildMobileListTile(
                  ctx, 'My List', Icons.bookmark_border_outlined, NavTab.watchlist),
              const Divider(color: Color(0xFF2E2E2E)),
              ListTile(
                leading: Icon(
                  hasApiKey ? Icons.check_circle_outline : Icons.vpn_key_outlined,
                  color: hasApiKey ? Colors.greenAccent : AppConstants.primaryRed,
                ),
                title: Text(
                  hasApiKey ? 'TMDB API Configured' : 'Configure TMDB API Key',
                  style: const TextStyle(color: AppConstants.textWhite),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onApiKeyPressed();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileListTile(
    BuildContext context,
    String title,
    IconData icon,
    NavTab tab,
  ) {
    final bool isSelected = activeTab == tab;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppConstants.primaryRed : AppConstants.textMuted,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppConstants.primaryRed : AppConstants.textWhite,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTabSelected(tab);
      },
    );
  }
}
