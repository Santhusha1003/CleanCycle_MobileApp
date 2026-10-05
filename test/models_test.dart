import 'package:flutter_test/flutter_test.dart';
import 'package:cleancycle_mobileapp/models/missed_report_model.dart';
import 'package:cleancycle_mobileapp/models/special_pickup_model.dart';
import 'package:cleancycle_mobileapp/models/driver_tracking_model.dart';

void main() {
  group('CleanCycle Model Unit Tests & Validation', () {
    test('MissedReportModel serialization and copyWith validation', () {
      final now = DateTime.now();
      final report = MissedReportModel(
        reportId: 'MC-TEST-001',
        userId: 'user_123',
        collectionType: 'Organic',
        scheduledDate: now,
        description: 'Green bin was missed on Monday morning',
        photoUrl: 'https://example.com/test.jpg',
        status: 'Reported',
        reportedOn: now,
      );

      // Validate getters
      expect(report.reportId, 'MC-TEST-001');
      expect(report.userId, 'user_123');
      expect(report.collectionType, 'Organic');
      expect(report.status, 'Reported');

      // Validate toMap()
      final map = report.toMap();
      expect(map['reportId'], 'MC-TEST-001');
      expect(map['userId'], 'user_123');
      expect(map['collectionType'], 'Organic');
      expect(map['description'], 'Green bin was missed on Monday morning');

      // Validate copyWith()
      final updated = report.copyWith(
        status: 'Resolved',
        description: 'Issue resolved by crew',
      );
      expect(updated.status, 'Resolved');
      expect(updated.description, 'Issue resolved by crew');
      expect(updated.reportId, 'MC-TEST-001');
    });

    test('SpecialPickupModel serialization and validation', () {
      final now = DateTime.now();
      final pickup = SpecialPickupModel(
        requestId: 'SP-TEST-002',
        userId: 'user_456',
        wasteType: 'Furniture',
        scheduledDate: now,
        timeSlot: '10-12 PM',
        address: 'No. 10, Flower Road, Colombo',
        notes: 'Sofa and wooden table',
        photoUrls: ['https://example.com/p1.jpg', 'https://example.com/p2.jpg'],
        status: 'Pending',
        createdAt: now,
      );

      expect(pickup.requestId, 'SP-TEST-002');
      expect(pickup.wasteType, 'Furniture');
      expect(pickup.photoUrls.length, 2);

      final map = pickup.toMap();
      expect(map['requestId'], 'SP-TEST-002');
      expect(map['timeSlot'], '10-12 PM');
      expect(map['photoUrls'], hasLength(2));

      final rescheduled = pickup.copyWith(timeSlot: '1-3 PM');
      expect(rescheduled.timeSlot, '1-3 PM');
    });

    test('DriverTrackingModel coordinate calculations and defaults', () {
      final driver = DriverTrackingModel(
        driverId: 'DRV-001',
        driverName: 'Nalin Perera',
        driverPhone: '+94771234567',
        currentLatitude: 6.9271,
        currentLongitude: 79.8612,
        destinationLatitude: 6.9319,
        destinationLongitude: 79.8578,
        etaMinutes: 20,
      );

      expect(driver.driverName, 'Nalin Perera');
      expect(driver.vehicleNumber, 'WP-NA-4521');
      expect(driver.etaMinutes, 20);

      final map = driver.toMap();
      expect(map['driverId'], 'DRV-001');
      expect(map['currentLatitude'], 6.9271);
      expect(map['etaMinutes'], 20);
    });
  });
}
