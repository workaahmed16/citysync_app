import 'package:flutter/material.dart';
import 'review_location_page.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded sample reviews (replace with DB later)
    final List<Map<String, dynamic>> reviews = [
      {
        "username": "Alice",
        "rating": 5,
        "review": "Great place! Had an awesome time.",
        "date": "2025-08-18"
      },
      {
        "username": "Bob",
        "rating": 3,
        "review": "It was okay, could be better.",
        "date": "2025-08-17"
      },
      {
        "username": "Charlie",
        "rating": 4,
        "review": "Nice atmosphere and friendly staff.",
        "date": "2025-08-16"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reviews"),
      ),
      body: Column(
        children: [
          // Review list
          Expanded(
            child: ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      review["username"],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            review["rating"],
                                (i) => const Icon(Icons.star, color: Colors.amber, size: 18),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(review["review"]),
                        const SizedBox(height: 4),
                        Text(
                          review["date"],
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Button to go write a new review
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReviewLocationPage(),
                    ),
                  );
                },
                child: const Text("Write a Review"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
