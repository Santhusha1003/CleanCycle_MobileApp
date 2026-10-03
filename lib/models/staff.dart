import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_model.dart';

/// Represents a municipal operations staff member stored in the `staff` collection.
///
/// The Firestore document ID is the stable staff identifier, which is stored in
/// the `staffId` field for consistency with the rest of the municipal backend
/// models.
class Staff implements BaseModel {
  Staff({
    required this.staffId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.position,
    this.assignedZone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String staffId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String position;
  final String? assignedZone;
  final String status;
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

  @override
  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'position': position,
      'assignedZone': assignedZone,
      'status': status,
      'createdAt': ModelValueConverter.toValue(createdAt),
      'updatedAt': ModelValueConverter.toValue(updatedAt),
    };
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    final staffId = _requiredStringFromMap(map, 'staffId');
    final fullName = _requiredStringFromMap(map, 'fullName');
    final email = _requiredStringFromMap(map, 'email');
    final phoneNumber = _requiredStringFromMap(map, 'phoneNumber');
    final position = _requiredStringFromMap(map, 'position');
    final status = _requiredStringFromMap(map, 'status');
    final createdAt = _requiredDateTimeFromValue(map, 'createdAt');
    final updatedAt = _requiredDateTimeFromValue(map, 'updatedAt');

    return Staff(
      staffId: staffId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      position: position,
      assignedZone: ModelMapHelper.nullableValue<String>(map, 'assignedZone'),
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Staff.fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw FormatException(
        'Staff document snapshot is null for document: ${snapshot.id}',
      );
    }
    return Staff.fromMap(data);
  }
}
