import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

// alerts for one saved spot, only stored on the phone
const alertRadiusMeters = 1609.0;
const alertWindow = Duration(hours: 48);

class Spot {
  final LatLng point;
  final String name;
  const Spot(this.point, this.name);
}

final savedSpot = ValueNotifier<Spot?>(null);

Future<void> loadSpot() async {
  final prefs = await SharedPreferences.getInstance();
  final lat = prefs.getDouble('spot_lat');
  final lng = prefs.getDouble('spot_lng');
  if (lat != null && lng != null) savedSpot.value = Spot(LatLng(lat, lng), prefs.getString('spot_name') ?? 'Your spot');
}

Future<void> saveSpot(Spot? spot) async {
  final prefs = await SharedPreferences.getInstance();
  if (spot == null) {
    await prefs.remove('spot_lat');
    await prefs.remove('spot_lng');
    await prefs.remove('spot_name');
  } else {
    await prefs.setDouble('spot_lat', spot.point.latitude);
    await prefs.setDouble('spot_lng', spot.point.longitude);
    await prefs.setString('spot_name', spot.name);
  }
  savedSpot.value = spot;
}

List<Map<String, dynamic>> bloomsNear(Spot spot, List<Map<String, dynamic>> reports) {
  final cutoff = DateTime.now().subtract(alertWindow);
  return reports.where((r) {
    if (r['label'] != 'bloom') return false;
    final time = (r['time'] as Timestamp?)?.toDate() ?? DateTime.now(); // server time still pending
    if (time.isBefore(cutoff)) return false;
    final meters = Geolocator.distanceBetween(
        spot.point.latitude, spot.point.longitude, (r['lat'] as num).toDouble(), (r['lng'] as num).toDouble());
    return meters <= alertRadiusMeters;
  }).toList();
}
