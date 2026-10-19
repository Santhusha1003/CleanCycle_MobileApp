import 'package:firebase_auth/firebase_auth.dart';

import '../../models/driver.dart';
import '../firebase/firebase_service.dart';
import '../firebase/firestore_service.dart';

/// Service for managing municipal driver records in Firestore.
class DriverServiceException implements Exception {
  const DriverServiceException(this.message, {this.code});

  final String message;
  final String? code;

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
    String verifiedUid;
    final linkedUid = record.authUid?.trim();
    if (linkedUid != null && linkedUid.isNotEmpty) {
      // An explicit account link takes precedence over email discovery.
      final profile = await _firestoreService.getDocument(
        path: 'users/$linkedUid',
      );
      if (profile == null) {
        throw const DriverServiceException(
          'The linked Driver profile no longer exists. Open Driver Management and ask an administrator to correct the account link.',
          code: 'account-link-missing',
        );
      }
      _validateAccountProfile(linkedUid, profile, normalizedEmail);
      verifiedUid = linkedUid;
    } else {
      final exact = await _firestoreService.firestore
          .collection('users')
          .where(
            'email',
            whereIn: {record.email.trim(), normalizedEmail}.toList(),
          )
          .get();
      // Firestore string equality is case-sensitive. Officers already have
      // directory read permission; restrict fallback reads to actual Drivers.
      final approved = await _firestoreService.firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();
      final candidates = {
        for (final profile in [...exact.docs, ...approved.docs])
          if (profile.data()['email'] is String &&
              (profile.data()['email'] as String).trim().toLowerCase() ==
                  normalizedEmail)
            profile.id: profile.data(),
      };
      final matches = candidates.entries
          .where((entry) => entry.value['role'] == 'driver')
          .toList();
      if (matches.isEmpty) {
        throw DriverServiceException(
          candidates.isEmpty
              ? 'No user profile matches this Driver record’s email. Open Driver Management to correct the record’s email to an existing account, or save without a Driver assignment.'
              : 'The matching account does not have the approved Driver role. A requested Driver role is not approval. Select another Driver, contact an administrator, or save without a Driver assignment.',
          code: candidates.isEmpty
              ? 'account-link-missing'
              : 'account-not-approved',
        );
      }
      if (matches.length != 1) {
        throw const DriverServiceException(
          'Multiple approved Driver profiles match this email. Ask an administrator to correct the account mapping.',
          code: 'account-link-ambiguous',
        );
      }
      verifiedUid = matches.single.key;
      _validateAccountProfile(
        verifiedUid,
        matches.single.value,
        normalizedEmail,
      );
    }
    if (verifiedUid == officerUid) {
      throw const DriverServiceException(
        'A Municipal Officer cannot assign their own account as a Driver.',
      );
    }
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

  void _validateAccountProfile(
    String uid,
    Map<String, dynamic> profile,
    String email,
  ) {
    // AppUser.fromFirestore uses the document ID as the canonical UID.
    // A missing legacy duplicate uid field is allowed; a conflicting one is not.
    if (profile.containsKey('uid') && profile['uid'] != uid) {
      throw const DriverServiceException(
        'The Driver profile has an inconsistent account identifier. Ask an administrator to correct it.',
        code: 'account-identity-mismatch',
      );
    }
    if (profile['role'] != 'driver') {
      throw const DriverServiceException(
        'The linked account does not have the approved Driver role. Contact an administrator or save without a Driver assignment.',
        code: 'account-not-approved',
      );
    }
    if (profile['email'] is! String ||
        (profile['email'] as String).trim().toLowerCase() != email) {
      throw const DriverServiceException(
        'The linked account email differs from the Driver record. Open Driver Management to correct the email; account links are not reassigned automatically.',
        code: 'account-email-mismatch',
      );
    }
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
        email: _normalizeTextField(driver.email, 'email').toLowerCase(),
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
      final profile = await _firestoreService.getDocument(
        path: 'users/$normalizedUid',
      );
      if (profile == null ||
          profile['email'] is! String ||
          (profile['email'] as String).trim().isEmpty) {
        throw const DriverServiceException(
          'Your Driver profile has no verified account email. Contact an administrator.',
          code: 'account-email-missing',
        );
      }
      final rawEmail = profile['email'] as String;
      final email = rawEmail.trim().toLowerCase();
      _validateAccountProfile(normalizedUid, profile, email);
      // Only exact variants derived from the trusted profile are queried.
      // Never fall back to listing all drivers or an authUid-only query.
      final snapshot = await _firestoreService.firestore
          .collection(collectionPath)
          .where('authUid', isEqualTo: normalizedUid)
          .where('email', whereIn: {email, rawEmail.trim(), rawEmail}.toList())
          .get();
      if (_authenticatedUid() != normalizedUid) {
        throw const DriverServiceException('The signed-in account changed.');
      }
      if (snapshot.docs.isEmpty) return null;
      if (snapshot.docs.length != 1) {
        throw const DriverServiceException(
          'Multiple driver records are linked to this account. Contact support.',
        );
      }
      final document = snapshot.docs.single;
      final driver = Driver.fromMap(document.data());
      if (driver.authUid != normalizedUid ||
          driver.driverId != document.id ||
          driver.email.trim().toLowerCase() != email) {
        throw const DriverServiceException(
          'The Driver record has an inconsistent account link. Contact an administrator.',
          code: 'account-identity-mismatch',
        );
      }
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
        email: _normalizeTextField(driver.email, 'email').toLowerCase(),
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
