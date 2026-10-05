import 'package:flutter/material.dart';

import '../models/collection_schedule.dart';
import '../services/collection_schedule_service.dart';
import 'collection_schedule_details_screen.dart';

class CollectionHistoryScreen extends StatelessWidget {
  const CollectionHistoryScreen({super.key});

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

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // WASTE ICON
  // ============================================================

  IconData _getWasteIcon(String wasteType) {
    final type = wasteType.toLowerCase();

    if (type.contains('recyclable')) {
      return Icons.recycling;
    }

    if (type.contains('organic')) {
      return Icons.compost;
    }

    if (type.contains('plastic')) {
      return Icons.local_drink_outlined;
    }

    if (type.contains('paper')) {
      return Icons.description_outlined;
    }

    if (type.contains('glass')) {
      return Icons.wine_bar_outlined;
    }

    if (type.contains('metal')) {
      return Icons.inventory_2_outlined;
    }

    return Icons.delete_outline;
  }

  // ============================================================
  // CHECK WHETHER SCHEDULE BELONGS TO HISTORY
  // ============================================================

  bool _isHistorySchedule(CollectionSchedule schedule) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final scheduleDate = DateTime(
      schedule.collectionDate.year,
      schedule.collectionDate.month,
      schedule.collectionDate.day,
    );

    final status = schedule.status.toLowerCase();

    return scheduleDate.isBefore(today) || status == 'completed';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF159447);

      case 'missed':
        return Colors.redAccent;

      case 'cancelled':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final CollectionScheduleService scheduleService =
        CollectionScheduleService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Collection History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<List<CollectionSchedule>>(
        stream: scheduleService.getSchedules(),

        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading collection history:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // NO DATA
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyHistory();
          }

          // FILTER HISTORY
          final historySchedules = snapshot.data!
              .where(_isHistorySchedule)
              .toList();

          // NEWEST FIRST
          historySchedules.sort(
            (a, b) => b.collectionDate.compareTo(a.collectionDate),
          );

          // NO HISTORY
          if (historySchedules.isEmpty) {
            return _emptyHistory();
          }

          // HISTORY LIST
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // INFO CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF159447)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'View your previous waste collection schedules.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                '${historySchedules.length} '
                '${historySchedules.length == 1 ? 'Collection' : 'Collections'}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...historySchedules.map(
                (schedule) => _historyCard(context, schedule),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================

  Widget _historyCard(BuildContext context, CollectionSchedule schedule) {
    final statusColor = _getStatusColor(schedule.status);

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CollectionScheduleDetailsScreen(schedule: schedule),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ICON
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getWasteIcon(schedule.wasteType),
                  color: const Color(0xFF159447),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              // DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.wasteType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            _formatDate(schedule.collectionDate),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 15,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          '${schedule.startTime} - '
                          '${schedule.endTime}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // STATUS
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        schedule.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY HISTORY
  // ============================================================

  Widget _emptyHistory() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey),

            SizedBox(height: 16),

            Text(
              'No Collection History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            Text(
              'Your previous collection schedules '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
