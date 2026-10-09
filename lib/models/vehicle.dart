import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_model.dart';

/// Represents a municipal waste collection vehicle stored in the `vehicles` collection.
///
/// The Firestore document ID is the vehicle registration number, for example:
/// `ABC-1234`.
class Vehicle implements BaseModel {
  Vehicle({
    required this.registrationNumber,
    required this.vehicleType,
    this.brand,
    this.model,
    this.yearManufactured,
    required this.capacityKg,
    required this.status,
    this.assignedDriverId,
    this.assignedZone,
    this.lastServiceDate,
    this.nextServiceDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String registrationNumber;
  final String vehicleType;
  final String? brand;
  final String? model;
  final int? yearManufactured;
  final num capacityKg;
  final String status;
  final String? assignedDriverId;
  final String? assignedZone;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime? _dateTimeFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    final converted = ModelValueConverter.fromValue(value);
    if (converted is DateTime) {
      return converted;
    }

    if (converted is Timestamp) {
      return converted.toDate();
    }

    return null;
  }

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

  static num _requiredNumFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      throw FormatException('Missing required field: $key');
    }
    if (value is num) {
      return value;
    }
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('Field "$key" must be a num.');
  }

  static int? _optionalIntFromMap(Map<String, dynamic> map, String key) {
    final value = ModelMapHelper.nullableValue<dynamic>(map, key);
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'registrationNumber': registrationNumber,
      'vehicleType': vehicleType,
      'brand': brand,
      'model': model,
      'yearManufactured': yearManufactured,
      'capacityKg': capacityKg,
      'status': status,
      'assignedDriverId': assignedDriverId,
      'assignedZone': assignedZone,
      'lastServiceDate': lastServiceDate == null
          ? null
          : ModelValueConverter.toValue(lastServiceDate!),
      'nextServiceDate': nextServiceDate == null
          ? null
          : ModelValueConverter.toValue(nextServiceDate!),
      'createdAt': ModelValueConverter.toValue(createdAt),
      'updatedAt': ModelValueConverter.toValue(updatedAt),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    final registrationNumber = _requiredStringFromMap(
      map,
      'registrationNumber',
    );
    final vehicleType = _requiredStringFromMap(map, 'vehicleType');
    final capacityKg = _requiredNumFromMap(map, 'capacityKg');
    final status = _requiredStringFromMap(map, 'status');
    final createdAt = _requiredDateTimeFromValue(map, 'createdAt');
    final updatedAt = _requiredDateTimeFromValue(map, 'updatedAt');

    return Vehicle(
      registrationNumber: registrationNumber,
      vehicleType: vehicleType,
      brand: ModelMapHelper.nullableValue<String>(map, 'brand'),
      model: ModelMapHelper.nullableValue<String>(map, 'model'),
      yearManufactured: _optionalIntFromMap(map, 'yearManufactured'),
      capacityKg: capacityKg,
      status: status,
      assignedDriverId: ModelMapHelper.nullableValue<String>(
        map,
        'assignedDriverId',
      ),
      assignedZone: ModelMapHelper.nullableValue<String>(map, 'assignedZone'),
      lastServiceDate: _dateTimeFromValue(map['lastServiceDate']),
      nextServiceDate: _dateTimeFromValue(map['nextServiceDate']),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Vehicle.fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw FormatException(
        'Vehicle document snapshot is null for document: ${snapshot.id}',
      );
    }
    return Vehicle.fromMap(data);
  }
}
