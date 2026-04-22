import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/poi.dart';

// ── Badge data model ──────────────────────────────────────────────────────────
class AppBadge {
  final String id;
  final String title;
  final String description;
  final String icon;       // emoji
  final String iconName;   // material icon name key (optional)
  final bool   unlocked;
  final String rarity;     // 'Common' | 'Rare' | 'Epic' | 'Legendary'
  final String category;   // 'Nature' | 'Summit' | 'Distance' | 'Culture' | 'Social'
  final String color;      // hex without #, e.g. '22A060'
  final int    xp;
  final double progress;   // 0.0–1.0 toward unlocking
  final String? earnedDate;

  const AppBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.iconName       = '',
    required this.unlocked,
    this.rarity         = 'Common',
    this.category       = 'Nature',
    this.color          = '22A060',
    this.xp             = 50,
    this.progress       = 0.0,
    this.earnedDate,
  });
}

// ── Badge service ─────────────────────────────────────────────────────────────
class BadgeService {
  BadgeService._();

  static const _definitions = <Map<String, dynamic>>[
    {
      'id': 'first_step',   'title': 'First Step',      'description': 'Visit your first place',
      'icon': '🥾', 'iconName': 'directions_run', 'rarity': 'Common',   'category': 'Nature',   'color': '22A060', 'xp': 50,  'threshold': 1,  'field': 'visits',
    },
    {
      'id': 'explorer',     'title': 'Explorer',         'description': 'Visit 3 different places',
      'icon': '🗺️', 'iconName': 'route',          'rarity': 'Common',   'category': 'Nature',   'color': '3498DB', 'xp': 100, 'threshold': 3,  'field': 'visits',
    },
    {
      'id': 'adventurer',   'title': 'Adventurer',       'description': 'Visit 7 different places',
      'icon': '⛺', 'iconName': 'terrain',         'rarity': 'Rare',     'category': 'Summit',   'color': 'FF8C00', 'xp': 200, 'threshold': 7,  'field': 'visits',
    },
    {
      'id': 'legend',       'title': 'Legend',           'description': 'Visit all 15 places',
      'icon': '🏆', 'iconName': 'filter_hdr',      'rarity': 'Legendary','category': 'Summit',   'color': 'E8B84B', 'xp': 500, 'threshold': 15, 'field': 'visits',
    },
    {
      'id': 'nature_lover', 'title': 'Nature Lover',     'description': 'Visit 3 nature spots',
      'icon': '🌿', 'iconName': 'park',             'rarity': 'Common',   'category': 'Nature',   'color': '22A060', 'xp': 75,  'threshold': 3,  'field': 'nature',
    },
    {
      'id': 'culture_buff', 'title': 'Culture Buff',     'description': 'Visit 3 cultural sites',
      'icon': '🏛️', 'iconName': 'account_balance', 'rarity': 'Common',   'category': 'Culture',  'color': '8B5A1A', 'xp': 75,  'threshold': 3,  'field': 'culture',
    },
    {
      'id': 'peak_master',  'title': 'Peak Master',      'description': 'Earn 500 total points',
      'icon': '🏔️', 'iconName': 'filter_hdr',      'rarity': 'Epic',     'category': 'Summit',   'color': 'FF8C00', 'xp': 300, 'threshold': 500, 'field': 'points',
    },
    {
      'id': 'story_teller', 'title': 'Story Teller',     'description': 'Add a story to a visit',
      'icon': '📖', 'iconName': 'auto_stories',    'rarity': 'Common',   'category': 'Social',   'color': '9B59B6', 'xp': 50,  'threshold': 1,  'field': 'notes',
    },
    {
      'id': 'photographer', 'title': 'Photographer',     'description': 'Add a photo to a visit',
      'icon': '📸', 'iconName': 'camera_alt',       'rarity': 'Common',   'category': 'Social',   'color': '4DB6C4', 'xp': 50,  'threshold': 1,  'field': 'photos',
    },
    {
      'id': 'night_owl',    'title': 'Night Owl',        'description': 'Check in after 8 PM',
      'icon': '🦉', 'iconName': 'nights_stay',      'rarity': 'Rare',     'category': 'Social',   'color': '6B3FA0', 'xp': 150, 'threshold': 1,  'field': 'night',
    },
    {
      'id': 'water_seeker', 'title': 'Water Seeker',     'description': 'Visit a water body place',
      'icon': '💧', 'iconName': 'water',             'rarity': 'Rare',     'category': 'Nature',   'color': '4DB6C4', 'xp': 125, 'threshold': 1,  'field': 'water',
    },
    {
      'id': 'zen_master',   'title': 'Zen Master',       'description': 'Earn 1200 total points',
      'icon': '🧘', 'iconName': 'self_improvement',  'rarity': 'Legendary','category': 'Summit',   'color': 'E8B84B', 'xp': 600, 'threshold': 1200, 'field': 'points',
    },
  ];

