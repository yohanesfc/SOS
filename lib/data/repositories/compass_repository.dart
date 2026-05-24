import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompassRepository {
  Stream<CompassEvent> getHeadingStream() {
    return FlutterCompass.events!.where((e) => e.heading != null);
  }

  bool get isAvailable => FlutterCompass.events != null;

  /// Convert numeric heading to cardinal label (English)
  static String headingToLabel(double heading) {
    const labels = [
      (337.5, 360.0, 'NORTH'),
      (0.0, 22.5, 'NORTH'),
      (22.5, 67.5, 'NORTHEAST'),
      (67.5, 112.5, 'EAST'),
      (112.5, 157.5, 'SOUTHEAST'),
      (157.5, 202.5, 'SOUTH'),
      (202.5, 247.5, 'SOUTHWEST'),
      (247.5, 292.5, 'WEST'),
      (292.5, 337.5, 'NORTHWEST'),
    ];
    final h = heading % 360;
    for (final (min, max, label) in labels) {
      if (h >= min && h < max) return label;
    }
    return 'NORTH';
  }

  static String headingToShort(double heading) {
    const labels = [
      (337.5, 360.0, 'N'), (0.0, 22.5, 'N'),
      (22.5, 67.5, 'NE'),  (67.5, 112.5, 'E'),
      (112.5, 157.5, 'SE'),(157.5, 202.5, 'S'),
      (202.5, 247.5, 'SW'),(247.5, 292.5, 'W'),
      (292.5, 337.5, 'NW'),
    ];
    final h = heading % 360;
    for (final (min, max, label) in labels) {
      if (h >= min && h < max) return label;
    }
    return 'N';
  }
}

final compassRepositoryProvider = Provider<CompassRepository>((ref) => CompassRepository());

final compassStreamProvider = StreamProvider<CompassEvent>((ref) {
  final repo = ref.read(compassRepositoryProvider);
  if (!repo.isAvailable) return const Stream.empty();
  return repo.getHeadingStream();
});
