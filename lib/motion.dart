import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

// shared animations, built in flutter stuff only

class Reveal extends StatefulWidget {
  final Widget child;
  final int delay;
  const Reveal({super.key, required this.child, this.delay = 0});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: 420));
  late final _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween(begin: Offset(0, 0.08), end: Offset.zero).animate(_curve),
          child: widget.child,
        ),
      );
}

// shrink on press
class Pressable extends StatefulWidget {
  final Widget child;
  const Pressable({super.key, required this.child});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

class ConfidenceRing extends StatelessWidget {
  final double value;
  final Color color;
  final double size;
  const ConfidenceRing({super.key, required this.value, required this.color, this.size = 76});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(v, color, GG.raised),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${(v * 100).round()}%',
                    style: TextStyle(
                        fontSize: size * 0.26,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: GG.text,
                        fontFeatures: [FontFeature.tabularFigures()])),
                Text('sure', style: TextStyle(fontSize: 12, color: GG.muted, height: 1.2)),
              ]),
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color, track;
  _RingPainter(this.value, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawArc(rect, 0, 2 * pi, false, stroke..color = track);
    // start at top
    canvas.drawArc(rect, -pi / 2, 2 * pi * value, false, stroke..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

// corner brackets + scan line
class Viewfinder extends StatefulWidget {
  final bool scanning;
  final Color color;
  const Viewfinder({super.key, required this.scanning, required this.color});

  @override
  State<Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<Viewfinder> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _ViewfinderPainter(Curves.easeInOut.transform(_c.value), widget.scanning, widget.color),
            size: Size.infinite,
          ),
        ),
      );
}

class _ViewfinderPainter extends CustomPainter {
  final double t;
  final bool scanning;
  final Color color;
  _ViewfinderPainter(this.t, this.scanning, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final inset = scanning ? 16.0 : 16 + 4 * t;
    final arm = 24.0;
    final r = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    for (final (corner, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
          Path()
            ..moveTo(corner.dx, corner.dy + arm * dy)
            ..lineTo(corner.dx, corner.dy)
            ..lineTo(corner.dx + arm * dx, corner.dy),
          p);
    }
    if (scanning) {
      final y = r.top + r.height * t;
      canvas.drawRect(Rect.fromLTRB(r.left, r.top, r.right, y), Paint()..color = color.withValues(alpha: 0.10));
      canvas.drawLine(
          Offset(r.left, y),
          Offset(r.right, y),
          Paint()
            ..color = color
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => true;
}

// ripple for blooms
class PulseRing extends StatefulWidget {
  final Color color;
  final double size;
  const PulseRing({super.key, required this.color, this.size = 44});

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Transform.scale(
            scale: 0.4 + 0.6 * _c.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
              ),
            ),
          ),
        ),
      );
}

// waves, level is 0-1
class WaterWaves extends StatefulWidget {
  final double level;
  final Color color;
  const WaterWaves({super.key, required this.level, required this.color});

  @override
  State<WaterWaves> createState() => _WaterWavesState();
}

class _WaterWavesState extends State<WaterWaves> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.level),
          duration: Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, level, _) => AnimatedBuilder(
            animation: _c,
            builder: (context, _) =>
                CustomPaint(painter: _WavePainter(_c.value, level, widget.color), size: Size.infinite),
          ),
        ),
      );
}

class _WavePainter extends CustomPainter {
  final double t, level;
  final Color color;
  _WavePainter(this.t, this.level, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final (alpha, speed, height, shift) in [(0.10, 1.0, 6.0, 0.0), (0.16, -1.0, 5.0, 1.5)]) {
      final top = size.height * (1 - level);
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 4) {
        final y = top + height * sin(x / size.width * 2 * pi * 1.5 + t * 2 * pi * speed + shift);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}

// indexedstack with a fade, tabs built lazily
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const FadeIndexedStack({super.key, required this.index, required this.children});

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  late final _opened = <int>{widget.index};

  @override
  Widget build(BuildContext context) {
    _opened.add(widget.index);
    return Stack(children: [
      for (var i = 0; i < widget.children.length; i++)
        Positioned.fill(
          child: IgnorePointer(
            ignoring: i != widget.index,
            child: AnimatedOpacity(
              opacity: i == widget.index ? 1 : 0,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOut,
              // tickermode has to be inside the fade or the fade out freezes
              child: TickerMode(
                enabled: i == widget.index,
                child: _opened.contains(i) ? widget.children[i] : SizedBox(),
              ),
            ),
          ),
        ),
    ]);
  }
}

class NavItem {
  final IconData icon, selectedIcon;
  final String label;
  final int badge;
  const NavItem(this.icon, this.selectedIcon, this.label, {this.badge = 0});
}

class BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final List<NavItem> items;
  const BottomNav({super.key, required this.selected, required this.onSelect, required this.items});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: GG.surface,
          border: Border(top: BorderSide(color: darkMode.value ? GG.rule : GG.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(children: [
              for (var i = 0; i < items.length; i++) Expanded(child: _item(i)),
            ]),
          ),
        ),
      );

  Widget _item(int i) {
    final item = items[i];
    final on = i == selected;
    return Semantics(
      selected: on,
      button: true,
      label: item.badge > 0 ? '${item.label}, ${item.badge} alerts' : item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!on) HapticFeedback.selectionClick();
          onSelect(i);
        },
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: on ? 56 : 40,
            height: 30,
            decoration: BoxDecoration(
              color: on ? GG.accentSoft : GG.surface.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Center(
              child: Badge(
                isLabelVisible: item.badge > 0,
                label: Text('${item.badge}'),
                backgroundColor: GG.bloom,
                textColor: darkMode.value ? GG.ground : Colors.white,
                child: Icon(on ? item.selectedIcon : item.icon, size: 22, color: on ? GG.accent : GG.muted),
              ),
            ),
          ),
          SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 200),
            style: TextStyle(
                fontFamily: T.family,
                fontSize: 12,
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                color: on ? GG.text : GG.muted),
            child: Text(item.label),
          ),
        ]),
      ),
    );
  }
}

// card deck, swipe or arrows
class CardDeck extends StatefulWidget {
  final List<Widget> cards;
  const CardDeck({super.key, required this.cards});

  @override
  State<CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<CardDeck> {
  int _index = 0;
  int _dir = 1;

  void _go(int to) {
    if (to < 0 || to >= widget.cards.length || to == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _dir = to > _index ? 1 : -1;
      _index = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.cards.length;
    if (count == 0) return SizedBox.shrink();
    final index = _index.clamp(0, count - 1);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -200) _go(index + 1);
          if (v > 200) _go(index - 1);
        },
        child: AnimatedSize(
          duration: Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey(index);
                final from = Offset(incoming ? 0.35 * _dir : -0.35 * _dir, 0);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: Tween(begin: from, end: Offset.zero).animate(anim), child: child),
                );
              },
              child: KeyedSubtree(key: ValueKey(index), child: widget.cards[index]),
            ),
          ),
        ),
      ),
      if (count > 1) ...[
        SizedBox(height: 10),
        Row(children: [
          _arrow(Icons.chevron_left, 'Previous', index > 0 ? () => _go(index - 1) : null),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < count; i++)
                AnimatedContainer(
                  duration: Duration(milliseconds: 220),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: i == index ? GG.accent : GG.control, borderRadius: BorderRadius.circular(3)),
                ),
            ]),
          ),
          _arrow(Icons.chevron_right, 'Next', index < count - 1 ? () => _go(index + 1) : null),
        ]),
      ],
    ]);
  }

  Widget _arrow(IconData icon, String tooltip, VoidCallback? onPressed) => IconButton.outlined(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          foregroundColor: GG.text,
          disabledForegroundColor: GG.control,
          side: BorderSide(color: onPressed == null ? GG.rule : GG.control),
          fixedSize: Size(44, 44),
        ),
        icon: Icon(icon, size: 24),
      );
}

// segmented control
class SlidingSegments extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  const SlidingSegments({super.key, required this.labels, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(color: GG.raised, borderRadius: GG.corner),
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth / labels.length;
          return Stack(children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: w * selected,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(
                  color: darkMode.value ? GG.control : GG.surface,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: darkMode.value
                      ? null
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3, offset: Offset(0, 1))],
                ),
              ),
            ),
            Row(children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != selected) HapticFeedback.selectionClick();
                        onSelect(i);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: TextStyle(
                              fontFamily: T.family,
                              fontSize: 14,
                              fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                              color: i == selected ? GG.text : GG.muted),
                          child: Text(labels[i]),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ]);
        }),
      );
}

// intro, tap to skip
class IntroSplash extends StatefulWidget {
  const IntroSplash({super.key});

  @override
  State<IntroSplash> createState() => _IntroSplashState();
}

class _IntroSplashState extends State<IntroSplash> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: 1900))..forward();
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _gone = true),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // logo 0-35%, name 20-50%, fade out after 78%
          final grow = Curves.easeOutCubic.transform((_c.value / 0.35).clamp(0, 1));
          final words = Curves.easeOutCubic.transform(((_c.value - 0.2) / 0.3).clamp(0, 1));
          final fade = 1 - Curves.easeIn.transform(((_c.value - 0.78) / 0.22).clamp(0, 1));
          return Opacity(
            opacity: fade,
            child: Container(
              color: GG.ground,
              padding: EdgeInsets.symmetric(horizontal: 32),
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Opacity(
                  opacity: grow,
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * grow,
                    child: Image.asset(GG.logo, width: 104, height: 104),
                  ),
                ),
                SizedBox(height: 24),
                Opacity(
                  opacity: words,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - words)),
                    child: Column(children: [
                      Text('GeistGuard',
                          style: TextStyle(
                              fontFamily: T.family,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              color: GG.text,
                              decoration: TextDecoration.none)),
                      SizedBox(height: 8),
                      Text('Spot blooms. Protect the lake.',
                          style: TextStyle(
                              fontFamily: T.family,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: GG.muted,
                              decoration: TextDecoration.none)),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
