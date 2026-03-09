import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';

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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: items.map((e) => _LegendItem(item: e)).toList(),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.item});

  final CalendarLegendItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: item.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          item.label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
