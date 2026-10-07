import 'package:flutter/material.dart';
import 'live_tracking_screen.dart';

class CollectionStatusScreen extends StatefulWidget {
  final bool isEmbedded;
  final String requestId;
  final int activeStage; // 0 to 4

  const CollectionStatusScreen({
    super.key,
    this.isEmbedded = false,
    this.requestId = 'SP-20260814-002',
    this.activeStage = 2, // Default: "In Progress"
  });

  @override
  State<CollectionStatusScreen> createState() => _CollectionStatusScreenState();
}

class _CollectionStatusScreenState extends State<CollectionStatusScreen> {
  late int _currentStage;

  final List<Map<String, dynamic>> _stages = [
    {
      'title': 'Request Received',
      'subtitle': 'System logged your waste request successfully.',
      'time': '10:15 AM, Aug 14',
      'icon': Icons.assignment_turned_in_outlined,
    },
    {
      'title': 'Assigned to Team',
      'subtitle': 'Assigned to Municipal Driver Nalin Perera.',
      'time': '11:30 AM, Aug 14',
      'icon': Icons.badge_outlined,
    },
    {
      'title': 'In Progress',
      'subtitle': 'Truck is en route to your residential pickup location.',
      'time': '01:45 PM, Aug 14',
      'icon': Icons.local_shipping_outlined,
      'hasAction': true,
    },
    {
      'title': 'Collected',
      'subtitle': 'Waste verified and loaded onto municipal vehicle.',
      'time': 'Pending confirmation',
      'icon': Icons.delete_sweep_outlined,
    },
    {
      'title': 'Completed',
      'subtitle': 'Disposal complete. Thank you for keeping our city clean!',
      'time': 'Pending final verification',
      'icon': Icons.task_alt_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentStage = widget.activeStage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                'Collection Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineCard(),
            const SizedBox(height: 20),
            // Progress banner matching Screen 3
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA5D6A7).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your collection is in progress.\nOur team is on the way!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _stages.length,
        itemBuilder: (context, index) {
          final isPast = index < _currentStage;
          final isCurrent = index == _currentStage;
          final isFuture = index > _currentStage;
          final stage = _stages[index];

          final Color iconBgColor = isPast || isCurrent
              ? const Color(0xFF2E7D32)
              : Colors.grey.shade300;
          final Color textColor = isFuture ? Colors.grey.shade400 : const Color(0xFF1B3B2B);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Column (Circle + Connector Line)
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2E7D32).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        stage['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (index < _stages.length - 1)
                      Expanded(
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: index < _currentStage
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Timeline Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stage['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: isFuture ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage['time'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isFuture ? Colors.grey.shade300 : Colors.grey.shade400,
                          ),
                        ),
                        // Direct Deep-Link from 'In Progress' to Live Tracking Screen
                        if (isCurrent && stage['hasAction'] == true) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LiveTrackingScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation, size: 16, color: Colors.white),
                            label: const Text(
                              'Track Live Truck on Map',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
