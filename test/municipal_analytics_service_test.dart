import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleancycle_mobileapp/services/firebase/firebase_service.dart';
import 'package:cleancycle_mobileapp/services/firebase/firestore_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/municipal_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/tracking_firestore.dart';

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
  Future<List<Map<String, dynamic>>> getCollectionWithIds({
    required String path,
  }) => getCollection(path: path);
  @override
  Future<List<Map<String, dynamic>>> getCollection({
    required String path,
  }) async {
    if (failure != null) throw failure!;
    return collections[path] ?? [];
  }
}

void main() {
  test(
    'October 8 completion is excluded from October 13 screenshot scenario',
    () async {
      final db = TrackingFirestoreFixture()..documents.clear();
      Map<String, dynamic> schedule(String id, Object date, String status) => {
        'scheduleId': id,
        'collectionDate': date,
        'status': status,
        'zone': 'Malabe',
        'startTime': '08:00',
        'endTime': '17:00',
        'wasteType': 'recyclable',
      };
      db.documents['schedules/schedule_001'] = schedule(
        'schedule_001',
        Timestamp.fromDate(DateTime.utc(2026, 10, 7, 18, 30)),
        'completed',
      );
      db.documents['schedules/schedule_002'] = schedule(
        'schedule_002',
        Timestamp.fromDate(DateTime.parse('2026-10-12T18:48:53.865828Z')),
        'completed',
      );
      db.documents['schedules/schedule_003'] = schedule(
        'schedule_003',
        Timestamp.fromDate(DateTime.parse('2026-10-12T19:59:02.207333Z')),
        'scheduled',
      );
      db.documents['schedules/future'] = schedule(
        'future',
        '2026-10-14',
        'scheduled',
      );
      // Resident copies are a separate view, never an additional collection route.
      db.documents['resident_schedules/schedule_003'] = Map.of(
        db.documents['schedules/schedule_003']!,
      );
      final service = MunicipalAnalyticsService(
        firestoreService: FirestoreService(firestoreInstance: db),
        now: () => DateTime.utc(2026, 10, 13, 12),
      );
      var summary = await service.getMunicipalAnalyticsSummary();
      expect(summary.todayCollections, 2);
      expect(summary.completedToday, 1);
      expect(summary.inProgressToday, 0);
      expect(summary.scheduledToday, 1);
      expect(summary.missedToday, 0);
      db.documents['schedules/schedule_003']!['status'] = 'in_progress';
      summary = await service.getMunicipalAnalyticsSummary();
      expect(summary.todayCollections, 2);
      expect(summary.completedToday, 1);
      expect(summary.inProgressToday, 1);
      expect(summary.scheduledToday, 0);
      db.documents['schedules/schedule_003']!['status'] = 'completed';
      summary = await service.getMunicipalAnalyticsSummary();
      expect(summary.todayCollections, 2);
      expect(summary.completedToday, 2);
      expect(summary.inProgressToday, 0);
      expect(summary.missedToday, 0);
      await db.dispose();
    },
  );

  test(
    'logical duplicates use canonical schedule before today filtering',
    () async {
      final records = [
        {
          '_documentId': 'old-copy',
          'scheduleId': 'schedule_003',
          'collectionDate': '2026-10-13',
          'status': 'completed',
        },
        {
          '_documentId': 'schedule_003',
          'scheduleId': 'schedule_003',
          'collectionDate': '2026-10-14',
          'status': 'scheduled',
        },
        {
          '_documentId': 'copy-b',
          'scheduleId': 'legacy',
          'collectionDate': '2026-10-13',
          'status': 'scheduled',
          'updatedAt': '2026-10-13T08:00:00Z',
        },
        {
          '_documentId': 'copy-a',
          'scheduleId': 'legacy',
          'collectionDate': '2026-10-13',
          'status': 'in_progress',
          'updatedAt': '2026-10-13T09:00:00Z',
        },
        {
          '_documentId': 'no-stored-id',
          'collectionDate': '2026-10-13',
          'status': 'missed',
        },
      ];
      for (final rows in [records, records.reversed.toList()]) {
        final summary = await MunicipalAnalyticsService(
          now: () => DateTime.utc(2026, 10, 13, 12),
          firestoreService: _Reads({'schedules': rows}),
        ).getMunicipalAnalyticsSummary();
        expect(summary.todayCollections, 2);
        expect(summary.completedToday, 0);
        expect(summary.inProgressToday, 1);
        expect(summary.missedToday, 1);
        expect(summary.scheduledToday, 0);
      }
    },
  );
  test(
    'Colombo day, legacy dates, status normalization and canonical IDs',
    () async {
      Map<String, dynamic> row(String id, Object? date, Object? status) => {
        '_documentId': id,
        'scheduleId': id,
        'collectionDate': date,
        'status': status,
        'zone': 'Malabe',
      };
      final service = MunicipalAnalyticsService(
        now: () => DateTime.utc(2026, 10, 12, 19), // Oct 13 in Colombo.
        firestoreService: _Reads({
          'schedules': [
            row(
              'a',
              Timestamp.fromDate(DateTime.utc(2026, 10, 12, 18, 30)),
              ' COMPLETED ',
            ),
            row(
              'a',
              '2026-10-13',
              'completed',
            ), // Duplicate document, not another route.
            row('b', '2026-10-12T19:00:00Z', 'In Progress'),
            row('c', '2026-10-13T00:00:00', 'missed'),
            row('d', '13/10/2026', 'Cancelled'),
            row('e', DateTime.utc(2026, 10, 13), 'upcoming'),
            row('f', '2026-10-13T08:00:00+05:30', 'in-progress'),
            row('g', '2026-10-13', null),
            row('yesterday', '2026-10-12T18:29:59Z', 'completed'),
            row('tomorrow', '2026-10-13T18:30:00Z', 'completed'),
            row('overflow', '2026-10-32', 'completed'),
            row('invalid-time', '2026-10-13T25:00:00', 'completed'),
            row('invalid-minute', '2026-10-13T00:90:00Z', 'completed'),
            row('bad', '2026-10-13Tbad', 'completed'),
            row('missing', null, 'completed'),
          ],
        }),
      );
      final summary = await service.getMunicipalAnalyticsSummary();
      expect(summary.todayCollections, 7);
      expect(summary.completedToday, 1);
      expect(summary.inProgressToday, 2);
      expect(summary.missedToday, 1);
      expect(summary.cancelledToday, 1);
      expect(summary.scheduledToday, 1);
      expect(summary.unknownToday, 1);
      expect(summary.collectionsByZone, {'Malabe': 7});
      expect(
        summary.completedToday +
            summary.inProgressToday +
            summary.missedToday +
            summary.cancelledToday +
            summary.scheduledToday +
            summary.unknownToday,
        summary.todayCollections,
      );
    },
  );

  test('live summary refreshes after schedule changes and midnight', () async {
    final db = TrackingFirestoreFixture()..documents.clear();
    var now = DateTime.utc(2026, 10, 13, 8);
    final service = MunicipalAnalyticsService(
      firestoreService: FirestoreService(firestoreInstance: db),
      now: () => now,
    );
    final summaries = <MunicipalAnalyticsSummary>[];
    final subscription = service.watchMunicipalAnalyticsSummary().listen(
      summaries.add,
    );
    await Future<void>.delayed(Duration.zero);
    expect(summaries.last.todayCollections, 0);
    db.documents['schedules/real-id'] = {
      'collectionDate': '2026-10-13',
      'status': 'scheduled',
    };
    db.publish();
    await Future<void>.delayed(Duration.zero);
    expect(summaries.last.scheduledToday, 1);
    db.documents['schedules/real-id']!['status'] = 'completed';
    db.publish();
    await Future<void>.delayed(Duration.zero);
    expect(summaries.last.completedToday, 1);
    now = now.add(const Duration(days: 1));
    db.publish();
    await Future<void>.delayed(Duration.zero);
    expect(summaries.last.todayCollections, 0);
    await subscription.cancel();
    await db.dispose();
  });

  test('live Firestore denial is an error rather than zero counts', () async {
    final db = TrackingFirestoreFixture()..denied.add('schedules');
    final service = MunicipalAnalyticsService(
      firestoreService: FirestoreService(firestoreInstance: db),
    );
    await expectLater(
      service.watchMunicipalAnalyticsSummary().first,
      throwsA(
        isA<FirebaseServiceException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
    await db.dispose();
  });
  test(
    'Vehicle performance counts only today completed assigned schedules',
    () async {
      final now = DateTime.utc(2026, 10, 13, 8);
      final today = DateTime(now.year, now.month, now.day);
      Map<String, dynamic> record(
        Object? date,
        Object? vehicle,
        String status,
      ) => {
        'collectionDate': date,
        'assignedVehicleId': vehicle,
        'status': status,
        'assignedDriverId': 'driver-with-no-route-history',
      };
      final summary = await MunicipalAnalyticsService(
        now: () => DateTime.utc(2026, 10, 13, 8),
        firestoreService: _Reads({
          'schedules': [
            record(today, ' VEH-1 ', 'completed'),
            record(Timestamp.fromDate(today), 'VEH-1', ' COMPLETED '),
            record(today.toIso8601String(), 'VEH-2', 'completed'),
            record(today, null, 'completed'),
            record(today, '', 'completed'),
            record(today, 99, 'completed'),
            record(today, 'VEH-1', 'scheduled'),
            record(today, 'VEH-1', 'in_progress'),
            record(today, 'VEH-1', 'cancelled'),
            record(
              today.subtract(const Duration(days: 1)),
              'VEH-1',
              'completed',
            ),
            record(today.add(const Duration(days: 1)), 'VEH-1', 'completed'),
            record('invalid', 'VEH-1', 'completed'),
          ],
        }),
      ).getMunicipalAnalyticsSummary();
      expect(summary.completedCollectionsByVehicleToday, {
        'VEH-1': 2,
        'VEH-2': 1,
      });
      expect(
        () => summary.completedCollectionsByVehicleToday['new'] = 1,
        throwsUnsupportedError,
      );
    },
  );
  test('Empty collections produce zero counts and empty grouping', () async {
    final summary = await MunicipalAnalyticsService(
      now: () => DateTime.utc(2026, 10, 13, 8),
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
    expect(summary.completedCollectionsByVehicleToday, isEmpty);
  });

  test('Legacy records need no CRUD identifiers or audit timestamps', () async {
    final now = DateTime.utc(2026, 10, 13, 8);
    final today = DateTime(now.year, now.month, now.day);
    final summary = await MunicipalAnalyticsService(
      now: () => DateTime.utc(2026, 10, 13, 8),
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
        now: () => DateTime.utc(2026, 10, 13, 8),
        firestoreService: _Reads({}, failure: error),
      );
      await expectLater(
        service.getMunicipalAnalyticsSummary(),
        throwsA(same(error)),
      );
    },
  );
}
