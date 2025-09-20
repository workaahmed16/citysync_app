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
  Future<Map<String, String>?> updateUserLocation(BuildContext context) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print("No logged-in user. Skipping location setup.");
      return null;
    }

    print("=== Fetching Firestore location ===");
    final userDoc = await _db.collection('users').doc(currentUserId).get();
    final data = userDoc.data() ?? {};
    String firestoreCity = (data['city'] ?? '').toString().trim();
    String firestoreCountry = (data['country'] ?? '').toString().trim();
    print("Firestore city: $firestoreCity, country: $firestoreCountry");

    print("=== Fetching IP-based location ===");
    final ipLocation = await _getCityFromIP();
    String ipCity = ipLocation?['city'] ?? '';
    String ipCountry = ipLocation?['country_name'] ?? '';
    print("IP lookup city: $ipCity, country: $ipCountry");

    String? finalCity, finalCountry;

    // Compare Firestore and IP
    if (ipCity.isNotEmpty &&
        ipCountry.isNotEmpty &&
        (ipCity != firestoreCity || ipCountry != firestoreCountry)) {
      print("Firestore and IP location mismatch. Prompting user confirmation.");
      final confirmed = await _promptConfirmCity(context, ipCity, ipCountry);
      if (confirmed) {
        finalCity = ipCity;
        finalCountry = ipCountry;
        print("User confirmed IP location: $finalCity, $finalCountry");
      } else {
        finalCity = await _promptManualInput(context, "City");
        finalCountry = await _promptManualInput(context, "Country");
        print("User manually entered location: $finalCity, $finalCountry");
      }
    } else if (firestoreCity.isNotEmpty && firestoreCountry.isNotEmpty) {
      finalCity = firestoreCity;
      finalCountry = firestoreCountry;
      print("Using Firestore location: $finalCity, $finalCountry");
    } else if (ipCity.isNotEmpty && ipCountry.isNotEmpty) {
      print("Firestore empty, using IP location with confirmation.");
      final confirmed = await _promptConfirmCity(context, ipCity, ipCountry);
      if (confirmed) {
        finalCity = ipCity;
        finalCountry = ipCountry;
        print("User confirmed IP location: $finalCity, $finalCountry");
      } else {
        finalCity = await _promptManualInput(context, "City");
        finalCountry = await _promptManualInput(context, "Country");
        print("User manually entered location: $finalCity, $finalCountry");
      }
    } else {
      finalCity = await _promptManualInput(context, "City");
      finalCountry = await _promptManualInput(context, "Country");
      print("No Firestore/IP data. User manually entered location: $finalCity, $finalCountry");
    }

    // Save final location to Firestore
    if (finalCity != null && finalCountry != null) {
      print("Saving location to Firestore: $finalCity, $finalCountry");
      await _db.collection('users').doc(currentUserId).update({
        'city': finalCity,
        'country': finalCountry,
      });
    }

    print("=== Location update complete ===");
    return {'city': finalCity ?? '', 'country': finalCountry ?? ''};
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
        content: Text("We detected your location as $city, $country."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Change")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm")),
        ],
      ),
    ) ??
        false;
  }

  /// 🔹 Manual input dialog
  Future<String> _promptManualInput(
      BuildContext context, String label) async {
    print("Prompting user for manual input: $label");
    final controller = TextEditingController();
    String result = '';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Enter $label"),
        content: TextField(controller: controller),
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
