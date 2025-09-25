import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart'; // your kDarkBlue, kOrange, kWhite

class AddLocationPopup {
  static Future<Map<String, dynamic>?> _reverseGeocode(LatLng coords) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?lat=${coords.latitude}&lon=${coords.longitude}&format=json",
    );

    try {
      final res = await http.get(
        url,
        headers: {"User-Agent": "citysync-app/1.0"},
      );
      if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    }
    return null;
  }

  /// Opens the dialog. prefillLatLng is optional.
  static Future<void> show(BuildContext context, {LatLng? prefillLatLng}) async {
    // Controllers
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descController = TextEditingController();

    // Preview placeholders for future media
    final List<String> photoPlaceholders = []; // will hold file paths / urls later
    final List<String> videoPlaceholders = [];

    // Rating
    int selectedRating = 0;

    // Prefill using reverse geocoding (if coordinates present).
    if (prefillLatLng != null) {
      final data = await _reverseGeocode(prefillLatLng);
      if (data != null) {
        final display = (data['display_name'] as String?) ?? '';
        final addressParts = (data['address'] as Map?) ?? <String, dynamic>{};

        // try several keys for a short name (many OSM files use different keys)
        final shortNameCandidate = addressParts['name'] ??
            addressParts['attraction'] ??
            addressParts['tourism'] ??
            addressParts['park'] ??
            addressParts['building'] ??
            addressParts['road'] ??
            addressParts['neighbourhood'] ??
            addressParts['suburb'] ??
            addressParts['city'] ??
            addressParts['town'] ??
            addressParts['village'] ??
            addressParts['county'];

        nameController.text = (shortNameCandidate?.toString() ?? '').isNotEmpty
            ? shortNameCandidate.toString()
            : '';
        addressController.text = display.isNotEmpty ? display : '';
      } else {
        // fallback to coordinates if geocoding failed
        nameController.text = '';
        addressController.text =
        "Lat: ${prefillLatLng.latitude.toStringAsFixed(6)}, Lng: ${prefillLatLng.longitude.toStringAsFixed(6)}";
      }
    }

    // Show the dialog (stateful inside to keep rating & placeholders)
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: kDarkBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StatefulBuilder(
                builder: (context, setState) {
                  Widget _buildThumbnailRow(List<String> items, IconData icon, String emptyLabel) {
                    if (items.isEmpty) {
                      // single placeholder
                      return GestureDetector(
                        onTap: () {
                          // TODO: open picker in future
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Picker coming soon")),
                          );
                        },
                        child: Container(
                          width: 88,
                          height: 64,
                          decoration: BoxDecoration(
                            color: kWhite.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kWhite.withOpacity(0.12)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: kWhite.withOpacity(0.9)),
                              const SizedBox(height: 6),
                              Text(
                                emptyLabel,
                                style: TextStyle(color: kWhite.withOpacity(0.8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // show thumbnails (future: show actual images)
                    return SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          return Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: kWhite.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: kWhite.withOpacity(0.08)),
                                ),
                                child: Center(
                                  child: Icon(icon, color: kWhite.withOpacity(0.9)),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => items.removeAt(idx));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kWhite.withOpacity(0.12),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.close, size: 16, color: kWhite),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Add Location / Review",
                              style: TextStyle(
                                color: kWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: kWhite),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Card container with white background for inputs
                      Card(
                        color: kWhite,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rating row
                              Row(
                                children: [
                                  const Text("Your rating:", style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: List.generate(5, (i) {
                                      final idx = i + 1;
                                      return IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32),
                                        icon: Icon(
                                          idx <= selectedRating ? Icons.star : Icons.star_border,
                                          color: kOrange,
                                        ),
                                        onPressed: () {
                                          setState(() => selectedRating = idx);
                                        },
                                      );
                                    }),
                                  ),
                                  if (selectedRating > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text("$selectedRating/5", style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Location name (editable)
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: "Location name",
                                  prefixIcon: const Icon(Icons.place),
                                  filled: true,
                                  fillColor: kWhite,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Address (read-only)
                              TextField(
                                controller: addressController,
                                readOnly: true,
                                maxLines: 2,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  labelText: "Address (read-only)",
                                  prefixIcon: const Icon(Icons.map),
                                  filled: true,
                                  fillColor: kWhite.withOpacity(0.98),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Description
                              TextField(
                                controller: descController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: "Description — why is this place cool?",
                                  alignLabelWithHint: true,
                                  filled: true,
                                  fillColor: kWhite,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Media section header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Photos", style: TextStyle(fontWeight: FontWeight.w600)),
                                  TextButton.icon(
                                    onPressed: () {
                                      // TODO: hook up Image Picker later
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Photo picker coming soon")),
                                      );
                                    },
                                    icon: Icon(Icons.add_a_photo, color: kDarkBlue),
                                    label: Text("Add", style: TextStyle(color: kDarkBlue)),
                                  ),
                                ],
                              ),
                              // Photo thumbnails (UI only)
                              _buildThumbnailRow(photoPlaceholders, Icons.photo, "No photos"),

                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Videos", style: TextStyle(fontWeight: FontWeight.w600)),
                                  TextButton.icon(
                                    onPressed: () {
                                      // TODO: hook up Video Picker later
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Video picker coming soon")),
                                      );
                                    },
                                    icon: Icon(Icons.videocam, color: kDarkBlue),
                                    label: Text("Add", style: TextStyle(color: kDarkBlue)),
                                  ),
                                ],
                              ),
                              _buildThumbnailRow(videoPlaceholders, Icons.videocam, "No videos"),

                              const SizedBox(height: 12),

                              // Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      side: BorderSide(color: kDarkBlue.withOpacity(0.12)),
                                      foregroundColor: kDarkBlue,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    ),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // TODO: Replace print with save-to-DB / API call
                                      final result = {
                                        'rating': selectedRating,
                                        'name': nameController.text,
                                        'address': addressController.text,
                                        'description': descController.text,
                                        'photos': photoPlaceholders,
                                        'videos': videoPlaceholders,
                                      };
                                      debugPrint("Saved location review: $result");
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kOrange,
                                      foregroundColor: kWhite,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text("Save"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
