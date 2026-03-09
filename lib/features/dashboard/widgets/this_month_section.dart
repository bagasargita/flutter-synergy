import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';
import 'package:flutter_synergy/features/dashboard/widgets/total_timesheet_card.dart';

/// "This Month" section: header + 2x2 stat grid + total timesheet card.
class ThisMonthSection extends StatelessWidget {
  const ThisMonthSection({
    super.key,
    required this.monthStats,
    required this.totalTimesheet,
  });

  final MonthStats monthStats;
  final TotalTimesheetInfo totalTimesheet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'This Month',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: DashboardTheme.darkText,
              ),
            ),
            Text(
              monthStats.monthLabel,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        GridView.count(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _StatCard(
              icon: Icons.schedule_rounded,
              iconColor: Colors.orange,
              title: 'Late checkin / early checkout',
              value: '${monthStats.lateCheckinEarlyCheckout}',
            ),
            _StatCard(
              icon: Icons.hourglass_empty_rounded,
              iconColor: Colors.orange,
              title: 'Short Workhours',
              value: '${monthStats.shortWorkhours}',
            ),
            _StatCard(
              icon: Icons.person_off_rounded,
              iconColor: Colors.red,
              title: 'Absences',
              value: '${monthStats.absences}',
            ),
            _StatCard(
              icon: Icons.work_rounded,
              iconColor: Colors.green,
              title: 'Works',
              value: '${monthStats.works}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        TotalTimesheetCard(totalTimesheet: totalTimesheet),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DashboardTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
