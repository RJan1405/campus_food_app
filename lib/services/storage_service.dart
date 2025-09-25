import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Test Firebase Storage connectivity
  Future<bool> testStorageConnection() async {
    try {
      if (kDebugMode) {
        print('Testing Firebase Storage connection...');
        print('Storage bucket: ${_storage.bucket}');
      }
      
      // Try to get a reference to the root
      final ref = _storage.ref();
      
      // Try to list files in root (this will fail if storage is not enabled)
      await ref.listAll();
      
      if (kDebugMode) {
        print('Firebase Storage connection successful!');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Storage connection failed: $e');
        print('Please ensure Firebase Storage is enabled in your Firebase Console');
        print('Go to: https://console.firebase.google.com/project/campus-food-app-75fc7/storage');
        print('For now, using mock storage service...');
      }
      return false;
    }
  }

  // Mock upload for development when Firebase Storage is not enabled
  Future<String> mockUploadFile(
    Uint8List fileBytes,
    String path,
    String fileName,
  ) async {
    if (kDebugMode) {
      print('Using mock storage service...');
      print('File path: $path');
      print('File name: $fileName');
      print('File size: ${fileBytes.length} bytes');
    }
    
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate a mock download URL
    final mockUrl = 'https://mock-storage.firebaseapp.com/$path';
    
    if (kDebugMode) {
      print('Mock upload successful: $mockUrl');
    }
    
    return mockUrl;
  }

  // Upload file to Firebase Storage
  Future<String> uploadFile(
    Uint8List fileBytes,
    String path,
    String fileName,
  ) async {
    try {
      if (kDebugMode) {
        print('Starting file upload...');
        print('File path: $path');
        print('File name: $fileName');
        print('File size: ${fileBytes.length} bytes');
        print('Storage bucket: ${_storage.bucket}');
      }
      
      // Create reference with proper metadata
      final ref = _storage.ref().child(path);
      
      // Set metadata for the upload
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'fileName': fileName,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      if (kDebugMode) {
        print('Uploading with metadata: $metadata');
      }
      
      final uploadTask = ref.putData(fileBytes, metadata);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (kDebugMode) {
          print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(2)}%');
        }
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('File uploaded successfully: $downloadUrl');
      }
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading file: $e');
        print('Error type: ${e.runtimeType}');
        if (e.toString().contains('object-not-found')) {
          print('Storage bucket may not exist or be accessible');
        }
      }
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload image file
  Future<String> uploadImage(
    Uint8List imageBytes,
    String path,
    String fileName,
  ) async {
    try {
      // Validate file size (max 10MB)
      if (imageBytes.length > 10 * 1024 * 1024) {
        throw Exception('File size too large. Maximum size is 10MB.');
      }

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'fileName': fileName,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putData(imageBytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('Image uploaded successfully: $downloadUrl');
      }
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload document file (PDF, etc.)
  Future<String> uploadDocument(
    Uint8List documentBytes,
    String path,
    String fileName,
  ) async {
    try {
      // Validate file size (max 20MB for documents)
      if (documentBytes.length > 20 * 1024 * 1024) {
        throw Exception('File size too large. Maximum size is 20MB.');
      }

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'fileName': fileName,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putData(documentBytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('Document uploaded successfully: $downloadUrl');
      }
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading document: $e');
      }
      throw Exception('Failed to upload document: $e');
    }
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      
      if (kDebugMode) {
        print('File deleted successfully: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
      throw Exception('Failed to delete file: $e');
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getMetadata();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting file metadata: $e');
      }
      throw Exception('Failed to get file metadata: $e');
    }
  }

  // Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // Validate file type
  bool isValidFileType(String fileName, List<String> allowedExtensions) {
    final extension = fileName.toLowerCase().split('.').last;
    return allowedExtensions.contains(extension);
  }

  // Get file size in MB
  double getFileSizeInMB(int bytes) {
    return bytes / (1024 * 1024);
  }

  // Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
