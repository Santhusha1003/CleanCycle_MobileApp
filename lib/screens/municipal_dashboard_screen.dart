import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_stat_card.dart';

class MunicipalDashboardScreen extends StatelessWidget {
  const MunicipalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      _QuickActionItem(
        title: 'Vehicle\nManagement',
        icon: Icons.local_shipping_outlined,
        routeName: AppRoutes.vehicleManagement,
      ),
      _QuickActionItem(
        title: 'Driver\nManagement',
        icon: Icons.drive_eta_outlined,
        routeName: AppRoutes.driverManagement,
      ),
      _QuickActionItem(
        title: 'Staff\nManagement',
        icon: Icons.people_alt_outlined,
        routeName: AppRoutes.staffManagement,
      ),
      _QuickActionItem(
        title: 'Schedule\nManagement',
        icon: Icons.calendar_today_outlined,
        routeName: AppRoutes.scheduleManagement,
      ),
      _QuickActionItem(
        title: 'Reports &\nAnalytics',
        icon: Icons.bar_chart_rounded,
        routeName: AppRoutes.reportsAnalytics,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Municipal Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Welcome back, Officer',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Operations Overview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.42,
                children: const [
                  AppStatCard(
                    title: 'Total Vehicles',
                    value: '48',
                    subtitle: 'Across 6 service zones',
                    icon: Icons.local_shipping_outlined,
                    iconBackground: AppColors.lightGreen,
                  ),
                  AppStatCard(
                    title: 'Active Drivers',
                    value: '24',
                    subtitle: '12 available today',
                    icon: Icons.drive_eta_outlined,
                    iconBackground: AppColors.greenSurface,
                  ),
                  AppStatCard(
                    title: 'Staff Members',
                    value: '31',
                    subtitle: '7 on duty now',
                    icon: Icons.people_alt_outlined,
                    iconBackground: AppColors.lightGreen,
                  ),
                  AppStatCard(
                    title: "Today's Collections",
                    value: '186',
                    subtitle: '12 routes scheduled',
                    icon: Icons.checklist_rounded,
                    iconBackground: AppColors.greenSurface,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Municipal Operations',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.05,
                children: quickActions.map((item) {
                  return AppCard(
                    onTap: () {
                      Navigator.pushNamed(context, item.routeName);
                    },
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.greenSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            color: AppColors.primaryDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.routeName,
  });

  final String title;
  final IconData icon;
  final String routeName;
}
