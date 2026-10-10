import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_roles.dart';
import '../models/driver_tracking_model.dart';

class ResidentScheduleProjectionSyncResult {
  const ResidentScheduleProjectionSyncResult({
    required this.publishedCount,
    required this.skippedCount,
  });

  final int publishedCount;
  final int skippedCount;
}

class TrackingService {
  TrackingService({
    FirebaseFirestore? firestore,
    String? Function()? authenticatedUid,
  }) : _firestore = firestore,
       _authenticatedUid =
           authenticatedUid ?? (() => FirebaseAuth.instance.currentUser?.uid);
  final FirebaseFirestore? _firestore;
  final String? Function() _authenticatedUid;
  FirebaseFirestore get _instance => _firestore ?? FirebaseFirestore.instance;

  /// Explicitly publishes safe Resident projections for schedules created
  /// before projection writes were added. This is never run automatically.
  Future<ResidentScheduleProjectionSyncResult>
  publishExistingResidentScheduleProjections() async {
    final operatorUid = _authenticatedUid();
    if (operatorUid == null) throw StateError('Sign in first.');
    final operator = await _instance.collection('users').doc(operatorUid).get();
    if (!['municipal_officer', 'officer'].contains(operator.data()?['role'])) {
      throw StateError(
        'Only an approved Municipal Officer can publish schedules.',
      );
    }

    final schedules = await _instance.collection('schedules').get();
    final publishable = <({String id, Map<String, dynamic> data})>[];
    var skippedCount = 0;
    for (final schedule in schedules.docs) {
      final projection = _safeResidentProjection(schedule.data());
      if (projection == null) {
        skippedCount++;
        continue;
      }
      publishable.add((id: schedule.id, data: projection));
    }

    var publishedCount = 0;
    for (var offset = 0; offset < publishable.length; offset += 450) {
      final end = (offset + 450).clamp(0, publishable.length);
      final batch = _instance.batch();
      for (final schedule in publishable.sublist(offset, end)) {
        batch.set(
          _instance.collection('resident_schedules').doc(schedule.id),
          schedule.data,
        );
      }
      await batch.commit();
      publishedCount += end - offset;
    }
    return ResidentScheduleProjectionSyncResult(
      publishedCount: publishedCount,
      skippedCount: skippedCount,
    );
  }

  Map<String, dynamic>? _safeResidentProjection(Map<String, dynamic> schedule) {
    final date = schedule['collectionDate'];
    if (!(date is Timestamp || date is DateTime || date is String) ||
        (date is String && DateTime.tryParse(date) == null)) {
      return null;
    }
    for (final field in ['startTime', 'endTime', 'wasteType', 'status']) {
      if (schedule[field] is! String) return null;
    }
    final zone = schedule['zone'];
    if (schedule.containsKey('zone') && zone != null && zone is! String) {
      return null;
    }
    final acceptedItems = schedule['acceptedItems'];
    if (acceptedItems != null &&
        (acceptedItems is! List ||
            acceptedItems.any((item) => item is! String))) {
      return null;
    }
    final instructions = schedule['instructions'];
    if (instructions != null && instructions is! String) return null;

    return {
      'collectionDate': date,
      'startTime': schedule['startTime'],
      'endTime': schedule['endTime'],
      if (schedule.containsKey('zone')) 'zone': zone,
      'wasteType': schedule['wasteType'],
      'status': schedule['status'],
      'acceptedItems': schedule.containsKey('acceptedItems')
          ? acceptedItems
          : <String>[],
      'instructions': schedule.containsKey('instructions') ? instructions : '',
    };
  }

  Stream<ResidentTrackingData> streamResidentTracking(String uid) =>
      _stream(uid, AppRoles.resident);
  Stream<ResidentTrackingData> streamDriverTracking(String uid) =>
      _stream(uid, AppRoles.driver);

