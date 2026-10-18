import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/collection_schedule.dart';
import '../services/collection_schedule_reminder_service.dart';

class CollectionScheduleDetailsScreen extends StatefulWidget {
  final CollectionSchedule schedule;
  final CollectionScheduleReminderService? reminderService;

  const CollectionScheduleDetailsScreen({
    super.key,
    required this.schedule,
    this.reminderService,
  });

  @override
  State<CollectionScheduleDetailsScreen> createState() =>
      _CollectionScheduleDetailsScreenState();
}

class _CollectionScheduleDetailsScreenState
    extends State<CollectionScheduleDetailsScreen> {
  bool _schedulingReminder = false;

  CollectionSchedule get schedule => widget.schedule;

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // SET REMINDER
  // ============================================================

  Future<void> _setReminder() async {
    setState(() => _schedulingReminder = true);
    var success = false;
    String? error;
    try {
      await (widget.reminderService ?? LocalCollectionScheduleReminderService())
          .scheduleReminder(schedule);
      success = true;
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _schedulingReminder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Reminder scheduled for ${schedule.wasteType}.'
              : 'Could not set reminder: $error',
        ),
        backgroundColor: success
            ? const Color(0xFF159447)
            : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(String value) {
    for (final pattern in ['H:mm', 'h:mm a']) {
      try {
        return DateFormat(
          'h:mm a',
        ).format(DateFormat(pattern).parseStrict(value));
      } on FormatException {
        // Preserve the actual stored value if it is not a supported time.
      }
    }
    return value;
  }

  IconData _wasteIcon(String value) {
    final category = value.toLowerCase();
    if (category.contains('organic') || category.contains('food')) {
      return Icons.compost_outlined;
    }
    if (category.contains('plastic')) return Icons.local_drink_outlined;
    if (category.contains('paper')) return Icons.description_outlined;
    if (category.contains('glass')) return Icons.wine_bar_outlined;
    if (category.contains('electronic') || category.contains('e-waste')) {
      return Icons.devices_other_outlined;
    }
    return Icons.recycling;
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
          'Collection Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // WASTE TYPE
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _wasteIcon(schedule.wasteType),
                      color: Color(0xFF159447),
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waste Type',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          schedule.wasteType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // COLLECTION DATE
            // ==================================================
            _buildInfoCard(
              icon: Icons.calendar_today_outlined,
              title: 'Collection Date',
              value: _formatDate(schedule.collectionDate),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // COLLECTION TIME
            // ==================================================
            _buildInfoCard(
              icon: Icons.access_time,
              title: 'Collection Time',
              value:
                  '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
            ),

            const SizedBox(height: 12),

            // ==================================================
            // STATUS
            // ==================================================
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Status',
              value: schedule.status.toUpperCase(),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // ACCEPTED ITEMS
            // ==================================================
            const Text(
              'Accepted Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),

              child: schedule.acceptedItems.isEmpty
                  ? const Text(
                      'No accepted items listed.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      children: schedule.acceptedItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF159447),
                                size: 20,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // INSTRUCTIONS
            // ==================================================
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.orange),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      schedule.instructions.isEmpty
                          ? 'No special instructions.'
                          : schedule.instructions,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // ==================================================
            // SET REMINDER BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _schedulingReminder ? null : _setReminder,
                icon: _schedulingReminder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.notifications_active_outlined),
                label: Text(
                  _schedulingReminder ? 'Scheduling…' : 'Set Reminder',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF159447),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF159447), size: 22),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
