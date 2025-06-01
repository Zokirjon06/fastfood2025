import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for handling image uploads with Firebase Storage fallback
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Flag to track if Firebase Storage is available
  // Temporarily disabled until Firebase Storage is properly configured
  static bool _isFirebaseStorageAvailable = false;

  /// Saves image locally and returns the local path
  /// This is used as a fallback when Firebase Storage is not available
  static Future<String> _saveImageLocally({
    required File imageFile,
    String? fileName,
  }) async {
    try {
      // Get app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory(path.join(appDocDir.path, 'product_images'));

      // Create directory if it doesn't exist
      if (!imagesDir.existsSync()) {
        await imagesDir.create(recursive: true);
      }

      // Generate unique filename if not provided
      final String finalFileName = fileName ??
          'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Copy image to app directory
      final String localPath = path.join(imagesDir.path, finalFileName);
      final File localFile = await imageFile.copy(localPath);

      debugPrint('✅ Image saved locally: ${localFile.path}');
      return localFile.path;

    } catch (e) {
      debugPrint('❌ Error saving image locally: $e');
      throw Exception('Failed to save image locally: ${e.toString()}');
    }
  }

  /// Uploads an image file to Firebase Storage and returns the download URL
  /// Falls back to local storage if Firebase Storage is not available
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
    // Validate image file exists
    if (!imageFile.existsSync()) {
      throw Exception('Image file does not exist');
    }

    // Validate file size (max 10MB)
    final int fileSizeInBytes = imageFile.lengthSync();
    const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    if (fileSizeInBytes > maxSizeInBytes) {
      throw Exception('File size too large. Maximum 10MB allowed.');
    }

    debugPrint('Starting upload for file: ${imageFile.path}');
    debugPrint('File size: ${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB');

    // Try Firebase Storage first if available
    if (_isFirebaseStorageAvailable) {
      try {
        return await _uploadToFirebaseStorage(
          imageFile: imageFile,
          fileName: fileName,
          folder: folder,
        );
      } on FirebaseException catch (e) {
        debugPrint('❌ Firebase Storage error: ${e.code} - ${e.message}');

        // Mark Firebase Storage as unavailable for certain errors
        if (e.code == 'storage/object-not-found' ||
            e.code == 'storage/unauthorized' ||
            e.code == 'storage/unknown' ||
            e.code == 'object-not-found') { // Handle both formats
          debugPrint('🔄 Firebase Storage unavailable (${e.code}), switching to local storage');
          _isFirebaseStorageAvailable = false;
        } else {
          // Re-throw other Firebase errors
          throw Exception('Firebase Storage error: ${e.message ?? e.code}');
        }
      } catch (e) {
        debugPrint('❌ Unexpected error with Firebase Storage: $e');
        _isFirebaseStorageAvailable = false;
      }
    }

    // Fallback to local storage
    debugPrint('📁 Using local storage fallback');
    return await _saveImageLocally(
      imageFile: imageFile,
      fileName: fileName,
    );
  }

  /// Uploads image to Firebase Storage
  static Future<String> _uploadToFirebaseStorage({
    required File imageFile,
    String? fileName,
    String folder = 'products',
  }) async {
    // Check if user is authenticated
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated. Please login first.');
    }

    // Generate unique filename if not provided
    final String finalFileName = fileName ??
        'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Create reference to Firebase Storage with proper path
    final Reference storageRef = _storage
        .ref()
        .child(folder)
        .child(finalFileName);

    debugPrint('Storage reference path: ${storageRef.fullPath}');

    // Set metadata for the upload
    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uploadedBy': currentUser.uid,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    // Upload file with metadata
    final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);

    // Monitor upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
      debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
    });

    // Wait for upload to complete
    final TaskSnapshot snapshot = await uploadTask;

    // Verify upload completed successfully
    if (snapshot.state != TaskState.success) {
      throw Exception('Upload failed with state: ${snapshot.state}');
    }

    // Get download URL
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    debugPrint('✅ Image uploaded to Firebase Storage: $downloadUrl');
    return downloadUrl;
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

  /// Tests Firebase Storage connectivity
  ///
  /// Returns true if storage is accessible, false otherwise
  static Future<bool> testStorageConnectivity() async {
    // If we already know Firebase Storage is unavailable, don't test again
    if (!_isFirebaseStorageAvailable) {
      debugPrint('📁 Firebase Storage marked as unavailable, using local storage');
      return false;
    }

    try {
      // Check if user is authenticated
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Storage test failed: User not authenticated');
        return false;
      }

      // Try to access storage root
      final Reference testRef = _storage.ref().child('test');

      // Try to get metadata (this will fail if storage is not accessible)
      try {
        await testRef.getMetadata();
      } on FirebaseException catch (e) {
        if (e.code == 'storage/object-not-found' || e.code == 'object-not-found') {
          // This error actually means the storage bucket doesn't exist
          debugPrint('❌ Firebase Storage bucket not found: ${e.code} - ${e.message}');
          _isFirebaseStorageAvailable = false;
          return false;
        } else {
          // Other Firebase errors indicate storage issues
          debugPrint('❌ Firebase Storage error: ${e.code} - ${e.message}');
          _isFirebaseStorageAvailable = false;
          return false;
        }
      } catch (e) {
        debugPrint('❌ Storage connectivity test failed: $e');
        _isFirebaseStorageAvailable = false;
        return false;
      }

      debugPrint('✅ Firebase Storage connectivity test passed');
      return true;

    } catch (e) {
      debugPrint('❌ Storage connectivity test failed: $e');
      _isFirebaseStorageAvailable = false;
      return false;
    }
  }

  /// Uploads image with retry mechanism and fallback
  ///
  /// [imageFile] - The local image file to upload
  /// [fileName] - Optional custom file name
  /// [maxRetries] - Maximum number of retry attempts for Firebase Storage (default: 2)
  ///
  /// Returns the download URL or local path of the uploaded image
  static Future<String> uploadProductImageWithRetry({
    required File imageFile,
    String? fileName,
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    Exception? lastException;

    // Try Firebase Storage with retries only if it's available
    if (_isFirebaseStorageAvailable) {
      while (attempts < maxRetries) {
        try {
          attempts++;
          debugPrint('Firebase Storage upload attempt $attempts/$maxRetries');

          // Test connectivity first
          final bool isConnected = await testStorageConnectivity();
          if (!isConnected) {
            debugPrint('🔄 Firebase Storage not accessible, switching to local storage');
            break; // Exit retry loop and use local storage
          }

          // Attempt upload to Firebase Storage
          return await _uploadToFirebaseStorage(
            imageFile: imageFile,
            fileName: fileName,
          );

        } on FirebaseException catch (e) {
          lastException = Exception('Firebase Storage error: ${e.message ?? e.code}');
          debugPrint('Firebase Storage attempt $attempts failed: ${e.code} - ${e.message}');

          // For certain errors, don't retry and switch to local storage immediately
          if (e.code == 'storage/object-not-found' ||
              e.code == 'storage/unauthorized' ||
              e.code == 'storage/unknown' ||
              e.code == 'object-not-found') { // Handle both formats
            debugPrint('🔄 Firebase Storage unavailable (${e.code}), switching to local storage');
            _isFirebaseStorageAvailable = false;
            break;
          }

          if (attempts < maxRetries) {
            // Wait before retry (exponential backoff)
            final int delaySeconds = attempts * 2;
            debugPrint('Retrying Firebase Storage in $delaySeconds seconds...');
            await Future.delayed(Duration(seconds: delaySeconds));
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          debugPrint('Upload attempt $attempts failed: $e');
          _isFirebaseStorageAvailable = false;
          break;
        }
      }
    }

    // Fallback to local storage
    try {
      debugPrint('📁 Using local storage fallback');
      return await _saveImageLocally(
        imageFile: imageFile,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('❌ Local storage also failed: $e');
      throw lastException ?? Exception('Both Firebase Storage and local storage failed');
    }
  }
}