  /// Auth UID and assignedDriverUid are identities. Municipal assignedDriverId
  /// remains a record ID and is never used as a substitute for an Auth UID.
  Stream<ResidentTrackingData> _stream(String uid, String role) {
    if (uid.isEmpty || _authenticatedUid() != uid) {
      return Stream.error(
        StateError('Sign in to view your collection tracking.'),
      );
    }
    final driverView = role == AppRoles.driver;
    final sources = driverView
        ? {
            'schedules': 'assignedDriverUid',
            'driver_trips': 'assignedDriverUid',
          }
        : {'special_pickups': 'userId', 'collectionRequests': 'residentId'};
    late StreamController<ResidentTrackingData> output;
    final roots = <StreamSubscription<dynamic>>[];
    StreamSubscription<dynamic>? tripSubscription;
    final rows = <String, List<Map<String, dynamic>>>{};
    final failures = <String, TrackingReadFailure>{};
    Map<String, dynamic>? profile;
    bool closed = false;
    int generation = 0;
    bool current(int version) =>
        !closed && generation == version && _authenticatedUid() == uid;

    Future<void> rebuild() async {
      final version = ++generation;
      final previous = tripSubscription;
      tripSubscription = null;
      await previous?.cancel();
      if (!current(version) ||
          profile == null ||
          rows.length + failures.length < sources.length) {
        return;
      }
      if (profile!['role'] != role) {
        output.addError(
          StateError(
            'The account role changed. Reopen tracking from your home screen.',
          ),
        );
        return;
      }
      final address = DriverTrackingModel.text(profile!['addressZone']);
      void emit(
        String message, {
        Map<String, dynamic>? request,
        Map<String, dynamic>? trip,
        TrackingReadFailure? failure,
      }) {
        if (!current(version)) return;
        final location = trip == null
            ? null
            : DriverTrackingModel.fromMap(trip);
        output.add(
          ResidentTrackingData(
            uid: uid,
            addressZone: address,
            requestId:
                request?['_id'] as String? ?? trip?['requestId'] as String?,
            status: DriverTrackingModel.text(
              trip?['status'] ?? request?['status'],
            ),
            driver: location,
            driverName: DriverTrackingModel.text(trip?['driverName']),
            driverPhone: DriverTrackingModel.text(trip?['driverPhone']),
            driverAvatarUrl: DriverTrackingModel.text(trip?['driverAvatarUrl']),
            vehicleRegistration: DriverTrackingModel.text(
              trip?['vehicleNumber'],
            ),
            message: message,
            failures: List.unmodifiable([...failures.values, ?failure]),
          ),
        );
      }

      if (driverView) {
        final trips = (rows['driver_trips'] ?? []).where(
          (trip) => trip['assignedDriverUid'] == uid,
        );
        final trip = selectActive(trips);
        if (trip != null) {
          final source = DriverTrackingModel.text(trip['requestCollection']);
          final id = DriverTrackingModel.text(trip['requestId']);
          if (![
                'schedules',
                'special_pickups',
                'collectionRequests',
              ].contains(source) ||
              id.isEmpty ||
              id.contains('/')) {
            emit('Assigned trip has an invalid collection relationship.');
            return;
          }
          emit('Checking your assigned collection…');
          tripSubscription = _instance
              .collection(source)
              .doc(id)
              .snapshots()
              .listen(
                (doc) {
                  final assignment = doc.data();
                  if (assignment?['assignedDriverUid'] != uid ||
                      assignment?['assignedVehicleId'] !=
                          trip['assignedVehicleId']) {
                    emit('Collection assignment is no longer available.');
                  } else {
                    emit(_locationMessage(trip), trip: trip);
                  }
                },
                onError: (Object error) {
                  emit(
                    'Assigned collection could not be loaded.',
                    failure: _failure('$source/$id', error),
                  );
                },
              );
          return;
        }
        final schedule = selectActive(
          (rows['schedules'] ?? []).where(
            (row) => row['assignedDriverUid'] == uid,
          ),
        );
        emit(
          schedule != null
              ? 'Collection assigned. A tracking trip has not been started yet.'
              : failures.isEmpty
              ? 'No active collections or trips assigned to you.'
              : 'Assigned work could not be loaded.',
          request: schedule,
        );
        return;
      }
      final request = selectActiveRequest(
        uid,
        rows.values.expand((value) => value),
      );
      if (request == null) {
        emit(
          failures.isEmpty
              ? 'No active collection request.'
              : 'Your requests could not be loaded.',
        );
        return;
      }
      final assignedUid = DriverTrackingModel.text(
        request['assignedDriverUid'],
      );
      if (assignedUid.isEmpty) {
        emit(
          'Your collection request is awaiting a verified driver assignment.',
          request: request,
        );
        return;
      }
      emit('Driver assigned. Tracking is not available yet.', request: request);
      final source = request['_source'] as String;
      final id = request['_id'] as String;
      final tripId = tripIdFor(source, id);
      final publishedTripId = DriverTrackingModel.text(
        request['trackingTripId'],
      );
      // Do not GET an unpublished document: its absence cannot be authorized
      // by resource-based ownership rules. Officers publish the link atomically.
      if (publishedTripId.isEmpty) return;
      if (publishedTripId != tripId) {
        emit(
          'The collection tracking relationship is invalid.',
          request: request,
        );
        return;
      }
      tripSubscription = _instance
          .collection('driver_trips')
          .doc(tripId)
          .snapshots()
          .listen(
            (doc) {
              if (!current(version)) return;
              final trip = doc.data();
              final valid =
                  trip != null &&
                  matchesResidentTrip(trip, uid, source, id, assignedUid);
              emit(
                !valid
                    ? 'Driver assigned. Tracking is not available yet.'
                    : _locationMessage(trip),
                request: request,
                trip: valid ? trip : null,
              );
            },
            onError: (Object error) {
              emit(
                'Assigned tracking data could not be loaded.',
                request: request,
                failure: _failure('driver_trips/$tripId', error),
              );
            },
          );
    }

    output = StreamController<ResidentTrackingData>(
      onListen: () {
        roots.add(
          _instance
              .collection('users')
              .doc(uid)
              .snapshots()
              .listen(
                (doc) {
                  profile = doc.data();
                  if (profile == null) {
                    generation++;
                    unawaited(tripSubscription?.cancel());
                    output.addError(
                      StateError('Your profile could not be loaded.'),
                    );
                  } else {
                    unawaited(rebuild());
                  }
                },
                onError: (Object error) {
                  profile = null;
                  generation++;
                  unawaited(tripSubscription?.cancel());
                  output.addError(_failure('users/$uid', error));
                },
              ),
        );
        for (final source in sources.entries) {
          roots.add(
            _instance
                .collection(source.key)
                .where(source.value, isEqualTo: uid)
                .snapshots()
                .listen(
                  (snapshot) {
                    failures.remove(source.key);
                    rows[source.key] = snapshot.docs
                        .map(
                          (doc) => {
                            ...doc.data(),
                            '_id': doc.id,
                            '_source': source.key,
                          },
                        )
                        .toList();
                    unawaited(rebuild());
                  },
                  onError: (Object error) {
                    rows.remove(source.key);
                    failures[source.key] = _failure(
                      '${source.key} where ${source.value} == $uid',
                      error,
                    );
                    unawaited(rebuild());
                  },
                ),
          );
        }
      },
      onCancel: () async {
        closed = true;
        generation++;
        for (final subscription in roots) {
          await subscription.cancel();
        }
        await tripSubscription?.cancel();
      },
    );
    return output.stream;
  }

