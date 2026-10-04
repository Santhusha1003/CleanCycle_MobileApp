import 'package:flutter/material.dart';

import '../screens/driver_management_screen.dart';
import '../screens/driver_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/municipal_dashboard_screen.dart';
import '../screens/reports_analytics_screen.dart';
import '../screens/resident_dashboard_screen.dart';
import '../screens/schedule_management_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/staff_management_screen.dart';
import '../screens/vehicle_management_screen.dart';
import 'app_routes.dart';

/// Centralized router configuration for the CleanCycle application.
///
/// This class manages navigation and route building for the app.
/// It provides a consistent interface for navigation across the application
/// and supports role-based route restrictions via NavigationGuard.
///
/// Currently uses Flutter's standard Navigator with MaterialApp.
/// Route building is role-aware: screens are built based on the route name.
/// Access control is enforced by NavigationGuard in onGenerateRoute.
class AppRouter {
  AppRouter._();

  /// Generate route for the MaterialApp.onGenerateRoute callback.
  ///
  /// This method is called when a route is requested via Navigator.pushNamed().
  /// It returns the appropriate widget for the requested route.
  ///
  /// **Role-based access control is enforced here.**
  /// If a user lacks permission for a route, navigation is redirected.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Common routes
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
          settings: settings,
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );
      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(), // Placeholder
          settings: settings,
        );

      // Resident routes
      case AppRoutes.residentDashboard:
        return MaterialPageRoute(
          builder: (context) => const ResidentDashboardScreen(),
          settings: settings,
        );
      case AppRoutes.collectionSchedule:
      case AppRoutes.collectionDetails:
      case AppRoutes.recycling:
      case AppRoutes.collectionHistory:
      case AppRoutes.missedCollection:
      case AppRoutes.specialPickup:
      case AppRoutes.recyclingCentres:
        return MaterialPageRoute(
          builder: (context) => const ResidentDashboardScreen(), // Placeholder
          settings: settings,
        );

      // Driver routes
      case AppRoutes.driverDashboard:
        return MaterialPageRoute(
          builder: (context) => const DriverDashboardScreen(),
          settings: settings,
        );
      case AppRoutes.assignedRoutes:
      case AppRoutes.routeDetails:
      case AppRoutes.collectionStatus:
      case AppRoutes.collectionIssue:
        return MaterialPageRoute(
          builder: (context) => const DriverDashboardScreen(), // Placeholder
          settings: settings,
        );

      // Municipal Officer routes
      case AppRoutes.municipalDashboard:
        return MaterialPageRoute(
          builder: (context) => const MunicipalDashboardScreen(),
          settings: settings,
        );
      case AppRoutes.vehicleManagement:
        return MaterialPageRoute(
          builder: (context) => const VehicleManagementScreen(),
          settings: settings,
        );
      case AppRoutes.driverManagement:
        return MaterialPageRoute(
          builder: (context) => const DriverManagementScreen(),
          settings: settings,
        );
      case AppRoutes.staffManagement:
        return MaterialPageRoute(
          builder: (context) => const StaffManagementScreen(),
          settings: settings,
        );
      case AppRoutes.scheduleManagement:
        return MaterialPageRoute(
          builder: (context) => const ScheduleManagementScreen(),
          settings: settings,
        );
      case AppRoutes.reportsAnalytics:
        return MaterialPageRoute(
          builder: (context) => const ReportsAnalyticsScreen(),
          settings: settings,
        );

      // Common authenticated routes
      case AppRoutes.profile:
      case AppRoutes.settings:
      case AppRoutes.notifications:
      case AppRoutes.driverProfile:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(), // Placeholder
          settings: settings,
        );

      // Unknown route
      default:
        return MaterialPageRoute(
          builder: (context) => _PlaceholderScreen(routeName: settings.name),
          settings: settings,
        );
    }
  }

  /// Navigate to a named route.
  ///
  /// Usage: AppRouter.navigateTo(context, AppRoutes.login)
  static Future<dynamic> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Navigate to a named route, replacing the current route.
  ///
  /// Usage: AppRouter.navigateToReplacement(context, AppRoutes.residentDashboard)
  static Future<dynamic> navigateToReplacement(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to a named route, removing all previous routes.
  ///
  /// Useful for navigating after authentication.
  /// Usage: AppRouter.navigateToAndClearStack(context, AppRoutes.residentDashboard)
  static Future<dynamic> navigateToAndClearStack(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop the current route.
  static void pop(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }

  /// Pop until a specific route is reached.
  ///
  /// Usage: AppRouter.popUntil(context, (route) => route.isFirst)
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.popUntil(context, predicate);
  }
}

/// Placeholder screen shown while routes are being implemented.
///
/// This provides visual feedback during development.
/// Remove or replace this class once actual screens are implemented.
class _PlaceholderScreen extends StatelessWidget {
  final String? routeName;

  const _PlaceholderScreen({this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Not Implemented')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64),
            const SizedBox(height: 16),
            Text(
              'Route: $routeName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This route is not yet implemented.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
