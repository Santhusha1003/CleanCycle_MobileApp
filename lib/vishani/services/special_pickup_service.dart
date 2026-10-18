import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/special_pickup_model.dart';
import 'storage_service.dart';

/// Real resident-owned requests only. Firestore remains the authorization layer;
/// failed writes propagate instead of being reported as successful demo bookings.
class SpecialPickupService {
  SpecialPickupService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
    String? Function()? authenticatedUid,
  }) : _firestore = firestore,
       _storageService = storageService ?? StorageService(),
       _authenticatedUid =
           authenticatedUid ?? (() => FirebaseAuth.instance.currentUser?.uid);
  final FirebaseFirestore? _firestore;
  final StorageService _storageService;
  final String? Function() _authenticatedUid;
  FirebaseFirestore get _instance => _firestore ?? FirebaseFirestore.instance;
  String _uid() {
    final uid = _authenticatedUid();
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in to access your requests.');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _ref(String id) {
    if (id.isEmpty || id.contains('/')) {
      throw ArgumentError('Invalid request ID.');
    }
    return _instance.collection('special_pickups').doc(id);
  }

  Future<DocumentReference<Map<String, dynamic>>> _owned(String id) async {
    final uid = _uid();
    final ref = _ref(id);
    final snapshot = await ref.get();
    if (snapshot.data()?['userId'] != uid) {
      throw StateError('Request does not belong to this account.');
    }
    if (_uid() != uid) throw StateError('Account changed.');
    return ref;
  }

  Future<String> createPickupRequest(
    SpecialPickupModel pickup,
    List<File> photos,
  ) async {
    final uid = _uid();
    if (pickup.userId != uid ||
        pickup.status.toLowerCase() != 'pending' ||
        pickup.assignedDriverUid != null ||
        pickup.assignedDriverId != null ||
        pickup.assignedVehicleId != null) {
      throw StateError(
        'New requests must belong to you and await administrator assignment.',
      );
    }
    final ref = pickup.requestId.isEmpty
        ? _instance.collection('special_pickups').doc()
        : _ref(pickup.requestId);
    final urls = [...pickup.photoUrls];
    if (photos.isNotEmpty) {
      urls.addAll(
        await _storageService.uploadSpecialPickupPhotos(photos, ref.id),
      );
    }
    if (_uid() != uid) throw StateError('Account changed.');
    await ref.set(pickup.copyWith(requestId: ref.id, photoUrls: urls).toMap());
    return ref.id;
  }

  Stream<SpecialPickupModel?> getPickupStream(String requestId) {
    final uid = _uid();
    return _ref(requestId).snapshots().map((doc) {
      if (_uid() != uid) throw StateError('Account changed.');
      if (!doc.exists) return null;
      final pickup = SpecialPickupModel.fromFirestore(doc);
      if (pickup.userId != uid) {
        throw StateError('Request does not belong to this account.');
      }
      return pickup;
    });
  }

  Stream<List<SpecialPickupModel>> getUserPickupsStream(String userId) {
    if (_uid() != userId) {
      return Stream.error(StateError('Request owner must match your account.'));
    }
    return _instance
        .collection('special_pickups')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (_uid() != userId) throw StateError('Account changed.');
          return snapshot.docs
              .map(SpecialPickupModel.fromFirestore)
              .where((row) => row.userId == userId)
              .toList();
        });
  }

  Future<void> reschedulePickup(String id, DateTime date, String slot) async {
    await (await _owned(
      id,
    )).update({'scheduledDate': Timestamp.fromDate(date), 'timeSlot': slot});
  }

  Future<void> updatePickupNotes(String id, String notes) async {
    await (await _owned(id)).update({'notes': notes});
  }

  Future<void> cancelPickup(String id) async {
    await (await _owned(id)).delete();
  }

  Future<void> cancelPickupRequest(String id) => cancelPickup(id);
  Future<void> updatePickupStatus(String id, String status) async {
    // Assignment/approval is not an owner action. Rules enforce this too.
    if (status.toLowerCase() != 'cancelled') {
      throw StateError('Status changes require an administrator.');
    }
    await (await _owned(id)).update({'status': status});
  }
}
