import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsPage extends StatelessWidget {
  final String locationId; // ✅ Location ID passed in from LocationCard

  const ReviewsPage({Key? key, required this.locationId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reviews"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ Listen to Firestore collection "reviews" filtered by locationId
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('locationId', isEqualTo: locationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reviews yet"));
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final reviewText = review['text'] ?? "No review text";
              final reviewer = review['user'] ?? "Anonymous";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(reviewText),
                  subtitle: Text("By $reviewer"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