  static String tripIdFor(String source, String id) => '${source}_$id';

  static Map<String, dynamic> residentScheduleProjection(
    Map<String, dynamic> schedule,
  ) => {
    'collectionDate': schedule['collectionDate'],
    'startTime': schedule['startTime'],
    'endTime': schedule['endTime'],
    if (schedule['zone'] is String) 'zone': schedule['zone'],
    'wasteType': schedule['wasteType'],
    'status': schedule['status'],
    'acceptedItems': schedule['acceptedItems'] is List
        ? (schedule['acceptedItems'] as List).whereType<String>().toList()
        : <String>[],
    'instructions': schedule['instructions'] is String
        ? schedule['instructions']
        : '',
  };

  Future<void> saveScheduleAndProjection(
    String scheduleId, {
    required Map<String, dynamic> scheduleData,
    Map<String, dynamic>? projectionData,
    bool mergeSchedule = true,
  }) async {
    if (scheduleId.isEmpty || scheduleId.contains('/')) {
      throw ArgumentError('Invalid schedule ID.');
    }
    final operatorUid = _authenticatedUid();
    if (operatorUid == null) throw StateError('Sign in first.');
    final operator = await _instance.collection('users').doc(operatorUid).get();
    if (!['municipal_officer', 'officer'].contains(operator.data()?['role'])) {
      throw StateError(
        'Only an approved Municipal Officer can save schedules.',
      );
    }
    if (DriverTrackingModel.text(
          scheduleData['assignedDriverUid'],
        ).isNotEmpty ||
        DriverTrackingModel.text(scheduleData['assignedDriverId']).isNotEmpty) {
      throw StateError(
        'Assigned schedules must be saved with their tracking trip.',
      );
    }
    final batch = _instance.batch();
    batch.set(
      _instance.collection('schedules').doc(scheduleId),
      scheduleData,
      SetOptions(merge: mergeSchedule),
    );
    batch.set(
      _instance.collection('resident_schedules').doc(scheduleId),
      residentScheduleProjection(projectionData ?? scheduleData),
    );
    await batch.commit();
  }

