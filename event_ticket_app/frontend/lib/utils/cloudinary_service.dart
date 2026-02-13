import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // Cloudinary configuration
  static const String cloudName =
      'dtvbnyhvn'; // Your Cloudinary cloud name
  static const String uploadPreset =
      'event_images'; // Your unsigned upload preset

  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    cloudName,
    uploadPreset,
    cache: false,
  );

  /// Upload image from bytes (works on all platforms including web)
  static Future<String> uploadImageBytes(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      // Upload to Cloudinary using bytes
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: fileName,
          folder: 'event_images',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Return the secure URL of the uploaded image
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }
}
