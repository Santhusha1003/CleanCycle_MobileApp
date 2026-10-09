import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';

import '../models/collection_schedule.dart';
import '../services/collection_schedule_service.dart';
import '../widgets/collection_bottom_nav.dart';

import 'collection_schedule_details_screen.dart';
import 'collection_calendar_screen.dart';
import 'waste_categories_screen.dart';
import 'recycling_tips_screen.dart';
import 'collection_history_screen.dart';
import 'missed_collection_report_screen.dart';

class CollectionScheduleScreen extends StatefulWidget {
  const CollectionScheduleScreen({super.key, this.scheduleService});

  final CollectionScheduleService? scheduleService;

  @override
  State<CollectionScheduleScreen> createState() =>
      _CollectionScheduleScreenState();
}

class _CollectionScheduleScreenState extends State<CollectionScheduleScreen> {
  late final CollectionScheduleService _scheduleService =
      widget.scheduleService ?? CollectionScheduleService();

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
  // OPEN WASTE CATEGORIES
  // ============================================================

  void _openWasteCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WasteCategoriesScreen()),
    );
  }

  // ============================================================
  // OPEN RECYCLING TIPS
  // ============================================================

  void _openRecyclingTips() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecyclingTipsScreen()),
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
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        title: const Text(
          'Collection Schedule',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Collection Calendar',
              onPressed: _openCalendar,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.greenSurface,
                foregroundColor: CollectionBottomNav.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 22),
            ),
          ),
        ],
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================
      bottomNavigationBar: const CollectionBottomNav(currentIndex: 1),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // ====================================================
              // THIS WEEK / THIS MONTH
              // ====================================================
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(14),
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
              // WASTE CATEGORIES
              // ====================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _featureButton(
                  icon: Icons.category_outlined,
                  title: 'Waste Categories',
                  description: 'Learn about different types of waste.',
                  backgroundColor: AppColors.greenSurface,
                  onTap: _openWasteCategories,
                ),
              ),

              // ====================================================
              // RECYCLING GUIDE
              // ====================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _featureButton(
                  icon: Icons.recycling,
                  title: 'Recycling Guide',
                  description: 'Simple tips for a greener tomorrow.',
                  backgroundColor: AppColors.greenSurface,
                  onTap: _openRecyclingTips,
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
                  onTap: _openMissedCollectionReport,
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Collections',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // ====================================================
              // FIRESTORE SCHEDULE LIST
              // ====================================================
              Padding(
                padding: const EdgeInsets.only(top: 8),
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
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    // SHOW SCHEDULES
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
        ),
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
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? CollectionBottomNav.primaryGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    required VoidCallback onTap,
  }) {
    final amber = title == 'Report Missed Collection';
    final accent = amber
        ? const Color(0xFF946200)
        : CollectionBottomNav.primaryGreen;
    return AppCard(
      color: backgroundColor,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: amber ? const Color(0xFFFFEFC8) : AppColors.lightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCHEDULE CARD
  // ============================================================

  Widget _scheduleCard(CollectionSchedule schedule) {
    final time = [
      schedule.startTime.trim(),
      schedule.endTime.trim(),
    ].where((value) => value.isNotEmpty).join(' – ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _openScheduleDetails(schedule),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getWasteIcon(schedule.wasteType),
                    color: CollectionBottomNav.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(schedule.collectionDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if (schedule.wasteType.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  schedule.wasteType,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
            if (time.isNotEmpty || schedule.status.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (time.isNotEmpty)
                    _scheduleDetail(Icons.schedule_outlined, time),
                  if (schedule.status.trim().isNotEmpty)
                    _scheduleDetail(
                      Icons.check_circle_outline,
                      schedule.status,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scheduleDetail(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}
