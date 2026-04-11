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
    // Wider cells (lower aspect ratio) when user has large text / display scaling.
    final textScaler = MediaQuery.textScalerOf(context);
    final textScale = textScaler.scale(14) / 14.0;
    final childAspectRatio = (1.35 / textScale).clamp(0.72, 1.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Month',
              style: const TextStyle(
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
          childAspectRatio: childAspectRatio,
          children: [
            _StatCard(
              icon: Icons.schedule_rounded,
              iconColor: Colors.orange,
              // Explicit two-line break so large text / narrow cards don’t squeeze one line.
              title: 'Late check-in / early checkout',
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
    final textScaler = MediaQuery.textScalerOf(context);
    final textScale = textScaler.scale(14) / 14.0;
    final iconBox = (40.0 * textScale.clamp(0.85, 1.25)).clamp(32.0, 48.0);
    final iconGlyph = (22.0 * textScale.clamp(0.85, 1.2)).clamp(18.0, 28.0);

    return Container(
      padding: EdgeInsets.all(
        (14.0 / textScale.clamp(0.9, 1.4)).clamp(8.0, 14.0),
      ),
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
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: iconGlyph),
              ),
              SizedBox(height: 10 * textScale.clamp(0.85, 1.2)),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22 * textScale.clamp(0.85, 1.25),
                  fontWeight: FontWeight.bold,
                  color: DashboardTheme.darkText,
                ),
              ),
              SizedBox(height: 4 * textScale.clamp(0.85, 1.2)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12 * textScale.clamp(0.85, 1.25),
                  color: Colors.grey.shade600,
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
