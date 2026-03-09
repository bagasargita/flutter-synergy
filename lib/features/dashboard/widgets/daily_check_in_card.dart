import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

/// Daily status card: date, holiday tag, CHECK IN/CHECK OUT, and primary action button.
class DailyCheckInCard extends StatelessWidget {
  const DailyCheckInCard({
    super.key,
    required this.attendance,
    this.onCheckIn,
    this.onCheckOut,
  });

  final DailyAttendanceInfo attendance;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;

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
          // Colored header (red for holiday, blue for working day)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            decoration: BoxDecoration(
              color: isHoliday
                  ? const Color(0xFFFFF1F1) // soft red
                  : const Color(0xFFE7F0FF), // soft blue
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
          // Body content with its own horizontal padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CHECK IN / CHECK OUT
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'CHECK IN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attendance.checkIn ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DashboardTheme.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'CHECK OUT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attendance.checkOut ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DashboardTheme.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (attendance.primaryAction == 'Check In') {
                        onCheckIn?.call();
                      } else {
                        onCheckOut?.call();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: DashboardTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          attendance.primaryAction,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
