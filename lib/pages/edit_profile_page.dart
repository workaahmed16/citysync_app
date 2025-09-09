import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

// 🎨 Color Scheme
const Color kDarkBlue = Color(0xFF0D47A1); // darker blue
const Color kOrange = Color(0xFFFF9800);   // material orange
const Color kWhite = Colors.white;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController interestsController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();

  String selectedCountry = "USA"; // default
  bool _isLoading = false;

  final List<String> countries = ["USA", "Australia", "UK"];

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes; // for web
  final ImagePicker _picker = ImagePicker();
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      bioController.text = data['bio'] ?? '';
      ageController.text = data['age']?.toString() ?? '';
      cityController.text = data['city'] ?? '';
      zipController.text = data['zip'] ?? '';
      interestsController.text = data['interests'] ?? '';
      instagramController.text = data['instagram'] ?? '';

      final countryFromDb = data['location'] ?? 'USA';
      selectedCountry =
      countries.contains(countryFromDb) ? countryFromDb : countries.first;

      final profileUrl = data['profilePhotoUrl'];
      if (profileUrl != null) _uploadedImageUrl = profileUrl;

      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (kIsWeb) {
          _pickedImageBytes = await picked.readAsBytes();
        } else {
          _pickedImage = picked;
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_pickedImage == null && _pickedImageBytes == null) {
      return _uploadedImageUrl;
    }

    const cloudName = "dutnlgohc"; // your cloud name
    const uploadPreset = "flutter_upload"; // unsigned preset

    try {
      final dio = Dio();
      FormData formData;

      if (kIsWeb && _pickedImageBytes != null) {
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(_pickedImageBytes!,
              filename: "upload.jpg"),
          "upload_preset": uploadPreset,
        });
      } else if (_pickedImage != null) {
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(_pickedImage!.path,
              filename: "upload.jpg"),
          "upload_preset": uploadPreset,
        });
      } else {
        return _uploadedImageUrl;
      }

      final response = await dio.post(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
        data: formData,
      );

      return response.data['secure_url'];
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error uploading image")),
      );
      return null;
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImageToCloudinary();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'location': selectedCountry,
        'age': int.tryParse(ageController.text.trim()) ?? 0,
        'city': cityController.text.trim(),
        'zip': zipController.text.trim(),
        'interests': interestsController.text.trim(),
        'instagram': instagramController.text.trim(),
        if (imageUrl != null) 'profilePhotoUrl': imageUrl,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving changes: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kDarkBlue),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: kDarkBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kOrange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = kIsWeb
        ? (_pickedImageBytes != null
        ? MemoryImage(_pickedImageBytes!)
        : (_uploadedImageUrl != null
        ? NetworkImage(_uploadedImageUrl!)
        : const NetworkImage("https://picsum.photos/200")))
        : (_pickedImage != null
        ? FileImage(File(_pickedImage!.path))
        : (_uploadedImageUrl != null
        ? NetworkImage(_uploadedImageUrl!)
        : const NetworkImage("https://picsum.photos/200")));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: kWhite, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: kDarkBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundImage: avatarImage as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: kWhite,
                    child: const Icon(Icons.edit, size: 20, color: kOrange),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(controller: nameController, decoration: _inputDecoration("Name")),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              readOnly: true,
              decoration: _inputDecoration("Email (cannot be changed)"),
            ),
            const SizedBox(height: 20),
            TextField(controller: bioController, maxLines: 2, decoration: _inputDecoration("Bio")),
            const SizedBox(height: 20),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Age"),
            ),
            const SizedBox(height: 20),
            TextField(controller: cityController, decoration: _inputDecoration("City")),
            const SizedBox(height: 20),
            TextField(
              controller: zipController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Zip Code"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: interestsController,
              maxLines: 3,
              decoration: _inputDecoration("Interests / Hobbies"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: instagramController,
              decoration: _inputDecoration("Instagram Handle (without @)"),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedCountry,
              items: countries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCountry = value!),
              decoration: _inputDecoration("Country/Region"),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator(color: kWhite)
                    : const Text("Save changes", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
