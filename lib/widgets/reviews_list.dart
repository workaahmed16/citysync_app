import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/review_card.dart';

class ReviewsList extends StatelessWidget {
  final String locationId;
  const ReviewsList({super.key, required this.locationId});

  /// Safely formats Firestore dates without crashing.
  String _safeFormatDate(dynamic value) {
    try {
      if (value == null) return 'Unknown date';
      if (value is Timestamp) {
        return DateFormat('MMM dd, yyyy').format(value.toDate());
      } else if (value is DateTime) {
        return DateFormat('MMM dd, yyyy').format(value);
      } else if (value is String) {
        return value; // already a string date
      } else {
        return 'Invalid date';
      }
    } catch (e) {
      debugPrint('⚠️ Date format error: $e');
      return 'Unknown date';
    }
  }

  /// Recalculates the average rating for a location based on base rating + all reviews
  Future<void> _recalculateLocationRating() async {
    try {
      // Get the location document to fetch the base rating
      final locationDoc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .get();

      if (!locationDoc.exists) {
        debugPrint('❌ Location document not found');
        return;
      }

      final locationData = locationDoc.data() as Map<String, dynamic>;

      // Use baseRating if it exists, otherwise log warning and use current rating as fallback
      final baseRating = locationData.containsKey('baseRating')
          ? (locationData['baseRating'] ?? 0).toDouble()
          : (locationData['rating'] ?? 0).toDouble();

      if (!locationData.containsKey('baseRating')) {
        debugPrint('⚠️ WARNING: baseRating not found for location $locationId. Using current rating as fallback.');
      }

      // Get all reviews for this location
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('locationId', isEqualTo: locationId)
          .get();

      double newRating = 0.0;

      // Calculate average: base rating + all review ratings
      double totalRating = baseRating; // Start with base rating
      int totalCount = 1; // Base rating counts as 1

      for (var doc in reviewsSnapshot.docs) {
        final review = doc.data();
        totalRating += (review['rating'] ?? 0).toDouble();
        totalCount++;
      }

      newRating = totalRating / totalCount;

      // Update only the current rating (never overwrite baseRating)
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .update({'rating': newRating});

      debugPrint('✅ Rating recalculated: $newRating (base: $baseRating + ${reviewsSnapshot.docs.length} reviews)');
    } catch (e) {
      debugPrint('❌ Error recalculating rating: $e');
    }
  }

  /// Deletes a review after user confirmation and recalculates rating
  Future<void> _deleteReview(BuildContext context, String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete the review
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // Recalculate the location's rating
      await _recalculateLocationRating();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('locationId', isEqualTo: locationId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading reviews.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data yet.'));
        }

        final reviews = snapshot.data!.docs;

        if (reviews.isEmpty) {
          return const Center(
            child: Text('No reviews yet. Be the first to write one!'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: reviews.map((doc) {
            final review = doc.data() as Map<String, dynamic>;
            final reviewUserId = review['userId'] ?? '';
            final isOwner = currentUserId != null && reviewUserId == currentUserId;
            final instagramPostUrl = review['instagramPostUrl'] as String?;

            return ReviewCard(
              userName: review['userName'] ?? 'Anonymous',
              userAvatar: review['userAvatar'] ?? '',
              rating: (review['rating'] ?? 0).toDouble(),
              reviewText: review['reviewText'] ?? '',
              date: _safeFormatDate(review['createdAt']),
              helpfulCount: review['helpfulCount'] ?? 0,
              isOwner: isOwner,
              onDelete: () => _deleteReview(context, doc.id),
              instagramPostUrl: instagramPostUrl, // NEW: Pass Instagram URL
            );
          }).toList(),
        );
      },
    );
  }
}