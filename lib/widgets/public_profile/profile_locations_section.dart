// lib/widgets/public_profile/profile_locations_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../pages/reviews_page.dart';
import '../../theme/colors.dart' as AppColors;

/// Locations section with Amazon-style star filter and pagination
class ProfileLocationsSection extends StatefulWidget {
  final String userId;
  final Stream<QuerySnapshot> locationsStream;
  final int? selectedStarFilter;
  final int currentPage;
  final int itemsPerPage;
  final VoidCallback onFilterPressed;
  final Function(int) onPageChanged;

  const ProfileLocationsSection({
    super.key,
    required this.userId,
    required this.locationsStream,
    required this.selectedStarFilter,
    required this.currentPage,
    required this.itemsPerPage,
    required this.onFilterPressed,
    required this.onPageChanged,
  });

  @override
  State<ProfileLocationsSection> createState() => _ProfileLocationsSectionState();
}

class _ProfileLocationsSectionState extends State<ProfileLocationsSection> {
  List<DocumentSnapshot>? _cachedLocations;

  @override
  void didUpdateWidget(ProfileLocationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear cache if userId changes
    if (oldWidget.userId != widget.userId) {
      _cachedLocations = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 DEBUG: ProfileLocationsSection building with filter: ${widget.selectedStarFilter}');

    return Column(
      children: [
        // Section header with filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('locations')
                    .where('userId', isEqualTo: widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(
                    'Locations ($count)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kDarkBlue,
                    ),
                  );
                },
              ),
              TextButton.icon(
                onPressed: widget.onFilterPressed,
                icon: Icon(
                  widget.selectedStarFilter != null ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: AppColors.kOrange,
                ),
                label: Text(
                  widget.selectedStarFilter != null
                      ? '${widget.selectedStarFilter}★'
                      : 'Filter',
                  style: const TextStyle(color: AppColors.kOrange),
                ),
              ),
            ],
          ),
        ),

        // Star filter bar (Amazon style)
        _buildStarFilterBar(),

        const SizedBox(height: 12),

        // Locations list with pagination - using single snapshot
        StreamBuilder<QuerySnapshot>(
          stream: widget.locationsStream,
          builder: (context, snapshot) {
            print('🟡 DEBUG: StreamBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, filter: ${widget.selectedStarFilter}');

            // Update cache when we get new data
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              _cachedLocations = snapshot.data!.docs;
              print('🟢 DEBUG: Cache updated with ${_cachedLocations!.length} locations');
            }

            // Use cached data if available
            if (_cachedLocations == null) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.kOrange),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                print('🔴 DEBUG: No data available');
                return _buildEmptyState();
              }
            }

            return _buildLocationsList(_cachedLocations!);
          },
        ),
      ],
    );
  }

  Widget _buildLocationsList(List<DocumentSnapshot> allLocations) {
    print('📋 DEBUG: Building locations list with ${allLocations.length} total locations, filter: ${widget.selectedStarFilter}');

    // Apply filter
    List<DocumentSnapshot> locations = allLocations;

    if (widget.selectedStarFilter != null) {
      print('🔍 DEBUG: Applying filter for ${widget.selectedStarFilter} stars');
      final filterValue = widget.selectedStarFilter!;

      locations = locations.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = (data['rating'] ?? 0).toDouble();
        final roundedRating = rating == 0 ? 0 : rating.ceil();
        final matches = roundedRating == filterValue;

        print('   - "${data['name']}": rating $rating → $roundedRating, matches? $matches');

        return matches;
      }).toList();

      print('✅ DEBUG: Filter complete. Matched ${locations.length} locations');

      if (locations.isEmpty) {
        print('⚠️ DEBUG: No matches, showing empty state');
        return _buildEmptyFilteredState();
      }
    }

    // Calculate pagination
    final totalLocations = locations.length;
    final totalPages = (totalLocations / widget.itemsPerPage).ceil();
    final startIndex = (widget.currentPage - 1) * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(0, totalLocations);
    final paginatedLocations = locations.sublist(startIndex, endIndex);

    print('📄 DEBUG: Pagination - showing $startIndex to $endIndex of $totalLocations (${paginatedLocations.length} cards)');

    return Column(
      children: [
        // Results info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Showing ${startIndex + 1}-$endIndex of $totalLocations',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Location cards
        ...paginatedLocations.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final data = doc.data() as Map<String, dynamic>;

          print('🎴 DEBUG: Rendering card ${index + 1}/${paginatedLocations.length}: ${data['name']}');

          return _buildLocationCard(doc.id, data);
        }),

        // Pagination controls
        if (totalPages > 1)
          _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildStarFilterBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('locations')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // Count locations by star rating
        final locations = snapshot.data!.docs;
        final Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

        for (var doc in locations) {
          final data = doc.data() as Map<String, dynamic>;
          final rating = (data['rating'] ?? 0).toDouble();
          if (rating > 0) {
            final roundedRating = rating.ceil().clamp(1, 5);
            starCounts[roundedRating] = (starCounts[roundedRating] ?? 0) + 1;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by rating',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kDarkBlue,
                ),
              ),
              const SizedBox(height: 8),
              for (int i = 5; i >= 1; i--)
                _buildStarFilterRow(i, starCounts[i] ?? 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarFilterRow(int stars, int count) {
    return InkWell(
      onTap: widget.onFilterPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String docId, Map<String, dynamic> data) {
    final locationName = data['name'] ?? 'Unnamed Location';
    final rating = (data['rating'] ?? 0).toDouble();
    final photos = List<String>.from(data['photos'] ?? []);
    final photoUrl = photos.isNotEmpty ? photos[0] : 'https://via.placeholder.com/150';
    final description = data['description'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewsPage(locationId: docId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.location_city, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kDarkBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    if (rating > 0)
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating.round() ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (rating == 0)
                      const Text(
                        'No rating yet',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: widget.currentPage > 1 ? () => widget.onPageChanged(widget.currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.kOrange,
            disabledColor: Colors.grey,
          ),

          const SizedBox(width: 8),

          ...List.generate(totalPages, (index) {
            final page = index + 1;
            final isCurrentPage = page == widget.currentPage;

            final shouldShow = page == 1 ||
                page == totalPages ||
                (page >= widget.currentPage - 1 && page <= widget.currentPage + 1);

            if (!shouldShow) {
              if (page == widget.currentPage - 2 || page == widget.currentPage + 2) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('...'),
                );
              }
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => widget.onPageChanged(page),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCurrentPage ? AppColors.kOrange : Colors.transparent,
                    border: Border.all(
                      color: isCurrentPage ? AppColors.kOrange : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$page',
                      style: TextStyle(
                        color: isCurrentPage ? Colors.white : AppColors.kDarkBlue,
                        fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 8),

          IconButton(
            onPressed: widget.currentPage < totalPages ? () => widget.onPageChanged(widget.currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.kOrange,
            disabledColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.explore_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No locations yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No locations with ${widget.selectedStarFilter} star${widget.selectedStarFilter! > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onFilterPressed,
              child: const Text('Clear filter'),
            ),
          ],
        ),
      ),
    );
  }
}