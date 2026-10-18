import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracking fields are optional: missing coordinates/ETA are never demo data.
class DriverTrackingModel {
  const DriverTrackingModel({
    required this.driverId,
    this.driverName = '',
    this.driverPhone = '',
    this.currentLatitude,
    this.currentLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.etaMinutes,
    this.vehicleNumber = '',
    this.status = '',
  });

  final String driverId;
  final String driverName;
  final String driverPhone;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final int? etaMinutes;
  final String vehicleNumber;
  final String status;

  bool get hasLocation => currentLatitude != null && currentLongitude != null;

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'currentLatitude': currentLatitude,
    'currentLongitude': currentLongitude,
    'destinationLatitude': destinationLatitude,
    'destinationLongitude': destinationLongitude,
    'etaMinutes': etaMinutes,
    'vehicleNumber': vehicleNumber,
    'status': status,
  };

  static double? coordinate(dynamic value, double limit) {
    final number = value is num ? value.toDouble() : null;
    return number != null && number.isFinite && number.abs() <= limit
        ? number
        : null;
  }

  factory DriverTrackingModel.fromMap(
    Map<String, dynamic> map, [
    String? documentId,
  ]) => DriverTrackingModel(
    driverId: documentId ?? text(map['driverId']),
    driverName: text(map['driverName']),
    driverPhone: text(map['driverPhone']),
    currentLatitude: coordinate(map['currentLatitude'], 90),
    currentLongitude: coordinate(map['currentLongitude'], 180),
    destinationLatitude: coordinate(map['destinationLatitude'], 90),
    destinationLongitude: coordinate(map['destinationLongitude'], 180),
    // A trip-level ETA/destination is not evidence of an ETA to this user.
    vehicleNumber: text(map['vehicleNumber']),
    status: text(map['status']),
  );

  factory DriverTrackingModel.fromFirestore(DocumentSnapshot doc) =>
      DriverTrackingModel.fromMap(
        doc.data() as Map<String, dynamic>? ?? {},
        doc.id,
      );

  static String text(dynamic value) => value is String ? value.trim() : '';
}

/// A single resident-owned request, with only its assigned records attached.
class ResidentTrackingData {
  const ResidentTrackingData({
    required this.uid,
    required this.message,
    this.requestId,
    this.status = '',
    this.addressZone = '',
    this.driver,
    this.driverName = '',
    this.driverPhone = '',
    this.driverAvatarUrl = '',
    this.vehicleRegistration = '',
    this.failures = const [],
  });
  final String uid;
  final String message;
  final String? requestId;
  final String status;
  final String addressZone;
  final DriverTrackingModel? driver;
  final String driverName;
  final String driverPhone;
  final String driverAvatarUrl;
  final String vehicleRegistration;
  final List<TrackingReadFailure> failures;
}

/// Safe source/code diagnostics; Firebase messages may contain unrelated data.
class TrackingReadFailure implements Exception {
  const TrackingReadFailure({required this.source, required this.code});
  factory TrackingReadFailure.fromError(String source, Object error) =>
      TrackingReadFailure(
        source: source,
        code: error is FirebaseException ? error.code : 'unknown',
      );
  final String source;
  final String code;
  String get displayMessage => code == 'permission-denied'
      ? 'Access denied to $source (permission-denied).'
      : 'Unable to load $source ($code).';
}
