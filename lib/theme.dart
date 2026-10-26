import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion.dart';

// colors, text styles, shared widgets

// light by default, easier to see outside
final darkMode = ValueNotifier<bool>(false);

class Palette {
  final Color ground, surface, raised, border, rule, control, text, muted, faint;
  final Color accent, accentSoft, accentInk, primary, onPrimary;
  final Color bloom, bloomSoft, bloomInk, lookAlike, lookAlikeSoft, lookAlikeInk, clearSoft, clearInk;
  final Color positive, positiveSoft, positiveInk, warning;
  const Palette({
    required this.ground, required this.surface, required this.raised, required this.border, required this.rule,
    required this.control, required this.text, required this.muted, required this.faint, required this.accent,
    required this.accentSoft, required this.accentInk, required this.primary, required this.onPrimary,
    required this.bloom, required this.bloomSoft, required this.bloomInk, required this.lookAlike,
    required this.lookAlikeSoft, required this.lookAlikeInk, required this.clearSoft, required this.clearInk,
    required this.positive, required this.positiveSoft, required this.positiveInk, required this.warning,
  });
}

const _light = Palette(
  ground: Color(0xFFF6F8FA), surface: Color(0xFFFFFFFF), raised: Color(0xFFEDF1F5), border: Color(0xFFE2E7ED),
  rule: Color(0xFFEDF0F3), control: Color(0xFFCCD4DD), text: Color(0xFF111827), muted: Color(0xFF5B6472),
  faint: Color(0xFF6B7280),
  accent: Color(0xFF1F5FA8), accentSoft: Color(0xFFEDF3FB), accentInk: Color(0xFF133B69),
  primary: Color(0xFF1F5FA8), onPrimary: Color(0xFFFFFFFF),
  bloom: Color(0xFFC2410C), bloomSoft: Color(0xFFFFEDE3), bloomInk: Color(0xFF7C2D12),
  lookAlike: Color(0xFF8A6A1F), lookAlikeSoft: Color(0xFFFBF3DE), lookAlikeInk: Color(0xFF5C4512),
  clearSoft: Color(0xFFEDF3FB), clearInk: Color(0xFF133B69),
  positive: Color(0xFF247B50), positiveSoft: Color(0xFFDCFCE7), positiveInk: Color(0xFF14532D),
  warning: Color(0xFF92400E),
);

// dark: primary button inverted
const _dark = Palette(
  ground: Color(0xFF0C0D0F), surface: Color(0xFF16181B), raised: Color(0xFF23262A), border: Color(0xFF16181B),
  rule: Color(0xFF24272B), control: Color(0xFF454A50), text: Color(0xFFFFFFFF), muted: Color(0xFFB4B4B4),
  faint: Color(0xFF949494),
  accent: Color(0xFF6CB0F5), accentSoft: Color(0xFF15253A), accentInk: Color(0xFFCFE4FB),
  primary: Color(0xFFFFFFFF), onPrimary: Color(0xFF0C0D0F),
  bloom: Color(0xFFFF7A4D), bloomSoft: Color(0xFF2E1A12), bloomInk: Color(0xFFFF9C78),
  lookAlike: Color(0xFFD4AE52), lookAlikeSoft: Color(0xFF2A2414), lookAlikeInk: Color(0xFFE2C272),
  clearSoft: Color(0xFF15253A), clearInk: Color(0xFFA9D0F8),
  positive: Color(0xFF5FCF95), positiveSoft: Color(0xFF16291E), positiveInk: Color(0xFF7EDCAA),
  warning: Color(0xFFE5A93B),
);

class GG {
  static Palette get _p => darkMode.value ? _dark : _light;
  static Color get ground => _p.ground;
  static Color get surface => _p.surface;
  static Color get raised => _p.raised;
  static Color get border => _p.border;
  static Color get rule => _p.rule;
  static Color get control => _p.control;
  static Color get text => _p.text;
  static Color get muted => _p.muted;
  static Color get faint => _p.faint;
  static Color get accent => _p.accent;
  static Color get accentSoft => _p.accentSoft;
  static Color get accentInk => _p.accentInk;
  static Color get primary => _p.primary;
  static Color get onPrimary => _p.onPrimary;
  static Color get bloom => _p.bloom;
  static Color get bloomSoft => _p.bloomSoft;
  static Color get bloomInk => _p.bloomInk;
  static Color get lookAlike => _p.lookAlike;
  static Color get positive => _p.positive;
  static Color get positiveSoft => _p.positiveSoft;
  static Color get positiveInk => _p.positiveInk;
  static Color get warning => _p.warning;
  static String get logo => darkMode.value ? 'assets/logo_mark.png' : 'assets/logo_mark_light.png';

