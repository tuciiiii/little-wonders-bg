import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Horizontal scrollable filter chip row — used by Map and Badges screens.
class GlassFilterChipRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color? activeColor;
  final List<Widget?>? leadingIcons;

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
    final active = activeColor ?? AppTheme.accentOrange;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final selected = index == selectedIndex;
          final leading = (leadingIcons != null && index < leadingIcons!.length)
              ? leadingIcons![index]
              : null;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: selected && activeColor == null
                        ? AppTheme.rosePurple
                        : null,
                    color: selected && activeColor != null
                        ? active.withValues(alpha: 0.15)
                        : selected
                            ? null
                            : AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: selected
                          ? active.withValues(alpha: 0.60)
                          : AppTheme.glassBorder,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: active.withValues(alpha: 0.22),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leading != null) ...[
                          leading,
                          const SizedBox(width: 5),
                        ],
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected && activeColor == null
                                ? Colors.white
                                : selected
                                    ? active
                                    : AppTheme.textSecondary,
                            letterSpacing: selected ? 0.3 : 0,
                          ),
                          child: Text(labels[index]),
                        ),
                      ],
                    ),
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
