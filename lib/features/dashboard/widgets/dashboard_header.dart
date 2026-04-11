import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

/// Header with avatar, greeting ("Good morning,"), user name, and "Dashboard" title.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userName,
    this.title = 'Dashboard',
    this.avatarUrl,
    this.initial,
  });

  final String userName;
  final String title;

  /// Profile photo URL from API; when null/empty, [initial] is shown instead.
  final String? avatarUrl;

  /// Short initials inside the avatar when [avatarUrl] is not available.
  final String? initial;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _HeaderAvatar(
              avatarUrl: avatarUrl,
              initial: initial,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DashboardTheme.darkText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.darkText,
          ),
        ),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.avatarUrl,
    required this.initial,
  });

  final String? avatarUrl;
  final String? initial;

  static const double _size = 48;
  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _initialCircle(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: _size,
              height: _size,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DashboardTheme.accentBlue.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _initialCircle();
  }

  Widget _initialCircle() {
    final label = (initial ?? '').trim();
    return CircleAvatar(
      radius: _radius,
      backgroundColor: DashboardTheme.accentBlue.withValues(alpha: 0.12),
      child: label.isNotEmpty
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: DashboardTheme.accentBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : const Icon(
              Icons.person_rounded,
              color: DashboardTheme.accentBlue,
              size: 28,
            ),
    );
  }
}
