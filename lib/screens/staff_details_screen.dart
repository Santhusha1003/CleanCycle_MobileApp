import 'package:flutter/material.dart';

import '../models/staff.dart';
import '../widgets/common/municipal_record_details.dart';

class StaffDetailsScreen extends StatelessWidget {
  const StaffDetailsScreen({
    super.key,
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });
  final Staff staff;
  final Future<Staff?> Function(Staff) onEdit;
  final Future<bool> Function(Staff) onDelete;

  @override
  Widget build(BuildContext context) => MunicipalRecordDetails<Staff>(
    title: 'Staff Details',
    record: staff,
    name: (v) => v.fullName,
    subtitle: (v) => v.staffId,
    status: (v) => v.status,
    icon: null,
    onEdit: onEdit,
    onDelete: onDelete,
    sections: (v) => [
      RecordDetailSection('Staff Information', [
        (Icons.badge_outlined, 'Staff ID', v.staffId),
        (Icons.work_outline, 'Position', v.position),
        (Icons.info_outline, 'Employment Status', v.status),
      ]),
      RecordDetailSection('Contact Information', [
        (Icons.email_outlined, 'Email', v.email),
        (Icons.phone_outlined, 'Contact Number', v.phoneNumber),
      ]),
      RecordDetailSection('Assignment', [
        (Icons.location_on_outlined, 'Assigned Zone', v.assignedZone),
      ]),
    ],
  );
}
