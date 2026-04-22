import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_export.dart';
import '../providers/providers.dart';
import '../widgets/glass_filter_chip.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});
  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  int _filterIdx = 0;
  static const _categories = ['All', 'Nature', 'Summit', 'Distance', 'Culture', 'Social'];

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (_, ref, __) {
      final badgesAsync = ref.watch(badgesProvider);
      return Scaffold(
        backgroundColor: AppTheme.backgroundDeep,
        body: badgesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 2)),
          error: (e, _) => EmptyStateWidget(icon: Icons.error_outline_rounded, title: 'Error loading badges', description: e.toString()),
          data: (badges) {
            final filtered  = _filterIdx == 0
                ? badges
                : badges.where((b) => (b.category as String? ?? '') == _categories[_filterIdx]).toList();
            final unlocked  = badges.where((b) => b.unlocked as bool).length;
            final progress  = badges.isEmpty ? 0.0 : unlocked / badges.length;
            final isTablet  = MediaQuery.of(context).size.width >= 600;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App bar ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
                    child: Row(children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text('Achievements',
                            style: TextStyle(fontFamily: 'Lora', fontSize: 26, fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary, height: 1.1)),
                        SizedBox(height: 3),
                        Text('Your exploration milestones',
                            style: TextStyle(fontFamily: 'Karla', fontSize: 13, color: AppTheme.textMuted)),
                      ]),
                      const Spacer(),
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                            color: AppTheme.glassSurface, borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.glassBorder)),
                        child: const Icon(Icons.sort_rounded, color: AppTheme.textSecondary, size: 20),
                      ),
                    ]),
                  ),
                ),

                // ── Progress header ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _ProgressHeader(total: badges.length, unlocked: unlocked),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Filter chips ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: GlassFilterChipRow(
                    labels: _categories, selectedIndex: _filterIdx, activeColor: AppTheme.accentGold,
                    onSelected: (i) => setState(() => _filterIdx = i),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Badge grid ────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 350 + (i % 6) * 80),
                        curve: Curves.easeOutBack,
                        builder: (_, val, child) => Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Transform.scale(scale: 0.85 + 0.15 * val, child: child),
                        ),
                        child: GestureDetector(
                          onTap: () => _showDetail(context, filtered[i]),
                          child: _BadgeCard(badge: filtered[i], index: i),
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : 2,
                      mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.82,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      );
    });
  }

  void _showDetail(BuildContext context, dynamic badge) {
    if (!(badge.unlocked as bool)) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BadgeDetailSheet(badge: badge),
    );
  }
}

// ── Progress header ────────────────────────────────────────────────────────
class _ProgressHeader extends StatefulWidget {
  final int total, unlocked;
  const _ProgressHeader({required this.total, required this.unlocked});
  @override
  State<_ProgressHeader> createState() => _ProgressHeaderState();
}

class _ProgressHeaderState extends State<_ProgressHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () => _ctrl.forward());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final progress = widget.total == 0 ? 0.0 : widget.unlocked / widget.total;
    final pct = (progress * 100).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.glassBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            Row(children: [
              _StatPill(icon: Icons.military_tech_rounded, value: '${widget.unlocked}', label: 'Unlocked', color: AppTheme.accentGold),
              const SizedBox(width: 12),
              _StatPill(icon: Icons.lock_outline_rounded, value: '${widget.total - widget.unlocked}', label: 'Locked', color: AppTheme.textMuted),
              const Spacer(),
              // Circular progress
              SizedBox(
                width: 64, height: 64,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: progress * _anim.value, strokeWidth: 5,
                      backgroundColor: AppTheme.glassSurface,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.accentGold),
                      strokeCap: StrokeCap.round,
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('$pct%', style: const TextStyle(fontFamily: 'Karla', fontSize: 15,
                          fontWeight: FontWeight.w800, color: AppTheme.accentGold, height: 1.0)),
                      const Text('done', style: TextStyle(fontFamily: 'Karla', fontSize: 9, color: AppTheme.textMuted)),
                    ]),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${widget.unlocked} of ${widget.total} badges earned',
                  style: const TextStyle(fontFamily: 'Karla', fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
              const Text('View all →', style: TextStyle(fontFamily: 'Karla', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentGold)),
            ]),
            const SizedBox(height: 10),
            Container(
              height: 6,
              decoration: BoxDecoration(color: AppTheme.glassSurface, borderRadius: BorderRadius.circular(100)),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (progress * _anim.value).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.accentGold, AppTheme.accentGlow]),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.40), blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _StatPill({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20))),
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontFamily: 'Karla', fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1.0)),
        Text(label, style: const TextStyle(fontFamily: 'Karla', fontSize: 10, color: AppTheme.textMuted)),
      ]),
    ]),
  );
}

