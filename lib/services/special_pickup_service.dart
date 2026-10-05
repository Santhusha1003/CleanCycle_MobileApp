import 'dart:io';
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

    if (!_isFirebaseAvailable) {
      _mockPickups.insert(0, newPickup);
      return id;
    }

    try {
      await _instance.collection('special_pickups').doc(id).set(newPickup.toMap());
      return id;
    } catch (e) {
      _mockPickups.insert(0, newPickup);
      return id;
    }
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
          .map((doc) => doc.exists ? SpecialPickupModel.fromFirestore(doc) : null);
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
          .map((snapshot) => snapshot.docs
              .map((doc) => SpecialPickupModel.fromFirestore(doc))
              .toList());
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
      } catch (_) {}
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
      } catch (_) {}
    }
  }

  /// [DELETE] Cancel / Withdraw a pickup request
  Future<void> cancelPickup(String requestId) async {
    _mockPickups.removeWhere((p) => p.requestId == requestId);

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('special_pickups').doc(requestId).delete();
      } catch (_) {}
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
      } catch (_) {}
    }
  }
}
