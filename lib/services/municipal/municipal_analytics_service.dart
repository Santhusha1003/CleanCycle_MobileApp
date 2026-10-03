import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/collection_schedule.dart';
import '../../models/driver.dart';
import '../../models/staff.dart';
import '../../models/vehicle.dart';
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

      final vehicles = results[0]
          .map((data) => Vehicle.fromMap(data))
          .toList(growable: false);
      final drivers = results[1]
          .map((data) => Driver.fromMap(data))
          .toList(growable: false);
      final staffMembers = results[2]
          .map((data) => Staff.fromMap(data))
          .toList(growable: false);
      final schedules = results[3]
          .map((data) => CollectionSchedule.fromMap(data))
          .toList(growable: false);

      final totalVehicles = vehicles.length;
      final availableVehicles = vehicles
          .where(
            (vehicle) => vehicle.status.trim().toLowerCase() == 'available',
          )
          .length;
      final maintenanceVehicles = vehicles
          .where(
            (vehicle) => vehicle.status.trim().toLowerCase() == 'maintenance',
          )
          .length;

      final totalDrivers = drivers.length;
      final availableDrivers = drivers
          .where((driver) => driver.status.trim().toLowerCase() == 'available')
          .length;
      final assignedDrivers = drivers
          .where((driver) => driver.status.trim().toLowerCase() == 'assigned')
          .length;

      final totalStaff = staffMembers.length;
      final activeStaff = staffMembers
          .where((member) => member.status.trim().toLowerCase() == 'active')
          .length;

      final now = DateTime.now();
      final todayStart = _startOfDay(now);
      final tomorrowStart = _startOfDay(now.add(const Duration(days: 1)));

      final todaysSchedules = schedules
          .where((schedule) {
            final collectionDate = schedule.collectionDate;
            return !collectionDate.isBefore(todayStart) &&
                collectionDate.isBefore(tomorrowStart);
          })
          .toList(growable: false);

      final todayCollections = todaysSchedules.length;
      final completedToday = todaysSchedules
          .where(
            (schedule) => schedule.status.trim().toLowerCase() == 'completed',
          )
          .length;
      final scheduledToday = todaysSchedules
          .where(
            (schedule) => schedule.status.trim().toLowerCase() == 'scheduled',
          )
          .length;
      final inProgressToday = todaysSchedules
          .where(
            (schedule) => schedule.status.trim().toLowerCase() == 'in_progress',
          )
          .length;
      final cancelledToday = todaysSchedules
          .where(
            (schedule) => schedule.status.trim().toLowerCase() == 'cancelled',
          )
          .length;

      final collectionsByWasteType = _emptyWasteTypeCounts();
      for (final schedule in todaysSchedules) {
        final normalizedWasteType = schedule.wasteType.trim().toLowerCase();
        if (collectionsByWasteType.containsKey(normalizedWasteType)) {
          collectionsByWasteType[normalizedWasteType] =
              (collectionsByWasteType[normalizedWasteType] ?? 0) + 1;
        }
      }

      final collectionsByZone = <String, int>{};
      for (final schedule in todaysSchedules) {
        final zoneKey = schedule.zone.trim();
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
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    } on FormatException catch (exception) {
      throw FirebaseServiceException(
        code: 'format_exception',
        message: exception.message,
      );
    } catch (exception) {
      if (exception is FirebaseServiceException) {
        rethrow;
      }
      throw FirebaseServiceException(
        code: 'municipal_analytics_error',
        message: 'Failed to calculate municipal analytics: $exception',
      );
    }
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
