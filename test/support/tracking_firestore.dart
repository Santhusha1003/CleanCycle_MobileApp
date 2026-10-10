import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingFirestoreFixture implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{
    'users/one': {'role': 'resident', 'addressZone': 'Zone One'},
    'users/two': {'role': 'resident', 'addressZone': 'Zone Two'},
    'users/d1': {
      'uid': 'd1',
      'email': 'driver1@example.test',
      'role': 'driver',
      'name': 'Driver One',
      'phone': '111',
    },
    'users/d2': {
      'uid': 'd2',
      'email': 'driver2@example.test',
      'role': 'driver',
      'name': 'Driver Two',
    },
    'users/officer': {
      'uid': 'officer',
      'email': 'officer@example.test',
      'role': 'municipal_officer',
    },
    'drivers/municipal-driver-1': {
      'driverId': 'municipal-driver-1',
      'fullName': 'Driver One',
      'email': 'driver1@example.test',
      'phoneNumber': '111',
      'licenseNumber': 'DL-1',
      'status': 'available',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    },
    'drivers/municipal-driver-2': {
      'driverId': 'municipal-driver-2',
      'fullName': 'Driver Two',
      'email': 'driver2@example.test',
      'phoneNumber': '222',
      'licenseNumber': 'DL-2',
      'status': 'available',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    },
    'vehicles/ABC-001': {
      'registrationNumber': 'ABC-001',
      'vehicleType': 'truck',
      'capacityKg': 1000,
      'status': 'available',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    },
    'vehicles/ABC-002': {
      'registrationNumber': 'ABC-002',
      'vehicleType': 'truck',
      'capacityKg': 1200,
      'status': 'available',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    },
    'special_pickups/r1': {
      'requestId': 'r1',
      'userId': 'one',
      'trackingTripId': 'special_pickups_r1',
      'status': 'assigned',
      'assignedDriverUid': 'd1',
      'assignedVehicleId': 'v1',
    },
    'collectionRequests/r2': {
      'residentId': 'two',
      'trackingTripId': 'collectionRequests_r2',
      'status': 'in_progress',
      'assignedDriverUid': 'd2',
      'assignedVehicleId': 'v2',
    },
    'schedules/s1': {
      'assignedDriverUid': 'd1',
      'assignedVehicleId': 'v1',
      'status': 'scheduled',
    },
    'schedules/s2': {
      'assignedDriverUid': 'd2',
      'assignedVehicleId': 'v2',
      'status': 'scheduled',
    },
    'vehicles/v1': {'registrationNumber': 'ONE-001'},
    'vehicles/v2': {'registrationNumber': 'TWO-002'},
    'driver_trips/special_pickups_r1': {
      'requestCollection': 'special_pickups',
      'requestId': 'r1',
      'residentId': 'one',
      'assignedDriverUid': 'd1',
      'assignedVehicleId': 'v1',
      'driverName': 'Driver One',
      'vehicleNumber': 'ONE-001',
      'status': 'assigned',
      'currentLatitude': 6.9,
      'currentLongitude': 79.8,
    },
    'driver_trips/collectionRequests_r2': {
      'requestCollection': 'collectionRequests',
      'requestId': 'r2',
      'residentId': 'two',
      'assignedDriverUid': 'd2',
      'assignedVehicleId': 'v2',
      'driverName': 'Driver Two',
      'vehicleNumber': 'TWO-002',
      'status': 'in_progress',
      'currentLatitude': 7.2,
      'currentLongitude': 80.1,
    },
  };
  final changes = StreamController<void>.broadcast();
  void publish() => changes.add(null);
  Future<void> dispose() => changes.close();
  int sequence = 0;
  final writes = <String>[];
  final queries = <String>[];
  final reads = <String>[];
  final denied = <String>{};
  final errorCodes = <String, String>{};
  bool failNextBatchCommit = false;
  @override
  WriteBatch batch() => _Batch(this);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path);
  final TrackingFirestoreFixture db;
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _Doc(db, '$path/${id ?? 'generated-${++db.sequence}'}');
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      _Query(db, path, const {}).get(options);
  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    db.queries.add('$path:$field=$isEqualTo');
    return _Query(db, path, {field.toString(): whereIn ?? isEqualTo});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Query implements Query<Map<String, dynamic>> {
  _Query(this.db, this.path, this.filters);
  final TrackingFirestoreFixture db;
  final String path;
  final Map<String, Object?> filters;
  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) => _Query(db, path, {...filters, field.toString(): whereIn ?? isEqualTo});
  QuerySnapshot<Map<String, dynamic>> snapshot() {
    if (db.denied.contains(path)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: db.errorCodes[path] ?? 'permission-denied',
      );
    }
    return _QuerySnapshot(
      db.documents.entries
          .where(
            (row) =>
                row.key.startsWith('$path/') &&
                filters.entries.every((filter) {
                  final expected = filter.value;
                  return expected is Iterable
                      ? expected.contains(row.value[filter.key])
                      : row.value[filter.key] == expected;
                }),
          )
          .map((row) => _QueryDoc(row.key.split('/').last, Map.of(row.value)))
          .toList(),
    );
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => snapshot();
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.multi((controller) {
    void emit() {
      try {
        controller.addSync(snapshot());
      } catch (error) {
        controller.addErrorSync(error);
      }
    }

    emit();
    final subscription = db.changes.stream.listen((_) => emit());
    controller.onCancel = subscription.cancel;
  });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Doc implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.db, this.path);
  final TrackingFirestoreFixture db;
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    db.reads.add(path);
    if (db.denied.contains(path)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: db.errorCodes[path] ?? 'permission-denied',
      );
    }
    return _Snapshot(
      id,
      db.documents[path] == null ? null : Map.of(db.documents[path]!),
    );
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.multi((controller) {
    void emit() {
      db.reads.add(path);
      if (db.denied.contains(path)) {
        controller.addErrorSync(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: db.errorCodes[path] ?? 'permission-denied',
          ),
        );
      } else {
        controller.addSync(
          _Snapshot(
            id,
            db.documents[path] == null ? null : Map.of(db.documents[path]!),
          ),
        );
      }
    }

    emit();
    final subscription = db.changes.stream.listen((_) => emit());
    controller.onCancel = subscription.cancel;
  });
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (db.denied.contains(path)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    db.writes.add(path);
    final next = options?.merge == true
        ? Map<String, dynamic>.of(db.documents[path] ?? {})
        : <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value == FieldValue.delete()) {
        next.remove(entry.key);
      } else {
        next[entry.key] = entry.value;
      }
    }
    db.documents[path] = next;
    for (final key in ['createdAt', 'updatedAt']) {
      if (db.documents[path]?[key] is FieldValue) {
        db.documents[path]![key] = Timestamp.now();
      }
    }
    db.publish();
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final next = Map<String, dynamic>.of(db.documents[path]!);
    for (final entry in data.entries) {
      final key = entry.key as String;
      if (entry.value == FieldValue.delete()) {
        next.remove(key);
      } else {
        next[key] = entry.value;
      }
    }
    await set(next);
  }

  @override
  Future<void> delete() async {
    db.writes.add(path);
    db.documents.remove(path);
    db.publish();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic>? value;
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _QueryDoc extends _Snapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDoc(super.id, super.value);
  @override
  Map<String, dynamic> data() => value!;
}

// ignore: subtype_of_sealed_class
class _QuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Batch implements WriteBatch {
  _Batch(this.db);
  final TrackingFirestoreFixture db;
  final operations = <Future<void> Function()>[];
  @override
  void set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    operations.add(() => ref.set(data, options));
  }

  @override
  void update<T>(DocumentReference<T> ref, T data) {
    operations.add(() => ref.update(data as dynamic));
  }

  @override
  void delete(DocumentReference ref) {
    operations.add(() => ref.delete());
  }

  @override
  Future<void> commit() async {
    if (db.failNextBatchCommit) {
      db.failNextBatchCommit = false;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Injected atomic batch failure.',
      );
    }
    for (final operation in operations) {
      await operation();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
