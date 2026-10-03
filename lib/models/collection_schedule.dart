import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_model.dart';

/// Represents a collection schedule stored in the `schedules` collection.
///
/// The Firestore document ID is generated automatically and stored in the
/// `scheduleId` field to keep the document stable while allowing multiple
/// schedules for the same collection date.
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
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _requiredDateTimeFromValue(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];
    if (value == null) {
      throw FormatException('Missing required field: $key');
    }

    final converted = ModelValueConverter.fromValue(value);
    if (converted is DateTime) {
      return converted;
    }
    if (converted is Timestamp) {
      return converted.toDate();
    }

    throw FormatException('Field "$key" must be a DateTime or Timestamp.');
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
      'status': status,
      'notes': notes,
      'createdAt': ModelValueConverter.toValue(createdAt),
      'updatedAt': ModelValueConverter.toValue(updatedAt),
    };
  }

  factory CollectionSchedule.fromMap(Map<String, dynamic> map) {
    final scheduleId = _requiredStringFromMap(map, 'scheduleId');
    final zone = _requiredStringFromMap(map, 'zone');
    final startTime = _requiredStringFromMap(map, 'startTime');
    final endTime = _requiredStringFromMap(map, 'endTime');
    final wasteType = _requiredStringFromMap(map, 'wasteType');
    final status = _requiredStringFromMap(map, 'status');
    final createdAt = _requiredDateTimeFromValue(map, 'createdAt');
    final updatedAt = _requiredDateTimeFromValue(map, 'updatedAt');

    if (!_isValidTimeString(startTime)) {
      throw FormatException('Field "startTime" must be a valid HH:mm value.');
    }
    if (!_isValidTimeString(endTime)) {
      throw FormatException('Field "endTime" must be a valid HH:mm value.');
    }

    final collectionDateValue = map['collectionDate'];
    if (collectionDateValue == null) {
      throw const FormatException('Missing required field: collectionDate');
    }

    final convertedCollectionDate = ModelValueConverter.fromValue(
      collectionDateValue,
    );
    if (convertedCollectionDate is! DateTime) {
      throw const FormatException(
        'Field "collectionDate" must be a DateTime or Timestamp.',
      );
    }

    return CollectionSchedule(
      scheduleId: scheduleId,
      zone: zone,
      collectionDate: convertedCollectionDate,
      startTime: startTime,
      endTime: endTime,
      wasteType: wasteType,
      assignedVehicleId: ModelMapHelper.nullableValue<String>(
        map,
        'assignedVehicleId',
      ),
      assignedDriverId: ModelMapHelper.nullableValue<String>(
        map,
        'assignedDriverId',
      ),
      status: status,
      notes: ModelMapHelper.nullableValue<String>(map, 'notes'),
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
    return CollectionSchedule.fromMap(data);
  }
}
