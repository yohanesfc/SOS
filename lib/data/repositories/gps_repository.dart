import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GpsRepository {
  Stream<Position>? _positionStream;

  /// Request permissions and return current position
  Future<Position?> getCurrentPosition() async {
    final permission = await _ensurePermission();
    if (!permission) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 30),
    );
  }

  /// Stream of position updates — requests permission first
  Stream<Position> getPositionStream() async* {
    final granted = await _ensurePermission();
    if (!granted) {
      throw Exception('Location permission denied or service disabled');
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    );

    yield* _positionStream!;
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  /// Format position into SMS-ready string
  String formatForSms(Position pos) {
    final lat = pos.latitude.toStringAsFixed(6);
    final lng = pos.longitude.toStringAsFixed(6);
    final alt = pos.altitude.toStringAsFixed(0);
    final acc = pos.accuracy.toStringAsFixed(0);
    final latDir = pos.latitude >= 0 ? 'N' : 'S';
    final lngDir = pos.longitude >= 0 ? 'E' : 'W';

    return '📍 ${lat.replaceAll('-','')}° $latDir, ${lng.replaceAll('-','')}° $lngDir\n'
           '⬆ Elevation: ${alt}m | Accuracy: ±${acc}m\n'
           '🗺 https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
  }
}

final gpsRepositoryProvider = Provider<GpsRepository>((ref) => GpsRepository());

final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final repo = ref.read(gpsRepositoryProvider);
  return repo.getCurrentPosition();
});

final positionStreamProvider = StreamProvider<Position>((ref) {
  final repo = ref.read(gpsRepositoryProvider);
  return repo.getPositionStream().handleError((e) {
    // Errors (permission denied) are shown in the UI via the error() builder
  });
});

