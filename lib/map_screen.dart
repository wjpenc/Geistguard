import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'motion.dart';
import 'reports.dart';
import 'theme.dart';

// 7 day pins or 6 month hotspots
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _mode = 'all';
  Map<String, dynamic>? _selected;
  Stream<List<Map<String, dynamic>>> _reports = reportsSince(Duration(days: 7));

  // hotspots need 6 months
  void _setMode(String mode) => setState(() {
        if ((mode == 'hotspots') != (_mode == 'hotspots')) {
          _reports = reportsSince(Duration(days: mode == 'hotspots' ? 180 : 7));
        }
        _mode = mode;
        _selected = null;
      });

  static const _modes = ['all', 'blooms', 'hotspots'];

  String _subtitle(AsyncSnapshot snapshot, int count) {
    if (snapshot.hasError) return 'Reports could not load';
    if (!snapshot.hasData) return 'Loading reports…';
    final what = _mode == 'all' ? (count == 1 ? 'report' : 'reports') : (count == 1 ? 'bloom report' : 'bloom reports');
    return '$count $what in the last ${_mode == 'hotspots' ? '6 months' : '7 days'}';
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _reports,
        builder: (context, snapshot) {
          final reports =
              (snapshot.data ?? []).where((r) => _mode == 'all' || r['label'] == 'bloom').toList();
          return Stack(children: [
            Positioned.fill(child: _map(reports)),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _float(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      ScreenHeader(
                        title: 'Community reports',
                        subtitle: _subtitle(snapshot, reports.length),
                        trailing: snapshot.hasData || snapshot.hasError
                            ? null
                            : SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      SizedBox(height: 14),
                      SlidingSegments(
                        labels: ['All', 'Blooms only', 'Hotspots'],
                        selected: _modes.indexOf(_mode),
                        onSelect: (i) => _setMode(_modes[i]),
                      ),
                    ]),
                  ),
                  SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: _legend()),
                  if (snapshot.hasError) ...[
                    SizedBox(height: 8),
                    _float(
                      child: Text('Could not load reports: ${snapshot.error}', style: T.small),
                    ),
                  ],
                  Spacer(),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                          position: Tween(begin: Offset(0, 0.25), end: Offset.zero).animate(anim), child: child),
                    ),
                    child: _selected == null
                        ? SizedBox(key: ValueKey('none'), width: double.infinity)
                        : KeyedSubtree(key: ObjectKey(_selected), child: _selectedCard(_selected!)),
                  ),
                ]),
              ),
            ),
          ]);
        },
      );

  Widget _map(List<Map<String, dynamic>> reports) => FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(39.935, -85.95),
          initialZoom: 12,
          onTap: (_, _) => setState(() => _selected = null),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.geistguard.app',
            // dark tiles
            tileBuilder: darkMode.value ? darkModeTileBuilder : null,
          ),
          // overlap = darker hotspot
          if (_mode == 'hotspots')
            CircleLayer(circles: [
              for (final r in reports)
                CircleMarker(
                  point: LatLng((r['lat'] as num).toDouble(), (r['lng'] as num).toDouble()),
                  radius: 250,
                  useRadiusInMeter: true,
                  color: GG.bloom.withValues(alpha: 0.25),
                ),
            ]),
          if (_mode != 'hotspots')
            MarkerLayer(markers: [
              for (final r in reports)
                Marker(
                  point: LatLng((r['lat'] as num).toDouble(), (r['lng'] as num).toDouble()),
                  width: 56,
                  height: 56,
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = r),
                    child: _pin(r['label'] as String, identical(r, _selected)),
                  ),
                ),
            ]),
          RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      );

  Widget _pin(String label, bool selected) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, pop, child) => Transform.scale(scale: pop, child: child),
        child: Stack(alignment: Alignment.center, children: [
          if (label == 'bloom') PulseRing(color: GG.bloom, size: 56),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: selected ? 26 : 18,
            height: selected ? 26 : 18,
            decoration: BoxDecoration(
              color: labelColor(label),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: Offset(0, 1))],
            ),
          ),
        ]),
      );

  Widget _float({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: GG.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: darkMode.value ? 0.4 : 0.10), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: child,
      );

  Widget _legendRow(Color color, String text) => Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Dot(color),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: GG.text)),
        ]),
      );

  Widget _legend() => _float(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AnimatedSize(
          duration: Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: _mode == 'hotspots'
              ? _legendRow(GG.bloom.withValues(alpha: 0.6), 'Bloom reports, darker where they repeat')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final label in _mode == 'blooms' ? ['bloom'] : ['bloom', 'look_alike', 'clear_water'])
                      _legendRow(labelColor(label), resultText[label]!),
                  ],
                ),
        ),
      );

  Widget _selectedCard(Map<String, dynamic> r) {
    final label = r['label'] as String;
    final confidence = ((r['confidence'] as num) * 100).round();
    final (fill, ink) = labelPill(label);
    return _float(
      padding: EdgeInsets.fromLTRB(16, 8, 6, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(child: StatusPill(resultText[label] ?? label, fill: fill, ink: ink, leading: Dot(labelColor(label), size: 8))),
            SizedBox(width: 10),
            Text(_timeAgo(r['time'] as Timestamp?), style: T.small),
            Spacer(),
            IconButton(
              tooltip: 'Close',
              onPressed: () => setState(() => _selected = null),
              icon: Icon(Icons.close, size: 20, color: GG.muted),
            ),
          ]),
          SizedBox(height: 2),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: '$confidence%',
                  style: TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
              TextSpan(text: ' sure · visual estimate only'),
            ]),
            style: TextStyle(fontSize: 15, color: GG.text),
          ),
          if (r['thumb'] != null) ...[
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: GG.corner,
                child: Image.memory(base64Decode(r['thumb'] as String),
                    height: 140, width: double.infinity, fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(Timestamp? t) {
    if (t == null) return 'just now';
    final d = DateTime.now().difference(t.toDate());
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return d.inDays == 1 ? 'yesterday' : '${d.inDays} days ago';
  }
}
