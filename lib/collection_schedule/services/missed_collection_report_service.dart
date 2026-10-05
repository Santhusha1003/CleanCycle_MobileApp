import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MissedCollectionReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _collectionName = 'missedCollectionReports';

  // ============================================================
  // CREATE MISSED COLLECTION REPORT
  // ============================================================

  Future<String> submitReport({
    required String scheduleId,
    required String wasteType,
    required DateTime collectionDate,
    required String reason,
    required String description,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User is not authenticated.');
      }

      final DocumentReference document = await _firestore
          .collection(_collectionName)
          .add({
            'scheduleId': scheduleId,
            'wasteType': wasteType,
            'collectionDate': collectionDate.toIso8601String(),

            'reason': reason,
            'description': description.trim(),

            'reportStatus': 'pending',

            'reportedBy': user.uid,

            'createdAt': FieldValue.serverTimestamp(),
          });

      return document.id;
    } catch (e) {
      throw Exception('Failed to submit missed collection report: $e');
    }
  }
}
