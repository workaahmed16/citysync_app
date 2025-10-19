import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final String userName;
  final String userAvatar; // URL or empty string for default
  final double rating;
  final String reviewText;
  final String date;
  final int helpfulCount;
  final bool isOwner; // NEW: to show/hide delete button
  final VoidCallback? onDelete; // NEW: delete callback

  const ReviewCard({
    super.key,
    required this.userName,
    this.userAvatar = '',
    required this.rating,
    required this.reviewText,
    required this.date,
    this.helpfulCount = 0,
    this.isOwner = false, // NEW
    this.onDelete, // NEW
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

                // NEW: Delete button for review owner
                if (isOwner && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    onPressed: onDelete,
                    tooltip: 'Delete review',
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
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