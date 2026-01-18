import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

/// Service for handling Cloudinary image and video uploads
/// Reusable across the app for profile photos, location images, and videos
class CloudinaryService {
  static const String _cloudName = "dz2mprd0y";
  static const String _uploadPreset = "test_upload";

  final ImagePicker _picker = ImagePicker();

  // ============= IMAGE METHODS =============

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

  // ============= VIDEO METHODS =============

  /// Pick a video from device gallery
  /// Returns [XFile] on mobile, requires readAsBytes() for web
  Future<XFile?> pickVideoFromGallery() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2), // Limit video length
      );
      return picked;
    } catch (e) {
      throw Exception('Error picking video: $e');
    }
  }

  /// Pick a video from device camera
  Future<XFile?> pickVideoFromCamera() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2), // Limit video length
      );
      return picked;
    } catch (e) {
      throw Exception('Error recording video: $e');
    }
  }

  /// Upload video to Cloudinary
  /// Handles both mobile (File) and web (bytes) platforms
  /// Returns the secure URL from Cloudinary
  ///
  /// Note: Video uploads may take longer than images
  Future<String> uploadVideo(XFile pickedVideo, {
    Function(double)? onProgress,
  }) async {
    try {
      const cloudName = _cloudName;
      const uploadPreset = _uploadPreset;

      final dio = Dio();
      FormData formData;

      if (kIsWeb) {
        // Web: Use bytes
        final videoBytes = await pickedVideo.readAsBytes();
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(
            videoBytes,
            filename: "upload.mp4",
          ),
          "upload_preset": uploadPreset,
          "resource_type": "video", // Important: specify video type
        });
      } else {
        // Mobile: Use file path
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(
            pickedVideo.path,
            filename: "upload.mp4",
          ),
          "upload_preset": uploadPreset,
          "resource_type": "video", // Important: specify video type
        });
      }

      final response = await dio.post(
        "https://api.cloudinary.com/v1_1/$cloudName/video/upload",
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total != -1) {
            final progress = sent / total;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading video to Cloudinary: $e');
    }
  }

  /// Convenience method: Pick and upload video in one call
  /// Returns the Cloudinary URL
  Future<String> pickAndUploadVideo({
    required ImageSource source,
    Function(double)? onProgress,
  }) async {
    XFile? pickedVideo;

    if (source == ImageSource.gallery) {
      pickedVideo = await pickVideoFromGallery();
    } else {
      pickedVideo = await pickVideoFromCamera();
    }

    if (pickedVideo == null) {
      throw Exception('No video selected');
    }

    return uploadVideo(pickedVideo, onProgress: onProgress);
  }

  /// Upload multiple videos and return their URLs
  /// Useful for batch uploads in forms
  Future<List<String>> uploadMultipleVideos(
      List<XFile> videos, {
        Function(int current, int total, double progress)? onProgress,
      }) async {
    final List<String> urls = [];

    for (int i = 0; i < videos.length; i++) {
      final url = await uploadVideo(
        videos[i],
        onProgress: (progress) {
          if (onProgress != null) {
            onProgress(i + 1, videos.length, progress);
          }
        },
      );
      urls.add(url);
    }

    return urls;
  }

  /// Get video thumbnail URL from Cloudinary
  /// Cloudinary automatically generates thumbnails for videos
  /// Just append .jpg to get a thumbnail frame
  String getVideoThumbnail(String videoUrl) {
    // Replace the extension with .jpg to get a thumbnail
    // Example: video.mp4 -> video.jpg
    return videoUrl.replaceAll(RegExp(r'\.(mp4|mov|avi|webm)$'), '.jpg');
  }
}