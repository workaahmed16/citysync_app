import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart' as AppColors;
import '../services/location_matching_service.dart';
import '../services/geofence_service.dart';
import '../services/location_search_service.dart';
import '../widgets/location_card.dart';

class HomeLocationsList extends StatelessWidget {
  final LatLng? userLocation;
  final double radiusKm;
  final String searchQuery;
  final int itemsToShow;
  final bool useSmartMatching;
  final VoidCallback onLoadMore;

  const HomeLocationsList({
    super.key,
    required this.userLocation,
    required this.radiusKm,
    required this.searchQuery,
    required this.itemsToShow,
    required this.useSmartMatching,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(context, 'Loading your location...'),
      );
    }

    // Create a unique key based on parameters to force rebuild when they change
    final searchKey = '$radiusKm-$searchQuery-${userLocation!.latitude}-${userLocation!.longitude}-$useSmartMatching';

    // Use smart matching or radius-only mode
    if (useSmartMatching) {
      return _buildSmartMatchingList(context, searchKey);
    } else {
      return _buildRadiusOnlyList(context, searchKey);
    }
  }

  Widget _buildSmartMatchingList(BuildContext context, String searchKey) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return FutureBuilder<List<LocationMatch>>(
              key: ValueKey(searchKey), // Force rebuild when parameters change
              future: LocationMatchingService().findMatchingLocations(
                userLocation: userLocation!,
                radiusKm: radiusKm,
                limit: 5, // Top 5 matching locations
                minSimilarityScore: 0.2,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.kOrange,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error loading locations',
                            style: TextStyle(
                              color: AppColors.kDarkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.kDarkBlue.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final matches = snapshot.data ?? [];

                if (matches.isEmpty) {
                  return _buildEmptyFiltered(context);
                }

                // Apply search filter
                final filteredMatches = searchQuery.isEmpty
                    ? matches
                    : matches.where((match) {
                  final query = searchQuery.toLowerCase();
                  final name = match.name.toLowerCase();
                  final description = (match.description ?? '').toLowerCase();
                  final address = (match.address ?? '').toLowerCase();
                  return name.contains(query) ||
                      description.contains(query) ||
                      address.contains(query);
                }).toList();

                if (filteredMatches.isEmpty) {
                  return _buildEmptyFiltered(context, showSearchMessage: true);
                }

                final displayedMatches = filteredMatches.take(itemsToShow).toList();
                final hasMore = filteredMatches.length > itemsToShow;

                if (index == 0) {
                  return Column(
                    children: [
                      // Total locations count with FutureBuilder
                      FutureBuilder<int>(
                        future: _getTotalLocationsCount(),
                        builder: (context, countSnapshot) {
                          final totalCount = countSnapshot.data ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.kOrange.withOpacity(0.1),
                                  AppColors.kOrange.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.kOrange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.kOrange,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Top ${displayedMatches.length} matched locations out of $totalCount total',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.kDarkBlue.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Location cards
                      ...displayedMatches.map((match) {
                        final displayDesc = match.description?.isNotEmpty == true
                            ? match.description!
                            : match.address ?? '';

                        final distanceText = GeofenceService.getDistanceString(match.distanceKm);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LocationCard(
                            title: match.name,
                            description: displayDesc,
                            placeId: match.locationId,
                            distance: distanceText,
                          ),
                        );
                      }),

                      if (hasMore)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton.icon(
                            onPressed: onLoadMore,
                            icon: const Icon(Icons.expand_more),
                            label: Text(
                              'Load More (${filteredMatches.length - itemsToShow} remaining)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kOrange,
                              foregroundColor: AppColors.kWhite,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
          childCount: 1,
        ),
      ),
    );
  }

  Widget _buildRadiusOnlyList(BuildContext context, String searchKey) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return StreamBuilder<QuerySnapshot>(
              key: ValueKey(searchKey),
              stream: FirebaseFirestore.instance
                  .collection('locations')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.kOrange,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return _buildEmptyState(context, 'No locations yet');
                }

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final lat = data['lat'] as double?;
                  final lng = data['lng'] as double?;

                  if (lat == null || lng == null || userLocation == null) {
                    return false;
                  }

                  final locationPoint = LatLng(lat, lng);
                  final withinRadius = GeofenceService.isWithinRadius(
                    userLocation!,
                    locationPoint,
                    radiusKm,
                  );
                  final matchesQuery = LocationSearchService.matchesSearch(
                      data, searchQuery);

                  return withinRadius && matchesQuery;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildEmptyFiltered(context);
                }

                final displayedDocs = filteredDocs.take(itemsToShow).toList();
                final hasMore = filteredDocs.length > itemsToShow;

                if (index == 0) {
                  return Column(
                    children: [
                      // Info banner for radius mode
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.kDarkBlue.withOpacity(0.1),
                              AppColors.kDarkBlue.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.kDarkBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.kDarkBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Showing ${displayedDocs.length} of ${filteredDocs.length} nearby locations',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.kDarkBlue.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ...displayedDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? "Unnamed";
                        final description = data['description'] ?? "";
                        final address = data['address'] ?? "";
                        final lat = data['lat'] as double?;
                        final lng = data['lng'] as double?;

                        final displayDesc = description.isNotEmpty
                            ? description
                            : address;

                        String distanceText = '';
                        if (lat != null &&
                            lng != null &&
                            userLocation != null) {
                          final distance = GeofenceService.calculateDistance(
                            userLocation!,
                            LatLng(lat, lng),
                          );
                          distanceText = GeofenceService.getDistanceString(distance);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LocationCard(
                            title: name,
                            description: displayDesc,
                            placeId: doc.id,
                            distance: distanceText,
                          ),
                        );
                      }),
                      if (hasMore)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton.icon(
                            onPressed: onLoadMore,
                            icon: const Icon(Icons.expand_more),
                            label: Text(
                              'Load More (${filteredDocs.length - itemsToShow} remaining)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kDarkBlue,
                              foregroundColor: AppColors.kWhite,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
          childCount: 1,
        ),
      ),
    );
  }

  Future<int> _getTotalLocationsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('locations')
        .get();
    return snapshot.docs.length;
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: AppColors.kOrange.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.kDarkBlue.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFiltered(BuildContext context, {bool showSearchMessage = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.kOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              showSearchMessage ? Icons.search_off : Icons.location_off,
              size: 64,
              color: AppColors.kOrange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            showSearchMessage
                ? 'No results for "$searchQuery"'
                : 'No matching locations within ${radiusKm.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.kDarkBlue,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            showSearchMessage
                ? 'Try a different search term'
                : 'Try increasing the radius or update your profile to find more matches',
            style: TextStyle(
              color: AppColors.kDarkBlue.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}