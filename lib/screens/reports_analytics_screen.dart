import 'package:flutter/material.dart';

import '../services/municipal/municipal_analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_card.dart';
import '../widgets/municipal/performance_charts.dart';
import '../widgets/common/app_primary_button.dart';
import '../navigation/app_routes.dart';
import '../widgets/common/authenticated_user_greeting.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key, this.analyticsService});

  final MunicipalAnalyticsService? analyticsService;

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  late final MunicipalAnalyticsService _analyticsService =
      widget.analyticsService ?? MunicipalAnalyticsService();

  bool _isLoading = true;
  String? _errorMessage;
  MunicipalAnalyticsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Notifications',
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primaryDark,
          ),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notifications),
        ),
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'CleanCycle',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Municipal Operations',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            SizedBox(height: 2),
            AuthenticatedUserGreeting(textAlign: TextAlign.center),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAnalytics,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryDark,
            ),
            tooltip: 'Refresh',
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.primaryDark,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

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

  // ─── Error state ───────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AppCard(
          padding: const EdgeInsets.all(24),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(label: 'Retry', onPressed: _loadAnalytics),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Main content ──────────────────────────────────────────────────────────

  Widget _buildContent(MunicipalAnalyticsSummary s) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection Analytics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Overview of municipal collection performance.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 18),
            _buildDateScope(),
            const SizedBox(height: 20),
            _buildStatusSection(
              title: 'Collection Performance',
              icon: Icons.insights_outlined,
              totalLabel: 'Total collections today',
              total: s.todayCollections,
              rows: [
                ('Completed', s.completedToday, AppColors.primary),
                ('In Progress', s.inProgressToday, const Color(0xFF9B6500)),
                ('Scheduled', s.scheduledToday, AppColors.info),
                ('Cancelled', s.cancelledToday, AppColors.error),
              ],
              emptyMessage: 'No collections scheduled for today.',
            ),
            const SizedBox(height: 24),
            const _SectionHeading(
              icon: Icons.dashboard_outlined,
              label: 'Operations Snapshot',
            ),
            const SizedBox(height: 12),
            _buildMetricGrid([
              (
                'Total Vehicles',
                s.totalVehicles,
                Icons.local_shipping_outlined,
              ),
              (
                'Available Vehicles',
                s.availableVehicles,
                Icons.check_circle_outline,
              ),
              ('Total Drivers', s.totalDrivers, Icons.drive_eta_outlined),
              ('Available Drivers', s.availableDrivers, Icons.person_outline),
              ('Total Staff', s.totalStaff, Icons.groups_outlined),
              ('Active Staff', s.activeStaff, Icons.badge_outlined),
              ("Today's Collections", s.todayCollections, Icons.today_outlined),
              ('Completed', s.completedToday, Icons.task_alt),
              ('In Progress', s.inProgressToday, Icons.timelapse),
              ('Cancelled', s.cancelledToday, Icons.cancel_outlined),
            ]),
            const SizedBox(height: 24),
            VehiclePerformanceChart(
              collections: s.completedCollectionsByVehicleToday,
            ),
            const SizedBox(height: 16),
            // Existing schedules record assignments, not completed route history.
            const DriverPerformanceChart(),
            const SizedBox(height: 16),
            _buildStatusSection(
              title: 'Vehicle Status',
              icon: Icons.local_shipping_outlined,
              totalLabel: 'Total vehicles',
              total: s.totalVehicles,
              rows: [
                ('Available', s.availableVehicles, AppColors.primary),
                (
                  'In Maintenance',
                  s.maintenanceVehicles,
                  const Color(0xFF9B6500),
                ),
              ],
              emptyMessage: 'No vehicles recorded.',
            ),
            const SizedBox(height: 16),
            _buildStatusSection(
              title: 'Driver Overview',
              icon: Icons.drive_eta_outlined,
              totalLabel: 'Total drivers',
              total: s.totalDrivers,
              rows: [
                ('Available', s.availableDrivers, AppColors.primary),
                ('Assigned', s.assignedDrivers, AppColors.info),
              ],
              emptyMessage: 'No drivers recorded.',
            ),
            const SizedBox(height: 16),
            _buildStatusSection(
              title: 'Staff Overview',
              icon: Icons.groups_outlined,
              totalLabel: 'Total staff',
              total: s.totalStaff,
              rows: [('Active', s.activeStaff, AppColors.primary)],
              emptyMessage: 'No staff recorded.',
            ),
            const SizedBox(height: 24),
            const _SectionHeading(
              icon: Icons.recycling_outlined,
              label: 'Collections by Waste Type',
            ),
            const SizedBox(height: 12),
            _buildBreakdownCard(
              data: s.collectionsByWasteType,
              labelMapper: _wasteTypeLabel,
              emptyMessage: 'No collections today by waste type.',
              total: s.todayCollections,
            ),
            const SizedBox(height: 24),
            const _SectionHeading(
              icon: Icons.location_on_outlined,
              label: 'Collections by Zone',
            ),
            const SizedBox(height: 12),
            _buildBreakdownCard(
              data: s.collectionsByZone,
              labelMapper: (key) => key,
              emptyMessage: 'No collections today by zone.',
              total: s.todayCollections,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateScope() {
    final now = DateTime.now();
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
    final date =
        '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
    // Analytics currently supports today only. Keep the scope explicit;
    // do not expose a date picker that cannot filter the underlying metrics.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: "Today's collection overview",
          child: AppCard(
            color: AppColors.greenSurface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_outlined,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Today · $date',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Collections today · current fleet and team totals',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMetricGrid(List<(String, int, IconData)> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 280 ? 1 : 2;
        return Column(
          children: [
            for (var index = 0; index < metrics.length; index += columns)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var offset = 0;
                        offset < columns && index + offset < metrics.length;
                        offset++
                      ) ...[
                        if (offset > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: metrics[index + offset].$1,
                            count: metrics[index + offset].$2,
                            icon: metrics[index + offset].$3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusSection({
    required String title,
    required IconData icon,
    required String totalLabel,
    required int total,
    required List<(String, int, Color)> rows,
    required String emptyMessage,
  }) {
    return AppCard(
      color: AppColors.white,
      elevation: 0.5,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(icon: icon, label: title),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    totalLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$total',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final row in rows)
            _BreakdownRow(
              label: row.$1,
              count: row.$2,
              fraction: total > 0 ? (row.$2 / total).clamp(0.0, 1.0) : 0,
              color: row.$3,
            ),
          if (total == 0)
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Breakdown card (waste type / zone rows) ───────────────────────────────

  Widget _buildBreakdownCard({
    required Map<String, int> data,
    required String Function(String) labelMapper,
    required String emptyMessage,
    required int total,
  }) {
    // Filter to non-zero entries for a cleaner display; keep all if all zero
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hasData = entries.any((e) => e.value > 0);

    if (!hasData) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: entries.map((entry) {
          final fraction = total > 0
              ? (entry.value / total).clamp(0.0, 1.0)
              : 0.0;
          return _BreakdownRow(
            label: labelMapper(entry.key),
            count: entry.value,
            fraction: fraction,
          );
        }).toList(),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _wasteTypeLabel(String type) {
    switch (type.trim().toLowerCase()) {
      case 'general':
        return 'General';
      case 'recyclable':
        return 'Recyclable';
      case 'organic':
        return 'Organic';
      case 'mixed':
        return 'Mixed';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  static String _safeErrorMessage(Object exception) {
    final text = exception.toString();
    if (text.contains('FirebaseServiceException')) {
      return 'Unable to load analytics right now. Please try again.';
    }
    return text;
  }
}

// ─── Section heading ───────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Breakdown row (label + bar + count) ──────────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.fraction,
    this.color = AppColors.primary,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.count,
    required this.icon,
  });
  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 0.5,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 18),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
