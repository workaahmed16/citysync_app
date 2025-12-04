import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';
import '../services/embedding_service.dart';
import '../theme/colors.dart' as AppColors;
import '../widgets/nominatim_location_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController interestsController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();

  // Location data
  Map<String, dynamic>? _locationData;
  String? _displayLocationName;

  bool _isLoading = false;
  bool _isUploadingImage = false;

  // Image state
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  String? _uploadedImageUrl;

  final CloudinaryService _cloudinaryService = CloudinaryService();

  // IMPORTANT: Store your OpenAI API key securely
  // Consider using flutter_dotenv or Firebase Remote Config
  late final EmbeddingService _embeddingService;

  @override
  void initState() {
    super.initState();
    super.initState();
    _embeddingService = EmbeddingService(
      apiKey: dotenv.env['OPENAI_API_KEY']!, // ⬅️ LOADS FROM .env FILE
    );
    _loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    bioController.dispose();
    ageController.dispose();
    interestsController.dispose();
    instagramController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          bioController.text = data['bio'] ?? '';
          ageController.text = data['age']?.toString() ?? '';
          interestsController.text = data['interests'] ?? '';
          instagramController.text = data['instagram'] ?? '';
          _uploadedImageUrl = data['profilePhotoUrl'];

          if (data['locationData'] != null) {
            _locationData = Map<String, dynamic>.from(data['locationData']);
            _displayLocationName = _locationData!['display_name'];
          } else {
            final city = data['city'] ?? '';
            final country = data['country'] ?? data['location'] ?? '';
            if (city.isNotEmpty || country.isNotEmpty) {
              _displayLocationName = '$city, $country'.trim();
            }
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _isUploadingImage = true);

      final picked = await _cloudinaryService.pickImageFromGallery();
      if (picked == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      if (kIsWeb) {
        _pickedImageBytes = await picked.readAsBytes();
      } else {
        _pickedImage = picked;
      }

      final imageUrl = await _cloudinaryService.uploadImage(picked);

      if (mounted) {
        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Prepare basic update data
      final updateData = <String, dynamic>{
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 0,
        'interests': interestsController.text.trim(),
        'instagram': instagramController.text.trim(),
        if (_uploadedImageUrl != null) 'profilePhotoUrl': _uploadedImageUrl,
      };

      // Save location data if available
      if (_locationData != null) {
        updateData['locationData'] = _locationData;
        updateData['city'] = _locationData!['city'];
        updateData['country'] = _locationData!['country'];
        updateData['location'] = _locationData!['country'];
        updateData['lat'] = _locationData!['lat'];
        updateData['lng'] = _locationData!['lon'];
      }

      // Step 2: Generate embedding vector from profile text
      // Combine bio, interests, and location into searchable text
      final profileText = EmbeddingService.createProfileText(
        bio: bioController.text.trim(),
        interests: interestsController.text.trim(),
        location: _displayLocationName ?? '',
        city: _locationData?['city'],
        country: _locationData?['country'],
      );

      print('🔍 Generating embedding for profile text: $profileText');

      // Step 3: Call OpenAI API to generate the vector
      List<double>? profileVector;
      try {
        profileVector = await _embeddingService.generateEmbedding(profileText);
        print('✅ Embedding generated successfully: ${profileVector.length} dimensions');
      } catch (e) {
        print('⚠️ Failed to generate embedding: $e');
        // Continue saving without vector if embedding fails
        // You can choose to fail the entire save if preferred
      }

      // Step 4: Add vector and metadata to update data
      if (profileVector != null) {
        updateData['profile_vector'] = profileVector;
        updateData['vector_updated_at'] = FieldValue.serverTimestamp();
        updateData['profile_text'] = profileText; // Store for debugging/re-generation
      }

      print('💾 Saving profile with ${updateData.containsKey('profile_vector') ? 'vector' : 'no vector'}');

      // Step 5: Save everything to Firestore atomically
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              profileVector != null
                  ? 'Profile updated with vector search enabled!'
                  : 'Profile updated (vector generation failed)',
            ),
            backgroundColor: profileVector != null ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context, _uploadedImageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.kDarkBlue),
      filled: true,
      fillColor: AppColors.kWhite,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.kDarkBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.kOrange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      return NetworkImage(_uploadedImageUrl!);
    } else if (kIsWeb && _pickedImageBytes != null) {
      return MemoryImage(_pickedImageBytes!);
    } else if (!kIsWeb && _pickedImage != null) {
      return FileImage(File(_pickedImage!.path));
    } else {
      return const NetworkImage("https://picsum.photos/200");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.kWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: AppColors.kWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.kDarkBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Photo with Upload
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndUploadImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: _getAvatarImage(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.kWhite,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: _isUploadingImage
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.kOrange,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.edit,
                        size: 20,
                        color: AppColors.kOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: _inputDecoration("Name"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              readOnly: true,
              decoration: _inputDecoration("Email (cannot be changed)"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: bioController,
              maxLines: 2,
              decoration: _inputDecoration("Bio"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Age"),
            ),
            const SizedBox(height: 20),

            NominatimLocationPicker(
              initialLocation: _displayLocationName,
              onLocationSelected: (location) {
                setState(() {
                  _locationData = location;
                  _displayLocationName = location['display_name'];
                });
                print('Location selected: ${location['display_name']}');
                print('Coordinates: ${location['lat']}, ${location['lon']}');
              },
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
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kOrange,
                  foregroundColor: AppColors.kWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.kWhite)
                    : const Text(
                  "Save changes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}