  Future<void> deleteScheduleAndProjection(String scheduleId) async {
    if (scheduleId.isEmpty || scheduleId.contains('/')) {
      throw ArgumentError('Invalid schedule ID.');
    }
    final operatorUid = _authenticatedUid();
    if (operatorUid == null) throw StateError('Sign in first.');
    final operator = await _instance.collection('users').doc(operatorUid).get();
    if (!['municipal_officer', 'officer'].contains(operator.data()?['role'])) {
      throw StateError(
        'Only an approved Municipal Officer can delete schedules.',
      );
    }
    final batch = _instance.batch();
    batch.delete(
      _instance
          .collection('driver_trips')
          .doc(tripIdFor('schedules', scheduleId)),
    );
    batch.delete(_instance.collection('resident_schedules').doc(scheduleId));
    batch.delete(_instance.collection('schedules').doc(scheduleId));
    await batch.commit();
  }

  static bool matchesResidentTrip(
    Map<String, dynamic> trip,
    String uid,
    String source,
    String id,
    String assignedUid,
  ) =>
      trip['residentId'] == uid &&
      trip['requestCollection'] == source &&
      trip['requestId'] == id &&
      trip['assignedDriverUid'] == assignedUid;

  static String _locationMessage(Map<String, dynamic> trip) =>
      DriverTrackingModel.fromMap(trip).hasLocation
      ? 'Assigned collection location. Arrival estimate is not available.'
      : 'Collection assigned. Live location is not available yet.';

  static TrackingReadFailure _failure(String source, Object error) {
    final failure = TrackingReadFailure.fromError(source, error);
    if (kDebugMode) {
      debugPrint(
        '[TRACKING DEBUG] Read failed: $source; code: ${failure.code}',
      );
    }
    return failure;
  }

  static Map<String, dynamic>? selectActiveRequest(
    String uid,
    Iterable<Map<String, dynamic>> records,
  ) => selectActive(
    records.where((row) => row['residentId'] == uid || row['userId'] == uid),
  );

  static Map<String, dynamic>? selectActive(
    Iterable<Map<String, dynamic>> records,
  ) {
    const priority = {
      'in_progress': 0,
      'assigned': 1,
      'approved': 2,
      'scheduled': 3,
      'pending': 4,
    };
    String status(Map<String, dynamic> row) => DriverTrackingModel.text(
      row['status'],
    ).toLowerCase().replaceAll(' ', '_');
    int created(Map<String, dynamic> row) {
      final value = row['createdAt'];
      return value is Timestamp
          ? value.millisecondsSinceEpoch
          : value is DateTime
          ? value.millisecondsSinceEpoch
          : 0;
    }

    final active = records
        .where((row) => priority.containsKey(status(row)))
        .toList();
    active.sort((a, b) {
      final rank = priority[status(a)]!.compareTo(priority[status(b)]!);
      return rank != 0 ? rank : created(b).compareTo(created(a));
    });
    return active.isEmpty ? null : active.first;
  }

