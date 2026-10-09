import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../navigation/municipal_shell.dart';
import '../services/municipal/municipal_analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/authenticated_user_greeting.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MunicipalDashboardScreen
// ─────────────────────────────────────────────────────────────────────────────

class MunicipalDashboardScreen extends StatefulWidget {
  const MunicipalDashboardScreen({super.key, this.analyticsService});

  final MunicipalAnalyticsService? analyticsService;

  @override
  State<MunicipalDashboardScreen> createState() =>
      _MunicipalDashboardScreenState();
}

class _MunicipalDashboardScreenState extends State<MunicipalDashboardScreen> {
  late final MunicipalAnalyticsService _analyticsService =
      widget.analyticsService ?? MunicipalAnalyticsService();

  bool _isLoading = true;
  String? _errorMessage;
  MunicipalAnalyticsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _safeMessage(e);
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
            // ── Compact header ─────────────────────────────────────────────
            _buildHeader(context),
            // ── Scrollable body ────────────────────────────────────────────
            Expanded(child: _buildScrollBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Notification bell (left)
          _IconBtn(
            icon: Icons.notifications_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          // CleanCycle branding (center)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CleanCycle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const Text(
                  'Municipal Operations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const AuthenticatedUserGreeting(textAlign: TextAlign.center),
              ],
            ),
          ),
          // Profile (right)
          _IconBtn(
            icon: Icons.account_circle_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
    );
  }

  // ── Scroll body ───────────────────────────────────────────────────────────
  Widget _buildScrollBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final s = _summary;
    if (s == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ────────────────────────────────────────────────
            const Text(
              'Municipal Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Monitor, manage and keep our city clean.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            // ── Today's Collection Status card ────────────────────────
            _CollectionStatusCard(summary: s),

            const SizedBox(height: 20),

            // ── 3 summary stat cards ──────────────────────────────────
            _buildSummaryRow(s),

            const SizedBox(height: 24),

            // ── Quick Actions ─────────────────────────────────────────
            _buildSectionHeading('Quick Actions'),
            const SizedBox(height: 12),
            _buildQuickActions(context),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────
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
              'Unable to load dashboard',
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
                onPressed: _loadData,
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

  // ── 3-column summary row ──────────────────────────────────────────────────
  Widget _buildSummaryRow(MunicipalAnalyticsSummary s) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.local_shipping_outlined,
            iconBg: AppColors.lightGreen,
            label: 'Vehicles\nin Operation',
            value: '${s.availableVehicles}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.drive_eta_outlined,
            iconBg: const Color(0xFFEAF4FF),
            label: 'Drivers\non Duty',
            value: '${s.assignedDrivers}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.warning_amber_rounded,
            iconBg: const Color(0xFFFFF3E0),
            label: 'Pending\nIssues',
            value: '${s.cancelledToday}',
          ),
        ),
      ],
    );
  }

  // ── Quick actions 2×2 grid ────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    const actions = [
      _ActionItem(
        label: 'Manage\nSchedule',
        icon: Icons.calendar_today_outlined,
        route: AppRoutes.scheduleManagement,
      ),
      _ActionItem(
        label: 'View\nReports',
        icon: Icons.bar_chart_rounded,
        route: AppRoutes.reportsAnalytics,
      ),
      _ActionItem(
        label: 'Manage\nVehicles',
        icon: Icons.local_shipping_outlined,
        route: AppRoutes.vehicleManagement,
      ),
      _ActionItem(
        label: 'Manage\nDrivers',
        icon: Icons.drive_eta_outlined,
        route: AppRoutes.driverManagement,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: actions.map((a) {
        return _QuickActionCard(
          item: a,
          onTap: () => MunicipalShell.navigate(context, a.route),
        );
      }).toList(),
    );
  }

  // ── Section heading ───────────────────────────────────────────────────────
  Widget _buildSectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static String _safeMessage(Object e) {
    final t = e.toString();
    if (t.contains('FirebaseServiceException')) {
      return 'Unable to load data. Please try again.';
    }
    return t;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's Collection Status card with custom donut
// ─────────────────────────────────────────────────────────────────────────────

class _CollectionStatusCard extends StatelessWidget {
  const _CollectionStatusCard({required this.summary});

  final MunicipalAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.todayCollections;
    final completed = summary.completedToday;
    final inProgress = summary.inProgressToday;
    // "Missed" = cancelled today
    final missed = summary.cancelledToday;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Collection Status",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  total == 0 ? 'No routes' : '$total routes',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Donut + legend row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut chart
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _DonutPainter(
                    completed: completed,
                    inProgress: inProgress,
                    missed: missed,
                    total: total,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DonutLegendRow(
                      color: AppColors.primary,
                      label: 'Completed',
                      count: completed,
                    ),
                    const SizedBox(height: 10),
                    _DonutLegendRow(
                      color: const Color(0xFF3A7BD5),
                      label: 'In Progress',
                      count: inProgress,
                    ),
                    const SizedBox(height: 10),
                    _DonutLegendRow(
                      color: AppColors.warning,
                      label: 'Missed',
                      count: missed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut chart painter
// ─────────────────────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.completed,
    required this.inProgress,
    required this.missed,
    required this.total,
  });

  final int completed;
  final int inProgress;
  final int missed;
  final int total;

  static const double _strokeWidth = 14.0;
  static const double _gap = 0.04; // radians between segments

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (math.min(size.width, size.height) / 2) - _strokeWidth / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total == 0) {
      // Empty ring
      paint.color = AppColors.border;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
      return;
    }

    final segments = [
      _Segment(completed, AppColors.primary),
      _Segment(inProgress, const Color(0xFF3A7BD5)),
      _Segment(missed, AppColors.warning),
    ];

    double startAngle = -math.pi / 2;

    for (final seg in segments) {
      if (seg.count <= 0) continue;
      final sweep = (seg.count / total) * (math.pi * 2) - _gap;
      if (sweep <= 0) continue;
      paint.color = seg.color;
      canvas.drawArc(rect, startAngle + _gap / 2, sweep, false, paint);
      startAngle += sweep + _gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.completed != completed ||
      old.inProgress != inProgress ||
      old.missed != missed ||
      old.total != total;
}

class _Segment {
  const _Segment(this.count, this.color);

  final int count;
  final Color color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut legend row
// ─────────────────────────────────────────────────────────────────────────────

class _DonutLegendRow extends StatelessWidget {
  const _DonutLegendRow({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-column summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick action card
// ─────────────────────────────────────────────────────────────────────────────

class _ActionItem {
  const _ActionItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.item, required this.onTap});

  final _ActionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
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
                child: Icon(item.icon, size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header icon button
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
