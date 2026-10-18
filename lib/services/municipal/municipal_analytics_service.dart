import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_service.dart';
import '../firebase/firestore_service.dart';

class MunicipalAnalyticsSummary {
  const MunicipalAnalyticsSummary({
    required this.totalVehicles,
    required this.availableVehicles,
    required this.maintenanceVehicles,
    required this.totalDrivers,
    required this.availableDrivers,
    required this.assignedDrivers,
    required this.totalStaff,
    required this.activeStaff,
    required this.todayCollections,
    required this.completedToday,
    required this.scheduledToday,
    required this.inProgressToday,
    required this.cancelledToday,
    required this.collectionsByWasteType,
    required this.collectionsByZone,
    this.completedCollectionsByVehicleToday = const {},
    this.missedToday = 0,
    this.unknownToday = 0,
  });

  final int totalVehicles;
  final int availableVehicles;
  final int maintenanceVehicles;
  final int totalDrivers;
  final int availableDrivers;
  final int assignedDrivers;
  final int totalStaff;
  final int activeStaff;
  final int todayCollections;
  final int completedToday;
  final int scheduledToday;
  final int inProgressToday;
  final int cancelledToday;
  final int missedToday;
  final int unknownToday;
  final Map<String, int> collectionsByWasteType;
  final Map<String, int> collectionsByZone;
  // Completed schedules assigned to a vehicle, not independently recorded trips.
  final Map<String, int> completedCollectionsByVehicleToday;
}

