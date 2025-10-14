import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/public_profile.dart';
import '../theme/colors.dart' as AppColors;

/// User profiles carousel with improved visual design
/// - Maintains core functionality (tap to view public profile)
/// - Filters out current user
/// - Real-time Firestore updates
class UserProfilesCarousel extends StatelessWidget {
  final double height;

  const UserProfilesCarousel({
    super.key,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect with Friends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.kDarkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'See who\'s exploring nearby',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.kDarkBlue.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Carousel
        SizedBox(
          height: height + 30,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No users found",
                    style: TextStyle(
                      color: AppColors.kDarkBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              // Filter out current user
              final users = snapshot.data!.docs
                  .where((doc) => doc.id != currentUserId)
                  .toList();

              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    "No other users yet",
                    style: TextStyle(color: AppColors.kDarkBlue),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final userData = userDoc.data() as Map<String, dynamic>;

                  final photoUrl = userData['profilePhotoUrl'] ??
                      'assets/default_avatar.png';
                  final userName = userData['name'] ?? "Unknown";

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PublicProfilePage(userId: userDoc.id),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          // Avatar with gradient border
                          Container(
                            width: height,
                            height: height,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.kOrange,
                                  AppColors.kOrange.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.kOrange.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                backgroundColor: AppColors.kWhite,
                                backgroundImage: photoUrl.startsWith('http')
                                    ? NetworkImage(photoUrl)
                                    : AssetImage(photoUrl) as ImageProvider,
                                child: photoUrl.startsWith('http')
                                    ? null
                                    : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.kDarkBlue
                                        .withOpacity(0.1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      userName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.kOrange,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Username
                          SizedBox(
                            width: height,
                            child: Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kDarkBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}