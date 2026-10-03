import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/vehicle.dart';
import '../firebase/firebase_service.dart';
import '../firebase/firestore_service.dart';

/// Service for managing municipal vehicle records in Firestore.
///
/// Data flow: Vehicle -> VehicleService -> FirestoreService -> Cloud Firestore.
class VehicleServiceException implements Exception {
  const VehicleServiceException(this.message);

  final String message;

  @override
  String toString() => 'VehicleServiceException: $message';
}

class VehicleService {
  VehicleService({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  static const String collectionPath = 'vehicles';
  static const Set<String> allowedStatuses = {
    'available',
    'assigned',
    'maintenance',
    'out_of_service',
    'retired',
  };

  final FirestoreService _firestoreService;

  String _normalizeRegistrationNumber(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const VehicleServiceException(
        'registrationNumber cannot be empty.',
      );
    }
    return normalized;
  }

  String _normalizeTextField(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw VehicleServiceException('$fieldName cannot be empty.');
    }
    return normalized;
  }

  String _documentPath(String registrationNumber) =>
      '$collectionPath/${_normalizeRegistrationNumber(registrationNumber)}';

  void _validateVehicle(Vehicle vehicle) {
    _normalizeRegistrationNumber(vehicle.registrationNumber);
    _normalizeTextField(vehicle.vehicleType, 'vehicleType');

    if (vehicle.capacityKg.isNaN || vehicle.capacityKg.isNegative) {
      throw const VehicleServiceException(
        'capacityKg must be a valid non-negative number.',
      );
    }

    final normalizedStatus = vehicle.status.trim().toLowerCase();
    if (!allowedStatuses.contains(normalizedStatus)) {
      throw VehicleServiceException(
        'status must be one of: ${allowedStatuses.toList().join(', ')}.',
      );
    }

    if (vehicle.assignedDriverId != null &&
        vehicle.assignedDriverId!.trim().isEmpty) {
      throw const VehicleServiceException(
        'assignedDriverId cannot be empty when provided.',
      );
    }

    if (vehicle.assignedZone != null && vehicle.assignedZone!.trim().isEmpty) {
      throw const VehicleServiceException(
        'assignedZone cannot be empty when provided.',
      );
    }
  }

