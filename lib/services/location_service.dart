import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 🔹 Updates user location: Firestore → IP → user confirmation
  Future<Map<String, dynamic>?> updateUserLocation(BuildContext context) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print("No logged-in user. Skipping location setup.");
      return null;
    }

    print("=== Fetching Firestore location ===");
    final userDoc = await _db.collection('users').doc(currentUserId).get();
    final data = userDoc.data() ?? {};
    String firestoreCity = (data['city'] ?? '').toString().trim();
    String firestoreCountry = (data['country'] ?? data['location'] ?? '').toString().trim();
    double? firestoreLat = data['lat'] as double?;
    double? firestoreLng = data['lng'] as double?;
    print("Firestore city: $firestoreCity, country: $firestoreCountry, lat: $firestoreLat, lng: $firestoreLng");

    print("=== Fetching IP-based location ===");
    final ipLocation = await _getCityFromIP();
    String ipCity = ipLocation?['city'] ?? '';
    String ipCountry = ipLocation?['country_name'] ?? '';
    double? ipLat = ipLocation?['latitude'] as double?;
    double? ipLng = ipLocation?['longitude'] as double?;
    print("IP lookup city: $ipCity, country: $ipCountry, lat: $ipLat, lng: $ipLng");

    String? finalCity, finalCountry;
    double? finalLat, finalLng;

    // Compare Firestore and IP
    if (ipCity.isNotEmpty &&
        ipCountry.isNotEmpty &&
        firestoreCity.isNotEmpty &&
        firestoreCountry.isNotEmpty &&
        (ipCity != firestoreCity || ipCountry != firestoreCountry)) {
      print("Firestore and IP location mismatch. Prompting user confirmation.");
      final confirmed = await _promptConfirmCity(context, ipCity, ipCountry);

      if (confirmed) {
        // User confirmed IP location - use IP data including coordinates
        finalCity = ipCity;
        finalCountry = ipCountry;
        finalLat = ipLat;
        finalLng = ipLng;
        print("User confirmed IP location: $finalCity, $finalCountry with coords ($finalLat, $finalLng)");
      } else {
        // User denied - use Firestore location with Firestore coords
        finalCity = firestoreCity;
        finalCountry = firestoreCountry;
        finalLat = firestoreLat;
        finalLng = firestoreLng;
        print("User denied update. Using Firestore location: $finalCity, $finalCountry with coords ($finalLat, $finalLng)");

        // If Firestore doesn't have coords, use IP coords as fallback
        if (finalLat == null || finalLng == null) {
          finalLat = ipLat;
          finalLng = ipLng;
          print("Firestore missing coords, using IP coords as fallback");
        }
      }
    } else if (firestoreCity.isNotEmpty && firestoreCountry.isNotEmpty) {
      // Firestore has data and matches IP (or IP is empty) - use Firestore
      finalCity = firestoreCity;
      finalCountry = firestoreCountry;
      finalLat = firestoreLat;
      finalLng = firestoreLng;
      print("Using Firestore location: $finalCity, $finalCountry");

      // If Firestore doesn't have coordinates, try geocoding or use IP coords
      if ((finalLat == null || finalLng == null)) {
        if (ipLat != null && ipLng != null) {
          finalLat = ipLat;
          finalLng = ipLng;
          print("Firestore missing coordinates, using IP coords as fallback");
        } else {
          final latLng = await geocodeCityCountry(finalCity, finalCountry);
          if (latLng != null) {
            finalLat = latLng.latitude;
            finalLng = latLng.longitude;
          }
        }
      }
    } else if (ipCity.isNotEmpty && ipCountry.isNotEmpty) {
      // Firestore is empty, but we have IP location - just use it with confirmation
      print("Firestore empty, using IP location with confirmation.");
      final confirmed = await _promptConfirmCity(context, ipCity, ipCountry);

      if (confirmed) {
        finalCity = ipCity;
        finalCountry = ipCountry;
        finalLat = ipLat;
        finalLng = ipLng;
        print("User confirmed IP location: $finalCity, $finalCountry");
      } else {
        // User denied and Firestore empty - just use IP coords anyway (no more prompts!)
        finalCity = ipCity;
        finalCountry = ipCountry;
        finalLat = ipLat;
        finalLng = ipLng;
        print("User denied but no saved location exists. Using IP location anyway.");
      }
    } else {
      // No Firestore or IP data - use default fallback coordinates
      print("No location data available, using default coordinates");
      finalCity = "San Francisco";
      finalCountry = "United States";
      finalLat = 37.7749;
      finalLng = -122.4194;
    }

    // Save final location to Firestore (only if it changed or is new)
    if (finalCity != null && finalCountry != null) {
      final needsUpdate = finalCity != firestoreCity ||
          finalCountry != firestoreCountry ||
          finalLat != firestoreLat ||
          finalLng != firestoreLng;

      if (needsUpdate) {
        print("Saving location to Firestore: $finalCity, $finalCountry, coords: ($finalLat, $finalLng)");
        final updateData = <String, dynamic>{
          'city': finalCity,
          'country': finalCountry,
          'location': finalCountry, // Also save as 'location' for consistency with EditProfilePage
        };

        // Add lat/lng if available
        if (finalLat != null && finalLng != null) {
          updateData['lat'] = finalLat;
          updateData['lng'] = finalLng;
        }

        await _db.collection('users').doc(currentUserId).update(updateData);
      }
    }

    print("=== Location update complete ===");
    return {
      'city': finalCity ?? '',
      'country': finalCountry ?? '',
      'lat': finalLat,
      'lng': finalLng,
    };
  }

  /// 🔹 IP lookup
  Future<Map<String, dynamic>?> _getCityFromIP() async {
    try {
      final res = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (res.statusCode == 200) {
        print("IP API response: ${res.body}");
        return json.decode(res.body);
      } else {
        print("IP API request failed with status: ${res.statusCode}");
      }
    } catch (e) {
      print("IP lookup error: $e");
    }
    return null;
  }

  /// 🔹 Confirmation dialog
  Future<bool> _promptConfirmCity(
      BuildContext context, String city, String country) async {
    print("Prompting user to confirm location: $city, $country");
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Confirm your city"),
        content: Text("We detected your location as $city, $country.\n\nIs this correct?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No, use my saved location")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes, update")),
        ],
      ),
    ) ??
        false;
  }

  /// 🔹 Manual input dialog
  Future<String?> _promptManualInput(
      BuildContext context, String label) async {
    print("Prompting user for manual input: $label");
    final controller = TextEditingController();
    String? result;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Enter $label"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              result = controller.text.trim();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
    print("User input for $label: $result");
    return result;
  }

  /// 🔹 Geocode city/country using OpenStreetMap Nominatim API
  Future<LatLng?> geocodeCityCountry(String city, String country) async {
    try {
      final query = Uri.encodeFull("$city, $country");
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1");

      final res = await http.get(url, headers: {
        'User-Agent': 'YourAppName/1.0 (youremail@example.com)' // Nominatim requires a valid User-Agent
      });

      if (res.statusCode != 200) {
        print("Nominatim HTTP error: ${res.statusCode}");
        return null;
      }

      final data = json.decode(res.body);
      if (data is List && data.isNotEmpty) {
        final firstResult = data[0];
        final lat = double.tryParse(firstResult['lat'] ?? '');
        final lon = double.tryParse(firstResult['lon'] ?? '');
        if (lat != null && lon != null) {
          print("Geocoded $city, $country to LatLng: ($lat, $lon)");
          return LatLng(lat, lon);
        }
      }

      print("No results found for $city, $country");
    } catch (e) {
      print("Geocoding error for $city, $country: $e");
    }

    return null;
  }
}