import 'dart:convert';
import 'package:http/http.dart' as http;

// runoff advice from the NWS forecast

class Advice {
  final String message;
  final String source;
  const Advice(this.message, this.source);
}

class Forecast {
  final int maxRainChance;
  final int minTempF;
  const Forecast(this.maxRainChance, this.minTempF);
}

// NWS wants a user agent with contact info
const _headers = {'User-Agent': 'GeistGuard student app (will.pence@outlook.com)'};

// null if offline
Future<Forecast?> fetchForecast(double lat, double lng) async {
  try {
    final points = await http.get(
        Uri.parse('https://api.weather.gov/points/${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}'),
        headers: _headers);
    if (points.statusCode != 200) return null;
    final hourlyUrl = jsonDecode(points.body)['properties']['forecastHourly'] as String;

    final hourly = await http.get(Uri.parse(hourlyUrl), headers: _headers);
    if (hourly.statusCode != 200) return null;
    final periods = (jsonDecode(hourly.body)['properties']['periods'] as List).take(48);

    var maxRain = 0;
    var minTemp = 999;
    for (final p in periods) {
      final rain = (p['probabilityOfPrecipitation']?['value'] as num?)?.toInt() ?? 0;
      final temp = (p['temperature'] as num).toInt();
      if (rain > maxRain) maxRain = rain;
      if (temp < minTemp) minTemp = temp;
    }
    return Forecast(maxRain, minTemp);
  } catch (_) {
    return null;
  }
}

// Avoid fertilizer if moderate to heavy rain is expected soon.
const rainThreshold = 50;

List<Advice> adviceFor(Forecast? f, DateTime now) {
  final advice = <Advice>[];
  if (f != null && f.maxRainChance >= rainThreshold) {
    advice.add(Advice(
        'Rain is likely in the next 48 hours (${f.maxRainChance}% chance). '
        'Hold off on fertilizing so it doesn\'t wash into storm drains and the reservoir.',
        'Iowa State Extension; Purdue Turfgrass Science'));
  }
  if (f != null && f.minTempF <= 32) {
    advice.add(const Advice(
        'Freezing temperatures are coming and lawns are going dormant. Don\'t fertilize dormant grass; it can\'t use it.',
        'Purdue Turfgrass Science'));
  }
  if (now.month >= 9 && now.month <= 11) {
    advice.add(const Advice(
        'Keep fallen leaves out of the street and storm drains. Mulch or compost them instead. '
        'Leaves that reach the water release phosphorus that feeds algae.',
        'Town of Fortville Stormwater; WFYI / White River Alliance'));
  }
  advice.add(const Advice(
      'If you fertilize, use a phosphorus-free fertilizer (the middle number on the bag is 0), and sweep any off driveways and sidewalks.',
      'Town of Fortville Stormwater; Purdue Turfgrass Science'));
  advice.add(const Advice(
      'Pick up pet waste. Rain carries it into storm drains, which flow untreated to streams.',
      'Hamilton County Health Department'));
  return advice;
}