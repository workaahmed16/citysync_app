import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme/colors.dart' as AppColors;
import '../services/location_search_service.dart';
import '../widgets/map_view.dart';
import '../widgets/add_location_popup.dart';
import '../pages/reviews_page.dart';

class HomeMapSection extends StatelessWidget {
  final LatLng? mapCenter;
  final String searchQuery;

  const HomeMapSection({
    super.key,
    required this.mapCenter,
    required this.searchQuery,
  });

  void _handleMapTap(BuildContext context, LatLng latlng) {
    AddLocationPopup.show(context, prefillLatLng: latlng);
  }

  void _handlePinTap(BuildContext context, String placeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsPage(locationId: placeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return SliverToBoxAdapter(
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
                  final pins = <Marker>[];

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    pins.addAll(
                      snapshot.data!.docs
                          .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final lat = data['lat'];
                        final lng = data['lng'];
                        if (lat == null || lng == null) return false;

                        return LocationSearchService.matchesSearch(
                            data, searchQuery);
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
                            onTap: () => _handlePinTap(context, doc.id),
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
                    center: mapCenter,
                    pins: pins,
                    onTap: (latlng) => _handleMapTap(context, latlng),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}