import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleancycle_mobileapp/collection_schedule/models/collection_schedule.dart'
    as resident;
import 'package:cleancycle_mobileapp/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/services/firebase/firestore_service.dart';
import 'package:cleancycle_mobileapp/services/firebase/firebase_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/schedule_service.dart';
import 'package:cleancycle_mobileapp/vishani/services/tracking_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Firestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Only test storage is used; no production Firebase writes.
// ignore: subtype_of_sealed_class
class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Store extends FirestoreService {
  _Store(this.records) : super(firestoreInstance: _Firestore());
  final Map<String, Map<String, dynamic>> records;
  final projections = <String, Map<String, dynamic>>{};
  bool? lastMerge;
  String? lastPath;

  @override
  Future<Map<String, dynamic>?> getDocument({required String path}) async =>
      records[path.split('/').last];

  @override
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getCollectionSnapshots({
    required String path,
  }) async {
    expect(path, 'schedules');
    return records.entries
        .map((entry) => _Snapshot(entry.key, entry.value))
        .toList();
  }

  @override
  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    lastPath = path;
    lastMerge = merge;
    final id = path.split('/').last;
    records[id] = {
      ...(merge ? records[id] ?? {} : <String, dynamic>{}),
      ...data,
    };
  }

  @override
  Future<void> deleteDocument({required String path}) async {
    lastPath = path;
    records.remove(path.split('/').last);
  }
}

class _Tracking extends TrackingService {
  _Tracking(this.store)
    : super(firestore: _Firestore(), authenticatedUid: () => 'officer');
  final _Store store;
  Object? writeFailure;

  @override
  Future<void> saveScheduleAndProjection(
    String scheduleId, {
    required Map<String, dynamic> scheduleData,
    Map<String, dynamic>? projectionData,
    bool mergeSchedule = true,
  }) async {
    if (writeFailure case final error?) throw error;
    final previous = store.records[scheduleId] ?? <String, dynamic>{};
    store.records[scheduleId] = {
      ...(mergeSchedule ? previous : <String, dynamic>{}),
      ...scheduleData,
    };
    store.projections[scheduleId] = TrackingService.residentScheduleProjection(
      projectionData ?? store.records[scheduleId]!,
    );
    store.lastPath = 'schedules/$scheduleId';
    store.lastMerge = mergeSchedule;
  }

  @override
  Future<void> deleteScheduleAndProjection(String scheduleId) async {
    store.records.remove(scheduleId);
    store.projections.remove(scheduleId);
    store.lastPath = 'schedules/$scheduleId';
  }
}

ScheduleService _service(_Store store) =>
    ScheduleService(firestoreService: store, trackingService: _Tracking(store));

Map<String, dynamic> legacy() => {
  'wasteType': 'Recyclable',
  'collectionDate': '2026-08-14T00:00:00.000',
  'startTime': '08:00',
  'endTime': '10:00',
  'status': 'Scheduled',
  'acceptedItems': ['Paper', 'Plastic'],
  'instructions': 'Separate recyclables.',
};

CollectionSchedule schedule(String id) => CollectionSchedule(
  scheduleId: id,
  zone: 'Malabe',
  collectionDate: DateTime(2026, 8, 14),
  startTime: '08:00',
  endTime: '10:00',
  wasteType: 'recyclable',
  status: 'scheduled',
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);

