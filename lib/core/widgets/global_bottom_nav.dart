import 'package:flutter/material.dart';

/// Global bottom navigation bar used across the app (e.g. Dashboard).
/// Avoids overflow by reserving content height and safe-area padding separately.
class GlobalBottomNav extends StatelessWidget {
  const GlobalBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.selectedColor,
    this.unselectedColor,
  });

  final List<GlobalBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? selectedColor;
  final Color? unselectedColor;

  static const double _contentHeight = 56;
  static const double _iconSize = 22;
  static const double _fontSize = 11;
  static const double _verticalPadding = 6;
  static const double _spacing = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedColor ?? theme.colorScheme.primary;
    final unselected = unselectedColor ?? Colors.grey.shade400;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _contentHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = currentIndex == index;
                return _GlobalNavItem(
                  label: item.label,
                  icon: item.icon,
                  isSelected: isSelected,
                  color: isSelected ? selected : unselected,
                  iconSize: _iconSize,
                  fontSize: _fontSize,
                  verticalPadding: _verticalPadding,
                  spacing: _spacing,
                  onTap: () {
                    onTap(index);
                    item.onSelected?.call();
                  },
                );
              }),
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

/// Single item for [GlobalBottomNav].
class GlobalBottomNavItem {
  const GlobalBottomNavItem({
    required this.label,
    required this.icon,
    this.onSelected,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onSelected;
}

class _GlobalNavItem extends StatelessWidget {
  const _GlobalNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.iconSize,
    required this.fontSize,
    required this.verticalPadding,
    required this.spacing,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final double iconSize;
  final double fontSize;
  final double verticalPadding;
  final double spacing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            SizedBox(height: spacing),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
