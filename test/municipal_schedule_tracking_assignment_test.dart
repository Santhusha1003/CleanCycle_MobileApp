import 'package:cleancycle_mobileapp/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/models/driver.dart';
import 'package:cleancycle_mobileapp/services/firebase/firestore_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/driver_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/schedule_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/vehicle_service.dart';
import 'package:cleancycle_mobileapp/vishani/services/tracking_service.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('failed assignment batch leaves schedule and trip unchanged', () async {
    db.failNextBatchCommit = true;
    await expectLater(
      scheduleService.createSchedule(schedule: schedule()),
      throwsA(isA<Exception>()),
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

  test('vehicle linked to a different Driver is rejected', () async {
    db.documents['vehicles/ABC-001']!['assignedDriverId'] =
        'municipal-driver-2';
    await expectLater(
      scheduleService.createSchedule(schedule: schedule()),
      throwsA(isA<ScheduleServiceException>()),
    );
    expect(db.documents.containsKey('schedules/schedule-integration'), isFalse);
  });
}
