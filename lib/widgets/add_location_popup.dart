import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AddLocationPopup {
  /// 🔹 Updated `show` method to accept optional prefillLatLng
  static Future<void> show(BuildContext context, {LatLng? prefillLatLng}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    // If we have coordinates, prefill description or name
    if (prefillLatLng != null) {
      descController.text =
      "Lat: ${prefillLatLng.latitude}, Lng: ${prefillLatLng.longitude}";
    }

    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "✨ Add a Cool New Location ✨",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                /// Location name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Location Name",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                /// Description or coordinates
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "Why is this place cool?",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        print("Saved Location: ${nameController.text}, "
                            "${descController.text}");
                        Navigator.of(context).pop();
                      },
                      child: const Text("Save"),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
