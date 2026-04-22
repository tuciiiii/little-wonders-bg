import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_export.dart';
import '../core/poi.dart';
import '../providers/providers.dart';
import 'poi_details_screen.dart';
import '../widgets/glass_filter_chip.dart';
import '../widgets/status_badge_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _ctrl;
  Set<Marker> _markers   = {};
  bool _hasPerm          = false;
  Poi? _selectedPoi;
  int _filterIdx         = 0;

  static const _filters = ['All', 'Nature', 'Culture'];

  @override
  void initState() { super.initState(); _initPerm(); }

  Future<void> _initPerm() async {
    final s = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    setState(() => _hasPerm = s.isGranted);
  }

  PoiFilter get _currentFilter => [PoiFilter.all, PoiFilter.nature, PoiFilter.culture][_filterIdx];

  void _buildMarkers(List<Poi> pois, Map<String, dynamic> visits) {
    final ms = pois.map((p) {
      final visited = visits.containsKey(p.id);
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.lat, p.lng),
        icon: visited
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : p.type == 'nature'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          setState(() => _selectedPoi = p);
          _ctrl?.animateCamera(CameraUpdate.newLatLng(LatLng(p.lat, p.lng)));
        },
      );
    }).toSet();
    if (mounted) setState(() => _markers = ms);
    _fitMarkers(ms);
  }

  void _fitMarkers(Set<Marker> ms) {
    final c = _ctrl;
    if (c == null || ms.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ms.length == 1) { c.animateCamera(CameraUpdate.newLatLngZoom(ms.first.position, 10)); return; }
      double minLat = ms.first.position.latitude, maxLat = minLat;
      double minLng = ms.first.position.longitude, maxLng = minLng;
      for (final m in ms) {
        if (m.position.latitude  < minLat) minLat = m.position.latitude;
        if (m.position.latitude  > maxLat) maxLat = m.position.latitude;
        if (m.position.longitude < minLng) minLng = m.position.longitude;
        if (m.position.longitude > maxLng) maxLng = m.position.longitude;
      }
      c.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 60));
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredPoisProvider);
    final visits        = ref.watch(visitsProvider);
    final me            = ref.watch(locationProvider).valueOrNull;

    filteredAsync.whenData((pois) => _buildMarkers(pois, visits));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(42.7339, 25.4858), zoom: 6),
            myLocationEnabled: _hasPerm, myLocationButtonEnabled: false,
            markers: _markers,
            onMapCreated: (c) { _ctrl = c; _fitMarkers(_markers); },
            onTap: (_) {
              if (_selectedPoi != null) setState(() => _selectedPoi = null);
            },
            style: _kDarkMapStyle,
          ),
        ),

        // Top controls
        Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(children: [
                _GlassSearchBar(),
                const SizedBox(height: 10),
                GlassFilterChipRow(
                  labels: _filters,
                  selectedIndex: _filterIdx,
                  activeColor: AppTheme.accentGold,
                  leadingIcons: [
                    Icon(Icons.grid_view_rounded, size: 13,
                        color: _filterIdx == 0 ? AppTheme.accentGold : AppTheme.textMuted),
                    null,
                    null,
                  ],
                  onSelected: (i) {
                    setState(() => _filterIdx = i);
                    ref.read(poiFilterProvider.notifier).state = _currentFilter;
                  },
                ),
              ]),
            ),
          ),
        ),

        // Right-side buttons
        Positioned(right: 14, top: MediaQuery.of(context).size.height * 0.35,
          child: Column(children: [
            _CircleBtn(icon: Icons.my_location_rounded, onTap: () {
              if (me != null) _ctrl?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(me.latitude, me.longitude), 13));
            }),
            const SizedBox(height: 8),
            _CircleBtn(icon: Icons.add_rounded,       onTap: () => _ctrl?.animateCamera(CameraUpdate.zoomIn())),
            const SizedBox(height: 8),
            _CircleBtn(icon: Icons.remove_rounded,    onTap: () => _ctrl?.animateCamera(CameraUpdate.zoomOut())),
            const SizedBox(height: 8),
            _CircleBtn(icon: Icons.fit_screen_rounded, onTap: () => _fitMarkers(_markers)),
          ]),
        ),

        // POI bottom card
        Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 110,
          left: 16,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _selectedPoi == null
                ? const SizedBox.shrink()
                : _PoiCard(
              key: ValueKey(_selectedPoi!.id),
              poi: _selectedPoi!,
              visited: visits.containsKey(_selectedPoi!.id),
              distanceM: me == null
                  ? null
                  : Geolocator.distanceBetween(me.latitude, me.longitude,
                  _selectedPoi!.lat, _selectedPoi!.lng),
              onTap: () async {
                final poi = _selectedPoi!;
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PoiDetailsScreen(poi: poi, me: me)));
                setState(() => _selectedPoi = null);
              },
            ),
          ),
        ),
      ]),
    );
  }
}

