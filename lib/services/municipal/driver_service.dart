import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/driver.dart';
import '../firebase/firebase_service.dart';
import '../firebase/firestore_service.dart';

/// Service for managing municipal driver records in Firestore.
class DriverServiceException implements Exception {
  const DriverServiceException(this.message);

  final String message;

  @override
  String toString() => 'DriverServiceException: $message';
}

class DriverService {
  DriverService({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  static const String collectionPath = 'drivers';
  static const Set<String> allowedStatuses = {
    'available',
    'assigned',
    'on_leave',
    'inactive',
  };

  final FirestoreService _firestoreService;

  String _normalizeDriverId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const DriverServiceException('driverId cannot be empty.');
    }
    return normalized;
  }

  String _normalizeTextField(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw DriverServiceException('$fieldName cannot be empty.');
    }
    return normalized;
  }

  String _documentPath(String driverId) =>
      '$collectionPath/${_normalizeDriverId(driverId)}';

  void _validateDriver(Driver driver) {
    _normalizeDriverId(driver.driverId);
    _normalizeTextField(driver.fullName, 'fullName');
    _normalizeTextField(driver.email, 'email');
    _normalizeTextField(driver.phoneNumber, 'phoneNumber');
    _normalizeTextField(driver.licenseNumber, 'licenseNumber');

    final normalizedStatus = driver.status.trim().toLowerCase();
    if (!allowedStatuses.contains(normalizedStatus)) {
      throw DriverServiceException(
        'status must be one of: ${allowedStatuses.toList().join(', ')}.',
      );
    }

    if (driver.assignedVehicleId != null &&
        driver.assignedVehicleId!.trim().isEmpty) {
      throw const DriverServiceException(
        'assignedVehicleId cannot be empty when provided.',
      );
    }

    if (driver.assignedZone != null && driver.assignedZone!.trim().isEmpty) {
      throw const DriverServiceException(
        'assignedZone cannot be empty when provided.',
      );
    }
  }

  Future<void> createDriver({required Driver driver}) async {
    try {
      final normalizedDriverId = _normalizeDriverId(driver.driverId);
      _validateDriver(
        Driver(
          driverId: normalizedDriverId,
          fullName: driver.fullName,
          email: driver.email,
          phoneNumber: driver.phoneNumber,
          licenseNumber: driver.licenseNumber,
          licenseExpiryDate: driver.licenseExpiryDate,
          assignedVehicleId: driver.assignedVehicleId,
          assignedZone: driver.assignedZone,
          status: driver.status,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final existingDriver = await getDriver(driverId: normalizedDriverId);
      if (existingDriver != null) {
        throw DriverServiceException(
          'Driver with driverId "$normalizedDriverId" already exists.',
        );
      }

      final driverToSave = Driver(
        driverId: normalizedDriverId,
        fullName: _normalizeTextField(driver.fullName, 'fullName'),
        email: _normalizeTextField(driver.email, 'email'),
        phoneNumber: _normalizeTextField(driver.phoneNumber, 'phoneNumber'),
        licenseNumber: _normalizeTextField(
          driver.licenseNumber,
          'licenseNumber',
        ),
        licenseExpiryDate: driver.licenseExpiryDate,
        assignedVehicleId: driver.assignedVehicleId?.trim().isEmpty == true
            ? null
            : driver.assignedVehicleId,
        assignedZone: driver.assignedZone?.trim().isEmpty == true
            ? null
            : driver.assignedZone,
        status: driver.status.trim().toLowerCase(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setDocument(
        path: _documentPath(normalizedDriverId),
        data: driverToSave.toMap(),
        merge: false,
      );
    } on DriverServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw DriverServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<Driver?> getDriver({required String driverId}) async {
    try {
      final normalizedDriverId = _normalizeDriverId(driverId);
      final data = await _firestoreService.getDocument(
        path: _documentPath(normalizedDriverId),
      );
      if (data == null) {
        return null;
      }
      return Driver.fromMap(data);
    } on DriverServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw DriverServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<List<Driver>> getDrivers() async {
    try {
      final docs = await _firestoreService.getCollection(path: collectionPath);

      if (docs.isEmpty) {
        return const <Driver>[];
      }

      return docs.map((data) => Driver.fromMap(data)).toList();
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }

  Future<void> updateDriver({
    required String driverId,
    required Driver driver,
  }) async {
    try {
      final normalizedDriverId = _normalizeDriverId(driverId);

      if (driver.driverId.trim() != normalizedDriverId) {
        throw DriverServiceException(
          'Driver driverId must match the document ID path.',
        );
      }

      final existingDriver = await getDriver(driverId: normalizedDriverId);
      if (existingDriver == null) {
        throw DriverServiceException(
          'Driver with driverId "$normalizedDriverId" does not exist.',
        );
      }

      _validateDriver(
        Driver(
          driverId: normalizedDriverId,
          fullName: driver.fullName,
          email: driver.email,
          phoneNumber: driver.phoneNumber,
          licenseNumber: driver.licenseNumber,
          licenseExpiryDate: driver.licenseExpiryDate,
          assignedVehicleId: driver.assignedVehicleId,
          assignedZone: driver.assignedZone,
          status: driver.status,
          createdAt: existingDriver.createdAt,
          updatedAt: DateTime.now(),
        ),
      );

      final updatedDriver = Driver(
        driverId: normalizedDriverId,
        fullName: _normalizeTextField(driver.fullName, 'fullName'),
        email: _normalizeTextField(driver.email, 'email'),
        phoneNumber: _normalizeTextField(driver.phoneNumber, 'phoneNumber'),
        licenseNumber: _normalizeTextField(
          driver.licenseNumber,
          'licenseNumber',
        ),
        licenseExpiryDate: driver.licenseExpiryDate,
        assignedVehicleId: driver.assignedVehicleId?.trim().isEmpty == true
            ? null
            : driver.assignedVehicleId,
        assignedZone: driver.assignedZone?.trim().isEmpty == true
            ? null
            : driver.assignedZone,
        status: driver.status.trim().toLowerCase(),
        createdAt: existingDriver.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setDocument(
        path: _documentPath(normalizedDriverId),
        data: updatedDriver.toMap(),
        merge: false,
      );
    } on DriverServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw DriverServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<void> deleteDriver({required String driverId}) async {
    try {
      final normalizedDriverId = _normalizeDriverId(driverId);
      final existingDriver = await getDriver(driverId: normalizedDriverId);
      if (existingDriver == null) {
        throw DriverServiceException(
          'Driver with driverId "$normalizedDriverId" does not exist.',
        );
      }

      await _firestoreService.deleteDocument(
        path: _documentPath(normalizedDriverId),
      );
    } on DriverServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }
}
