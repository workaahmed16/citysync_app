import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  String selectedCountry = "Australia"; // default
  bool _isLoading = false;

  final List<String> countries = ["Australia", "USA", "UK"]; // ✅ valid list

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      bioController.text = data['bio'] ?? '';

      final countryFromDb = data['location'] ?? 'Nigeria';
      // ✅ ensure country is valid
      if (countries.contains(countryFromDb)) {
        selectedCountry = countryFromDb;
      } else {
        selectedCountry = countries.first;
      }

      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'location': selectedCountry,
      });

      if (mounted) Navigator.pop(context); // ✅ Go back to ProfilePage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving changes: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ safety check
    if (!countries.contains(selectedCountry)) {
      selectedCountry = countries.first;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile picture
            const Center(
              child: CircleAvatar(
                radius: 55,
                backgroundImage: NetworkImage("https://picsum.photos/200"),
              ),
            ),
            const SizedBox(height: 30),

            // Name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Email (read-only)
            TextField(
              controller: emailController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Email (cannot be changed)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Bio
            TextField(
              controller: bioController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Country
            DropdownButtonFormField<String>(
              value: selectedCountry,
              items: countries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedCountry = value!);
              },
              decoration: const InputDecoration(
                labelText: "Country/Region",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
