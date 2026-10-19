import 'package:cleancycle_mobileapp/services/firebase/firestore_service.dart';
import 'package:cleancycle_mobileapp/services/firebase/firebase_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/driver_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/tracking_firestore.dart';

void main() {
  late TrackingFirestoreFixture db;
  late String? uid;
  late DriverService service;
  setUp(() {
    db = TrackingFirestoreFixture();
    db.documents['drivers/municipal-driver-1']!['authUid'] = 'd1';
    uid = 'd1';
    service = DriverService(
      firestoreService: FirestoreService(firestoreInstance: db),
      authenticatedUid: () => uid,
    );
  });
  tearDown(() => db.dispose());

  test('lookup constrains UID and only trusted email variants', () async {
    db.documents['users/d1']!['email'] = ' Driver1@Example.Test ';
    final result = await service.getDriverForAuthUid(authUid: 'd1');
    expect(result?.driverId, 'municipal-driver-1');
    final reads = db.queryReads.where((read) => read.collection == 'drivers');
    expect(reads, hasLength(1));
    expect(reads.single.filters['authUid'], 'd1');
    expect(
      reads.single.filters['email'],
      unorderedEquals([
        'driver1@example.test',
        'Driver1@Example.Test',
        ' Driver1@Example.Test ',
      ]),
    );
    expect(db.writes, isEmpty);
  });
  test(
    'preserves a matching legacy raw email without unrestricted fallback',
    () async {
      db.documents['users/d1']!['email'] = ' Driver1@Example.Test ';
      db.documents['drivers/municipal-driver-1']!['email'] =
          ' Driver1@Example.Test ';
      expect((await service.getDriverForAuthUid(authUid: 'd1'))?.authUid, 'd1');
    },
  );
  test(
    'missing link returns no assignment and never scans other drivers',
    () async {
      db.documents.remove('drivers/municipal-driver-1');
      expect(await service.getDriverForAuthUid(authUid: 'd1'), isNull);
      expect(
        db.queryReads.single.filters.keys,
        unorderedEquals(['authUid', 'email']),
      );
    },
  );
  test(
    'unqueryable legacy spelling fails closed without an unrestricted scan',
    () async {
      db.documents['drivers/municipal-driver-1']!['email'] =
          'DRIVER1@EXAMPLE.TEST';
      expect(await service.getDriverForAuthUid(authUid: 'd1'), isNull);
      expect(db.queryReads, hasLength(1));
      expect(
        db.queryReads.single.filters.keys,
        unorderedEquals(['authUid', 'email']),
      );
    },
  );
  test(
    'missing email, role revocation and inconsistent profile UID are rejected',
    () async {
      final original = Map<String, dynamic>.of(db.documents['users/d1']!);
      for (final changes in [
        {'email': ''},
        {'role': 'resident'},
        {'uid': 'someone-else'},
      ]) {
        db.documents['users/d1'] = {...original, ...changes};
        await expectLater(
          service.getDriverForAuthUid(authUid: 'd1'),
          throwsA(isA<DriverServiceException>()),
        );
      }
      expect(db.queryReads, isEmpty);
    },
  );
  test(
    'other account and signed-out lookup are rejected before querying',
    () async {
      await expectLater(
        service.getDriverForAuthUid(authUid: 'd2'),
        throwsA(isA<DriverServiceException>()),
      );
      uid = null;
      await expectLater(
        service.getDriverForAuthUid(authUid: 'd1'),
        throwsA(isA<DriverServiceException>()),
      );
      expect(db.queryReads, isEmpty);
    },
  );
  test('duplicate linked records are rejected', () async {
    db.documents['drivers/duplicate'] = {
      ...db.documents['drivers/municipal-driver-1']!,
      'driverId': 'duplicate',
    };
    await expectLater(
      service.getDriverForAuthUid(authUid: 'd1'),
      throwsA(isA<DriverServiceException>()),
    );
  });
  test('record with conflicting canonical document ID is rejected', () async {
    db.documents['drivers/municipal-driver-1']!['driverId'] = 'forged';
    await expectLater(
      service.getDriverForAuthUid(authUid: 'd1'),
      throwsA(isA<DriverServiceException>()),
    );
  });
  test('genuine permission errors propagate', () async {
    db.denied.add('drivers');
    await expectLater(
      service.getDriverForAuthUid(authUid: 'd1'),
      throwsA(isA<FirebaseServiceException>()),
    );
  });
  test('account change during lookup is rejected', () async {
    var reads = 0;
    service = DriverService(
      firestoreService: FirestoreService(firestoreInstance: db),
      authenticatedUid: () => reads++ == 0 ? 'd1' : 'd2',
    );
    await expectLater(
      service.getDriverForAuthUid(authUid: 'd1'),
      throwsA(isA<DriverServiceException>()),
    );
  });
}
