import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    super.key,
    required this.data,
    required this.onDaySelected,
  });

  final CalendarMonthData data;
  final ValueChanged<CalendarDayInfo> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final firstDay = data.days.first.date;
    final leadingEmpty =
        (firstDay.weekday % 7); // Sunday=0, Monday=1, ..., Saturday=6
    final totalCells = leadingEmpty + data.days.length;

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
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                Text(
                  data.monthLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.darkText,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _WeekdayLabel('SUN'),
                _WeekdayLabel('MON'),
                _WeekdayLabel('TUE'),
                _WeekdayLabel('WED'),
                _WeekdayLabel('THU'),
                _WeekdayLabel('FRI'),
                _WeekdayLabel('SAT'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < leadingEmpty) {
                  return const SizedBox.shrink();
                }
                final dayIndex = index - leadingEmpty;
                final day = data.days[dayIndex];
                return _DayCell(day: day, onTap: () => onDaySelected(day));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.onTap});

  final CalendarDayInfo day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = day.isSelected;
    final isToday = day.isToday;

    final Color baseColor = DashboardTheme.accentBlue;

    final Color bgColor = isSelected ? baseColor : Colors.transparent;
    final Color borderColor = isToday && !isSelected
        ? baseColor.withValues(alpha: 0.7)
        : Colors.transparent;
    final Color textColor = isSelected ? Colors.white : DashboardTheme.darkText;

    final legendColor = _legendColorForKey(day.legendKey);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (legendColor != null)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: legendColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Color? _legendColorForKey(String? key) {
    switch (key) {
      case 'today':
        return const Color(0xFF1A73E8);
      case 'late_checkin':
        return const Color(0xFFF4B400);
      case 'leave':
        return const Color(0xFF34A853);
      case 'public_holiday':
        return const Color(0xFFEA4335);
      case 'absence':
        return const Color(0xFF9E9E9E);
      case 'trip':
        return const Color(0xFF5C6BC0);
    }
    return null;
  }
}
