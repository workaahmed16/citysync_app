import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../theme/colors.dart';

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
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    }
    return null;
  }

  static Future<void> show(BuildContext context, {LatLng? prefillLatLng}) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descController = TextEditingController();
    final instagramController = TextEditingController();

    final List<String> photoUrls = [];
    final List<String> videoUrls = [];
    int selectedRating = 0;

    final cloudinaryService = CloudinaryService();

    if (prefillLatLng != null) {
      final data = await _reverseGeocode(prefillLatLng);
      if (data != null) {
        final display = (data['display_name'] as String?) ?? '';
        final addressParts = (data['address'] as Map?) ?? <String, dynamic>{};

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
        nameController.text = '';
        addressController.text =
        "Lat: ${prefillLatLng.latitude.toStringAsFixed(6)}, Lng: ${prefillLatLng.longitude.toStringAsFixed(6)}";
      }
    }

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
                  Widget _buildThumbnailRow(
                      List<String> items,
                      IconData icon,
                      String emptyLabel,
                      VoidCallback onAdd,
                      ) {
                    if (items.isEmpty) {
                      return GestureDetector(
                        onTap: onAdd,
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
                                style: TextStyle(
                                  color: kWhite.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final isVideo = icon == Icons.videocam;
                          final thumbnailUrl = isVideo
                              ? cloudinaryService.getVideoThumbnail(items[idx])
                              : items[idx];

                          return Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: kWhite.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: kWhite.withOpacity(0.08),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        thumbnailUrl,
                                        fit: BoxFit.cover,
                                        width: 96,
                                        height: 72,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Icon(
                                              icon,
                                              color: kWhite.withOpacity(0.9),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (isVideo)
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.play_arrow,
                                            color: kWhite,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                  ],
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
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: kWhite,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }

                  Future<void> _addPhoto() async {
                    try {
                      final imageUrl = await cloudinaryService.pickAndUploadImage(
                        source: ImageSource.gallery,
                      );
                      setState(() => photoUrls.add(imageUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Photo uploaded!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error uploading photo: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }

                  Future<void> _addVideo() async {
                    try {
                      double uploadProgress = 0.0;
                      void Function(void Function())? dialogSetState;

                      // Show loading dialog with progress
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) => StatefulBuilder(
                            builder: (context, setDialogState) {
                              dialogSetState = setDialogState; // Capture setState
                              return AlertDialog(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    const Text('Uploading video...'),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(value: uploadProgress),
                                    const SizedBox(height: 8),
                                    Text('${(uploadProgress * 100).toInt()}%'),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }

                      // Pick and upload video with progress tracking
                      final videoUrl = await cloudinaryService.pickAndUploadVideo(
                        source: ImageSource.gallery,
                        onProgress: (progress) {
                          uploadProgress = progress;
                          debugPrint('Video upload progress: ${(progress * 100).toInt()}%');
                          // Update dialog state
                          dialogSetState?.call(() {
                            uploadProgress = progress;
                          });
                        },
                      );

                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }

                      setState(() => videoUrls.add(videoUrl));

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Video uploaded successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // Close loading dialog if it's open
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error uploading video: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Card(
                          color: kWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rating
                                Row(
                                  children: [
                                    const Text(
                                      "Your rating:",
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: List.generate(5, (i) {
                                        final idx = i + 1;
                                        return IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints:
                                          const BoxConstraints(minWidth: 32),
                                          icon: Icon(
                                            idx <= selectedRating
                                                ? Icons.star
                                                : Icons.star_border,
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
                                        child: Text(
                                          "$selectedRating/5",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Name
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: "Location name",
                                    prefixIcon: const Icon(Icons.place),
                                    filled: true,
                                    fillColor: kWhite,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Address
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
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
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
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Instagram Post URL (optional)
                                TextField(
                                  controller: instagramController,
                                  decoration: InputDecoration(
                                    labelText: "Instagram Post URL (optional)",
                                    hintText: "https://instagram.com/p/...",
                                    prefixIcon: Icon(Icons.camera_alt, color: Colors.pink[600]),
                                    filled: true,
                                    fillColor: kWhite,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    helperText: "Paste link to your Instagram post about this place",
                                    helperMaxLines: 2,
                                  ),
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 12),

                                // Photos Section
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Photos",
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    TextButton.icon(
                                      onPressed: _addPhoto,
                                      icon: Icon(Icons.add_a_photo, color: kDarkBlue),
                                      label: Text(
                                        "Add",
                                        style: TextStyle(color: kDarkBlue),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildThumbnailRow(
                                  photoUrls,
                                  Icons.photo,
                                  "No photos",
                                  _addPhoto,
                                ),
                                const SizedBox(height: 12),

                                // Videos Section
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Videos",
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    TextButton.icon(
                                      onPressed: _addVideo,
                                      icon: Icon(Icons.videocam, color: kDarkBlue),
                                      label: Text(
                                        "Add",
                                        style: TextStyle(color: kDarkBlue),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildThumbnailRow(
                                  videoUrls,
                                  Icons.videocam,
                                  "No videos",
                                  _addVideo,
                                ),
                                const SizedBox(height: 12),

                                // Buttons
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: TextButton.styleFrom(
                                        side: BorderSide(
                                          color: kDarkBlue.withOpacity(0.12),
                                        ),
                                        foregroundColor: kDarkBlue,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;

                                        if (user == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "You must be logged in to save a location.",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        // Validate Instagram URL if provided
                                        final instagramUrl = instagramController.text.trim();
                                        if (instagramUrl.isNotEmpty &&
                                            !instagramUrl.contains('instagram.com')) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please enter a valid Instagram URL'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }

                                        final result = {
                                          'userId': user.uid,
                                          'rating': selectedRating,
                                          'baseRating': selectedRating,
                                          'name': nameController.text,
                                          'address': addressController.text,
                                          'description': descController.text,
                                          'photos': photoUrls,
                                          'videos': videoUrls,
                                          'createdAt':
                                          FieldValue.serverTimestamp(),
                                          if (prefillLatLng != null)
                                            'lat': prefillLatLng.latitude,
                                          if (prefillLatLng != null)
                                            'lng': prefillLatLng.longitude,
                                          if (instagramUrl.isNotEmpty)
                                            'instagramPostUrl': instagramUrl,
                                        };

                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('locations')
                                              .add(result);

                                          debugPrint("Saved to Firestore: $result");

                                          if (context.mounted) {
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content:
                                                Text("Location saved!"),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          debugPrint(
                                              "Firestore save error: $e");
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                Text("Error saving: $e"),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kOrange,
                                        foregroundColor: kWhite,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
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
                    ),
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