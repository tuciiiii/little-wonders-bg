import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_export.dart';
import '../core/poi.dart';
import '../providers/providers.dart';
import 'poi_details_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _hasLocationPermission = false;
  Poi? _selectedPoi;
  int _filterIndex = 0;

  static const _filters = ['Всички', 'Природа', 'Култура'];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();

    if (!mounted) return;

    setState(() {
      _hasLocationPermission = status.isGranted;
    });
  }

  PoiFilter get _currentFilter {
    return [
      PoiFilter.all,
      PoiFilter.nature,
      PoiFilter.culture,
    ][_filterIndex];
  }

  void _buildMarkers(List<Poi> pois, Map<String, dynamic> visits) {
    final newMarkers = pois.map((poi) {
      final visited = visits.containsKey(poi.id);

      return Marker(
        markerId: MarkerId(poi.id),
        position: LatLng(poi.lat, poi.lng),
        icon: visited
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)
            : poi.type == 'nature'
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  )
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
        onTap: () {
          setState(() {
            _selectedPoi = poi;
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(poi.lat, poi.lng),
            ),
          );
        },
      );
    }).toSet();

    if (!mounted) return;

    setState(() {
      _markers = newMarkers;

      if (_selectedPoi != null &&
          !pois.any((poi) => poi.id == _selectedPoi!.id)) {
        _selectedPoi = null;
      }
    });

    _fitMarkers(newMarkers);
  }

  void _fitMarkers(Set<Marker> markers) {
    final controller = _mapController;

    if (controller == null || markers.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (markers.length == 1) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(markers.first.position, 10),
        );
        return;
      }

      double minLat = markers.first.position.latitude;
      double maxLat = minLat;
      double minLng = markers.first.position.longitude;
      double maxLng = minLng;

      for (final marker in markers) {
        if (marker.position.latitude < minLat) {
          minLat = marker.position.latitude;
        }

        if (marker.position.latitude > maxLat) {
          maxLat = marker.position.latitude;
        }

        if (marker.position.longitude < minLng) {
          minLng = marker.position.longitude;
        }

        if (marker.position.longitude > maxLng) {
          maxLng = marker.position.longitude;
        }
      }

      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          60,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPoisAsync = ref.watch(filteredPoisProvider);
    final visits = ref.watch(visitsProvider);
    final currentPosition = ref.watch(locationProvider).valueOrNull;

    ref.listen<AsyncValue<List<Poi>>>(filteredPoisProvider, (previous, next) {
      next.whenData((pois) {
        _buildMarkers(pois, ref.read(visitsProvider));
      });
    });

    ref.listen<Map<String, dynamic>>(visitsProvider, (previous, next) {
      final pois = ref.read(filteredPoisProvider).valueOrNull;

      if (pois != null) {
        _buildMarkers(pois, next);
      }
    });

    filteredPoisAsync.whenData((pois) {
      if (_markers.isEmpty && pois.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _buildMarkers(pois, visits);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(42.7339, 25.4858),
                zoom: 6,
              ),
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: false,
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitMarkers(_markers);
              },
              onTap: (_) {
                if (_selectedPoi != null) {
                  setState(() {
                    _selectedPoi = null;
                  });
                }
              },
              style: _darkMapStyle,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    _GlassSearchBar(),
                    const SizedBox(height: 10),
                    GlassFilterChipRow(
                      labels: _filters,
                      selectedIndex: _filterIndex,
                      leadingIcons: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 13,
                          color: _filterIndex == 0
                              ? AppTheme.accentOrange
                              : AppTheme.textMuted,
                        ),
                        null,
                        null,
                      ],
                      onSelected: (index) {
                        setState(() {
                          _filterIndex = index;
                        });

                        ref.read(poiFilterProvider.notifier).state =
                            _currentFilter;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                _CircleButton(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    if (currentPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(
                            currentPosition.latitude,
                            currentPosition.longitude,
                          ),
                          13,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _CircleButton(
                  icon: Icons.add_rounded,
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 8),
                _CircleButton(
                  icon: Icons.remove_rounded,
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                const SizedBox(height: 8),
                _CircleButton(
                  icon: Icons.fit_screen_rounded,
                  onTap: () => _fitMarkers(_markers),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 110,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _selectedPoi == null
                  ? const SizedBox.shrink()
                  : _PoiCard(
                      key: ValueKey(_selectedPoi!.id),
                      poi: _selectedPoi!,
                      visited: visits.containsKey(_selectedPoi!.id),
                      distanceM: currentPosition == null
                          ? null
                          : Geolocator.distanceBetween(
                              currentPosition.latitude,
                              currentPosition.longitude,
                              _selectedPoi!.lat,
                              _selectedPoi!.lng,
                            ),
                      onTap: () async {
                        final poi = _selectedPoi!;

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PoiDetailsScreen(
                              poi: poi,
                              me: currentPosition,
                            ),
                          ),
                        );

                        if (!mounted) return;

                        setState(() {
                          _selectedPoi = null;
                        });
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

const _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#7c8d80"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0d1b2a"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#162032"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1c2a3a"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#081420"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#111c28"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#111827"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#102018"}]}
]
''';

class _GlassSearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final currentPosition = ref.watch(locationProvider).valueOrNull;

    return Column(
      children: [
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                style: const TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Търси места и забележителности…',
                  hintStyle: const TextStyle(
                    fontFamily: 'Karla',
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: false,
                  contentPadding: const EdgeInsets.only(
                    top: 16,
                    bottom: 10,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (query.isNotEmpty)
          results.when(
            data: (pois) {
              if (pois.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.glassBorder),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pois.length,
                  itemBuilder: (_, index) {
                    final poi = pois[index];

                    return ListTile(
                      leading: Text(poi.type == 'nature' ? '🌿' : '🏛️'),
                      title: Text(
                        poi.name,
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        poi.categoryLabel,
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      onTap: () {
                        ref.read(searchQueryProvider.notifier).state = '';

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PoiDetailsScreen(
                              poi: poi,
                              me: currentPosition,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Icon(
              icon,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

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

  String get _distanceText {
    if (distanceM == null) return '';

    if (distanceM! >= 1000) {
      return '${(distanceM! / 1000).toStringAsFixed(1)} km';
    }

    return '${distanceM!.toStringAsFixed(0)} m';
  }

  String get _categoryText {
    return poi.categoryLabel.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        poi.type == 'nature' ? AppTheme.badgeNature : AppTheme.badgeCulture;

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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: poi.imageUrl.isNotEmpty
                      ? poi.imageUrl.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: poi.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) {
                                return Container(
                                  color: Colors.white10,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorWidget: (_, __, ___) {
                                return Container(
                                  color: Colors.white10,
                                  child: const Center(
                                    child: Icon(
                                      Icons.landscape_rounded,
                                      color: Colors.white70,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              poi.imageUrl,
                              fit: BoxFit.cover,
                            )
                      : Container(
                          color: Colors.white10,
                          child: const Center(
                            child: Icon(
                              Icons.landscape_rounded,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _categoryText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: visited
                                ? AppTheme.success.withValues(alpha: 0.18)
                                : AppTheme.textMuted.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            visited ? 'Посетено' : 'Ново място',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: visited
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                    Row(
                      children: [
                        if (_distanceText.isNotEmpty) ...[
                          const Icon(
                            Icons.place,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _distanceText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.flash_on,
                          size: 14,
                          color: AppTheme.accentGold,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${poi.points} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.rosePurple,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.roseGlowShadow,
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Виж',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.white,
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
}
