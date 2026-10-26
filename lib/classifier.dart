import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class BloomClassifier {
  static const threshold = 0.6; // from the threshold table
  late Interpreter _interpreter;
  late List<String> _labels;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset('assets/model.tflite');
    _labels = (await rootBundle.loadString('assets/labels.txt')).trim().split('\n');
  }

  (String, double) classify(File photo) {
    final decoded = img.decodeImage(photo.readAsBytesSync())!;
    // fix rotation, resize to 224
    final resized = img.copyResize(img.bakeOrientation(decoded), width: 224, height: 224);

    // raw 0-255, model scales it
    final input = [
      List.generate(224, (y) => List.generate(224, (x) {
        final p = resized.getPixel(x, y);
        return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
      }))
    ];
    final output = [List.filled(_labels.length, 0.0)];
    _interpreter.run(input, output);

    final probs = output[0];
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    final confidence = probs[best];
    return (confidence < threshold ? 'unsure' : _labels[best], confidence);
  }
}