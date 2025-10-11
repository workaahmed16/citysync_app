import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart';

// ===============================================
// MAP VIEW WIDGET
// Displays a map using flutter_map with:
// - Base OpenStreetMap tiles
// - A center marker (user location)
// - Any number of extra pins passed from parent
// - Optional tap callback to notify parent
// ===============================================
class MapView extends StatelessWidget {
  final LatLng? center;               // 🔹 Starting map center (e.g. user location)

  // Instead of just LatLngs, we now accept *Marker objects*.
  // This gives the parent full control over pin colors,
  // ownership logic, tap handlers, etc.
  final List<Marker> pins;

  // 🔹 Callback triggered when user taps the map
  final Function(LatLng)? onTap;

  const MapView({
    super.key,
    this.center,
    this.onTap,
    this.pins = const [],             // 🔹 Default = empty list of pins
  });

  @override
  Widget build(BuildContext context) {
    // ===============================================
    // LOADING STATE
    // If no center yet (e.g. still fetching location),
    // show a loading spinner instead of a blank map.
    // ===============================================
    if (center == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: kDarkBlue),
        ),
      );
    }

    // ===============================================
    // MAIN MAP WIDGET
    // Uses flutter_map + OpenStreetMap tiles
    // ===============================================
    return ClipRRect(
      borderRadius: BorderRadius.circular(12), // Rounded corners
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center!,   // 👈 Focus map on given center
            initialZoom: 13,

            // 🔹 Triggered whenever the user taps the map
            onTap: (tapPosition, latlng) {
              if (onTap != null) {
                onTap!(latlng);       // 👈 Notify parent with tapped LatLng
              }
            },
          ),
          children: [
            // ===============================================
            // BASE MAP TILES
            // Using OpenStreetMap free tile server
            // ===============================================
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),

            // ===============================================
            // MARKERS LAYER
            // Shows both:
            // 1. A center marker (user location in orange)
            // 2. Any additional pins passed from parent
            //
            // NOTE:
            // - Pins are passed in as a *list of Marker objects*
            // - Parent decides how pins look (color/ownership/tap logic)
            // ===============================================
            MarkerLayer(
              markers: [
                // // 🔹 Center marker (highlighted in orange)
                // Marker(
                //   point: center!,
                //   width: 40,
                //   height: 40,
                //   child: const Icon(
                //     Icons.location_on,
                //     color: kOrange,
                //     size: 30,
                //   ),
                // ),

                // 🔹 Inject pins provided by parent
                ...pins,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
