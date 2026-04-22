import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'glass_card.dart';

class AppLoadingOverlay extends StatelessWidget {
  final String? message;
  const AppLoadingOverlay({super.key, this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent), strokeWidth: 2.5),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: const TextStyle(fontFamily: 'Karla', color: AppColors.textLight, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

class GradientSliverHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double expandedHeight;
  final Widget? bottom;
  final List<Widget>? actions;
  const GradientSliverHeader({super.key, required this.title, required this.subtitle, this.expandedHeight = 210, this.bottom, this.actions});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight, pinned: true,
      backgroundColor: AppColors.auroraDeep, foregroundColor: Colors.white, elevation: 0,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(background: _HeaderBg(title: title, subtitle: subtitle, bottom: bottom)),
    );
  }
}

class _HeaderBg extends StatelessWidget {
  final String title; final String subtitle; final Widget? bottom;
  const _HeaderBg({required this.title, required this.subtitle, this.bottom});
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
        Positioned(top: -60, right: -40,
            child: Container(width: 220, height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppColors.auroraMist.withValues(alpha: 0.15), Colors.transparent])))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Spacer(),
              Text(title, style: const TextStyle(fontFamily: 'Lora', fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.8, height: 1.1)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(fontFamily: 'Karla', fontSize: 14, color: Colors.white.withValues(alpha: 0.72), height: 1.4)),
              if (bottom != null) ...[const SizedBox(height: 18), bottom!],
            ]),
          ),
        ),
      ],
    );
  }
}


class GlassProgressCard extends StatelessWidget {
  final String label; final double progress;
  const GlassProgressCard({super.key, required this.label, required this.progress});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: const BorderRadius.all(AppRadius.full),
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ]),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String emoji; final String title; final String subtitle;
  final String? buttonLabel; final VoidCallback? onButton;
  const AppEmptyState({super.key, required this.emoji, required this.title, required this.subtitle, this.buttonLabel, this.onButton});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: const BorderRadius.all(AppRadius.xxl),
              border: Border.all(color: AppColors.darkBorder, width: 1.5),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 26),
          Text(title, style: const TextStyle(fontFamily: 'Lora', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(fontFamily: 'Karla', fontSize: 15, color: AppColors.textLight, height: 1.55), textAlign: TextAlign.center),
          if (buttonLabel != null && onButton != null) ...[
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onButton,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(AppRadius.lg)),
              ),
              child: Text(buttonLabel!, style: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ]),
      ),
    );
  }
}

Future<bool> showConfirmDialog(BuildContext context, {required String title, required String message, String confirmLabel = 'Confirm', bool destructive = false}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(AppRadius.xl)),
      title: Text(title, style: const TextStyle(fontFamily: 'Lora', fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 20)),
      content: Text(message, style: const TextStyle(fontFamily: 'Karla', color: AppColors.textMid, fontSize: 15, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w600, color: AppColors.textLight))),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: destructive ? AppColors.error : AppColors.accent, foregroundColor: Colors.white, elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(AppRadius.md))),
          child: Text(confirmLabel, style: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return result ?? false;
}

class StatCard extends StatelessWidget {
  final IconData icon; final String value; final String label; final Color color;
  const StatCard({super.key, required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: const BorderRadius.all(AppRadius.lg), border: Border.all(color: AppColors.darkBorder), boxShadow: AppShadows.card),
      child: Column(children: [
        Container(height: 44, width: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: const BorderRadius.all(AppRadius.md)), child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontFamily: 'Lora', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// StatChip alias for profile screen
class StatChip extends StatelessWidget {
  final IconData icon; final String value; final String label; final Color color;
  const StatChip({super.key, required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => StatCard(icon: icon, value: value, label: label, color: color);
}

class SectionHeader extends StatelessWidget {
  final String title; final String? trailing; final VoidCallback? onTrailing;
  final String? action; final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.trailing, this.onTrailing, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    final trailText = trailing ?? action;
    final trailFn   = onTrailing ?? onAction;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(children: [
        Text(title, style: const TextStyle(fontFamily: 'Lora', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const Spacer(),
        if (trailText != null)
          GestureDetector(
            onTap: trailFn,
            child: Text(trailText, style: const TextStyle(fontFamily: 'Karla', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ),
      ]),
    );
  }
}

class PillTag extends StatelessWidget {
  final String label; final Color color; final IconData? icon;
  const PillTag({super.key, required this.label, this.color = AppColors.primary, this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: const BorderRadius.all(AppRadius.full), border: Border.all(color: color.withValues(alpha: 0.30))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 4)],
        Text(label, style: TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}