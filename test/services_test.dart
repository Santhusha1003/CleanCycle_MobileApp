import 'package:flutter_test/flutter_test.dart';
import 'package:cleancycle_mobileapp/models/missed_report_model.dart';
import 'package:cleancycle_mobileapp/models/special_pickup_model.dart';
import 'package:cleancycle_mobileapp/services/missed_report_service.dart';
import 'package:cleancycle_mobileapp/services/special_pickup_service.dart';
import 'package:cleancycle_mobileapp/services/tracking_service.dart';

void main() {
  group('Backend Services & CRUD Validation Tests', () {
    late MissedReportService missedReportService;
    late SpecialPickupService specialPickupService;
    late TrackingService trackingService;

    setUp(() {
      missedReportService = MissedReportService();
      specialPickupService = SpecialPickupService();
      trackingService = TrackingService();
    });

    test('CRUD 1: Full lifecycle test for MissedReportService', () async {
      // 1. CREATE
      final newReport = MissedReportModel(
        reportId: '',
        userId: 'test_user_01',
        collectionType: 'Recyclable',
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Test missed bin report for automated unit test.',
        reportedOn: DateTime.now(),
      );

      final reportId = await missedReportService.createReport(newReport, null);
      expect(reportId, startsWith('MC-'));

      // 2. READ (Stream)
      final reportStream = missedReportService.getReportStream(reportId);
      final fetchedReport = await reportStream.first;
      expect(fetchedReport, isNotNull);
      expect(fetchedReport?.collectionType, 'Recyclable');
      expect(fetchedReport?.description, 'Test missed bin report for automated unit test.');

      // 3. UPDATE (Description)
      await missedReportService.updateReportDescription(
        reportId,
        'Updated description for testing.',
      );
      final updatedReport = await missedReportService.getReportStream(reportId).first;
      expect(updatedReport?.description, 'Updated description for testing.');

      // 4. DELETE (Cancel / Withdraw)
      await missedReportService.cancelReport(reportId);
      final deletedReport = await missedReportService.getReportStream(reportId).first;
      expect(deletedReport, isNull);
    });

    test('CRUD 2: Full lifecycle test for SpecialPickupService', () async {
      // 1. CREATE
      final newPickup = SpecialPickupModel(
        requestId: '',
        userId: 'test_user_02',
        wasteType: 'E-Waste',
        scheduledDate: DateTime.now().add(const Duration(days: 3)),
        timeSlot: '1-3 PM',
        address: 'No. 55, Havelock Road, Colombo 05',
        notes: 'Old CRT monitor and printer',
        createdAt: DateTime.now(),
      );

      final requestId = await specialPickupService.createPickupRequest(newPickup, []);
      expect(requestId, startsWith('SP-'));

      // 2. READ (Stream)
      final pickupStream = specialPickupService.getPickupStream(requestId);
      final fetchedPickup = await pickupStream.first;
      expect(fetchedPickup, isNotNull);
      expect(fetchedPickup?.wasteType, 'E-Waste');
      expect(fetchedPickup?.timeSlot, '1-3 PM');

      // 3. UPDATE (Reschedule)
      final rescheduledDate = DateTime.now().add(const Duration(days: 5));
      await specialPickupService.reschedulePickup(requestId, rescheduledDate, '3-5 PM');
      final updatedPickup = await specialPickupService.getPickupStream(requestId).first;
      expect(updatedPickup?.timeSlot, '3-5 PM');

      // 4. DELETE (Cancel Pickup)
      await specialPickupService.cancelPickup(requestId);
      final deletedPickup = await specialPickupService.getPickupStream(requestId).first;
      expect(deletedPickup, isNull);
    });

    test('TrackingService: Next collection retrieval and driver stream', () async {
      final nextCol = await trackingService.fetchNextCollection('test_user_01');
      expect(nextCol, isNotNull);
      expect(nextCol.containsKey('category'), isTrue);
      expect(nextCol.containsKey('timeWindow'), isTrue);

      final driverStream = trackingService.streamDriverLocation('DRV-001');
      final driver = await driverStream.first;
      expect(driver.driverName, 'Nalin Perera');
      expect(driver.driverPhone, '+94771234567');
      expect(driver.etaMinutes, greaterThan(0));
    });
  });
}
