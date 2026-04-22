import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_export.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();
  }

  @override
  void dispose() { _entranceCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final stats    = ref.watch(userStatsProvider);
    final badges   = ref.watch(badgesProvider);
    final user     = AuthService.currentUser;
    final email    = user?.email ?? 'Explorer';
    final initials = _initials(email);
    final unlocked = badges.valueOrNull?.where((b) => b.unlocked as bool).length ?? 0;
    final level    = stats.points ~/ 100 + 1; // rough level from points

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero header ─────────────────────────────────────────────
          SliverToBoxAdapter(child: _ProfileHero(email: email, initials: initials, level: level)),

          // ── Body ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    const SizedBox(height: 20),
                    // XP card
                    _XpCard(stats: stats, level: level),
                    const SizedBox(height: 20),
                    // Stats — horizontal scrollable
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _StatCard(icon: Icons.bolt_rounded,               value: _fmt(stats.points),       label: 'Total Points',  sublabel: 'All-time XP', color: AppTheme.accentGold),
                          const SizedBox(width: 12),
                          _StatCard(icon: Icons.place_rounded,               value: '${stats.visitedCount}', label: 'Explored',       sublabel: 'Unique spots', color: AppTheme.badgeNature),
                          const SizedBox(width: 12),
                          _StatCard(icon: Icons.military_tech_rounded,       value: '$unlocked',             label: 'Badges',         sublabel: 'Achievements', color: AppTheme.badgeSummit),
                          const SizedBox(width: 12),
                          _StatCard(icon: Icons.route_rounded,               value: '0 km',                 label: 'Distance',       sublabel: 'Total traveled', color: AppTheme.badgeCulture),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Recent adventures
                    _RecentSection(userId: user?.uid),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(children: [
                      Expanded(child: _ActionBtn(
                        icon: Icons.settings_outlined, label: 'Settings',
                        style: _ActionStyle.outline,
                        onTap: () => _showLogoutDialog(context),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _ActionBtn(
                        icon: Icons.share_outlined, label: 'Share Profile',
                        style: _ActionStyle.filled,
                        onTap: () {},
                      )),
                    ]),
                  ]),
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
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  Future<void> _showLogoutDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: const Text('Log out?', style: TextStyle(fontFamily: 'Lora', fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 20)),
        content: const Text('You will be returned to the login screen.', style: TextStyle(fontFamily: 'Karla', color: AppTheme.textSecondary, fontSize: 15, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w600, color: AppTheme.textMuted))),
          FilledButton(onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accentOrange),
              child: const Text('Log Out', style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AuthService.logout();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }
}

// ── Hero header with background image simulation ────────────────────────────
class _ProfileHero extends StatelessWidget {
  final String email, initials;
  final int level;
  const _ProfileHero({required this.email, required this.initials, required this.level});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 300 + topPad,
      child: Stack(fit: StackFit.expand, children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF1A3D2B), Color(0xFF0A2E18), AppTheme.backgroundDeep],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Ambient glow
        Positioned(top: 0, left: 0, right: 0, height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.2,
                colors: [AppTheme.primaryGreenMuted.withValues(alpha: 0.20), Colors.transparent],
              ),
            ),
          ),
        ),
        // Content
        Positioned(bottom: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              // Avatar
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.nature,
                  border: Border.all(color: AppTheme.accentGold, width: 2.5),
                  boxShadow: [BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 2)],
                ),
                child: Center(child: Text(initials,
                    style: const TextStyle(fontFamily: 'Lora', color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(email.split('@').first,
                    style: const TextStyle(fontFamily: 'Lora', fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.1)),
                const SizedBox(height: 4),
                // Rank chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.40))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.terrain_rounded, size: 11, color: AppTheme.accentGold),
                    const SizedBox(width: 4),
                    Text('Explorer', style: const TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentGold)),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: AppTheme.textMuted)),
              ])),
              // Edit + Settings
              Column(children: [
                _HeroIconBtn(icon: Icons.edit_outlined, onTap: () {}),
                const SizedBox(height: 8),
                _HeroIconBtn(icon: Icons.settings_outlined, onTap: () {}),
              ]),
            ]),
          ),
        ),
        // Top bar — app name + level pill
        Positioned(top: topPad + 8, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('SummitStories', style: TextStyle(fontFamily: 'Lora', fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppTheme.glassSurface, borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.glassBorder)),
                child: Row(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle),
                    child: Center(child: Text('$level',
                        style: const TextStyle(fontFamily: 'Karla', fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.backgroundDeep))),
                  ),
                  const SizedBox(width: 6),
                  const Text('Level', style: TextStyle(fontFamily: 'Karla', fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _HeroIconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HeroIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppTheme.glassSurface, shape: BoxShape.circle, border: Border.all(color: AppTheme.glassBorder)),
      child: Icon(icon, size: 16, color: AppTheme.textSecondary),
    ),
  );
}

// ── XP card with animated progress bar ─────────────────────────────────────
class _XpCard extends StatefulWidget {
  final UserStats stats; final int level;
  const _XpCard({required this.stats, required this.level});
  @override
  State<_XpCard> createState() => _XpCardState();
}

