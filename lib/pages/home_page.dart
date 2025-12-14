import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart' as AppColors;
import '../services/location_service.dart';
import '../widgets/location_search_widget.dart';
import '../widgets/user_profiles_carousel.dart';
import '../widgets/similar_interests_widget.dart';
import '../widgets/home_header.dart';
import '../widgets/home_map_section.dart';
import '../widgets/home_locations_list.dart';
import 'profile_page.dart';
import 'matches_page.dart';

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
        if (lat != null && lng != null) {
          _mapCenter = LatLng(lat, lng);
          _userLocation = LatLng(lat, lng);
          print("Map centered at: $lat, $lng");
        } else {
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

  void _navigateToMatches() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MatchesPage()),
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
            HomeHeader(onMatchesTap: _navigateToMatches),

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

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildRadiusCard(),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            HomeMapSection(
              mapCenter: _mapCenter,
              searchQuery: _searchQuery,
            ),

            HomeLocationsList(
              userLocation: _userLocation,
              radiusKm: _radiusKm,
              searchQuery: _searchQuery,
              itemsToShow: _itemsToShow,
              onLoadMore: () {
                setState(() => _itemsToShow += 10);
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            const SliverToBoxAdapter(child: UserProfilesCarousel()),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            const SliverToBoxAdapter(child: SimilarInterestsWidget()),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusCard() {
    return Card(
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.kDarkBlue.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_radiusKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                inactiveColor: AppColors.kDarkBlue.withOpacity(0.1),
                onChanged: (value) {
                  setState(() => _radiusKm = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}