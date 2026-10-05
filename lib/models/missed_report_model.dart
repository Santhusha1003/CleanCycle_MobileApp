import 'package:cloud_firestore/cloud_firestore.dart';

class MissedReportModel {
  final String reportId;
  final String userId;
  final String collectionType;
  final DateTime scheduledDate;
  final String description;
  final String? photoUrl;
  final String status;
  final DateTime reportedOn;

  MissedReportModel({
    required this.reportId,
    required this.userId,
    required this.collectionType,
    required this.scheduledDate,
    required this.description,
    this.photoUrl,
    this.status = 'Reported',
    required this.reportedOn,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'userId': userId,
      'collectionType': collectionType,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'description': description,
      'photoUrl': photoUrl,
      'status': status,
      'reportedOn': Timestamp.fromDate(reportedOn),
    };
  }

  factory MissedReportModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return MissedReportModel(
      reportId: documentId ?? map['reportId'] ?? '',
      userId: map['userId'] ?? '',
      collectionType: map['collectionType'] ?? '',
      scheduledDate: parseDate(map['scheduledDate']),
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'],
      status: map['status'] ?? 'Reported',
      reportedOn: parseDate(map['reportedOn']),
    );
  }

  factory MissedReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MissedReportModel.fromMap(data, doc.id);
  }

  MissedReportModel copyWith({
    String? reportId,
    String? userId,
    String? collectionType,
    DateTime? scheduledDate,
    String? description,
    String? photoUrl,
    String? status,
    DateTime? reportedOn,
  }) {
    return MissedReportModel(
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      collectionType: collectionType ?? this.collectionType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      reportedOn: reportedOn ?? this.reportedOn,
    );
  }
}
