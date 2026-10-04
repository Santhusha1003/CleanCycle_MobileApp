import 'package:flutter/material.dart';

import '../models/collection_schedule.dart';
import '../services/municipal/schedule_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_primary_button.dart';
import '../widgets/common/app_search_field.dart';
import '../widgets/common/app_secondary_button.dart';
import '../widgets/common/app_status_card.dart';
import '../widgets/common/app_text_field.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<CollectionSchedule> _schedules = const <CollectionSchedule>[];
  List<CollectionSchedule> _filteredSchedules = const <CollectionSchedule>[];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schedules = await _scheduleService.getSchedules();
      setState(() {
        _schedules = schedules;
        _filteredSchedules = _applyFilter(_schedules, _searchController.text);
        _isLoading = false;
      });
    } on Exception catch (exception) {
      setState(() {
        _errorMessage = _safeErrorMessage(exception);
        _isLoading = false;
      });
    }
  }

  List<CollectionSchedule> _applyFilter(
    List<CollectionSchedule> source,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((s) {
      final fields = [
        s.zone,
        s.wasteType,
        s.status,
        s.assignedVehicleId ?? '',
        s.assignedDriverId ?? '',
      ];
      return fields.any((f) => f.toLowerCase().contains(q));
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filteredSchedules = _applyFilter(_schedules, value);
    });
  }

  // ─── ID generation ─────────────────────────────────────────────────────────

  String _generateScheduleId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'schedule_$timestamp';
  }

  // ─── Add / Edit form ───────────────────────────────────────────────────────

  Future<void> _showScheduleForm({CollectionSchedule? schedule}) async {
    final isEditing = schedule != null;
    final formKey = GlobalKey<FormState>();

    final scheduleIdController = TextEditingController(
      text: schedule?.scheduleId ?? _generateScheduleId(),
    );
    final zoneController = TextEditingController(text: schedule?.zone ?? '');
    final vehicleController = TextEditingController(
      text: schedule?.assignedVehicleId ?? '',
    );
    final driverController = TextEditingController(
      text: schedule?.assignedDriverId ?? '',
    );
    final notesController = TextEditingController(text: schedule?.notes ?? '');

    DateTime selectedDate = schedule?.collectionDate ?? DateTime.now();
    TimeOfDay selectedStartTime = schedule != null
        ? _parseTime(schedule.startTime)
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay selectedEndTime = schedule != null
        ? _parseTime(schedule.endTime)
        : const TimeOfDay(hour: 17, minute: 0);
    String wasteTypeValue = schedule?.wasteType ?? 'general';
    String statusValue = schedule?.status ?? 'scheduled';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
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
                                  isEditing ? 'Edit Schedule' : 'Add Schedule',
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

                          // ── Schedule ID (read-only when editing) ─────────
                          AppTextField(
                            controller: scheduleIdController,
                            label: 'Schedule ID',
                            hintText: 'schedule_123',
                            readOnly: isEditing,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Schedule ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Zone ─────────────────────────────────────────
                          AppTextField(
                            controller: zoneController,
                            label: 'Zone',
                            hintText: 'e.g. North Zone',
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Zone is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Collection Date ───────────────────────────────
                          _SectionLabel(label: 'Collection Date'),
                          const SizedBox(height: 6),
                          AppSecondaryButton(
                            label: 'Date: ${_formatDate(selectedDate)}',
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Start / End time ──────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel(label: 'Start Time'),
                                    const SizedBox(height: 6),
                                    AppSecondaryButton(
                                      label: _formatTime(selectedStartTime),
                                      onPressed: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: selectedStartTime,
                                          builder: (context, child) =>
                                              MediaQuery(
                                                data: MediaQuery.of(context)
                                                    .copyWith(
                                                      alwaysUse24HourFormat:
                                                          true,
                                                    ),
                                                child: child!,
                                              ),
                                        );
                                        if (picked != null) {
                                          setModalState(
                                            () => selectedStartTime = picked,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel(label: 'End Time'),
                                    const SizedBox(height: 6),
                                    AppSecondaryButton(
                                      label: _formatTime(selectedEndTime),
                                      onPressed: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: selectedEndTime,
                                          builder: (context, child) =>
                                              MediaQuery(
                                                data: MediaQuery.of(context)
                                                    .copyWith(
                                                      alwaysUse24HourFormat:
                                                          true,
                                                    ),
                                                child: child!,
                                              ),
                                        );
                                        if (picked != null) {
                                          setModalState(
                                            () => selectedEndTime = picked,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Waste Type ────────────────────────────────────
                          DropdownButtonFormField<String>(
                            initialValue:
                                ScheduleService.allowedWasteTypes.contains(
                                  wasteTypeValue,
                                )
                                ? wasteTypeValue
                                : 'general',
                            decoration: const InputDecoration(
                              labelText: 'Waste Type',
                              border: OutlineInputBorder(),
                            ),
                            items: ScheduleService.allowedWasteTypes
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w,
                                    child: Text(_wasteTypeLabel(w)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => wasteTypeValue = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Status ────────────────────────────────────────
                          DropdownButtonFormField<String>(
                            initialValue:
                                ScheduleService.allowedStatuses.contains(
                                  statusValue,
                                )
                                ? statusValue
                                : 'scheduled',
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: ScheduleService.allowedStatuses
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

                          // ── Assigned Vehicle (optional) ───────────────────
                          AppTextField(
                            controller: vehicleController,
                            label: 'Assigned Vehicle ID (optional)',
                            hintText: 'e.g. ABC-1234',
                          ),
                          const SizedBox(height: 12),

                          // ── Assigned Driver (optional) ────────────────────
                          AppTextField(
                            controller: driverController,
                            label: 'Assigned Driver ID (optional)',
                            hintText: 'e.g. driver_123',
                          ),
                          const SizedBox(height: 12),

                          // ── Notes (optional) ──────────────────────────────
                          AppTextField(
                            controller: notesController,
                            label: 'Notes (optional)',
                            hintText: 'Any additional notes...',
                            maxLines: 3,
                            minLines: 2,
                          ),
                          const SizedBox(height: 20),

                          // ── Submit ────────────────────────────────────────
                          AppPrimaryButton(
                            label: isEditing
                                ? 'Update Schedule'
                                : 'Save Schedule',
                            isLoading: false,
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              // Validate end time is not before start time
                              final startMinutes =
                                  selectedStartTime.hour * 60 +
                                  selectedStartTime.minute;
                              final endMinutes =
                                  selectedEndTime.hour * 60 +
                                  selectedEndTime.minute;
                              if (endMinutes <= startMinutes) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'End time must be after start time.',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              final schedulePayload = CollectionSchedule(
                                scheduleId: scheduleIdController.text.trim(),
                                zone: zoneController.text.trim(),
                                collectionDate: selectedDate,
                                startTime: _formatTime(selectedStartTime),
                                endTime: _formatTime(selectedEndTime),
                                wasteType: wasteTypeValue,
                                assignedVehicleId: _normalizeOptional(
                                  vehicleController.text,
                                ),
                                assignedDriverId: _normalizeOptional(
                                  driverController.text,
                                ),
                                status: statusValue,
                                notes: _normalizeOptional(notesController.text),
                                createdAt:
                                    schedule?.createdAt ?? DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              // Capture before async gap
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              final navigator = Navigator.of(sheetContext);

                              String successMessage;

                              try {
                                if (isEditing) {
                                  await _scheduleService.updateSchedule(
                                    scheduleId: schedule.scheduleId,
                                    schedule: schedulePayload,
                                  );
                                  successMessage =
                                      'Schedule updated successfully.';
                                } else {
                                  await _scheduleService.createSchedule(
                                    schedule: schedulePayload,
                                  );
                                  successMessage =
                                      'Schedule created successfully.';
                                }
                              } on ScheduleServiceException catch (exception) {
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
                              await _loadSchedules();
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

  void _showScheduleDetail(CollectionSchedule schedule) {
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
                Icons.calendar_today_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                schedule.zone,
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
              _dialogRow('Schedule ID', schedule.scheduleId),
              _dialogRow('Date', _formatDate(schedule.collectionDate)),
              _dialogRow('Time', '${schedule.startTime} – ${schedule.endTime}'),
              _dialogRow('Waste Type', _wasteTypeLabel(schedule.wasteType)),
              if (schedule.assignedVehicleId != null &&
                  schedule.assignedVehicleId!.isNotEmpty)
                _dialogRow('Vehicle', schedule.assignedVehicleId!),
              if (schedule.assignedDriverId != null &&
                  schedule.assignedDriverId!.isNotEmpty)
                _dialogRow('Driver', schedule.assignedDriverId!),
              if (schedule.notes != null && schedule.notes!.isNotEmpty)
                _dialogRow('Notes', schedule.notes!),
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
                    statusText: _statusLabel(schedule.status),
                    color: _statusColor(schedule.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _dialogRow('Created', _formatDateTime(schedule.createdAt)),
              _dialogRow('Updated', _formatDateTime(schedule.updatedAt)),
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
              _showScheduleForm(schedule: schedule);
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

  Widget _dialogRow(String label, String value) {
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

  Future<void> _confirmDelete(CollectionSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text(
          'Delete the schedule for "${schedule.zone}" on '
          '${_formatDate(schedule.collectionDate)}? '
          'This action cannot be undone.',
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
      await _scheduleService.deleteSchedule(scheduleId: schedule.scheduleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadSchedules();
    } on ScheduleServiceException catch (exception) {
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
          'Schedule Management',
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
                'Manage waste collection schedules',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // ── Search / Filter ───────────────────────────────────────
              AppSearchField(
                controller: _searchController,
                hintText:
                    'Filter by zone, waste type, status, vehicle, driver...',
                onChanged: _onSearchChanged,
                onClear: () => _onSearchChanged(''),
              ),
              const SizedBox(height: 16),

              // ── Add button ────────────────────────────────────────────
              AppPrimaryButton(
                label: 'Add Schedule',
                onPressed: () => _showScheduleForm(),
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
              else if (_filteredSchedules.isEmpty)
                _buildEmptyState()
              else
                _buildScheduleList(),
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
                'Unable to load schedules',
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
              AppPrimaryButton(label: 'Retry', onPressed: _loadSchedules),
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
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 40,
              ),
              SizedBox(height: 12),
              Text(
                'No schedules found',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your filter or add a new schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return Expanded(
      child: ListView.separated(
        itemCount: _filteredSchedules.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final schedule = _filteredSchedules[index];
          return _ScheduleCard(
            schedule: schedule,
            onView: () => _showScheduleDetail(schedule),
            onEdit: () => _showScheduleForm(schedule: schedule),
            onDelete: () => _confirmDelete(schedule),
          );
        },
      ),
    );
  }

  // ─── Static helpers ────────────────────────────────────────────────────────

  static String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'scheduled':
        return const Color(0xFFEAF4FF);
      case 'in_progress':
        return AppColors.lightGreen;
      case 'completed':
        return AppColors.greenSurface;
      case 'cancelled':
        return const Color(0xFFFFEAEA);
      default:
        return AppColors.greenSurface;
    }
  }

  static String _wasteTypeLabel(String type) {
    switch (type.trim().toLowerCase()) {
      case 'general':
        return 'General';
      case 'recyclable':
        return 'Recyclable';
      case 'organic':
        return 'Organic';
      case 'mixed':
        return 'Mixed';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year}  $hour:$minute';
  }

  static String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  static String? _normalizeOptional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String _safeErrorMessage(Object exception) {
    final text = exception.toString();
    if (text.startsWith('ScheduleServiceException:')) {
      return text.replaceFirst('ScheduleServiceException: ', '');
    }
    if (text.contains('FirebaseServiceException')) {
      return 'Unable to load schedules right now. Please try again.';
    }
    return text;
  }
}

// ─── Section label helper ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Schedule Card Widget ──────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final CollectionSchedule schedule;
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
          // ── Zone + Status ────────────────────────────────────────────
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
                  Icons.calendar_today_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.zone,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _wasteTypeLabel(schedule.wasteType),
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
                statusText: _statusLabel(schedule.status),
                color: _statusColor(schedule.status),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Date & Time row ──────────────────────────────────────────
          _detailRow(
            Icons.calendar_month_outlined,
            _formatDate(schedule.collectionDate),
          ),
          const SizedBox(height: 6),
          _detailRow(
            Icons.access_time_rounded,
            '${schedule.startTime} – ${schedule.endTime}',
          ),
          if (schedule.assignedVehicleId != null &&
              schedule.assignedVehicleId!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(
              Icons.local_shipping_outlined,
              schedule.assignedVehicleId!,
            ),
          ],
          if (schedule.assignedDriverId != null &&
              schedule.assignedDriverId!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.person_outlined, schedule.assignedDriverId!),
          ],
          if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.notes_outlined, schedule.notes!),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'scheduled':
        return const Color(0xFFEAF4FF);
      case 'in_progress':
        return AppColors.lightGreen;
      case 'completed':
        return AppColors.greenSurface;
      case 'cancelled':
        return const Color(0xFFFFEAEA);
      default:
        return AppColors.greenSurface;
    }
  }

  static String _wasteTypeLabel(String type) {
    switch (type.trim().toLowerCase()) {
      case 'general':
        return 'General';
      case 'recyclable':
        return 'Recyclable';
      case 'organic':
        return 'Organic';
      case 'mixed':
        return 'Mixed';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
