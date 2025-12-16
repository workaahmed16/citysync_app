import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'embedding_service.dart';
import 'geofence_service.dart';

class LocationMatch {
  final String locationId;
  final String name;
  final String? description;
  final String? address;
  final double rating;
  final double lat;
  final double lng;
  final double similarityScore;
  final double distanceKm;
  final List<String> photos;
  final Map<String, dynamic> locationData;

  LocationMatch({
    required this.locationId,
    required this.name,
    this.description,
    this.address,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.similarityScore,
    required this.distanceKm,
    required this.photos,
    required this.locationData,
  });

  factory LocationMatch.fromFirestore(
      DocumentSnapshot doc,
      double score,
      double distance,
      ) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationMatch(
      locationId: doc.id,
      name: data['name'] ?? 'Unnamed Location',
      description: data['description'],
      address: data['address'],
      rating: (data['rating'] ?? 0).toDouble(),
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      similarityScore: score,
      distanceKm: distance,
      photos: List<String>.from(data['photos'] ?? []),
      locationData: data,
    );
  }
}

class LocationMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Finds locations similar to the current user's profile within a radius
  ///
  /// [userLocation] - User's current coordinates
  /// [radiusKm] - Maximum distance in kilometers
  /// [limit] - Maximum number of matches to return (default: 5)
  /// [minSimilarityScore] - Minimum similarity threshold (0.0 to 1.0)
  Future<List<LocationMatch>> findMatchingLocations({
    required LatLng userLocation,
    required double radiusKm,
    int limit = 5,
    double minSimilarityScore = 0.2,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Step 1: Get current user's profile vector
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!currentUserDoc.exists) {
      throw Exception('User profile not found');
    }

    final currentUserData = currentUserDoc.data()!;
    final currentVector = currentUserData['profile_vector'];

    if (currentVector == null) {
      // If user doesn't have a vector, fall back to distance-only filtering
      print('⚠️ User profile vector not found. Falling back to distance-only filtering.');
      return _getLocationsByDistanceOnly(userLocation, radiusKm, limit);
    }

    final currentVectorList = List<double>.from(currentVector);

    // Step 2: Fetch all locations with vectors within rough geographic bounds
    final locationsSnapshot = await _firestore
        .collection('locations')
        .where('location_vector', isNull: false)
        .get();

    final matches = <LocationMatch>[];

    // Step 3: Calculate similarity and filter by distance
    for (final doc in locationsSnapshot.docs) {
      final locationData = doc.data();
      final locationVector = locationData['location_vector'];

      if (locationVector == null) continue;

      final lat = locationData['lat'] as double?;
      final lng = locationData['lng'] as double?;

      if (lat == null || lng == null) continue;

      final locationPoint = LatLng(lat, lng);

      // Check if within radius
      final distance = GeofenceService.calculateDistance(
        userLocation,
        locationPoint,
      );

      if (distance > radiusKm) continue;

      try {
        final locationVectorList = List<double>.from(locationVector);

        // Calculate cosine similarity between user profile and location
        final similarity = EmbeddingService.cosineSimilarity(
          currentVectorList,
          locationVectorList,
        );

        // Apply similarity threshold
        if (similarity < minSimilarityScore) continue;

        matches.add(LocationMatch.fromFirestore(doc, similarity, distance));
      } catch (e) {
        print('Error processing location ${doc.id}: $e');
        continue;
      }
    }

    // Step 4: Sort by similarity score (highest first), then by distance
    matches.sort((a, b) {
      final scoreDiff = b.similarityScore.compareTo(a.similarityScore);
      if (scoreDiff != 0) return scoreDiff;
      return a.distanceKm.compareTo(b.distanceKm);
    });

    return matches.take(limit).toList();
  }

  /// Fallback method: Get locations by distance only when user has no vector
  Future<List<LocationMatch>> _getLocationsByDistanceOnly(
      LatLng userLocation,
      double radiusKm,
      int limit,
      ) async {
    final locationsSnapshot = await _firestore
        .collection('locations')
        .get();

    final matches = <LocationMatch>[];

    for (final doc in locationsSnapshot.docs) {
      final data = doc.data();
      final lat = data['lat'] as double?;
      final lng = data['lng'] as double?;

      if (lat == null || lng == null) continue;

      final locationPoint = LatLng(lat, lng);
      final distance = GeofenceService.calculateDistance(
        userLocation,
        locationPoint,
      );

      if (distance <= radiusKm) {
        // Use 0.5 as default similarity score for distance-only matches
        matches.add(LocationMatch.fromFirestore(doc, 0.5, distance));
      }
    }

    // Sort by distance
    matches.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return matches.take(limit).toList();
  }

  /// Helper to create location text for embedding generation
  static String createLocationText({
    required String name,
    required String description,
    String? address,
  }) {
    final parts = <String>[];

    if (name.trim().isNotEmpty) {
      parts.add('Name: $name');
    }

    if (description.trim().isNotEmpty) {
      parts.add('Description: $description');
    }

    if (address != null && address.trim().isNotEmpty) {
      parts.add('Address: $address');
    }

    return parts.join('. ');
  }
}