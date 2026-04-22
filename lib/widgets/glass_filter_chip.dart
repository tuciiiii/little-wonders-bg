import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Horizontal scrollable filter chip row — used by Map and Badges screens.
class GlassFilterChipRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color? activeColor;
  final List<Widget?>? leadingIcons; // optional icon per chip (index-aligned, may be null)

  const GlassFilterChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.activeColor,
    this.leadingIcons,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppTheme.accentGold;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          final leading  = (leadingIcons != null && i < leadingIcons!.length) ? leadingIcons![i] : null;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: selected ? active.withValues(alpha: 0.15) : AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: selected ? active.withValues(alpha: 0.60) : AppTheme.glassBorder,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: active.withValues(alpha: 0.15), blurRadius: 12)]
                        : null,
                  ),
                  child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (leading != null) ...[leading, const SizedBox(width: 5)],
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontFamily: 'Karla', fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? active : AppTheme.textSecondary,
                          letterSpacing: selected ? 0.3 : 0,
                        ),
                        child: Text(labels[i]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}