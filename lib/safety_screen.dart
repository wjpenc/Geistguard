import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'about_screen.dart';
import 'address_field.dart';
import 'alerts.dart';
import 'geocode.dart';
import 'motion.dart';
import 'reports.dart';
import 'theme.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weekAgo = Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7)));
    final blooms = FirebaseFirestore.instance
        .collection('reports')
        .where('time', isGreaterThan: weekAgo)
        .snapshots()
        .map((s) => s.docs.where((d) => d.data()['label'] == 'bloom').length);

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          ScreenHeader(title: 'Stay safe', subtitle: 'Bloom alerts for your spot, and who is at risk'),
          SizedBox(height: 20),
          SpotAlertCard(),
          SizedBox(height: 12),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              StreamBuilder<int>(
                stream: blooms,
                builder: (context, snap) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  // only color it if > 0
                  snap.hasData
                      ? Text('${snap.data}', style: T.figure.copyWith(color: snap.data! > 0 ? GG.bloom : GG.text))
                      : LoadingBar(width: 28, height: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                        snap.hasData
                            ? 'possible ${snap.data == 1 ? 'bloom' : 'blooms'} reported on Geist this week'
                            : 'Checking this week\'s reports…',
                        style: T.cardTitle),
                  ),
                ]),
              ),
              SizedBox(height: 12),
              Text(
                'Blooms are patchy and move with the wind. Official sampling happens at a few spots, '
                'but people on the lake every day see changes first. A shared map helps everyone choose where to go today.',
                style: T.body,
              ),
            ]),
          ),
          SectionTitle('Who is at risk'),
          CardDeck(cards: [
            _group('Dog owners',
                'Dogs are most at risk. They can get very sick and die within hours of drinking or going in water with a harmful algal bloom.',
                ['Keep dogs out of the water near red pins.', 'If your dog goes in scummy or discolored water, rinse it off with tap water right away.'],
                'CDC'),
            _group('Swimmers and families',
                'Don\'t go into water with a harmful bloom. When in doubt, stay out.',
                ['Check the map before you swim, and pick a spot without recent bloom reports.', 'Keep kids out of water that looks discolored or has scum.'],
                'CDC'),
            _group('Boaters, paddlers and anglers',
                'Before swimming, boating, or fishing, learn how to spot harmful algae.',
                ['Check the map before you launch.', 'Add a report when you see a bloom from the water, so others can avoid it.'],
                'CDC'),
            _group('Everyone who drinks Geist water',
                'Geist Reservoir has supplied Indianapolis with water since 1943, and it is owned by Citizens Energy Group.',
                ['Over weeks, the pins show where blooms keep coming back. That points to which coves and creeks need attention upstream.'],
                'Encyclopedia of Indianapolis'),
          ]),
          SizedBox(height: 20),
          SecondaryButton(onPressed: openAdvisories, label: 'Indiana algae advisories (IDEM) ↗'),
          SizedBox(height: 14),
          Text('GeistGuard reports are visual estimates, not water tests. They never mean the water is safe.',
              style: T.meta),
        ],
      ),
    );
  }

  Widget _group(String title, String fact, List<String> tips, String source) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: T.cardTitle.copyWith(fontSize: 17)),
          SizedBox(height: 8),
          Text(fact, style: T.body),
          SizedBox(height: 10),
          for (final tip in tips) BulletLine(tip, style: T.body.copyWith(fontWeight: FontWeight.w500)),
          SizedBox(height: 2),
          Text('Source: $source', style: T.meta),
        ]),
      );
}

class SpotAlertCard extends StatefulWidget {
  const SpotAlertCard({super.key});

  @override
  State<SpotAlertCard> createState() => _SpotAlertCardState();
}

