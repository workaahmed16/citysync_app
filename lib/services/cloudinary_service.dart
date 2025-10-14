import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

/// Service for handling Cloudinary image uploads
/// Reusable across the app for profile photos and other images
class CloudinaryService {
  static const String _cloudName = "dutnlgohc";
  static const String _uploadPreset = "flutter_upload";

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from device gallery
  /// Returns [XFile] on mobile, requires readAsBytes() for web
  Future<XFile?> pickImageFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      return picked;
    } catch (e) {
      throw Exception('Error picking image: $e');
    }
  }

  /// Pick an image from device camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      return picked;
    } catch (e) {
      throw Exception('Error taking photo: $e');
    }
  }

  /// Upload image to Cloudinary
  /// Handles both mobile (File) and web (bytes) platforms
  /// Returns the secure URL from Cloudinary
  Future<String> uploadImage(XFile pickedImage) async {
    try {
      const cloudName = _cloudName;
      const uploadPreset = _uploadPreset;

      final dio = Dio();
      FormData formData;

      if (kIsWeb) {
        // Web: Use bytes
        final imageBytes = await pickedImage.readAsBytes();
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(
            imageBytes,
            filename: "upload.jpg",
          ),
          "upload_preset": uploadPreset,
        });
      } else {
        // Mobile: Use file path
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(
            pickedImage.path,
            filename: "upload.jpg",
          ),
          "upload_preset": uploadPreset,
        });
      }

      final response = await dio.post(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  /// Convenience method: Pick and upload image in one call
  /// Returns the Cloudinary URL
  Future<String> pickAndUploadImage({required ImageSource source}) async {
    XFile? pickedImage;

    if (source == ImageSource.gallery) {
      pickedImage = await pickImageFromGallery();
    } else {
      pickedImage = await pickImageFromCamera();
    }

    if (pickedImage == null) {
      throw Exception('No image selected');
    }

    return uploadImage(pickedImage);
  }
}