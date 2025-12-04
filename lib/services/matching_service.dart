import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'embedding_service.dart';

class ProfileMatch {
  final String userId;
  final String name;
  final String? profilePhotoUrl;
  final String? bio;
  final String? interests;
  final String? city;
  final String? country;
  final double similarityScore;
  final Map<String, dynamic> userData;

  ProfileMatch({
    required this.userId,
    required this.name,
    this.profilePhotoUrl,
    this.bio,
    this.interests,
    this.city,
    this.country,
    required this.similarityScore,
    required this.userData,
  });

  factory ProfileMatch.fromFirestore(
      DocumentSnapshot doc,
      double score,
      ) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileMatch(
      userId: doc.id,
      name: data['name'] ?? 'Anonymous',
      profilePhotoUrl: data['profilePhotoUrl'],
      bio: data['bio'],
      interests: data['interests'],
      city: data['city'],
      country: data['country'],
      similarityScore: score,
      userData: data,
    );
  }
}

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Finds users similar to the current user based on profile vectors
  ///
  /// [limit] - Maximum number of matches to return
  /// [minSimilarityScore] - Minimum similarity threshold (0.0 to 1.0)
  /// [maxDistanceKm] - Optional: Filter by geographic distance
  Future<List<ProfileMatch>> findMatches({
    int limit = 20,
    double minSimilarityScore = 0.3,
    double? maxDistanceKm,
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
      throw Exception('User profile vector not generated. Please update your profile.');
    }

    final currentVectorList = List<double>.from(currentVector);

    // Step 2: Get current user's location for distance filtering
    double? currentLat;
    double? currentLng;
    if (maxDistanceKm != null) {
      currentLat = currentUserData['lat']?.toDouble();
      currentLng = currentUserData['lng']?.toDouble();
    }

    // Step 3: Fetch all other users with vectors
    // Note: Firestore doesn't support vector similarity queries natively
    // So we fetch all users and compute similarity in-memory
    final usersSnapshot = await _firestore
        .collection('users')
        .where('profile_vector', isNull: false)
        .get();

    final matches = <ProfileMatch>[];

    // Step 4: Calculate similarity for each user
    for (final doc in usersSnapshot.docs) {
      // Skip current user
      if (doc.id == currentUser.uid) continue;

      final userData = doc.data();
      final otherVector = userData['profile_vector'];

      if (otherVector == null) continue;

      try {
        final otherVectorList = List<double>.from(otherVector);

        // Calculate cosine similarity
        final similarity = EmbeddingService.cosineSimilarity(
          currentVectorList,
          otherVectorList,
        );

        // Apply similarity threshold
        if (similarity < minSimilarityScore) continue;

        // Apply distance filter if specified
        if (maxDistanceKm != null && currentLat != null && currentLng != null) {
          final otherLat = userData['lat']?.toDouble();
          final otherLng = userData['lng']?.toDouble();

          if (otherLat != null && otherLng != null) {
            final distance = _calculateDistance(
              currentLat,
              currentLng,
              otherLat,
              otherLng,
            );

            if (distance > maxDistanceKm) continue;
          } else {
            // Skip users without location if distance filtering is enabled
            continue;
          }
        }

        matches.add(ProfileMatch.fromFirestore(doc, similarity));
      } catch (e) {
        print('Error processing user ${doc.id}: $e');
        continue;
      }
    }

    // Step 5: Sort by similarity score (highest first) and limit results
    matches.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return matches.take(limit).toList();
  }

  /// Calculates the Haversine distance between two points in kilometers
  double _calculateDistance(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
      ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_degreesToRadians(lat1)) *
            Math.cos(_degreesToRadians(lat2)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2);

    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.14159265359 / 180.0;
  }

  /// Finds matches for a specific user (useful for recommendations)
  Future<List<ProfileMatch>> findMatchesForUser(
      String userId, {
        int limit = 20,
        double minSimilarityScore = 0.3,
      }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final userData = userDoc.data()!;
    final userVector = userData['profile_vector'];

    if (userVector == null) {
      throw Exception('User profile vector not available');
    }

    final userVectorList = List<double>.from(userVector);

    final usersSnapshot = await _firestore
        .collection('users')
        .where('profile_vector', isNull: false)
        .get();

    final matches = <ProfileMatch>[];

    for (final doc in usersSnapshot.docs) {
      if (doc.id == userId) continue;

      final otherData = doc.data();
      final otherVector = otherData['profile_vector'];

      if (otherVector == null) continue;

      try {
        final otherVectorList = List<double>.from(otherVector);
        final similarity = EmbeddingService.cosineSimilarity(
          userVectorList,
          otherVectorList,
        );

        if (similarity >= minSimilarityScore) {
          matches.add(ProfileMatch.fromFirestore(doc, similarity));
        }
      } catch (e) {
        continue;
      }
    }

    matches.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return matches.take(limit).toList();
  }
}

// Math helper class (same as in embedding_service.dart)
class Math {
  static double sqrt(double x) => x < 0 ? 0 : _sqrt(x);

  static double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    double prevGuess;
    do {
      prevGuess = guess;
      guess = (guess + x / guess) / 2;
    } while ((guess - prevGuess).abs() > 0.000001);
    return guess;
  }

  static double sin(double x) {
    // Taylor series approximation for sin
    double result = 0;
    double term = x;
    for (int i = 1; i <= 15; i += 2) {
      result += term;
      term *= -x * x / ((i + 1) * (i + 2));
    }
    return result;
  }

  static double cos(double x) {
    // Use identity: cos(x) = sin(x + π/2)
    return sin(x + 1.5707963267948966);
  }

  static double atan2(double y, double x) {
    if (x > 0) {
      return _atan(y / x);
    } else if (x < 0 && y >= 0) {
      return _atan(y / x) + 3.14159265359;
    } else if (x < 0 && y < 0) {
      return _atan(y / x) - 3.14159265359;
    } else if (x == 0 && y > 0) {
      return 1.5707963267948966;
    } else if (x == 0 && y < 0) {
      return -1.5707963267948966;
    }
    return 0;
  }

  static double _atan(double x) {
    // Approximation using Taylor series
    if (x.abs() > 1) {
      return 1.5707963267948966 - _atan(1 / x);
    }
    double result = 0;
    double term = x;
    for (int i = 1; i <= 15; i += 2) {
      result += term / i;
      term *= -x * x;
    }
    return result;
  }
}