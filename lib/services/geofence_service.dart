import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Service for geofencing and distance calculations
class GeofenceService {
  static const double earthRadiusKm = 6371.0;

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(LatLng point1, LatLng point2) {
    final dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final dLng = _degreesToRadians(point2.longitude - point1.longitude);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_degreesToRadians(point1.latitude)) *
            math.cos(_degreesToRadians(point2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Check if a location is within the specified radius
  static bool isWithinRadius(
      LatLng userLocation,
      LatLng targetLocation,
      double radiusKm,
      ) {
    final distance = calculateDistance(userLocation, targetLocation);
    return distance <= radiusKm;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Get formatted distance string
  static String getDistanceString(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }
}