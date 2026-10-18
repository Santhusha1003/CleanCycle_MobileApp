import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class MunicipalBottomNavigation extends StatelessWidget {
  const MunicipalBottomNavigation({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    _NavItem(label: 'Vehicles', icon: Icons.local_shipping_outlined),
    _NavItem(label: 'Drivers', icon: Icons.drive_eta_outlined),
    _NavItem(label: 'Staff', icon: Icons.people_alt_outlined),
    _NavItem(label: 'Reports', icon: Icons.bar_chart_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final active = i == activeIndex;
              return Semantics(
                selected: active,
                button: true,
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _items[i].icon,
                          size: 22,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Active indicator dot
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: active ? 18 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
