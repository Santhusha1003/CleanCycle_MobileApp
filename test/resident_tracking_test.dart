import 'package:cleancycle_mobileapp/vishani/models/driver_tracking_model.dart';
import 'package:cleancycle_mobileapp/vishani/services/tracking_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/tracking_firestore.dart';

void main() {
  late TrackingFirestoreFixture db;
  setUp(() => db = TrackingFirestoreFixture());
  tearDown(() => db.dispose());
  TrackingService service(String uid) =>
      TrackingService(firestore: db, authenticatedUid: () => uid);
  for (final uid in ['one', 'two']) {
    test('Resident $uid sees only its owned request and linked trip', () async {
      final data = await service(uid)
          .streamResidentTracking(uid)
          .firstWhere((data) => data.driver?.hasLocation == true);
      expect(data.uid, uid);
      expect(data.driverName, uid == 'one' ? 'Driver One' : 'Driver Two');
      expect(data.vehicleRegistration, uid == 'one' ? 'ONE-001' : 'TWO-002');
      expect(data.driver!.etaMinutes, isNull);
      expect(data.failures, isEmpty);
      expect(
        db.reads,
        contains(
          uid == 'one'
              ? 'driver_trips/special_pickups_r1'
              : 'driver_trips/collectionRequests_r2',
        ),
      );
      expect(
        db.queries.any((query) => query.startsWith('schedules:')),
        isFalse,
      );
      expect(
        db.reads.any(
          (path) => path.startsWith('users/') && path != 'users/$uid',
        ),
        isFalse,
      );
    });
  }
  for (final uid in ['d1', 'd2']) {
    test('Driver $uid queries only its assigned schedules/trips', () async {
      final data = await service(uid)
          .streamDriverTracking(uid)
          .firstWhere((data) => data.driver?.hasLocation == true);
      expect(data.driverName, uid == 'd1' ? 'Driver One' : 'Driver Two');
      expect(db.queries, [
        'schedules:assignedDriverUid=$uid',
        'driver_trips:assignedDriverUid=$uid',
      ]);
      expect(data.failures, isEmpty);
    });
  }
  test('cross-UID stream is rejected before any read', () async {
    await expectLater(
      service('one').streamResidentTracking('two'),
      emitsError(isA<StateError>()),
    );
    expect(db.queries, isEmpty);
  });
  test('missing assignment uses pending state without trip reads', () async {
    db.documents['special_pickups/r1']!.remove('assignedDriverUid');
    final data = await service('one').streamResidentTracking('one').first;
    expect(data.message, contains('awaiting a verified driver assignment'));
    expect(data.driver, isNull);
    expect(db.queries.any((q) => q.startsWith('driver_trips')), isFalse);
  });
  test(
    'assigned request without published trip link stays pending without a denied GET',
    () async {
      db.documents['special_pickups/r1']!.remove('trackingTripId');
      final data = await service('one').streamResidentTracking('one').first;
      expect(data.message, 'Driver assigned. Tracking is not available yet.');
      expect(data.failures, isEmpty);
      expect(db.reads, ['users/one']);
    },
  );
  test(
    'Driver empty collections do not fall back to Resident requests',
    () async {
      db.documents.remove('driver_trips/special_pickups_r1');
      db.documents.remove('schedules/s1');
      final data = await service('d1').streamDriverTracking('d1').first;
      expect(data.message, 'No active collections or trips assigned to you.');
      expect(data.driver, isNull);
    },
  );
  test(
    'Driver assigned schedule without trip shows honest pending state',
    () async {
      db.documents.remove('driver_trips/special_pickups_r1');
      final data = await service('d1').streamDriverTracking('d1').first;
      expect(data.requestId, 's1');
      expect(data.message, contains('has not been started'));
    },
  );
  test(
    'missing coordinates keep actual assignment but no map or ETA',
    () async {
      db.documents['driver_trips/special_pickups_r1']!.remove(
        'currentLatitude',
      );
      final data = await service('one')
          .streamResidentTracking('one')
          .firstWhere((data) => data.driverName.isNotEmpty);
      expect(data.driverName, 'Driver One');
      expect(data.driver!.hasLocation, isFalse);
      expect(data.driver!.etaMinutes, isNull);
      expect(data.message, contains('Live location is not available'));
    },
  );
  test('permission denied remains an explicit failure', () async {
    db.denied.add('driver_trips');
    final data = await service('d1').streamDriverTracking('d1').first;
    expect(data.failures.single.code, 'permission-denied');
    expect(data.driver, isNull);
  });
  test(
    'Resident permission denied does not look like an empty collection',
    () async {
      db.denied.addAll(['special_pickups', 'collectionRequests']);
      final data = await service('one').streamResidentTracking('one').first;
      expect(data.failures, hasLength(2));
      expect(data.message, contains('could not be loaded'));
    },
  );
  test('source/owner/assignment mismatch never selects a foreign trip', () {
    final trip = db.documents['driver_trips/collectionRequests_r2']!;
    expect(
      TrackingService.matchesResidentTrip(
        trip,
        'one',
        'special_pickups',
        'r1',
        'd1',
      ),
      isFalse,
    );
  });
  test('Driver cannot publish coordinates to another Driver trip', () async {
    await expectLater(
      service(
        'd1',
      ).updateTripLocation('d1', 'collectionRequests_r2', 6.9, 79.8),
      throwsStateError,
    );
    expect(db.writes, isEmpty);
  });
  test('assigned Driver can publish real validated coordinates', () async {
    await service(
      'd1',
    ).updateTripLocation('d1', 'special_pickups_r1', 6.91, 79.81);
    expect(
      db.documents['driver_trips/special_pickups_r1']!['currentLatitude'],
      6.91,
    );
    await expectLater(
      service('d1').updateTripLocation('d1', 'special_pickups_r1', 100, 79.81),
      throwsArgumentError,
    );
  });
  test('Officer trip projection uses actual driver/vehicle records', () async {
    final id = await service(
      'officer',
    ).createAssignedTrip('special_pickups', 'r1');
    final trip = db.documents['driver_trips/$id']!;
    expect(trip['residentId'], 'one');
    expect(trip['assignedDriverUid'], 'd1');
    expect(trip['driverName'], 'Driver One');
    expect(trip['vehicleNumber'], 'ONE-001');
    expect(trip['currentLatitude'], 6.9);
    expect(trip['currentLongitude'], 79.8);
    expect(db.documents['special_pickups/r1']!['trackingTripId'], id);
  });
  test('Resident cannot create an assigned trip or approve a role', () async {
    await expectLater(
      service('one').createAssignedTrip('special_pickups', 'r1'),
      throwsStateError,
    );
    expect(db.writes, isEmpty);
  });
  test('malformed coordinates never acquire defaults', () {
    expect(
      DriverTrackingModel.fromMap({
        'currentLatitude': 999,
        'etaMinutes': 25,
      }).hasLocation,
      isFalse,
    );
    expect(DriverTrackingModel.fromMap({}).etaMinutes, isNull);
  });
}