void main() {
  test(
    'Actual shared Firestore structure reads without losing the schedule',
    () {
      final model = CollectionSchedule.fromDocumentSnapshot(
        _Snapshot('4og3O7TAu9LLZOtivbRj', {
          ...legacy(),
          'startTime': '8:00 AM',
          'endTime': '12:00 PM',
          'wasteType': 'Recyclable Waste',
          'status': 'upcoming',
        }),
      );
      expect(model.scheduleId, '4og3O7TAu9LLZOtivbRj');
      expect(model.startTime, '08:00');
      expect(model.endTime, '12:00');
      expect(model.wasteType, 'recyclable');
      expect(model.status, 'scheduled');
    },
  );
  test('Display time conversion respects noon, midnight and invalid times', () {
    final model = CollectionSchedule.fromMap({
      ...legacy(),
      'startTime': '12:00 AM',
      'endTime': '1:30 PM',
    }, documentId: 'legacy');
    expect(model.startTime, '00:00');
    expect(model.endTime, '13:30');
    expect(
      () => CollectionSchedule.fromMap({
        ...legacy(),
        'startTime': '13:00 AM',
      }, documentId: 'legacy'),
      throwsFormatException,
    );
  });

  test('Legacy snapshot ID is used without inventing missing metadata', () {
    final model = CollectionSchedule.fromDocumentSnapshot(
      _Snapshot('member02-id', legacy()),
    );
    expect(model.scheduleId, 'member02-id');
    expect(model.collectionDate, DateTime(2026, 8, 14));
    expect(model.zone, isEmpty);
    expect(model.createdAt, isNull);
    expect(model.updatedAt, isNull);
    expect(model.notes, 'Separate recyclables.');
    expect(model.wasteType, 'recyclable');
    expect(model.status, 'scheduled');
    expect(model.toMap().containsKey('createdAt'), isFalse);
  });

  test(
    'Updating actual legacy record preserves unchanged Resident values',
    () async {
      final store = _Store({
        'legacy': {
          ...legacy(),
          'wasteType': 'Recyclable Waste',
          'status': 'upcoming',
          'startTime': '8:00 AM',
          'endTime': '12:00 PM',
        },
      });
      final service = _service(store);
      final original = (await service.getSchedule(scheduleId: 'legacy'))!;
      await service.updateSchedule(
        scheduleId: 'legacy',
        schedule: CollectionSchedule(
          scheduleId: original.scheduleId,
          zone: 'Malabe',
          collectionDate: original.collectionDate,
          startTime: original.startTime,
          endTime: original.endTime,
          wasteType: original.wasteType,
          status: original.status,
          notes: original.notes,
          createdAt: original.createdAt,
          updatedAt: original.updatedAt,
        ),
      );
      expect(store.records['legacy']!['scheduleId'], 'legacy');
      expect(store.records['legacy']!['wasteType'], 'Recyclable Waste');
      expect(store.records['legacy']!['status'], 'upcoming');
      expect(store.records['legacy']!['startTime'], '8:00 AM');
      expect(store.records['legacy']!['endTime'], '12:00 PM');
    },
  );

  test('Explicit scheduleId takes priority over document ID', () {
    final model = CollectionSchedule.fromDocumentSnapshot(
      _Snapshot('document-id', {...legacy(), 'scheduleId': 'stored-id'}),
    );
    expect(model.scheduleId, 'stored-id');
  });

  test('Null ID falls back to path, but absent identity still fails', () {
    expect(
      CollectionSchedule.fromMap({
        ...legacy(),
        'scheduleId': null,
      }, documentId: 'path-id').scheduleId,
      'path-id',
    );
    expect(() => CollectionSchedule.fromMap(legacy()), throwsFormatException);
  });

  for (final date in [
    DateTime(2026, 8, 14),
    Timestamp.fromDate(DateTime(2026, 8, 14)),
    '2026-08-14T00:00:00.000',
  ]) {
    test('Collection date reads ${date.runtimeType}', () {
      final model = CollectionSchedule.fromMap({
        ...schedule('native').toMap(),
        'collectionDate': date,
      });
      expect(model.collectionDate, DateTime(2026, 8, 14));
    });
  }

  test('Malformed dates and missing operational fields remain errors', () {
    expect(
      () => CollectionSchedule.fromMap({
        ...legacy(),
        'collectionDate': 'invalid',
      }, documentId: 'id'),
      throwsFormatException,
    );
    final fields = legacy()..remove('startTime');
    expect(
      () => CollectionSchedule.fromMap(fields, documentId: 'id'),
      throwsFormatException,
    );
  });

  test('Municipal and Member 02 records both remain in the list', () async {
    final store = _Store({
      'legacy-id': legacy(),
      'native-id': schedule('native-id').toMap(),
    });
    final service = _service(store);
    final values = await service.getSchedules();
    expect(values.map((s) => s.scheduleId), ['legacy-id', 'native-id']);
    expect(
      (await service.getSchedule(scheduleId: 'legacy-id'))!.scheduleId,
      'legacy-id',
    );
  });

  test(
    'Create uses the same normalized ID in the document path and field',
    () async {
      final store = _Store({});
      final service = _service(store);
      await service.createSchedule(schedule: schedule(' new-id '));
      expect(store.lastPath, 'schedules/new-id');
      expect(store.records['new-id']!['scheduleId'], 'new-id');
      expect(store.lastMerge, isFalse);
      expect(store.records['new-id']!['createdAt'], isA<Timestamp>());
      expect(store.records['new-id']!['updatedAt'], isA<Timestamp>());
      await expectLater(
        service.createSchedule(schedule: schedule('new-id')),
        throwsA(isA<ScheduleServiceException>()),
      );
    },
  );

  test(
    'creation preserves the original secondary-write failure stack',
    () async {
      final store = _Store({});
      final tracking = _Tracking(store)
        ..writeFailure = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Resident projection write denied.',
        );
      final service = ScheduleService(
        firestoreService: store,
        trackingService: tracking,
      );
      Object? caught;
      StackTrace? originalStack;
      try {
        await service.createSchedule(schedule: schedule('projection-denied'));
      } catch (error, stack) {
        caught = error;
        originalStack = stack;
      }
      expect(
        caught,
        isA<FirebaseServiceException>()
            .having((error) => error.code, 'code', 'permission-denied')
            .having(
              (error) => error.message,
              'message',
              'Resident projection write denied.',
            ),
      );
      expect(
        originalStack.toString(),
        contains('_Tracking.saveScheduleAndProjection'),
      );
      expect(store.records, isEmpty);
    },
  );

  test(
    'Create preserves Firestore write code and message on failure',
    () async {
      final store = _Store({});
      final tracking = _Tracking(store)
        ..writeFailure = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Schedule write rejected by rules.',
        );
      final service = ScheduleService(
        firestoreService: store,
        trackingService: tracking,
      );

      await expectLater(
        service.createSchedule(schedule: schedule('denied')),
        throwsA(
          isA<FirebaseServiceException>()
              .having((error) => error.code, 'code', 'permission-denied')
              .having(
                (error) => error.message,
                'message',
                'Schedule write rejected by rules.',
              ),
        ),
      );
      expect(store.records, isEmpty);
    },
  );

  test(
    'Update preserves Resident fields and date encoding; delete uses original ID',
    () async {
      final store = _Store({'legacy-id': legacy()});
      final service = _service(store);
      await service.updateSchedule(
        scheduleId: 'legacy-id',
        schedule: schedule('legacy-id'),
      );
      final data = store.records['legacy-id']!;
      expect(store.lastMerge, isTrue);
      expect(data['scheduleId'], 'legacy-id');
      expect(data['acceptedItems'], ['Paper', 'Plastic']);
      expect(data['instructions'], 'Separate recyclables.');
      expect(data['collectionDate'], isA<String>());
      expect(data.containsKey('createdAt'), isFalse);
      expect(data['updatedAt'], isA<Timestamp>());
      expect(
        resident.CollectionSchedule.fromMap('legacy-id', data).collectionDate,
        DateTime(2026, 8, 14),
      );
      await service.deleteSchedule(scheduleId: 'legacy-id');
      expect(store.lastPath, 'schedules/legacy-id');
      expect(store.records, isEmpty);
    },
  );

  test(
    'Native update retains Timestamp encoding and original creation time',
    () async {
      final original = schedule('native').toMap();
      final store = _Store({'native': original});
      await _service(
        store,
      ).updateSchedule(scheduleId: 'native', schedule: schedule('native'));
      expect(store.records['native']!['collectionDate'], isA<Timestamp>());
      expect(store.records['native']!['createdAt'], original['createdAt']);
    },
  );

  test('Update rejects a different payload ID and never writes', () async {
    final store = _Store({'original': legacy()});
    await expectLater(
      _service(
        store,
      ).updateSchedule(scheduleId: 'original', schedule: schedule('different')),
      throwsA(isA<ScheduleServiceException>()),
    );
    expect(store.lastPath, isNull);
    expect(store.records.keys, ['original']);
  });
}