  /// Existing Driver dashboard card: no dummy resident ID or next-day fallback.
  Future<Map<String, dynamic>> fetchNextCollection(String uid) async {
    if (uid.isEmpty || _authenticatedUid() != uid) {
      throw StateError('Sign in first.');
    }
    final snapshot = await _instance
        .collection('schedules')
        .where('assignedDriverUid', isEqualTo: uid)
        .get();
    final row = selectActive(
      snapshot.docs
          .map((doc) => doc.data())
          .where((row) => row['assignedDriverUid'] == uid),
    );
    if (row == null) return {};
    final date = row['collectionDate'];
    return {
      'date': date is Timestamp
          ? date.toDate()
          : date is DateTime
          ? date
          : date is String
          ? DateTime.tryParse(date)
          : null,
      'category': row['wasteType'],
      'timeWindow': '${row['startTime'] ?? ''} - ${row['endTime'] ?? ''}',
    };
  }

  /// A driver can publish coordinates only to an existing assigned trip.
  /// Rules separately validate role, source assignment, and mutable fields.
  Future<void> updateTripLocation(
    String uid,
    String tripId,
    double latitude,
    double longitude,
  ) async {
    if (_authenticatedUid() != uid ||
        uid.isEmpty ||
        tripId.isEmpty ||
        tripId.contains('/')) {
      throw StateError('Invalid trip identity.');
    }
    if (DriverTrackingModel.coordinate(latitude, 90) == null ||
        DriverTrackingModel.coordinate(longitude, 180) == null) {
      throw ArgumentError('Invalid coordinates.');
    }
    final ref = _instance.collection('driver_trips').doc(tripId);
    final snapshot = await ref.get();
    if (snapshot.data()?['assignedDriverUid'] != uid) {
      throw StateError('Trip is not assigned to this account.');
    }
    await ref.update({
      'currentLatitude': latitude,
      'currentLongitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Trusted Officer workflow: derive the display projection from real records.
  /// This never creates an assignment or approves a requested account role.
  Future<String> createAssignedTrip(
    String source,
    String id, {
    Map<String, dynamic>? sourceData,
    Map<String, dynamic>? projectionData,
    bool mergeSource = true,
  }) async {
    if (![
          'special_pickups',
          'collectionRequests',
          'schedules',
        ].contains(source) ||
        id.isEmpty ||
        id.contains('/')) {
      throw ArgumentError('Invalid assignment source.');
    }
    final operatorUid = _authenticatedUid();
    if (operatorUid == null) throw StateError('Sign in first.');
    final operator = await _instance.collection('users').doc(operatorUid).get();
    if (!['municipal_officer', 'officer'].contains(operator.data()?['role'])) {
      throw StateError('Only an approved Municipal Officer can start a trip.');
    }
    final sourceRef = _instance.collection(source).doc(id);
    final assignment = sourceData ?? (await sourceRef.get()).data();
    final driverUid = DriverTrackingModel.text(
      assignment?['assignedDriverUid'],
    );
    final vehicleId = DriverTrackingModel.text(
      assignment?['assignedVehicleId'],
    );
    if (driverUid.isEmpty || vehicleId.isEmpty) {
      throw StateError('Assign a verified driver UID and vehicle first.');
    }
    if (driverUid == operatorUid) {
      throw StateError('An Officer cannot assign their own account as Driver.');
    }
    final assignedDriverId = DriverTrackingModel.text(
      assignment?['assignedDriverId'],
    );
    if (source == 'schedules') {
      if (assignedDriverId.isEmpty) {
        throw StateError('The schedule has no municipal Driver record.');
      }
      final driverRecord =
          (await _instance.collection('drivers').doc(assignedDriverId).get())
              .data();
      if (driverRecord?['authUid'] != driverUid) {
        throw StateError('Driver record is not linked to this Auth account.');
      }
    }
    final driver = (await _instance.collection('users').doc(driverUid).get())
        .data();
    final vehicle =
        (await _instance.collection('vehicles').doc(vehicleId).get()).data();
    if (driver?['role'] != AppRoles.driver || vehicle == null) {
      throw StateError('Assignment records are invalid.');
    }
    final residentUid = source == 'schedules'
        ? ''
        : DriverTrackingModel.text(
            assignment?[source == 'special_pickups' ? 'userId' : 'residentId'],
          );
    if (source != 'schedules' && residentUid.isEmpty) {
      throw StateError('Request has no authenticated owner.');
    }
    if (_authenticatedUid() != operatorUid) {
      throw StateError('Account changed.');
    }
    final trip = _instance
        .collection('driver_trips')
        .doc(tripIdFor(source, id));
    final existingTrip = (await trip.get()).data();
    final retainLocation =
        existingTrip?['assignedDriverUid'] == driverUid &&
        existingTrip?['assignedVehicleId'] == vehicleId;
    final createdAt = retainLocation && existingTrip?['createdAt'] != null
        ? existingTrip!['createdAt']
        : FieldValue.serverTimestamp();
    final batch = _instance.batch();
    batch.set(trip, {
      'requestCollection': source,
      'requestId': id,
      'residentId': residentUid,
      'assignedDriverUid': driverUid,
      if (assignedDriverId.isNotEmpty) 'assignedDriverId': assignedDriverId,
      'assignedVehicleId': vehicleId,
      'driverId': assignedDriverId,
      'driverName': DriverTrackingModel.text(driver?['name']),
      'driverPhone': DriverTrackingModel.text(driver?['phone']),
      'driverAvatarUrl': DriverTrackingModel.text(driver?['avatarUrl']),
      'vehicleNumber': DriverTrackingModel.text(vehicle['registrationNumber']),
      'status': DriverTrackingModel.text(assignment?['status']),
      'createdAt': createdAt,
      if (retainLocation && existingTrip?['currentLatitude'] != null)
        'currentLatitude': existingTrip!['currentLatitude'],
      if (retainLocation && existingTrip?['currentLongitude'] != null)
        'currentLongitude': existingTrip!['currentLongitude'],
      if (retainLocation && existingTrip?['updatedAt'] != null)
        'updatedAt': existingTrip!['updatedAt'],
    }, SetOptions(merge: false));
    if (sourceData == null) {
      batch.update(sourceRef, {'trackingTripId': trip.id});
    } else {
      batch.set(sourceRef, {
        ...sourceData,
        'trackingTripId': trip.id,
      }, SetOptions(merge: mergeSource));
    }
    if (source == 'schedules') {
      batch.set(
        _instance.collection('resident_schedules').doc(id),
        residentScheduleProjection(projectionData ?? assignment!),
      );
    }
    await batch.commit();
    return trip.id;
  }

  /// Remove the deterministic schedule trip on cancellation/unassignment.
  /// Clearing the source assignment first causes validTrip to reject stale
  /// trip reads during any concurrent/retried operation.
  Future<void> clearScheduleTrip(
    String scheduleId, {
    Map<String, dynamic>? sourceData,
    Map<String, dynamic>? projectionData,
  }) async {
    if (scheduleId.isEmpty || scheduleId.contains('/')) {
      throw ArgumentError('Invalid schedule ID.');
    }
    final operatorUid = _authenticatedUid();
    if (operatorUid == null) throw StateError('Sign in first.');
    final operator = await _instance.collection('users').doc(operatorUid).get();
    if (!['municipal_officer', 'officer'].contains(operator.data()?['role'])) {
      throw StateError('Only an approved Municipal Officer can change trips.');
    }
    final trip = _instance
        .collection('driver_trips')
        .doc(tripIdFor('schedules', scheduleId));
    final schedule = _instance.collection('schedules').doc(scheduleId);
    final batch = _instance.batch();
    batch.delete(trip);
    if (sourceData == null) {
      batch.update(schedule, {
        'assignedDriverId': FieldValue.delete(),
        'assignedDriverUid': FieldValue.delete(),
        'trackingTripId': FieldValue.delete(),
      });
    } else {
      batch.set(schedule, {
        ...sourceData,
        'assignedDriverId': FieldValue.delete(),
        'assignedDriverUid': FieldValue.delete(),
        'trackingTripId': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
    if (sourceData != null) {
      batch.set(
        _instance.collection('resident_schedules').doc(scheduleId),
        residentScheduleProjection(projectionData ?? sourceData),
      );
    }
    await batch.commit();
  }
}
