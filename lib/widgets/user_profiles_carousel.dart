import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/public_profile.dart';

// 🎨 App color theme constants
const Color kDarkBlue = Color(0xFF0D47A1);
const Color kOrange = Color(0xFFFF6F00);
const Color kWhite = Colors.white;

/// 🚀 A horizontally scrollable carousel of user profile pictures
/// Designed to look premium & clean on both Android and iOS.
/// - Uses gradient rings around avatars
/// - Shows usernames below each profile
/// - Smooth shadow and glow for depth
/// - Fully real-time using Firestore snapshots
class UserProfilesCarousel extends StatelessWidget {
  final double height;

  const UserProfilesCarousel({
    super.key,
    this.height = 120, // Default avatar size
  });

  @override
  Widget build(BuildContext context) {
    // 🔑 Get the currently logged-in user's UID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return SizedBox(
      height: height + 30, // Extra space for username text
      child: StreamBuilder<QuerySnapshot>(
        // 📡 Listen to Firestore collection `users` in real-time
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // ⏳ Show loading spinner while fetching
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // ❌ Show message when no users are found
            return const Center(
              child: Text(
                "No users found",
                style: TextStyle(color: kDarkBlue, fontWeight: FontWeight.bold),
              ),
            );
          }

          // 👥 Filter out the current logged-in user
          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId)
              .toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal, // 📌 Scroll left-to-right
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;

              // 🖼️ Use profile photo if exists, otherwise fallback avatar
              final photoUrl = userData['profilePhotoUrl'] ??
                  'assets/default_avatar.png';

              final userName = userData['name'] ?? "Unknown";

              return GestureDetector(
                onTap: () {
                  // 📍 Navigate to that user's public profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfilePage(userId: userDoc.id),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      // 👤 Circular profile picture with gradient ring + glow
                      Container(
                        width: height,
                        height: height,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [kDarkBlue, kOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(2, 4),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0), // 🌟 Border thickness
                          child: CircleAvatar(
                            radius: (height / 2) - 6,
                            backgroundColor: kWhite,
                            backgroundImage: photoUrl.startsWith('http')
                                ? NetworkImage(photoUrl)
                                : AssetImage(photoUrl) as ImageProvider,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6), // 🪜 Spacing below avatar

                      // 📝 Username under profile picture
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kDarkBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
