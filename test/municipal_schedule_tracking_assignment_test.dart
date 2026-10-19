import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleancycle_mobileapp/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/models/driver.dart';
import 'package:cleancycle_mobileapp/services/firebase/firestore_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/driver_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/schedule_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/vehicle_service.dart';
import 'package:cleancycle_mobileapp/vishani/services/tracking_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cleancycle_mobileapp/services/firebase/firebase_service.dart';

import 'support/tracking_firestore.dart';

class _FixtureStore extends FirestoreService {
  _FixtureStore(this.db) : super(firestoreInstance: db);
  final TrackingFirestoreFixture db;

  @override
  Future<Map<String, dynamic>?> getDocument({required String path}) async =>
      db.documents[path];

  @override
  Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    db.documents[path] = {...db.documents[path]!, ...data};
    db.writes.add(path);
    db.publish();
  }

  @override
  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    db.documents[path] = {
      ...(merge ? db.documents[path] ?? {} : <String, dynamic>{}),
      ...data,
    };
    db.writes.add(path);
    db.publish();
  }
}

CollectionSchedule schedule({
  String? driverId = 'municipal-driver-1',
  String? vehicleId = 'ABC-001',
  String status = 'scheduled',
}) => CollectionSchedule(
  scheduleId: 'schedule-integration',
  zone: 'North',
  collectionDate: DateTime(2026, 10, 10),
  startTime: '08:00',
  endTime: '10:00',
  wasteType: 'general',
  assignedDriverId: driverId,
  assignedVehicleId: vehicleId,
  status: status,
  createdAt: DateTime(2026, 10, 9),
  updatedAt: DateTime(2026, 10, 9),
);

