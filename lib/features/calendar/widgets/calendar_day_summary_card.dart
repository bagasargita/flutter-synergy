import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

class CalendarDaySummaryCard extends StatelessWidget {
  const CalendarDaySummaryCard({
    super.key,
    required this.attendance,
    required this.timesheetHours,
  });

  final DailyAttendanceInfo attendance;
  final String timesheetHours;

  @override
  Widget build(BuildContext context) {
    final isHoliday = attendance.dayType == 'PUBLIC_HOLIDAY';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20),
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
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            decoration: BoxDecoration(
              color: isHoliday
                  ? const Color(0xFFFFF1F1)
                  : const Color(0xFFE7F0FF),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.date,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isHoliday
                              ? Colors.red.shade700
                              : DashboardTheme.darkText,
                        ),
                      ),
                      if (attendance.holidayName != null &&
                          attendance.holidayName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          attendance.holidayName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isHoliday
                                ? Colors.red.shade700
                                : DashboardTheme.darkText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isHoliday
                        ? Colors.red.shade100
                        : const Color(0xFFD2E1FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isHoliday ? 'PUBLIC HOLIDAY' : 'WORKING DAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isHoliday
                          ? Colors.red.shade700
                          : const Color(0xFF6575CF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _ColumnInfo(
                  label: 'CHECK IN',
                  value: attendance.checkIn ?? '-',
                ),
                _ColumnInfo(
                  label: 'CHECK OUT',
                  value: attendance.checkOut ?? '-',
                ),
                _ColumnInfo(label: 'TIMESHEET', value: timesheetHours),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnInfo extends StatelessWidget {
  const _ColumnInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DashboardTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
