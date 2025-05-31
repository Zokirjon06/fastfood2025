import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for handling image uploads to Firebase Storage
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file to Firebase Storage and returns the download URL
  /// 
  /// [imageFile] - The local image file to upload
  /// [fileName] - Optional custom file name. If not provided, uses timestamp
  /// [folder] - The folder path in Firebase Storage (default: 'products')
  /// 
  /// Returns the download URL of the uploaded image
  /// Throws exception if upload fails
  static Future<String> uploadProductImage({
    required File imageFile,
    String? fileName,
    String folder = 'products',
  }) async {
    try {
      // Generate unique filename if not provided
      final String finalFileName = fileName ?? 
          'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create reference to Firebase Storage
      final Reference storageRef = _storage
          .ref()
          .child(folder)
          .child(finalFileName);

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Deletes an image from Firebase Storage using its URL
  /// 
  /// [imageUrl] - The download URL of the image to delete
  /// 
  /// Returns true if deletion was successful, false otherwise
  static Future<bool> deleteProductImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return false;
      
      // Create reference from URL
      final Reference imageRef = _storage.refFromURL(imageUrl);
      
      // Delete the file
      await imageRef.delete();
      
      debugPrint('Image deleted successfully: $imageUrl');
      return true;
      
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Updates an existing product image by uploading new image and deleting old one
  /// 
  /// [newImageFile] - The new image file to upload
  /// [oldImageUrl] - The URL of the old image to delete (optional)
  /// [fileName] - Optional custom file name for the new image
  /// 
  /// Returns the download URL of the new uploaded image
  static Future<String> updateProductImage({
    required File newImageFile,
    String? oldImageUrl,
    String? fileName,
  }) async {
    try {
      // Upload new image first
      final String newImageUrl = await uploadProductImage(
        imageFile: newImageFile,
        fileName: fileName,
      );
      
      // Delete old image if URL is provided and upload was successful
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteProductImage(oldImageUrl);
      }
      
      return newImageUrl;
      
    } catch (e) {
      debugPrint('Error updating image: $e');
      throw Exception('Failed to update image: ${e.toString()}');
    }
  }

  /// Validates if the provided file is a valid image
  /// 
  /// [imageFile] - The file to validate
  /// 
  /// Returns true if file is a valid image, false otherwise
  static bool isValidImageFile(File imageFile) {
    try {
      if (!imageFile.existsSync()) return false;
      
      final String extension = imageFile.path.toLowerCase();
      final List<String> validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
      
      return validExtensions.any((ext) => extension.endsWith(ext));
    } catch (e) {
      debugPrint('Error validating image file: $e');
      return false;
    }
  }

  /// Gets the file size in MB
  /// 
  /// [imageFile] - The file to check
  /// 
  /// Returns file size in MB
  static double getFileSizeInMB(File imageFile) {
    try {
      final int fileSizeInBytes = imageFile.lengthSync();
      return fileSizeInBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0.0;
    }
  }

  /// Validates image file size (max 5MB by default)
  /// 
  /// [imageFile] - The file to validate
  /// [maxSizeInMB] - Maximum allowed size in MB (default: 5MB)
  /// 
  /// Returns true if file size is within limit, false otherwise
  static bool isValidFileSize(File imageFile, {double maxSizeInMB = 5.0}) {
    try {
      final double fileSizeInMB = getFileSizeInMB(imageFile);
      return fileSizeInMB <= maxSizeInMB;
    } catch (e) {
      debugPrint('Error validating file size: $e');
      return false;
    }
  }
}
