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
  final int    points;

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

  factory Poi.fromJson(Map<String, dynamic> json) => Poi(
    id:            json['id']            as String,
    name:          json['name']          as String,
    type:          json['type']          as String,
    categoryLabel: json['categoryLabel'] as String,
    lat:           (json['lat']          as num).toDouble(),
    lng:           (json['lng']          as num).toDouble(),
    imageUrl:      json['imageUrl']      as String? ?? '',
    description:   json['description']  as String,
    tips:          json['tips']          as String,
    points:        (json['points']       as num).toInt(),
  );
}