import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavigation({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.map_outlined,            activeIcon: Icons.map_rounded,            label: 'Map'),
    (icon: Icons.photo_library_outlined,  activeIcon: Icons.photo_library_rounded,  label: 'Feed'),
    (icon: Icons.book_outlined,           activeIcon: Icons.book_rounded,           label: 'Journal'),
    (icon: Icons.emoji_events_outlined,   activeIcon: Icons.emoji_events_rounded,   label: 'Badges'),
    (icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,         label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard.withValues(alpha: 0.92),
            border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final item   = _items[i];
                  final active = i == currentIndex;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.accentOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        boxShadow: active ? AppTheme.glowShadow(AppTheme.accentOrange) : null,
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(active ? item.activeIcon : item.icon, size: 22,
                            color: active ? Colors.white : AppTheme.textMuted),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Karla', fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? Colors.white : AppTheme.textMuted,
                          ),
                          child: Text(item.label),
                        ),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
