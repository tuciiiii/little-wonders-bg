import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  const AppButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon, this.backgroundColor, this.foregroundColor, this.height = 56});

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.accentOrange;
    final fg = foregroundColor ?? Colors.white;
    return SizedBox(
      width: double.infinity, height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4), elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        ),
        child: loading
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
            : Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 16, color: fg)),
        ]),
      ),
    );
  }
}