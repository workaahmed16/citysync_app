import 'package:flutter/material.dart';
import '../services/matching_service.dart';
import '../theme/colors.dart' as AppColors;

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final MatchingService _matchingService = MatchingService();

  List<ProfileMatch>? _matches;
  bool _isLoading = false;
  String? _error;

  // Filter options
  double _minSimilarity = 0.3;
  double? _maxDistance;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matches = await _matchingService.findMatches(
        limit: 50,
        minSimilarityScore: _minSimilarity,
        maxDistanceKm: _maxDistance,
      );

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kDarkBlue,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.kOrange,
                ),
                onPressed: () {
                  setState(() => _showFilters = !_showFilters);
                },
              ),
            ],
          ),
          if (_showFilters) ...[
            const SizedBox(height: 16),

            // Similarity threshold slider
            Text(
              'Minimum Match Score: ${(_minSimilarity * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.kDarkBlue,
              ),
            ),
            Slider(
              value: _minSimilarity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: AppColors.kOrange,
              label: '${(_minSimilarity * 100).toInt()}%',
              onChanged: (value) {
                setState(() => _minSimilarity = value);
              },
            ),

            const SizedBox(height: 16),

            // Distance filter
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Max Distance: ${_maxDistance?.toInt() ?? "No limit"} km',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.kDarkBlue,
                    ),
                  ),
                ),
                if (_maxDistance != null)
                  TextButton(
                    onPressed: () {
                      setState(() => _maxDistance = null);
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            if (_maxDistance != null)
              Slider(
                value: _maxDistance!,
                min: 1,
                max: 500,
                divisions: 99,
                activeColor: AppColors.kOrange,
                label: '${_maxDistance!.toInt()} km',
                onChanged: (value) {
                  setState(() => _maxDistance = value);
                },
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kOrange.withOpacity(0.2),
                  foregroundColor: AppColors.kOrange,
                ),
                onPressed: () {
                  setState(() => _maxDistance = 50);
                },
                child: const Text('Enable Distance Filter'),
              ),

            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kOrange,
                  foregroundColor: AppColors.kWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _loadMatches,
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchCard(ProfileMatch match) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to profile detail page
          // Navigator.push(context, MaterialPageRoute(...));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile photo
              CircleAvatar(
                radius: 35,
                backgroundImage: match.profilePhotoUrl != null
                    ? NetworkImage(match.profilePhotoUrl!)
                    : const NetworkImage('https://picsum.photos/200'),
              ),
              const SizedBox(width: 16),

              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kDarkBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Match score badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getScoreColor(match.similarityScore),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(match.similarityScore * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (match.city != null || match.country != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.kOrange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${match.city ?? ''}${match.city != null && match.country != null ? ', ' : ''}${match.country ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (match.bio != null && match.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        match.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.5) return AppColors.kOrange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Matches',
          style: TextStyle(
            color: AppColors.kWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.kDarkBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.kWhite),
            onPressed: _isLoading ? null : _loadMatches,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMatches,
        color: AppColors.kOrange,
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: AppColors.kOrange,
          ),
        )
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading matches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kOrange,
                    foregroundColor: AppColors.kWhite,
                  ),
                  onPressed: _loadMatches,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        )
            : _matches == null || _matches!.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No matches found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or update your profile to find more matches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilterSection(),
            const SizedBox(height: 16),

            // Match count
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${_matches!.length} matches found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Match list
            ..._matches!.map((match) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMatchCard(match),
            )),
          ],
        ),
      ),
    );
  }
}