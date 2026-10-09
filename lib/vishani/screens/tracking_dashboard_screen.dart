import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/common/authenticated_user_greeting.dart';
import '../services/tracking_service.dart';
import 'live_tracking_screen.dart';
import 'collection_status_screen.dart';
import 'report_missed_screen.dart';
import 'special_pickup_screen.dart';
import 'driver_profile_screen.dart';
import '../../services/municipal/driver_service.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/auth_controller.dart';

class TrackingDashboardScreen extends StatefulWidget {
  const TrackingDashboardScreen({super.key, this.driverService});

  final DriverService? driverService;

  @override
  State<TrackingDashboardScreen> createState() =>
      _TrackingDashboardScreenState();
}

class _TrackingDashboardScreenState extends State<TrackingDashboardScreen> {
  final TrackingService _trackingService = TrackingService();
  int _currentTabIndex = 0;
  Map<String, dynamic>? _nextCollection;
  bool _isLoading = true;
  String? _dashboardUid;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.watch<AuthController>().firebaseUser?.uid;
    if (!_started || uid != _dashboardUid) {
      _started = true;
      _dashboardUid = uid;
      _nextCollection = null;
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final uid = context.read<AuthController>().firebaseUser?.uid;
      final data = uid == null
          ? <String, dynamic>{}
          : await _trackingService.fetchNextCollection(uid);
      if (mounted && uid == _dashboardUid) {
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
            ? const SpecialPickupScreen(isEmbedded: true)
            : DriverProfileScreen(driverService: widget.driverService),
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
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.pushNamed(context, AppRoutes.driverProfile),
          child: const Tooltip(
            message: 'Profile',
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 26),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthenticatedUserGreeting(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3B2B),
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "Let's keep our city clean",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 14),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF1B3B2B),
              size: 22,
            ),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ),
      ],
    );
  }

  Widget _buildNextCollectionCard() {
    if (_isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final date = _nextCollection?['date'] as DateTime?;
    final formattedDate = date == null
        ? ''
        : DateFormat('EEEE, d MMM yyyy').format(date);
    final category =
        _nextCollection?['category'] ?? 'No assigned collection available';
    final timeWindow = _nextCollection?['timeWindow'] ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Next Collection',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        timeWindow,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTiles() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _buildActionTile(
          title: 'Track Collection',
          icon: Icons.location_on,
          iconColor: const Color(0xFF2E7D32),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Report Missed\nCollection',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red.shade600,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportMissedScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Special Pickup\nRequest',
          icon: Icons.local_shipping,
          iconColor: const Color(0xFF2E7D32),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpecialPickupScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'View Status',
          icon: Icons.article_outlined,
          iconColor: const Color(0xFF2E7D32),
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
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3B2B),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      children: [
        // Clean Communities Banner matching Screen 1
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFA5D6A7).withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Clean Communities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Brighter Tomorrows',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/clean_communities.jpg',
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.eco, size: 48, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) => setState(() => _currentTabIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: Colors.grey.shade500,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
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
