// public_profile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'reviews_page.dart';

// 🎨 Color Scheme
const Color kDarkBlue = Color(0xFF0D47A1);
const Color kOrange = Color(0xFFFF9800);
const Color kWhite = Colors.white;

enum LocationSortBy { mostRecent, highestRated }

class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  LocationSortBy _sortBy = LocationSortBy.mostRecent;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserProfile() async {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  Stream<QuerySnapshot> _getUserLocations() {
    print('DEBUG: Fetching locations for userId: ${widget.userId}');
    print('DEBUG: Sort by: $_sortBy');

    Query query = FirebaseFirestore.instance
        .collection('locations')
        .where('userId', isEqualTo: widget.userId);

    // TEMPORARILY DISABLED - Testing if base query works
    // Apply sorting based on selection
    // Note: These require composite indexes in Firestore
    // if (_sortBy == LocationSortBy.mostRecent) {
    //   print('DEBUG: Ordering by createdAt descending');
    //   query = query.orderBy('createdAt', descending: true);
    // } else if (_sortBy == LocationSortBy.highestRated) {
    //   print('DEBUG: Ordering by rating descending');
    //   query = query.orderBy('rating', descending: true);
    // }

    return query.snapshots();
  }

  Future<void> _launchInstagram(String handle) async {
    final url = Uri.parse("https://instagram.com/$handle");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch Instagram");
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time, color: kOrange),
                title: const Text('Most Recent'),
                trailing: _sortBy == LocationSortBy.mostRecent
                    ? const Icon(Icons.check, color: kOrange)
                    : null,
                onTap: () {
                  setState(() => _sortBy = LocationSortBy.mostRecent);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: kOrange),
                title: const Text('Highest Rated'),
                trailing: _sortBy == LocationSortBy.highestRated
                    ? const Icon(Icons.check, color: kOrange)
                    : null,
                onTap: () {
                  setState(() => _sortBy = LocationSortBy.highestRated);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
        backgroundColor: kDarkBlue,
        iconTheme: const IconThemeData(color: kWhite),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kOrange));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final data = snapshot.data!.data()!;
          final name = data['name'] ?? "Unknown";
          final bio = data['bio'] ?? "No bio yet";
          final location = data['location'] ?? "Unknown";
          final age = data['age']?.toString() ?? "";
          final city = data['city'] ?? "";
          final zip = data['zip'] ?? "";
          final interests = data['interests'] ?? "";
          final instagram = data['instagram'] ?? "";
          final photoUrl =
              data['profilePhotoUrl'] ?? "https://picsum.photos/200";

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- Cover + Profile Picture ---
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 160,
                      decoration: const BoxDecoration(
                        color: kDarkBlue,
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: kWhite,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage(photoUrl),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // --- Profile Info ---
                Text(name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue)),
                const SizedBox(height: 6),
                Text(bio,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: kOrange),
                    const SizedBox(width: 4),
                    Text(location,
                        style:
                        const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Extra profile details ---
                if (age.isNotEmpty) _infoRow(Icons.cake, "Age: $age"),
                if (city.isNotEmpty)
                  _infoRow(Icons.location_city, "City: $city"),
                if (zip.isNotEmpty)
                  _infoRow(Icons.local_post_office, "Zip: $zip"),
                if (interests.isNotEmpty)
                  _infoRow(Icons.star, "Interests: $interests"),

                const SizedBox(height: 20),

                // --- Instagram button ---
                if (instagram.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _launchInstagram(instagram),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("View Instagram"),
                  ),

                const SizedBox(height: 30),

                // --- Divider ---
                const Divider(thickness: 1, height: 1),

                const SizedBox(height: 20),

                // --- Locations Section ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('locations')
                            .where('userId', isEqualTo: widget.userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          return Text(
                            'Locations ($count)',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kDarkBlue,
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: _showSortOptions,
                        icon: const Icon(Icons.sort, color: kOrange),
                        label: const Text(
                          'Sort',
                          style: TextStyle(color: kOrange),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // --- Locations List ---
                StreamBuilder<QuerySnapshot>(
                  stream: _getUserLocations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(color: kOrange),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('DEBUG: No data or empty docs. HasData: ${snapshot.hasData}, Docs length: ${snapshot.data?.docs.length ?? 0}');
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.explore_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No locations yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final locations = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final doc = locations[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final locationName = data['name'] ?? 'Unnamed Location';
                        final rating = (data['rating'] ?? 0).toDouble();
                        final photos = List<String>.from(data['photos'] ?? []);
                        final photoUrl = photos.isNotEmpty
                            ? photos[0]
                            : 'https://via.placeholder.com/150';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              // Navigate to ReviewsPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewsPage(locationId: doc.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Photo
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      photoUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.location_city,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name and Rating
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          locationName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: kDarkBlue,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        if (rating > 0)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (rating == 0)
                                          const Text(
                                            'No rating yet',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Arrow
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// Note: Make sure to import your ReviewsPage
// import 'reviews_page.dart';