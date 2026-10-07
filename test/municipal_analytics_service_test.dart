import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleancycle_mobileapp/services/firebase/firebase_service.dart';
import 'package:cleancycle_mobileapp/services/firebase/firestore_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/municipal_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Firestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reads extends FirestoreService {
  _Reads(this.collections, {this.failure})
    : super(firestoreInstance: _Firestore());
  final Map<String, List<Map<String, dynamic>>> collections;
  final FirebaseServiceException? failure;
  @override
  Future<List<Map<String, dynamic>>> getCollection({
    required String path,
  }) async {
    if (failure != null) throw failure!;
    return collections[path] ?? [];
  }
}

void main() {
  test('Empty collections produce zero counts and empty grouping', () async {
    final summary = await MunicipalAnalyticsService(
      firestoreService: _Reads({}),
    ).getMunicipalAnalyticsSummary();
    expect([
      summary.totalVehicles,
      summary.availableVehicles,
      summary.maintenanceVehicles,
      summary.totalDrivers,
      summary.availableDrivers,
      summary.assignedDrivers,
      summary.totalStaff,
      summary.activeStaff,
      summary.todayCollections,
      summary.completedToday,
      summary.scheduledToday,
      summary.inProgressToday,
      summary.cancelledToday,
    ], everyElement(0));
    expect(summary.collectionsByWasteType.values, everyElement(0));
    expect(summary.collectionsByZone, isEmpty);
  });

  test('Legacy records need no CRUD identifiers or audit timestamps', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final summary = await MunicipalAnalyticsService(
      firestoreService: _Reads({
        'vehicles': [
          {'status': ' AVAILABLE '},
          {'status': 'maintenance'},
          {'status': 1},
        ],
        'drivers': [
          {'status': 'available'},
          {'status': 'assigned'},
          {},
        ],
        'staff': [
          {'status': 'active'},
          {'status': null},
        ],
        'schedules': [
          {
            'collectionDate': today.toIso8601String(),
            'status': 'completed',
            'wasteType': 'organic',
            'zone': ' Kaduwela ',
          },
          {
            'collectionDate': Timestamp.fromDate(today),
            'status': 'in_progress',
            'wasteType': 'general',
            'zone': 'Malabe',
          },
          {
            'collectionDate': today,
            'status': 'scheduled',
            'wasteType': 'mixed',
          },
          {
            'collectionDate': today,
            'status': 'cancelled',
            'wasteType': 'recyclable',
          },
          // Bad optional fields still count; a bad date cannot be counted as today.
          {
            'collectionDate': today,
            'status': null,
            'zone': 123,
            'wasteType': [],
          },
          {'collectionDate': null}, {'collectionDate': 'bad-date'},
          {'collectionDate': today.subtract(const Duration(days: 1))},
          {'collectionDate': today.add(const Duration(days: 1))},
        ],
      }),
    ).getMunicipalAnalyticsSummary();
    expect(summary.totalVehicles, 3);
    expect(summary.availableVehicles, 1);
    expect(summary.maintenanceVehicles, 1);
    expect(summary.totalDrivers, 3);
    expect(summary.availableDrivers, 1);
    expect(summary.assignedDrivers, 1);
    expect(summary.totalStaff, 2);
    expect(summary.activeStaff, 1);
    expect(summary.todayCollections, 5);
    expect([
      summary.completedToday,
      summary.scheduledToday,
      summary.inProgressToday,
      summary.cancelledToday,
    ], everyElement(1));
    expect(summary.collectionsByWasteType, {
      'general': 1,
      'recyclable': 1,
      'organic': 1,
      'mixed': 1,
      'other': 0,
    });
    expect(summary.collectionsByZone, {'Kaduwela': 1, 'Malabe': 1});
  });

  test(
    'A failed collection read preserves the actual Firebase error',
    () async {
      const error = FirebaseServiceException(
        code: 'permission-denied',
        message: 'Denied',
      );
      final service = MunicipalAnalyticsService(
        firestoreService: _Reads({}, failure: error),
      );
      await expectLater(
        service.getMunicipalAnalyticsSummary(),
        throwsA(same(error)),
      );
    },
  );
}
