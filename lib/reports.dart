import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

Stream<List<Map<String, dynamic>>> reportsSince(Duration age) => FirebaseFirestore.instance
    .collection('reports')
    .where('time', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(age)))
    .snapshots()
    .map((s) => s.docs.map((d) => d.data()).toList());

// small base64 thumb in the doc, no cloud storage (free plan)
String makeThumbnail(File photo) {
  final decoded = img.decodeImage(photo.readAsBytesSync())!;
  final small = img.copyResize(img.bakeOrientation(decoded), width: 240);
  return base64Encode(img.encodeJpg(small, quality: 60));
}
