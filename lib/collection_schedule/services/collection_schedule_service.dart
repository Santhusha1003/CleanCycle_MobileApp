import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/collection_schedule.dart';

class CollectionScheduleService {
  CollectionScheduleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Firestore collection name
  // Residents read the safe projection only. Municipal assignments and trip
  // identifiers remain in the restricted `schedules` collection.
  static const String collectionName = 'resident_schedules';
  final String _collectionName = collectionName;

  // =========================
  // CREATE
  // =========================

  Future<String> addSchedule(CollectionSchedule schedule) async {
    try {
      DocumentReference doc = await _firestore
          .collection(_collectionName)
          .add(schedule.toMap());

      return doc.id;
    } catch (e) {
      throw Exception('Failed to add collection schedule: $e');
    }
  }

  // =========================
  // READ
  // =========================

  Stream<List<CollectionSchedule>> getSchedules() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      final schedules = <CollectionSchedule>[];
      for (final doc in snapshot.docs) {
        try {
          schedules.add(CollectionSchedule.fromMap(doc.id, doc.data()));
        } on FormatException catch (error) {
          if (kDebugMode) {
            debugPrint(
              'CollectionScheduleService: excluding invalid schedule '
              '${doc.id}: ${error.message}',
            );
          }
        }
      }
      return schedules;
    });
  }

  // =========================
  // UPDATE
  // =========================

  Future<void> updateSchedule(String id, CollectionSchedule schedule) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(schedule.toMap());
    } catch (e) {
      throw Exception('Failed to update collection schedule: $e');
    }
  }

  // =========================
  // DELETE
  // =========================

  Future<void> deleteSchedule(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete collection schedule: $e');
    }
  }
}
