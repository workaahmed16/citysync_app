import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:myfirstflutterapp/widgets/add_location_popup.dart';
import 'dart:math' as math;

import '../theme/colors.dart' as AppColors;
import '../services/location_service.dart';
import '../widgets/search_bar.dart';
import '../widgets/map_view.dart';
import '../widgets/location_card.dart';
import '../widgets/user_profiles_carousel.dart';
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
  String _searchQuery = ''; // NEW: Search query state

  final _locationService = LocationService();
  final _auth = FirebaseAuth.instance;
  final _searchController = TextEditingController(); // NEW: Search controller

  @override
  void initState() {
    super.initState();
    _setupLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.currentUser != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Welcome!"),
            content: const Text("Tap on the map to review a location!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Cleanup
    super.dispose();
  }

  Future<void> _setupLocation() async {
    final result = await _locationService.updateUserLocation(context);

    if (result != null) {
      final city = result['city']!;
      final country = result['country']!;
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;

      print('🔍 DEBUG: LocationService result = $result');
      print('🔍 DEBUG: lat = $lat, lng = $lng');

      final latLng = await _locationService.geocodeCityCountry(city, country);
      print('🔍 DEBUG: geocoded latLng = $latLng');

      setState(() {
        _city = city;
        _country = country;
        _mapCenter = latLng ?? const LatLng(37.7749, -122.4194);
        _userLocation = (lat != null && lng != null)
            ? LatLng(lat, lng)
            : latLng ?? const LatLng(37.7749, -122.4194);

        print('🔍 DEBUG: _userLocation set to = $_userLocation');
      });
    } else {
      print('🔍 DEBUG: LocationService returned null');
      setState(() {
        _mapCenter = const LatLng(37.7749, -122.4194);
        _userLocation = const LatLng(37.7749, -122.4194);
      });
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final dLng = _degreesToRadians(point2.longitude - point1.longitude);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_degreesToRadians(point1.latitude)) *
            math.cos(_degreesToRadians(point2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
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

  // NEW: Check if location matches search query
  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();
    final name = (data['name'] ?? '').toString().toLowerCase();
    final description = (data['description'] ?? '').toString().toLowerCase();
    final address = (data['address'] ?? '').toString().toLowerCase();

    return name.contains(query) ||
        description.contains(query) ||
        address.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // Search Bar Section
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _itemsToShow = 10; // Reset pagination
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _itemsToShow = 10;
                          });
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),

            // Map Section
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('locations')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.kDarkBlue,
                        ),
                      );
                    }

                    final currentUserId = _auth.currentUser?.uid;
                    final pins = snapshot.data!.docs
                        .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _matchesSearch(data);
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
                        child: Icon(
                          Icons.location_pin,
                          color: pinColor,
                          size: 35,
                        ),
                      );
                    })
                        .toList();

                    return MapView(
                      center: _mapCenter,
                      pins: pins,
                      onTap: _handleMapTap,
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Radius Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show locations within ${_radiusKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 1.0,
                      max: 50.0,
                      divisions: 49,
                      onChanged: (value) {
                        setState(() => _radiusKm = value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Geofenced Locations List with Search Filter
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
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
                    return const Center(child: Text("No locations yet."));
                  }

                  // Filter by distance AND search query
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final lat = data['lat'] as double?;
                    final lng = data['lng'] as double?;

                    if (lat == null || lng == null || _userLocation == null) {
                      return false;
                    }

                    final locationPoint = LatLng(lat, lng);
                    final distance = _calculateDistance(_userLocation!, locationPoint);
                    final withinRadius = distance <= _radiusKm;
                    final matchesQuery = _matchesSearch(data);

                    return withinRadius && matchesQuery;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No locations within ${_radiusKm.toStringAsFixed(1)} km'
                                  : 'No locations match "$_searchQuery"',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Try increasing the radius'
                                  : 'Try a different search term',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final displayedDocs = filteredDocs.take(_itemsToShow).toList();
                  final hasMore = filteredDocs.length > _itemsToShow;

                  return Column(
                    children: [
                      ...displayedDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        final name = data['name'] ?? "Unnamed";
                        final description = data['description'] ?? "";
                        final address = data['address'] ?? "";
                        final lat = data['lat'] as double?;
                        final lng = data['lng'] as double?;

                        final displayDesc =
                        description.isNotEmpty ? description : address;

                        String distanceText = '';
                        if (lat != null && lng != null && _userLocation != null) {
                          final distance =
                          _calculateDistance(_userLocation!, LatLng(lat, lng));
                          distanceText = '${distance.toStringAsFixed(1)} km away';
                        }

                        return LocationCard(
                          title: name,
                          description: displayDesc,
                          placeId: doc.id,
                          distance: distanceText,
                        );
                      }).toList(),

                      if (hasMore)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _itemsToShow += 10);
                            },
                            icon: const Icon(Icons.expand_more),
                            label: Text(
                              'Load More (${filteredDocs.length - _itemsToShow} remaining)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kDarkBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // User Profiles Carousel
            SliverToBoxAdapter(child: UserProfilesCarousel()),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}