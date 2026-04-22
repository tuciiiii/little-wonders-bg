import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ExplorationStatus { visited, nearby, undiscovered, trending }

class StatusBadgeWidget extends StatelessWidget {
  final ExplorationStatus status;
  final String? customLabel;
  const StatusBadgeWidget({super.key, required this.status, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final cfg = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: cfg.color.withValues(alpha: 0.40)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(color: cfg.color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: cfg.color.withValues(alpha: 0.60), blurRadius: 4, spreadRadius: 1)]),
        ),
        const SizedBox(width: 5),
        Text(customLabel ?? cfg.label,
            style: TextStyle(fontFamily: 'Karla', fontSize: 10, fontWeight: FontWeight.w600, color: cfg.color, letterSpacing: 0.5)),
      ]),
    );
  }

  ({Color color, String label}) _config() {
    switch (status) {
      case ExplorationStatus.visited:      return (color: AppTheme.success,     label: 'VISITED');
      case ExplorationStatus.nearby:       return (color: AppTheme.accentGold,  label: 'NEARBY');
      case ExplorationStatus.undiscovered: return (color: AppTheme.textMuted,   label: 'UNDISCOVERED');
      case ExplorationStatus.trending:     return (color: AppTheme.badgeSummit, label: 'TRENDING');
    }
  }
}