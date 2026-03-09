import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

/// Header with avatar, greeting ("Good morning,"), user name, and "Dashboard" title.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userName,
    this.title = 'Dashboard',
  });

  final String userName;
  final String title;

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
            CircleAvatar(
              radius: 24,
              backgroundColor: DashboardTheme.accentBlue.withValues(
                alpha: 0.12,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: DashboardTheme.accentBlue,
                size: 28,
              ),
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