// ── Badge card ─────────────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final dynamic badge;
  final int index;
  const _BadgeCard({required this.badge, required this.index});

  static const List<LinearGradient> _gradients = [
    AppTheme.badgeOrange, AppTheme.badgeGreen, AppTheme.badgeRed,
    AppTheme.badgeBlueG, AppTheme.badgePurple, AppTheme.badgeTeal,
  ];

  static const _iconMap = {
    'terrain': Icons.terrain_rounded, 'park': Icons.park_outlined, 'route': Icons.route_rounded,
    'water': Icons.water_rounded, 'account_balance': Icons.account_balance_outlined,
    'directions_run': Icons.directions_run_rounded, 'nights_stay': Icons.nights_stay_outlined,
    'auto_stories': Icons.auto_stories_rounded, 'filter_hdr': Icons.filter_hdr_rounded,
    'flash_on': Icons.flash_on_rounded, 'self_improvement': Icons.self_improvement_rounded,
  };

  IconData _icon() => _iconMap[badge.icon as String? ?? ''] ?? Icons.military_tech_rounded;
  Color _badgeColor() {
    final hex = badge.color as String? ?? 'FF8C00';
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.unlocked as bool;
    final badgeColor = _badgeColor();
    final gradient   = _gradients[index % _gradients.length];
    final rarity     = badge.rarity as String? ?? 'Common';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: isUnlocked ? badgeColor.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
                color: isUnlocked ? badgeColor.withValues(alpha: 0.30) : AppTheme.glassBorder, width: 1),
            boxShadow: isUnlocked
                ? [BoxShadow(color: badgeColor.withValues(alpha: 0.20), blurRadius: 20, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Stack(children: [
            // Glow blob for unlocked
            if (isUnlocked)
              Positioned(top: -20, right: -20,
                  child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [badgeColor.withValues(alpha: 0.15), Colors.transparent])))),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Icon area
                Expanded(
                  child: Center(
                    child: isUnlocked
                        ? Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: gradient, shape: BoxShape.circle,
                        border: Border.all(color: badgeColor.withValues(alpha: 0.40), width: 1.5),
                        boxShadow: [BoxShadow(color: badgeColor.withValues(alpha: 0.40), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Icon(_icon(), size: 34, color: Colors.white),
                    )
                        : ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 0.4, 0,
                      ]),
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(color: AppTheme.glassSurface, shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.glassBorder)),
                        child: Icon(_icon(), size: 34, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Rarity chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: (isUnlocked ? badgeColor : AppTheme.textMuted).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (isUnlocked ? badgeColor : AppTheme.textMuted).withValues(alpha: 0.20))),
                  child: Text(rarity.toUpperCase(),
                      style: TextStyle(fontFamily: 'Karla', fontSize: 9, fontWeight: FontWeight.w700,
                          color: isUnlocked ? badgeColor : AppTheme.textMuted, letterSpacing: 0.8)),
                ),
                const SizedBox(height: 6),

                Text(badge.title as String? ?? badge.name as String? ?? '',
                    style: TextStyle(fontFamily: 'Karla', fontSize: 13, fontWeight: FontWeight.w700,
                        color: isUnlocked ? AppTheme.textPrimary : AppTheme.textMuted, height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),

                if (isUnlocked)
                  Row(children: [
                    Icon(Icons.bolt_rounded, size: 12, color: badgeColor),
                    const SizedBox(width: 3),
                    Text('+${badge.xp ?? 0} XP',
                        style: TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor)),
                  ])
                else if ((badge.progress as double? ?? 0) > 0)
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${((badge.progress as double) * 100).toInt()}% complete',
                        style: const TextStyle(fontFamily: 'Karla', fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    ClipRRect(borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(value: badge.progress as double,
                            minHeight: 4, backgroundColor: AppTheme.glassSurface,
                            valueColor: AlwaysStoppedAnimation(AppTheme.textMuted.withValues(alpha: 0.60)))),
                  ])
                else
                  Text(badge.description as String? ?? '',
                      style: const TextStyle(fontFamily: 'Karla', fontSize: 10, color: AppTheme.textMuted, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),

            // Lock / check badge
            Positioned(top: 12, right: 12,
              child: Container(
                width: isUnlocked ? 24 : 28, height: isUnlocked ? 24 : 28,
                decoration: BoxDecoration(
                    color: isUnlocked ? badgeColor.withValues(alpha: 0.20) : AppTheme.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: isUnlocked ? badgeColor.withValues(alpha: 0.40) : AppTheme.glassBorder)),
                child: Icon(isUnlocked ? Icons.check_rounded : Icons.lock_rounded,
                    size: isUnlocked ? 13 : 12,
                    color: isUnlocked ? badgeColor : AppTheme.textMuted),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Badge detail bottom sheet ───────────────────────────────────────────────
class _BadgeDetailSheet extends StatelessWidget {
  final dynamic badge;
  const _BadgeDetailSheet({required this.badge});

  static const _iconMap = {
    'terrain': Icons.terrain_rounded, 'park': Icons.park_outlined, 'route': Icons.route_rounded,
    'water': Icons.water_rounded, 'account_balance': Icons.account_balance_outlined,
    'directions_run': Icons.directions_run_rounded, 'nights_stay': Icons.nights_stay_outlined,
    'auto_stories': Icons.auto_stories_rounded, 'filter_hdr': Icons.filter_hdr_rounded,
    'flash_on': Icons.flash_on_rounded, 'self_improvement': Icons.self_improvement_rounded,
  };

  IconData get _icon => _iconMap[badge.icon as String? ?? ''] ?? Icons.military_tech_rounded;
  Color get _color {
    final hex = badge.color as String? ?? 'FF8C00';
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: c.withValues(alpha: 0.30)),
              boxShadow: [BoxShadow(color: c.withValues(alpha: 0.15), blurRadius: 32)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(100))),
              const SizedBox(height: 24),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [c.withValues(alpha: 0.40), c.withValues(alpha: 0.10)]),
                  shape: BoxShape.circle,
                  border: Border.all(color: c.withValues(alpha: 0.60), width: 2),
                  boxShadow: [BoxShadow(color: c.withValues(alpha: 0.50), blurRadius: 32, spreadRadius: 4)],
                ),
                child: Icon(_icon, size: 48, color: c),
              ),
              const SizedBox(height: 20),
              Text(badge.title as String? ?? badge.name as String? ?? '',
                  style: const TextStyle(fontFamily: 'Lora', fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(badge.description as String? ?? '',
                  style: const TextStyle(fontFamily: 'Karla', fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _DetailStat(icon: Icons.bolt_rounded, value: '+${badge.xp ?? 0} XP', label: 'Reward', color: c),
                const SizedBox(width: 20),
                _DetailStat(icon: Icons.calendar_today_outlined, value: badge.earnedDate as String? ?? '—', label: 'Earned on', color: AppTheme.textSecondary),
                const SizedBox(width: 20),
                _DetailStat(icon: Icons.diamond_outlined, value: badge.rarity as String? ?? 'Common', label: 'Rarity',
                    color: (badge.rarity == 'Legendary') ? AppTheme.accentGold : (badge.rarity == 'Epic') ? AppTheme.badgePurpleColor : AppTheme.textSecondary),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.80)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.30), blurRadius: 16)],
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.share_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Share Achievement', style: TextStyle(fontFamily: 'Karla', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _DetailStat({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 44, height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.20))),
        child: Icon(icon, size: 20, color: color)),
    const SizedBox(height: 6),
    Text(value, style: TextStyle(fontFamily: 'Karla', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    Text(label, style: const TextStyle(fontFamily: 'Karla', fontSize: 10, color: AppTheme.textMuted)),
  ]);
}