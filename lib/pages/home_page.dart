import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'reviews_page.dart';
import 'public_profile.dart';

// 🎨 Shared colors
const Color kDarkBlue = Color(0xFF0D47A1);
const Color kOrange = Color(0xFFFF6F00);
const Color kWhite = Colors.white;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: kDarkBlue,
        selectedItemColor: kOrange,
        unselectedItemColor: kWhite,
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
            // 🔎 Search bar
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: kOrange),
                        hintText: "Search location",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),

            // 🌍 Map section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(37.7749, -122.4194),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.example.citysync',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: const LatLng(6.2442, -75.5812),
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
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 📍 Location cards
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 150,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12)),
                            image: DecorationImage(
                              image: NetworkImage("https://picsum.photos/400/200"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "\$123 / night",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kDarkBlue,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const ReviewsPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kOrange,
                                  foregroundColor: kWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Select"),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: 3,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 👥 Firebase User Profiles
            SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: kDarkBlue),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No users found"));
                    }

                    final users = snapshot.data!.docs
                        .where((doc) => doc.id != currentUserId)
                        .toList();

                    if (users.isEmpty) {
                      return const Center(child: Text("No other users"));
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: users.length,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final user =
                        userDoc.data() as Map<String, dynamic>;
                        final name = user['name'] ?? "No name";
                        final photoUrl = user['profilePhotoUrl'];

                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PublicProfilePage(
                                              userId: userDoc.id), // ✅ fixed
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                  kOrange.withOpacity(0.2),
                                  backgroundImage: (photoUrl != null &&
                                      photoUrl.toString().isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: (photoUrl == null ||
                                      photoUrl.toString().isEmpty)
                                      ? Text(
                                    name[0],
                                    style: const TextStyle(
                                      color: kDarkBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                style: const TextStyle(color: kDarkBlue),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
