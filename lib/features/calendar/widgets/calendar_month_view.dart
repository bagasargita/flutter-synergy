import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
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
                      fontSize: 16,
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
                // Fixed row height avoids default square cells (extra gap under SUN–SAT).
                mainAxisExtent: 50,
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
        fontSize: 11,
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

    final Color baseColor = DashboardTheme.accentBlue;

    final Color bgColor = isSelected ? baseColor : Colors.transparent;
    final Color borderColor = isToday && !isSelected
        ? baseColor.withValues(alpha: 0.7)
        : Colors.transparent;
    final Color textColor = isSelected ? Colors.white : DashboardTheme.darkText;

    final legend = _legendForKey(day.legendKey);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
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
          const SizedBox(height: 2),
          if (legend != null)
            _LegendMark(
              color: legend.dotColor,
              symbol: legend.symbol ?? 'circle',
            ),
        ],
      ),
    );
  }
}

class _LegendMark extends StatelessWidget {
  const _LegendMark({required this.color, required this.symbol});

  final Color color;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final s = symbol.toLowerCase();
    if (s == 'triangle') {
      return CustomPaint(
        size: const Size(8, 6),
        painter: _TrianglePainter(color),
      );
    }
    if (s == 'square') {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
