import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.glassBorder),
                boxShadow: [BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.10), blurRadius: 24, spreadRadius: 4)],
              ),
              child: Icon(icon, size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(fontFamily: 'Lora', fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(fontFamily: 'Karla', fontSize: 14, color: AppTheme.textMuted, height: 1.6),
                textAlign: TextAlign.center),
            if (ctaLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCta,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.backgroundDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(ctaLabel!, style: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}