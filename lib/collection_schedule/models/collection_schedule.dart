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

  // Convert Firestore data into a CollectionSchedule object
  factory CollectionSchedule.fromMap(String id, Map<String, dynamic> data) {
    return CollectionSchedule(
      id: id,
      wasteType: data['wasteType'] ?? '',
      collectionDate:
          DateTime.tryParse(data['collectionDate'] ?? '') ?? DateTime.now(),
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