  Future<void> createVehicle({required Vehicle vehicle}) async {
    try {
      final normalizedRegistrationNumber = _normalizeRegistrationNumber(
        vehicle.registrationNumber,
      );
      _validateVehicle(
        Vehicle(
          registrationNumber: normalizedRegistrationNumber,
          vehicleType: vehicle.vehicleType,
          brand: vehicle.brand,
          model: vehicle.model,
          yearManufactured: vehicle.yearManufactured,
          capacityKg: vehicle.capacityKg,
          status: vehicle.status,
          assignedDriverId: vehicle.assignedDriverId,
          assignedZone: vehicle.assignedZone,
          lastServiceDate: vehicle.lastServiceDate,
          nextServiceDate: vehicle.nextServiceDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final existingVehicle = await getVehicle(
        registrationNumber: normalizedRegistrationNumber,
      );
      if (existingVehicle != null) {
        throw VehicleServiceException(
          'Vehicle with registrationNumber "$normalizedRegistrationNumber" already exists.',
        );
      }

      final vehicleToSave = Vehicle(
        registrationNumber: normalizedRegistrationNumber,
        vehicleType: _normalizeTextField(vehicle.vehicleType, 'vehicleType'),
        brand: vehicle.brand?.trim().isEmpty == true ? null : vehicle.brand,
        model: vehicle.model?.trim().isEmpty == true ? null : vehicle.model,
        yearManufactured: vehicle.yearManufactured,
        capacityKg: vehicle.capacityKg,
        status: vehicle.status.trim().toLowerCase(),
        assignedDriverId: vehicle.assignedDriverId?.trim().isEmpty == true
            ? null
            : vehicle.assignedDriverId,
        assignedZone: vehicle.assignedZone?.trim().isEmpty == true
            ? null
            : vehicle.assignedZone,
        lastServiceDate: vehicle.lastServiceDate,
        nextServiceDate: vehicle.nextServiceDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setDocument(
        path: _documentPath(normalizedRegistrationNumber),
        data: vehicleToSave.toMap(),
        merge: false,
      );
    } on VehicleServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw VehicleServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<Vehicle?> getVehicle({required String registrationNumber}) async {
    try {
      final normalizedRegistrationNumber = _normalizeRegistrationNumber(
        registrationNumber,
      );
      final data = await _firestoreService.getDocument(
        path: _documentPath(normalizedRegistrationNumber),
      );
      if (data == null) {
        return null;
      }
      return Vehicle.fromMap(data);
    } on VehicleServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw VehicleServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<List<Vehicle>> getVehicles() async {
    try {
      final docs = await _firestoreService.getCollection(path: collectionPath);

      if (docs.isEmpty) {
        return const <Vehicle>[];
      }

      return docs.map((data) => Vehicle.fromMap(data)).toList();
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }

  Future<void> updateVehicle({
    required String registrationNumber,
    required Vehicle vehicle,
  }) async {
    try {
      final normalizedRegistrationNumber = _normalizeRegistrationNumber(
        registrationNumber,
      );

      if (vehicle.registrationNumber.trim() != normalizedRegistrationNumber) {
        throw VehicleServiceException(
          'Vehicle registrationNumber must match the document ID path.',
        );
      }

      final existingVehicle = await getVehicle(
        registrationNumber: normalizedRegistrationNumber,
      );
      if (existingVehicle == null) {
        throw VehicleServiceException(
          'Vehicle with registrationNumber "$normalizedRegistrationNumber" does not exist.',
        );
      }

      _validateVehicle(
        Vehicle(
          registrationNumber: normalizedRegistrationNumber,
          vehicleType: vehicle.vehicleType,
          brand: vehicle.brand,
          model: vehicle.model,
          yearManufactured: vehicle.yearManufactured,
          capacityKg: vehicle.capacityKg,
          status: vehicle.status,
          assignedDriverId: vehicle.assignedDriverId,
          assignedZone: vehicle.assignedZone,
          lastServiceDate: vehicle.lastServiceDate,
          nextServiceDate: vehicle.nextServiceDate,
          createdAt: existingVehicle.createdAt,
          updatedAt: DateTime.now(),
        ),
      );

      final updatedVehicle = Vehicle(
        registrationNumber: normalizedRegistrationNumber,
        vehicleType: _normalizeTextField(vehicle.vehicleType, 'vehicleType'),
        brand: vehicle.brand?.trim().isEmpty == true ? null : vehicle.brand,
        model: vehicle.model?.trim().isEmpty == true ? null : vehicle.model,
        yearManufactured: vehicle.yearManufactured,
        capacityKg: vehicle.capacityKg,
        status: vehicle.status.trim().toLowerCase(),
        assignedDriverId: vehicle.assignedDriverId?.trim().isEmpty == true
            ? null
            : vehicle.assignedDriverId,
        assignedZone: vehicle.assignedZone?.trim().isEmpty == true
            ? null
            : vehicle.assignedZone,
        lastServiceDate: vehicle.lastServiceDate,
        nextServiceDate: vehicle.nextServiceDate,
        createdAt: existingVehicle.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setDocument(
        path: _documentPath(normalizedRegistrationNumber),
        data: updatedVehicle.toMap(),
        merge: false,
      );
    } on VehicleServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw VehicleServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<void> deleteVehicle({required String registrationNumber}) async {
    try {
      final normalizedRegistrationNumber = _normalizeRegistrationNumber(
        registrationNumber,
      );
      final existingVehicle = await getVehicle(
        registrationNumber: normalizedRegistrationNumber,
      );
      if (existingVehicle == null) {
        throw VehicleServiceException(
          'Vehicle with registrationNumber "$normalizedRegistrationNumber" does not exist.',
        );
      }

      await _firestoreService.deleteDocument(
        path: _documentPath(normalizedRegistrationNumber),
      );
    } on VehicleServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }
}
