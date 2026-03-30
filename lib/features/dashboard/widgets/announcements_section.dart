import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

/// Max height for the banner area so tall infographics scale down but stay fully visible.
const double _kAnnouncementBannerHeight = 280;

/// Page viewport: header row + banner + bottom padding + card padding.
const double _kAnnouncementPageHeight = 400;

/// Announcements section with "View All" and carousel-style cards with pagination dots.
class AnnouncementsSection extends StatelessWidget {
  const AnnouncementsSection({
    super.key,
    required this.announcements,
    this.onViewAll,
  });

  final List<Announcement> announcements;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Announcements',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: DashboardTheme.darkText,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.accentBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (announcements.isEmpty)
          const SizedBox.shrink()
        else
          AnnouncementCarousel(announcements: announcements),
      ],
    );
  }
}

/// Single announcement card with image placeholder, title, date, and pagination dots.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
  });

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: Colors.orange.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.grey.shade100,
                child: SizedBox(
                  width: double.infinity,
                  height: _kAnnouncementBannerHeight,
                  child: _announcementBanner(announcement),
                ),
              ),
            ),
          ),
          if (announcement.date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                announcement.date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// Carousel of announcements with page indicator dots.
class AnnouncementCarousel extends StatefulWidget {
  const AnnouncementCarousel({
    super.key,
    required this.announcements,
  });

  final List<Announcement> announcements;

  @override
  State<AnnouncementCarousel> createState() => _AnnouncementCarouselState();
}

class _AnnouncementCarouselState extends State<AnnouncementCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _kAnnouncementPageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.announcements.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnnouncementCard(
                  announcement: widget.announcements[index],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.announcements.length,
            (index) {
              final isActive = index == _currentPage;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? DashboardTheme.accentBlue
                      : Colors.grey.shade300,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _announcementBanner(Announcement announcement) {
  final url = announcement.fileUrl;
  if (url != null && url.isNotEmpty) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      width: double.infinity,
      height: _kAnnouncementBannerHeight,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DashboardTheme.accentBlue,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _announcementPlaceholder(),
    );
  }
  final asset = announcement.imageAsset;
  if (asset != null && asset.isNotEmpty) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      width: double.infinity,
      height: _kAnnouncementBannerHeight,
      errorBuilder: (_, __, ___) => _announcementPlaceholder(),
    );
  }
  return _announcementPlaceholder();
}

Widget _announcementPlaceholder() {
  return Container(
    width: double.infinity,
    height: _kAnnouncementBannerHeight,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF5BA3D0), Color(0xFF7EC8E3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(
        Icons.campaign_rounded,
        size: 48,
        color: Colors.white70,
      ),
    ),
  );
}
