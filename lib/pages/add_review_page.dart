import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddReviewPage extends StatefulWidget {
  final String locationId;
  final String locationName;

  const AddReviewPage({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current authenticated user
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('You must be logged in to submit a review');
      }

      // Get user's display name from Auth or Firestore users collection
      String userName = currentUser.displayName ?? 'Anonymous User';
      String userAvatar = currentUser.photoURL ?? '';

      // If displayName is null, try to get it from users collection
      if (currentUser.displayName == null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            userName = userDoc.data()?['name'] ?? 'Anonymous User';
            userAvatar = userDoc.data()?['photoURL'] ?? '';
          }
        } catch (e) {
          // If users doc doesn't exist, use email as fallback
          userName = currentUser.email?.split('@')[0] ?? 'Anonymous User';
        }
      }

      // Add review to top-level reviews collection (not subcollection)
      await FirebaseFirestore.instance.collection('reviews').add({
        'locationId': widget.locationId,
        'userId': currentUser.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'helpfulCount': 0,
        'helpfulBy': [], // Array to track who marked it helpful
      });

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous page
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Name
              Text(
                widget.locationName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your experience with others',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Rating Section
              const Text(
                'Your Rating',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Star Rating Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Rating Slider
                    Slider(
                      value: _rating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _rating.toStringAsFixed(0),
                      activeColor: Colors.amber,
                      onChanged: (value) {
                        setState(() {
                          _rating = value;
                        });
                      },
                    ),
                    Text(
                      '${_rating.toInt()} out of 5 stars',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Review Text Section
              const Text(
                'Your Review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reviewController,
                maxLines: 8,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Tell others about your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write a review';
                  }
                  if (value.trim().length < 10) {
                    return 'Review must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit Review',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}