import 'package:flutter/material.dart';

/// Shape for calendar legend / day dots. API: `null` → circle; `circle` | `triangle` | `square`.
class CalendarLegendMark extends StatelessWidget {
  const CalendarLegendMark({
    super.key,
    required this.color,
    this.symbol,
    this.size = 8,
  });

  final Color color;
  final String? symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = symbol?.trim() ?? '';
    final s = trimmed.isEmpty ? 'circle' : trimmed.toLowerCase();

    if (s == 'triangle') {
      final w = size * 1.15;
      final h = size * 0.85;
      return CustomPaint(
        size: Size(w, h),
        painter: _LegendTrianglePainter(color),
      );
    }
    if (s == 'square') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1.5),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendTrianglePainter extends CustomPainter {
  _LegendTrianglePainter(this.color);

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
