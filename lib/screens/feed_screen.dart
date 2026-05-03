import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_export.dart';

Color _categoryColor(String? type) {
  switch (type) {
    case 'nature':
      return AppTheme.badgeNature;
    case 'culture':
      return AppTheme.badgeCulture;
    default:
      return AppTheme.accentGold;
  }
}

String _categoryLabel(String? type) {
  switch (type) {
    case 'nature':
      return '🌿  Природа';
    case 'culture':
      return '🏛️  Култура';
    default:
      return type ?? 'Приключение';
  }
}

final List<Map<String, dynamic>> _demoPosts = [
  {
    'user': 'mira@littlewonders.bg',
    'role': 'Планински изследовател',
    'location': 'Тевно езеро',
    'note':
        'Високо в Пирин всичко изглежда по-тихо и по-силно. Езерото е като скрито малко чудо между върховете.',
    'type': 'nature',
    'points': 190,
    'photo': 'assets/images/demo/pirin_feed.png',
    'likedBy': ['1', '2', '3', '4', '5', '6', '7', '8'],
    'commentCount': 4,
    'time': null,
    'timeLabel': 'преди 2 дни',
  },
  {
    'user': 'alex@littlewonders.bg',
    'role': 'Морски пътешественик',
    'location': 'Старият Несебър',
    'note':
        'Калдъръмени улици, стари църкви и море навсякъде около теб. Има много специална атмосфера привечер.',
    'type': 'culture',
    'points': 160,
    'photo': 'assets/images/demo/nesebar_feed.png',
    'likedBy': ['1', '2', '3', '4', '5', '6'],
    'commentCount': 2,
    'time': null,
    'timeLabel': 'преди 4 дни',
  },
  {
    'user': 'nora@littlewonders.bg',
    'role': 'Родопски мечтател',
    'location': 'Чудните мостове',
    'note':
        'Огромните скални арки в Родопите са още по-впечатляващи на живо. Мястото е спокойно и много фотогенично.',
    'type': 'nature',
    'points': 140,
    'photo': 'assets/images/demo/chudnimostove_feed.png',
    'likedBy': ['1', '2', '3', '4', '5'],
    'commentCount': 3,
    'time': null,
    'timeLabel': 'преди седмица',
  },
];

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;

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

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

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
                .collection('posts')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildDemoFeed();
              }

              if (!snapshot.hasData ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return _buildDemoFeed();
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return _buildDemoFeed();
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _FeedCard(
                          postId: docs[i].id,
                          post: docs[i].data() as Map<String, dynamic>,
                          isDemo: false,
                        ),
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
      decoration: const BoxDecoration(
        gradient: AppTheme.aurora,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Общност',
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Истории от посетени места',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ClipRRect(
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
                      Icons.photo_library_rounded,
                      color: AppTheme.textPrimary,
                      size: 20,
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

  Widget _buildDemoFeed() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _FeedCard(
                postId: 'demo_$i',
                post: _demoPosts[i],
                isDemo: true,
              ),
            ),
          ),
          childCount: _demoPosts.length,
        ),
      ),
    );
  }
}

