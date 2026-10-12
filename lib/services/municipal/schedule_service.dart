import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../vishani/services/tracking_service.dart';
import '../../models/collection_schedule.dart';
import '../firebase/firebase_service.dart';
import '../firebase/firestore_service.dart';
import 'driver_service.dart';
import 'vehicle_service.dart';

/// Service for managing municipal collection schedule records in Firestore.
class ScheduleServiceException implements Exception {
  const ScheduleServiceException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ScheduleServiceException: $message';
}

/// Safe save context, while retaining the underlying exception for debugging.
class ScheduleSavePermissionException extends FirebaseServiceException {
  ScheduleSavePermissionException({required this.stage, required this.cause})
    : super(
        code: 'permission-denied',
        message: cause is FirebaseException
            ? cause.message ?? 'Firestore denied the schedule operation.'
            : cause is FirebaseServiceException
            ? cause.message
            : 'Firestore denied the schedule operation.',
      );

  final String stage;
  final Object cause;

  String get userMessage =>
      'Firestore denied access while $stage (permission-denied). '
      'Check the signed-in account role and the published Firestore rules. '
      'The schedule was not saved.';
}

class ScheduleService {
  ScheduleService({
    FirestoreService? firestoreService,
    DriverService? driverService,
    VehicleService? vehicleService,
    TrackingService? trackingService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _driverService =
           driverService ?? DriverService(firestoreService: firestoreService),
       _vehicleService =
           vehicleService ?? VehicleService(firestoreService: firestoreService),
       _trackingService =
           trackingService ??
           TrackingService(
             firestore: (firestoreService ?? FirestoreService()).firestore,
           );

  static const String collectionPath = 'schedules';
  static const Set<String> allowedWasteTypes = {
    'general',
    'recyclable',
    'organic',
    'mixed',
    'other',
  };
  static const Set<String> allowedStatuses = {
    'scheduled',
    'in_progress',
    'completed',
    'cancelled',
  };

  final FirestoreService _firestoreService;
  final DriverService _driverService;
  final VehicleService _vehicleService;
  final TrackingService _trackingService;

  String _normalizeScheduleId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const ScheduleServiceException('scheduleId cannot be empty.');
    }
    return normalized;
  }

