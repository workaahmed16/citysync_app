// lib/widgets/public_profile/profile_info_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/colors.dart' as AppColors;

/// Profile information section including name, bio, location, and details
class ProfileInfoSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileInfoSection({
    super.key,
    required this.data,
  });

  Future<void> _launchInstagram(String handle) async {
    final url = Uri.parse("https://instagram.com/$handle");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch Instagram");
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.kOrange),
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

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? "Unknown";
    final bio = data['bio'] ?? "No bio yet";
    final location = data['location'] ?? "Unknown";
    final age = data['age']?.toString() ?? "";
    final city = data['city'] ?? "";
    final zip = data['zip'] ?? "";
    final interests = data['interests'] ?? "";
    final instagram = data['instagram'] ?? "";

    return Column(
      children: [
        // Name
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.kDarkBlue,
          ),
        ),
        const SizedBox(height: 6),

        // Bio
        Text(
          bio,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 6),

        // Location
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.kOrange),
            const SizedBox(width: 4),
            Text(
              location,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Extra profile details
        if (age.isNotEmpty) _infoRow(Icons.cake, "Age: $age"),
        if (city.isNotEmpty) _infoRow(Icons.location_city, "City: $city"),
        if (zip.isNotEmpty) _infoRow(Icons.local_post_office, "Zip: $zip"),
        if (interests.isNotEmpty) _infoRow(Icons.star, "Interests: $interests"),

        const SizedBox(height: 20),

        // Instagram button
        if (instagram.isNotEmpty)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kOrange,
              foregroundColor: AppColors.kWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _launchInstagram(instagram),
            icon: const Icon(Icons.camera_alt),
            label: const Text("View Instagram"),
          ),
      ],
    );
  }
}