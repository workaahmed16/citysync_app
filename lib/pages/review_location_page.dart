import 'package:flutter/material.dart';

class ReviewLocationPage extends StatelessWidget {
  const ReviewLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Location"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          "Here the user can review the location!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
