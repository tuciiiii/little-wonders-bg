import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../core/poi.dart';
import '../providers/providers.dart';
import '../services/badge_service.dart';
import '../services/poi_service.dart';
import '../theme/app_theme.dart';

class PoiDetailsScreen extends ConsumerStatefulWidget {
  final Poi poi;
  final Position? me;

  const PoiDetailsScreen({
    super.key,
    required this.poi,
    required this.me,
  });

  @override
  ConsumerState<PoiDetailsScreen> createState() => _PoiDetailsScreenState();
}

class _PoiDetailsScreenState extends ConsumerState<PoiDetailsScreen>
    with SingleTickerProviderStateMixin {
  double? _dist;
  bool _submitting = false;
  File? _image;
  final _noteCtrl = TextEditingController();
  StreamSubscription<Position>? _posSub;

  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool get _checkedIn => ref.read(visitsProvider).containsKey(widget.poi.id);

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _startLocation();
  }

  void _startLocation() {
    if (widget.me != null) {
      _calcDist(widget.me!);
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      _calcDist,
      onError: (_) {
        if (mounted) {
          setState(() => _dist = null);
        }
      },
    );
  }

  void _calcDist(Position pos) {
    if (!mounted) return;

    setState(() {
      _dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        widget.poi.lat,
        widget.poi.lng,
      );
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _noteCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  bool get _canCheckIn {
    final d = _dist;

    return d != null &&
        d <= GameConstants.checkInRadiusMeters &&
        !_checkedIn &&
        !_submitting;
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Karla'),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        backgroundColor: AppTheme.backgroundCard,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (picked != null && mounted) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _checkIn() async {
    final d = _dist;

    if (d == null) {
      _snack('📍 Не можем да определим локацията ти. Включи GPS.');
      return;
    }

    if (d > GameConstants.checkInRadiusMeters) {
      _snack(
        '📍 На ${d.toStringAsFixed(0)} м си. Трябва да си до ${GameConstants.checkInRadiusMeters.toStringAsFixed(0)} м.',
      );
      return;
    }

    if (_checkedIn) {
      _snack('✓ Вече си посетил това място.');
      return;
    }

    if (_image == null && _noteCtrl.text.trim().isEmpty) {
      _snack('Добави снимка или кратка история преди отбелязване.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      final email = user?.email ?? 'Пътешественик';
      final note = _noteCtrl.text.trim();

      String? photoUrl;

      if (_image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('photos/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_image!);
        photoUrl = await storageRef.getDownloadURL();
      }

      await ref.read(visitsProvider.notifier).put(widget.poi.id, {
        'poiId': widget.poi.id,
        'time': DateTime.now().toIso8601String(),
        'distanceMeters': d,
        'points': widget.poi.points,
        'note': note,
        'photoPath': _image?.path,
        'type': widget.poi.type,
      });

      if (uid != null) {
        final visits = ref.read(visitsProvider);

        final total = visits.values.fold<int>(
          0,
          (totalPoints, value) {
            final data = value as Map?;
            return totalPoints + ((data?['points'] as num?)?.toInt() ?? 0);
          },
        );

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'points': total,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'user': email,
        'photo': photoUrl,
        'location': widget.poi.name,
        'note': note,
        'type': widget.poi.type,
        'points': widget.poi.points,
        'time': FieldValue.serverTimestamp(),
        'likedBy': [],
        'commentCount': 0,
      });

      if (!mounted) return;

      _snack('🎉 Успешно посещение! +${widget.poi.points} точки');

      final allPois = await PoiService.loadPois();

      if (!mounted) return;

      BadgeService.checkForNewBadges(
        context: context,
        allPois: allPois,
      );

      setState(() {});
    } catch (e) {
      _snack('Грешка при отбелязване: $e');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final poi = widget.poi;
    final d = _dist;
    final checkedIn = _checkedIn;
    final inRange = d != null && d <= GameConstants.checkInRadiusMeters;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.primaryGreenDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeroHeader(
                poi: poi,
                checkedIn: checkedIn,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GlassSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _CategoryChip(
                                  type: poi.type,
                                  label: poi.categoryLabel,
                                ),
                                const Spacer(),
                                _PointsBadge(points: poi.points),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              poi.description,
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 15,
                                height: 1.6,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(
                              color: Color(0xFF253545),
                              height: 1,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: AppTheme.accentGold,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    poi.tips,
                                    style: const TextStyle(
                                      fontFamily: 'Karla',
                                      fontSize: 14,
                                      height: 1.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DistanceCard(
                        dist: d,
                        checkedIn: checkedIn,
                        inRange: inRange,
                      ),
                      const SizedBox(height: 24),
                      if (!checkedIn) ...[
                        const Text(
                          'ТВОЯТА ИСТОРИЯ',
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickImage,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            child: _image != null
                                ? Stack(
                                    children: [
                                      Image.file(
                                        _image!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() => _image = null);
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 8,
                                                sigmaY: 8,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.50),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundCard,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLg,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.primaryGreen
                                            .withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 30,
                                          color: AppTheme.primaryGreenLight
                                              .withValues(alpha: 0.80),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Добави снимка',
                                          style: TextStyle(
                                            fontFamily: 'Karla',
                                            fontSize: 14,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 4,
                          style: const TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Напиши кратка история от мястото…',
                            hintStyle: const TextStyle(
                              fontFamily: 'Karla',
                              color: AppTheme.textMuted,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundCard,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLg),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLg),
                              borderSide:
                                  const BorderSide(color: Color(0xFF253545)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLg),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _canCheckIn ? _checkIn : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inRange
                                  ? AppTheme.primaryGreen
                                  : AppTheme.backgroundCard,
                              disabledBackgroundColor: AppTheme.backgroundCard,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              side: BorderSide(
                                color: inRange
                                    ? AppTheme.primaryGreen
                                    : AppTheme.glassBorder,
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        inRange
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.location_searching_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        inRange
                                            ? 'Отбележи посещение'
                                            : 'Приближи се до мястото',
                                        style: TextStyle(
                                          fontFamily: 'Karla',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: inRange
                                              ? Colors.white
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (!inRange && d != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Center(
                              child: Text(
                                'Остават ${(d - GameConstants.checkInRadiusMeters).toStringAsFixed(0)} м',
                                style: const TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                      ] else
                        _GlassSection(
                          tint: AppTheme.badgeNature.withValues(alpha: 0.08),
                          borderColor:
                              AppTheme.badgeNature.withValues(alpha: 0.25),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.badgeNature
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.badgeNature,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Мястото е посетено! 🎉',
                                      style: TextStyle(
                                        fontFamily: 'Karla',
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.badgeNature,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Историята ти е запазена в дневника.',
                                      style: TextStyle(
                                        fontFamily: 'Karla',
                                        fontSize: 13,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Poi poi;
  final bool checkedIn;

  const _HeroHeader({
    required this.poi,
    required this.checkedIn,
  });

  @override
  Widget build(BuildContext context) {
    final isNature = poi.type == 'nature';

    return Stack(
      fit: StackFit.expand,
      children: [
        poi.imageUrl.isNotEmpty
            ? (poi.imageUrl.startsWith('http')
                ? Image.network(
                    poi.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: isNature ? AppTheme.nature : AppTheme.culture,
                      ),
                    ),
                  )
                : Image.asset(
                    poi.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: isNature ? AppTheme.nature : AppTheme.culture,
                      ),
                    ),
                  ))
            : Container(
                decoration: BoxDecoration(
                  gradient: isNature ? AppTheme.nature : AppTheme.culture,
                ),
              ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.30),
                Colors.black.withValues(alpha: 0.60),
              ],
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 30,
              ),
            ),
          ),
        ),
        if (checkedIn)
          Positioned.fill(
            child: Container(
              color: AppTheme.badgeNature.withValues(alpha: 0.10),
            ),
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (checkedIn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.badgeNature.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        border: Border.all(
                          color: AppTheme.badgeNature.withValues(alpha: 0.40),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: Colors.greenAccent,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Посетено',
                            style: TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    poi.name,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DistanceCard extends StatelessWidget {
  final double? dist;
  final bool checkedIn;
  final bool inRange;

  const _DistanceCard({
    required this.dist,
    required this.checkedIn,
    required this.inRange,
  });

  @override
  Widget build(BuildContext context) {
    if (checkedIn) {
      return _GlassSection(
        tint: AppTheme.badgeNature.withValues(alpha: 0.08),
        borderColor: AppTheme.badgeNature.withValues(alpha: 0.20),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.badgeNature,
              size: 22,
            ),
            SizedBox(width: 12),
            Text(
              'Вече си посетил това място.',
              style: TextStyle(
                fontFamily: 'Karla',
                fontWeight: FontWeight.w700,
                color: AppTheme.badgeNature,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (dist == null) {
      return const _GlassSection(
        child: Row(
          children: [
            Icon(
              Icons.location_off_outlined,
              color: AppTheme.textMuted,
              size: 22,
            ),
            SizedBox(width: 12),
            Text(
              'Локацията не е достъпна',
              style: TextStyle(
                fontFamily: 'Karla',
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final color = inRange ? AppTheme.badgeNature : AppTheme.warning;
    final distStr = dist! >= 1000
        ? '${(dist! / 1000).toStringAsFixed(1)} км'
        : '${dist!.toStringAsFixed(0)} м';

    return _GlassSection(
      tint: color.withValues(alpha: 0.06),
      borderColor: color.withValues(alpha: 0.20),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (1 -
                          (dist! / (GameConstants.checkInRadiusMeters * 3))
                              .clamp(0.0, 1.0))
                      .toDouble(),
                  strokeWidth: 4,
                  backgroundColor: AppTheme.glassSurface,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
                Icon(
                  inRange ? Icons.check_rounded : Icons.near_me_rounded,
                  size: 16,
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inRange ? 'В обхват си! 🎉' : 'На $distStr си от мястото',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Радиус за посещение: ${GameConstants.checkInRadiusMeters.toStringAsFixed(0)} м',
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final Widget child;
  final Color? tint;
  final Color? borderColor;

  const _GlassSection({
    required this.child,
    this.tint,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tint ?? AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: borderColor ?? AppTheme.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  final String type;
  final String label;

  const _CategoryChip({
    required this.type,
    required this.label,
  });

  Color get _color =>
      type == 'nature' ? AppTheme.badgeNature : AppTheme.badgeCulture;

  IconData get _icon =>
      type == 'nature' ? Icons.park_outlined : Icons.account_balance_outlined;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: _color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 12, color: _color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ],
        ),
      );
}

class _PointsBadge extends StatelessWidget {
  final int points;

  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.accentGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
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
            const SizedBox(width: 4),
            Text(
              '+$points XP',
              style: const TextStyle(
                fontFamily: 'Karla',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentGold,
              ),
            ),
          ],
        ),
      );
}
