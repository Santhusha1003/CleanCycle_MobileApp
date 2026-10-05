import 'package:flutter/material.dart';

import '../models/collection_schedule.dart';
import '../services/collection_schedule_service.dart';

import 'collection_schedule_details_screen.dart';
import 'collection_calendar_screen.dart';
import 'waste_categories_screen.dart';
import 'collection_history_screen.dart';
import 'missed_collection_report_screen.dart';

class CollectionScheduleScreen extends StatefulWidget {
  const CollectionScheduleScreen({super.key});

  @override
  State<CollectionScheduleScreen> createState() =>
      _CollectionScheduleScreenState();
}

class _CollectionScheduleScreenState extends State<CollectionScheduleScreen> {
  final CollectionScheduleService _scheduleService =
      CollectionScheduleService();

  bool showThisWeek = true;

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
        '${date.day} ${months[date.month - 1]}';
  }

  // ============================================================
  // FILTER SCHEDULES
  // ============================================================

  List<CollectionSchedule> _filterSchedules(
    List<CollectionSchedule> schedules,
  ) {
    final now = DateTime.now();

    // THIS WEEK
    if (showThisWeek) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      final end = start.add(const Duration(days: 7));

      return schedules.where((schedule) {
        return !schedule.collectionDate.isBefore(start) &&
            schedule.collectionDate.isBefore(end);
      }).toList();
    }

    // THIS MONTH
    return schedules.where((schedule) {
      return schedule.collectionDate.year == now.year &&
          schedule.collectionDate.month == now.month;
    }).toList();
  }

  // ============================================================
  // OPEN COLLECTION DETAILS
  // ============================================================

  void _openScheduleDetails(CollectionSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CollectionScheduleDetailsScreen(schedule: schedule),
      ),
    );
  }

  // ============================================================
  // OPEN CALENDAR
  // ============================================================

  void _openCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CollectionCalendarScreen()),
    );
  }

  // ============================================================
  // OPEN RECYCLING GUIDE
  // ============================================================

  void _openRecyclingGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WasteCategoriesScreen()),
    );
  }

  // ============================================================
  // OPEN COLLECTION HISTORY
  // ============================================================

  void _openCollectionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CollectionHistoryScreen()),
    );
  }

  // ============================================================
  // OPEN MISSED COLLECTION REPORT
  // ============================================================

  void _openMissedCollectionReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MissedCollectionReportScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'Collection Schedule',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),

        actions: [
          // CALENDAR
          IconButton(
            tooltip: 'Collection Calendar',
            onPressed: _openCalendar,
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.black,
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          // ====================================================
          // THIS WEEK / THIS MONTH
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
                Expanded(
                  child: _filterButton(
                    title: 'This Week',
                    selected: showThisWeek,
                    onTap: () {
                      setState(() {
                        showThisWeek = true;
                      });
                    },
                  ),
                ),

                Expanded(
                  child: _filterButton(
                    title: 'This Month',
                    selected: !showThisWeek,
                    onTap: () {
                      setState(() {
                        showThisWeek = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // RECYCLING GUIDE
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _featureButton(
              icon: Icons.recycling,
              title: 'Recycling Guide',
              description: 'Learn how to separate your waste correctly.',
              backgroundColor: const Color(0xFFE8F5E9),
              borderColor: const Color(0xFFB7DFBF),
              onTap: _openRecyclingGuide,
            ),
          ),

          // ====================================================
          // COLLECTION HISTORY
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _featureButton(
              icon: Icons.history,
              title: 'Collection History',
              description: 'View your previous waste collections.',
              backgroundColor: Colors.white,
              borderColor: Colors.grey.shade300,
              onTap: _openCollectionHistory,
            ),
          ),

          // ====================================================
          // REPORT MISSED COLLECTION
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _featureButton(
              icon: Icons.report_problem_outlined,
              title: 'Report Missed Collection',
              description: 'Report a collection that did not happen.',
              backgroundColor: const Color(0xFFFFF8E1),
              borderColor: const Color(0xFFFFE0A3),
              onTap: _openMissedCollectionReport,
            ),
          ),

          // ====================================================
          // FIRESTORE SCHEDULE LIST
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
                        'Error loading schedules:\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // NO FIRESTORE DATA
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No collection schedules available.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                // FILTER
                final schedules = _filterSchedules(snapshot.data!);

                // SORT BY DATE
                schedules.sort(
                  (a, b) => a.collectionDate.compareTo(b.collectionDate),
                );

                // NO DATA FOR CURRENT FILTER
                if (schedules.isEmpty) {
                  return Center(
                    child: Text(
                      showThisWeek
                          ? 'No schedules for this week.'
                          : 'No schedules for this month.',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                // SHOW SCHEDULES
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  itemCount: schedules.length,

                  itemBuilder: (context, index) {
                    final schedule = schedules[index];

                    return _scheduleCard(schedule);
                  },
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

  Widget _filterButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),

        decoration: BoxDecoration(
          color: selected ? const Color(0xFF159447) : Colors.transparent,

          borderRadius: BorderRadius.circular(8),
        ),

        child: Text(
          title,
          textAlign: TextAlign.center,

          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FEATURE BUTTON
  // ============================================================

  Widget _featureButton({
    required IconData icon,
    required String title,
    required String description,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),

        child: Row(
          children: [
            // ICON
            Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),

              child: Icon(icon, color: const Color(0xFF159447), size: 27),
            ),

            const SizedBox(width: 12),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Color(0xFF159447)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCHEDULE CARD
  // ============================================================

  Widget _scheduleCard(CollectionSchedule schedule) {
    return Card(
      color: Colors.white,
      elevation: 1,

      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // ICON
        leading: Container(
          width: 48,
          height: 48,

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

        // DATE
        title: Text(
          _formatDate(schedule.collectionDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        // WASTE TYPE
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            schedule.wasteType,
            style: const TextStyle(color: Colors.black87),
          ),
        ),

        // ARROW
        trailing: const Icon(Icons.chevron_right),

        // OPEN DETAILS
        onTap: () {
          _openScheduleDetails(schedule);
        },
      ),
    );
  }
}