void main() {
  late TrackingFirestoreFixture db;
  late _FixtureStore store;
  late DriverService driverService;
  late VehicleService vehicleService;
  late TrackingService trackingService;
  late ScheduleService scheduleService;

  setUp(() {
    db = TrackingFirestoreFixture();
    store = _FixtureStore(db);
    driverService = DriverService(
      firestoreService: store,
      authenticatedUid: () => 'officer',
    );
    vehicleService = VehicleService(firestoreService: store);
    trackingService = TrackingService(
      firestore: db,
      authenticatedUid: () => 'officer',
    );
    scheduleService = ScheduleService(
      firestoreService: store,
      driverService: driverService,
      vehicleService: vehicleService,
      trackingService: trackingService,
    );
  });
  tearDown(() => db.dispose());

  test(
    'driver next collection scopes schedules to the verified record ID',
    () async {
      db.documents['drivers/municipal-driver-1']!['authUid'] = 'd1';
      db.documents['schedules/driver-next'] = {
        'assignedDriverUid': 'd1',
        'assignedDriverId': 'municipal-driver-1',
        'collectionDate': '2099-10-10',
        'startTime': '08:00',
        'endTime': '10:00',
        'wasteType': 'general',
        'status': 'scheduled',
      };
      final driverTracking = TrackingService(
        firestore: db,
        authenticatedUid: () => 'd1',
      );
      final result = await driverTracking.fetchNextCollection('d1');
      expect(result['category'], 'general');
      final reads = db.queryReads.where(
        (read) => read.collection == 'schedules',
      );
      expect(reads.single.filters, {
        'assignedDriverUid': 'd1',
        'assignedDriverId': 'municipal-driver-1',
      });
    },
  );

  test(
    'missing driver link does not issue a schedule collection query',
    () async {
      db.documents.remove('drivers/municipal-driver-1');
      final driverTracking = TrackingService(
        firestore: db,
        authenticatedUid: () => 'd1',
      );
      expect(await driverTracking.fetchNextCollection('d1'), isEmpty);
      expect(
        db.queryReads.where((read) => read.collection == 'schedules'),
        isEmpty,
      );
    },
  );

  test(
    'example assigned schedule saves typed fields and matching projection',
    () async {
      db.documents['drivers/driver003'] = {
        ...db.documents['drivers/municipal-driver-1']!,
        'driverId': 'driver003',
        'fullName': 'Nuwan Jayasinghe',
      };
      db.documents['vehicles/WP-CAB-2341'] = {
        ...db.documents['vehicles/ABC-001']!,
        'registrationNumber': 'WP-CAB-2341',
        'vehicleType': 'Garbage Truck',
      };
      final date = DateTime(2026, 10, 13);
      final input = CollectionSchedule(
        scheduleId: 'schedule_003',
        zone: 'Malabe',
        collectionDate: date,
        startTime: '08:00',
        endTime: '17:00',
        wasteType: 'recyclable',
        status: 'scheduled',
        assignedDriverId: 'driver003',
        assignedVehicleId: 'WP-CAB-2341',
        createdAt: date,
        updatedAt: date,
      );
      await scheduleService.createSchedule(schedule: input);
      final saved = db.documents['schedules/schedule_003']!;
      expect((saved['collectionDate'] as Timestamp).toDate(), date);
      expect(saved['startTime'], '08:00');
      expect(saved['endTime'], '17:00');
      expect(saved['wasteType'], 'recyclable');
      expect(saved['status'], 'scheduled');
      expect(saved['assignedDriverId'], 'driver003');
      expect(saved['assignedDriverUid'], 'd1');
      expect(saved['assignedVehicleId'], 'WP-CAB-2341');
      expect(saved['trackingTripId'], 'schedules_schedule_003');
      expect(saved['createdAt'], isA<Timestamp>());
      expect(saved['updatedAt'], isA<Timestamp>());
      final projection = db.documents['resident_schedules/schedule_003']!;
      expect(projection['collectionDate'], saved['collectionDate']);
      expect(projection['zone'], 'Malabe');
      expect(projection.containsKey('assignedDriverUid'), isFalse);

      // An existing ID must not replace the saved record.
      final before = Map<String, dynamic>.from(saved);
      await expectLater(
        scheduleService.createSchedule(schedule: input),
        throwsA(isA<ScheduleServiceException>()),
      );
      expect(db.documents['schedules/schedule_003'], before);
    },
  );

  test(
    'municipal driver and vehicle selections are submitted independently',
    () async {
      db.documents['drivers/municipal-driver-1']!['assignedVehicleId'] =
          'ABC-002';
      await scheduleService.createSchedule(schedule: schedule());
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverId'],
        'municipal-driver-1',
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedVehicleId'],
        'ABC-001',
      );
      expect(
        db.documents['drivers/municipal-driver-1']!['assignedVehicleId'],
        'ABC-002',
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverUid'],
        isNull,
      );
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
    },
  );

  test(
    'vehicle linked to another Driver creates no authenticated trip',
    () async {
      db.documents['vehicles/ABC-001']!['assignedDriverId'] = 'another-driver';
      await scheduleService.createSchedule(schedule: schedule());
      final saved = db.documents['schedules/schedule-integration']!;
      expect(saved['assignedDriverId'], 'municipal-driver-1');
      expect(saved['assignedVehicleId'], 'ABC-001');
      expect(saved['assignedDriverUid'], isNull);
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
      expect(
        db.documents['vehicles/ABC-001']!['assignedDriverId'],
        'another-driver',
      );
    },
  );

  test(
    'unlinked selected Driver ID and name survive creation and updates',
    () async {
      db.documents.remove('users/d1');
      await scheduleService.createSchedule(schedule: schedule());
      var saved = db.documents['schedules/schedule-integration']!;
      expect(saved['assignedDriverId'], 'municipal-driver-1');
      expect(saved['assignedDriverName'], 'Driver One');
      expect(saved['assignedDriverUid'], isNull);
      expect(saved['assignedVehicleId'], 'ABC-001');
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
      expect(
        db.documents['drivers/municipal-driver-1']!.containsKey('authUid'),
        isFalse,
      );
      await scheduleService.updateSchedule(
        scheduleId: 'schedule-integration',
        schedule: schedule(),
      );
      saved = db.documents['schedules/schedule-integration']!;
      expect(saved['assignedDriverId'], 'municipal-driver-1');
      expect(saved['assignedDriverName'], 'Driver One');
      expect(
        db.documents['resident_schedules/schedule-integration'],
        isNotNull,
      );
    },
  );

  test(
    'driver without a vehicle and vehicle without a driver are independently supported',
    () async {
      await scheduleService.createSchedule(schedule: schedule(vehicleId: null));
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverId'],
        'municipal-driver-1',
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverUid'],
        isNull,
      );
      await scheduleService.updateSchedule(
        scheduleId: 'schedule-integration',
        schedule: schedule(driverId: null),
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverId'],
        isNull,
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverName'],
        isNull,
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedVehicleId'],
        'ABC-001',
      );
    },
  );

  test(
    'losing account linkage retains municipal assignment and removes stale tracking',
    () async {
      await scheduleService.createSchedule(schedule: schedule());
      db.documents.remove('users/d1');
      await scheduleService.updateSchedule(
        scheduleId: 'schedule-integration',
        schedule: schedule(),
      );
      final saved = db.documents['schedules/schedule-integration']!;
      expect(saved['assignedDriverId'], 'municipal-driver-1');
      expect(saved['assignedDriverName'], 'Driver One');
      expect(saved.containsKey('assignedDriverUid'), isFalse);
      expect(saved.containsKey('trackingTripId'), isFalse);
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
    },
  );

  test('non-officer cannot create an assigned schedule', () async {
    db.documents['users/officer']!['role'] = 'resident';
    await expectLater(
      scheduleService.createSchedule(schedule: schedule()),
      throwsA(
        isA<ScheduleServiceException>().having(
          (error) => error.message,
          'message',
          contains('authorized Municipal Officer'),
        ),
      ),
    );
    expect(db.writes, isEmpty);
  });

  test(
    'unassigned creation persists schedule and resident projection without trip',
    () async {
      await scheduleService.createSchedule(
        schedule: schedule(driverId: null, vehicleId: null),
      );
      expect(db.documents['schedules/schedule-integration'], isNotNull);
      expect(
        db.documents['resident_schedules/schedule-integration'],
        isNotNull,
      );
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
    },
  );

  test(
    'existing account link uses canonical document UID without a duplicate uid field',
    () async {
      db.documents['drivers/municipal-driver-1']!['authUid'] = 'd1';
      db.documents['users/d1']!.remove('uid');
      db.documents['users/d1']!['email'] = ' DRIVER1@EXAMPLE.TEST ';
      expect(
        await driverService.resolveVerifiedAuthUid(
          driverId: 'municipal-driver-1',
        ),
        'd1',
      );
      expect(db.queries, isEmpty);
      expect(db.writes, isEmpty);
    },
  );

  test(
    'unlinked approved profile matches across email casing and whitespace',
    () async {
      db.documents['users/d1']!['email'] = ' Driver1@Example.Test ';
      db.documents['users/d1']!.remove('uid');
      await scheduleService.createSchedule(schedule: schedule());
      expect(db.documents['drivers/municipal-driver-1']!['authUid'], 'd1');
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverUid'],
        'd1',
      );
    },
  );

  test('requested Driver role does not authorize a Resident account', () async {
    db.documents['users/d1']!['role'] = 'resident';
    db.documents['users/d1']!['requestedRole'] = 'driver';
    await expectLater(
      driverService.resolveVerifiedAuthUid(driverId: 'municipal-driver-1'),
      throwsA(
        isA<DriverServiceException>().having(
          (error) => error.code,
          'code',
          'account-not-approved',
        ),
      ),
    );
    expect(db.writes, isEmpty);
  });

  test(
    'existing unapproved link cannot switch to another approved account',
    () async {
      db.documents['drivers/municipal-driver-1']!['authUid'] = 'd1';
      db.documents['users/d1']!['role'] = 'resident';
      db.documents['users/d2']!['email'] = 'driver1@example.test';
      await expectLater(
        driverService.resolveVerifiedAuthUid(driverId: 'municipal-driver-1'),
        throwsA(
          isA<DriverServiceException>().having(
            (error) => error.code,
            'code',
            'account-not-approved',
          ),
        ),
      );
      expect(db.documents['drivers/municipal-driver-1']!['authUid'], 'd1');
      expect(db.writes, isEmpty);
    },
  );

  test('conflicting embedded UID and linked email are rejected', () async {
    db.documents['drivers/municipal-driver-1']!['authUid'] = 'd1';
    db.documents['users/d1']!['uid'] = 'd2';
    await expectLater(
      driverService.resolveVerifiedAuthUid(driverId: 'municipal-driver-1'),
      throwsA(
        isA<DriverServiceException>().having(
          (error) => error.code,
          'code',
          'account-identity-mismatch',
        ),
      ),
    );
    db.documents['users/d1']!['uid'] = 'd1';
    db.documents['users/d1']!['email'] = 'different@example.test';
    await expectLater(
      driverService.resolveVerifiedAuthUid(driverId: 'municipal-driver-1'),
      throwsA(
        isA<DriverServiceException>().having(
          (error) => error.code,
          'code',
          'account-email-mismatch',
        ),
      ),
    );
    expect(db.writes, isEmpty);
  });

  test(
    'duplicate approved profiles differing only in email case remain ambiguous',
    () async {
      db.documents['users/d2']!['email'] = ' DRIVER1@example.test ';
      await expectLater(
        driverService.resolveVerifiedAuthUid(driverId: 'municipal-driver-1'),
        throwsA(
          isA<DriverServiceException>().having(
            (error) => error.code,
            'code',
            'account-link-ambiguous',
          ),
        ),
      );
      expect(db.writes, isEmpty);
    },
  );

  test('municipal Driver ID maps to the unique verified Auth UID', () async {
    expect(
      await driverService.resolveVerifiedAuthUid(
        driverId: 'municipal-driver-1',
      ),
      'd1',
    );
    expect(db.documents['drivers/municipal-driver-1']!['authUid'], 'd1');
    expect('municipal-driver-1', isNot('d1'));
  });

  test(
    'Driver CRUD preserves a verified mapping only while email is stable',
    () async {
      await driverService.resolveVerifiedAuthUid(
        driverId: 'municipal-driver-1',
      );
      final current = Driver.fromMap(
        db.documents['drivers/municipal-driver-1']!,
      );
      Driver replacement({String email = 'driver1@example.test'}) => Driver(
        driverId: current.driverId,
        fullName: 'Updated Driver',
        email: email,
        phoneNumber: current.phoneNumber,
        licenseNumber: current.licenseNumber,
        status: current.status,
        createdAt: current.createdAt,
        updatedAt: DateTime(2026, 10, 10),
      );

      await driverService.updateDriver(
        driverId: current.driverId,
        driver: replacement(),
      );
      expect(db.documents['drivers/municipal-driver-1']!['authUid'], 'd1');
      await driverService.updateDriver(
        driverId: current.driverId,
        driver: replacement(email: 'changed@example.test'),
      );
      expect(
        db.documents['drivers/municipal-driver-1']!.containsKey('authUid'),
        isFalse,
      );
    },
  );

  test('role mismatch prevents mapping to a Resident Auth profile', () async {
    db.documents['users/d1']!['role'] = 'resident';
    await expectLater(
      driverService.resolveVerifiedAuthUid(driverId: 'municipal-driver-1'),
      throwsA(isA<DriverServiceException>()),
    );
    expect(
      db.documents['drivers/municipal-driver-1']!.containsKey('authUid'),
      isFalse,
    );
  });

  test('unmatched municipal email cannot map to another account', () async {
    db.documents['drivers/municipal-driver-1']!['email'] =
        'unlinked@example.test';
    await expectLater(
      driverService.resolveVerifiedAuthUid(driverId: 'municipal-driver-1'),
      throwsA(isA<DriverServiceException>()),
    );
    expect(
      db.documents['drivers/municipal-driver-1']!.containsKey('authUid'),
      isFalse,
    );
  });

  test(
    'unauthorized user cannot resolve and persist an assignment mapping',
    () async {
      final untrusted = DriverService(
        firestoreService: store,
        authenticatedUid: () => 'd1',
      );
      await expectLater(
        untrusted.resolveVerifiedAuthUid(driverId: 'municipal-driver-1'),
        throwsA(isA<DriverServiceException>()),
      );
      expect(
        db.documents['drivers/municipal-driver-1']!.containsKey('authUid'),
        isFalse,
      );
    },
  );

  test(
    'schedule assignment persists both IDs and creates linked trip',
    () async {
      await scheduleService.createSchedule(schedule: schedule());
      final saved = db.documents['schedules/schedule-integration']!;
      expect(saved['assignedDriverId'], 'municipal-driver-1');
      expect(saved['assignedDriverUid'], 'd1');
      expect(saved['assignedVehicleId'], 'ABC-001');
      expect(saved['trackingTripId'], 'schedules_schedule-integration');
      final trip = db.documents['driver_trips/schedules_schedule-integration']!;
      expect(trip['assignedDriverId'], 'municipal-driver-1');
      expect(trip['assignedDriverUid'], 'd1');
      expect(trip['assignedVehicleId'], 'ABC-001');
      final projection =
          db.documents['resident_schedules/schedule-integration']!;
      expect(projection['wasteType'], 'general');
      expect(projection['status'], 'scheduled');
      expect(projection['startTime'], '08:00');
      expect(projection['endTime'], '10:00');
      expect(projection['collectionDate'], isNotNull);
      expect(projection.keys, isNot(contains('assignedDriverUid')));
      expect(projection.keys, isNot(contains('assignedDriverId')));
      expect(projection.keys, isNot(contains('assignedVehicleId')));
      expect(projection.keys, isNot(contains('trackingTripId')));
    },
  );

  test(
    'saving the same assignment repeatedly reuses one deterministic trip',
    () async {
      await scheduleService.createSchedule(schedule: schedule());
      db.documents['driver_trips/schedules_schedule-integration']!
        ..['currentLatitude'] = 6.91
        ..['currentLongitude'] = 79.81;
      await scheduleService.updateSchedule(
        scheduleId: 'schedule-integration',
        schedule: schedule(),
      );
      expect(
        db.documents.keys.where(
          (path) => path.startsWith('driver_trips/schedules_'),
        ),
        ['driver_trips/schedules_schedule-integration'],
      );
      expect(
        db.documents['driver_trips/schedules_schedule-integration']!['currentLatitude'],
        6.91,
      );
      expect(
        db.documents['resident_schedules/schedule-integration']!['status'],
        'scheduled',
      );
    },
  );

  test(
    'reassignment replaces trip owner and cancellation revokes assignment',
    () async {
      await scheduleService.createSchedule(schedule: schedule());
      await scheduleService.updateSchedule(
        scheduleId: 'schedule-integration',
        schedule: schedule(
          driverId: 'municipal-driver-2',
          vehicleId: 'ABC-002',
        ),
      );
      expect(
        db.documents['driver_trips/schedules_schedule-integration']!['assignedDriverUid'],
        'd2',
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverUid'],
        'd2',
      );
      expect(
        db.documents['resident_schedules/schedule-integration']!['status'],
        'scheduled',
      );
      db.documents.remove('schedules/s1');
      db.documents.remove('driver_trips/special_pickups_r1');
      final previousDriverView = await TrackingService(
        firestore: db,
        authenticatedUid: () => 'd1',
      ).streamDriverTracking('d1').first;
      expect(
        previousDriverView.message,
        'No active collections or trips assigned to you.',
      );
      await scheduleService.updateSchedule(
        scheduleId: 'schedule-integration',
        schedule: schedule(status: 'cancelled'),
      );
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
      expect(
        db.documents['schedules/schedule-integration']!.containsKey(
          'assignedDriverUid',
        ),
        isFalse,
      );
      expect(
        db.documents['resident_schedules/schedule-integration']!['status'],
        'cancelled',
      );
    },
  );

  for (final assignment in <({String? driver, String? vehicle})>[
    (driver: 'municipal-driver-1', vehicle: 'ABC-001'),
    (driver: 'municipal-driver-1', vehicle: null),
    (driver: null, vehicle: 'ABC-001'),
    (driver: null, vehicle: null),
  ]) {
    test('create and update assignment $assignment', () async {
      final selected = schedule(
        driverId: assignment.driver,
        vehicleId: assignment.vehicle,
      );
      await scheduleService.createSchedule(schedule: selected);
      void verifyAssignment() {
        final saved = db.documents['schedules/schedule-integration']!;
        expect(saved['assignedDriverId'], assignment.driver);
        expect(saved['assignedVehicleId'], assignment.vehicle);
        final projection =
            db.documents['resident_schedules/schedule-integration']!;
        for (final key in [
          'collectionDate',
          'startTime',
          'endTime',
          'zone',
          'status',
        ]) {
          expect(projection[key], saved[key]);
        }
        expect(
          db.documents.containsKey(
            'driver_trips/schedules_schedule-integration',
          ),
          assignment.driver != null && assignment.vehicle != null,
        );
      }

      verifyAssignment();
      // Exercise removal of an existing trip, then reassignment on update.
      await scheduleService.updateSchedule(
        scheduleId: selected.scheduleId,
        schedule: schedule(driverId: null, vehicleId: null),
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedDriverId'],
        isNull,
      );
      expect(
        db.documents['schedules/schedule-integration']!['assignedVehicleId'],
        isNull,
      );
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
      await scheduleService.updateSchedule(
        scheduleId: selected.scheduleId,
        schedule: selected,
      );
      verifyAssignment();
    });

    test('permission denial preserves data for $assignment', () async {
      final selected = schedule(
        driverId: assignment.driver,
        vehicleId: assignment.vehicle,
      );
      final expectedStage =
          assignment.driver != null && assignment.vehicle != null
          ? 'saving schedules, resident_schedules, and driver_trips'
          : 'saving schedules and resident_schedules';
      final denied = isA<ScheduleSavePermissionException>()
          .having((error) => error.code, 'code', 'permission-denied')
          .having((error) => error.stage, 'stage', expectedStage)
          .having((error) => error.cause, 'cause', isA<FirebaseException>());
      db.batchFailureCode = 'permission-denied';
      db.failNextBatchCommit = true;
      await expectLater(
        scheduleService.createSchedule(schedule: selected),
        throwsA(denied),
      );
      expect(
        db.documents.containsKey('schedules/schedule-integration'),
        isFalse,
      );
      expect(
        db.documents.containsKey('resident_schedules/schedule-integration'),
        isFalse,
      );
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
      await scheduleService.createSchedule(schedule: selected);
      final saved = Map<String, dynamic>.from(
        db.documents['schedules/schedule-integration']!,
      );
      final projection = Map<String, dynamic>.from(
        db.documents['resident_schedules/schedule-integration']!,
      );
      db.failNextBatchCommit = true;
      await expectLater(
        scheduleService.updateSchedule(
          scheduleId: selected.scheduleId,
          schedule: selected,
        ),
        throwsA(denied),
      );
      expect(db.documents['schedules/schedule-integration'], saved);
      expect(
        db.documents['resident_schedules/schedule-integration'],
        projection,
      );
    });
  }

  test('failed assignment batch leaves schedule and trip unchanged', () async {
    db.failNextBatchCommit = true;
    await expectLater(
      scheduleService.createSchedule(schedule: schedule()),
      throwsA(
        isA<FirebaseServiceException>()
            .having((error) => error.code, 'code', 'unavailable')
            .having(
              (error) => error.message,
              'message',
              'Injected atomic batch failure.',
            ),
      ),
    );
    expect(db.documents.containsKey('schedules/schedule-integration'), isFalse);
    expect(
      db.documents.containsKey('resident_schedules/schedule-integration'),
      isFalse,
    );
    expect(
      db.documents.containsKey('driver_trips/schedules_schedule-integration'),
      isFalse,
    );
  });

  test(
    'failed reassignment batch retains the previous valid assignment',
    () async {
      await scheduleService.createSchedule(schedule: schedule());
      final oldSchedule = Map<String, dynamic>.of(
        db.documents['schedules/schedule-integration']!,
      );
      final oldTrip = Map<String, dynamic>.of(
        db.documents['driver_trips/schedules_schedule-integration']!,
      );
      final oldProjection = Map<String, dynamic>.of(
        db.documents['resident_schedules/schedule-integration']!,
      );
      db.failNextBatchCommit = true;

      await expectLater(
        scheduleService.updateSchedule(
          scheduleId: 'schedule-integration',
          schedule: schedule(
            driverId: 'municipal-driver-2',
            vehicleId: 'ABC-002',
          ),
        ),
        throwsA(isA<Exception>()),
      );

      expect(db.documents['schedules/schedule-integration'], oldSchedule);
      expect(
        db.documents['driver_trips/schedules_schedule-integration'],
        oldTrip,
      );
      expect(
        db.documents['resident_schedules/schedule-integration'],
        oldProjection,
      );
    },
  );

  test(
    'failed unassignment batch retains the previous valid assignment',
    () async {
      await scheduleService.createSchedule(schedule: schedule());
      final oldSchedule = Map<String, dynamic>.of(
        db.documents['schedules/schedule-integration']!,
      );
      final oldTrip = Map<String, dynamic>.of(
        db.documents['driver_trips/schedules_schedule-integration']!,
      );
      final oldProjection = Map<String, dynamic>.of(
        db.documents['resident_schedules/schedule-integration']!,
      );
      db.failNextBatchCommit = true;

      await expectLater(
        scheduleService.updateSchedule(
          scheduleId: 'schedule-integration',
          schedule: schedule(driverId: null, vehicleId: null),
        ),
        throwsA(isA<Exception>()),
      );

      expect(db.documents['schedules/schedule-integration'], oldSchedule);
      expect(
        db.documents['driver_trips/schedules_schedule-integration'],
        oldTrip,
      );
      expect(
        db.documents['resident_schedules/schedule-integration'],
        oldProjection,
      );
    },
  );

  test('missing vehicle blocks assignment before schedule write', () async {
    await expectLater(
      scheduleService.createSchedule(
        schedule: schedule(vehicleId: 'missing-vehicle'),
      ),
      throwsA(isA<ScheduleServiceException>()),
    );
    expect(db.documents.containsKey('schedules/schedule-integration'), isFalse);
  });

  test(
    'unassigned schedules still publish a safe Resident projection',
    () async {
      await scheduleService.createSchedule(
        schedule: schedule(driverId: null, vehicleId: null),
      );
      final projection =
          db.documents['resident_schedules/schedule-integration']!;
      expect(projection['wasteType'], 'general');
      expect(projection['acceptedItems'], isEmpty);
      expect(projection['instructions'], isEmpty);
      expect(projection.keys, isNot(contains('assignedDriverUid')));
      expect(
        db.documents.containsKey('driver_trips/schedules_schedule-integration'),
        isFalse,
      );
    },
  );

  test('status edits update the Resident projection', () async {
    await scheduleService.createSchedule(
      schedule: schedule(driverId: null, vehicleId: null),
    );
    await scheduleService.updateSchedule(
      scheduleId: 'schedule-integration',
      schedule: schedule(driverId: null, vehicleId: null, status: 'completed'),
    );
    expect(
      db.documents['resident_schedules/schedule-integration']!['status'],
      'completed',
    );
    expect(
      db.documents['schedules/schedule-integration']!['status'],
      'completed',
    );
  });

  test(
    'existing vehicle linkage is preserved without a client-side pairing block',
    () async {
      db.documents['vehicles/ABC-001']!['assignedDriverId'] =
          'municipal-driver-2';
      await scheduleService.createSchedule(schedule: schedule());
      expect(
        db.documents['schedules/schedule-integration']!['assignedVehicleId'],
        'ABC-001',
      );
      expect(
        db.documents['vehicles/ABC-001']!['assignedDriverId'],
        'municipal-driver-2',
      );
    },
  );

  test(
    'one-time projection publisher migrates only safe valid schedule fields',
    () async {
      db.documents['schedules/legacy-schedule'] = {
        'scheduleId': 'legacy-schedule',
        'collectionDate': Timestamp.fromDate(DateTime(2026, 10, 10)),
        'startTime': '08:00',
        'endTime': '10:00',
        'zone': 'North',
        'wasteType': 'general',
        'status': 'scheduled',
        'assignedDriverId': 'municipal-driver-1',
        'assignedDriverUid': 'd1',
        'assignedVehicleId': 'ABC-001',
        'trackingTripId': 'schedules_legacy-schedule',
      };

      final result = await trackingService
          .publishExistingResidentScheduleProjections();

      expect(result.publishedCount, 1);
      expect(result.skippedCount, 2); // Existing incomplete fixture records.
      final projection = db.documents['resident_schedules/legacy-schedule']!;
      expect(projection, {
        'collectionDate': Timestamp.fromDate(DateTime(2026, 10, 10)),
        'startTime': '08:00',
        'endTime': '10:00',
        'zone': 'North',
        'wasteType': 'general',
        'status': 'scheduled',
        'acceptedItems': <String>[],
        'instructions': '',
      });
      expect(projection.keys, isNot(contains('assignedDriverUid')));
      expect(projection.keys, isNot(contains('assignedDriverId')));
      expect(projection.keys, isNot(contains('assignedVehicleId')));
      expect(projection.keys, isNot(contains('trackingTripId')));
      expect(
        db.documents['schedules/legacy-schedule']!['trackingTripId'],
        'schedules_legacy-schedule',
      );
    },
  );

  test(
    'projection publisher is officer-only and skips malformed schedules',
    () async {
      db.documents['schedules/invalid-schedule'] = {
        'collectionDate': 'not-a-date',
        'startTime': '08:00',
        'endTime': '10:00',
        'wasteType': 'general',
        'status': 'scheduled',
      };
      final result = await trackingService
          .publishExistingResidentScheduleProjections();
      expect(result.publishedCount, 0);
      expect(result.skippedCount, 3);
      expect(
        db.documents.containsKey('resident_schedules/invalid-schedule'),
        isFalse,
      );

      await expectLater(
        TrackingService(
          firestore: db,
          authenticatedUid: () => 'd1',
        ).publishExistingResidentScheduleProjections(),
        throwsA(isA<StateError>()),
      );
      expect(
        db.writes.where((path) => path.startsWith('resident_schedules/')),
        isEmpty,
      );
    },
  );
}