  static const radius = 8.0;
  static BorderRadius get corner => BorderRadius.circular(radius);
}

class T {
  static const family = 'DM Sans';
  static TextStyle get title =>
      TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.8, color: GG.text);
  static TextStyle get section => TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: GG.text);
  static TextStyle get cardTitle => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, color: GG.text);
  static TextStyle get body => TextStyle(fontSize: 15, height: 1.5, color: GG.text);
  static TextStyle get small => TextStyle(fontSize: 13, height: 1.45, color: GG.muted);
  static TextStyle get meta => TextStyle(fontSize: 12, height: 1.4, color: GG.muted);
  // tabular digits
  static TextStyle get figure => TextStyle(
      fontSize: 30, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.5, color: GG.text,
      fontFeatures: [FontFeature.tabularFigures()]);
}

ThemeData buildTheme() {
  final dark = darkMode.value;
  final base = ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light, useMaterial3: true, fontFamily: T.family);
  final shape = RoundedRectangleBorder(borderRadius: GG.corner);
  return base.copyWith(
    scaffoldBackgroundColor: GG.ground,
    colorScheme: base.colorScheme.copyWith(
      primary: GG.accent,
      onPrimary: dark ? GG.ground : Colors.white,
      surface: GG.surface,
      onSurface: GG.text,
      surfaceTint: Colors.transparent,
    ),
    textTheme: base.textTheme.apply(bodyColor: GG.text, displayColor: GG.text, fontFamily: T.family),
    textSelectionTheme: TextSelectionThemeData(cursorColor: GG.accent, selectionHandleColor: GG.accent),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GG.surface,
      hintStyle: TextStyle(color: GG.faint),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(borderRadius: GG.corner, borderSide: BorderSide(color: GG.control)),
      focusedBorder: OutlineInputBorder(borderRadius: GG.corner, borderSide: BorderSide(color: GG.accent, width: 2)),
      border: OutlineInputBorder(borderRadius: GG.corner, borderSide: BorderSide(color: GG.control)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: GG.accent,
        textStyle: TextStyle(fontFamily: T.family, fontSize: 15, fontWeight: FontWeight.w600),
        shape: shape,
        minimumSize: Size(44, 44),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? GG.raised : GG.text,
      contentTextStyle: TextStyle(fontFamily: T.family, color: dark ? GG.text : Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    dialogTheme: DialogThemeData(
        backgroundColor: GG.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: GG.accent, linearTrackColor: GG.raised),
    dividerTheme: DividerThemeData(color: GG.rule, thickness: 1, space: 1),
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      for (final p in TargetPlatform.values) p: FadeUpwardsPageTransitionsBuilder(),
    }),
  );
}

// never say safe
const resultText = {
  'bloom': 'Possible algal bloom',
  'look_alike': 'Green, but likely not a bloom',
  'clear_water': 'No bloom visible',
  'not_water': 'This doesn\'t look like water',
  'unsure': 'Not sure',
};

const adviceText = {
  'bloom': 'Avoid contact and keep pets out of this water. '
      'Visual estimate only. Check official advisories before contact with the water.',
  'look_alike': 'This looks like something green that probably isn\'t a bloom, like duckweed or pollen. '
      'Visual estimate only. Check official advisories before contact with the water.',
  'clear_water': 'No bloom is visible in this photo. That doesn\'t mean the water is safe. '
      'Visual estimate only. Check official advisories before contact with the water.',
  'not_water': 'Try again with the water filling most of the photo.',
  'unsure': 'The AI isn\'t confident about this photo. Try again closer to the water, in good light.',
};

Color labelColor(String label) => switch (label) {
      'bloom' => GG.bloom,
      'look_alike' => GG.lookAlike,
      'clear_water' => GG.accent,
      _ => GG.faint,
    };

(Color, Color) labelPill(String label) => switch (label) {
      'bloom' => (GG.bloomSoft, GG.bloomInk),
      'look_alike' => (GG._p.lookAlikeSoft, GG._p.lookAlikeInk),
      'clear_water' => (GG._p.clearSoft, GG._p.clearInk),
      _ => (GG.raised, GG.muted),
    };

