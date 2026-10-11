import 'package:cloud_firestore/cloud_firestore.dart';

class MissedCollectionReport {
  const MissedCollectionReport({
    required this.id,
    required this.wasteType,
    required this.collectionDate,
    required this.reason,
    required this.description,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String wasteType;
  final DateTime collectionDate;
  final String reason;
  final String description;
  final String status;
  final DateTime? createdAt;

  factory MissedCollectionReport.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return MissedCollectionReport(
      id: document.id,
      wasteType: data['wasteType'] as String? ?? '',
      collectionDate: parseDate(data['collectionDate']),
      reason: data['reason'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['reportStatus'] as String? ?? 'pending',
      createdAt: parseOptionalDate(data['createdAt']),
    );
  }
}
