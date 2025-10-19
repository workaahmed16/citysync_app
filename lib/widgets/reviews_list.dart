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

  /// Deletes a review after user confirmation
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
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();

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

            return ReviewCard(
              userName: review['userName'] ?? 'Anonymous',
              userAvatar: review['userAvatar'] ?? '',
              rating: (review['rating'] ?? 0).toDouble(),
              reviewText: review['reviewText'] ?? '',
              date: _safeFormatDate(review['createdAt']),
              helpfulCount: review['helpfulCount'] ?? 0,
              isOwner: isOwner,
              onDelete: () => _deleteReview(context, doc.id),
            );
          }).toList(),
        );
      },
    );
  }
}