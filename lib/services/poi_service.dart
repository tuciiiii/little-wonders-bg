import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/poi.dart';

class PoiService {
  PoiService._();
  static List<Poi>? _cache;

  static Future<List<Poi>> loadPois() async {
    if (_cache != null) return _cache!;
    try {
      final json = await rootBundle.loadString('assets/pois.json');
      final list = jsonDecode(json) as List<dynamic>;
      _cache =
          list.map((e) => Poi.fromJson(e as Map<String, dynamic>)).toList();
      return _cache!;
    } catch (e) {
      return [];
    }
  }

  static void invalidateCache() => _cache = null;
}
