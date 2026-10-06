import 'package:flutter/material.dart';

import '../models/collection_schedule.dart';
import '../services/collection_schedule_service.dart';
import 'collection_schedule_details_screen.dart';

class CollectionHistoryScreen extends StatefulWidget {
  const CollectionHistoryScreen({super.key});

  @override
  State<CollectionHistoryScreen> createState() =>
      _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState extends State<CollectionHistoryScreen> {
  final CollectionScheduleService _scheduleService =
      CollectionScheduleService();

  String _selectedFilter = 'All';

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
  // HISTORY CHECK
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

    return scheduleDate.isBefore(today) ||
        status == 'completed' ||
        status == 'missed';
  }

  // ============================================================
  // FILTER HISTORY
  // ============================================================

  List<CollectionSchedule> _filterHistory(List<CollectionSchedule> schedules) {
    final history = schedules.where(_isHistorySchedule).toList();

    if (_selectedFilter == 'Completed') {
      return history.where((schedule) {
        return schedule.status.toLowerCase() == 'completed';
      }).toList();
    }

    if (_selectedFilter == 'Missed') {
      return history.where((schedule) {
        return schedule.status.toLowerCase() == 'missed';
      }).toList();
    }

    return history;
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

      body: Column(
        children: [
          // ====================================================
          // FILTER TABS
          // ====================================================

          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(child: _filterButton('All')),
                Expanded(child: _filterButton('Completed')),
                Expanded(child: _filterButton('Missed')),
              ],
            ),
          ),

          // ====================================================
          // FIRESTORE HISTORY
          // ====================================================
          Expanded(
            child: StreamBuilder<List<CollectionSchedule>>(
              stream: _scheduleService.getSchedules(),

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

                // NO FIRESTORE DATA
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyHistory();
                }

                // FILTER HISTORY
                final historySchedules = _filterHistory(snapshot.data!);

                // NEWEST FIRST
                historySchedules.sort(
                  (a, b) => b.collectionDate.compareTo(a.collectionDate),
                );

                // NO RESULTS FOR FILTER
                if (historySchedules.isEmpty) {
                  return _emptyHistory();
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  children: [
                    // ==========================================
                    // INFO CARD
                    // ==========================================

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: Color(0xFF159447)),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              _selectedFilter == 'All'
                                  ? 'View your previous waste collections.'
                                  : _selectedFilter == 'Completed'
                                  ? 'View your completed collections.'
                                  : 'View your missed collections.',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==========================================
                    // COUNT
                    // ==========================================
                    Text(
                      '${historySchedules.length} '
                      '${historySchedules.length == 1 ? 'Collection' : 'Collections'}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // HISTORY CARDS
                    // ==========================================
                    ...historySchedules.map(
                      (schedule) => _historyCard(context, schedule),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _filterButton(String title) {
    final selected = _selectedFilter == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF159447) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    String message;

    if (_selectedFilter == 'Completed') {
      message = 'No completed collections found.';
    } else if (_selectedFilter == 'Missed') {
      message = 'No missed collections found.';
    } else {
      message = 'Your previous collection schedules will appear here.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == 'Missed'
                  ? Icons.report_problem_outlined
                  : Icons.history,
              size: 60,
              color: Colors.grey,
            ),

            const SizedBox(height: 16),

            Text(
              _selectedFilter == 'All'
                  ? 'No Collection History'
                  : 'No $_selectedFilter Collections',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
