// lib/pages/public_profile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/public_profile/profile_header.dart';
import '../widgets/public_profile/profile_info_section.dart';
import '../widgets/public_profile/profile_locations_section.dart';
import '../widgets/public_profile/profile_reviews_section.dart';
import '../theme/colors.dart' as AppColors;

class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  // Locations filter state
  int? _selectedLocationsStarFilter;
  int _locationsCurrentPage = 1;
  final int _locationsItemsPerPage = 10;
  Key _locationsStreamKey = UniqueKey();

  // Reviews filter state
  int? _selectedReviewsStarFilter;
  int _reviewsCurrentPage = 1;
  final int _reviewsItemsPerPage = 10;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserProfile() async {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  Stream<QuerySnapshot> _getUserLocations() {
    Query query = FirebaseFirestore.instance
        .collection('locations')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true);

    return query.snapshots();
  }

  void _showStarFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Locations by Rating',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // All ratings option
              _buildFilterOption(
                context,
                rating: null,
                label: 'All Ratings',
                icon: Icons.star_border,
                isLocations: true,
              ),

              // Individual star ratings
              for (int i = 5; i >= 1; i--)
                _buildFilterOption(
                  context,
                  rating: i,
                  label: '$i Star${i > 1 ? 's' : ''}',
                  icon: Icons.star,
                  isLocations: true,
                ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewsStarFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Reviews by Rating',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // All ratings option
              _buildFilterOption(
                context,
                rating: null,
                label: 'All Ratings',
                icon: Icons.star_border,
                isLocations: false,
              ),

              // Individual star ratings
              for (int i = 5; i >= 1; i--)
                _buildFilterOption(
                  context,
                  rating: i,
                  label: '$i Star${i > 1 ? 's' : ''}',
                  icon: Icons.star,
                  isLocations: false,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
      BuildContext context, {
        required int? rating,
        required String label,
        required IconData icon,
        required bool isLocations,
      }) {
    final isSelected = isLocations
        ? _selectedLocationsStarFilter == rating
        : _selectedReviewsStarFilter == rating;

    return ListTile(
      leading: Icon(
        icon,
        color: rating != null ? Colors.amber : AppColors.kDarkBlue,
      ),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.kOrange)
          : null,
      onTap: () {
        setState(() {
          if (isLocations) {
            _selectedLocationsStarFilter = rating;
            _locationsCurrentPage = 1;
            _locationsStreamKey = UniqueKey();
          } else {
            _selectedReviewsStarFilter = rating;
            _reviewsCurrentPage = 1;
          }
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            color: AppColors.kWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.kDarkBlue,
        iconTheme: const IconThemeData(color: AppColors.kWhite),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.kOrange),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final data = snapshot.data!.data()!;

          return SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(data: data),
                const SizedBox(height: 60),
                ProfileInfoSection(data: data),
                const SizedBox(height: 30),
                const Divider(thickness: 1, height: 1),
                const SizedBox(height: 20),

                // Locations Section with Star Filter
                ProfileLocationsSection(
                  key: _locationsStreamKey,
                  userId: widget.userId,
                  locationsStream: _getUserLocations(),
                  selectedStarFilter: _selectedLocationsStarFilter,
                  currentPage: _locationsCurrentPage,
                  itemsPerPage: _locationsItemsPerPage,
                  onFilterPressed: _showStarFilterDialog,
                  onPageChanged: (page) {
                    setState(() => _locationsCurrentPage = page);
                  },
                ),

                const SizedBox(height: 30),
                const Divider(thickness: 1, height: 1),
                const SizedBox(height: 20),

                // Reviews Section with Star Filter
                ProfileReviewsSection(
                  userId: widget.userId,
                  selectedStarFilter: _selectedReviewsStarFilter,
                  currentPage: _reviewsCurrentPage,
                  itemsPerPage: _reviewsItemsPerPage,
                  onFilterPressed: _showReviewsStarFilterDialog,
                  onPageChanged: (page) {
                    setState(() => _reviewsCurrentPage = page);
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}