import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/app_export.dart';
import '../core/poi.dart';
import '../providers/providers.dart';
import 'poi_details_screen.dart';

Color _categoryColor(String? cat) {
  switch (cat) {
    case 'nature':  return AppTheme.badgeNature;
    case 'culture': return AppTheme.badgeCulture;
    case 'Water':   return AppTheme.badgeWater;
    default:        return AppTheme.accentGold;
  }
}

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen>
    with SingleTickerProviderStateMixin {
  late final Box _box;
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _box = Hive.box('visits');
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceCtrl.forward();
  }

  @override
  void dispose() { _entranceCtrl.dispose(); super.dispose(); }

  Poi? _findPoi(String id, List<Poi> pois) {
    for (final p in pois) { if (p.id == id) return p; } return null;
  }

  Future<void> _clearJournal() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: const Text('Clear journal?', style: TextStyle(fontFamily: 'Lora', fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 20)),
        content: const Text('All visit records will be permanently deleted.', style: TextStyle(fontFamily: 'Karla', color: AppTheme.textSecondary, fontSize: 15, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w600, color: AppTheme.textMuted))),
          FilledButton(onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Delete All', style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && mounted) { _box.clear(); setState(() {}); }
  }

  @override
  Widget build(BuildContext context) {
    final keys      = _box.keys.whereType<String>().toList();
    final poisAsync = ref.watch(poisProvider);

    if (keys.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDeep,
        body: SafeArea(child: Column(children: [
          _buildHeader(keys),
          Expanded(child: EmptyStateWidget(
            icon: Icons.terrain_rounded,
            title: 'Your story starts here',
            description: 'Every adventure deserves to be remembered. Visit a place and write your first entry.',
            ctaLabel: 'Start exploring',
          )),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SafeArea(child: _buildHeader(keys))),
          poisAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 2))),
            error: (e, _) => SliverFillRemaining(
                child: EmptyStateWidget(icon: Icons.error_outline_rounded, title: 'Error', description: e.toString())),
            data: (pois) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final id   = keys[i];
                    final raw  = _box.get(id);
                    if (raw == null) return const SizedBox.shrink();
                    final data = Map<String, dynamic>.from(raw as Map);
                    final poi  = _findPoi(id, pois);
                    final time = DateTime.tryParse(data['time'] as String? ?? '')?.toLocal();
                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _JournalCard(
                          title:     poi?.name ?? id,
                          date:      _fmt(time),
                          note:      data['note'] as String? ?? '',
                          xp:        (data['points'] as num?)?.toInt() ?? 0,
                          photoPath: data['photoPath'] as String?,
                          category:  poi?.type,
                          index:     i,
                          duration:  null,
                          onTap:     poi == null ? null : () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => PoiDetailsScreen(poi: poi, me: null))),
                        ),
                      ),
                    );
                  },
                  childCount: keys.length,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader(List keys) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Journal', style: TextStyle(fontFamily: 'Lora', fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.5)),
          Text('${keys.length} adventures recorded', style: const TextStyle(fontFamily: 'Karla', fontSize: 13, color: AppTheme.textMuted)),
        ]),
        const Spacer(),
        if (keys.isNotEmpty)
          GestureDetector(
            onTap: _clearJournal,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: AppTheme.glassSurface, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.glassBorder)),
                  child: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary, size: 20),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Recently';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Journal card — full-bleed photo, content below ─────────────────────────
class _JournalCard extends StatelessWidget {
  final String title, date, note;
  final int xp, index;
  final String? photoPath, category, duration;
  final VoidCallback? onTap;

  const _JournalCard({
    required this.title, required this.date, required this.note,
    required this.xp, required this.index,
    this.photoPath, this.category, this.duration, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto  = photoPath?.isNotEmpty == true;
    final catColor  = _categoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Photo — full bleed, exactly like reference
            SizedBox(
              height: 260, width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                // Background image
                hasPhoto
                    ? Image.file(File(photoPath!), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _GradFallback(category: category))
                    : _GradFallback(category: category),

                // Gradient scrim — heavier at bottom
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.20), Colors.black.withValues(alpha: 0.80)],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // Content overlaid at bottom of photo
                Positioned(bottom: 0, left: 0, right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          // Category chip + date
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: catColor.withValues(alpha: 0.40))),
                              child: Text(category?.capitalize() ?? 'Adventure',
                                  style: TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w600, color: catColor)),
                            ),
                            const Spacer(),
                            Text(date, style: const TextStyle(fontFamily: 'Karla', fontSize: 11, color: AppTheme.textSecondary)),
                          ]),
                          const SizedBox(height: 8),

                          // Location name
                          Text(title, style: const TextStyle(fontFamily: 'Lora', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (note.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(note, style: const TextStyle(fontFamily: 'Karla', fontSize: 13, color: AppTheme.textSecondary, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 12),

                          // Stat chips
                          Row(children: [
                            _StatChip(icon: Icons.bolt_rounded, label: '+$xp XP', color: AppTheme.accentGold),
                            if (duration != null) ...[
                              const SizedBox(width: 8),
                              _StatChip(icon: Icons.timer_outlined, label: duration!, color: AppTheme.textSecondary),
                            ],
                          ]),
                        ]),
                      ),
                    ),
                  ),
                ),

                // Entry number top-right
                Positioned(top: 14, right: 14,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40), shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
                    child: Center(child: Text('${index + 1}',
                        style: const TextStyle(fontFamily: 'Karla', fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    ),
  );
}

class _GradFallback extends StatelessWidget {
  final String? category;
  const _GradFallback({this.category});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(gradient: category == 'nature' ? AppTheme.nature : AppTheme.culture),
      child: Center(child: Text(category == 'nature' ? '🌿' : '🏛️', style: const TextStyle(fontSize: 56))));
}

extension _StringX on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}