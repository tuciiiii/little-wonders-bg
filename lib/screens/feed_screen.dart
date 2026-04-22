import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_export.dart';

Color _categoryColor(String? type) {
  switch (type) {
    case 'nature':  return AppTheme.badgeNature;
    case 'culture': return AppTheme.badgeCulture;
    case 'Summit':  return AppTheme.badgeSummit;
    case 'Water':   return AppTheme.badgeWater;
    default:        return AppTheme.accentGold;
  }
}

String _categoryLabel(String? type) {
  switch (type) {
    case 'nature':  return '🌿  Nature';
    case 'culture': return '🏛️  Culture';
    default:        return type ?? 'Adventure';
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceCtrl.forward();
  }

  @override
  void dispose() { _entranceCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.backgroundDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts').orderBy('time', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.lock_outline_rounded,
                    title: 'Feed unavailable',
                    description: 'Update your Firestore rules in the Firebase console.',
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(child: _buildSkeletons());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.forest_outlined,
                    title: 'No stories yet',
                    description: 'Check in at a place and add a photo to share your first adventure.',
                    ctaLabel: 'Explore the map',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) => FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _FeedCard(postId: docs[i].id, post: docs[i].data() as Map<String, dynamic>),
                      ),
                    ),
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              Text('Explorer Feed',
                  style: TextStyle(fontFamily: 'Lora', fontSize: 28, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary, letterSpacing: -0.5)),
              SizedBox(height: 2),
              Text('Stories from the wild',
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
                    color: AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppTheme.textPrimary, size: 20),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LoadingSkeletonWidget(width: double.infinity, height: 220, borderRadius: 24),
          const SizedBox(height: 0),
          Container(
            color: AppTheme.backgroundCard,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                LoadingSkeletonWidget(width: 36, height: 36, borderRadius: 18),
                const SizedBox(width: 10),
                LoadingSkeletonWidget(width: 120, height: 12, borderRadius: 6),
              ]),
              const SizedBox(height: 12),
              LoadingSkeletonWidget(width: double.infinity, height: 12, borderRadius: 6),
              const SizedBox(height: 6),
              LoadingSkeletonWidget(width: 200, height: 12, borderRadius: 6),
            ]),
          ),
        ]),
      ))),
    );
  }
}