  /// Compute all badge states from current visits box + POI data.
  static List<AppBadge> computeBadges({
    required List<Poi> allPois,
    required Box visitsBox,
  }) {
    final visits     = visitsBox.keys.whereType<String>().toSet();
    final visitData  = {
      for (final k in visits) k: (visitsBox.get(k) as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    };

    final visitedPois = allPois.where((p) => visits.contains(p.id)).toList();
    final natureCount = visitedPois.where((p) => p.type == 'nature').length;
    final cultCount   = visitedPois.where((p) => p.type == 'culture').length;
    final totalPoints = visitData.values.fold<int>(0, (s, v) => s + ((v['points'] as num?)?.toInt() ?? 0));
    final hasNote     = visitData.values.any((v) => (v['note'] as String?)?.trim().isNotEmpty == true);
    final hasPhoto    = visitData.values.any((v) => (v['photoPath'] as String?)?.isNotEmpty == true);

    bool hasNight = false;
    bool hasWater = false;
    for (final v in visitData.values) {
      final t = DateTime.tryParse(v['time'] as String? ?? '');
      if (t != null && t.toLocal().hour >= 20) hasNight = true;
      final id = v['poiId'] as String? ?? '';
      final poi = allPois.where((p) => p.id == id).firstOrNull;
      if (poi != null && poi.categoryLabel.toLowerCase().contains('lake') ||
          poi?.categoryLabel.toLowerCase().contains('river') == true ||
          poi?.categoryLabel.toLowerCase().contains('water') == true ||
          poi?.categoryLabel.toLowerCase().contains('sea') == true) hasWater = true;
    }

    return _definitions.map((def) {
      final field     = def['field'] as String;
      final threshold = (def['threshold'] as num).toDouble();
      double current;

      switch (field) {
        case 'visits':  current = visits.length.toDouble();  break;
        case 'nature':  current = natureCount.toDouble();    break;
        case 'culture': current = cultCount.toDouble();      break;
        case 'points':  current = totalPoints.toDouble();    break;
        case 'notes':   current = hasNote ? 1 : 0;          break;
        case 'photos':  current = hasPhoto ? 1 : 0;         break;
        case 'night':   current = hasNight ? 1 : 0;         break;
        case 'water':   current = hasWater ? 1 : 0;         break;
        default:        current = 0;
      }

      final unlocked = current >= threshold;
      final progress = unlocked ? 1.0 : (current / threshold).clamp(0.0, 1.0);

      return AppBadge(
        id:          def['id']          as String,
        title:       def['title']       as String,
        description: def['description'] as String,
        icon:        def['icon']        as String,
        iconName:    def['iconName']    as String? ?? '',
        unlocked:    unlocked,
        rarity:      def['rarity']      as String? ?? 'Common',
        category:    def['category']    as String? ?? 'Nature',
        color:       def['color']       as String? ?? '22A060',
        xp:          (def['xp']         as num?)?.toInt() ?? 50,
        progress:    progress,
        earnedDate:  unlocked ? _today() : null,
      );
    }).toList();
  }

  static String _today() {
    final d = DateTime.now();
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}, ${d.year}';
  }

  /// Show a toast/dialog for any newly unlocked badges.
  static void checkForNewBadges({
    required BuildContext context,
    required List<Poi> allPois,
  }) {
    final box    = Hive.box('visits');
    final badges = computeBadges(allPois: allPois, visitsBox: box);
    final earned = badges.where((b) => b.unlocked).toList();
    if (earned.isEmpty) return;

    // Save newly unlocked ones so we don't re-announce
    final announced = Hive.box('badges');
    for (final b in earned) {
      if (!announced.containsKey(b.id)) {
        announced.put(b.id, true);
        _showBadgeToast(context, b);
        break; // show one at a time
      }
    }
  }

  static void _showBadgeToast(BuildContext context, AppBadge b) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: const Color(0xFF162032),
        content: Row(children: [
          Text(b.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Badge Unlocked! 🎉',
                style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFE8B84B))),
            Text(b.title,
                style: const TextStyle(fontFamily: 'Lora', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFFEEF5F0))),
          ])),
          Text('+${b.xp} XP',
              style: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFE8B84B))),
        ]),
      ),
    );
  }
}