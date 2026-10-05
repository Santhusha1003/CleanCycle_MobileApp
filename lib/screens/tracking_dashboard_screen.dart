import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tracking_service.dart';
import 'live_tracking_screen.dart';
import 'collection_status_screen.dart';
import 'report_missed_screen.dart';
import 'special_pickup_screen.dart';

class TrackingDashboardScreen extends StatefulWidget {
  const TrackingDashboardScreen({super.key});

  @override
  State<TrackingDashboardScreen> createState() => _TrackingDashboardScreenState();
}

class _TrackingDashboardScreenState extends State<TrackingDashboardScreen> {
  final TrackingService _trackingService = TrackingService();
  int _currentTabIndex = 0;
  Map<String, dynamic>? _nextCollection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _trackingService.fetchNextCollection('USR-2026-COL');
      if (mounted) {
        setState(() {
          _nextCollection = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: SafeArea(
        child: _currentTabIndex == 0
            ? _buildHomeDashboard()
            : _currentTabIndex == 1
                ? const LiveTrackingScreen(isEmbedded: true)
                : _currentTabIndex == 2
                    ? const CollectionStatusScreen(isEmbedded: true)
                    : _buildProfilePlaceholder(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF2E7D32),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildNextCollectionCard(),
            const SizedBox(height: 28),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3B2B),
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionTiles(),
            const SizedBox(height: 28),
            _buildRecentActivitySection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE8F5E9),
              child: const Icon(Icons.person, color: Color(0xFF2E7D32), size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello, Vishani!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3B2B),
                  ),
                ),
                Text(
                  'Zone 3 • Ward 12 Colombo',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF1B3B2B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new collection alerts')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNextCollectionCard() {
    if (_isLoading) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    final date = _nextCollection?['date'] as DateTime? ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d').format(date);
    final category = _nextCollection?['category'] ?? 'Recyclables';
    final timeWindow = _nextCollection?['timeWindow'] ?? '08:00 AM - 10:00 AM';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_filled, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'NEXT SCHEDULED PICKUP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.recycling, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.schedule, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                timeWindow,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
                );
              },
              icon: const Icon(Icons.navigation, size: 16, color: Color(0xFF1B5E20)),
              label: const Text(
                'Track Truck',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTiles() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        _buildActionTile(
          title: 'Track Collection',
          subtitle: 'Live Truck GPS',
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Report Missed',
          subtitle: 'Lodge Complaint',
          icon: Icons.report_problem_outlined,
          color: const Color(0xFFD84315),
          bgColor: const Color(0xFFFBE9E7),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportMissedScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Special Pickup',
          subtitle: 'Bulky Waste / E-Waste',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF0277BD),
          bgColor: const Color(0xFFE1F5FE),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpecialPickupScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Status Timeline',
          subtitle: '5-Stage Progression',
          icon: Icons.timeline,
          color: const Color(0xFF6A1B9A),
          bgColor: const Color(0xFFF3E5F5),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CollectionStatusScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3B2B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Collection Guidelines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3B2B),
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            Icons.check_circle_outline,
            'Place bins outside before 07:30 AM on collection days.',
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            Icons.check_circle_outline,
            'Separate electronic waste from regular municipal trash.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vishani Somarathna',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Resident ID: RES-COL-44360',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _currentTabIndex = 0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Return to Home', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) => setState(() => _currentTabIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: Colors.grey.shade500,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.navigation_outlined),
          activeIcon: Icon(Icons.navigation),
          label: 'Track',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fact_check_outlined),
          activeIcon: Icon(Icons.fact_check),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