// ─── Feed Card ────────────────────────────────────────────────────────────────
class _FeedCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;
  const _FeedCard({required this.postId, required this.post});
  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _commentsOpen = false;
  bool _bookmarked   = false;
  final _commentCtrl = TextEditingController();
  bool _sending      = false;

  String get _uid     => FirebaseAuth.instance.currentUser?.uid ?? '';
  List   get _likedBy => widget.post['likedBy'] as List? ?? [];
  bool   get _liked   => _likedBy.contains(_uid);
  int    get _likes   => _likedBy.length;

  String  get _location => (widget.post['location'] ?? 'Unknown place').toString();
  String  get _note     => (widget.post['note']     ?? '').toString();
  String  get _user     => (widget.post['user']     ?? 'Explorer').toString();
  String? get _photo    => widget.post['photo']?.toString();
  String? get _type     => widget.post['type']?.toString();

  String get _timeAgo {
    final ts = widget.post['time'] as Timestamp?;
    if (ts == null) return 'Recently';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _initials(String s) {
    final parts = s.split('@').first.split('.');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }

  Future<void> _toggleLike() async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    if (_liked) await ref.update({'likedBy': FieldValue.arrayRemove([_uid])});
    else         await ref.update({'likedBy': FieldValue.arrayUnion([_uid])});
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId)
        .collection('comments').add({
      'user': FirebaseAuth.instance.currentUser?.email ?? 'Explorer',
      'text': text, 'time': FieldValue.serverTimestamp(),
    });
    _commentCtrl.clear();
    setState(() => _sending = false);
  }

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo?.isNotEmpty == true;
    final catColor = _categoryColor(_type);
    final catLabel = _categoryLabel(_type);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Photo section ─────────────────────────────────────────────
          Stack(children: [
            SizedBox(
              width: double.infinity, height: 220,
              child: hasPhoto
                  ? CachedNetworkImage(
                imageUrl: _photo!, fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.backgroundCard,
                    child: const Center(child: CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 2))),
                errorWidget: (_, __, ___) => _FallbackPhoto(type: _type, location: _location),
              )
                  : _FallbackPhoto(type: _type, location: _location),
            ),
            // Gradient scrim
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.60)],
                  stops: const [0.5, 1.0],
                ),
              ),
            )),
            // Category badge — glassmorphic
            Positioned(top: 14, left: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: catColor.withValues(alpha: 0.40)),
                    ),
                    child: Text(catLabel,
                        style: TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w700, color: catColor)),
                  ),
                ),
              ),
            ),
            // XP badge — glassmorphic
            Positioned(top: 14, right: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.30)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: AppTheme.accentGold),
                      const SizedBox(width: 3),
                      Text('+${widget.post['points'] ?? 0} XP',
                          style: const TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentGold)),
                    ]),
                  ),
                ),
              ),
            ),
            // Location name with text shadow
            Positioned(bottom: 14, left: 14, right: 14,
              child: Text(_location,
                  style: const TextStyle(
                    fontFamily: 'Lora', fontSize: 20, fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),

          // ── Content section ───────────────────────────────────────────
          Container(
            color: AppTheme.backgroundCard,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // User row
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.nature,
                    border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.30), width: 1.5),
                  ),
                  child: Center(child: Text(_initials(_user),
                      style: const TextStyle(fontFamily: 'Karla', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_user, style: const TextStyle(fontFamily: 'Karla', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const Text('Explorer', style: TextStyle(fontFamily: 'Karla', fontSize: 11, color: AppTheme.textMuted)),
                ])),
                Text(_timeAgo, style: const TextStyle(fontFamily: 'Karla', fontSize: 11, color: AppTheme.textMuted)),
              ]),

              if (_note.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_note,
                    style: const TextStyle(fontFamily: 'Karla', fontSize: 14, color: AppTheme.textSecondary, height: 1.55),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 14),

              // Actions — like / comment / bookmark / share
              Row(children: [
                _ActionBtn(
                    icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: '$_likes',
                    color: _liked ? Colors.redAccent : AppTheme.textMuted,
                    onTap: _toggleLike),
                const SizedBox(width: 16),
                _ActionBtn(
                    icon: Icons.chat_bubble_outline_rounded, label: null,
                    color: _commentsOpen ? AppTheme.accentOrange : AppTheme.textMuted,
                    onTap: () => setState(() => _commentsOpen = !_commentsOpen)),
                const Spacer(),
                _ActionBtn(
                    icon: _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: null,
                    color: _bookmarked ? AppTheme.accentGold : AppTheme.textMuted,
                    onTap: () => setState(() => _bookmarked = !_bookmarked)),
                const SizedBox(width: 12),
                _ActionBtn(icon: Icons.share_outlined, label: null, color: AppTheme.textMuted, onTap: () {}),
              ]),

              // Comments
              if (_commentsOpen) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.backgroundDeep, borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId)
                          .collection('comments').orderBy('time').snapshots(),
                      builder: (_, snap) {
                        final comments = snap.data?.docs ?? [];
                        if (comments.isEmpty) return Padding(padding: const EdgeInsets.only(bottom: 8),
                            child: const Text('No comments yet.', style: TextStyle(fontFamily: 'Karla', color: AppTheme.textMuted, fontSize: 12)));
                        return Column(children: comments.map((d) {
                          final c = d.data() as Map<String, dynamic>;
                          return Padding(padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(width: 26, height: 26,
                                    decoration: BoxDecoration(color: AppTheme.backgroundCard, borderRadius: BorderRadius.circular(8)),
                                    child: Center(child: Text((c['user'] as String? ?? '?')[0].toUpperCase(),
                                        style: const TextStyle(fontFamily: 'Karla', color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800)))),
                                const SizedBox(width: 8),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['user'] ?? '', style: const TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentOrange)),
                                  Text(c['text'] ?? '', style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                                ])),
                              ]));
                        }).toList());
                      },
                    ),
                    Row(children: [
                      Expanded(child: TextField(
                        controller: _commentCtrl,
                        style: const TextStyle(fontFamily: 'Karla', fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                            hintText: 'Write a comment…',
                            hintStyle: const TextStyle(fontFamily: 'Karla', color: AppTheme.textMuted, fontSize: 13),
                            filled: true, fillColor: AppTheme.backgroundCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      )),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sending ? null : _sendComment,
                        child: Container(height: 38, width: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.glowShadow(AppTheme.accentOrange),
                            ),
                            child: _sending
                                ? const Center(child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 16)),
                      ),
                    ]),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String? label; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 20, color: color),
      if (label != null) ...[const SizedBox(width: 5), Text(label!, style: TextStyle(fontFamily: 'Karla', fontSize: 13, color: color, fontWeight: FontWeight.w500))],
    ]),
  );
}

class _FallbackPhoto extends StatelessWidget {
  final String? type; final String location;
  const _FallbackPhoto({required this.type, required this.location});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: type == 'nature' ? AppTheme.nature : AppTheme.culture),
    child: Stack(fit: StackFit.expand, children: [
      Center(child: Text(type == 'nature' ? '🌿' : '🏛️', style: const TextStyle(fontSize: 60))),
      Positioned(bottom: 14, left: 14,
          child: Text(location, style: const TextStyle(fontFamily: 'Lora', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 6)]), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );
}