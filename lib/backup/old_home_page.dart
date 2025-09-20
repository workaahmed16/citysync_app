// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:http/http.dart' as http;
//
// import 'profile_page.dart';
// import 'reviews_page.dart';
// import 'public_profile.dart';
//
// /// 🎨 Shared color palette
// const Color kDarkBlue = Color(0xFF0D47A1);
// const Color kOrange = Color(0xFFFF6F00);
// const Color kWhite = Colors.white;
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;
//   LatLng? _mapCenter;
//   String? _city;
//   String? _country;
//
//   @override
//   void initState() {
//     super.initState();
//     _updateUserLocationWorkflow();
//   }
//
//   /// 🔹 Main location workflow: Firestore → IP → user confirmation
//   Future<void> _updateUserLocationWorkflow() async {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//     if (currentUserId == null) return;
//
//     // 1️⃣ Fetch Firestore location
//     final userDoc =
//     await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
//
//     String firestoreCity = '';
//     String firestoreCountry = '';
//     if (userDoc.exists) {
//       final data = userDoc.data() as Map<String, dynamic>;
//       firestoreCity = (data['city'] ?? "").toString().trim();
//       firestoreCountry = (data['country'] ?? "").toString().trim();
//     }
//
//     // 2️⃣ Fetch IP-based location
//     final ipLocation = await _getCityFromIP();
//     String ipCity = ipLocation?['city'] ?? '';
//     String ipCountry = ipLocation?['country_name'] ?? '';
//
//     // 3️⃣ Compare Firestore vs IP
//     bool locationMismatch = ipCity.isNotEmpty &&
//         ipCountry.isNotEmpty &&
//         (ipCity != firestoreCity || ipCountry != firestoreCountry);
//
//     String? finalCity;
//     String? finalCountry;
//
//     if (locationMismatch) {
//       // Ask user to confirm new location
//       bool confirmed = await _promptUserConfirmCity(ipCity, ipCountry);
//       if (confirmed) {
//         finalCity = ipCity;
//         finalCountry = ipCountry;
//       } else {
//         finalCity = await _promptUserManualInput("City");
//         finalCountry = await _promptUserManualInput("Country");
//       }
//     } else if (firestoreCity.isNotEmpty && firestoreCountry.isNotEmpty) {
//       finalCity = firestoreCity;
//       finalCountry = firestoreCountry;
//     } else if (ipCity.isNotEmpty && ipCountry.isNotEmpty) {
//       // Firestore empty → use IP location
//       bool confirmed = await _promptUserConfirmCity(ipCity, ipCountry);
//       if (confirmed) {
//         finalCity = ipCity;
//         finalCountry = ipCountry;
//       } else {
//         finalCity = await _promptUserManualInput("City");
//         finalCountry = await _promptUserManualInput("Country");
//       }
//     } else {
//       // Both Firestore and IP fail → manual input
//       finalCity = await _promptUserManualInput("City");
//       finalCountry = await _promptUserManualInput("Country");
//     }
//
//     // 4️⃣ Save final location to Firestore
//     if (finalCity != null && finalCountry != null) {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(currentUserId)
//           .update({'city': finalCity, 'country': finalCountry});
//     }
//
//     _city = finalCity;
//     _country = finalCountry;
//
//     // 5️⃣ Geocode to LatLng for map
//     if (_city != null && _country != null) {
//       try {
//         final fullAddress = "$_city, $_country";
//         final locations = await locationFromAddress(fullAddress);
//         if (locations.isNotEmpty) {
//           setState(() {
//             _mapCenter = LatLng(
//               locations.first.latitude,
//               locations.first.longitude,
//             );
//           });
//         }
//       } catch (e) {
//         debugPrint("Geocoding failed: $e");
//         setState(() {
//           _mapCenter = const LatLng(37.7749, -122.4194); // fallback: San Francisco
//         });
//       }
//     }
//   }
//
//   /// 🔹 IP Lookup API
//   Future<Map<String, dynamic>?> _getCityFromIP() async {
//     try {
//       final response = await http.get(Uri.parse('https://ipapi.co/json/'));
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       }
//     } catch (e) {
//       debugPrint("IP lookup failed: $e");
//     }
//     return null;
//   }
//
//   /// 🔹 Confirmation dialog for auto-detected location
//   Future<bool> _promptUserConfirmCity(String city, String country) async {
//     return await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text("Confirm your city"),
//         content: Text("We detected your location as $city, $country."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Change"),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Confirm"),
//           ),
//         ],
//       ),
//     ) ??
//         false;
//   }
//
//   /// 🔹 Manual input dialog (used when auto-detect fails or rejected)
//   Future<String> _promptUserManualInput(String label) async {
//     final controller = TextEditingController();
//     String result = '';
//
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text("Enter $label"),
//         content: TextField(controller: controller),
//         actions: [
//           ElevatedButton(
//             onPressed: () {
//               result = controller.text.trim();
//               Navigator.pop(context);
//             },
//             child: const Text("Save"),
//           )
//         ],
//       ),
//     );
//
//     return result;
//   }
//
//   /// 🔹 Bottom navigation handling
//   void _onItemTapped(int index) {
//     if (index == 4) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const ProfilePage()),
//       );
//     } else {
//       setState(() {
//         _selectedIndex = index;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//
//     return Scaffold(
//       // --- Bottom Navigation Bar ---
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         backgroundColor: kDarkBlue,
//         selectedItemColor: kOrange,
//         unselectedItemColor: kWhite,
//         showSelectedLabels: false,
//         showUnselectedLabels: false,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
//           BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
//           BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: ''),
//           BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
//           BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
//         ],
//       ),
//
//       // --- Main Body ---
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             // 🔎 Search Bar
//             SliverPadding(
//               padding: const EdgeInsets.all(12),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate([
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[50],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const TextField(
//                       decoration: InputDecoration(
//                         icon: Icon(Icons.search, color: kOrange),
//                         hintText: "Search location",
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                 ]),
//               ),
//             ),
//
//             // 🌍 Map Section
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: SizedBox(
//                     height: 250,
//                     width: double.infinity,
//                     child: _mapCenter == null
//                         ? const Center(
//                       child: CircularProgressIndicator(color: kDarkBlue),
//                     )
//                         : FlutterMap(
//                       options: MapOptions(
//                         initialCenter: _mapCenter!,
//                         initialZoom: 13,
//                       ),
//                       children: [
//                         TileLayer(
//                           urlTemplate:
//                           "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                           userAgentPackageName: 'com.example.citysync',
//                         ),
//                         MarkerLayer(
//                           markers: [
//                             Marker(
//                               point: _mapCenter!,
//                               width: 40,
//                               height: 40,
//                               child: const Icon(
//                                 Icons.location_on,
//                                 color: kOrange,
//                                 size: 30,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             const SliverToBoxAdapter(child: SizedBox(height: 12)),
//
//             // 📍 Location Cards (Sample placeholder)
//             SliverList(
//               delegate: SliverChildBuilderDelegate(
//                     (context, index) {
//                   return Card(
//                     margin:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 3,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Image
//                         Container(
//                           height: 150,
//                           decoration: const BoxDecoration(
//                             borderRadius:
//                             BorderRadius.vertical(top: Radius.circular(12)),
//                             image: DecorationImage(
//                               image: NetworkImage("https://picsum.photos/400/200"),
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                         // Price + Button
//                         Padding(
//                           padding: const EdgeInsets.all(12),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               const Text(
//                                 "\$123 / night",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                   color: kDarkBlue,
//                                 ),
//                               ),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => const ReviewsPage(),
//                                     ),
//                                   );
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: kOrange,
//                                   foregroundColor: kWhite,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 child: const Text("Select"),
//                               )
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//                 childCount: 3,
//               ),
//             ),
//
//             const SliverToBoxAdapter(child: SizedBox(height: 12)),
//
//             // 👥 Firebase User Profiles Carousel
//             SliverToBoxAdapter(
//               child: SizedBox(
//                 height: 150,
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance.collection('users').snapshots(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(
//                           child: CircularProgressIndicator(color: kDarkBlue));
//                     }
//                     if (snapshot.hasError) {
//                       return Center(child: Text("Error: ${snapshot.error}"));
//                     }
//                     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                       return const Center(child: Text("No users found"));
//                     }
//
//                     // Filter out currently logged-in user
//                     final users = snapshot.data!.docs
//                         .where((doc) => doc.id != currentUserId)
//                         .toList();
//
//                     if (users.isEmpty) {
//                       return const Center(child: Text("No other users"));
//                     }
//
//                     return ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: users.length,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 12),
//                       itemBuilder: (context, index) {
//                         final userDoc = users[index];
//                         final user = userDoc.data() as Map<String, dynamic>;
//                         final name = user['name'] ?? "No name";
//                         final photoUrl = user['profilePhotoUrl'];
//
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8),
//                           child: Column(
//                             children: [
//                               // Avatar (clickable)
//                               GestureDetector(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           PublicProfilePage(userId: userDoc.id),
//                                     ),
//                                   );
//                                 },
//                                 child: CircleAvatar(
//                                   radius: 28,
//                                   backgroundColor: kOrange.withOpacity(0.2),
//                                   backgroundImage: (photoUrl != null &&
//                                       photoUrl.toString().isNotEmpty)
//                                       ? NetworkImage(photoUrl)
//                                       : null,
//                                   child: (photoUrl == null ||
//                                       photoUrl.toString().isEmpty)
//                                       ? Text(
//                                     name[0],
//                                     style: const TextStyle(
//                                       color: kDarkBlue,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   )
//                                       : null,
//                                 ),
//                               ),
//                               const SizedBox(height: 6),
//                               Text(
//                                 name,
//                                 style: const TextStyle(color: kDarkBlue),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//
//             const SliverToBoxAdapter(child: SizedBox(height: 20)),
//           ],
//         ),
//       ),
//     );
//   }
// }
