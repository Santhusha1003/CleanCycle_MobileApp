import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/collection_schedule.dart';
import '../firebase/firebase_service.dart';
import '../firebase/firestore_service.dart';

/// Service for managing municipal collection schedule records in Firestore.
class ScheduleServiceException implements Exception {
  const ScheduleServiceException(this.message);

  final String message;

  @override
  String toString() => 'ScheduleServiceException: $message';
}

class ScheduleService {
  ScheduleService({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

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

  Future<void> createSchedule({required CollectionSchedule schedule}) async {
    try {
      final normalizedScheduleId = _normalizeScheduleId(schedule.scheduleId);
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
          status: schedule.status,
          notes: schedule.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

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
        assignedVehicleId: schedule.assignedVehicleId?.trim().isEmpty == true
            ? null
            : schedule.assignedVehicleId,
        assignedDriverId: schedule.assignedDriverId?.trim().isEmpty == true
            ? null
            : schedule.assignedDriverId,
        status: schedule.status.trim().toLowerCase(),
        notes: schedule.notes?.trim().isEmpty == true ? null : schedule.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setDocument(
        path: _documentPath(normalizedScheduleId),
        data: scheduleToSave.toMap(),
        merge: false,
      );
    } on ScheduleServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw ScheduleServiceException(exception.message);
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
      return CollectionSchedule.fromMap(data);
    } on ScheduleServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw ScheduleServiceException(exception.message);
      }
      rethrow;
    }
  }

  Future<List<CollectionSchedule>> getSchedules() async {
    try {
      final docs = await _firestoreService.getCollection(path: collectionPath);

      if (docs.isEmpty) {
        return const <CollectionSchedule>[];
      }

      return docs.map((data) => CollectionSchedule.fromMap(data)).toList();
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }

  Future<void> updateSchedule({
    required String scheduleId,
    required CollectionSchedule schedule,
  }) async {
    try {
      final normalizedScheduleId = _normalizeScheduleId(scheduleId);

      if (schedule.scheduleId.trim() != normalizedScheduleId) {
        throw ScheduleServiceException(
          'Schedule scheduleId must match the document ID path.',
        );
      }

      final existingSchedule = await getSchedule(
        scheduleId: normalizedScheduleId,
      );
      if (existingSchedule == null) {
        throw ScheduleServiceException(
          'Schedule with scheduleId "$normalizedScheduleId" does not exist.',
        );
      }

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
        assignedVehicleId: schedule.assignedVehicleId?.trim().isEmpty == true
            ? null
            : schedule.assignedVehicleId,
        assignedDriverId: schedule.assignedDriverId?.trim().isEmpty == true
            ? null
            : schedule.assignedDriverId,
        status: schedule.status.trim().toLowerCase(),
        notes: schedule.notes?.trim().isEmpty == true ? null : schedule.notes,
        createdAt: existingSchedule.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setDocument(
        path: _documentPath(normalizedScheduleId),
        data: updatedSchedule.toMap(),
        merge: false,
      );
    } on ScheduleServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } catch (exception) {
      if (exception is FormatException) {
        throw ScheduleServiceException(exception.message);
      }
      rethrow;
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

      await _firestoreService.deleteDocument(
        path: _documentPath(normalizedScheduleId),
      );
    } on ScheduleServiceException {
      rethrow;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }
}
