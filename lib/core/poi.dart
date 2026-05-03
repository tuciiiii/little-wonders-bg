class Poi {
  final String id;
  final String name;
  final String type;
  final String categoryLabel;
  final double lat;
  final double lng;
  final String imageUrl;
  final String description;
  final String tips;
  final int points;

  const Poi({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryLabel,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.description,
    required this.tips,
    required this.points,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? 'nature').trim();
    final rawCategory = (json['categoryLabel'] as String? ?? '').trim();

    return Poi(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      categoryLabel: _localizedCategoryLabel(rawCategory, type),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tips: json['tips'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  static String _localizedCategoryLabel(String category, String type) {
    final value = category.toLowerCase().trim();
    final poiType = type.toLowerCase().trim();

    switch (value) {
      case 'peak':
        return 'Връх';

      case 'lake':
      case 'lakes':
        return 'Езеро';

      case 'monastery':
        return 'Манастир';

      case 'rock formation':
        return 'Скали';

      case 'old town':
      case 'historic town':
        return 'Стар град';

      case 'seaside':
        return 'Морска градина';

      case 'valley':
        return 'Долина';

      case 'fortress':
        return 'Крепост';

      case 'nature reserve':
        return 'Резерват';

      case 'monument':
      case 'memorial':
        return 'Паметник';

      case 'river gorge':
        return 'Ждрело';
    }

    if (category.isNotEmpty) {
      return category;
    }

    switch (poiType) {
      case 'nature':
        return 'Природа';
      case 'culture':
        return 'Култура';
      default:
        return 'Място';
    }
  }
}
