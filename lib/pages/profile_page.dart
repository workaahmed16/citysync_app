import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ import firebase auth
import 'edit_profile_page.dart';
import 'home_page.dart';
import 'login_page.dart'; // make sure this exists
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No logged-in user");
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final data = snapshot.data!.data()!;
          final name = data['name'] ?? "Unknown";
          final bio = data['bio'] ?? "No bio yet";
          final location = data['location'] ?? "Unknown";
          final photoUrl = data['photoUrl'] ?? "https://picsum.photos/200";

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- Cover + Profile Picture ---
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage("https://picsum.photos/600/300"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage(photoUrl),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // --- Dynamic Profile Info ---
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(bio, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Edit Profile button (still works) ---
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfilePage()),
                    );
                  },
                  child: const Text("Edit Profile"),
                ),

                const SizedBox(height: 30),
                const Divider(),

                // --- Logout ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Log Out"),
                    onPressed: () => _logout(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
