import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/missed_collection_report.dart';

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
            'collectionDate': Timestamp.fromDate(collectionDate),

            'reason': reason,
            'description': description.trim(),

            'reportStatus': 'pending',

            'residentId': user.uid,
            'reportedBy': user.uid,

            'createdAt': FieldValue.serverTimestamp(),
          });

      return document.id;
    } catch (e) {
      throw Exception('Failed to submit missed collection report: $e');
    }
  }

  Stream<List<MissedCollectionReport>> getMyReports() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(Exception('User is not authenticated.'));
    }

    return _firestore
        .collection(_collectionName)
        .where('residentId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs
              .map(MissedCollectionReport.fromDocument)
              .toList();

          reports.sort((a, b) {
            final aDate = a.createdAt ?? a.collectionDate;
            final bDate = b.createdAt ?? b.collectionDate;
            return bDate.compareTo(aDate);
          });

          return reports;
        });
  }

  Future<void> updateReport({
    required String reportId,
    required String reason,
    required String description,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final reportReference = _firestore.collection(_collectionName).doc(reportId);
      final report = await reportReference.get();

      if (!report.exists || report.data()?['residentId'] != user.uid) {
        throw Exception('You can only edit your own report.');
      }

      if ((report.data()?['reportStatus'] as String? ?? 'pending') !=
          'pending') {
        throw Exception('Only pending reports can be edited.');
      }

      await reportReference.update({
        'reason': reason.trim(),
        'description': description.trim(),
      });
    } catch (e) {
      throw Exception('Failed to update missed collection report: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final reportReference = _firestore.collection(_collectionName).doc(reportId);
      final report = await reportReference.get();

      if (!report.exists || report.data()?['residentId'] != user.uid) {
        throw Exception('You can only delete your own report.');
      }

      if ((report.data()?['reportStatus'] as String? ?? 'pending') !=
          'pending') {
        throw Exception('Only pending reports can be deleted.');
      }

      await reportReference.delete();
    } catch (e) {
      throw Exception('Failed to delete missed collection report: $e');
    }
  }
}