class _FeedCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;
  final bool isDemo;

  const _FeedCard({
    required this.postId,
    required this.post,
    this.isDemo = false,
  });

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _commentsOpen = false;
  bool _sending = false;
  bool _updatingLike = false;
  final _commentCtrl = TextEditingController();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  List get _likedBy => widget.post['likedBy'] as List? ?? [];

  bool get _liked => _likedBy.contains(_uid);

  int get _likes => _likedBy.length;

  String get _location =>
      (widget.post['location'] ?? 'Непознато място').toString();

  String get _note => (widget.post['note'] ?? '').toString();

  String get _user => (widget.post['user'] ?? 'Пътешественик').toString();

  String get _role => (widget.post['role'] ?? 'Изследовател').toString();

  String? get _photo => widget.post['photo']?.toString();

  String? get _type => widget.post['type']?.toString();

  int get _points => (widget.post['points'] as num?)?.toInt() ?? 0;

  String get _timeAgo {
    final ts = widget.post['time'] as Timestamp?;

    if (ts == null) {
      if (widget.post['timeLabel'] != null) {
        return widget.post['timeLabel'].toString();
      }

      return 'току-що';
    }

    final diff = DateTime.now().difference(ts.toDate());

    if (diff.inMinutes < 1) return 'току-що';
    if (diff.inMinutes < 60) return 'преди ${diff.inMinutes} мин';
    if (diff.inHours < 24) return 'преди ${diff.inHours} ч';

    return 'преди ${diff.inDays} дни';
  }

  String _initials(String value) {
    final name = value.split('@').first.trim();

    if (name.isEmpty) return '?';

    final parts = name.split('.');

    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }

  Future<void> _toggleLike() async {
    if (widget.isDemo) {
      _showMessage('Харесванията ще бъдат активни при реални публикации.');
      return;
    }

    if (_uid.isEmpty || _updatingLike) return;

    setState(() => _updatingLike = true);

    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      if (_liked) {
        await postRef.update({
          'likedBy': FieldValue.arrayRemove([_uid]),
        });
      } else {
        await postRef.update({
          'likedBy': FieldValue.arrayUnion([_uid]),
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Неуспешно обновяване на харесването.');
    } finally {
      if (mounted) {
        setState(() => _updatingLike = false);
      }
    }
  }

  Future<void> _sendComment() async {
    if (widget.isDemo) {
      _showMessage('Коментарите са активни само за реални истории.');
      return;
    }

    final text = _commentCtrl.text.trim();

    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      await postRef.collection('comments').add({
        'user': FirebaseAuth.instance.currentUser?.email ?? 'Пътешественик',
        'text': text,
        'time': FieldValue.serverTimestamp(),
      });

      await postRef.update({
        'commentCount': FieldValue.increment(1),
      });

      _commentCtrl.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Коментарът не беше изпратен.');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Karla'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo?.isNotEmpty == true;
    final catColor = _categoryColor(_type);
    final catLabel = _categoryLabel(_type);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: hasPhoto
                      ? _photo!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: _photo!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppTheme.backgroundCard,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.accentGold,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => _FallbackPhoto(
                                type: _type,
                                location: _location,
                              ),
                            )
                          : Image.asset(
                              _photo!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _FallbackPhoto(
                                type: _type,
                                location: _location,
                              ),
                            )
                      : _FallbackPhoto(
                          type: _type,
                          location: _location,
                        ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.60),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Text(
                          catLabel,
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 12,
                              color: AppTheme.accentGold,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '+$_points XP',
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Text(
                    _location,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 8),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Container(
              color: AppTheme.backgroundCard,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.rosePurple,
                          border: Border.all(
                            color:
                                AppTheme.accentOrange.withValues(alpha: 0.30),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _initials(_user),
                            style: const TextStyle(
                              fontFamily: 'Karla',
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user,
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _role,
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _timeAgo,
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (_note.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _note,
                      style: const TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.55,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ActionBtn(
                        icon: _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: '$_likes',
                        color: _liked ? Colors.redAccent : AppTheme.textMuted,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: null,
                        color: _commentsOpen
                            ? AppTheme.accentOrange
                            : AppTheme.textMuted,
                        onTap: () {
                          setState(() => _commentsOpen = !_commentsOpen);
                        },
                      ),
                    ],
                  ),
                  if (_commentsOpen) ...[
                    const SizedBox(height: 14),
                    widget.isDemo
                        ? _DemoCommentsBox(
                            commentController: _commentCtrl,
                            onSend: _sendComment,
                          )
                        : _RealCommentsBox(
                            postId: widget.postId,
                            commentController: _commentCtrl,
                            sending: _sending,
                            onSend: _sendComment,
                            initialsBuilder: _initials,
                          ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoCommentsBox extends StatelessWidget {
  final TextEditingController commentController;
  final VoidCallback onSend;

  const _DemoCommentsBox({
    required this.commentController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDeep,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Коментарите ще бъдат активни при реални публикации.',
              style: TextStyle(
                fontFamily: 'Karla',
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Напиши коментар…',
                    hintStyle: const TextStyle(
                      fontFamily: 'Karla',
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.glowShadow(AppTheme.accentOrange),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RealCommentsBox extends StatelessWidget {
  final String postId;
  final TextEditingController commentController;
  final bool sending;
  final VoidCallback onSend;
  final String Function(String value) initialsBuilder;

  const _RealCommentsBox({
    required this.postId,
    required this.commentController,
    required this.sending,
    required this.onSend,
    required this.initialsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDeep,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .collection('comments')
                .orderBy('time')
                .snapshots(),
            builder: (_, snap) {
              final comments = snap.data?.docs ?? [];

              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Все още няма коментари.',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              return Column(
                children: comments.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final user = (data['user'] ?? 'Пътешественик').toString();
                  final text = (data['text'] ?? '').toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundCard,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              initialsBuilder(user),
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user,
                                style: const TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                              Text(
                                text,
                                style: const TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Напиши коментар…',
                    hintStyle: const TextStyle(
                      fontFamily: 'Karla',
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: sending ? null : onSend,
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.glowShadow(AppTheme.accentOrange),
                  ),
                  child: sending
                      ? const Center(
                          child: SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          if (label != null) ...[
            const SizedBox(width: 5),
            Text(
              label!,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FallbackPhoto extends StatelessWidget {
  final String? type;
  final String location;

  const _FallbackPhoto({
    required this.type,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: type == 'nature' ? AppTheme.nature : AppTheme.culture,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Text(
              type == 'nature' ? '🌿' : '🏛️',
              style: const TextStyle(fontSize: 60),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: Text(
              location,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 6),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
