import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialPickupModel {
  final String requestId;
  final String userId;
  final String wasteType;
  final DateTime scheduledDate;
  final String timeSlot;
  final String address;
  final String notes;
  final List<String> photoUrls;
  final String status;
  final String? assignedDriverUid;
  final String? assignedDriverId;
  final String? assignedVehicleId;
  final DateTime createdAt;

  SpecialPickupModel({
    required this.requestId,
    required this.userId,
    required this.wasteType,
    required this.scheduledDate,
    required this.timeSlot,
    required this.address,
    required this.notes,
    this.photoUrls = const [],
    this.status = 'Pending',
    this.assignedDriverUid,
    this.assignedDriverId,
    this.assignedVehicleId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'userId': userId,
      'wasteType': wasteType,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'timeSlot': timeSlot,
      'address': address,
      'notes': notes,
      'photoUrls': photoUrls,
      'status': status,
      if (assignedDriverUid != null) 'assignedDriverUid': assignedDriverUid,
      if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
      if (assignedVehicleId != null) 'assignedVehicleId': assignedVehicleId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SpecialPickupModel.fromMap(
    Map<String, dynamic> map, [
    String? documentId,
  ]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return SpecialPickupModel(
      requestId: documentId ?? map['requestId'] ?? '',
      userId: map['userId'] ?? '',
      wasteType: map['wasteType'] ?? '',
      scheduledDate: parseDate(map['scheduledDate']),
      timeSlot: map['timeSlot'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      status: map['status'] ?? 'Pending',
      assignedDriverUid: map['assignedDriverUid'] as String?,
      assignedDriverId: map['assignedDriverId'] as String?,
      assignedVehicleId: map['assignedVehicleId'] as String?,
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory SpecialPickupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SpecialPickupModel.fromMap(data, doc.id);
  }

  SpecialPickupModel copyWith({
    String? requestId,
    String? userId,
    String? wasteType,
    DateTime? scheduledDate,
    String? timeSlot,
    String? address,
    String? notes,
    List<String>? photoUrls,
    String? status,
    DateTime? createdAt,
  }) {
    return SpecialPickupModel(
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      wasteType: wasteType ?? this.wasteType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      assignedDriverUid: assignedDriverUid,
      assignedDriverId: assignedDriverId,
      assignedVehicleId: assignedVehicleId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
