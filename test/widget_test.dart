import 'package:flutter_test/flutter_test.dart';
import 'package:geistguard/theme.dart';

void main() {
  test('every AI label has a result and advice message', () {
    for (final label in ['bloom', 'look_alike', 'clear_water', 'not_water', 'unsure']) {
      expect(resultText[label], isNotNull, reason: label);
      expect(adviceText[label], isNotNull, reason: label);
    }
  });

  test('no result headline ever calls the water safe', () {
    for (final text in resultText.values) {
      expect(text.toLowerCase().contains('safe'), isFalse, reason: text);
    }
  });

  test('water results carry the visual-estimate disclaimer', () {
    for (final label in ['bloom', 'look_alike', 'clear_water']) {
      expect(adviceText[label], contains('Visual estimate only'), reason: label);
    }
  });
}
