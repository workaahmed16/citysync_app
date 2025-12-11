import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart' as AppColors;
import '../pages/public_profile.dart';

/// User profiles carousel - shows 4 users with consistent card design
class UserProfilesCarousel extends StatelessWidget {
  const UserProfilesCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Members',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.kDarkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect with other users',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.kDarkBlue.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal List
        SizedBox(
          height: 240,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(4) // Show only 4 users
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.kOrange,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: AppColors.kDarkBlue.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No users yet',
                          style: TextStyle(
                            color: AppColors.kDarkBlue.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Filter out current user and take only 4
              final users = snapshot.data!.docs
                  .where((doc) => doc.id != currentUserId)
                  .take(4)
                  .toList();

              if (users.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No other users yet',
                      style: TextStyle(
                        color: AppColors.kDarkBlue.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final userId = doc.id;
                  final name = data['name'] ?? 'Anonymous';
                  final profilePhotoUrl = data['profilePhotoUrl'];
                  final city = data['city'];
                  final country = data['country'];
                  final interests = data['interests'];

                  return _buildProfileCard(
                    context,
                    userId: userId,
                    name: name,
                    profilePhotoUrl: profilePhotoUrl,
                    city: city,
                    country: country,
                    interests: interests,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
      BuildContext context, {
        required String userId,
        required String name,
        String? profilePhotoUrl,
        String? city,
        String? country,
        String? interests,
      }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicProfilePage(userId: userId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Photo
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.kOrange.withOpacity(0.2),
                  backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                      ? NetworkImage(profilePhotoUrl)
                      : null,
                  child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                      ? Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.kOrange,
                  )
                      : null,
                ),

                const SizedBox(height: 12),

                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kDarkBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Location
                if (city != null || country != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.kOrange,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          city ?? country ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Interests snippet
                if (interests != null && interests.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.kOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      interests,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.kOrange,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}