class _XpCardState extends State<_XpCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () => _ctrl.forward());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.stats.levelProgress * 100).toInt();
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
              // Level badge
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.accentGold, AppTheme.accentGlow],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glowShadow(AppTheme.accentGold),
                ),
                child: Center(child: Text('${widget.level}',
                    style: const TextStyle(fontFamily: 'Karla', fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.backgroundDeep))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.stats.levelName, style: const TextStyle(fontFamily: 'Karla', fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text('Level ${widget.level} → Level ${widget.level + 1}',
                    style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: AppTheme.textMuted)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${widget.stats.points}',
                    style: const TextStyle(fontFamily: 'Karla', fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.accentGold)),
                Text('/ ${widget.stats.points + widget.stats.pointsToNext} XP',
                    style: const TextStyle(fontFamily: 'Karla', fontSize: 11, color: AppTheme.textMuted)),
              ]),
            ]),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$pct% to next level', style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              Text('${widget.stats.pointsToNext} XP remaining', style: const TextStyle(fontFamily: 'Karla', fontSize: 11, color: AppTheme.textMuted)),
            ]),
            const SizedBox(height: 8),
            Container(
              height: 8,
              decoration: BoxDecoration(color: AppTheme.glassSurface, borderRadius: BorderRadius.circular(100)),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (widget.stats.levelProgress * _anim.value).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.accentGold, AppTheme.accentGlow]),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.50), blurRadius: 8, spreadRadius: 1)],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              _MiniStat(icon: Icons.local_fire_department_rounded, label: '${widget.stats.points ~/ 50} day streak', color: AppTheme.warning),
              const SizedBox(width: 16),
              const _MiniStat(icon: Icons.calendar_today_outlined, label: 'Exploring since 2024', color: AppTheme.textMuted),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _MiniStat({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 13, color: color),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontFamily: 'Karla', fontSize: 12, fontWeight: FontWeight.w500, color: color)),
  ]);
}

// ── Stat card (horizontal list) ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon; final String value, label, sublabel; final Color color;
  const _StatCard({required this.icon, required this.value, required this.label, required this.sublabel, required this.color});

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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: color)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: 'Karla', fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1.0)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          Text(sublabel, style: const TextStyle(fontFamily: 'Karla', fontSize: 10, color: AppTheme.textMuted)),
        ]),
      ),
    ),
  );
}

// ── Recent adventures ────────────────────────────────────────────────────────
class _RecentSection extends StatelessWidget {
  final String? userId;
  const _RecentSection({this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Recent Adventures', style: TextStyle(fontFamily: 'Lora', fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        GestureDetector(onTap: () {}, child: const Text('See all', style: TextStyle(fontFamily: 'Karla', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentGold))),
      ]),
      const SizedBox(height: 14),
      Consumer(builder: (_, ref, __) {
        final visits = ref.watch(visitsProvider);
        final poisAsync = ref.watch(poisProvider);
        return poisAsync.when(
          loading: () => Column(children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LoadingSkeletonWidget(width: double.infinity, height: 80, borderRadius: AppTheme.radiusMd)))),
          error: (_, __) => const SizedBox.shrink(),
          data: (pois) {
            final keys = visits.keys.take(3).toList();
            if (keys.isEmpty) return const Text('No adventures yet.', style: TextStyle(fontFamily: 'Karla', color: AppTheme.textMuted, fontSize: 13));
            return Column(children: keys.map((k) {
              final poi = pois.where((p) => p.id == k).firstOrNull;
              final data = visits[k] as Map<String, dynamic>? ?? {};
              final xp   = (data['points'] as num?)?.toInt() ?? 0;
              final date = DateTime.tryParse(data['time'] as String? ?? '');
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, val, child) => Opacity(
                    opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActivityCard(title: poi?.name ?? k, date: date, xp: xp, type: poi?.type),
                ),
              );
            }).toList());
          },
        );
      }),
    ]);
  }
}

class _ActivityCard extends StatelessWidget {
  final String title; final DateTime? date; final int xp; final String? type;
  const _ActivityCard({required this.title, required this.date, required this.xp, required this.type});

  String _fmt(DateTime? d) {
    if (d == null) return 'Recently';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  Color get _typeColor => type == 'nature' ? AppTheme.badgeNature : type == 'culture' ? AppTheme.badgeCulture : AppTheme.accentGold;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
            color: AppTheme.glassSurface, borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.glassBorder)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(AppTheme.radiusMd), bottomLeft: Radius.circular(AppTheme.radiusMd)),
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(gradient: type == 'nature' ? AppTheme.nature : AppTheme.culture),
              child: Center(child: Text(type == 'nature' ? '🌿' : '🏛️', style: const TextStyle(fontSize: 30))),
            ),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontFamily: 'Karla', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 11, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(_fmt(date), style: const TextStyle(fontFamily: 'Karla', fontSize: 11, color: AppTheme.textMuted)),
              ]),
            ]),
          )),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _typeColor.withValues(alpha: 0.30))),
              child: Row(children: [
                Icon(Icons.bolt_rounded, size: 12, color: _typeColor),
                const SizedBox(width: 3),
                Text('+$xp', style: TextStyle(fontFamily: 'Karla', fontSize: 12, fontWeight: FontWeight.w700, color: _typeColor)),
              ]),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ── Action button ────────────────────────────────────────────────────────────
enum _ActionStyle { outline, filled }

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final _ActionStyle style; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.style, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFilled = style == _ActionStyle.filled;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isFilled ? AppTheme.primaryGreen : AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: isFilled ? AppTheme.primaryGreen : AppTheme.glassBorder),
          boxShadow: isFilled ? AppTheme.glowShadow(AppTheme.primaryGreen) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: isFilled ? Colors.white : AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 14,
              color: isFilled ? Colors.white : AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}