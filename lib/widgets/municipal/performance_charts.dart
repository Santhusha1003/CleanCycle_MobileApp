import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/app_card.dart';

// Positive, recorded counts only; alphabetical tie-breaking keeps refresh stable.
List<MapEntry<String, int>> _ranked(Map<String, int> counts) =>
    counts.entries
        .where((entry) => entry.key.trim().isNotEmpty && entry.value > 0)
        .toList()
      ..sort((a, b) {
        final comparison = b.value.compareTo(a.value);
        return comparison == 0 ? a.key.compareTo(b.key) : comparison;
      });

class VehiclePerformanceChart extends StatelessWidget {
  const VehiclePerformanceChart({super.key, required this.collections});

  final Map<String, int> collections;

  @override
  Widget build(BuildContext context) {
    final entries = _ranked(collections);
    final maximum = entries.isEmpty ? 0 : entries.first.value;
    return _ChartCard(
      title: 'Vehicle Performance',
      subtitle: 'Trips / Day',
      note: 'Completed collections today. Individual trips are not recorded.',
      child: entries.isEmpty
          ? const _ChartEmpty(
              message:
                  'No completed collections with a vehicle assignment today.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Many vehicles remain readable through horizontal scrolling.
                    final width = math.max(
                      constraints.maxWidth,
                      entries.length * 88.0,
                    );
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: width,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final entry in entries)
                              Expanded(
                                child: Semantics(
                                  label:
                                      '${entry.key}: ${entry.value} completed collections today',
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 170,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${entry.value}',
                                              style: _countStyle,
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              key: ValueKey(
                                                'vehicle-bar-${entry.key}',
                                              ),
                                              width: 30,
                                              height:
                                                  126 * entry.value / maximum,
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppColors.secondaryGreen,
                                                    AppColors.primary,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      top: Radius.circular(7),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 1,
                                        color: AppColors.border,
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          entry.key,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Scale: 0–$maximum collections/day · Active vehicles in chart: ${entries.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}

class DriverPerformanceChart extends StatelessWidget {
  const DriverPerformanceChart({super.key, this.completedRoutes = const {}});

  // Supply only independently recorded completed-route totals. The current
  // tracking model and schedule assignments do not provide this information.
  final Map<String, int> completedRoutes;

  @override
  Widget build(BuildContext context) {
    final entries = _ranked(completedRoutes);
    final maximum = entries.isEmpty ? 0 : entries.first.value;
    return _ChartCard(
      title: 'Driver Performance',
      subtitle: 'Routes Completed',
      child: entries.isEmpty
          ? const _ChartEmpty(
              message:
                  'Completed-route history is not recorded yet. Driver assignments are not completed-route counts.',
            )
          : Column(
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Semantics(
                      label: '${entry.key}: ${entry.value} routes completed',
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                key: ValueKey('driver-bar-${entry.key}'),
                                value: entry.value / maximum,
                                minHeight: 10,
                                backgroundColor: const Color(0xFFEDF1EE),
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${entry.value}', style: _countStyle),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

const _countStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: AppColors.primaryDark,
);

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.note,
  });
  final String title;
  final String subtitle;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.white,
    elevation: 0.5,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(
            note!,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        const Icon(
          Icons.bar_chart_rounded,
          color: AppColors.secondaryGreen,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