class _SpotAlertCardState extends State<SpotAlertCard> {
  final _recent = reportsSince(alertWindow);
  final _typed = TextEditingController();
  bool _busy = false;
  bool _typing = false;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _busy = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'location permission was denied';
      }
      final pos = await Geolocator.getCurrentPosition();
      await saveSpot(Spot(LatLng(pos.latitude, pos.longitude), 'your saved spot'));
    } catch (e) {
      _show('Could not save your spot: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _openAddress() => setState(() {
        _typed.clear();
        _typing = true;
      });

  // suggestion already has coords
  Future<void> _savePicked(LatLng point, String name) async {
    setState(() => _typing = false);
    await saveSpot(Spot(point, name));
  }

  // nothing picked, use census
  Future<void> _saveTyped(String text) async {
    if (text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _typing = false;
      _busy = true;
    });
    try {
      final match = await geocodeAddress(text.trim());
      if (match == null) {
        _show('Could not find that address. Try adding the city and state.');
      } else {
        await saveSpot(Spot(match.$1, match.$2));
      }
    } catch (e) {
      _show('Could not look up that address: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Spot?>(
        valueListenable: savedSpot,
        builder: (context, spot, _) => StreamBuilder<List<Map<String, dynamic>>>(
          stream: _recent,
          builder: (context, snap) {
            final near = spot == null ? <Map<String, dynamic>>[] : bloomsNear(spot, snap.data ?? []);
            final alert = near.isNotEmpty;
            final String title;
            final String detail;
            if (spot == null) {
              title = 'Get bloom alerts for your spot';
              detail = 'Save a dock, beach or home. GeistGuard will show here when a possible bloom '
                  'is reported within 1 mile of it in the last 48 hours.';
            } else if (!snap.hasData) {
              title = 'Checking reports near ${spot.name}…';
              detail = '';
            } else if (alert) {
              title = '${near.length} possible ${near.length == 1 ? 'bloom' : 'blooms'} reported within 1 mile of ${spot.name}';
              detail = 'In the last 48 hours. Check the Map tab, and keep people and pets out of discolored water.';
            } else {
              title = 'No bloom reports within 1 mile of ${spot.name} in the last 48 hours';
              detail = 'That is not a water test. Blooms can be missed, so still check official advisories.';
            }
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: alert ? GG.bloomSoft : GG.surface,
                borderRadius: GG.corner,
                border: alert || darkMode.value ? null : Border.all(color: GG.border),
              ),
              padding: EdgeInsets.all(20),
              child: AnimatedSize(
                duration: Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(alignment: Alignment.center, children: [
                        if (alert) PulseRing(color: GG.bloom, size: 28),
                        Dot(alert ? GG.bloom : (spot == null ? GG.control : GG.positive), size: 10),
                      ]),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(title, style: T.cardTitle.copyWith(color: alert ? GG.bloomInk : GG.text)),
                    ),
                  ]),
                  if (detail.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Padding(
                      padding: EdgeInsets.only(left: 36),
                      child: Text(detail, style: T.body),
                    ),
                  ],
                  SizedBox(height: 16),
                  if (_busy)
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(borderRadius: BorderRadius.circular(99)))
                  else if (_typing)
                    _addressForm()
                  else if (spot == null)
                    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      PrimaryButton(onPressed: _useMyLocation, label: 'Use my location', height: 48),
                      SizedBox(height: 8),
                      SecondaryButton(onPressed: _openAddress, label: 'Type an address', height: 48),
                    ])
                  else
                    Wrap(spacing: 4, children: [
                      TextButton(onPressed: _useMyLocation, child: Text('Use my location')),
                      TextButton(onPressed: _openAddress, child: Text('Change address')),
                      TextButton(
                        onPressed: () => saveSpot(null),
                        style: TextButton.styleFrom(foregroundColor: GG.muted),
                        child: Text('Remove'),
                      ),
                    ]),
                ]),
              ),
            );
          },
        ),
      );

  Widget _addressForm() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Address of your spot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: GG.text)),
        SizedBox(height: 8),
        AddressField(
          controller: _typed,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Start typing an address',
          ),
          onPicked: _savePicked,
          onSubmitted: _saveTyped,
        ),
        SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed: () => setState(() => _typing = false),
            style: TextButton.styleFrom(foregroundColor: GG.muted),
            child: Text('Cancel'),
          ),
          TextButton(onPressed: () => _saveTyped(_typed.text), child: Text('Save')),
        ]),
      ]);
}
