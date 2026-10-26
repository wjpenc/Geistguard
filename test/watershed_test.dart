import 'package:flutter_test/flutter_test.dart';
import 'package:geistguard/watershed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('points inside and outside the Geist watershed', () async {
    final w = Watershed();
    await w.load();
    expect(w.contains(39.935, -85.95), isTrue, reason: 'mid-Geist');
    expect(w.contains(39.9323, -85.8480), isTrue, reason: 'Fortville');
    expect(w.contains(39.9975, -85.7466), isTrue, reason: 'Pendleton');
    expect(w.contains(39.9568, -86.0136), isFalse, reason: 'Fishers City Hall');
    expect(w.contains(40.0456, -86.0086), isFalse, reason: 'Noblesville');
    expect(w.contains(39.8387, -86.0253), isFalse, reason: 'Lawrence');
  });
}
