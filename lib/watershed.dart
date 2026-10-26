import 'dart:convert';
import 'package:flutter/services.dart';

// geist watershed, USGS HUC10 0512020108
class Watershed {
  late List<List<double>> _ring; // [lon, lat]!!

  Future<void> load() async {
    final json = jsonDecode(await rootBundle.loadString('assets/geist_watershed.geojson'));
    final geometry = json['features'][0]['geometry'];
    // outer ring
    final coords = geometry['type'] == 'MultiPolygon'
        ? geometry['coordinates'][0][0]
        : geometry['coordinates'][0];
    _ring = [for (final p in coords) [(p[0] as num).toDouble(), (p[1] as num).toDouble()]];
  }

  bool contains(double lat, double lng) {
    // bbox check
    if (lng < -85.993 || lng > -85.437 || lat < 39.863 || lat > 40.104) return false;

    // ray casting, odd = inside
    var inside = false;
    for (var i = 0, j = _ring.length - 1; i < _ring.length; j = i++) {
      final xi = _ring[i][0], yi = _ring[i][1];
      final xj = _ring[j][0], yj = _ring[j][1];
      final spansLat = (yi > lat) != (yj > lat);
      if (spansLat && lng < xi + (lat - yi) * (xj - xi) / (yj - yi)) {
        inside = !inside;
      }
    }
    return inside;
  }
}
