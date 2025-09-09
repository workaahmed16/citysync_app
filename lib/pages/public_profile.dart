// public_profile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// 🎨 Color Scheme
const Color kDarkBlue = Color(0xFF0D47A1);
const Color kOrange = Color(0xFFFF9800);
const Color kWhite = Colors.white;

class PublicProfilePage extends StatelessWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserProfile() async {
    return FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  Future<void> _launchInstagram(String handle) async {
    final url = Uri.parse("https://instagram.com/$handle");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch Instagram");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
        backgroundColor: kDarkBlue,
        iconTheme: const IconThemeData(color: kWhite),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kOrange));
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
          final age = data['age']?.toString() ?? "";
          final city = data['city'] ?? "";
          final zip = data['zip'] ?? "";
          final interests = data['interests'] ?? "";
          final instagram = data['instagram'] ?? "";
          final photoUrl =
              data['profilePhotoUrl'] ?? "https://picsum.photos/200";

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- Cover + Profile Picture ---
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 160,
                      decoration: const BoxDecoration(
                        color: kDarkBlue,
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: kWhite,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage(photoUrl),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // --- Profile Info ---
                Text(name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue)),
                const SizedBox(height: 6),
                Text(bio,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: kOrange),
                    const SizedBox(width: 4),
                    Text(location,
                        style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Extra profile details ---
                if (age.isNotEmpty)
                  _infoRow(Icons.cake, "Age: $age"),
                if (city.isNotEmpty)
                  _infoRow(Icons.location_city, "City: $city"),
                if (zip.isNotEmpty)
                  _infoRow(Icons.local_post_office, "Zip: $zip"),
                if (interests.isNotEmpty)
                  _infoRow(Icons.star, "Interests: $interests"),

                const SizedBox(height: 20),

                // --- Instagram button ---
                if (instagram.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _launchInstagram(instagram),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("View Instagram"),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
