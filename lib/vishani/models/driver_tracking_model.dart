import 'package:cloud_firestore/cloud_firestore.dart';

class DriverTrackingModel {
  final String driverId;
  final String driverName;
  final String driverPhone;
  final double currentLatitude;
  final double currentLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final int etaMinutes;
  final String vehicleNumber;
  final String status;

  DriverTrackingModel({
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.etaMinutes,
    this.vehicleNumber = 'WP-NA-4521',
    this.status = 'In Progress',
  });

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory DriverTrackingModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    double parseDouble(dynamic val, double fallback) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic val, int fallback) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    return DriverTrackingModel(
      driverId: documentId ?? map['driverId'] ?? 'DRV-001',
      driverName: map['driverName'] ?? 'Nalin Perera',
      driverPhone: map['driverPhone'] ?? '+94771234567',
      currentLatitude: parseDouble(map['currentLatitude'], 6.9271),
      currentLongitude: parseDouble(map['currentLongitude'], 79.8612),
      destinationLatitude: parseDouble(map['destinationLatitude'], 6.9319),
      destinationLongitude: parseDouble(map['destinationLongitude'], 79.8578),
      etaMinutes: parseInt(map['etaMinutes'], 25),
      vehicleNumber: map['vehicleNumber'] ?? 'WP-NA-4521',
      status: map['status'] ?? 'In Progress',
    );
  }

  factory DriverTrackingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DriverTrackingModel.fromMap(data, doc.id);
  }

  DriverTrackingModel copyWith({
    String? driverId,
    String? driverName,
    String? driverPhone,
    double? currentLatitude,
    double? currentLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
    int? etaMinutes,
    String? vehicleNumber,
    String? status,
  }) {
    return DriverTrackingModel(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      status: status ?? this.status,
    );
  }
}
