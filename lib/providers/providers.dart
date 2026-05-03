import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/poi.dart';
import '../services/poi_service.dart';
import '../services/badge_service.dart';
import '../core/constants.dart';

enum PoiFilter { all, nature, culture }

final poisProvider = FutureProvider<List<Poi>>((ref) => PoiService.loadPois());

final poiFilterProvider = StateProvider<PoiFilter>((ref) => PoiFilter.all);

final filteredPoisProvider = FutureProvider<List<Poi>>((ref) async {
  final all = await ref.watch(poisProvider.future);
  final filter = ref.watch(poiFilterProvider);
  return switch (filter) {
    PoiFilter.nature => all.where((p) => p.type == 'nature').toList(),
    PoiFilter.culture => all.where((p) => p.type == 'culture').toList(),
    PoiFilter.all => all,
  };
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Poi>>((ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return [];
  final all = await ref.watch(poisProvider.future);
  return all
      .where(
        (p) =>
            p.name.toLowerCase().contains(query) ||
            p.categoryLabel.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query),
      )
      .toList();
});

final locationProvider = FutureProvider<Position?>((ref) async {
  final status = await Permission.locationWhenInUse.request();
  if (!status.isGranted) return null;
  try {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  } catch (_) {
    return null;
  }
});

// ── Visits notifier — writeable ───────────────────────────────────────────────
class VisitsNotifier extends StateNotifier<Map<String, dynamic>> {
  VisitsNotifier() : super(_load());
  static Map<String, dynamic> _load() {
    final box = Hive.box('visits');
    return Map<String, dynamic>.fromEntries(
        box.keys.whereType<String>().map((k) => MapEntry(k, box.get(k))));
  }

  Future<void> put(String id, Map<String, dynamic> data) async {
    await Hive.box('visits').put(id, data);
    state = _load();
  }

  Future<void> remove(String id) async {
    await Hive.box('visits').delete(id);
    state = _load();
  }

  Future<void> clear() async {
    await Hive.box('visits').clear();
    state = {};
  }
}

final visitsProvider =
    StateNotifierProvider<VisitsNotifier, Map<String, dynamic>>(
        (_) => VisitsNotifier());

final badgesProvider = FutureProvider<List<AppBadge>>((ref) async {
  ref.watch(visitsProvider);
  final pois = await ref.watch(poisProvider.future);
  final box = Hive.box('visits');
  return BadgeService.computeBadges(allPois: pois, visitsBox: box);
});

// ── UserStats ─────────────────────────────────────────────────────────────────
class UserStats {
  final int points, visitedCount, unlockedBadges, pointsToNext;
  final String levelName, nextLevel;
  final double levelProgress;
  const UserStats({
    required this.points,
    required this.visitedCount,
    required this.unlockedBadges,
    required this.levelName,
    required this.levelProgress,
    required this.nextLevel,
    required this.pointsToNext,
  });
}

final userStatsProvider = Provider<UserStats>((ref) {
  final visits = ref.watch(visitsProvider);
  final points = visits.values.fold<int>(0, (s, v) {
    if (v is Map && v['points'] != null) {
      return s + (v['points'] as num).toInt();
    }
    return s;
  });
  return UserStats(
    points: points,
    visitedCount: visits.length,
    unlockedBadges: Hive.box('badges').length,
    levelName: GameConstants.levelName(points),
    levelProgress: GameConstants.levelProgress(points),
    nextLevel: GameConstants.nextLevelName(points),
    pointsToNext: GameConstants.pointsToNextLevel(points),
  );
});
