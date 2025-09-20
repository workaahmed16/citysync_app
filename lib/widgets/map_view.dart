import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart';

class MapView extends StatelessWidget {
  final LatLng? center;

  /// 🔹 Add a callback for when the user taps the map
  final Function(LatLng)? onTap;

  const MapView({
    super.key,
    this.center,
    this.onTap, // 👈 new optional parameter
  });

  @override
  Widget build(BuildContext context) {
    if (center == null) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(color: kDarkBlue),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center!,
            initialZoom: 13,

            /// 🔹 This will trigger whenever the user taps on the map
            onTap: (tapPosition, latlng) {
              if (onTap != null) {
                onTap!(latlng); // 👈 Pass tapped LatLng to parent widget
              }
            },
          ),
          children: [
            // 🔹 Base map tiles
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),

            // 🔹 Center marker (e.g. user’s location)
            MarkerLayer(
              markers: [
                Marker(
                  point: center!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: kOrange,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
