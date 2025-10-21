import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/reviews_list.dart';
import '../widgets/video_thumbnail_player.dart';
import '../services/location_delete_service.dart';
import 'add_review_page.dart';

class ReviewsPage extends StatelessWidget {
  final String locationId;

  const ReviewsPage({super.key, required this.locationId});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<void> _deleteLocation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: const Text(
          'Are you sure you want to delete this location? '
              'This will also delete all reviews. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await LocationDeleteService.deleteLocation(locationId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Go back to previous page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Location not found'),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unnamed Location';
        final description = data['description'] ?? '';
        final address = data['address'] ?? '';
        final rating = (data['rating'] ?? 0).toDouble();
        final lat = data['lat'] ?? 0.0;
        final lng = data['lng'] ?? 0.0;
        final createdAt = data['createdAt'] as Timestamp?;
        final photos = List<String>.from(data['photos'] ?? []);
        final videos = List<String>.from(data['videos'] ?? []);
        final locationOwnerId = data['userId'] ?? '';
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final isOwner = locationOwnerId == currentUserId && currentUserId.isNotEmpty;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero Header with Photo
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                actions: [
                  // Delete button for location owner
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () => _deleteLocation(context),
                      tooltip: 'Delete Location',
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                  background: photos.isNotEmpty
                      ? Image.network(
                    photos[0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.location_city,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                      : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[400]!,
                          Colors.blue[700]!,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.location_city,
                      size: 80,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating Card
                    if (rating > 0)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              ' / 5.0',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Address Section
                    if (address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.red),
                            title: const Text(
                              'Address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            subtitle: Text(
                              address,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Description Section
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Photos Gallery
                    if (photos.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: photos.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      photos[index],
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 150,
                                          height: 150,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Videos Section - UPDATED!
                    if (videos.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Videos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: videos.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: VideoThumbnailPlayer(
                                    videoUrl: videos[index],
                                    width: 150,
                                    height: 150,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Info Footer
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Added ${_formatDate(createdAt)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (lat != 0.0 && lng != 0.0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.pin_drop, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Divider
                    const Divider(height: 32, thickness: 1),

                    // Reviews Section with Real Count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('locationId', isEqualTo: locationId)
                            .snapshots(),
                        builder: (context, reviewSnapshot) {
                          final reviewCount = reviewSnapshot.data?.docs.length ?? 0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Reviews',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ReviewsList(locationId: locationId),
                              const SizedBox(height: 80), // Extra space for FAB
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('locationId', isEqualTo: locationId)
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              // Check if user already reviewed this location
              final hasReviewed = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              if (hasReviewed) {
                // User already reviewed - show a disabled button or nothing
                return FloatingActionButton.extended(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You have already reviewed this location'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Already Reviewed'),
                  backgroundColor: Colors.grey,
                );
              }

              // User hasn't reviewed yet - show normal button
              return FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddReviewPage(
                        locationId: locationId,
                        locationName: name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.rate_review),
                label: const Text('Write Review'),
                backgroundColor: Colors.blue,
              );
            },
          ),
        );
      },
    );
  }
}