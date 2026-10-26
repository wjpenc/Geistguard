import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'about_screen.dart';
import 'alerts.dart';
import 'classifier.dart';
import 'firebase_options.dart';
import 'map_screen.dart';
import 'motion.dart';
import 'reports.dart';
import 'safety_screen.dart';
import 'theme.dart';
import 'upstream_screen.dart';

final classifier = BloomClassifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.signInAnonymously();
  await classifier.load();
  await loadSpot();
  runApp(GeistGuardApp());
}

class GeistGuardApp extends StatelessWidget {
  const GeistGuardApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: darkMode,
        builder: (context, dark, _) => MaterialApp(
          title: 'GeistGuard',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: HomeShell(),
        ),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _recent = reportsSince(alertWindow);

  // redraw on theme or spot change
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([darkMode, savedSpot]),
        builder: (context, _) => Stack(children: [
          Scaffold(
            backgroundColor: GG.ground,
            body: FadeIndexedStack(
              index: _tab,
              children: [CheckScreen(), MapScreen(), UpstreamScreen(), SafetyScreen()],
            ),
            bottomNavigationBar: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _recent,
              builder: (context, snap) {
                final spot = savedSpot.value;
                final alerts = spot == null ? 0 : bloomsNear(spot, snap.data ?? []).length;
                return BottomNav(
                  selected: _tab,
                  onSelect: (i) => setState(() => _tab = i),
                  items: [
                    NavItem(Icons.photo_camera_outlined, Icons.photo_camera, 'Check'),
                    NavItem(Icons.map_outlined, Icons.map, 'Map'),
                    NavItem(Icons.water_drop_outlined, Icons.water_drop, 'Upstream'),
                    NavItem(Icons.health_and_safety_outlined, Icons.health_and_safety, 'Stay safe', badge: alerts),
                  ],
                );
              },
            ),
          ),
          IntroSplash(),
        ]),
      );
}

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  File? _photo;
  String? _label;
  double _confidence = 0;
  bool _saved = false;
  bool _busy = false;
  bool _fromLibrary = false;

  Future<void> _takePhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024);
    if (picked == null) return;
    final photo = File(picked.path);
    setState(() {
      _photo = photo;
      _label = null;
      _saved = false;
      _busy = true;
      _fromLibrary = source == ImageSource.gallery;
    });

    // let the scan animation play
    await Future.delayed(Duration(milliseconds: 900));
    final (label, confidence) = classifier.classify(photo);
    setState(() {
      _label = label;
      _confidence = confidence;
      _busy = false;
    });

    // only camera photos of water get pinned
    if (label == 'not_water' || label == 'unsure' || _fromLibrary) return;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'location permission was denied';
      }
      final pos = await Geolocator.getCurrentPosition();
      await FirebaseFirestore.instance.collection('reports').add({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'label': label,
        'confidence': confidence,
        'thumb': makeThumbnail(photo),
        'time': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Bloom check',
                subtitle: 'Snap the water to check it',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen())),
                    tooltip: 'About & credits',
                    style: IconButton.styleFrom(foregroundColor: GG.text, fixedSize: Size(44, 44)),
                    icon: Icon(Icons.info_outline, size: 22),
                  ),
                  ThemeToggle(),
                ]),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ListView(
                    padding: EdgeInsets.only(bottom: 8),
                    children: [
                      _viewfinder(),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 360),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                              position: Tween(begin: Offset(0, 0.08), end: Offset.zero).animate(anim), child: child),
                        ),
                        child: _label == null
                            ? SizedBox(key: ValueKey('none'), width: double.infinity)
                            : Padding(
                                key: ValueKey(_photo!.path),
                                padding: EdgeInsets.only(top: 12),
                                child: _resultCard(),
                              ),
                      ),
                      if (_photo == null) Padding(padding: EdgeInsets.only(top: 12), child: _tips()),
                      if (_label != null && _fromLibrary)
                        Reveal(
                          delay: 200,
                          child: _note('Library photo: checked only, not added to the map', GG.muted),
                        ),
                      if (_saved)
                        Reveal(
                            child: _note('Added to the community map with a small preview', GG.positive)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Row(children: [
                  Expanded(
                    child: PrimaryButton(
                      onPressed: _busy ? null : () => _takePhoto(ImageSource.camera),
                      icon: Icons.photo_camera_outlined,
                      label: _photo == null ? 'Take a photo' : 'Take another photo',
                    ),
                  ),
                  SizedBox(width: 10),
                  RoundIconButton(
                    onPressed: _busy ? null : () => _takePhoto(ImageSource.gallery),
                    icon: Icons.photo_library_outlined,
                    tooltip: 'Check a photo from your library',
                  ),
                ]),
              ),
            ],
          ),
        ),
      );

  Widget _viewfinder() => ClipRRect(
        borderRadius: GG.corner,
        child: AspectRatio(
          aspectRatio: 1.05,
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: GG.raised),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              child: _photo == null
                  ? Padding(
                      key: ValueKey('empty'),
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Point at the water', style: T.section),
                          SizedBox(height: 4),
                          Text('Fill most of the photo with the water\'s surface',
                              textAlign: TextAlign.center, style: T.small),
                        ],
                      ),
                    )
                  : Image.file(_photo!, key: ValueKey(_photo!.path), fit: BoxFit.cover),
            ),
            Viewfinder(scanning: _busy, color: _photo == null ? GG.faint : Colors.white),
            if (_busy)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(99)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                          width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 10),
                      Text('AI is checking the water…',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      );

  Widget _tips() => Padding(
        padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('For a good check', style: T.cardTitle),
          SizedBox(height: 12),
          _tip('Shoot in daylight, with the water filling most of the frame.'),
          _tip('Camera photos go on the community map for 7 days, with a small preview.'),
          _tip('Library photos are checked only, never added to the map.'),
        ]),
      );

  Widget _tip(String text) => BulletLine(text);

  Widget _note(String text, Color color) => Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(text, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      );

  Widget _resultCard() {
    final color = labelColor(_label!);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ConfidenceRing(value: _confidence, color: color),
            SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI result', style: T.meta),
                SizedBox(height: 2),
                Text(resultText[_label]!,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: GG.text, height: 1.2, letterSpacing: -0.3)),
              ]),
            ),
          ]),
          SizedBox(height: 14),
          Text(adviceText[_label]!, style: T.body),
          if (_label != 'not_water' && _label != 'unsure') ...[
            SizedBox(height: 4),
            LinkOut('See official advisories (IDEM)', onPressed: openAdvisories),
          ],
        ],
      ),
    );
  }
}
