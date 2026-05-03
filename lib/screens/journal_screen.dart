import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/app_export.dart';
import '../core/poi.dart';
import '../providers/providers.dart';
import 'poi_details_screen.dart';

Color _categoryColor(String? category) {
  switch (category) {
    case 'nature':
      return AppTheme.badgeNature;
    case 'culture':
      return AppTheme.badgeCulture;
    default:
      return AppTheme.accentGold;
  }
}

String _categoryLabel(String? category) {
  switch (category) {
    case 'nature':
      return 'Природа';
    case 'culture':
      return 'Култура';
    default:
      return 'Приключение';
  }
}

const List<_JournalEntry> _demoJournalEntries = [
  _JournalEntry(
    id: 'sedemte_rilski_ezera',
    data: {
      'title': 'Седемте рилски езера',
      'time': null,
      'points': 180,
      'note':
          'Първото ми малко чудо — невероятна гледка към езерата и усещане, че си над света.',
      'type': 'nature',
      'photoPath': 'assets/images/demo/rila_profile.png',
      'isDemo': true,
    },
  ),
  _JournalEntry(
    id: 'tsarevets',
    data: {
      'title': 'Царевец',
      'time': null,
      'points': 150,
      'note':
          'Разходка из историята на България. Царевец има много силна атмосфера.',
      'type': 'culture',
      'photoPath': 'assets/images/demo/carevec_profile.png',
      'isDemo': true,
    },
  ),
  _JournalEntry(
    id: 'musala',
    data: {
      'title': 'Мусала',
      'time': null,
      'points': 220,
      'note':
          'Студено, ветровито и незабравимо. Чувството да стигнеш върха е специално.',
      'type': 'nature',
      'photoPath': 'assets/images/demo/musala_profile.png',
      'isDemo': true,
    },
  ),
];

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen>
    with SingleTickerProviderStateMixin {
  late final Box _box;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _box = Hive.box('visits');

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BoxEvent>(
      stream: _box.watch(),
      builder: (context, _) {
        final realEntries = _journalEntries();
        final entries = realEntries.isEmpty ? _demoJournalEntries : realEntries;
        final isShowingDemo = realEntries.isEmpty;
        final poisAsync = ref.watch(poisProvider);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDeep,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.aurora,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: _buildHeader(
                      entries.length,
                      isDemo: isShowingDemo,
                    ),
                  ),
                ),
              ),
              poisAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentGold,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.error_outline_rounded,
                    title: 'Грешка при зареждане',
                    description: error.toString(),
                  ),
                ),
                data: (pois) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = entries[index];
                        final poi = _findPoi(entry.id, pois);
                        final date = _parseDate(entry.data['time']);
                        final isDemo = entry.data['isDemo'] == true;

                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _JournalCard(
                              title: poi?.name ??
                                  entry.data['title'] as String? ??
                                  entry.id,
                              date: _formatDate(date),
                              note: (entry.data['note'] ?? '').toString(),
                              xp: (entry.data['points'] as num?)?.toInt() ?? 0,
                              photoPath: entry.data['photoPath'] as String?,
                              category:
                                  poi?.type ?? entry.data['type'] as String?,
                              isDemo: isDemo,
                              onTap: poi == null
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PoiDetailsScreen(
                                            poi: poi,
                                            me: null,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        );
                      },
                      childCount: entries.length,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  List<_JournalEntry> _journalEntries() {
    final entries = <_JournalEntry>[];

    for (final key in _box.keys.whereType<String>()) {
      final raw = _box.get(key);

      if (raw is! Map) continue;

      entries.add(
        _JournalEntry(
          id: key,
          data: Map<String, dynamic>.from(raw),
        ),
      );
    }

    entries.sort((a, b) {
      final aDate = _parseDate(a.data['time']);
      final bDate = _parseDate(b.data['time']);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return entries;
  }

  Poi? _findPoi(String id, List<Poi> pois) {
    for (final poi in pois) {
      if (poi.id == id) return poi;
    }

    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  Future<void> _clearJournal() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: const Text(
          'Изтриване на дневника?',
          style: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Всички записани посещения ще бъдат изтрити от устройството.',
          style: TextStyle(
            fontFamily: 'Karla',
            color: AppTheme.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отказ',
              style: TextStyle(
                fontFamily: 'Karla',
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text(
              'Изтрий',
              style: TextStyle(
                fontFamily: 'Karla',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _box.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Дневникът беше изтрит.',
            style: TextStyle(fontFamily: 'Karla'),
          ),
        ),
      );
    }
  }

  Widget _buildHeader(int count, {bool isDemo = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Дневник',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                count == 1
                    ? '1 записано приключение'
                    : '$count записани приключения',
                style: const TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (count > 0 && !isDemo)
            GestureDetector(
              onTap: _clearJournal,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.glassSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Скоро';

    const months = [
      'ян.',
      'фев.',
      'март',
      'апр.',
      'май',
      'юни',
      'юли',
      'авг.',
      'септ.',
      'окт.',
      'ное.',
      'дек.',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _JournalEntry {
  final String id;
  final Map<String, dynamic> data;

  const _JournalEntry({
    required this.id,
    required this.data,
  });
}

class _JournalCard extends StatelessWidget {
  final String title;
  final String date;
  final String note;
  final int xp;
  final String? photoPath;
  final String? category;
  final bool isDemo;
  final VoidCallback? onTap;

  const _JournalCard({
    required this.title,
    required this.date,
    required this.note,
    required this.xp,
    this.photoPath,
    this.category,
    this.isDemo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath?.isNotEmpty == true;
    final categoryColor = _categoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                hasPhoto
                    ? photoPath!.startsWith('assets/')
                        ? Image.asset(
                            photoPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _GradFallback(
                              category: category,
                            ),
                          )
                        : Image.file(
                            File(photoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _GradFallback(
                              category: category,
                            ),
                          )
                    : _GradFallback(category: category),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                if (isDemo)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppTheme.accentOrange.withValues(
                                alpha: 0.40,
                              ),
                            ),
                          ),
                          child: const Text(
                            'DEMO',
                            style: TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentOrange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.40),
                                ),
                              ),
                              child: Text(
                                _categoryLabel(category),
                                style: TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              date,
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            note,
                            style: const TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _StatChip(
                          icon: Icons.bolt_rounded,
                          label: '+$xp XP',
                          color: AppTheme.accentGold,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradFallback extends StatelessWidget {
  final String? category;

  const _GradFallback({
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: category == 'nature' ? AppTheme.nature : AppTheme.culture,
      ),
      child: Center(
        child: Text(
          category == 'nature' ? '🌿' : '🏛️',
          style: const TextStyle(fontSize: 56),
        ),
      ),
    );
  }
}
