import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for deleting locations and their associated data
class LocationDeleteService {
  /// Delete a location and all its associated reviews
  /// Returns true if successful, throws exception on error
  static Future<bool> deleteLocation(String locationId) async {
    try {
      // 1. Delete all reviews for this location
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('locationId', isEqualTo: locationId)
          .get();

      // Delete all reviews in a batch
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in reviewsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 2. Delete the location itself
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .delete();

      return true;
    } catch (e) {
      throw Exception('Error deleting location: $e');
    }
  }

  /// Check if current user owns this location
  static Future<bool> canDeleteLocation(
      String locationId,
      String currentUserId,
      ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      return data?['userId'] == currentUserId;
    } catch (e) {
      return false;
    }
  }
}