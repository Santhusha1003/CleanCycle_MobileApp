import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_model.dart';

/// Represents a municipal waste collection driver stored in the `drivers` collection.
///
/// The Firestore document ID is the driver identifier, which may correspond to a
/// Firebase Auth UID when available, or to a stable generated ID if not yet
/// provided by the authentication layer.
class Driver implements BaseModel {
  Driver({
    required this.driverId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.licenseNumber,
    this.licenseExpiryDate,
    this.assignedVehicleId,
    this.assignedZone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String driverId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? assignedVehicleId;
  final String? assignedZone;
  final String status;
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

  @override
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'licenseExpiryDate': licenseExpiryDate == null
          ? null
          : ModelValueConverter.toValue(licenseExpiryDate!),
      'assignedVehicleId': assignedVehicleId,
      'assignedZone': assignedZone,
      'status': status,
      'createdAt': ModelValueConverter.toValue(createdAt),
      'updatedAt': ModelValueConverter.toValue(updatedAt),
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    final driverId = _requiredStringFromMap(map, 'driverId');
    final fullName = _requiredStringFromMap(map, 'fullName');
    final email = _requiredStringFromMap(map, 'email');
    final phoneNumber = _requiredStringFromMap(map, 'phoneNumber');
    final licenseNumber = _requiredStringFromMap(map, 'licenseNumber');
    final status = _requiredStringFromMap(map, 'status');
    final createdAt = _requiredDateTimeFromValue(map, 'createdAt');
    final updatedAt = _requiredDateTimeFromValue(map, 'updatedAt');

    return Driver(
      driverId: driverId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      licenseNumber: licenseNumber,
      licenseExpiryDate: _dateTimeFromValue(map['licenseExpiryDate']),
      assignedVehicleId: ModelMapHelper.nullableValue<String>(
        map,
        'assignedVehicleId',
      ),
      assignedZone: ModelMapHelper.nullableValue<String>(map, 'assignedZone'),
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Driver.fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw FormatException(
        'Driver document snapshot is null for document: ${snapshot.id}',
      );
    }
    return Driver.fromMap(data);
  }
}