class MunicipalAnalyticsService {
  MunicipalAnalyticsService({
    FirestoreService? firestoreService,
    DateTime Function()? now,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _now = now ?? DateTime.now;

  final DateTime Function() _now;

  final FirestoreService _firestoreService;

  static const String vehicleCollectionPath = 'vehicles';
  static const String driverCollectionPath = 'drivers';
  static const String staffCollectionPath = 'staff';
  static const String scheduleCollectionPath = 'schedules';

  static const List<String> supportedWasteTypes = [
    'general',
    'recyclable',
    'organic',
    'mixed',
    'other',
  ];

  Map<String, int> _emptyWasteTypeCounts() {
    return {for (final wasteType in supportedWasteTypes) wasteType: 0};
  }

  Future<MunicipalAnalyticsSummary> getMunicipalAnalyticsSummary() async {
    try {
      final results = await Future.wait([
        _firestoreService.getCollection(path: vehicleCollectionPath),
        _firestoreService.getCollection(path: driverCollectionPath),
        _firestoreService.getCollection(path: staffCollectionPath),
        _firestoreService.getCollectionWithIds(path: scheduleCollectionPath),
      ]);

      return _calculateSummary(results);
    } catch (exception, stackTrace) {
      if (kDebugMode) {
        debugPrint('MunicipalAnalyticsService: $exception\n$stackTrace');
      }
      if (exception is FirebaseServiceException) rethrow;
      if (exception is FirebaseException) {
        throw FirebaseServiceException.fromFirebaseException(exception);
      }
      throw FirebaseServiceException(
        code: 'municipal_analytics_error',
        message: 'Failed to calculate municipal analytics: $exception',
      );
    }
  }

  MunicipalAnalyticsSummary _calculateSummary(
    List<List<Map<String, dynamic>>> results,
  ) {
    // Analytics needs only status/date/grouping fields, not complete CRUD
    // models. Legacy records and pending audit timestamps remain countable.
    final vehicles = results[0];
    final drivers = results[1];
    final staffMembers = results[2];
    final schedules = _uniqueSchedules(results[3]);

    final totalVehicles = vehicles.length;
    final availableVehicles = vehicles
        .where(
          (vehicle) => _text(vehicle['status']).toLowerCase() == 'available',
        )
        .length;
    final maintenanceVehicles = vehicles
        .where(
          (vehicle) => _text(vehicle['status']).toLowerCase() == 'maintenance',
        )
        .length;

    final totalDrivers = drivers.length;
    final availableDrivers = drivers
        .where((driver) => _text(driver['status']).toLowerCase() == 'available')
        .length;
    final assignedDrivers = drivers
        .where((driver) => _text(driver['status']).toLowerCase() == 'assigned')
        .length;

    final totalStaff = staffMembers.length;
    final activeStaff = staffMembers
        .where((member) => _text(member['status']).toLowerCase() == 'active')
        .length;

    final today = _colomboDay(_now());

    final todaysSchedules = schedules
        .where((schedule) {
          final collectionDate = _collectionDate(schedule['collectionDate']);
          if (collectionDate == null) {
            if (kDebugMode) {
              debugPrint(
                'MunicipalAnalyticsService: excluding schedule with '
                'missing/invalid collectionDate from today statistics.',
              );
            }
            return false;
          }
          if (collectionDate != today) return false;
          return true;
        })
        .toList(growable: false);

    final todayCollections = todaysSchedules.length;
    final completedToday = todaysSchedules
        .where((schedule) => _status(schedule['status']) == 'completed')
        .length;
    final scheduledToday = todaysSchedules
        .where((schedule) => _status(schedule['status']) == 'scheduled')
        .length;
    final inProgressToday = todaysSchedules
        .where((schedule) => _status(schedule['status']) == 'in_progress')
        .length;
    final cancelledToday = todaysSchedules
        .where((schedule) => _status(schedule['status']) == 'cancelled')
        .length;

    final missedToday = todaysSchedules
        .where((schedule) => _status(schedule['status']) == 'missed')
        .length;
    final unknownToday =
        todayCollections -
        completedToday -
        scheduledToday -
        inProgressToday -
        cancelledToday -
        missedToday;

    final collectionsByWasteType = _emptyWasteTypeCounts();
    for (final schedule in todaysSchedules) {
      final normalizedWasteType = _text(schedule['wasteType']).toLowerCase();
      if (collectionsByWasteType.containsKey(normalizedWasteType)) {
        collectionsByWasteType[normalizedWasteType] =
            (collectionsByWasteType[normalizedWasteType] ?? 0) + 1;
      }
    }

    final collectionsByZone = <String, int>{};
    for (final schedule in todaysSchedules) {
      final zoneKey = _text(schedule['zone']);
      if (zoneKey.isEmpty) {
        continue;
      }
      collectionsByZone[zoneKey] = (collectionsByZone[zoneKey] ?? 0) + 1;
    }

    final completedCollectionsByVehicleToday = <String, int>{};
    for (final schedule in todaysSchedules) {
      if (_status(schedule['status']) != 'completed') continue;
      final vehicleId = _text(schedule['assignedVehicleId']);
      if (vehicleId.isEmpty) continue;
      completedCollectionsByVehicleToday.update(
        vehicleId,
        (collectionCount) => collectionCount + 1,
        ifAbsent: () => 1,
      );
    }

    return MunicipalAnalyticsSummary(
      totalVehicles: totalVehicles,
      availableVehicles: availableVehicles,
      maintenanceVehicles: maintenanceVehicles,
      totalDrivers: totalDrivers,
      availableDrivers: availableDrivers,
      assignedDrivers: assignedDrivers,
      totalStaff: totalStaff,
      activeStaff: activeStaff,
      todayCollections: todayCollections,
      completedToday: completedToday,
      scheduledToday: scheduledToday,
      inProgressToday: inProgressToday,
      cancelledToday: cancelledToday,
      missedToday: missedToday,
      unknownToday: unknownToday,
      collectionsByWasteType: collectionsByWasteType,
      collectionsByZone: collectionsByZone,
      completedCollectionsByVehicleToday: Map.unmodifiable(
        completedCollectionsByVehicleToday,
      ),
    );
  }

  // Match CollectionSchedule's identity: stored scheduleId, then document ID.
  // Prefer the actual schedules/{scheduleId} document written by ScheduleService.
  // Resolve duplicate copies before day filtering, so an obsolete copy cannot
  // make a rescheduled collection appear in today's total.
  List<Map<String, dynamic>> _uniqueSchedules(List<Map<String, dynamic>> rows) {
    final identified = <String, Map<String, dynamic>>{};
    final unidentified = <Map<String, dynamic>>[];
    for (final row in rows) {
      final documentId = _text(row['_documentId']);
      final storedId = _text(row['scheduleId']);
      final id = storedId.isEmpty ? documentId : storedId;
      if (id.isEmpty) {
        unidentified.add(row);
        continue;
      }
      final previous = identified[id];
      if (previous == null || _preferSchedule(row, previous, id)) {
        identified[id] = row;
      }
    }
    return [...identified.values, ...unidentified];
  }

  bool _preferSchedule(
    Map<String, dynamic> next,
    Map<String, dynamic> previous,
    String id,
  ) {
    final nextId = _text(next['_documentId']);
    final previousId = _text(previous['_documentId']);
    final nextCanonical = nextId == id;
    final previousCanonical = previousId == id;
    if (nextCanonical != previousCanonical) return nextCanonical;
    DateTime? updated(dynamic value) {
      if (value is Timestamp) return value.toDate().toUtc();
      if (value is DateTime) return value.toUtc();
      if (value is String) return DateTime.tryParse(value)?.toUtc();
      return null;
    }

    final nextUpdate = updated(next['updatedAt']);
    final previousUpdate = updated(previous['updatedAt']);
    if (nextUpdate != previousUpdate) {
      if (nextUpdate == null) return false;
      if (previousUpdate == null) return true;
      return nextUpdate.isAfter(previousUpdate);
    }
    return nextId.compareTo(previousId) < 0;
  }

  String _text(dynamic value) => value is String ? value.trim() : '';

  // Asia/Colombo is UTC+05:30 for current collection operations.
  // UTC arithmetic makes this independent of the phone's configured timezone.
  static DateTime _colomboDay(DateTime instant) {
    final local = instant.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateTime.utc(local.year, local.month, local.day);
  }

  String _status(dynamic value) {
    final status = _text(
      value,
    ).toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
    return status == 'upcoming' ? 'scheduled' : status;
  }

  DateTime? _collectionDate(dynamic value) {
    if (value is Timestamp) return _colomboDay(value.toDate());
    if (value is DateTime) return _colomboDay(value);
    if (value is! String) return null;
    final text = value.trim();
    // Date-only and legacy timezone-less ISO values represent calendar dates,
    // not instants in the device's timezone. Reject overflow dates.
    final date = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|T| )').firstMatch(text);
    final display = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (date == null && display == null) return null;
    final year = int.parse(date?.group(1) ?? display!.group(3)!);
    final month = int.parse(date?.group(2) ?? display!.group(2)!);
    final day = int.parse(date?.group(3) ?? display!.group(1)!);
    final calendar = DateTime.utc(year, month, day);
    if (calendar.year != year ||
        calendar.month != month ||
        calendar.day != day) {
      return null;
    }
    if (display != null || text.length == 10) return calendar;
    final time = RegExp(r'[T ](\d{2}):?(\d{2})(?::?(\d{2}))?').firstMatch(text);
    if (time == null ||
        int.parse(time.group(1)!) > 23 ||
        int.parse(time.group(2)!) > 59 ||
        int.parse(time.group(3) ?? '0') > 59) {
      return null;
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return parsed.isUtc ? _colomboDay(parsed) : calendar;
  }

  Stream<MunicipalAnalyticsSummary> watchMunicipalAnalyticsSummary() {
    late StreamController<MunicipalAnalyticsSummary> controller;
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    final rows = List<List<Map<String, dynamic>>?>.filled(4, null);
    Timer? midnight;
    void emit() {
      if (rows.any((row) => row == null) || controller.isClosed) return;
      controller.add(
        _calculateSummary(rows.cast<List<Map<String, dynamic>>>()),
      );
    }

    void scheduleMidnight() {
      final now = _now().toUtc();
      final next = _colomboDay(now)
          .add(const Duration(days: 1))
          .subtract(const Duration(hours: 5, minutes: 30));
      midnight = Timer(next.difference(now), () {
        emit();
        scheduleMidnight();
      });
    }

    controller = StreamController<MunicipalAnalyticsSummary>(
      onListen: () {
        const paths = [
          vehicleCollectionPath,
          driverCollectionPath,
          staffCollectionPath,
          scheduleCollectionPath,
        ];
        for (var i = 0; i < paths.length; i++) {
          final index = i;
          subscriptions.add(
            _firestoreService.firestore
                .collection(paths[i])
                .snapshots()
                .listen(
                  (snapshot) {
                    rows[index] = snapshot.docs
                        .map((doc) => {...doc.data(), '_documentId': doc.id})
                        .toList();
                    emit();
                  },
                  onError: (Object error, StackTrace stack) {
                    rows[index] = null;
                    controller.addError(
                      error is FirebaseException
                          ? FirebaseServiceException.fromFirebaseException(
                              error,
                            )
                          : error,
                      stack,
                    );
                  },
                ),
          );
        }
        scheduleMidnight();
      },
      onCancel: () async {
        midnight?.cancel();
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Future<int> getTotalVehicles() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.totalVehicles;
  }

  Future<int> getAvailableVehicles() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.availableVehicles;
  }

  Future<int> getMaintenanceVehicles() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.maintenanceVehicles;
  }

  Future<int> getTotalDrivers() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.totalDrivers;
  }

  Future<int> getAvailableDrivers() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.availableDrivers;
  }

  Future<int> getAssignedDrivers() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.assignedDrivers;
  }

  Future<int> getTotalStaff() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.totalStaff;
  }

  Future<int> getActiveStaff() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.activeStaff;
  }

  Future<int> getTodaysCollections() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.todayCollections;
  }

  Future<int> getCompletedTodaysCollections() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.completedToday;
  }

  Future<int> getScheduledTodaysCollections() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.scheduledToday;
  }

  Future<int> getInProgressTodaysCollections() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.inProgressToday;
  }

  Future<int> getCancelledTodaysCollections() async {
    final summary = await getMunicipalAnalyticsSummary();
    return summary.cancelledToday;
  }

  Future<Map<String, int>> getCollectionsByWasteType() async {
    final summary = await getMunicipalAnalyticsSummary();
    return Map<String, int>.unmodifiable(summary.collectionsByWasteType);
  }

  Future<Map<String, int>> getCollectionsByZone() async {
    final summary = await getMunicipalAnalyticsSummary();
    return Map<String, int>.unmodifiable(summary.collectionsByZone);
  }
}
