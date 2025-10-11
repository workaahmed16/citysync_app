import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/reviews_page.dart';

/// LocationCard now passes the unique Firestore placeId
class LocationCard extends StatelessWidget {
  final String placeId;
  final String title; // still useful to show on the tile
  final String description;
  final String distance; // 🔹 Add this

  const LocationCard({
    super.key,
    required this.placeId,
    required this.title,
    required this.description,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to dynamic review page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewsPage(locationId: placeId)
            ),
          );
        },
      ),
    );
  }
}