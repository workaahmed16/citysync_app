import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // 🔹 For Firestore
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:myfirstflutterapp/widgets/add_location_popup.dart';

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
// Holds state like current map center, city/country,
// and bottom navigation index.
// ===============================================
class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;        // 🔹 Index of bottom nav bar
  LatLng? _mapCenter;            // 🔹 Center point of the map (set via LocationService)
  String? _city, _country;       // 🔹 City and country for current user location

  final _locationService = LocationService(); // 🔹 Helper service to fetch location
  final _auth = FirebaseAuth.instance;        // 🔹 To check current user

  @override
  void initState() {
    super.initState();
    _setupLocation(); // Fetch user location on startup

    // 🔹 Show a "welcome" popup after login (runs once when widget builds)
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
  // Uses LocationService to get user location, then
  // reverse-geocodes into city/country + map center.
  // ===============================================
  Future<void> _setupLocation() async {
    final result = await _locationService.updateUserLocation(context);

    if (result != null) {
      // Extract city + country
      final city = result['city']!;
      final country = result['country']!;

      // Geocode city + country into LatLng
      final latLng = await _locationService.geocodeCityCountry(city, country);

      setState(() {
        _city = city;
        _country = country;
        _mapCenter = latLng ?? const LatLng(37.7749, -122.4194); // fallback = San Francisco
      });
    } else {
      // 🔹 Fallback if no result from LocationService
      setState(() {
        _mapCenter = const LatLng(37.7749, -122.4194); // default = San Francisco
      });
    }
  }

  // ===============================================
  // BOTTOM NAVIGATION HANDLER
  // If user taps profile (index 1), go to ProfilePage.
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
  // Called when user taps on the map.
  // Opens the AddLocationPopup where user confirms
  // details before saving to Firestore.
  // ===============================================
  void _handleMapTap(LatLng latlng) {
    AddLocationPopup.show(context, prefillLatLng: latlng);
  }

  // ===============================================
  // BUILD METHOD
  // Creates the UI:
  // - BottomNavigationBar (Home & Profile only)
  // - SafeArea with scrollable content
  // ===============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 Bottom navigation bar (simplified to 2 items)
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

      // 🔹 Main content area
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ===============================================
            // SEARCH BAR SECTION
            // Appears at the top of the page
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
            // Uses a Firestore StreamBuilder to fetch pins
            // so they persist across sessions & users.
            // - Your pins = blue
            // - Others' pins = orange
            // ===============================================
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('locations')
                      .snapshots(), // 👈 Live updates from Firestore
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

                      // 🔹 Color logic:
                      // Blue = mine, Orange = others
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

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final name = data['name'] ?? "Unnamed";
                      final description = data['description'] ?? "";
                      final address = data['address'] ?? "";
                      final displayDesc =
                      description.isNotEmpty ? description : address;

                      return LocationCard(
                        title: name,
                        description: displayDesc,
                        placeId: doc.id, // 👈 pass Firestore doc id
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ===============================================
            // USER PROFILES CAROUSEL
            // Horizontal carousel of user profiles
            // ===============================================
            SliverToBoxAdapter(child: UserProfilesCarousel()),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}