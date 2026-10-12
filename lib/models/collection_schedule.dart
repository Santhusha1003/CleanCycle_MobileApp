import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_model.dart';

/// Represents a collection schedule stored in the `schedules` collection.
///
/// Municipal writes store the document ID in `scheduleId`. Older shared
/// records can keep their identifier solely in the Firestore document path.
class CollectionSchedule implements BaseModel {
  CollectionSchedule({
    required this.scheduleId,
    required this.zone,
    required this.collectionDate,
    required this.startTime,
    required this.endTime,
    required this.wasteType,
    this.assignedVehicleId,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDriverUid,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String scheduleId;
  final String zone;
  final DateTime collectionDate;
  final String startTime;
  final String endTime;
  final String wasteType;
  final String? assignedVehicleId;
  final String? assignedDriverId;
  final String? assignedDriverName;

  /// Firebase Auth UID linked to the municipal Driver record. Never inferred
  /// from [assignedDriverId].
  final String? assignedDriverUid;
  final String status;
  final String? notes;
  // Older Member 02 records do not contain audit timestamps.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _dateTimeFromValue(
    Map<String, dynamic> map,
    String key, {
    bool required = true,
  }) {
    final value = map[key];
    if (value == null) {
      if (!required) return null;
      throw FormatException('Missing required field: $key');
    }

    final converted = ModelValueConverter.fromValue(value);
    if (converted is DateTime) {
      return converted;
    }
    if (converted is Timestamp) {
      return converted.toDate();
    }

    if (converted is String) {
      final parsed = DateTime.tryParse(converted);
      if (parsed != null) return parsed;
    }

    throw FormatException(
      'Field "$key" must be a DateTime, Timestamp or valid ISO date string.',
    );
  }

  static String _requiredStringFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      throw FormatException('Missing required field: $key');
    }
    if (value is! String) {
      throw FormatException('Field "$key" must be a String.');
    }
    return value;
  }

  // Shared Resident records use display times (e.g. 8:00 AM).
  static String _normalizeTime(String value) {
    final trimmed = value.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) return trimmed;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour < 1 || hour > 12 || minute > 59) return trimmed;
    final normalizedHour =
        hour % 12 + (match.group(3)!.toUpperCase() == 'PM' ? 12 : 0);
    return '${normalizedHour.toString().padLeft(2, '0')}:${match.group(2)}';
  }

  static bool _isValidTimeString(String value) {
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

  @override
  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'zone': zone,
      'collectionDate': ModelValueConverter.toValue(collectionDate),
      'startTime': startTime,
      'endTime': endTime,
      'wasteType': wasteType,
      'assignedVehicleId': assignedVehicleId,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'assignedDriverUid': assignedDriverUid,
      'status': status,
      'notes': notes,
      if (createdAt != null)
        'createdAt': ModelValueConverter.toValue(createdAt),
      if (updatedAt != null)
        'updatedAt': ModelValueConverter.toValue(updatedAt),
    };
  }

  factory CollectionSchedule.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final scheduleId = _requiredStringFromMap({
      ...map,
      'scheduleId': map['scheduleId'] ?? documentId,
    }, 'scheduleId');
    final zone = map['zone'] == null ? '' : _requiredStringFromMap(map, 'zone');
    final startTime = _normalizeTime(_requiredStringFromMap(map, 'startTime'));
    final endTime = _normalizeTime(_requiredStringFromMap(map, 'endTime'));
    final wasteType = _requiredStringFromMap(
      map,
      'wasteType',
    ).trim().toLowerCase();
    final storedStatus = _requiredStringFromMap(
      map,
      'status',
    ).trim().toLowerCase();
    // Existing Resident terminology for the same scheduled collection state.
    final status = storedStatus == 'upcoming' ? 'scheduled' : storedStatus;
    final createdAt = _dateTimeFromValue(map, 'createdAt', required: false);
    final updatedAt = _dateTimeFromValue(map, 'updatedAt', required: false);

    if (!_isValidTimeString(startTime)) {
      throw FormatException('Field "startTime" must be a valid HH:mm value.');
    }
    if (!_isValidTimeString(endTime)) {
      throw FormatException('Field "endTime" must be a valid HH:mm value.');
    }

    final convertedCollectionDate = _dateTimeFromValue(map, 'collectionDate')!;

    return CollectionSchedule(
      scheduleId: scheduleId,
      zone: zone,
      collectionDate: convertedCollectionDate,
      startTime: startTime,
      endTime: endTime,
      wasteType: wasteType == 'recyclable waste' ? 'recyclable' : wasteType,
      assignedVehicleId: ModelMapHelper.nullableValue<String>(
        map,
        'assignedVehicleId',
      ),
      assignedDriverId: ModelMapHelper.nullableValue<String>(
        map,
        'assignedDriverId',
      ),
      assignedDriverName: ModelMapHelper.nullableValue<String>(
        map,
        'assignedDriverName',
      ),
      assignedDriverUid: ModelMapHelper.nullableValue<String>(
        map,
        'assignedDriverUid',
      ),
      status: status,
      notes: ModelMapHelper.nullableValue<String>(
        map,
        map['notes'] == null ? 'instructions' : 'notes',
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CollectionSchedule.fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw FormatException(
        'CollectionSchedule document snapshot is null for document: ${snapshot.id}',
      );
    }
    return CollectionSchedule.fromMap(data, documentId: snapshot.id);
  }
}
