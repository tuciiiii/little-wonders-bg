import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;
  final Color? tint;

  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.borderRadius, this.tint});

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? AppTheme.radiusMd;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}