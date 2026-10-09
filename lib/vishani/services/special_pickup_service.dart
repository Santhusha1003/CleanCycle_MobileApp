import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/special_pickup_model.dart';
import 'storage_service.dart';

class SpecialPickupService {
  final FirebaseFirestore? _firestore;
  final StorageService _storageService;

  SpecialPickupService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore,
        _storageService = storageService ?? StorageService();

  FirebaseFirestore get _instance {
    if (_firestore != null) return _firestore;
    return FirebaseFirestore.instance;
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // In-memory fallback cache for local testing / offline demo
  static final List<SpecialPickupModel> _mockPickups = [
    SpecialPickupModel(
      requestId: 'SP-20260814-002',
      userId: 'user_default',
      wasteType: 'Furniture',
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      timeSlot: '10-12 PM',
      address: 'No. 42, Galle Road, Colombo 03',
      notes: 'Old wooden sofa set and broken study table. Please call on arrival.',
      photoUrls: [
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=600&q=80',
      ],
      status: 'Assigned',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  /// [CREATE] Book a new Special Bulky Waste Pickup Request
  Future<String> createPickupRequest(SpecialPickupModel pickup, List<File> photos) async {
    final id = pickup.requestId.isEmpty
        ? 'SP-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().millisecond.toString().padLeft(3, '0')}'
        : pickup.requestId;

    List<String> photoUrls = List.from(pickup.photoUrls);
    if (photos.isNotEmpty) {
      final uploadedUrls = await _storageService.uploadSpecialPickupPhotos(photos, id);
      photoUrls.addAll(uploadedUrls);
    }

    final newPickup = pickup.copyWith(
      requestId: id,
      photoUrls: photoUrls,
    );

    _mockPickups.insert(0, newPickup);

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('special_pickups').doc(id).set(newPickup.toMap());
        debugPrint('Special pickup request successfully saved to Firestore: $id');
      } catch (e) {
        debugPrint('Firestore save error for special pickup: $e');
      }
    }
    return id;
  }

  /// [READ] Stream a single pickup booking (used for receipts & status timelines)
  Stream<SpecialPickupModel?> getPickupStream(String requestId) {
    if (!_isFirebaseAvailable) {
      final match = _mockPickups.where((p) => p.requestId == requestId);
      return Stream.value(match.isNotEmpty ? match.first : null);
    }

    try {
      return _instance
          .collection('special_pickups')
          .doc(requestId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return SpecialPickupModel.fromFirestore(doc);
        }
        final match = _mockPickups.where((p) => p.requestId == requestId);
        return match.isNotEmpty ? match.first : null;
      });
    } catch (_) {
      final match = _mockPickups.where((p) => p.requestId == requestId);
      return Stream.value(match.isNotEmpty ? match.first : null);
    }
  }

  /// [READ] Stream all special pickup bookings for a citizen
  Stream<List<SpecialPickupModel>> getUserPickupsStream(String userId) {
    if (!_isFirebaseAvailable) {
      return Stream.value(List.from(_mockPickups));
    }

    try {
      return _instance
          .collection('special_pickups')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => SpecialPickupModel.fromFirestore(doc)).toList();
        }
        return List<SpecialPickupModel>.from(_mockPickups);
      });
    } catch (_) {
      return Stream.value(List.from(_mockPickups));
    }
  }

  /// [UPDATE] Reschedule pickup date and time window
  Future<void> reschedulePickup(String requestId, DateTime newDate, String newSlot) async {
    final index = _mockPickups.indexWhere((p) => p.requestId == requestId);
    if (index != -1) {
      _mockPickups[index] = _mockPickups[index].copyWith(
        scheduledDate: newDate,
        timeSlot: newSlot,
      );
    }

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('special_pickups').doc(requestId).update({
          'scheduledDate': Timestamp.fromDate(newDate),
          'timeSlot': newSlot,
        });
        debugPrint('Pickup rescheduled in Firestore: $requestId');
      } catch (e) {
        debugPrint('Firestore update error on reschedule: $e');
      }
    }
  }

  /// [UPDATE] Update pickup instructions or notes
  Future<void> updatePickupNotes(String requestId, String newNotes) async {
    final index = _mockPickups.indexWhere((p) => p.requestId == requestId);
    if (index != -1) {
      _mockPickups[index] = _mockPickups[index].copyWith(notes: newNotes);
    }

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('special_pickups').doc(requestId).update({
          'notes': newNotes,
        });
      } catch (e) {
        debugPrint('Firestore update error on notes: $e');
      }
    }
  }

  /// [DELETE] Cancel / Withdraw a pickup request
  Future<void> cancelPickup(String requestId) async {
    _mockPickups.removeWhere((p) => p.requestId == requestId);

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('special_pickups').doc(requestId).delete();
        debugPrint('Pickup deleted from Firestore: $requestId');
      } catch (e) {
        debugPrint('Firestore delete error: $e');
      }
    }
  }

  /// [DELETE] Alias matching project architecture documentation
  Future<void> cancelPickupRequest(String requestId) => cancelPickup(requestId);

  /// [UPDATE] Update pickup status (e.g. Scheduled, In Progress, Cancelled)
  Future<void> updatePickupStatus(String requestId, String newStatus) async {
    final index = _mockPickups.indexWhere((p) => p.requestId == requestId);
    if (index != -1) {
      _mockPickups[index] = _mockPickups[index].copyWith(status: newStatus);
    }

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('special_pickups').doc(requestId).update({
          'status': newStatus,
        });
      } catch (e) {
        debugPrint('Firestore update error on status: $e');
      }
    }
  }
}
