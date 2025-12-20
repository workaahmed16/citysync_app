// lib/pages/public_profile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/public_profile/profile_header.dart';
import '../widgets/public_profile/profile_info_section.dart';
import '../widgets/public_profile/profile_reviews_section.dart';
import '../widgets/public_profile/profile_locations_section.dart';
import '../theme/colors.dart' as AppColors;

enum LocationSortBy { mostRecent, highestRated }

class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  LocationSortBy _sortBy = LocationSortBy.mostRecent;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserProfile() async {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  Stream<QuerySnapshot> _getUserLocations() {
    print('DEBUG: Fetching locations for userId: ${widget.userId}');
    print('DEBUG: Sort by: $_sortBy');

    Query query = FirebaseFirestore.instance
        .collection('locations')
        .where('userId', isEqualTo: widget.userId);

    return query.snapshots();
  }

  void _showSortOptions() {
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
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time, color: AppColors.kOrange),
                title: const Text('Most Recent'),
                trailing: _sortBy == LocationSortBy.mostRecent
                    ? const Icon(Icons.check, color: AppColors.kOrange)
                    : null,
                onTap: () {
                  setState(() => _sortBy = LocationSortBy.mostRecent);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.kOrange),
                title: const Text('Highest Rated'),
                trailing: _sortBy == LocationSortBy.highestRated
                    ? const Icon(Icons.check, color: AppColors.kOrange)
                    : null,
                onTap: () {
                  setState(() => _sortBy = LocationSortBy.highestRated);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(color: AppColors.kWhite, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.kDarkBlue,
        iconTheme: const IconThemeData(color: AppColors.kWhite),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.kOrange));
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
                ProfileReviewsSection(userId: widget.userId),
                const SizedBox(height: 30),
                const Divider(thickness: 1, height: 1),
                const SizedBox(height: 20),
                ProfileLocationsSection(
                  userId: widget.userId,
                  locationsStream: _getUserLocations(),
                  onSortPressed: _showSortOptions,
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