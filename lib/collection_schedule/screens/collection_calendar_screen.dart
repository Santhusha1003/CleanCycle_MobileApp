import 'package:flutter/material.dart';

import '../models/collection_schedule.dart';
import '../services/collection_schedule_service.dart';
import 'collection_schedule_details_screen.dart';

class CollectionCalendarScreen extends StatefulWidget {
  const CollectionCalendarScreen({super.key});

  @override
  State<CollectionCalendarScreen> createState() =>
      _CollectionCalendarScreenState();
}

class _CollectionCalendarScreenState extends State<CollectionCalendarScreen> {
  final CollectionScheduleService _scheduleService =
      CollectionScheduleService();

  late DateTime _selectedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(now.year, now.month);
  }

  // =========================
  // MONTH NAME
  // =========================

  String _monthName(int month) {
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

    return months[month - 1];
  }

  // =========================
  // DATE FORMAT
  // =========================

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

  // =========================
  // CHECK SAME DATE
  // =========================

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // =========================
  // PREVIOUS MONTH
  // =========================

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);

      _selectedDate = null;
    });
  }

  // =========================
  // NEXT MONTH
  // =========================

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);

      _selectedDate = null;
    });
  }

  // =========================
  // OPEN DETAILS
  // =========================

  void _openDetails(CollectionSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CollectionScheduleDetailsScreen(schedule: schedule),
      ),
    );
  }

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
          'Collection Calendar',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<List<CollectionSchedule>>(
        stream: _scheduleService.getSchedules(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading calendar:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final schedules = snapshot.data ?? <CollectionSchedule>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // =========================
                // MONTH HEADER
                // =========================

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.chevron_left),
                      ),

                      Expanded(
                        child: Text(
                          '${_monthName(_selectedMonth.month)} '
                          '${_selectedMonth.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // CALENDAR
                // =========================
                _buildCalendar(schedules),

                const SizedBox(height: 24),

                // =========================
                // SELECTED DATE SCHEDULES
                // =========================
                _buildSelectedDateSchedules(schedules),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================
  // CALENDAR
  // =========================

  Widget _buildCalendar(List<CollectionSchedule> schedules) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);

    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    // Monday = 1
    final emptyCells = firstDay.weekday - 1;

    final totalCells = emptyCells + daysInMonth;

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Week day names
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 4),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < emptyCells) {
                return const SizedBox();
              }

              final day = index - emptyCells + 1;

              final date = DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                day,
              );

              final hasSchedule = schedules.any(
                (schedule) => _isSameDate(schedule.collectionDate, date),
              );

              final selected =
                  _selectedDate != null && _isSameDate(_selectedDate!, date);

              return InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF159447)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),

                      if (hasSchedule)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF159447),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // SELECTED DATE DATA
  // =========================

  Widget _buildSelectedDateSchedules(List<CollectionSchedule> schedules) {
    if (_selectedDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.calendar_month, color: Color(0xFF159447), size: 32),
            SizedBox(height: 8),
            Text(
              'Select a date to view collection schedules.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final selectedSchedules = schedules.where((schedule) {
      return _isSameDate(schedule.collectionDate, _selectedDate!);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDate(_selectedDate!),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        if (selectedSchedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'No collection scheduled for this date.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...selectedSchedules.map((schedule) {
            return Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.recycling, color: Color(0xFF159447)),
                ),

                title: Text(
                  schedule.wasteType,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Text(
                  '${schedule.startTime} - '
                  '${schedule.endTime}',
                ),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  _openDetails(schedule);
                },
              ),
            );
          }),
      ],
    );
  }
}
