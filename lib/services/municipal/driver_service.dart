import 'package:firebase_auth/firebase_auth.dart';

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
  DriverService({
    FirestoreService? firestoreService,
    String? Function()? authenticatedUid,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _authenticatedUid =
           authenticatedUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  static const String collectionPath = 'drivers';
  static const Set<String> allowedStatuses = {
    'available',
    'assigned',
    'on_leave',
    'inactive',
  };

  final FirestoreService _firestoreService;
  final String? Function() _authenticatedUid;

  /// Resolves a municipal record to exactly one approved Driver profile.
  /// It never treats driverId as an Auth UID and only persists the UID after
  /// validating the signed-in officer and the matched profile's role.
  Future<String> resolveVerifiedAuthUid({required String driverId}) async {
    final officerUid = _authenticatedUid();
    if (officerUid == null || officerUid.isEmpty) {
      throw const DriverServiceException('Sign in as a Municipal Officer.');
    }
    final officer = await _firestoreService.getDocument(
      path: 'users/$officerUid',
    );
    if (officer?['role'] != 'municipal_officer' &&
        officer?['role'] != 'officer') {
      throw const DriverServiceException(
        'Only an authorized Municipal Officer can assign a Driver.',
      );
    }
    final record = await getDriver(driverId: driverId);
    if (record == null) {
      throw const DriverServiceException(
        'The selected Driver no longer exists.',
      );
    }
    final normalizedEmail = record.email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const DriverServiceException(
        'This Driver record has no account email to verify.',
      );
    }
    final emailVariants = {record.email.trim(), normalizedEmail}.toList();
    final profiles = await _firestoreService.firestore
        .collection('users')
        .where('email', whereIn: emailVariants)
        .get();
    final matches = profiles.docs.where((profile) {
      final data = profile.data();
      return (data['email'] as String?)?.trim().toLowerCase() ==
              normalizedEmail &&
          data['role'] == 'driver' &&
          data['uid'] == profile.id;
    }).toList();
    if (matches.length != 1) {
      throw DriverServiceException(
        matches.isEmpty
            ? 'No verified Driver account matches ${record.email}.'
            : 'More than one Driver account matches ${record.email}.',
      );
    }
    if (matches.single.id == officerUid) {
      throw const DriverServiceException(
        'A Municipal Officer cannot assign their own account as a Driver.',
      );
    }
    final verifiedUid = matches.single.id;
    if (_authenticatedUid() != officerUid) {
      throw const DriverServiceException('The signed-in account changed.');
    }
    if (record.authUid != verifiedUid) {
      await _firestoreService.updateDocument(
        path: _documentPath(record.driverId),
        data: {'authUid': verifiedUid},
      );
    }
    return verifiedUid;
  }

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

  /// Loads only the municipal Driver record linked to this authenticated UID.
  /// Firestore rules enforce the same verified authUid relationship.
  Future<Driver?> getDriverForAuthUid({required String authUid}) async {
    final normalizedUid = authUid.trim();
    if (normalizedUid.isEmpty || _authenticatedUid() != normalizedUid) {
      throw const DriverServiceException(
        'Sign in to view your linked Driver record.',
      );
    }
    try {
      final snapshot = await _firestoreService.firestore
          .collection(collectionPath)
          .where('authUid', isEqualTo: normalizedUid)
          .get();
      if (snapshot.docs.isEmpty) return null;
      if (snapshot.docs.length != 1) {
        throw const DriverServiceException(
          'Multiple driver records are linked to this account. Contact support.',
        );
      }
      final driver = Driver.fromMap(snapshot.docs.single.data());
      if (driver.authUid != normalizedUid) return null;
      return driver;
    } on DriverServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } on FormatException catch (exception) {
      throw DriverServiceException(exception.message);
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
        authUid:
            existingDriver.email.trim().toLowerCase() ==
                driver.email.trim().toLowerCase()
            ? existingDriver.authUid
            : null,
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
