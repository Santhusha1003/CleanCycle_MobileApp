import 'package:flutter/material.dart';

import '../models/collection_schedule.dart';
import '../services/collection_schedule_service.dart';
import '../services/missed_collection_report_service.dart';
import 'missed_collection_report_details_screen.dart';
import 'missed_collection_reports_screen.dart';

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

  String? _selectedReason;
  DateTime? _selectedCollectionDate;

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

  Future<void> _selectCollectionDate() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedCollectionDate == null
        ? today
        : DateTime(
            _selectedCollectionDate!.year,
            _selectedCollectionDate!.month,
            _selectedCollectionDate!.day,
          );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          initialDate.isBefore(firstDayOfMonth) || initialDate.isAfter(today)
          ? today
          : initialDate,
      firstDate: firstDayOfMonth,
      lastDate: today,
      helpText: 'Select missed collection date',
      confirmText: 'Select',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCollectionDate = selectedDate;
    });
  }

  // ============================================================
  // SUBMIT REPORT
  // ============================================================

  void _openReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MissedCollectionReportsScreen(reportService: _reportService),
      ),
    );
  }

  Future<void> _submitReport(
    List<CollectionSchedule> availableSchedules,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCollectionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the missed collection date.'),
        ),
      );
      return;
    }

    // Find the schedule that matches the selected calendar date.
    CollectionSchedule? selectedSchedule;

    for (final schedule in availableSchedules) {
      final scheduleDate = DateTime(
        schedule.collectionDate.year,
        schedule.collectionDate.month,
        schedule.collectionDate.day,
      );

      if (scheduleDate.year == _selectedCollectionDate!.year &&
          scheduleDate.month == _selectedCollectionDate!.month &&
          scheduleDate.day == _selectedCollectionDate!.day) {
        selectedSchedule = schedule;
        break;
      }
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
        scheduleId: selectedSchedule?.id ?? '',
        wasteType: selectedSchedule?.wasteType ?? 'Not specified',
        collectionDate:
            selectedSchedule?.collectionDate ?? _selectedCollectionDate!,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      debugPrint('Missed collection report created: $reportId');

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MissedCollectionReportDetailsScreen(
            reportId: reportId,
            wasteType: selectedSchedule?.wasteType ?? 'Not specified',
            collectionDate:
                selectedSchedule?.collectionDate ?? _selectedCollectionDate!,
            reason: _selectedReason!,
            description: _descriptionController.text.trim(),
          ),
        ),
      );
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
        actions: [
          TextButton(
            onPressed: _openReports,
            child: const Text(
              'View Reports',
              style: TextStyle(
                color: Color(0xFF159447),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          // GET SCHEDULES FOR THE SELECTED DATE
          // ====================================================

          final availableSchedules = schedules.where((schedule) {
            final scheduleDate = DateTime(
              schedule.collectionDate.year,
              schedule.collectionDate.month,
              schedule.collectionDate.day,
            );

            final matchesSelectedDate =
                _selectedCollectionDate == null ||
                (scheduleDate.year == _selectedCollectionDate!.year &&
                    scheduleDate.month == _selectedCollectionDate!.month &&
                    scheduleDate.day == _selectedCollectionDate!.day);

            return matchesSelectedDate;
          }).toList();

          // Newest schedule first.
          availableSchedules.sort(
            (a, b) => b.collectionDate.compareTo(a.collectionDate),
          );

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
                  // MISSED COLLECTION DATE
                  // =============================================
                  const Text(
                    'Missed Collection Date',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap: _isSubmitting ? null : _selectCollectionDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        hintText: 'Select a date from this month',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(Icons.calendar_month_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        _selectedCollectionDate == null
                            ? 'Select a date from this month'
                            : _formatDate(_selectedCollectionDate!),
                        style: TextStyle(
                          color: _selectedCollectionDate == null
                              ? Colors.black54
                              : Colors.black87,
                        ),
                      ),
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
                      onPressed: _isSubmitting
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
