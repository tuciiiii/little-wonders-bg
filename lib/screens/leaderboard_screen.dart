import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_skeleton_widget.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryGreenDeep, AppTheme.backgroundDeep],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Leaderboard',
                          style: TextStyle(fontFamily: 'Lora', fontSize: 28, fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary, letterSpacing: -0.5)),
                      SizedBox(height: 2),
                      Text('The top explorers of Bulgaria.',
                          style: TextStyle(fontFamily: 'Karla', fontSize: 13, color: AppTheme.textMuted)),
                    ]),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                              color: AppTheme.glassSurface, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.glassBorder)),
                          child: const Icon(Icons.emoji_events_rounded, color: AppTheme.accentGold, size: 22),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // ── Live ranking ────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users').orderBy('points', descending: true).limit(50).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.lock_outline_rounded,
                    title: 'Leaderboard unavailable',
                    description: 'Check your Firestore rules allow reads on the users collection.',
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(child: _LeaderboardSkeletons());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.leaderboard_outlined,
                    title: 'No rankings yet',
                    description: 'Be the first to explore and claim the top spot.',
                    ctaLabel: 'Explore the map',
                  ),
                );
              }

              final podium = docs.take(3).toList();
              final rest   = docs.skip(3).toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  // Podium card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _Podium(docs: podium, myEmail: myEmail),
                  ),

                  // Section header
                  if (rest.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(children: [
                        const Text('All Explorers',
                            style: TextStyle(fontFamily: 'Lora', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        const Spacer(),
                        Text('${docs.length} total',
                            style: const TextStyle(fontFamily: 'Karla', fontSize: 13, color: AppTheme.textMuted)),
                      ]),
                    ),

                  // Remaining rows with staggered entrance
                  ...rest.asMap().entries.map((entry) {
                    final rank = entry.key + 4;
                    final data = entry.value.data() as Map<String, dynamic>? ?? {};
                    final email  = data['email']  as String? ?? 'Unknown';
                    final points = (data['points'] as num?)?.toInt() ?? 0;
                    final isMe   = email == myEmail;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + entry.key * 40),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, child) => Opacity(opacity: val,
                          child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _LeaderRow(rank: rank, email: email, points: points, isMe: isMe),
                      ),
                    );
                  }),
                  const SizedBox(height: 120),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<DocumentSnapshot> docs;
  final String? myEmail;
  const _Podium({required this.docs, required this.myEmail});

  @override
  Widget build(BuildContext context) {
    final items = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return (
      email:  data['email']  as String? ?? 'Unknown',
      points: (data['points'] as num?)?.toInt() ?? 0,
      isMe:   (data['email'] as String? ?? '') == myEmail,
      );
    }).toList();

    // Layout: 2nd | 1st | 3rd
    final display = [
      if (items.length > 1) (rank: 2, d: items[1]),
      (rank: 1, d: items[0]),
      if (items.length > 2) (rank: 3, d: items[2]),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppTheme.primaryGreenDeep, AppTheme.primaryGreenMid],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassBorder),
            boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(children: [
            const Text('Top Explorers',
                style: TextStyle(fontFamily: 'Lora', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: display.map((item) => _PodiumEntry(
                rank: item.rank, email: item.d.email,
                points: item.d.points, isMe: item.d.isMe,
                elevated: item.rank == 1,
              )).toList(),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  final int rank; final String email; final int points; final bool isMe, elevated;
  const _PodiumEntry({required this.rank, required this.email, required this.points, required this.isMe, required this.elevated});

  static const _medals  = {1: '🥇', 2: '🥈', 3: '🥉'};
  static const _heights = {1: 80.0, 2: 56.0, 3: 40.0};
  Color get _podiumColor => switch (rank) { 1 => const Color(0xFFD4AF37), 2 => const Color(0xFFBDBDBD), _ => const Color(0xFFCD7F32) };

  @override
  Widget build(BuildContext context) {
    final h = _heights[rank] ?? 40.0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_medals[rank] ?? '', style: TextStyle(fontSize: elevated ? 28 : 22)),
      const SizedBox(height: 6),
      Container(
        width: elevated ? 62 : 50, height: elevated ? 62 : 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isMe ? 0.35 : 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: isMe ? AppTheme.accentOrange : Colors.white.withValues(alpha: 0.30), width: isMe ? 2.5 : 1.5),
          boxShadow: isMe ? [BoxShadow(color: AppTheme.accentOrange.withValues(alpha: 0.40), blurRadius: 12)] : null,
        ),
        child: Center(child: Text(email.isNotEmpty ? email[0].toUpperCase() : '?',
            style: TextStyle(fontFamily: 'Lora', color: Colors.white, fontSize: elevated ? 22 : 18, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(height: 6),
      SizedBox(width: 80, child: Text(email.split('@').first,
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: 'Karla', color: Colors.white, fontSize: elevated ? 13 : 11, fontWeight: FontWeight.w700))),
      Text('$points pts', style: TextStyle(fontFamily: 'Karla', color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
      const SizedBox(height: 8),
      Container(
        width: elevated ? 70 : 56, height: h,
        decoration: BoxDecoration(
          color: _podiumColor.withValues(alpha: 0.35),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          border: Border(
            top:   BorderSide(color: _podiumColor.withValues(alpha: 0.60), width: 2),
            left:  BorderSide(color: _podiumColor.withValues(alpha: 0.40)),
            right: BorderSide(color: _podiumColor.withValues(alpha: 0.40)),
          ),
        ),
        child: Center(child: Text('#$rank',
            style: TextStyle(fontFamily: 'Lora', color: _podiumColor, fontSize: 16, fontWeight: FontWeight.w700))),
      ),
    ]);
  }
}

// ── Regular row ───────────────────────────────────────────
class _LeaderRow extends StatelessWidget {
  final int rank; final String email; final int points; final bool isMe;
  const _LeaderRow({required this.rank, required this.email, required this.points, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryGreen.withValues(alpha: 0.10) : AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
                color: isMe ? AppTheme.primaryGreen.withValues(alpha: 0.30) : AppTheme.glassBorder),
          ),
          child: Row(children: [
            // Rank
            SizedBox(width: 32,
                child: Text('#$rank', style: TextStyle(fontFamily: 'Lora', fontSize: 15, fontWeight: FontWeight.w700,
                    color: isMe ? AppTheme.primaryGreenLight : AppTheme.textMuted))),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.glassSurface,
                shape: BoxShape.circle,
                border: Border.all(color: isMe ? AppTheme.primaryGreenLight.withValues(alpha: 0.40) : AppTheme.glassBorder),
              ),
              child: Center(child: Text(email.isNotEmpty ? email[0].toUpperCase() : '?',
                  style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700,
                      color: isMe ? AppTheme.primaryGreenLight : AppTheme.textSecondary))),
            ),
            const SizedBox(width: 12),
            // Name + "You" tag
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(email.split('@').first,
                  style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 14,
                      color: isMe ? AppTheme.primaryGreenLight : AppTheme.textPrimary)),
              if (isMe) const Text('You',
                  style: TextStyle(fontFamily: 'Karla', fontSize: 11, color: AppTheme.primaryGreenMuted, fontWeight: FontWeight.w600)),
            ])),
            // Points chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryGreen.withValues(alpha: 0.12) : AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: isMe ? AppTheme.primaryGreen.withValues(alpha: 0.30) : AppTheme.glassBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt_rounded, size: 12, color: isMe ? AppTheme.primaryGreenLight : AppTheme.textMuted),
                const SizedBox(width: 3),
                Text('$points', style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 13,
                    color: isMe ? AppTheme.primaryGreenLight : AppTheme.textSecondary)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Loading skeletons ─────────────────────────────────────
class _LeaderboardSkeletons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        LoadingSkeletonWidget(width: double.infinity, height: 220, borderRadius: AppTheme.radiusXl),
        const SizedBox(height: 16),
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LoadingSkeletonWidget(width: double.infinity, height: 66, borderRadius: AppTheme.radiusMd),
        )),
      ]),
    );
  }
}