import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'address_field.dart';
import 'geocode.dart';
import 'motion.dart';
import 'theme.dart';
import 'upstream.dart';
import 'watershed.dart';

class UpstreamScreen extends StatefulWidget {
  const UpstreamScreen({super.key});

  @override
  State<UpstreamScreen> createState() => _UpstreamScreenState();
}

class _UpstreamScreenState extends State<UpstreamScreen> {
  bool? _inWatershed;
  Forecast? _forecast;
  List<Advice> _advice = [];
  String? _error;
  String? _place;
  bool _loading = true;
  Watershed? _watershed;
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    _useMyLocation();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    _address.clear();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission is needed to check your watershed. You can type an address instead.';
          _loading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      await _checkAt(pos.latitude, pos.longitude, null);
    } catch (e) {
      setState(() {
        _error = 'Could not check your location: $e';
        _loading = false;
      });
    }
  }

  // suggestion already has coords
  Future<void> _checkPicked(LatLng point, String name) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _checkAt(point.latitude, point.longitude, name);
    } catch (e) {
      setState(() {
        _error = 'Could not check that address: $e';
        _loading = false;
      });
    }
  }

  Future<void> _searchAddress() async {
    final text = _address.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final match = await geocodeAddress(text);
      if (match == null) {
        setState(() {
          _error = 'Could not find that address. Try adding the city and state.';
          _loading = false;
        });
        return;
      }
      await _checkAt(match.$1.latitude, match.$1.longitude, match.$2);
    } catch (e) {
      setState(() {
        _error = 'Could not look up that address: $e';
        _loading = false;
      });
    }
  }

  Future<void> _checkAt(double lat, double lng, String? place) async {
    if (_watershed == null) {
      final watershed = Watershed();
      await watershed.load();
      _watershed = watershed;
    }
    final inside = _watershed!.contains(lat, lng);
    final forecast = await fetchForecast(lat, lng);
    if (!mounted) return;
    setState(() {
      _inWatershed = inside;
      _forecast = forecast;
      _advice = adviceFor(forecast, DateTime.now());
      _place = place;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> content;
    if (_error != null) {
      content = [
        Panel(
          child: Text(_error!, style: T.body),
        ),
      ];
    } else if (_loading || _inWatershed == null) {
      // skeleton
      content = [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LoadingBar(width: 110, height: 22),
            SizedBox(height: 14),
            LoadingBar(width: 240, height: 22),
            SizedBox(height: 14),
            LoadingBar(),
            SizedBox(height: 8),
            LoadingBar(width: 200),
            SizedBox(height: 18),
            Text('Checking the watershed and forecast…', style: T.small),
          ]),
        ),
        SizedBox(height: 12),
        Panel(child: Row(children: [Expanded(child: LoadingBar(height: 48)), SizedBox(width: 20), Expanded(child: LoadingBar(height: 48))])),
      ];
    } else {
      final inside = _inWatershed!;
      content = [
        ClipRRect(
          borderRadius: GG.corner,
          child: Stack(children: [
            Positioned.fill(child: Panel(child: SizedBox())),
            Positioned.fill(child: WaterWaves(level: inside ? 0.42 : 0.16, color: GG.accent)),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                StatusPill(inside ? 'Drains to Geist' : 'Outside the watershed',
                    fill: inside ? GG.accentSoft : GG.raised, ink: inside ? GG.accentInk : GG.muted),
                SizedBox(height: 12),
                Text(
                    _place == null
                        ? (inside ? 'You\'re in the Geist watershed' : 'You\'re outside the Geist watershed')
                        : (inside ? 'This address is in the Geist watershed' : 'This address is outside the Geist watershed'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3, color: GG.text)),
                SizedBox(height: 8),
                Text(
                  inside
                      ? 'Rain that falls here drains to Geist Reservoir, so what happens in this yard reaches the lake.'
                      : 'Rain here doesn\'t drain to Geist, but these tips still protect your local streams.',
                  style: T.body,
                ),
              ]),
            ),
          ]),
        ),
        SizedBox(height: 12),
        Panel(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // rain label is longer
              Expanded(flex: 3, child: _stat('Rain chance, next 48 h', _forecast?.maxRainChance, '%')),
              VerticalDivider(width: 1, color: GG.rule),
              Expanded(flex: 2, child: _stat('Low temperature', _forecast?.minTempF, '°F')),
            ]),
          ),
        ),
        if (_forecast == null) ...[
          SizedBox(height: 8),
          Text('Forecast unavailable right now, so weather-based tips are skipped.', style: T.small),
        ],
        SectionTitle('What you can do this week'),
        CardDeck(cards: [
          for (final advice in _advice)
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(advice.message, style: T.body.copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(height: 10),
                Text('Source: ${advice.source}', style: T.meta),
              ]),
            ),
        ]),
        SizedBox(height: 16),
        Text('Boundary: USGS Watershed Boundary Dataset · Forecast: National Weather Service · Addresses: Photon (OpenStreetMap), US Census Bureau',
            style: T.meta),
      ];
    }

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          ScreenHeader(title: 'Upstream', subtitle: 'Does your yard drain to Geist?'),
          SizedBox(height: 20),
          AddressField(
            controller: _address,
            onSubmitted: (_) => _searchAddress(),
            onPicked: _checkPicked,
            style: TextStyle(fontSize: 16, color: GG.text),
            decoration: InputDecoration(hintText: 'Check any address'),
          ),
          SizedBox(height: 4),
          Row(children: [
            Expanded(child: Text(_place == null ? 'Showing: your location' : 'Showing: $_place', style: T.small)),
            TextButton(onPressed: _loading ? null : _useMyLocation, child: Text('Use my location')),
          ]),
          SizedBox(height: 12),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 260),
            child: Column(
              key: ValueKey('${_loading}_${_error}_$_place'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int? value, String suffix) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, maxLines: 1, softWrap: false, style: T.small),
          ),
          SizedBox(height: 6),
          value == null
              ? Text('—', style: TextStyle(fontSize: 18, color: GG.faint))
              : Text('$value$suffix', style: T.figure),
        ]),
      );
}
