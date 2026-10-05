import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/staff.dart';
import '../services/municipal/staff_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_primary_button.dart';
import '../widgets/common/app_search_field.dart';
import '../widgets/common/app_secondary_button.dart';
import '../widgets/common/app_status_card.dart';
import '../widgets/common/app_text_field.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _staffService = StaffService();
  final TextEditingController _searchController = TextEditingController();

  // Real-time Firestore subscription.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _staffSubscription;

  bool _isLoading = true;
  String? _errorMessage;
  List<Staff> _staffMembers = const <Staff>[];
  List<Staff> _filteredStaff = const <Staff>[];

  @override
  void initState() {
    super.initState();
    _subscribeStaff();
  }

  @override
  void dispose() {
    _staffSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  void _subscribeStaff() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _staffSubscription = FirebaseFirestore.instance
        .collection('staff')
        .snapshots()
        .listen(
          (snapshot) {
            final members = snapshot.docs
                .map((doc) => Staff.fromMap(doc.data()))
                .toList();
            if (mounted) {
              setState(() {
                _staffMembers = members;
                _filteredStaff = _applySearchFilter(
                  _staffMembers,
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

  Future<void> _loadStaff() async {
    await _staffSubscription?.cancel();
    _subscribeStaff();
  }

  List<Staff> _applySearchFilter(List<Staff> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((s) {
      final fields = [
        s.fullName,
        s.email,
        s.phoneNumber,
        s.position,
        s.assignedZone ?? '',
      ];
      return fields.any((f) => f.toLowerCase().contains(q));
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filteredStaff = _applySearchFilter(_staffMembers, value);
    });
  }

  // ─── ID generation ─────────────────────────────────────────────────────────

  String _generateStaffId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'staff_$timestamp';
  }

  // ─── Add / Edit form ───────────────────────────────────────────────────────

  Future<void> _showStaffForm({Staff? staff}) async {
    final isEditing = staff != null;
    final formKey = GlobalKey<FormState>();

    final staffIdController = TextEditingController(
      text: staff?.staffId ?? _generateStaffId(),
    );
    final fullNameController = TextEditingController(
      text: staff?.fullName ?? '',
    );
    final emailController = TextEditingController(text: staff?.email ?? '');
    final phoneController = TextEditingController(
      text: staff?.phoneNumber ?? '',
    );
    final positionController = TextEditingController(
      text: staff?.position ?? '',
    );
    final zoneController = TextEditingController(
      text: staff?.assignedZone ?? '',
    );

    String statusValue = staff?.status ?? 'active';

    await showModalBottomSheet<void>(
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
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 28,
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ──────────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isEditing
                                      ? 'Edit Staff Member'
                                      : 'Add Staff Member',
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

                          // ── Staff ID (read-only when editing) ────────────
                          AppTextField(
                            controller: staffIdController,
                            label: 'Staff ID',
                            hintText: 'staff_123',
                            readOnly: isEditing,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Staff ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Full Name ────────────────────────────────────
                          AppTextField(
                            controller: fullNameController,
                            label: 'Full Name',
                            hintText: 'e.g. Sarah Mensah',
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Email ────────────────────────────────────────
                          AppTextField(
                            controller: emailController,
                            label: 'Email',
                            hintText: 'staff@cleancycle.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Email is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Phone Number ─────────────────────────────────
                          AppTextField(
                            controller: phoneController,
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

                          // ── Position ─────────────────────────────────────
                          AppTextField(
                            controller: positionController,
                            label: 'Position',
                            hintText: 'e.g. Collection Supervisor',
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Position is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Status ───────────────────────────────────────
                          DropdownButtonFormField<String>(
                            initialValue:
                                StaffService.allowedStatuses.contains(
                                  statusValue,
                                )
                                ? statusValue
                                : 'active',
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: StaffService.allowedStatuses
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(_statusLabel(s)),
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

                          // ── Assigned Zone (optional) ─────────────────────
                          AppTextField(
                            controller: zoneController,
                            label: 'Assigned Zone (optional)',
                            hintText: 'e.g. North Zone',
                          ),
                          const SizedBox(height: 20),

                          // ── Submit ───────────────────────────────────────
                          AppPrimaryButton(
                            label: isEditing
                                ? 'Update Staff Member'
                                : 'Save Staff Member',
                            isLoading: false,
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final staffPayload = Staff(
                                staffId: staffIdController.text.trim(),
                                fullName: fullNameController.text.trim(),
                                email: emailController.text.trim(),
                                phoneNumber: phoneController.text.trim(),
                                position: positionController.text.trim(),
                                assignedZone: _normalizeOptional(
                                  zoneController.text,
                                ),
                                status: statusValue.trim().toLowerCase(),
                                createdAt: staff?.createdAt ?? DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              String successMessage;

                              // Capture before async gap
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              final navigator = Navigator.of(sheetContext);

                              try {
                                if (isEditing) {
                                  await _staffService.updateStaff(
                                    staffId: staff.staffId,
                                    staff: staffPayload,
                                  );
                                  successMessage =
                                      'Staff member updated successfully.';
                                } else {
                                  await _staffService.createStaff(
                                    staff: staffPayload,
                                  );
                                  successMessage =
                                      'Staff member created successfully.';
                                }
                              } on StaffServiceException catch (exception) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(exception.message),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              } on Exception catch (exception) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(_safeErrorMessage(exception)),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              navigator.pop();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(successMessage),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              await _loadStaff();
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
  }

  // ─── View detail dialog ────────────────────────────────────────────────────

  void _showStaffDetail(Staff staff) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.greenSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primaryDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                staff.fullName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogDetailRow('Staff ID', staff.staffId),
              _dialogDetailRow('Position', staff.position),
              _dialogDetailRow('Email', staff.email),
              _dialogDetailRow('Phone', staff.phoneNumber),
              if (staff.assignedZone != null && staff.assignedZone!.isNotEmpty)
                _dialogDetailRow('Zone', staff.assignedZone!),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppStatusCard(
                    statusText: _statusLabel(staff.status),
                    color: _statusColor(staff.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _dialogDetailRow('Created', _formatDate(staff.createdAt)),
              _dialogDetailRow('Last Updated', _formatDate(staff.updatedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showStaffForm(staff: staff);
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text(
          'Delete "${staff.fullName}"? This action cannot be undone.',
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

    if (confirmed != true) return;

    try {
      await _staffService.deleteStaff(staffId: staff.staffId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff member deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadStaff();
    } on StaffServiceException catch (exception) {
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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Staff Management',
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
              // ── Subtitle ──────────────────────────────────────────────
              const Text(
                'Manage municipal operations staff',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // ── Search ────────────────────────────────────────────────
              AppSearchField(
                controller: _searchController,
                hintText: 'Search staff...',
                onChanged: _onSearchChanged,
                onClear: () => _onSearchChanged(''),
              ),
              const SizedBox(height: 16),

              // ── Add button ────────────────────────────────────────────
              AppPrimaryButton(
                label: 'Add Staff Member',
                onPressed: () => _showStaffForm(),
              ),
              const SizedBox(height: 20),

              // ── Body ──────────────────────────────────────────────────
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_filteredStaff.isEmpty)
                _buildEmptyState()
              else
                _buildStaffList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
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
                'Unable to load staff',
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
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(label: 'Retry', onPressed: _loadStaff),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.group_outlined, color: AppColors.primary, size: 40),
              SizedBox(height: 12),
              Text(
                'No staff members found',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your search or add a staff member.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffList() {
    return Expanded(
      child: ListView.separated(
        itemCount: _filteredStaff.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final staff = _filteredStaff[index];
          return _StaffCard(
            staff: staff,
            onView: () => _showStaffDetail(staff),
            onEdit: () => _showStaffForm(staff: staff),
            onDelete: () => _confirmDelete(staff),
          );
        },
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'on_leave':
        return 'On Leave';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return AppColors.lightGreen;
      case 'inactive':
        return const Color(0xFFFFEAEA);
      case 'on_leave':
        return const Color(0xFFFFF3E0);
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
    if (text.startsWith('StaffServiceException:')) {
      return text.replaceFirst('StaffServiceException: ', '');
    }
    if (text.contains('FirebaseServiceException')) {
      return 'Unable to load staff data right now. Please try again.';
    }
    return text;
  }
}

// ─── Staff Card Widget ─────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.staff,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final Staff staff;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onView,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + status badge ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.fullName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff.position,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusCard(
                statusText: _statusLabel(staff.status),
                color: _statusColor(staff.status),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Details ──────────────────────────────────────────────────
          _detailRow(Icons.email_outlined, staff.email),
          const SizedBox(height: 6),
          _detailRow(Icons.phone_outlined, staff.phoneNumber),
          if (staff.assignedZone != null && staff.assignedZone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.location_on_outlined, staff.assignedZone!),
          ],
          const SizedBox(height: 14),

          // ── Actions ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(label: 'Edit', onPressed: onEdit),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppSecondaryButton(label: 'Delete', onPressed: onDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'on_leave':
        return 'On Leave';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return AppColors.lightGreen;
      case 'inactive':
        return const Color(0xFFFFEAEA);
      case 'on_leave':
        return const Color(0xFFFFF3E0);
      default:
        return AppColors.greenSurface;
    }
  }
}
