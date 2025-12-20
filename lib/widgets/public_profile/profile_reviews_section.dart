// lib/widgets/public_profile/profile_reviews_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../pages/reviews_page.dart';
import '../../theme/colors.dart' as AppColors;

/// Reviews section with Amazon-style star filter and pagination
class ProfileReviewsSection extends StatefulWidget {
  final String userId;
  final int? selectedStarFilter;
  final int currentPage;
  final int itemsPerPage;
  final VoidCallback onFilterPressed;
  final Function(int) onPageChanged;

  const ProfileReviewsSection({
    super.key,
    required this.userId,
    this.selectedStarFilter,
    this.currentPage = 1,
    this.itemsPerPage = 10,
    required this.onFilterPressed,
    required this.onPageChanged,
  });

  @override
  State<ProfileReviewsSection> createState() => _ProfileReviewsSectionState();
}

class _ProfileReviewsSectionState extends State<ProfileReviewsSection> {
  List<DocumentSnapshot>? _cachedReviews;

  @override
  void didUpdateWidget(ProfileReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _cachedReviews = null;
    }
  }

  String _formatReviewDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 DEBUG (Reviews): ProfileReviewsSection building with filter: ${widget.selectedStarFilter}');

    return Column(
      children: [
        // Section header with filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.rate_review, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('userId', isEqualTo: widget.userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Text(
                        'Reviews Written ($count)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      );
                    },
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: widget.onFilterPressed,
                icon: Icon(
                  widget.selectedStarFilter != null
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  color: AppColors.kOrange,
                  size: 18,
                ),
                label: Text(
                  widget.selectedStarFilter != null
                      ? '${widget.selectedStarFilter}★'
                      : 'Filter',
                  style: const TextStyle(
                    color: AppColors.kOrange,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Star filter bar (Amazon style)
        _buildStarFilterBar(),

        const SizedBox(height: 12),

        // Reviews list with pagination
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('userId', isEqualTo: widget.userId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            print('🟡 DEBUG (Reviews): StreamBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}');

            // Update cache when we get new data
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              _cachedReviews = snapshot.data!.docs;
              print('🟢 DEBUG (Reviews): Cache updated with ${_cachedReviews!.length} reviews');
            }

            // Use cached data if available
            if (_cachedReviews == null) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                print('🔴 DEBUG (Reviews): No data available');
                return _buildEmptyState();
              }
            }

            return _buildReviewsList(_cachedReviews!);
          },
        ),
      ],
    );
  }

  Widget _buildReviewsList(List<DocumentSnapshot> allReviews) {
    print('📋 DEBUG (Reviews): Building reviews list with ${allReviews.length} total reviews, filter: ${widget.selectedStarFilter}');

    // Apply filter
    List<DocumentSnapshot> reviews = allReviews;

    if (widget.selectedStarFilter != null) {
      print('🔍 DEBUG (Reviews): Applying filter for ${widget.selectedStarFilter} stars');
      final filterValue = widget.selectedStarFilter!;

      reviews = reviews.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = (data['rating'] ?? 0).toDouble();
        final roundedRating = rating == 0 ? 0 : rating.ceil();
        final matches = roundedRating == filterValue;

        print('   - Review rating $rating → $roundedRating, matches? $matches');

        return matches;
      }).toList();

      print('✅ DEBUG (Reviews): Filter complete. Matched ${reviews.length} reviews');

      if (reviews.isEmpty) {
        print('⚠️ DEBUG (Reviews): No matches, showing empty state');
        return _buildEmptyFilteredState();
      }
    }

    // Calculate pagination
    final totalReviews = reviews.length;
    final totalPages = (totalReviews / widget.itemsPerPage).ceil();
    final startIndex = (widget.currentPage - 1) * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(0, totalReviews);
    final paginatedReviews = reviews.sublist(startIndex, endIndex);

    print('📄 DEBUG (Reviews): Pagination - showing $startIndex to $endIndex of $totalReviews (${paginatedReviews.length} cards)');

    return Column(
      children: [
        // Results info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Showing ${startIndex + 1}-$endIndex of $totalReviews',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Review cards
        ...paginatedReviews.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final reviewData = doc.data() as Map<String, dynamic>;

          print('🎴 DEBUG (Reviews): Rendering card ${index + 1}/${paginatedReviews.length}');

          return _buildReviewCard(reviewData);
        }),

        // Pagination controls
        if (totalPages > 1) _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildStarFilterBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // Count reviews by star rating
        final reviews = snapshot.data!.docs;
        final Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

        for (var doc in reviews) {
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

  Widget _buildReviewCard(Map<String, dynamic> reviewData) {
    final locationId = reviewData['locationId'] ?? '';
    final rating = (reviewData['rating'] ?? 0).toDouble();
    final comment = reviewData['comment'] ?? reviewData['reviewText'] ?? '';
    final createdAt = reviewData['createdAt'] as Timestamp?;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .get(),
      builder: (context, locationSnapshot) {
        String locationName = 'Unknown Location';
        if (locationSnapshot.hasData && locationSnapshot.data!.exists) {
          final locData =
          locationSnapshot.data!.data() as Map<String, dynamic>;
          locationName = locData['name'] ?? 'Unknown Location';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
          elevation: 1,
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey[300]!,
              width: 0.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsPage(locationId: locationId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          locationName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      comment,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatReviewDate(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: widget.currentPage > 1
                ? () => widget.onPageChanged(widget.currentPage - 1)
                : null,
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
                (page >= widget.currentPage - 1 &&
                    page <= widget.currentPage + 1);

            if (!shouldShow) {
              if (page == widget.currentPage - 2 ||
                  page == widget.currentPage + 2) {
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
                    color: isCurrentPage
                        ? AppColors.kOrange
                        : Colors.transparent,
                    border: Border.all(
                      color: isCurrentPage
                          ? AppColors.kOrange
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$page',
                      style: TextStyle(
                        color: isCurrentPage
                            ? Colors.white
                            : AppColors.kDarkBlue,
                        fontWeight: isCurrentPage
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.currentPage < totalPages
                ? () => widget.onPageChanged(widget.currentPage + 1)
                : null,
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
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'No reviews yet',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.filter_alt_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No reviews with ${widget.selectedStarFilter} star${widget.selectedStarFilter! > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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