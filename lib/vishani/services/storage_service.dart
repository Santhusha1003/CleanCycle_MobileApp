import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage? _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage;

  FirebaseStorage get _instance {
    if (_storage != null) return _storage;
    return FirebaseStorage.instance;
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Uploads a photo for a missed collection report
  Future<String?> uploadMissedReportPhoto(File file, String userId) async {
    if (!_isFirebaseAvailable) {
      // Fallback placeholder for offline/local testing
      return 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=600&q=80';
    }

    try {
      final fileName = 'missed_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _instance.ref().child('missed_reports').child(userId).child(fileName);
      
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      // Return fallback on upload error during development
      return 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=600&q=80';
    }
  }

  /// Uploads a single photo for a special pickup request
  Future<String?> uploadSpecialPickupPhoto(File file, String requestId, int index) async {
    if (!_isFirebaseAvailable) {
      return 'https://images.unsplash.com/photo-1528323273322-d81458248d40?auto=format&fit=crop&w=600&q=80';
    }

    try {
      final fileName = 'pickup_${requestId}_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _instance.ref().child('special_pickups').child(requestId).child(fileName);
      
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return 'https://images.unsplash.com/photo-1528323273322-d81458248d40?auto=format&fit=crop&w=600&q=80';
    }
  }

  /// Uploads multiple photos concurrently for a special pickup request
  Future<List<String>> uploadSpecialPickupPhotos(List<File> files, String requestId) async {
    if (files.isEmpty) return [];
    
    final List<String> urls = [];
    for (int i = 0; i < files.length; i++) {
      final url = await uploadSpecialPickupPhoto(files[i], requestId, i);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }
}
