import 'package:flutter/material.dart';
import '../theme/colors.dart' as AppColors;

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.kDarkBlue,
              AppColors.kDarkBlue.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.kWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore locations around you',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.kWhite.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}