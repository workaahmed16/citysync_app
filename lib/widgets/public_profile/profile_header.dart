// lib/widgets/public_profile/profile_header.dart
import 'package:flutter/material.dart';
import '../../theme/colors.dart' as AppColors;

/// Profile header with cover and profile picture
class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileHeader({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = data['profilePhotoUrl'] ?? "https://picsum.photos/200";

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 160,
          decoration: const BoxDecoration(
            color: AppColors.kDarkBlue,
          ),
        ),
        Positioned(
          bottom: -50,
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.kWhite,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: NetworkImage(photoUrl),
            ),
          ),
        ),
      ],
    );
  }
}