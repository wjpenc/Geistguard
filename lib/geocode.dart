import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// census geocoder, free no key
Future<(LatLng, String)?> geocodeAddress(String address) async {
  final url = Uri.https('geocoding.geo.census.gov', '/geocoder/locations/onelineaddress', {
    'address': address,
    'benchmark': 'Public_AR_Current',
    'format': 'json',
  });
  final response = await http.get(url).timeout(Duration(seconds: 15));
  if (response.statusCode != 200) throw 'address lookup failed (${response.statusCode})';
  final matches = jsonDecode(response.body)['result']['addressMatches'] as List;
  if (matches.isEmpty) return null;
  final match = matches.first;
  final coords = match['coordinates'];
  return (LatLng((coords['y'] as num).toDouble(), (coords['x'] as num).toDouble()), match['matchedAddress'] as String);
}

// photon suggestions, biased toward geist
Future<List<(LatLng, String)>> suggestAddresses(String text) async {
  final url = Uri.https('photon.komoot.io', '/api/', {
    'q': text,
    'limit': '8',
    'lat': '39.935',
    'lon': '-85.95',
    'lang': 'en',
  });
  final response = await http.get(url, headers: {'User-Agent': 'GeistGuard student app'}).timeout(Duration(seconds: 8));
  if (response.statusCode != 200) return [];
  final features = jsonDecode(response.body)['features'] as List;
  final results = <(LatLng, String)>[];
  for (final f in features) {
    final p = f['properties'] as Map<String, dynamic>;
    if (p['countrycode'] != 'US') continue;
    final coords = f['geometry']['coordinates'] as List;
    final label = _label(p);
    if (results.any((r) => r.$2 == label)) continue;
    results.add((LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()), label));
    if (results.length == 5) break;
  }
  return results;
}

String _label(Map<String, dynamic> p) {
  final street = [p['housenumber'], p['street']].whereType<String>().join(' ');
  final parts = <String>[];
  for (final part in [p['name'], street, p['city'] ?? p['county'], p['state']]) {
    if (part is String && part.isNotEmpty && !parts.contains(part)) parts.add(part);
  }
  return parts.join(', ');
}
