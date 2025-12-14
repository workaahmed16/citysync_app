import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart' as AppColors;
import '../services/geofence_service.dart';
import '../services/location_search_service.dart';
import '../widgets/location_card.dart';

class HomeLocationsList extends StatelessWidget {
  final LatLng? userLocation;
  final double radiusKm;
  final String searchQuery;
  final int itemsToShow;
  final VoidCallback onLoadMore;

  const HomeLocationsList({
    super.key,
    required this.userLocation,
    required this.radiusKm,
    required this.searchQuery,
    required this.itemsToShow,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('locations')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
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

  Widget _buildEmptyFiltered(BuildContext context) {
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
              Icons.location_off,
              size: 64,
              color: AppColors.kOrange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No locations within ${radiusKm.toStringAsFixed(1)} km'
                : 'No results for "$searchQuery"',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.kDarkBlue,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Increase the search radius'
                : 'Try a different search term',
            style: TextStyle(
              color: AppColors.kDarkBlue.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}