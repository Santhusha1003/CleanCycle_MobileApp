import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../navigation/municipal_shell.dart';

import '../models/driver.dart';
import '../services/municipal/driver_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_primary_button.dart';
import '../widgets/common/app_search_field.dart';
import '../widgets/common/app_secondary_button.dart';
import '../widgets/common/app_status_card.dart';
import '../widgets/common/app_text_field.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final DriverService _driverService = DriverService();
  final TextEditingController _searchController = TextEditingController();

  // Real-time Firestore subscription.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _driverSubscription;

  bool _isLoading = true;
  String? _errorMessage;
  List<Driver> _drivers = const <Driver>[];
  List<Driver> _filteredDrivers = const <Driver>[];

  @override
  void initState() {
    super.initState();
    _subscribeDrivers();
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeDrivers() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _driverSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .snapshots()
        .listen(
          (snapshot) {
            final drivers = snapshot.docs
                .map((doc) => Driver.fromMap(doc.data()))
                .toList();
            if (mounted) {
              setState(() {
                _drivers = drivers;
                _filteredDrivers = _applySearchFilter(
                  _drivers,
                  _searchController.text,
                );
                _isLoading = false;
                _errorMessage = null;
              });
            }
          },
          onError: (Object error) {
            if (mounted) {
              setState(() {
                _errorMessage = _safeErrorMessage(
                  error is Exception ? error : Exception(error.toString()),
                );
                _isLoading = false;
              });
            }
          },
        );
  }

  Future<void> _loadDrivers() async {
    await _driverSubscription?.cancel();
    _subscribeDrivers();
  }

  List<Driver> _applySearchFilter(List<Driver> source, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return source;
    }

    return source.where((driver) {
      final searchableValues = [
        driver.fullName,
        driver.email,
        driver.phoneNumber,
        driver.licenseNumber,
        driver.assignedVehicleId ?? '',
        driver.assignedZone ?? '',
      ];

      return searchableValues.any(
        (value) => value.toLowerCase().contains(normalizedQuery),
      );
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filteredDrivers = _applySearchFilter(_drivers, value);
    });
  }

  String _generateDriverId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'driver_$timestamp';
  }

  Future<void> _showDriverForm({Driver? driver}) async {
    final isEditing = driver != null;
    final formKey = GlobalKey<FormState>();
    final driverIdController = TextEditingController(
      text: driver?.driverId ?? _generateDriverId(),
    );
    final fullNameController = TextEditingController(
      text: driver?.fullName ?? '',
    );
    final emailController = TextEditingController(text: driver?.email ?? '');
    final phoneNumberController = TextEditingController(
      text: driver?.phoneNumber ?? '',
    );
    final licenseNumberController = TextEditingController(
      text: driver?.licenseNumber ?? '',
    );
    final assignedVehicleController = TextEditingController(
      text: driver?.assignedVehicleId ?? '',
    );
    final assignedZoneController = TextEditingController(
      text: driver?.assignedZone ?? '',
    );

    DateTime? licenseExpiryDate = driver?.licenseExpiryDate;
    String statusValue = driver?.status ?? 'available';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                                  isEditing ? 'Edit Driver' : 'Add Driver',
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
                            controller: driverIdController,
                            label: 'Driver ID',
                            hintText: 'driver_123',
                            readOnly: isEditing,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Driver ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: fullNameController,
                            label: 'Full Name',
                            hintText: 'e.g. Jane Doe',
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: emailController,
                            label: 'Email',
                            hintText: 'driver@cleancycle.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Email is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: phoneNumberController,
                            label: 'Phone Number',
                            hintText: '+1 555 123 4567',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: licenseNumberController,
                            label: 'License Number',
                            hintText: 'DL-123456',
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'License number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue:
                                DriverService.allowedStatuses.contains(
                                  statusValue,
                                )
                                ? statusValue
                                : 'available',
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: DriverService.allowedStatuses
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
                            controller: assignedVehicleController,
                            label: 'Assigned Vehicle ID (optional)',
                            hintText: 'ABC-1234',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: assignedZoneController,
                            label: 'Assigned Zone (optional)',
                            hintText: 'North Zone',
                          ),
                          const SizedBox(height: 16),
                          AppSecondaryButton(
                            compact: true,
                            label: licenseExpiryDate == null
                                ? 'Select License Expiry Date'
                                : 'Expiry: ${_formatDate(licenseExpiryDate!)}',
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    licenseExpiryDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  licenseExpiryDate = picked;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          AppPrimaryButton(
                            compact: true,
                            icon: Icons.check,
                            label: isEditing ? 'Update Driver' : 'Save Driver',
                            isLoading: false,
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final driverId = driverIdController.text.trim();
                              final driverPayload = Driver(
                                driverId: driverId,
                                fullName: fullNameController.text.trim(),
                                email: emailController.text.trim(),
                                phoneNumber: phoneNumberController.text.trim(),
                                licenseNumber: licenseNumberController.text
                                    .trim(),
                                licenseExpiryDate: licenseExpiryDate,
                                assignedVehicleId: _normalizeOptional(
                                  assignedVehicleController.text,
                                ),
                                assignedZone: _normalizeOptional(
                                  assignedZoneController.text,
                                ),
                                status: statusValue.trim().toLowerCase(),
                                createdAt: driver?.createdAt ?? DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              bool success = false;
                              String successMessage = '';

                              try {
                                if (isEditing) {
                                  await _driverService.updateDriver(
                                    driverId: driver.driverId,
                                    driver: driverPayload,
                                  );
                                  successMessage =
                                      'Driver updated successfully.';
                                } else {
                                  await _driverService.createDriver(
                                    driver: driverPayload,
                                  );
                                  successMessage =
                                      'Driver created successfully.';
                                }
                                success = true;
                              } on DriverServiceException catch (exception) {
                                if (!mounted) return;
                                final errorMessage = exception.message;
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              } on Exception catch (exception) {
                                if (!mounted) return;
                                final errorMessage = _safeErrorMessage(
                                  exception,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              if (!mounted) return;
                              final safeContext = context;
                              Navigator.pop(sheetContext, success);
                              ScaffoldMessenger.of(safeContext).showSnackBar(
                                SnackBar(
                                  content: Text(successMessage),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              await _loadDrivers();
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
      await _loadDrivers();
    }
  }

  Future<void> _confirmDelete(Driver driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Delete driver ${driver.fullName}?'),
        actions: [
          AppSecondaryButton(
            label: 'Cancel',
            compact: true,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          AppSecondaryButton(
            label: 'Delete',
            compact: true,
            destructive: true,
            icon: Icons.delete_outline,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _driverService.deleteDriver(driverId: driver.driverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadDrivers();
    } on DriverServiceException catch (exception) {
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
          content: Text(_safeErrorMessage(exception)),
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
        leading: BackButton(
          onPressed: () => MunicipalShell.backToDashboard(context),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Driver Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage waste collection drivers',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              AppSearchField(
                controller: _searchController,
                hintText: 'Search drivers...',
                onChanged: _onSearchChanged,
                onClear: () => _onSearchChanged(''),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: AppPrimaryButton(
                  label: 'Add Driver',
                  compact: true,
                  icon: Icons.add,
                  onPressed: () => _showDriverForm(),
                ),
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
                            'Unable to load drivers',
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
                            onPressed: _loadDrivers,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_filteredDrivers.isEmpty)
                Expanded(
                  child: Center(
                    child: AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No drivers found',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or add a driver.',
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
                    itemCount: _filteredDrivers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final driver = _filteredDrivers[index];

                      return AppCard(
                        color: AppColors.greenSurface,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    driver.fullName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                AppStatusCard(
                                  statusText: _statusLabel(driver.status),
                                  color: _statusColor(driver.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _detailRow('Email', driver.email),
                            _detailRow('Phone', driver.phoneNumber),
                            _detailRow('License', driver.licenseNumber),
                            if (driver.assignedVehicleId != null &&
                                driver.assignedVehicleId!.isNotEmpty)
                              _detailRow(
                                'Assigned Vehicle',
                                driver.assignedVehicleId!,
                              ),
                            if (driver.assignedZone != null &&
                                driver.assignedZone!.isNotEmpty)
                              _detailRow('Zone', driver.assignedZone!),
                            if (driver.licenseExpiryDate != null)
                              _detailRow(
                                'License Expiry',
                                _formatDate(driver.licenseExpiryDate!),
                              ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  AppSecondaryButton(
                                    label: 'Edit',
                                    compact: true,
                                    icon: Icons.edit_outlined,
                                    onPressed: () =>
                                        _showDriverForm(driver: driver),
                                  ),
                                  AppSecondaryButton(
                                    label: 'Delete',
                                    compact: true,
                                    icon: Icons.delete_outline,
                                    destructive: true,
                                    onPressed: () => _confirmDelete(driver),
                                  ),
                                ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            TextSpan(text: value),
          ],
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
      case 'on_leave':
        return 'On Leave';
      case 'inactive':
        return 'Inactive';
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
      case 'on_leave':
        return const Color(0xFFFFF3E0);
      case 'inactive':
        return const Color(0xFFFFEAEA);
      default:
        return AppColors.greenSurface;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String? _normalizeOptional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String _safeErrorMessage(Object exception) {
    final text = exception.toString();
    if (text.startsWith('DriverServiceException:')) {
      return text.replaceFirst('DriverServiceException: ', '');
    }
    if (text.startsWith('FirebaseServiceException')) {
      return 'Unable to load driver data right now. Please try again.';
    }
    return text;
  }
}
