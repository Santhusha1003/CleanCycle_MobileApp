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
  final Map<String, int> collectionsByWasteType;
  final Map<String, int> collectionsByZone;
}

class MunicipalAnalyticsService {
  MunicipalAnalyticsService({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

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

  DateTime _startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Future<MunicipalAnalyticsSummary> getMunicipalAnalyticsSummary() async {
    try {
      final results = await Future.wait([
        _firestoreService.getCollection(path: vehicleCollectionPath),
        _firestoreService.getCollection(path: driverCollectionPath),
        _firestoreService.getCollection(path: staffCollectionPath),
        _firestoreService.getCollection(path: scheduleCollectionPath),
      ]);

      // Analytics needs only status/date/grouping fields, not complete CRUD
      // models. Legacy records and pending audit timestamps remain countable.
      final vehicles = results[0];
      final drivers = results[1];
      final staffMembers = results[2];
      final schedules = results[3];

      final totalVehicles = vehicles.length;
      final availableVehicles = vehicles
          .where(
            (vehicle) => _text(vehicle['status']).toLowerCase() == 'available',
          )
          .length;
      final maintenanceVehicles = vehicles
          .where(
            (vehicle) =>
                _text(vehicle['status']).toLowerCase() == 'maintenance',
          )
          .length;

      final totalDrivers = drivers.length;
      final availableDrivers = drivers
          .where(
            (driver) => _text(driver['status']).toLowerCase() == 'available',
          )
          .length;
      final assignedDrivers = drivers
          .where(
            (driver) => _text(driver['status']).toLowerCase() == 'assigned',
          )
          .length;

      final totalStaff = staffMembers.length;
      final activeStaff = staffMembers
          .where((member) => _text(member['status']).toLowerCase() == 'active')
          .length;

      final now = DateTime.now();
      final todayStart = _startOfDay(now);
      final tomorrowStart = _startOfDay(now.add(const Duration(days: 1)));

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
            return !collectionDate.isBefore(todayStart) &&
                collectionDate.isBefore(tomorrowStart);
          })
          .toList(growable: false);

      final todayCollections = todaysSchedules.length;
      final completedToday = todaysSchedules
          .where(
            (schedule) =>
                _text(schedule['status']).toLowerCase() == 'completed',
          )
          .length;
      final scheduledToday = todaysSchedules
          .where(
            (schedule) =>
                _text(schedule['status']).toLowerCase() == 'scheduled',
          )
          .length;
      final inProgressToday = todaysSchedules
          .where(
            (schedule) =>
                _text(schedule['status']).toLowerCase() == 'in_progress',
          )
          .length;
      final cancelledToday = todaysSchedules
          .where(
            (schedule) =>
                _text(schedule['status']).toLowerCase() == 'cancelled',
          )
          .length;

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
        collectionsByWasteType: collectionsByWasteType,
        collectionsByZone: collectionsByZone,
      );
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

  String _text(dynamic value) => value is String ? value.trim() : '';

  DateTime? _collectionDate(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    // Existing schedules also store ISO dates; do not fabricate missing dates.
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
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
