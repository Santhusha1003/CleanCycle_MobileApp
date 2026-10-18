import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionSchedule {
  final String id;
  final String wasteType;
  final DateTime collectionDate;
  final String startTime;
  final String endTime;
  final String status;
  final List<String> acceptedItems;
  final String instructions;

  CollectionSchedule({
    required this.id,
    required this.wasteType,
    required this.collectionDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.acceptedItems,
    required this.instructions,
  });

  static DateTime _parseCollectionDate(Object? value) {
    // Shared Municipal writes use Timestamp; Resident writes use ISO strings.
    // Preserve the instant and time of day, displaying it in local time.
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    // Never fabricate "today" for an undated schedule. The collection reader
    // isolates this invalid record so other valid schedules remain available.
    throw const FormatException('Missing or invalid collectionDate');
  }

  // Convert Firestore data into a CollectionSchedule object
  factory CollectionSchedule.fromMap(String id, Map<String, dynamic> data) {
    return CollectionSchedule(
      id: id,
      wasteType: data['wasteType'] ?? '',
      collectionDate: _parseCollectionDate(data['collectionDate']),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      status: data['status'] ?? '',
      acceptedItems: List<String>.from(data['acceptedItems'] ?? []),
      instructions: data['instructions'] ?? '',
    );
  }

  // Convert CollectionSchedule object into Firestore data
  Map<String, dynamic> toMap() {
    return {
      'wasteType': wasteType,
      'collectionDate': collectionDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'acceptedItems': acceptedItems,
      'instructions': instructions,
    };
  }
}
