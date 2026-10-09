import 'package:flutter/material.dart';

import '../services/municipal/municipal_analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_primary_button.dart';
import '../widgets/common/app_stat_card.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
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

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _analyticsService.getMunicipalAnalyticsSummary();
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } on Exception catch (exception) {
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
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Refresh button — always visible
          IconButton(
            onPressed: _isLoading ? null : _loadAnalytics,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryDark,
            ),
            tooltip: 'Refresh',
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

  Widget _buildContent(MunicipalAnalyticsSummary summary) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Subtitle ──────────────────────────────────────────────
            const Text(
              'Municipal operations at a glance',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // ── Vehicles ─────────────────────────────────────────────
            _SectionHeading(
              icon: Icons.local_shipping_outlined,
              label: 'Vehicles',
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              children: [
                AppStatCard(
                  title: 'Total Vehicles',
                  value: '${summary.totalVehicles}',
                  icon: Icons.local_shipping_outlined,
                  iconBackground: AppColors.lightGreen,
                ),
                AppStatCard(
                  title: 'Available',
                  value: '${summary.availableVehicles}',
                  icon: Icons.check_circle_outline_rounded,
                  iconBackground: AppColors.greenSurface,
                ),
                AppStatCard(
                  title: 'In Maintenance',
                  value: '${summary.maintenanceVehicles}',
                  icon: Icons.build_outlined,
                  iconBackground: const Color(0xFFFFF3E0),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Drivers ───────────────────────────────────────────────
            _SectionHeading(icon: Icons.drive_eta_outlined, label: 'Drivers'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              children: [
                AppStatCard(
                  title: 'Total Drivers',
                  value: '${summary.totalDrivers}',
                  icon: Icons.drive_eta_outlined,
                  iconBackground: AppColors.lightGreen,
                ),
                AppStatCard(
                  title: 'Available',
                  value: '${summary.availableDrivers}',
                  icon: Icons.check_circle_outline_rounded,
                  iconBackground: AppColors.greenSurface,
                ),
                AppStatCard(
                  title: 'Assigned',
                  value: '${summary.assignedDrivers}',
                  icon: Icons.assignment_ind_outlined,
                  iconBackground: const Color(0xFFEAF4FF),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Staff ─────────────────────────────────────────────────
            _SectionHeading(icon: Icons.people_alt_outlined, label: 'Staff'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              children: [
                AppStatCard(
                  title: 'Total Staff',
                  value: '${summary.totalStaff}',
                  icon: Icons.people_alt_outlined,
                  iconBackground: AppColors.lightGreen,
                ),
                AppStatCard(
                  title: 'Active',
                  value: '${summary.activeStaff}',
                  icon: Icons.person_rounded,
                  iconBackground: AppColors.greenSurface,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Today's Collections ───────────────────────────────────
            _SectionHeading(
              icon: Icons.today_outlined,
              label: "Today's Collections",
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              children: [
                AppStatCard(
                  title: 'Total Today',
                  value: '${summary.todayCollections}',
                  icon: Icons.checklist_rounded,
                  iconBackground: AppColors.lightGreen,
                ),
                AppStatCard(
                  title: 'Completed',
                  value: '${summary.completedToday}',
                  icon: Icons.check_circle_outline_rounded,
                  iconBackground: AppColors.greenSurface,
                ),
                AppStatCard(
                  title: 'Scheduled',
                  value: '${summary.scheduledToday}',
                  icon: Icons.calendar_today_outlined,
                  iconBackground: const Color(0xFFEAF4FF),
                ),
                AppStatCard(
                  title: 'In Progress',
                  value: '${summary.inProgressToday}',
                  icon: Icons.play_circle_outline_rounded,
                  iconBackground: AppColors.lightGreen,
                ),
                AppStatCard(
                  title: 'Cancelled',
                  value: '${summary.cancelledToday}',
                  icon: Icons.cancel_outlined,
                  iconBackground: const Color(0xFFFFEAEA),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Collections by Waste Type ─────────────────────────────
            _SectionHeading(
              icon: Icons.delete_outline_rounded,
              label: 'Collections by Waste Type',
            ),
            const SizedBox(height: 12),
            _buildBreakdownCard(
              data: summary.collectionsByWasteType,
              labelMapper: _wasteTypeLabel,
              emptyMessage: 'No collections today by waste type.',
              total: summary.todayCollections,
            ),
            const SizedBox(height: 24),

            // ── Collections by Zone ───────────────────────────────────
            _SectionHeading(
              icon: Icons.location_on_outlined,
              label: 'Collections by Zone',
            ),
            const SizedBox(height: 12),
            _buildBreakdownCard(
              data: summary.collectionsByZone,
              labelMapper: (key) => key,
              emptyMessage: 'No collections today by zone.',
              total: summary.todayCollections,
            ),
          ],
        ),
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
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
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
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
  });

  final String label;
  final int count;
  final double fraction;

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
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
