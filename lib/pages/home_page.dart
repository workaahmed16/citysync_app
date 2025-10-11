import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:myfirstflutterapp/widgets/add_location_popup.dart';
import 'dart:math' as math;

// 🔹 App-specific imports
import '../theme/colors.dart' as AppColors;
import '../services/location_service.dart';
import '../widgets/search_bar.dart';
import '../widgets/map_view.dart';
import '../widgets/location_card.dart';
import '../widgets/user_profiles_carousel.dart';
import 'profile_page.dart';
import 'reviews_page.dart';

// ===============================================
// HOME PAGE WIDGET
// This is the main "landing screen" of your app
// ===============================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ===============================================
// STATE CLASS FOR HOMEPAGE
// ===============================================
class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  LatLng? _mapCenter;
  LatLng? _userLocation; // 🔹 Store user's actual location
  String? _city, _country;
  double _radiusKm = 5.0; // 🔹 Geofence radius in kilometers
  int _itemsToShow = 10; // 🔹 Pagination: show 10 at a time

  final _locationService = LocationService();
  final _auth = FirebaseAuth.instance;

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

  // ===============================================
  // SETUP LOCATION
  // Gets user location and sets map center
  // ===============================================
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
        // 🔹 Store user's actual location if available
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

  // ===============================================
  // HAVERSINE FORMULA
  // Calculates distance between two lat/lng points
  // Returns distance in kilometers
  // ===============================================
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

  // ===============================================
  // BOTTOM NAVIGATION HANDLER
  // ===============================================
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

  // ===============================================
  // ADD PIN HELPER
  // ===============================================
  void _handleMapTap(LatLng latlng) {
    AddLocationPopup.show(context, prefillLatLng: latlng);
  }

  // ===============================================
  // BUILD METHOD
  // ===============================================
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
            // ===============================================
            // SEARCH BAR SECTION
            // ===============================================
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SearchBarWidget(),
                  const SizedBox(height: 12),
                ]),
              ),
            ),

            // ===============================================
            // MAP SECTION
            // ===============================================
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
                    final pins = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final lat = data['lat'] as double;
                      final lng = data['lng'] as double;
                      final ownerId = data['userId'] as String?;

                      final pinColor =
                      (ownerId == currentUserId) ? Colors.blue : AppColors.kOrange;

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
                    }).toList();

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

            // ===============================================
            // RADIUS SELECTOR
            // 🔹 Let user adjust geofence radius
            // ===============================================
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

            // ===============================================
            // GEOFENCED LOCATIONS LIST
            // 🔹 Filters locations based on distance
            // ===============================================
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

                  // 🔹 Filter locations by distance
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final lat = data['lat'] as double?;
                    final lng = data['lng'] as double?;

                    if (lat == null || lng == null || _userLocation == null) {
                      print('🔍 DEBUG: Skipping doc ${doc.id} - lat=$lat, lng=$lng, _userLocation=$_userLocation');
                      return false;
                    }

                    final locationPoint = LatLng(lat, lng);
                    final distance = _calculateDistance(_userLocation!, locationPoint);

                    print('🔍 DEBUG: Doc ${doc.id} - distance=$distance km, radius=$_radiusKm km, included=${distance <= _radiusKm}');

                    return distance <= _radiusKm;
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
                              'No locations within ${_radiusKm.toStringAsFixed(1)} km',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try increasing the radius',
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

                  // 🔹 Only show the first N items
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

                        // 🔹 Calculate and display distance
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
                          distance: distanceText, // 🔹 Pass distance
                        );
                      }).toList(),

                      // 🔹 Load More Button
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

            // ===============================================
            // USER PROFILES CAROUSEL
            // ===============================================
            SliverToBoxAdapter(child: UserProfilesCarousel()),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}