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
  final _instagramController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  /// Recalculates the average rating for a location based on base rating + all reviews
  Future<void> _recalculateLocationRating() async {
    try {
      // Get the location document to fetch the base rating
      final locationDoc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(widget.locationId)
          .get();

      if (!locationDoc.exists) {
        debugPrint('❌ Location document not found');
        return;
      }

      final locationData = locationDoc.data() as Map<String, dynamic>;

      // Use baseRating if it exists, otherwise use current rating as fallback
      final baseRating = locationData.containsKey('baseRating')
          ? (locationData['baseRating'] as num).toDouble()
          : (locationData['rating'] as num? ?? 0).toDouble();

      if (!locationData.containsKey('baseRating')) {
        debugPrint('⚠️ WARNING: baseRating not found for location ${widget.locationId}. Using current rating as fallback.');
      }

      // Get all reviews for this location
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('locationId', isEqualTo: widget.locationId)
          .get();

      // Calculate average: base rating + all review ratings
      double totalRating = baseRating;
      int totalCount = 1; // Base rating counts as 1

      for (var doc in reviewsSnapshot.docs) {
        final review = doc.data();
        final reviewRating = (review['rating'] as num? ?? 0).toDouble();
        totalRating += reviewRating;
        totalCount++;
      }

      final newRating = totalRating / totalCount;

      // Update only the current rating (never overwrite baseRating)
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(widget.locationId)
          .update({'rating': newRating});

      debugPrint('✅ Rating recalculated: $newRating (base: $baseRating + ${reviewsSnapshot.docs.length} reviews)');
    } catch (e) {
      debugPrint('❌ Error recalculating rating: $e');
    }
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

      // Validate Instagram URL if provided
      final instagramUrl = _instagramController.text.trim();
      if (instagramUrl.isNotEmpty && !instagramUrl.contains('instagram.com')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid Instagram URL'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
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

      // Build review data - FIX: Remove empty array and ensure proper types
      final reviewData = <String, dynamic>{
        'locationId': widget.locationId,
        'userId': currentUser.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': _rating, // Keep as double
        'reviewText': _reviewController.text.trim(),
        'comment': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'helpfulCount': 0,
        // FIX: Don't include helpfulBy as empty array - add it later when needed
      };

      // Add Instagram URL if provided
      if (instagramUrl.isNotEmpty) {
        reviewData['instagramPostUrl'] = instagramUrl;
      }

      // Add review to top-level reviews collection
      debugPrint('📝 Submitting review data: $reviewData');

      await FirebaseFirestore.instance
          .collection('reviews')
          .add(reviewData);

      debugPrint('✅ Review added successfully');

      // Wait a moment before recalculating to avoid race conditions
      await Future.delayed(const Duration(milliseconds: 500));

      // Recalculate the location's rating after adding review
      await _recalculateLocationRating();

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
    } catch (e, stackTrace) {
      debugPrint('❌ Error submitting review: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: ${e.toString()}'),
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
              const SizedBox(height: 24),

              // Instagram Post URL Section
              const Text(
                'Instagram Post (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _instagramController,
                decoration: InputDecoration(
                  labelText: "Instagram Post URL",
                  hintText: "https://instagram.com/p/...",
                  prefixIcon: Icon(Icons.camera_alt, color: Colors.pink[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  helperText: "Link your Instagram post about this place",
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.url,
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