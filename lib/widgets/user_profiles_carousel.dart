import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 To get the logged-in user
import '../pages/public_profile.dart';

class UserProfilesCarousel extends StatelessWidget {
  final double height;

  const UserProfilesCarousel({
    super.key,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user's UID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return SizedBox(
      height: height,
      child: StreamBuilder<QuerySnapshot>(
        // Listen to all users in Firestore
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          // Get all users but filter out the current logged-in user
          final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index]; // 👈 Each Firestore user document
              final userData = userDoc.data() as Map<String, dynamic>;

              // Use profilePhotoUrl if available, otherwise default avatar
              final photoUrl = userData['profilePhotoUrl'] ??
                  'assets/default_avatar.png';

              return GestureDetector(
                onTap: () {
                  // Navigate to the PublicProfilePage with this user's ID
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfilePage(userId: userDoc.id),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: height,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      // If it's a URL (http/https), use NetworkImage
                      // Otherwise, use a local asset (default avatar)
                      image: photoUrl.startsWith('http')
                          ? NetworkImage(photoUrl)
                          : AssetImage(photoUrl) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(2, 2),
                      )
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
