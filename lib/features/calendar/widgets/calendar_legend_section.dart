import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
import 'package:flutter_synergy/features/calendar/widgets/calendar_legend_mark.dart';

class CalendarLegendSection extends StatelessWidget {
  const CalendarLegendSection({super.key, required this.items});

  final List<CalendarLegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LEGEND',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),
        ..._legendRows(),
      ],
    );
  }

  List<Widget> _legendRows() {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _LegendRowCell(item: items[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < items.length
                    ? _LegendRowCell(item: items[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}

class _LegendRowCell extends StatelessWidget {
  const _LegendRowCell({required this.item});

  final CalendarLegendItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: CalendarLegendMark(
              color: item.dotColor,
              symbol: item.symbol,
              size: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              height: 1.95,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
