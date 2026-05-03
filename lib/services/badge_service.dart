import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../core/poi.dart';

class AppBadge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String iconName;
  final bool unlocked;
  final String rarity;
  final String category;
  final String color;
  final int xp;
  final double progress;
  final String? earnedDate;

  const AppBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.iconName = '',
    required this.unlocked,
    this.rarity = 'Обикновена',
    this.category = 'Nature',
    this.color = '22A060',
    this.xp = 50,
    this.progress = 0.0,
    this.earnedDate,
  });
}

class BadgeService {
  BadgeService._();

  static const _definitions = <Map<String, dynamic>>[
    {
      'id': 'first_step',
      'title': 'Първа стъпка',
      'description': 'Посети първото си място',
      'icon': '🥾',
      'iconName': 'directions_run',
      'rarity': 'Обикновена',
      'category': 'Nature',
      'color': '22A060',
      'xp': 50,
      'threshold': 1,
      'field': 'visits',
    },
    {
      'id': 'explorer',
      'title': 'Изследовател',
      'description': 'Посети 3 различни места',
      'icon': '🗺️',
      'iconName': 'route',
      'rarity': 'Обикновена',
      'category': 'Nature',
      'color': '3498DB',
      'xp': 100,
      'threshold': 3,
      'field': 'visits',
    },
    {
      'id': 'adventurer',
      'title': 'Приключенец',
      'description': 'Посети 7 различни места',
      'icon': '⛺',
      'iconName': 'terrain',
      'rarity': 'Рядка',
      'category': 'Nature',
      'color': 'FF8C00',
      'xp': 200,
      'threshold': 7,
      'field': 'visits',
    },
    {
      'id': 'legend',
      'title': 'Легенда',
      'description': 'Посети всички места в приложението',
      'icon': '🏆',
      'iconName': 'filter_hdr',
      'rarity': 'Легендарна',
      'category': 'Nature',
      'color': 'E8B84B',
      'xp': 500,
      'threshold': 15,
      'field': 'visits',
    },
    {
      'id': 'nature_lover',
      'title': 'Любител на природата',
      'description': 'Посети 3 природни места',
      'icon': '🌿',
      'iconName': 'park',
      'rarity': 'Обикновена',
      'category': 'Nature',
      'color': '22A060',
      'xp': 75,
      'threshold': 3,
      'field': 'nature',
    },
    {
      'id': 'culture_buff',
      'title': 'Пазител на историята',
      'description': 'Посети 3 културни обекта',
      'icon': '🏛️',
      'iconName': 'account_balance',
      'rarity': 'Обикновена',
      'category': 'Culture',
      'color': '8B5A1A',
      'xp': 75,
      'threshold': 3,
      'field': 'culture',
    },
    {
      'id': 'peak_master',
      'title': 'Майстор на върховете',
      'description': 'Събери общо 500 точки',
      'icon': '🏔️',
      'iconName': 'filter_hdr',
      'rarity': 'Епична',
      'category': 'Nature',
      'color': 'FF8C00',
      'xp': 300,
      'threshold': 500,
      'field': 'points',
    },
    {
      'id': 'story_teller',
      'title': 'Разказвач',
      'description': 'Добави история към свое посещение',
      'icon': '📖',
      'iconName': 'auto_stories',
      'rarity': 'Обикновена',
      'category': 'Culture',
      'color': '9B59B6',
      'xp': 50,
      'threshold': 1,
      'field': 'notes',
    },
    {
      'id': 'photographer',
      'title': 'Фотограф',
      'description': 'Добави снимка към свое посещение',
      'icon': '📸',
      'iconName': 'camera_alt',
      'rarity': 'Обикновена',
      'category': 'Nature',
      'color': '4DB6C4',
      'xp': 50,
      'threshold': 1,
      'field': 'photos',
    },
    {
      'id': 'night_owl',
      'title': 'Нощен пътешественик',
      'description': 'Отбележи посещение след 20:00 ч.',
      'icon': '🦉',
      'iconName': 'nights_stay',
      'rarity': 'Рядка',
      'category': 'Culture',
      'color': '6B3FA0',
      'xp': 150,
      'threshold': 1,
      'field': 'night',
    },
    {
      'id': 'water_seeker',
      'title': 'Търсач на водни места',
      'description': 'Посети езеро, река, водопад или море',
      'icon': '💧',
      'iconName': 'water',
      'rarity': 'Рядка',
      'category': 'Nature',
      'color': '4DB6C4',
      'xp': 125,
      'threshold': 1,
      'field': 'water',
    },
    {
      'id': 'zen_master',
      'title': 'Дзен майстор',
      'description': 'Събери общо 1200 точки',
      'icon': '🧘',
      'iconName': 'self_improvement',
      'rarity': 'Легендарна',
      'category': 'Culture',
      'color': 'E8B84B',
      'xp': 600,
      'threshold': 1200,
      'field': 'points',
    },
  ];

