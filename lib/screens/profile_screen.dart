import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_export.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
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
    final stats = ref.watch(userStatsProvider);
    final badges = ref.watch(badgesProvider);
    final user = AuthService.currentUser;

    final email = user?.email ?? 'Explorer';
    final initials = _initials(email);
    final unlocked = badges.valueOrNull?.where((b) => b.unlocked).length ?? 0;
    final level = _levelFromPoints(stats.points);

    final isDemoProfile = stats.points == 0 && stats.visitedCount == 0;

    final displayPoints = isDemoProfile ? 550 : stats.points;
    final displayVisited = isDemoProfile ? 3 : stats.visitedCount;
    final displayUnlocked = isDemoProfile ? 4 : unlocked;
    final displayLevel = isDemoProfile ? 3 : level;
    final displayLevelName = isDemoProfile ? 'Изследовател' : stats.levelName;
    final displayProgress = isDemoProfile ? 0.65 : stats.levelProgress;
    final displayPointsToNext = isDemoProfile ? 300 : stats.pointsToNext;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              email: email,
              initials: initials,
              level: displayLevel,
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _XpCard(
                        level: displayLevel,
                        displayPoints: displayPoints,
                        displayLevelName: displayLevelName,
                        displayProgress: displayProgress,
                        displayPointsToNext: displayPointsToNext,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _StatCard(
                              icon: Icons.bolt_rounded,
                              value: _fmt(displayPoints),
                              label: 'Точки',
                              sublabel: 'Общо XP',
                              color: AppTheme.accentGold,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              icon: Icons.place_rounded,
                              value: '$displayVisited',
                              label: 'Посетени',
                              sublabel: 'Уникални места',
                              color: AppTheme.badgeNature,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              icon: Icons.military_tech_rounded,
                              value: '$displayUnlocked',
                              label: 'Значки',
                              sublabel: 'Постижения',
                              color: AppTheme.badgeSummit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ActionBtn(
                        icon: Icons.emoji_events_rounded,
                        label: 'Класация',
                        style: _ActionStyle.outline,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const _RecentSection(),
                      const SizedBox(height: 24),
                      _ActionBtn(
                        icon: Icons.logout_rounded,
                        label: 'Изход от профила',
                        style: _ActionStyle.outline,
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  String _initials(String email) {
    final parts = email.split('@').first.split('.');

    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  String _fmt(int n) {
    return n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
  }

  int _levelFromPoints(int points) {
    const thresholds = GameConstants.levelThresholds;

    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (points >= thresholds[i]) {
        return i + 1;
      }
    }

    return 1;
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: const Text(
          'Изход от профила?',
          style: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Ще бъдеш върната към екрана за вход.',
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
              backgroundColor: AppTheme.accentOrange,
            ),
            child: const Text(
              'Изход',
              style: TextStyle(
                fontFamily: 'Karla',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await AuthService.logout();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}

class _ProfileHero extends StatelessWidget {
  final String email;
  final String initials;
  final int level;

  const _ProfileHero({
    required this.email,
    required this.initials,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 300 + topPad,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3A244D),
                  Color(0xFF24182F),
                  AppTheme.backgroundDeep,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.2,
                  colors: [
                    AppTheme.accentOrange.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -60,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.08),
                  width: 34,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentPurple.withValues(alpha: 0.07),
                  width: 26,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.rosePurple,
                      border: Border.all(
                        color: AppTheme.accentOrange,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentOrange.withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email.split('@').first,
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color:
                                  AppTheme.accentOrange.withValues(alpha: 0.40),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.terrain_rounded,
                                size: 11,
                                color: AppTheme.accentOrange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Изследовател',
                                style: TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPad + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Little Wonders BG',
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.glassSurface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            gradient: AppTheme.rosePurple,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$level',
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Ниво',
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpCard extends StatefulWidget {
  final int level;
  final int displayPoints;
  final String displayLevelName;
  final double displayProgress;
  final int displayPointsToNext;

  const _XpCard({
    required this.level,
    required this.displayPoints,
    required this.displayLevelName,
    required this.displayProgress,
    required this.displayPointsToNext,
  });

  @override
  State<_XpCard> createState() => _XpCardState();
}

class _XpCardState extends State<_XpCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.displayProgress * 100).toInt();

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppTheme.rosePurple,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.roseGlowShadow,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.level}',
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.displayLevelName,
                          style: const TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Ниво ${widget.level} → Ниво ${widget.level + 1}',
                          style: const TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.displayPoints}',
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      Text(
                        '/ ${widget.displayPoints + widget.displayPointsToNext} XP',
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$pct% до следващо ниво',
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Остават ${widget.displayPointsToNext} XP',
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.glassSurface,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (widget.displayProgress * _anim.value).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.rosePurple,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.accentOrange.withValues(alpha: 0.50),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 130,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RecentSection extends StatelessWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Последни приключения',
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Consumer(
          builder: (_, ref, __) {
            final visits = ref.watch(visitsProvider);
            final poisAsync = ref.watch(poisProvider);

            return poisAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LoadingSkeletonWidget(
                      width: double.infinity,
                      height: 80,
                      borderRadius: AppTheme.radiusMd,
                    ),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (pois) {
                final keys = visits.keys.take(3).toList();

                if (keys.isEmpty) {
                  final demo = [
                    (
                      title: 'Седемте рилски езера',
                      date: DateTime.now().subtract(const Duration(days: 2)),
                      xp: 180,
                      type: 'nature',
                      imagePath: 'assets/images/demo/rila_profile.png',
                    ),
                    (
                      title: 'Царевец',
                      date: DateTime.now().subtract(const Duration(days: 5)),
                      xp: 150,
                      type: 'culture',
                      imagePath: 'assets/images/demo/carevec_profile.png',
                    ),
                    (
                      title: 'Мусала',
                      date: DateTime.now().subtract(const Duration(days: 9)),
                      xp: 220,
                      type: 'nature',
                      imagePath: 'assets/images/demo/musala_profile.png',
                    ),
                  ];

                  return Column(
                    children: demo.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActivityCard(
                          title: item.title,
                          date: item.date,
                          xp: item.xp,
                          type: item.type,
                          imagePath: item.imagePath,
                        ),
                      );
                    }).toList(),
                  );
                }

                return Column(
                  children: keys.map((k) {
                    final poi = pois.where((p) => p.id == k).firstOrNull;
                    final data = visits[k] as Map<String, dynamic>? ?? {};
                    final xp = (data['points'] as num?)?.toInt() ?? 0;
                    final date =
                        DateTime.tryParse(data['time'] as String? ?? '');

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, child) => Opacity(
                        opacity: val,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - val)),
                          child: child,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActivityCard(
                          title: poi?.name ?? k,
                          date: date,
                          xp: xp,
                          type: poi?.type,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final DateTime? date;
  final int xp;
  final String? type;
  final String? imagePath;

  const _ActivityCard({
    required this.title,
    required this.date,
    required this.xp,
    required this.type,
    this.imagePath,
  });

  String _fmt(DateTime? d) {
    if (d == null) return 'Скоро';

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

    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Color get _typeColor => type == 'nature'
      ? AppTheme.badgeNature
      : type == 'culture'
          ? AppTheme.badgeCulture
          : AppTheme.accentOrange;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMd),
                    bottomLeft: Radius.circular(AppTheme.radiusMd),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: imagePath?.isNotEmpty == true
                        ? Image.asset(
                            imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ActivityFallback(type: type),
                          )
                        : _ActivityFallback(type: type),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _fmt(date),
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _typeColor.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 12, color: _typeColor),
                        const SizedBox(width: 3),
                        Text(
                          '+$xp',
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ActivityFallback extends StatelessWidget {
  final String? type;

  const _ActivityFallback({
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: type == 'nature' ? AppTheme.nature : AppTheme.culture,
      ),
      child: Center(
        child: Text(
          type == 'nature' ? '🌿' : '🏛️',
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

enum _ActionStyle { outline }

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final _ActionStyle style;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Karla',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
