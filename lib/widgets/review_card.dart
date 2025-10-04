import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final String userName;
  final String userAvatar; // URL or empty string for default
  final double rating;
  final String reviewText;
  final String date;
  final int helpfulCount;

  const ReviewCard({
    super.key,
    required this.userName,
    this.userAvatar = '',
    required this.rating,
    required this.reviewText,
    required this.date,
    this.helpfulCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[700],
                  backgroundImage: userAvatar.isNotEmpty
                      ? NetworkImage(userAvatar)
                      : null,
                  child: userAvatar.isEmpty
                      ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),

                // Name and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating Stars
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Review Text
            Text(
              reviewText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // Helpful Button
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Helpful ($helpfulCount)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Mock data generator for testing
class MockReviews {
  static final List<Map<String, dynamic>> mockReviews = [
    {
      'userName': 'Maria Garcia',
      'userAvatar': '',
      'rating': 5.0,
      'reviewText': 'Absolutely loved this place! The atmosphere was amazing and the location is perfect. Would definitely recommend to anyone visiting the area.',
      'date': 'Oct 1, 2025',
      'helpfulCount': 12,
    },
    {
      'userName': 'Carlos Rodriguez',
      'userAvatar': '',
      'rating': 4.5,
      'reviewText': 'Great spot! Really enjoyed my visit here. Only minor complaint is it can get a bit crowded during peak hours.',
      'date': 'Sep 28, 2025',
      'helpfulCount': 8,
    },
    {
      'userName': 'Ana Martinez',
      'userAvatar': '',
      'rating': 5.0,
      'reviewText': 'One of my favorite places in the city. Clean, well-maintained, and always a pleasant experience.',
      'date': 'Sep 25, 2025',
      'helpfulCount': 15,
    },
    {
      'userName': 'Juan Perez',
      'userAvatar': '',
      'rating': 4.0,
      'reviewText': 'Pretty good overall. The place has a nice vibe and is easy to get to. Will come back again.',
      'date': 'Sep 20, 2025',
      'helpfulCount': 5,
    },
  ];
}