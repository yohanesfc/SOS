import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class Landmark {
  final String name;
  final double lat;
  final double lng;
  final String region;

  Landmark({
    required this.name,
    required this.lat,
    required this.lng,
    required this.region,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      region: json['region'] as String,
    );
  }
}

class OfflineGeocodingService {
  List<Landmark>? _landmarks;

  /// Load landmarks from the JSON asset
  Future<void> loadLandmarks() async {
    if (_landmarks != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/landmarks.json');
      final List<dynamic> data = json.decode(jsonString);
      _landmarks = data.map((item) => Landmark.fromJson(item)).toList();
    } catch (e) {
      print('--- Geocoder: Error loading database: $e ---');
      _landmarks = [];
    }
  }

  /// Resolve raw coordinates to the nearest landmark
  Future<String?> resolveLocation(double lat, double lng) async {
    await loadLandmarks();
    if (_landmarks == null || _landmarks!.isEmpty) return null;

    Landmark? nearest;
    double minDistance = double.infinity;
    double bearingAngle = 0.0;

    for (final landmark in _landmarks!) {
      final dist = _calculateDistance(lat, lng, landmark.lat, landmark.lng);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = landmark;
        bearingAngle = _calculateBearing(lat, lng, landmark.lat, landmark.lng);
      }
    }

    if (nearest == null) return null;

    final direction = _getDirection(bearingAngle);
    final distanceStr = minDistance.toStringAsFixed(1);

    // If extremely close (e.g. under 500 meters), say "On" or "At" the landmark
    if (minDistance < 0.5) {
      return 'At ${nearest.name} (${nearest.region})';
    }

    return 'Approx. $distanceStr km $direction of ${nearest.name} (${nearest.region})';
  }

  /// Haversine formula to compute distance in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(rLat1) * math.cos(rLat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Calculate bearing from source to destination coordinate
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);
    final dLon = _degreesToRadians(lon2 - lon1);

    final y = math.sin(dLon) * math.cos(rLat2);
    final x = math.cos(rLat1) * math.sin(rLat2) -
        math.sin(rLat1) * math.cos(rLat2) * math.cos(dLon);

    final brng = math.atan2(y, x);
    return (_radiansToDegrees(brng) + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
  double _radiansToDegrees(double radians) => radians * 180 / math.pi;

  /// Map bearing degrees to standard 8 cardinal directions
  String _getDirection(double bearingDegrees) {
    const directions = ['North', 'North-East', 'East', 'South-East', 'South', 'South-West', 'West', 'North-West'];
    final index = ((bearingDegrees + 22.5) % 360 / 45).floor();
    return directions[index];
  }
}
