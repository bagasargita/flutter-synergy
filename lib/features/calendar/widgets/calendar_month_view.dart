import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
import 'package:flutter_synergy/features/calendar/widgets/calendar_legend_mark.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    super.key,
    required this.data,
    required this.onDaySelected,
    this.onPreviousMonth,
    this.onNextMonth,
    this.isLoadingMonth = false,
  });

  final CalendarMonthData data;
  final ValueChanged<CalendarDayInfo> onDaySelected;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final bool isLoadingMonth;

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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: isLoadingMonth
                      ? null
                      : (onPreviousMonth != null
                            ? () => onPreviousMonth!()
                            : null),
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: isLoadingMonth
                        ? Colors.grey.shade300
                        : Colors.grey.shade600,
                  ),
                  tooltip: 'Previous month',
                ),
                Expanded(
                  child: Text(
                    data.monthLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.darkText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isLoadingMonth
                      ? null
                      : (onNextMonth != null ? () => onNextMonth!() : null),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: isLoadingMonth
                        ? Colors.grey.shade300
                        : Colors.grey.shade600,
                  ),
                  tooltip: 'Next month',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                // Fixed row height; extra space for multiple legend marks under a day.
                mainAxisExtent: 60,
                mainAxisSpacing: 2,
                crossAxisSpacing: 4,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < leadingEmpty) {
                  return const SizedBox.shrink();
                }
                final dayIndex = index - leadingEmpty;
                final day = data.days[dayIndex];
                return _DayCell(
                  day: day,
                  legends: data.legends,
                  onTap: () => onDaySelected(day),
                );
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
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.legends,
    required this.onTap,
  });

  final CalendarDayInfo day;
  final List<CalendarLegendItem> legends;
  final VoidCallback onTap;

  CalendarLegendItem? _legendForKey(String? key) {
    if (key == null) return null;
    for (final e in legends) {
      if (e.key == key) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = day.isSelected;
    final isToday = day.isToday;
    final todayLegend = _legendForKey('today');
    final holidayLegend = _legendForKey('holiday');
    final isPublicHoliday = day.dayType == 'PUBLIC_HOLIDAY';
    // Holiday uses number color only; other keys (leave + late, etc.) show as dots.
    final markLegends = <CalendarLegendItem>[];
    for (final key in day.legendKeys) {
      if (key == 'holiday') continue;
      final item = _legendForKey(key);
      if (item != null) markLegends.add(item);
    }

    final Color baseColor = DashboardTheme.accentBlue;

    // Today/public holiday use number color (no solid fill).
    // Selected (non-today): outline only.
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    if (isToday) {
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
      textColor = todayLegend?.dotColor ?? baseColor;
    } else if (isSelected) {
      bgColor = Colors.transparent;
      borderColor = baseColor.withValues(alpha: 0.7);
      textColor = isPublicHoliday
          ? (holidayLegend?.dotColor ?? DashboardTheme.darkText)
          : DashboardTheme.darkText;
    } else if (isPublicHoliday) {
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
      textColor = holidayLegend?.dotColor ?? DashboardTheme.darkText;
    } else {
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
      textColor = DashboardTheme.darkText;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (markLegends.isNotEmpty)
            Transform.translate(
              offset: const Offset(0, -7),
              child: Wrap(
                spacing: 3,
                runSpacing: 1,
                alignment: WrapAlignment.center,
                children: [
                  for (final item in markLegends)
                    CalendarLegendMark(
                      color: item.dotColor,
                      symbol: item.symbol,
                      size: markLegends.length > 3 ? 5 : 6,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
