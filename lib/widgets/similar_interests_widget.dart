import 'package:flutter/material.dart';
import '../services/matching_service.dart';
import '../theme/colors.dart' as AppColors;
import '../pages/public_profile.dart';

class SimilarInterestsWidget extends StatefulWidget {
  const SimilarInterestsWidget({super.key});

  @override
  State<SimilarInterestsWidget> createState() => _SimilarInterestsWidgetState();
}

class _SimilarInterestsWidgetState extends State<SimilarInterestsWidget> {
  final MatchingService _matchingService = MatchingService();
  List<ProfileMatch>? _topMatches;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopMatches();
  }

  Future<void> _loadTopMatches() async {
    try {
      final matches = await _matchingService.findMatches(
        limit: 4,
        minSimilarityScore: 0.2,
        maxDistanceKm: null, // No geographic limit - searches globally
      );

      if (mounted) {
        setState(() {
          _topMatches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading similar interests: $e');
      if (mounted) {
        setState(() {
          _topMatches = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Users with Similar Interests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.kDarkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect with people like you',
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
          child: _isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: AppColors.kOrange,
            ),
          )
              : _topMatches == null || _topMatches!.isEmpty
              ? Center(
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
                    'No matches yet',
                    style: TextStyle(
                      color: AppColors.kDarkBlue.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Update your profile to find matches',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.kDarkBlue.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _topMatches!.length,
            itemBuilder: (context, index) {
              final match = _topMatches![index];
              return _buildMatchCard(match);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(ProfileMatch match) {
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
                builder: (context) => PublicProfilePage(userId: match.userId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Photo - NO BADGE
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.kOrange.withOpacity(0.2),
                  backgroundImage: match.profilePhotoUrl != null && match.profilePhotoUrl!.isNotEmpty
                      ? NetworkImage(match.profilePhotoUrl!)
                      : null,
                  child: match.profilePhotoUrl == null || match.profilePhotoUrl!.isEmpty
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
                  match.name,
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
                if (match.city != null || match.country != null)
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
                          match.city ?? match.country ?? '',
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
                if (match.interests != null && match.interests!.isNotEmpty)
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
                      match.interests!,
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