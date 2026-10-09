import 'package:flutter_test/flutter_test.dart';
import 'package:cleancycle_mobileapp/vishani/models/missed_report_model.dart';
import 'package:cleancycle_mobileapp/vishani/models/special_pickup_model.dart';
import 'package:cleancycle_mobileapp/vishani/services/missed_report_service.dart';
import 'package:cleancycle_mobileapp/vishani/services/special_pickup_service.dart';
import 'package:cleancycle_mobileapp/vishani/services/tracking_service.dart';

void main() {
  group('Backend Services & CRUD Validation Tests', () {
    late MissedReportService missedReportService;

    setUp(() {
      missedReportService = MissedReportService();
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
      expect(
        fetchedReport?.description,
        'Test missed bin report for automated unit test.',
      );

      // 3. UPDATE (Description - backward-compatible method)
      await missedReportService.updateReportDescription(
        reportId,
        'Updated description for testing.',
      );
      final updatedReport = await missedReportService
          .getReportStream(reportId)
          .first;
      expect(updatedReport?.description, 'Updated description for testing.');

      // 3b. UPDATE (All relevant fields: collectionType, scheduledDate, address, description)
      final newScheduledDate = DateTime.now().subtract(const Duration(days: 2));
      await missedReportService.updateReportDetails(
        reportId,
        collectionType: 'Organic',
        scheduledDate: newScheduledDate,
        address: 'No. 42, Galle Road, Colombo 03',
        description: 'Organic compost bin was missed.',
      );
      final fullyUpdatedReport = await missedReportService
          .getReportStream(reportId)
          .first;
      expect(fullyUpdatedReport?.collectionType, 'Organic');
      expect(fullyUpdatedReport?.scheduledDate, newScheduledDate);
      expect(fullyUpdatedReport?.address, 'No. 42, Galle Road, Colombo 03');
      expect(
        fullyUpdatedReport?.description,
        'Organic compost bin was missed.',
      );

      // 4. DELETE (Cancel / Withdraw)
      await missedReportService.cancelReport(reportId);
      final deletedReport = await missedReportService
          .getReportStream(reportId)
          .first;
      expect(deletedReport, isNull);
    });

    test(
      'SpecialPickupService never creates a demo booking when signed out',
      () async {
        final service = SpecialPickupService(authenticatedUid: () => null);
        final pickup = SpecialPickupModel(
          requestId: '',
          userId: 'test_user_02',
          wasteType: 'E-Waste',
          scheduledDate: DateTime(2026, 10, 9),
          timeSlot: '1-3 PM',
          address: 'Test address',
          notes: '',
          createdAt: DateTime(2026, 10, 9),
        );
        await expectLater(
          service.createPickupRequest(pickup, []),
          throwsStateError,
        );
      },
    );

    test(
      'TrackingService: Next collection retrieval and signed-out tracking',
      () async {
        final signedOut = TrackingService(authenticatedUid: () => null);
        await expectLater(
          signedOut.streamResidentTracking('test_user_01'),
          emitsError(isA<StateError>()),
        );
      },
    );
  });
}
