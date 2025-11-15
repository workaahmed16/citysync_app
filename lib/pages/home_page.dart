import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:myfirstflutterapp/widgets/add_location_popup.dart';

// Theme and Services
import '../theme/colors.dart' as AppColors;
import '../services/location_service.dart';
import '../services/geofence_service.dart';
import '../services/location_search_service.dart';

// Widgets
import '../widgets/location_search_widget.dart';
import '../widgets/map_view.dart';
import '../widgets/location_card.dart';
import '../widgets/user_profiles_carousel.dart';

// Pages
import 'profile_page.dart';
import 'reviews_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  LatLng? _mapCenter;
  LatLng? _userLocation;
  String? _city, _country;
  double _radiusKm = 5.0;
  int _itemsToShow = 10;
  String _searchQuery = '';

  final _locationService = LocationService();
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  Future<void> _setupLocation() async {
    final result = await _locationService.updateUserLocation(context);

    if (result != null) {
      final city = result['city'] as String?;
      final country = result['country'] as String?;
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;

      setState(() {
        _city = city;
        _country = country;
        // Use coordinates directly from LocationService
        if (lat != null && lng != null) {
          _mapCenter = LatLng(lat, lng);
          _userLocation = LatLng(lat, lng);
          print("Map centered at: $lat, $lng");
        } else {
          // Fallback only if no coordinates available
          _mapCenter = const LatLng(37.7749, -122.4194);
          _userLocation = const LatLng(37.7749, -122.4194);
          print("No coordinates available, using default San Francisco");
        }
      });
    } else {
      setState(() {
        _mapCenter = const LatLng(37.7749, -122.4194);
        _userLocation = const LatLng(37.7749, -122.4194);
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _handleMapTap(LatLng latlng) {
    AddLocationPopup.show(context, prefillLatLng: latlng);
  }

  void _handlePinTap(String placeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsPage(locationId: placeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.kDarkBlue,
        selectedItemColor: AppColors.kOrange,
        unselectedItemColor: AppColors.kWhite,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with greeting
            SliverToBoxAdapter(
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
            ),

            // Search Bar
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  LocationSearchWidget(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _itemsToShow = 10;
                      });
                    },
                  ),
                ]),
              ),
            ),

            // Radius Control Card
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.kOrange.withOpacity(0.1),
                            AppColors.kOrange.withOpacity(0.05),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Search Radius',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                      color: AppColors.kDarkBlue
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_radiusKm.toStringAsFixed(1)} km',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                      color: AppColors.kOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.kOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: AppColors.kOrange,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 6,
                              thumbShape: RoundSliderThumbShape(
                                elevation: 4,
                                enabledThumbRadius: 12,
                              ),
                            ),
                            child: Slider(
                              value: _radiusKm,
                              min: 1.0,
                              max: 50.0,
                              divisions: 49,
                              activeColor: AppColors.kOrange,
                              inactiveColor:
                              AppColors.kDarkBlue.withOpacity(0.1),
                              onChanged: (value) {
                                setState(() => _radiusKm = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Map Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 312,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('locations')
                            .snapshots(),
                        builder: (context, snapshot) {
                          // Show map even if there's no data or an error
                          final currentUserId = _auth.currentUser?.uid;
                          final pins = <Marker>[];

                          // Only process pins if we have data
                          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                            pins.addAll(
                              snapshot.data!.docs
                                  .where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                // Filter out documents with null coordinates
                                final lat = data['lat'];
                                final lng = data['lng'];
                                if (lat == null || lng == null) return false;

                                return LocationSearchService.matchesSearch(
                                    data, _searchQuery);
                              })
                                  .map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final lat = data['lat'] as double;
                                final lng = data['lng'] as double;
                                final ownerId = data['userId'] as String?;

                                final pinColor = (ownerId == currentUserId)
                                    ? Colors.blue
                                    : AppColors.kOrange;

                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () => _handlePinTap(doc.id),
                                    child: Icon(
                                      Icons.location_pin,
                                      color: pinColor,
                                      size: 35,
                                    ),
                                  ),
                                );
                              })
                                  .toList(),
                            );
                          }

                          return MapView(
                            center: _mapCenter,
                            pins: pins,
                            onTap: _handleMapTap,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Locations List
            SliverPadding(
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
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
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
                                    'No locations yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                      color: AppColors.kDarkBlue
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final lat = data['lat'] as double?;
                          final lng = data['lng'] as double?;

                          if (lat == null ||
                              lng == null ||
                              _userLocation == null) {
                            return false;
                          }

                          final locationPoint = LatLng(lat, lng);
                          final withinRadius =
                          GeofenceService.isWithinRadius(
                            _userLocation!,
                            locationPoint,
                            _radiusKm,
                          );
                          final matchesQuery =
                          LocationSearchService.matchesSearch(
                              data, _searchQuery);

                          return withinRadius && matchesQuery;
                        }).toList();

                        if (filteredDocs.isEmpty) {
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
                                  _searchQuery.isEmpty
                                      ? 'No locations within ${_radiusKm.toStringAsFixed(1)} km'
                                      : 'No results for "$_searchQuery"',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                    color: AppColors.kDarkBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Increase the search radius'
                                      : 'Try a different search term',
                                  style: TextStyle(
                                    color:
                                    AppColors.kDarkBlue.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final displayedDocs =
                        filteredDocs.take(_itemsToShow).toList();
                        final hasMore = filteredDocs.length > _itemsToShow;

                        if (index == 0) {
                          return Column(
                            children: [
                              ...displayedDocs.map((doc) {
                                final data =
                                doc.data() as Map<String, dynamic>;

                                final name = data['name'] ?? "Unnamed";
                                final description =
                                    data['description'] ?? "";
                                final address = data['address'] ?? "";
                                final lat = data['lat'] as double?;
                                final lng = data['lng'] as double?;

                                final displayDesc = description.isNotEmpty
                                    ? description
                                    : address;

                                String distanceText = '';
                                if (lat != null &&
                                    lng != null &&
                                    _userLocation != null) {
                                  final distance =
                                  GeofenceService.calculateDistance(
                                    _userLocation!,
                                    LatLng(lat, lng),
                                  );
                                  distanceText = GeofenceService
                                      .getDistanceString(distance);
                                }

                                return Padding(
                                  padding:
                                  const EdgeInsets.only(bottom: 12),
                                  child: LocationCard(
                                    title: name,
                                    description: displayDesc,
                                    placeId: doc.id,
                                    distance: distanceText,
                                  ),
                                );
                              }).toList(),
                              if (hasMore)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(
                                              () => _itemsToShow += 10);
                                    },
                                    icon: const Icon(
                                        Icons.expand_more),
                                    label: Text(
                                      'Load More (${filteredDocs.length - _itemsToShow} remaining)',
                                    ),
                                    style: ElevatedButton
                                        .styleFrom(
                                      backgroundColor:
                                      AppColors.kOrange,
                                      foregroundColor:
                                      AppColors.kWhite,
                                      padding: const EdgeInsets
                                          .symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            12),
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
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // User Profiles Carousel
            SliverToBoxAdapter(child: UserProfilesCarousel()),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}