import 'package:flutter/material.dart';

import '../screens/driver_management_screen.dart';
import '../screens/municipal_dashboard_screen.dart';
import '../screens/reports_analytics_screen.dart';
import '../screens/staff_management_screen.dart';
import '../screens/vehicle_management_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/common/municipal_bottom_navigation.dart';
import 'app_routes.dart';

/// One Municipal tab layout. Visited screens stay mounted to retain their
/// search, scroll and screen state instead of pushing duplicate tab routes.
class MunicipalShell extends StatefulWidget {
  const MunicipalShell({
    super.key,
    this.initialRoute = AppRoutes.municipalDashboard,
  });

  final String initialRoute;

  static const routes = [
    AppRoutes.municipalDashboard,
    AppRoutes.vehicleManagement,
    AppRoutes.driverManagement,
    AppRoutes.staffManagement,
    AppRoutes.reportsAnalytics,
  ];

  static void navigate(BuildContext context, String route) {
    final shell = context.findAncestorStateOfType<_MunicipalShellState>();
    final index = routes.indexOf(route);
    if (shell != null && index >= 0) {
      shell.selectTab(index);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  static void backToDashboard(BuildContext context) {
    final shell = context.findAncestorStateOfType<_MunicipalShellState>();
    if (shell != null) {
      shell.selectTab(0);
    } else {
      final navigator = Navigator.of(context);
      var foundDashboard = false;
      navigator.popUntil((route) {
        foundDashboard = route.settings.name == AppRoutes.municipalDashboard;
        return foundDashboard || route.isFirst;
      });
      // A directly opened management screen may have no dashboard beneath it.
      if (!foundDashboard) {
        navigator.pushReplacementNamed(AppRoutes.municipalDashboard);
      }
    }
  }

  @override
  State<MunicipalShell> createState() => _MunicipalShellState();
}

class _MunicipalShellState extends State<MunicipalShell> {
  static const _screens = [
    MunicipalDashboardScreen(),
    VehicleManagementScreen(),
    DriverManagementScreen(),
    StaffManagementScreen(),
    ReportsAnalyticsScreen(),
  ];

  late int _index;
  final _visited = <int>{};

  @override
  void initState() {
    super.initState();
    final initialIndex = MunicipalShell.routes.indexOf(widget.initialRoute);
    _index = initialIndex < 0 ? 0 : initialIndex;
    _visited.add(_index);
  }

  void selectTab(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) selectTab(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        // Each existing screen owns its Scaffold and keyboard/form layout.
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _index,
          children: List.generate(
            _screens.length,
            (index) => TickerMode(
              enabled: index == _index,
              child: _visited.contains(index)
                  ? _screens[index]
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        bottomNavigationBar: MunicipalBottomNavigation(
          activeIndex: _index,
          onTap: selectTab,
        ),
      ),
    );
  }
}
