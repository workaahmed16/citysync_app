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

  /// 🔹 Helper function to recalculate and update the average rating (Option 2)
  Future<void> _updateLocationAverageRating(String locationId) async {
    final firestore = FirebaseFirestore.instance;

    // Get all reviews for this location
    final reviewsSnapshot = await firestore
        .collection('reviews')
        .where('locationId', isEqualTo: locationId)
        .get();

    double totalFromReviews = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalFromReviews += (doc['rating'] ?? 0).toDouble();
    }

    // Get the location’s existing (original) rating
    final locationDoc =
    await firestore.collection('locations').doc(locationId).get();

    if (!locationDoc.exists) return;

    double initialLocationRating = (locationDoc.data()?['rating'] ?? 0).toDouble();

    // Combine both sets of ratings
    double totalCombined = totalFromReviews + initialLocationRating;
    int totalCount = reviewsSnapshot.docs.length + 1; // +1 for location rating

    double average = totalCombined / totalCount;

    // Update the location’s rating
    await firestore
        .collection('locations')
        .doc(locationId)
        .update({'rating': average});
  }

  /// 🔹 Submits a new review
  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to submit a review');
      }

      String userName = currentUser.displayName ?? 'Anonymous User';
      String userAvatar = currentUser.photoURL ?? '';

      // If missing display name, try to fetch from users collection
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
        } catch (_) {
          userName = currentUser.email?.split('@')[0] ?? 'Anonymous User';
        }
      }

      // 🔹 Step 1: Add the new review document
      await FirebaseFirestore.instance.collection('reviews').add({
        'locationId': widget.locationId,
        'userId': currentUser.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'helpfulCount': 0,
        'helpfulBy': [],
      });

      // 🔹 Step 2: Recalculate and update the location’s average rating
      await _updateLocationAverageRating(widget.locationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

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

              // Review Text
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
