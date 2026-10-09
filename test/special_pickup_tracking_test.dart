import 'package:cleancycle_mobileapp/vishani/models/special_pickup_model.dart';
import 'package:cleancycle_mobileapp/vishani/services/special_pickup_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/tracking_firestore.dart';

void main() {
  late TrackingFirestoreFixture db;
  setUp(() => db = TrackingFirestoreFixture());
  tearDown(() => db.dispose());
  SpecialPickupModel pickup({String uid = 'one', String? assigned}) =>
      SpecialPickupModel(
        requestId: '',
        userId: uid,
        wasteType: 'Recyclable',
        scheduledDate: DateTime(2026, 10, 10),
        timeSlot: '10:00',
        address: 'Saved address',
        notes: '',
        createdAt: DateTime(2026, 10, 9),
        assignedDriverUid: assigned,
      );
  SpecialPickupService service() =>
      SpecialPickupService(firestore: db, authenticatedUid: () => 'one');
  test(
    'new request stores actual owner and Pending without self-assignment',
    () async {
      final id = await service().createPickupRequest(pickup(), []);
      final row = db.documents['special_pickups/$id']!;
      expect(row['userId'], 'one');
      expect(row['requestId'], id);
      expect(row['status'], 'Pending');
      expect(row.containsKey('assignedDriverUid'), isFalse);
    },
  );
  test('cross-account creation and client assignment are rejected', () async {
    await expectLater(
      service().createPickupRequest(pickup(uid: 'two'), []),
      throwsStateError,
    );
    await expectLater(
      service().createPickupRequest(pickup(assigned: 'd1'), []),
      throwsStateError,
    );
    expect(db.writes, isEmpty);
  });
  test(
    'write permission failure propagates rather than returning a receipt',
    () async {
      db.denied.add('special_pickups/generated-1');
      await expectLater(
        service().createPickupRequest(pickup(), []),
        throwsA(isA<FirebaseException>()),
      );
      expect(db.documents.containsKey('special_pickups/generated-1'), isFalse);
    },
  );
  test(
    'new request retains real CRUD and authenticated stream ownership',
    () async {
      final id = await service().createPickupRequest(pickup(), []);
      await service().reschedulePickup(id, DateTime(2026, 10, 11), '11:00');
      await service().updatePickupNotes(id, 'Actual instructions');
      final row = await service().getPickupStream(id).first;
      expect(row!.userId, 'one');
      expect(row.notes, 'Actual instructions');
      expect(row.timeSlot, '11:00');
      await service().cancelPickup(id);
      expect(await service().getPickupStream(id).first, isNull);
    },
  );
  test('cross-account request query never runs', () async {
    await expectLater(
      service().getUserPickupsStream('two'),
      emitsError(isA<StateError>()),
    );
    expect(db.queries, isEmpty);
  });
}