const _kDarkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#5a7a6a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0d1b2a"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#162032"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1c2a3a"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#081420"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#111c28"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0f2218"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#0a1c12"}]}
]''';

// ── Search bar ────────────────────────────────────────────────────────────────
class _GlassSearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query   = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final me      = ref.watch(locationProvider).valueOrNull;

    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: AppTheme.glassBorder),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16)],
            ),
            child: TextField(
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              style: const TextStyle(fontFamily: 'Karla', fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search trails, peaks, forests…',
                hintStyle: const TextStyle(fontFamily: 'Karla', color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                    onPressed: () => ref.read(searchQueryProvider.notifier).state = '')
                    : null,
                border: InputBorder.none, contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      if (query.isNotEmpty)
        results.when(
          data: (pois) => pois.isEmpty ? const SizedBox.shrink() : Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.glassBorder),
              boxShadow: AppTheme.cardShadow,
            ),
            child: ListView.builder(
              shrinkWrap: true, itemCount: pois.length,
              itemBuilder: (_, i) => ListTile(
                leading: Text(pois[i].type == 'nature' ? '🌿' : '🏛️'),
                title: Text(pois[i].name,
                    style: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700,
                        fontSize: 14, color: AppTheme.textPrimary)),
                subtitle: Text(pois[i].categoryLabel,
                    style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: AppTheme.textMuted)),
                onTap: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PoiDetailsScreen(poi: pois[i], me: me)));
                },
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
    ]);
  }
}

// ── Circle button ─────────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 44, width: 44,
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Icon(icon, color: AppTheme.textSecondary, size: 18),
        ),
      ),
    ),
  );
}

// ── POI bottom card ───────────────────────────────────────────────────────────
class _PoiCard extends StatelessWidget {
  final Poi poi;
  final bool visited;
  final double? distanceM;
  final VoidCallback onTap;

  const _PoiCard({
    super.key,
    required this.poi,
    required this.visited,
    required this.distanceM,
    required this.onTap,
  });

  String get _km => distanceM == null
      ? ''
      : distanceM! >= 1000
      ? '${(distanceM! / 1000).toStringAsFixed(1)} km'
      : '${distanceM!.toStringAsFixed(0)} m';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassBorder),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // 📸 IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: poi.imageUrl.isNotEmpty
                      ? (poi.imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                    imageUrl: poi.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.white10,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.white10,
                      child: const Center(
                        child: Icon(Icons.landscape_rounded, color: Colors.white70),
                      ),
                    ),
                  )
                      : Image.asset(
                    poi.imageUrl,
                    fit: BoxFit.cover,
                  ))
                      : Container(
                    color: Colors.white10,
                    child: const Center(
                      child: Icon(Icons.landscape_rounded, color: Colors.white70),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // 🧾 CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🏷️ BADGES
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            poi.categoryLabel.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Hard',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // 🏔️ TITLE
                    Text(
                      poi.name,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // 📍 DISTANCE + ⚡ XP
                    Row(
                      children: [
                        if (_km.isNotEmpty) ...[
                          const Icon(Icons.place, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            _km,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        const Icon(Icons.flash_on, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${poi.points} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // 🚀 GO BUTTON
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.glowShadow(AppTheme.accentGold),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Go',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.black),
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
}