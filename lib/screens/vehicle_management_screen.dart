import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import 'vehicle_details_screen.dart';
import '../services/municipal/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_primary_button.dart';
import '../widgets/common/municipal_add_button.dart';
import '../widgets/common/app_search_field.dart';
import '../widgets/common/app_secondary_button.dart';
import '../widgets/common/municipal_crud_actions.dart';
import '../widgets/common/app_status_card.dart';
import '../widgets/common/app_text_field.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key, this.vehicleService});

  final VehicleService? vehicleService;

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  late final VehicleService _vehicleService =
      widget.vehicleService ?? VehicleService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Vehicle> _vehicles = const <Vehicle>[];
  List<Vehicle> _filteredVehicles = const <Vehicle>[];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _filteredVehicles = _applySearchFilter(
          _vehicles,
          _searchController.text,
        );
        _isLoading = false;
      });
    } on Exception catch (exception) {
      setState(() {
        _errorMessage = exception.toString();
        _isLoading = false;
      });
    }
  }

  List<Vehicle> _applySearchFilter(List<Vehicle> source, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return source;
    }

    return source.where((vehicle) {
      final searchableValues = [
        vehicle.registrationNumber,
        vehicle.vehicleType,
        vehicle.brand ?? '',
        vehicle.model ?? '',
        vehicle.assignedZone ?? '',
      ];

      return searchableValues.any(
        (value) => value.toLowerCase().contains(normalizedQuery),
      );
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filteredVehicles = _applySearchFilter(_vehicles, value);
    });
  }

  Future<void> _showVehicleForm({Vehicle? vehicle}) async {
    final isEditing = vehicle != null;
    final formKey = GlobalKey<FormState>();
    final registrationController = TextEditingController(
      text: vehicle?.registrationNumber ?? '',
    );
    final vehicleTypeController = TextEditingController(
      text: vehicle?.vehicleType ?? '',
    );
    final brandController = TextEditingController(text: vehicle?.brand ?? '');
    final modelController = TextEditingController(text: vehicle?.model ?? '');
    final yearController = TextEditingController(
      text: vehicle?.yearManufactured?.toString() ?? '',
    );
    final capacityController = TextEditingController(
      text: vehicle?.capacityKg.toString() ?? '',
    );
    final assignedDriverController = TextEditingController(
      text: vehicle?.assignedDriverId ?? '',
    );
    final assignedZoneController = TextEditingController(
      text: vehicle?.assignedZone ?? '',
    );

    DateTime? lastServiceDate = vehicle?.lastServiceDate;
    DateTime? nextServiceDate = vehicle?.nextServiceDate;
    String statusValue = vehicle?.status ?? 'available';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: registrationController,
                            label: 'Registration Number',
                            hintText: 'e.g. ABC-1234',
                            readOnly: isEditing,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Registration number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: vehicleTypeController,
                            label: 'Vehicle Type',
                            hintText: 'e.g. Compactor',
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Vehicle type is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: capacityController,
                            label: 'Capacity (kg)',
                            hintText: 'e.g. 3500',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final valueText = (value ?? '').trim();
                              if (valueText.isEmpty) {
                                return 'Capacity is required';
                              }
                              final parsed = num.tryParse(valueText);
                              if (parsed == null || parsed < 0) {
                                return 'Capacity must be a valid non-negative number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue:
                                VehicleService.allowedStatuses.contains(
                                  statusValue,
                                )
                                ? statusValue
                                : 'available',
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: VehicleService.allowedStatuses
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(_statusLabel(status)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => statusValue = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: brandController,
                            label: 'Brand (optional)',
                            hintText: 'e.g. Volvo',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: modelController,
                            label: 'Model (optional)',
                            hintText: 'e.g. FE 320',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: yearController,
                            label: 'Year Manufactured (optional)',
                            hintText: 'e.g. 2022',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: assignedDriverController,
                            label: 'Assigned Driver ID (optional)',
                            hintText: 'driver id',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: assignedZoneController,
                            label: 'Assigned Zone (optional)',
                            hintText: 'West Zone',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppSecondaryButton(
                                  label: lastServiceDate == null
                                      ? 'Last Service Date'
                                      : 'Last: ${_formatDate(lastServiceDate!)}',
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          lastServiceDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        lastServiceDate = picked;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppSecondaryButton(
                                  label: nextServiceDate == null
                                      ? 'Next Service Date'
                                      : 'Next: ${_formatDate(nextServiceDate!)}',
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          nextServiceDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        nextServiceDate = picked;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AppPrimaryButton(
                            label: isEditing
                                ? 'Update Vehicle'
                                : 'Save Vehicle',
                            isLoading: false,
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final resultVehicle = Vehicle(
                                  registrationNumber: registrationController
                                      .text
                                      .trim(),
                                  vehicleType: vehicleTypeController.text
                                      .trim(),
                                  brand: _normalizeOptional(
                                    brandController.text,
                                  ),
                                  model: _normalizeOptional(
                                    modelController.text,
                                  ),
                                  yearManufactured:
                                      yearController.text.trim().isEmpty
                                      ? null
                                      : int.tryParse(
                                          yearController.text.trim(),
                                        ),
                                  capacityKg: num.parse(
                                    capacityController.text.trim(),
                                  ),
                                  status: statusValue.trim().toLowerCase(),
                                  assignedDriverId: _normalizeOptional(
                                    assignedDriverController.text,
                                  ),
                                  assignedZone: _normalizeOptional(
                                    assignedZoneController.text,
                                  ),
                                  lastServiceDate: lastServiceDate,
                                  nextServiceDate: nextServiceDate,
                                  createdAt:
                                      vehicle?.createdAt ?? DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );

                                bool success = false;
                                String? message;

                                try {
                                  if (isEditing) {
                                    await _vehicleService.updateVehicle(
                                      registrationNumber:
                                          vehicle.registrationNumber,
                                      vehicle: resultVehicle,
                                    );
                                    message = 'Vehicle updated successfully.';
                                  } else {
                                    await _vehicleService.createVehicle(
                                      vehicle: resultVehicle,
                                    );
                                    message = 'Vehicle created successfully.';
                                  }
                                  success = true;
                                } on VehicleServiceException catch (exception) {
                                  message = exception.message;
                                } on Exception catch (exception) {
                                  message = exception.toString();
                                }

                                if (success) {
                                  if (!mounted) return;
                                  Navigator.pop(sheetContext, success);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  await _loadVehicles();
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadVehicles();
    }
  }

  void _showVehicleDetail(Vehicle vehicle) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsScreen(
          vehicle: vehicle,
          onEdit: (record) async {
            await _showVehicleForm(vehicle: record);
            if (!mounted) return null;
            final matches = _vehicles.where(
              (item) => item.registrationNumber == record.registrationNumber,
            );
            return matches.isEmpty ? null : matches.first;
          },
          onDelete: (record) async {
            await _confirmDelete(record);
            return mounted &&
                !_vehicles.any(
                  (item) =>
                      item.registrationNumber == record.registrationNumber,
                );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete vehicle ${vehicle.registrationNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _vehicleService.deleteVehicle(
        registrationNumber: vehicle.registrationNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadVehicles();
    } on VehicleServiceException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.message),
          backgroundColor: AppColors.error,
        ),
      );
    } on Exception catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Vehicle Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showVehicleForm(),
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage municipal vehicles',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              AppSearchField(
                controller: _searchController,
                hintText: 'Search vehicles...',
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MunicipalAddButton(
                      label: 'Add Vehicle',
                      onPressed: () => _showVehicleForm(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load vehicles',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppPrimaryButton(
                            label: 'Retry',
                            onPressed: _loadVehicles,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_filteredVehicles.isEmpty)
                Expanded(
                  child: Center(
                    child: AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No vehicles found',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or add a new vehicle.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _filteredVehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final vehicle = _filteredVehicles[index];
                      return AppCard(
                        onTap: () => _showVehicleDetail(vehicle),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    vehicle.registrationNumber,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                AppStatusCard(
                                  statusText: _statusLabel(vehicle.status),
                                  color: _statusColor(vehicle.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${vehicle.vehicleType}${vehicle.brand != null && vehicle.model != null
                                  ? ' • ${vehicle.brand} ${vehicle.model}'
                                  : vehicle.brand != null
                                  ? ' • ${vehicle.brand}'
                                  : vehicle.model != null
                                  ? ' • ${vehicle.model}'
                                  : ''}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                InfoChip(
                                  label: 'Capacity: ${vehicle.capacityKg} kg',
                                ),
                                if (vehicle.assignedZone != null &&
                                    vehicle.assignedZone!.isNotEmpty)
                                  InfoChip(
                                    label: 'Zone: ${vehicle.assignedZone}',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: MunicipalCrudActions(
                                onEdit: () =>
                                    _showVehicleForm(vehicle: vehicle),
                                onDelete: () => _confirmDelete(vehicle),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'available':
        return 'Available';
      case 'assigned':
        return 'Assigned';
      case 'maintenance':
        return 'Maintenance';
      case 'out_of_service':
        return 'Out of Service';
      case 'retired':
        return 'Retired';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'available':
        return AppColors.lightGreen;
      case 'assigned':
        return const Color(0xFFEAF4FF);
      case 'maintenance':
        return const Color(0xFFFFF3E0);
      case 'out_of_service':
        return const Color(0xFFFFEAEA);
      case 'retired':
        return const Color(0xFFEAEAEA);
      default:
        return AppColors.greenSurface;
    }
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  static String? _normalizeOptional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