  static List<AppBadge> computeBadges({
    required List<Poi> allPois,
    required Box visitsBox,
  }) {
    final visits = visitsBox.keys.whereType<String>().toSet();

    final visitData = {
      for (final key in visits)
        key: (visitsBox.get(key) as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
    };

    final visitedPois =
        allPois.where((poi) => visits.contains(poi.id)).toList();
    final natureCount = visitedPois.where((poi) => poi.type == 'nature').length;
    final cultureCount =
        visitedPois.where((poi) => poi.type == 'culture').length;

    final totalPoints = visitData.values.fold<int>(
      0,
      (total, data) => total + ((data['points'] as num?)?.toInt() ?? 0),
    );

    final hasNote = visitData.values.any(
      (data) => (data['note'] as String?)?.trim().isNotEmpty == true,
    );

    final hasPhoto = visitData.values.any(
      (data) => (data['photoPath'] as String?)?.isNotEmpty == true,
    );

    bool hasNight = false;
    bool hasWater = false;

    for (final data in visitData.values) {
      final time = DateTime.tryParse(data['time'] as String? ?? '');

      if (time != null && time.toLocal().hour >= 20) {
        hasNight = true;
      }

      final id = data['poiId'] as String? ?? '';
      final poi = allPois.where((item) => item.id == id).firstOrNull;

      if (poi != null && _isWaterPlace(poi)) {
        hasWater = true;
      }
    }

    return _definitions.map((definition) {
      final field = definition['field'] as String;
      final threshold = (definition['threshold'] as num).toDouble();

      final current = switch (field) {
        'visits' => visits.length.toDouble(),
        'nature' => natureCount.toDouble(),
        'culture' => cultureCount.toDouble(),
        'points' => totalPoints.toDouble(),
        'notes' => hasNote ? 1.0 : 0.0,
        'photos' => hasPhoto ? 1.0 : 0.0,
        'night' => hasNight ? 1.0 : 0.0,
        'water' => hasWater ? 1.0 : 0.0,
        _ => 0.0,
      };

      final unlocked = current >= threshold;
      final progress = unlocked ? 1.0 : (current / threshold).clamp(0.0, 1.0);

      return AppBadge(
        id: definition['id'] as String,
        title: definition['title'] as String,
        description: definition['description'] as String,
        icon: definition['icon'] as String,
        iconName: definition['iconName'] as String? ?? '',
        unlocked: unlocked,
        rarity: definition['rarity'] as String? ?? 'Обикновена',
        category: definition['category'] as String? ?? 'Nature',
        color: definition['color'] as String? ?? '22A060',
        xp: (definition['xp'] as num?)?.toInt() ?? 50,
        progress: progress,
        earnedDate: unlocked ? _today() : null,
      );
    }).toList();
  }

  static bool _isWaterPlace(Poi poi) {
    final label = poi.categoryLabel.toLowerCase();
    final name = poi.name.toLowerCase();

    return label.contains('lake') ||
        label.contains('river') ||
        label.contains('water') ||
        label.contains('sea') ||
        label.contains('езеро') ||
        label.contains('река') ||
        label.contains('водопад') ||
        label.contains('море') ||
        name.contains('lake') ||
        name.contains('river') ||
        name.contains('water') ||
        name.contains('sea') ||
        name.contains('езеро') ||
        name.contains('река') ||
        name.contains('водопад') ||
        name.contains('море');
  }

  static String _today() {
    final date = DateTime.now();

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

  static void checkForNewBadges({
    required BuildContext context,
    required List<Poi> allPois,
  }) {
    final visitsBox = Hive.box('visits');
    final badges = computeBadges(allPois: allPois, visitsBox: visitsBox);
    final earned = badges.where((badge) => badge.unlocked).toList();

    if (earned.isEmpty) return;

    final announced = Hive.box('badges');

    for (final badge in earned) {
      if (!announced.containsKey(badge.id)) {
        announced.put(badge.id, true);
        _showBadgeToast(context, badge);
        break;
      }
    }
  }

  static void _showBadgeToast(BuildContext context, AppBadge badge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: const Color(0xFF162032),
        content: Row(
          children: [
            Text(
              badge.icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Отключена значка! 🎉',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFFE8B84B),
                    ),
                  ),
                  Text(
                    badge.title,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFEEF5F0),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '+${badge.xp} XP',
              style: const TextStyle(
                fontFamily: 'Karla',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFFE8B84B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
