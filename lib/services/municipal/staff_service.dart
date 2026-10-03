import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/staff.dart';
import '../firebase/firebase_service.dart';
import '../firebase/firestore_service.dart';

/// Service for managing municipal staff records in Firestore.
class StaffServiceException implements Exception {
  const StaffServiceException(this.message);

  final String message;

  @override
  String toString() => 'StaffServiceException: $message';
}

class StaffService {
  StaffService({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  static const String collectionPath = 'staff';
  static const Set<String> allowedStatuses = {'active', 'inactive', 'on_leave'};

  final FirestoreService _firestoreService;

  String _normalizeStaffId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const StaffServiceException('staffId cannot be empty.');
    }
    return normalized;
  }

  String _normalizeTextField(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw StaffServiceException('$fieldName cannot be empty.');
    }
    return normalized;
  }

  String _documentPath(String staffId) =>
      '$collectionPath/${_normalizeStaffId(staffId)}';

  void _validateStaff(Staff staff) {
    _normalizeStaffId(staff.staffId);
    _normalizeTextField(staff.fullName, 'fullName');
    _normalizeTextField(staff.email, 'email');
    _normalizeTextField(staff.phoneNumber, 'phoneNumber');
    _normalizeTextField(staff.position, 'position');

    final normalizedStatus = staff.status.trim().toLowerCase();
    if (!allowedStatuses.contains(normalizedStatus)) {
      throw StaffServiceException(
        'status must be one of: ${allowedStatuses.toList().join(', ')}.',
      );
    }

    if (staff.assignedZone != null && staff.assignedZone!.trim().isEmpty) {
      throw const StaffServiceException(
        'assignedZone cannot be empty when provided.',
      );
    }
  }

  Future<void> createStaff({required Staff staff}) async {
    try {
      final normalizedStaffId = _normalizeStaffId(staff.staffId);
      _validateStaff(
        Staff(
          staffId: normalizedStaffId,
          fullName: staff.fullName,
          email: staff.email,
          phoneNumber: staff.phoneNumber,
          position: staff.position,
          assignedZone: staff.assignedZone,
          status: staff.status,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final existingStaff = await getStaff(staffId: normalizedStaffId);
      if (existingStaff != null) {
        throw StaffServiceException(
          'Staff with staffId "$normalizedStaffId" already exists.',
        );
      }

      final staffToSave = Staff(
        staffId: normalizedStaffId,
        fullName: _normalizeTextField(staff.fullName, 'fullName'),
        email: _normalizeTextField(staff.email, 'email'),
        phoneNumber: _normalizeTextField(staff.phoneNumber, 'phoneNumber'),
        position: _normalizeTextField(staff.position, 'position'),
        assignedZone: staff.assignedZone?.trim().isEmpty == true
            ? null
            : staff.assignedZone,
        status: staff.status.trim().toLowerCase(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setDocument(
        path: _documentPath(normalizedStaffId),
        data: staffToSave.toMap(),
        merge: false,
      );
    } on StaffServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw StaffServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<Staff?> getStaff({required String staffId}) async {
    try {
      final normalizedStaffId = _normalizeStaffId(staffId);
      final data = await _firestoreService.getDocument(
        path: _documentPath(normalizedStaffId),
      );
      if (data == null) {
        return null;
      }
      return Staff.fromMap(data);
    } on StaffServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw StaffServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<List<Staff>> getStaffMembers() async {
    try {
      final docs = await _firestoreService.getCollection(path: collectionPath);

      if (docs.isEmpty) {
        return const <Staff>[];
      }

      return docs.map((data) => Staff.fromMap(data)).toList();
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }

  Future<void> updateStaff({
    required String staffId,
    required Staff staff,
  }) async {
    try {
      final normalizedStaffId = _normalizeStaffId(staffId);

      if (staff.staffId.trim() != normalizedStaffId) {
        throw StaffServiceException(
          'Staff staffId must match the document ID path.',
        );
      }

      final existingStaff = await getStaff(staffId: normalizedStaffId);
      if (existingStaff == null) {
        throw StaffServiceException(
          'Staff with staffId "$normalizedStaffId" does not exist.',
        );
      }

      _validateStaff(
        Staff(
          staffId: normalizedStaffId,
          fullName: staff.fullName,
          email: staff.email,
          phoneNumber: staff.phoneNumber,
          position: staff.position,
          assignedZone: staff.assignedZone,
          status: staff.status,
          createdAt: existingStaff.createdAt,
          updatedAt: DateTime.now(),
        ),
      );

      final updatedStaff = Staff(
        staffId: normalizedStaffId,
        fullName: _normalizeTextField(staff.fullName, 'fullName'),
        email: _normalizeTextField(staff.email, 'email'),
        phoneNumber: _normalizeTextField(staff.phoneNumber, 'phoneNumber'),
        position: _normalizeTextField(staff.position, 'position'),
        assignedZone: staff.assignedZone?.trim().isEmpty == true
            ? null
            : staff.assignedZone,
        status: staff.status.trim().toLowerCase(),
        createdAt: existingStaff.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setDocument(
        path: _documentPath(normalizedStaffId),
        data: updatedStaff.toMap(),
        merge: false,
      );
    } on StaffServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw StaffServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<void> deleteStaff({required String staffId}) async {
    try {
      final normalizedStaffId = _normalizeStaffId(staffId);
      final existingStaff = await getStaff(staffId: normalizedStaffId);
      if (existingStaff == null) {
        throw StaffServiceException(
          'Staff with staffId "$normalizedStaffId" does not exist.',
        );
      }

      await _firestoreService.deleteDocument(
        path: _documentPath(normalizedStaffId),
      );
    } on StaffServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }
}