class Panel extends StatelessWidget {
  final Widget child;
  final Color? tint;
  final EdgeInsets padding;
  const Panel({super.key, required this.child, this.tint, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: tint ?? GG.surface,
          borderRadius: GG.corner,
          border: tint == null && !darkMode.value ? Border.all(color: GG.border) : null,
        ),
        child: child,
      );
}

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const ScreenHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Semantics(label: 'GeistGuard', child: Image.asset(GG.logo, width: 40, height: 40)),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(header: true, child: Text(title, style: T.title)),
              if (subtitle != null) ...[
                SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: Text(subtitle!, key: ValueKey(subtitle), style: T.small.copyWith(fontSize: 14)),
                ),
              ],
            ]),
          ),
          ?trailing,
        ]),
      ]);
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 32, bottom: 12),
        child: Semantics(header: true, child: Text(text, style: T.section)),
      );
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color fill, ink;
  final Widget? leading;
  const StatusPill(this.text, {super.key, required this.fill, required this.ink, this.leading});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading != null) ...[leading!, SizedBox(width: 6)],
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink, height: 1.3)),
        ]),
      );
}

class Dot extends StatelessWidget {
  final Color color;
  final double size;
  const Dot(this.color, {super.key, this.size = 10});

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class PrimaryButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;
  final double height;
  const PrimaryButton({super.key, this.icon, required this.label, this.onPressed, this.height = 52});

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: GG.primary,
      foregroundColor: GG.onPrimary,
      disabledBackgroundColor: GG.raised,
      disabledForegroundColor: GG.muted,
      shape: StadiumBorder(),
      padding: EdgeInsets.symmetric(horizontal: 24),
      textStyle: TextStyle(fontFamily: T.family, fontSize: 16, fontWeight: FontWeight.w600),
    );
    final VoidCallback? tap = onPressed == null
        ? null
        : () {
            HapticFeedback.lightImpact();
            onPressed!();
          };
    final text = Text(label, overflow: TextOverflow.ellipsis);
    return Pressable(
      child: SizedBox(
        height: height,
        child: icon == null
            ? FilledButton(onPressed: tap, style: style, child: text)
            : FilledButton.icon(onPressed: tap, style: style, icon: Icon(icon, size: 20), label: text),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  const SecondaryButton({super.key, required this.label, this.onPressed, this.height = 52});

  @override
  Widget build(BuildContext context) => Pressable(
        child: SizedBox(
          height: height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: GG.text,
              disabledForegroundColor: GG.faint,
              side: BorderSide(color: GG.control),
              shape: StadiumBorder(),
              padding: EdgeInsets.symmetric(horizontal: 22),
              textStyle: TextStyle(fontFamily: T.family, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: Text(label),
          ),
        ),
      );
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  const RoundIconButton({super.key, required this.icon, required this.tooltip, this.onPressed, this.size = 52});

  @override
  Widget build(BuildContext context) => Pressable(
        child: IconButton.outlined(
          onPressed: onPressed,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            foregroundColor: GG.text,
            disabledForegroundColor: GG.faint,
            side: BorderSide(color: GG.control),
            fixedSize: Size(size, size),
          ),
          icon: Icon(icon, size: 22),
        ),
      );
}

class LinkOut extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const LinkOut(this.label, {super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
        child: Text('$label ↗'),
      );
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          darkMode.value = !darkMode.value;
        },
        tooltip: darkMode.value ? 'Switch to light mode' : 'Switch to dark mode',
        style: IconButton.styleFrom(foregroundColor: GG.text, fixedSize: Size(44, 44)),
        icon: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: Tween(begin: 0.75, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(darkMode.value ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              key: ValueKey(darkMode.value), size: 22),
        ),
      );
}

class BulletLine extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const BulletLine(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.only(top: 9, right: 12), child: Dot(GG.faint, size: 5)),
          Expanded(child: Text(text, style: style ?? T.body)),
        ]),
      );
}

class LoadingBar extends StatelessWidget {
  final double width, height;
  const LoadingBar({super.key, this.width = double.infinity, this.height = 14});

  @override
  Widget build(BuildContext context) => Container(
      width: width, height: height, decoration: BoxDecoration(color: GG.raised, borderRadius: BorderRadius.circular(4)));
}
