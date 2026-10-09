import 'package:flutter/material.dart';

import '../models/collection_schedule.dart';
import '../services/collection_schedule_service.dart';
import '../services/missed_collection_report_service.dart';

class MissedCollectionReportScreen extends StatefulWidget {
  const MissedCollectionReportScreen({
    super.key,
    this.scheduleService,
    this.reportService,
  });

  final CollectionScheduleService? scheduleService;
  final MissedCollectionReportService? reportService;

  @override
  State<MissedCollectionReportScreen> createState() =>
      _MissedCollectionReportScreenState();
}

class _MissedCollectionReportScreenState
    extends State<MissedCollectionReportScreen> {
  late final CollectionScheduleService _scheduleService =
      widget.scheduleService ?? CollectionScheduleService();

  late final MissedCollectionReportService _reportService =
      widget.reportService ?? MissedCollectionReportService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();

  // Store the Firestore document ID instead of the whole object.
  String? _selectedScheduleId;
  String? _selectedReason;

  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Collection vehicle did not arrive',
    'Waste was not collected',
    'Collection was incomplete',
    'Other',
  ];

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // SUBMIT REPORT
  // ============================================================

  Future<void> _submitReport(
    List<CollectionSchedule> availableSchedules,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a collection schedule.')),
      );
      return;
    }

    // Find the selected schedule using its unique Firestore ID.
    CollectionSchedule? selectedSchedule;

    for (final schedule in availableSchedules) {
      if (schedule.id == _selectedScheduleId) {
        selectedSchedule = schedule;
        break;
      }
    }

    if (selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected schedule is no longer available.'),
        ),
      );
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a reason.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportId = await _reportService.submitReport(
        scheduleId: selectedSchedule.id,
        wasteType: selectedSchedule.wasteType,
        collectionDate: selectedSchedule.collectionDate,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      debugPrint('Missed collection report created: $reportId');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missed collection report submitted successfully.'),
        ),
      );

      // Clear the form.
      setState(() {
        _selectedScheduleId = null;
        _selectedReason = null;
        _descriptionController.clear();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Report Missed Collection',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<List<CollectionSchedule>>(
        stream: _scheduleService.getSchedules(),

        builder: (context, snapshot) {
          // ====================================================
          // LOADING
          // ====================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading schedules:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final schedules = snapshot.data ?? <CollectionSchedule>[];

          // ====================================================
          // GET PREVIOUS / COMPLETED SCHEDULES
          // ====================================================

          final now = DateTime.now();

          final today = DateTime(now.year, now.month, now.day);

          final availableSchedules = schedules.where((schedule) {
            final scheduleDate = DateTime(
              schedule.collectionDate.year,
              schedule.collectionDate.month,
              schedule.collectionDate.day,
            );

            return scheduleDate.isBefore(today) ||
                schedule.status.toLowerCase() == 'completed';
          }).toList();

          // Newest schedule first.
          availableSchedules.sort(
            (a, b) => b.collectionDate.compareTo(a.collectionDate),
          );

          // Make sure the selected ID still exists.
          final selectedIdExists =
              _selectedScheduleId != null &&
              availableSchedules.any(
                (schedule) => schedule.id == _selectedScheduleId,
              );

          final safeSelectedScheduleId = selectedIdExists
              ? _selectedScheduleId
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================================
                  // INFORMATION CARD
                  // =============================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),

                        SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            'Use this form if a scheduled '
                            'waste collection was missed.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =============================================
                  // COLLECTION SCHEDULE
                  // =============================================
                  const Text(
                    'Collection Schedule',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: safeSelectedScheduleId,

                    isExpanded: true,

                    decoration: InputDecoration(
                      hintText: 'Select collection schedule',

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),

                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),

                    items: availableSchedules
                        .map(
                          (schedule) => DropdownMenuItem<String>(
                            value: schedule.id,

                            child: Text(
                              '${_formatDate(schedule.collectionDate)} '
                              '- ${schedule.wasteType}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),

                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedScheduleId = value;
                            });
                          },

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a collection schedule.';
                      }

                      return null;
                    },
                  ),

                  if (availableSchedules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),

                      child: Text(
                        'No previous collection schedules available.',
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // =============================================
                  // REASON
                  // =============================================
                  const Text(
                    'Reason',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,

                    isExpanded: true,

                    decoration: InputDecoration(
                      hintText: 'Select reason',

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),

                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),

                    items: _reasons
                        .map(
                          (reason) => DropdownMenuItem<String>(
                            value: reason,

                            child: Text(
                              reason,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),

                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedReason = value;
                            });
                          },

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a reason.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // =============================================
                  // DESCRIPTION
                  // =============================================
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _descriptionController,

                    enabled: !_isSubmitting,

                    maxLines: 5,
                    maxLength: 300,

                    decoration: InputDecoration(
                      hintText: 'Describe what happened...',

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),

                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description.';
                      }

                      if (value.trim().length < 10) {
                        return 'Please provide more details.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // =============================================
                  // SUBMIT BUTTON
                  // =============================================
                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton.icon(
                      onPressed: availableSchedules.isEmpty || _isSubmitting
                          ? null
                          : () {
                              _submitReport(availableSchedules);
                            },

                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),

                      label: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Report',

                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF159447),

                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
