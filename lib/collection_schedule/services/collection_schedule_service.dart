import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_schedule.dart';

class CollectionScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collection name
  final String _collectionName = 'schedules';

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
      return snapshot.docs.map((doc) {
        return CollectionSchedule.fromMap(doc.id, doc.data());
      }).toList();
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
