import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/missed_report_model.dart';
import 'storage_service.dart';

class MissedReportService {
  final FirebaseFirestore? _firestore;
  final StorageService _storageService;

  MissedReportService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore,
        _storageService = storageService ?? StorageService();

  FirebaseFirestore get _instance {
    if (_firestore != null) return _firestore;
    return FirebaseFirestore.instance;
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // In-memory fallback cache for local testing / offline demo
  static final List<MissedReportModel> _mockReports = [
    MissedReportModel(
      reportId: 'MC-20260812-001',
      userId: 'user_default',
      collectionType: 'Recyclable',
      scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Blue recycling bin was not emptied during the morning round.',
      address: 'No. 15, Station Road, Colombo 04',
      photoUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=600&q=80',
      status: 'Reported',
      reportedOn: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  /// [CREATE] Submit a new Missed Collection Report
  Future<String> createReport(MissedReportModel report, File? photo) async {
    String? photoUrl = report.photoUrl;

    if (photo != null) {
      photoUrl = await _storageService.uploadMissedReportPhoto(photo, report.userId);
    }

    final id = report.reportId.isEmpty
        ? 'MC-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().millisecond.toString().padLeft(3, '0')}'
        : report.reportId;

    final newReport = report.copyWith(
      reportId: id,
      photoUrl: photoUrl,
    );

    _mockReports.insert(0, newReport);

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('missed_reports').doc(id).set(newReport.toMap());
        debugPrint('Missed report successfully saved to Firestore: $id');
      } catch (e) {
        debugPrint('Firestore save error for missed report: $e');
      }
    }
    return id;
  }

  /// [READ] Stream a single report by ID (receipt/status screen)
  Stream<MissedReportModel?> getReportStream(String reportId) {
    if (!_isFirebaseAvailable) {
      final match = _mockReports.where((r) => r.reportId == reportId);
      return Stream.value(match.isNotEmpty ? match.first : null);
    }

    try {
      return _instance
          .collection('missed_reports')
          .doc(reportId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return MissedReportModel.fromFirestore(doc);
        }
        final match = _mockReports.where((r) => r.reportId == reportId);
        return match.isNotEmpty ? match.first : null;
      });
    } catch (_) {
      final match = _mockReports.where((r) => r.reportId == reportId);
      return Stream.value(match.isNotEmpty ? match.first : null);
    }
  }

  /// [READ] Get all reports for a specific user
  Stream<List<MissedReportModel>> getUserReportsStream(String userId) {
    if (!_isFirebaseAvailable) {
      return Stream.value(List.from(_mockReports));
    }

    try {
      return _instance
          .collection('missed_reports')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => MissedReportModel.fromFirestore(doc)).toList();
        }
        return List<MissedReportModel>.from(_mockReports);
      });
    } catch (_) {
      return Stream.value(List.from(_mockReports));
    }
  }

  /// [UPDATE] Edit report description (backward compatible)
  Future<void> updateReportDescription(String reportId, String newDescription) async {
    await updateReportDetails(reportId, description: newDescription);
  }

  /// [UPDATE] Edit all relevant report fields
  Future<void> updateReportDetails(
    String reportId, {
    String? collectionType,
    DateTime? scheduledDate,
    String? address,
    String? description,
    String? photoUrl,
  }) async {
    final index = _mockReports.indexWhere((r) => r.reportId == reportId);
    if (index != -1) {
      _mockReports[index] = _mockReports[index].copyWith(
        collectionType: collectionType ?? _mockReports[index].collectionType,
        scheduledDate: scheduledDate ?? _mockReports[index].scheduledDate,
        address: address ?? _mockReports[index].address,
        description: description ?? _mockReports[index].description,
        photoUrl: photoUrl ?? _mockReports[index].photoUrl,
      );
    }

    if (_isFirebaseAvailable) {
      try {
        final Map<String, dynamic> updateData = {};
        if (collectionType != null) updateData['collectionType'] = collectionType;
        if (scheduledDate != null) updateData['scheduledDate'] = Timestamp.fromDate(scheduledDate);
        if (address != null) updateData['address'] = address;
        if (description != null) updateData['description'] = description;
        if (photoUrl != null) updateData['photoUrl'] = photoUrl;

        if (updateData.isNotEmpty) {
          await _instance.collection('missed_reports').doc(reportId).update(updateData);
        }
      } catch (e) {
        debugPrint('Firestore update error: $e');
      }
    }
  }

  /// [UPDATE] Update report status
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    final index = _mockReports.indexWhere((r) => r.reportId == reportId);
    if (index != -1) {
      _mockReports[index] = _mockReports[index].copyWith(status: newStatus);
    }

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('missed_reports').doc(reportId).update({
          'status': newStatus,
        });
      } catch (e) {
        debugPrint('Firestore update error: $e');
      }
    }
  }

  /// [DELETE] Cancel / Withdraw a report
  Future<void> cancelReport(String reportId) async {
    _mockReports.removeWhere((r) => r.reportId == reportId);

    if (_isFirebaseAvailable) {
      try {
        await _instance.collection('missed_reports').doc(reportId).delete();
      } catch (e) {
        debugPrint('Firestore delete error: $e');
      }
    }
  }
}
