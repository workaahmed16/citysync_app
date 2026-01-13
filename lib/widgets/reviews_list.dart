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
        return value;
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
      final locationDoc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .get();

      if (!locationDoc.exists) {
        debugPrint('❌ Location document not found');
        return;
      }

      final locationData = locationDoc.data() as Map<String, dynamic>;

      // Get base rating (original rating before any reviews)
      final baseRating = locationData.containsKey('baseRating')
          ? (locationData['baseRating'] as num).toDouble()
          : (locationData['rating'] as num? ?? 0).toDouble();

      if (!locationData.containsKey('baseRating')) {
        debugPrint('⚠️ WARNING: baseRating not found for location $locationId. Using current rating as fallback.');
      }

      // Get all current reviews for this location
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('locationId', isEqualTo: locationId)
          .get();

      double newRating;

      if (reviewsSnapshot.docs.isEmpty) {
        // No reviews left, revert to base rating
        newRating = baseRating;
        debugPrint('✅ No reviews remaining. Reverting to base rating: $baseRating');
      } else {
        // Calculate average: (baseRating + sum of all review ratings) / (1 + number of reviews)
        double totalRating = baseRating;
        int reviewCount = reviewsSnapshot.docs.length;

        for (var doc in reviewsSnapshot.docs) {
          final review = doc.data();
          final reviewRating = (review['rating'] as num? ?? 0).toDouble();
          totalRating += reviewRating;
        }

        newRating = totalRating / (reviewCount + 1);
        debugPrint('✅ Rating recalculated: $newRating (base: $baseRating + $reviewCount reviews)');
      }

      // Update the location's rating
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .update({'rating': newRating});

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
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Error loading reviews: ${snapshot.error}');
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

        // Sort reviews in memory (newest first)
        reviews.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: reviews.map((doc) {
            final review = doc.data() as Map<String, dynamic>;
            final reviewUserId = review['userId'] ?? '';
            final isOwner = currentUserId != null && reviewUserId == currentUserId;
            final instagramPostUrl = review['instagramPostUrl'] as String?;

            final rating = (review['rating'] as num? ?? 0).toDouble();
            final helpfulCount = (review['helpfulCount'] as num? ?? 0).toInt();

            return ReviewCard(
              userName: review['userName'] ?? 'Anonymous',
              userAvatar: review['userAvatar'] ?? '',
              rating: rating,
              reviewText: review['reviewText'] ?? review['comment'] ?? '',
              date: _safeFormatDate(review['createdAt']),
              helpfulCount: helpfulCount,
              isOwner: isOwner,
              onDelete: () => _deleteReview(context, doc.id),
              instagramPostUrl: instagramPostUrl,
            );
          }).toList(),
        );
      },
    );
  }
}