  String _normalizeTextField(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ScheduleServiceException('$fieldName cannot be empty.');
    }
    return normalized;
  }

  bool _isValidTimeString(String value) {
    final trimmed = value.trim();
    if (trimmed.length != 5) {
      return false;
    }

    final parts = trimmed.split(':');
    if (parts.length != 2) {
      return false;
    }

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) {
      return false;
    }

    if (hours < 0 || hours > 23) {
      return false;
    }
    if (minutes < 0 || minutes > 59) {
      return false;
    }

    return true;
  }

  String _documentPath(String scheduleId) =>
      '$collectionPath/${_normalizeScheduleId(scheduleId)}';

  void _validateSchedule(CollectionSchedule schedule) {
    _normalizeScheduleId(schedule.scheduleId);
    _normalizeTextField(schedule.zone, 'zone');
    if (schedule.collectionDate == DateTime.fromMillisecondsSinceEpoch(0)) {
      throw const ScheduleServiceException('collectionDate is required.');
    }
    _normalizeTextField(schedule.startTime, 'startTime');
    _normalizeTextField(schedule.endTime, 'endTime');
    _normalizeTextField(schedule.wasteType, 'wasteType');

    if (!_isValidTimeString(schedule.startTime)) {
      throw const ScheduleServiceException(
        'startTime must be a valid HH:mm value.',
      );
    }
    if (!_isValidTimeString(schedule.endTime)) {
      throw const ScheduleServiceException(
        'endTime must be a valid HH:mm value.',
      );
    }

    final normalizedWasteType = schedule.wasteType.trim().toLowerCase();
    if (!allowedWasteTypes.contains(normalizedWasteType)) {
      throw ScheduleServiceException(
        'wasteType must be one of: ${allowedWasteTypes.toList().join(', ')}.',
      );
    }

    final normalizedStatus = schedule.status.trim().toLowerCase();
    if (!allowedStatuses.contains(normalizedStatus)) {
      throw ScheduleServiceException(
        'status must be one of: ${allowedStatuses.toList().join(', ')}.',
      );
    }

    if (schedule.assignedVehicleId != null &&
        schedule.assignedVehicleId!.trim().isEmpty) {
      throw const ScheduleServiceException(
        'assignedVehicleId cannot be empty when provided.',
      );
    }

    if (schedule.assignedDriverId != null &&
        schedule.assignedDriverId!.trim().isEmpty) {
      throw const ScheduleServiceException(
        'assignedDriverId cannot be empty when provided.',
      );
    }

    if (schedule.notes != null && schedule.notes!.trim().isEmpty) {
      throw const ScheduleServiceException(
        'notes cannot be empty when provided.',
      );
    }
  }

  Future<({String? uid, String? name})> _resolveAssignment(
    CollectionSchedule schedule,
  ) async {
    if (schedule.status.trim().toLowerCase() == 'cancelled') {
      return (uid: null, name: null);
    }
    final vehicleId = schedule.assignedVehicleId?.trim();
    String? vehicleDriverId;
    if (vehicleId != null && vehicleId.isNotEmpty) {
      final vehicle = await _vehicleService.getVehicle(
        registrationNumber: vehicleId,
      );
      vehicleDriverId = vehicle?.assignedDriverId;
      if (vehicle == null ||
          !['available', 'assigned'].contains(vehicle.status.toLowerCase())) {
        throw const ScheduleServiceException(
          'Choose an existing vehicle that is available for assignment.',
        );
      }
    }
    final driverId = schedule.assignedDriverId?.trim();
    if (driverId == null || driverId.isEmpty) return (uid: null, name: null);
    final driver = await _driverService.getDriver(driverId: driverId);
    if (driver == null) {
      throw const ScheduleServiceException(
        'The selected Driver record could not be found.',
      );
    }
    // The municipal assignment is independent from tracking identity. A failed
    // account match never discards the actual selected municipal driver ID.
    if (vehicleId == null ||
        vehicleId.isEmpty ||
        driver.email.trim().isEmpty ||
        (driver.assignedVehicleId != null &&
            driver.assignedVehicleId != vehicleId) ||
        (vehicleDriverId != null && vehicleDriverId != driverId)) {
      return (uid: null, name: driver.fullName);
    }
    try {
      final uid = await _driverService.resolveVerifiedAuthUid(
        driverId: driverId,
      );
      return (uid: uid, name: driver.fullName);
    } on DriverServiceException catch (error, stack) {
      if (error.code?.startsWith('account-') == true) {
        return (uid: null, name: driver.fullName);
      }
      Error.throwWithStackTrace(
        ScheduleServiceException(error.message, cause: error),
        stack,
      );
    }
  }

  Future<void> createSchedule({required CollectionSchedule schedule}) async {
    var stage = 'validating schedule fields';
    try {
      final normalizedScheduleId = _normalizeScheduleId(schedule.scheduleId);
      stage = 'verifying Driver and vehicle assignment';
      final assignment = await _resolveAssignment(schedule);
      final assignedDriverUid = assignment.uid;
      final isCancelled = schedule.status.trim().toLowerCase() == 'cancelled';
      stage = 'validating schedule fields';
      _validateSchedule(
        CollectionSchedule(
          scheduleId: normalizedScheduleId,
          zone: schedule.zone,
          collectionDate: schedule.collectionDate,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
          wasteType: schedule.wasteType,
          assignedVehicleId: schedule.assignedVehicleId,
          assignedDriverId: schedule.assignedDriverId,
          assignedDriverUid: assignedDriverUid,
          status: schedule.status,
          notes: schedule.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      stage = 'checking for an existing schedule ID';
      final existingSchedule = await getSchedule(
        scheduleId: normalizedScheduleId,
      );
      if (existingSchedule != null) {
        throw ScheduleServiceException(
          'Schedule with scheduleId "$normalizedScheduleId" already exists.',
        );
      }

      final scheduleToSave = CollectionSchedule(
        scheduleId: normalizedScheduleId,
        zone: _normalizeTextField(schedule.zone, 'zone'),
        collectionDate: schedule.collectionDate,
        startTime: _normalizeTextField(schedule.startTime, 'startTime'),
        endTime: _normalizeTextField(schedule.endTime, 'endTime'),
        wasteType: _normalizeTextField(schedule.wasteType, 'wasteType'),
        assignedVehicleId:
            isCancelled || schedule.assignedVehicleId?.trim().isEmpty == true
            ? null
            : schedule.assignedVehicleId,
        assignedDriverId:
            isCancelled || schedule.assignedDriverId?.trim().isEmpty == true
            ? null
            : schedule.assignedDriverId,
        assignedDriverUid: assignedDriverUid,
        assignedDriverName: assignment.name,
        status: schedule.status.trim().toLowerCase(),
        notes: schedule.notes?.trim().isEmpty == true ? null : schedule.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      stage = assignedDriverUid == null
          ? 'saving schedules and resident_schedules'
          : 'saving schedules, resident_schedules, and driver_trips';
      if (assignedDriverUid != null) {
        await _trackingService.createAssignedTrip(
          'schedules',
          normalizedScheduleId,
          sourceData: scheduleToSave.toMap(),
          mergeSource: false,
        );
      } else {
        await _trackingService.saveScheduleAndProjection(
          normalizedScheduleId,
          scheduleData: scheduleToSave.toMap(),
          mergeSchedule: false,
        );
      }
    } catch (exception, stack) {
      final code = exception is FirebaseServiceException
          ? exception.code
          : exception is FirebaseException
          ? exception.code
          : exception.runtimeType.toString();
      _logSaveFailure('create', stage, code, exception.toString(), stack);
      if (code == 'permission-denied') {
        Error.throwWithStackTrace(
          ScheduleSavePermissionException(stage: stage, cause: exception),
          stack,
        );
      }
      if (exception is FirebaseException) {
        Error.throwWithStackTrace(
          FirebaseServiceException.fromFirebaseException(exception),
          stack,
        );
      }
      if (exception is StateError || exception is FormatException) {
        final message = exception is StateError
            ? exception.message.toString()
            : (exception as FormatException).message;
        Error.throwWithStackTrace(
          ScheduleServiceException(message, cause: exception),
          stack,
        );
      }
      rethrow;
    }
  }

  Future<CollectionSchedule?> getSchedule({required String scheduleId}) async {
    try {
      final normalizedScheduleId = _normalizeScheduleId(scheduleId);
      final data = await _firestoreService.getDocument(
        path: _documentPath(normalizedScheduleId),
      );
      if (data == null) {
        return null;
      }
      return CollectionSchedule.fromMap(data, documentId: normalizedScheduleId);
    } on ScheduleServiceException {
      rethrow;
    } on StateError catch (exception, stack) {
      Error.throwWithStackTrace(
        ScheduleServiceException(exception.message, cause: exception),
        stack,
      );
    } on FirebaseException catch (exception, stack) {
      Error.throwWithStackTrace(
        FirebaseServiceException.fromFirebaseException(exception),
        stack,
      );
    } catch (exception, stack) {
      if (exception is FormatException) {
        Error.throwWithStackTrace(
          ScheduleServiceException(exception.message, cause: exception),
          stack,
        );
      }
      rethrow;
    }
  }

  Future<List<CollectionSchedule>> getSchedules() async {
    try {
      final docs = await _firestoreService.getCollectionSnapshots(
        path: collectionPath,
      );

      if (docs.isEmpty) {
        return const <CollectionSchedule>[];
      }

      return docs.map(CollectionSchedule.fromDocumentSnapshot).toList();
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }

  /// One-time, explicitly invoked backfill for safe Resident schedule views.
  /// New schedule creation and updates already maintain their projections.
  Future<ResidentScheduleProjectionSyncResult>
  publishExistingResidentProjections() =>
      _trackingService.publishExistingResidentScheduleProjections();

  Future<void> updateSchedule({
    required String scheduleId,
    required CollectionSchedule schedule,
  }) async {
    var stage = 'loading existing schedule';
    try {
      final normalizedScheduleId = _normalizeScheduleId(scheduleId);

      if (schedule.scheduleId.trim() != normalizedScheduleId) {
        throw ScheduleServiceException(
          'Schedule scheduleId must match the document ID path.',
        );
      }

      final existingData = await _firestoreService.getDocument(
        path: _documentPath(normalizedScheduleId),
      );
      if (existingData == null) {
        throw ScheduleServiceException(
          'Schedule with scheduleId "$normalizedScheduleId" does not exist.',
        );
      }
      final existingSchedule = CollectionSchedule.fromMap(
        existingData,
        documentId: normalizedScheduleId,
      );
      stage = 'verifying Driver and vehicle assignment';
      final assignment = await _resolveAssignment(schedule);
      final assignedDriverUid = assignment.uid;
      final isCancelled = schedule.status.trim().toLowerCase() == 'cancelled';

      stage = 'validating updated schedule fields';
      _validateSchedule(
        CollectionSchedule(
          scheduleId: normalizedScheduleId,
          zone: schedule.zone,
          collectionDate: schedule.collectionDate,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
          wasteType: schedule.wasteType,
          assignedVehicleId: schedule.assignedVehicleId,
          assignedDriverId: schedule.assignedDriverId,
          assignedDriverUid: assignedDriverUid,
          status: schedule.status,
          notes: schedule.notes,
          createdAt: existingSchedule.createdAt,
          updatedAt: DateTime.now(),
        ),
      );

      final updatedSchedule = CollectionSchedule(
        scheduleId: normalizedScheduleId,
        zone: _normalizeTextField(schedule.zone, 'zone'),
        collectionDate: schedule.collectionDate,
        startTime: _normalizeTextField(schedule.startTime, 'startTime'),
        endTime: _normalizeTextField(schedule.endTime, 'endTime'),
        wasteType: _normalizeTextField(schedule.wasteType, 'wasteType'),
        assignedVehicleId:
            isCancelled || schedule.assignedVehicleId?.trim().isEmpty == true
            ? null
            : schedule.assignedVehicleId,
        assignedDriverId:
            isCancelled || schedule.assignedDriverId?.trim().isEmpty == true
            ? null
            : schedule.assignedDriverId,
        assignedDriverUid: assignedDriverUid,
        assignedDriverName: assignment.name,
        status: schedule.status.trim().toLowerCase(),
        notes: schedule.notes?.trim().isEmpty == true ? null : schedule.notes,
        createdAt: existingSchedule.createdAt,
        updatedAt: DateTime.now(),
      );

      final data = updatedSchedule.toMap();
      // Preserve the shared Resident record's date format and any unchanged
      // display values (e.g. "upcoming", "Recyclable Waste", "8:00 AM").
      if (existingData['collectionDate'] is String) {
        data['collectionDate'] = updatedSchedule.collectionDate
            .toIso8601String();
      }
      final previousValues = {
        'wasteType': existingSchedule.wasteType,
        'status': existingSchedule.status,
        'startTime': existingSchedule.startTime,
        'endTime': existingSchedule.endTime,
      };
      for (final entry in previousValues.entries) {
        if (data[entry.key] == entry.value) {
          data[entry.key] = existingData[entry.key];
        }
      }
      final hadTrip =
          existingData['trackingTripId'] != null ||
          existingData['assignedDriverUid'] != null;
      final projectionSourceData = {...existingData, ...data};
      stage = assignedDriverUid != null || hadTrip || isCancelled
          ? 'saving schedules, resident_schedules, and driver_trips'
          : 'saving schedules and resident_schedules';
      if (assignedDriverUid != null) {
        await _trackingService.createAssignedTrip(
          'schedules',
          normalizedScheduleId,
          sourceData: data,
          projectionData: projectionSourceData,
          mergeSource: true,
        );
      } else if (hadTrip ||
          schedule.status.trim().toLowerCase() == 'cancelled') {
        await _trackingService.clearScheduleTrip(
          normalizedScheduleId,
          sourceData: data,
          projectionData: projectionSourceData,
          preserveMunicipalAssignment: !isCancelled,
        );
      } else {
        await _trackingService.saveScheduleAndProjection(
          normalizedScheduleId,
          scheduleData: data,
          projectionData: projectionSourceData,
          mergeSchedule: true,
        );
      }
    } catch (exception, stack) {
      final code = exception is FirebaseServiceException
          ? exception.code
          : exception is FirebaseException
          ? exception.code
          : exception.runtimeType.toString();
      _logSaveFailure('update', stage, code, exception.toString(), stack);
      if (code == 'permission-denied') {
        Error.throwWithStackTrace(
          ScheduleSavePermissionException(stage: stage, cause: exception),
          stack,
        );
      }
      if (exception is FirebaseException) {
        Error.throwWithStackTrace(
          FirebaseServiceException.fromFirebaseException(exception),
          stack,
        );
      }
      if (exception is StateError || exception is FormatException) {
        final message = exception is StateError
            ? exception.message.toString()
            : (exception as FormatException).message;
        Error.throwWithStackTrace(
          ScheduleServiceException(message, cause: exception),
          stack,
        );
      }
      rethrow;
    }
  }

  void _logSaveFailure(
    String operation,
    String stage,
    String code,
    String message,
    StackTrace stack,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[SCHEDULE SAVE] operation=$operation stage=$stage code=$code message=$message',
      );
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> deleteSchedule({required String scheduleId}) async {
    try {
      final normalizedScheduleId = _normalizeScheduleId(scheduleId);
      final existingSchedule = await getSchedule(
        scheduleId: normalizedScheduleId,
      );
      if (existingSchedule == null) {
        throw ScheduleServiceException(
          'Schedule with scheduleId "$normalizedScheduleId" does not exist.',
        );
      }

      await _trackingService.deleteScheduleAndProjection(normalizedScheduleId);
    } on ScheduleServiceException {
      rethrow;
    } on StateError catch (exception) {
      throw ScheduleServiceException(exception.message);
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }
}
