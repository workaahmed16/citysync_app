import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:myfirstflutterapp/widgets/add_location_popup.dart';

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
  String? _city, _country;

  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _setupLocation();

    // 🔹 Show a simple popup once after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
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

  Future<void> _setupLocation() async {
    final result = await _locationService.updateUserLocation(context);

    if (result != null) {
      final city = result['city']!;
      final country = result['country']!;
      final latLng = await _locationService.geocodeCityCountry(city, country);

      setState(() {
        _city = city;
        _country = country;
        _mapCenter = latLng ?? const LatLng(37.7749, -122.4194);
      });
    } else {
      setState(() {
        _mapCenter = const LatLng(37.7749, -122.4194);
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.kDarkBlue,
        selectedItemColor: AppColors.kOrange,
        unselectedItemColor: AppColors.kWhite,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SearchBarWidget(),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: MapView(
                center: _mapCenter,
                onTap: (latlng) {
                  AddLocationPopup.show(context, prefillLatLng: latlng);
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => LocationCard(
                  title: 'Location $index',
                  description: 'Description for location $index',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReviewsPage()),
                  ),
                ),
                childCount: 3,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: UserProfilesCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
