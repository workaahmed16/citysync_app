import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    debugPrint('🔥 Building ReviewsList for locationId: $locationId');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('locationId', isEqualTo: locationId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        debugPrint('📡 StreamBuilder state: ${snapshot.connectionState}');

        if (snapshot.hasError) {
          debugPrint('❌ Firestore error: ${snapshot.error}');
          return const Center(child: Text('Error loading reviews.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('⏳ Waiting for Firestore data...');
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          debugPrint('⚠️ Snapshot has no data.');
          return const Center(child: Text('No data yet.'));
        }

        final reviews = snapshot.data!.docs;
        debugPrint('✅ Found ${reviews.length} review(s) for $locationId');

        if (reviews.isEmpty) {
          return const Center(
            child: Text('No reviews yet. Be the first to write one!'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: reviews.map((doc) {
            final review = doc.data() as Map<String, dynamic>;

            // Debugging for each review document
            debugPrint('📝 Review document: ${doc.id}');
            debugPrint('   → userName: ${review['userName']}');
            debugPrint('   → reviewText: ${review['reviewText']}');
            debugPrint('   → rating: ${review['rating']}');
            debugPrint('   → createdAt type: ${review['createdAt']?.runtimeType}');

            return ReviewCard(
              userName: review['userName'] ?? 'Anonymous',
              userAvatar: review['userAvatar'] ?? '',
              rating: (review['rating'] ?? 0).toDouble(),
              reviewText: review['reviewText'] ?? '',
              date: _safeFormatDate(review['createdAt']),
              helpfulCount: review['helpfulCount'] ?? 0,
            );
          }).toList(),
        );
      },
    );
  }
}
