import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../widgets/common/municipal_record_details.dart';

class DriverDetailsScreen extends StatelessWidget {
  const DriverDetailsScreen({
    super.key,
    required this.driver,
    required this.onEdit,
    required this.onDelete,
  });
  final Driver driver;
  final Future<Driver?> Function(Driver) onEdit;
  final Future<bool> Function(Driver) onDelete;

  @override
  Widget build(BuildContext context) => MunicipalRecordDetails<Driver>(
    title: 'Driver Details',
    record: driver,
    name: (v) => v.fullName,
    subtitle: (v) => v.driverId,
    status: (v) => v.status,
    icon: null,
    onEdit: onEdit,
    onDelete: onDelete,
    sections: (v) => [
      RecordDetailSection('Contact Information', [
        (Icons.badge_outlined, 'Driver ID', v.driverId),
        (Icons.email_outlined, 'Email', v.email),
        (Icons.phone_outlined, 'Contact Number', v.phoneNumber),
      ]),
      RecordDetailSection('License', [
        (Icons.credit_card_outlined, 'License Number', v.licenseNumber),
        (
          Icons.event_outlined,
          'License Expiry Date',
          detailDate(v.licenseExpiryDate),
        ),
      ]),
      RecordDetailSection('Assignment', [
        (
          Icons.local_shipping_outlined,
          'Assigned Vehicle',
          v.assignedVehicleId,
        ),
        (Icons.location_on_outlined, 'Collection Zone', v.assignedZone),
        (Icons.info_outline, 'Driver Status', v.status),
      ]),
    ],
  );
}
