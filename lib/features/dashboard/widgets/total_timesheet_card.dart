import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

/// Single card showing "Total Timesheet" with checkmark icon and total hours.
class TotalTimesheetCard extends StatelessWidget {
  const TotalTimesheetCard({
    super.key,
    required this.totalTimesheet,
  });

  final TotalTimesheetInfo totalTimesheet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Total Timesheet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DashboardTheme.darkText,
              ),
            ),
          ),
          Text(
            totalTimesheet.totalHours,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DashboardTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
