import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../widgets/common/municipal_record_details.dart';

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });
  final Vehicle vehicle;
  final Future<Vehicle?> Function(Vehicle) onEdit;
  final Future<bool> Function(Vehicle) onDelete;

  @override
  Widget build(BuildContext context) => MunicipalRecordDetails<Vehicle>(
    title: 'Vehicle Details',
    record: vehicle,
    name: (v) => v.registrationNumber,
    subtitle: (v) => v.vehicleType,
    status: (v) => v.status,
    icon: Icons.local_shipping_outlined,
    onEdit: onEdit,
    onDelete: onDelete,
    sections: (v) => [
      RecordDetailSection('Vehicle Information', [
        (
          Icons.confirmation_number_outlined,
          'Registration',
          v.registrationNumber,
        ),
        (Icons.category_outlined, 'Vehicle Type', v.vehicleType),
        (Icons.business_outlined, 'Brand', v.brand),
        (Icons.local_shipping_outlined, 'Model', v.model),
        (
          Icons.calendar_today_outlined,
          'Manufacturing Year',
          v.yearManufactured?.toString(),
        ),
        (Icons.scale_outlined, 'Capacity', '${v.capacityKg} kg'),
      ]),
      RecordDetailSection('Assignment', [
        (Icons.person_outline, 'Assigned Driver ID', v.assignedDriverId),
        (Icons.location_on_outlined, 'Collection Zone', v.assignedZone),
        (Icons.info_outline, 'Current Status', v.status),
      ]),
      RecordDetailSection('Service Dates', [
        (
          Icons.build_outlined,
          'Last Service Date',
          detailDate(v.lastServiceDate),
        ),
        (
          Icons.event_outlined,
          'Next Service Date',
          detailDate(v.nextServiceDate),
        ),
      ]),
    ],
  );
}
