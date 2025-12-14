import 'package:flutter/material.dart';
import '../theme/colors.dart' as AppColors;

class HomeHeader extends StatelessWidget {
  final VoidCallback onMatchesTap;

  const HomeHeader({
    super.key,
    required this.onMatchesTap,
  });

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
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
                ),
                IconButton(
                  onPressed: onMatchesTap,
                  icon: const Icon(Icons.people_alt),
                  color: AppColors.kWhite,
                  iconSize: 28,
                  tooltip: 'Find Matches',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.kOrange,
                    padding: const EdgeInsets.all(12),
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