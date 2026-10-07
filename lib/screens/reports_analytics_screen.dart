import 'package:flutter/material.dart';

import '../services/municipal/municipal_analytics_service.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static chart data (UI placeholders — replace with real service data later)
// ─────────────────────────────────────────────────────────────────────────────

const List<_VehicleBar> _kVehicleBars = [
  _VehicleBar(id: 'V001', trips: 36),
  _VehicleBar(id: 'V002', trips: 28),
  _VehicleBar(id: 'V003', trips: 22),
  _VehicleBar(id: 'V004', trips: 16),
  _VehicleBar(id: 'V005', trips: 12),
];

const double _kBarMax = 40.0;

const List<_DriverRow> _kDriverRows = [
  _DriverRow(label: 'Driver 1', routes: 48),
  _DriverRow(label: 'Driver 2', routes: 42),
  _DriverRow(label: 'Driver 3', routes: 38),
  _DriverRow(label: 'Driver 4', routes: 25),
  _DriverRow(label: 'Driver 5', routes: 20),
];

const int _kDriverMax = 50;

// ─────────────────────────────────────────────────────────────────────────────
// Data holders
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleBar {
  const _VehicleBar({required this.id, required this.trips});
  final String id;
  final int trips;
}

class _DriverRow {
  const _DriverRow({required this.label, required this.routes});
  final String label;
  final int routes;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  // ── Service (existing — preserved) ────────────────────────────────────────
  final MunicipalAnalyticsService _analyticsService =
      MunicipalAnalyticsService();

  bool _isLoading = true;
  String? _errorMessage;
  MunicipalAnalyticsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await _analyticsService.getMunicipalAnalyticsSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } on Exception catch (exception) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _safeErrorMessage(exception);
        _isLoading = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Top header (CleanCycle branding — mirrors dashboard) ──────────────────
  Widget _buildTopHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Notification icon (left)
          _IconBtn(icon: Icons.notifications_outlined, onTap: () {}),
          // CleanCycle branding (center)
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CleanCycle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  'Clean Today, Greener Tomorrow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // Placeholder to balance the row
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ── Body (loading / error / content) ─────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    final summary = _summary;
    if (summary == null) {
      return _buildErrorState();
    }
    return _buildContent(summary);
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load analytics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loadAnalytics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MunicipalAnalyticsSummary summary) {
    // Derive summary-card values from live data where available, otherwise
    // fall back to static UI placeholder values shown in the reference.
    final totalCollections = summary.todayCollections > 0
        ? summary.todayCollections
        : 1245;
    final completed = summary.completedToday > 0
        ? summary.completedToday
        : 1120;
    final missed = summary.cancelledToday > 0 ? summary.cancelledToday : 65;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page title ───────────────────────────────────────────
            const Text(
              'Collection Analytics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Overview of municipal collection performance.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 18),

            // ── Date range selector ───────────────────────────────────
            _DateRangeSelector(),

            const SizedBox(height: 20),

            // ── Summary cards 2×2 ─────────────────────────────────────
            _buildSummaryCards(
              totalCollections: totalCollections,
              completed: completed,
              missed: missed,
            ),

            const SizedBox(height: 20),

            // ── Vehicle Performance chart ──────────────────────────────
            _VehiclePerformanceCard(),

            const SizedBox(height: 16),

            // ── Driver Performance bars ────────────────────────────────
            _DriverPerformanceCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards({
    required int totalCollections,
    required int completed,
    required int missed,
  }) {
    final completionPct = totalCollections > 0
        ? (completed / totalCollections * 100).round()
        : 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _SummaryCard(
          icon: Icons.checklist_rounded,
          iconBg: AppColors.lightGreen,
          iconColor: AppColors.primary,
          label: 'Total Collections',
          value: '$totalCollections',
          badge: '+4.8%',
          badgeBg: AppColors.lightGreen,
          badgeTextColor: AppColors.primaryDark,
        ),
        _SummaryCard(
          icon: Icons.check_circle_outline_rounded,
          iconBg: AppColors.lightGreen,
          iconColor: AppColors.primary,
          label: 'Completed',
          value: '$completed',
          badge: '$completionPct%',
          badgeBg: AppColors.lightGreen,
          badgeTextColor: AppColors.primaryDark,
        ),
        _SummaryCard(
          icon: Icons.warning_amber_rounded,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: AppColors.warning,
          label: 'Missed',
          value: '$missed',
          badge: '-2.1%',
          badgeBg: const Color(0xFFFFF3E0),
          badgeTextColor: AppColors.warning,
        ),
        const _SummaryCard(
          icon: Icons.feedback_outlined,
          iconBg: Color(0xFFEAF4FF),
          iconColor: Color(0xFF3A7BD5),
          label: 'Complaints',
          value: '18',
          badge: 'Low',
          badgeBg: Color(0xFFEAF4FF),
          badgeTextColor: Color(0xFF3A7BD5),
        ),
      ],
    );
  }

  static String _safeErrorMessage(Object exception) {
    final text = exception.toString();
    if (text.contains('FirebaseServiceException')) {
      return 'Unable to load analytics right now. Please try again.';
    }
    return text;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date range selector
// ─────────────────────────────────────────────────────────────────────────────

class _DateRangeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Range',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '01 Sep 2026 – 30 Sep 2026',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card (2×2 grid item)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeBg,
    required this.badgeTextColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String badge;
  final Color badgeBg;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + badge row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Value + label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Performance — vertical bar chart card
// ─────────────────────────────────────────────────────────────────────────────

class _VehiclePerformanceCard extends StatelessWidget {
  const _VehiclePerformanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Vehicle Performance',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Trips / Day',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar chart
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _kVehicleBars.map((bar) {
                final fraction = bar.trips / _kBarMax;
                return _VerticalBar(
                  id: bar.id,
                  trips: bar.trips,
                  fraction: fraction,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),

          // Bottom labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scale: 0 – 40 units',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '5 active units',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single vertical bar
// ─────────────────────────────────────────────────────────────────────────────

class _VerticalBar extends StatelessWidget {
  const _VerticalBar({
    required this.id,
    required this.trips,
    required this.fraction,
  });

  final String id;
  final int trips;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    // Each bar occupies equal horizontal space
    const double maxBarHeight = 110.0;
    final double barH = (maxBarHeight * fraction).clamp(4.0, maxBarHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Value label above bar
        Text(
          '$trips',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        // Bar
        Container(
          width: 36,
          height: barH,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        // Vehicle ID below bar
        Text(
          id,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Driver Performance — horizontal progress bars card
// ─────────────────────────────────────────────────────────────────────────────

class _DriverPerformanceCard extends StatelessWidget {
  const _DriverPerformanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Driver Performance',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Routes Completed',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress rows
          ..._kDriverRows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HorizontalBar(
                label: row.label,
                value: row.routes,
                max: _kDriverMax,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single horizontal bar row
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalBar extends StatelessWidget {
  const _HorizontalBar({
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        // Driver label
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: AppColors.greenSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Value label
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header icon button (mirrors dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.greenSurface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryDark),
      ),
    );
  }
}
