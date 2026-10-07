import 'package:flutter/material.dart';

import '../screens/driver_dashboard_screen.dart';
import '../features/auth/presentation/screens/auth_gate.dart';
import '../features/auth/presentation/screens/create_account_screen.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/profile/presentation/screens/account_settings_screen.dart';
import '../features/notifications/presentation/notification_settings_screen.dart';
import '../core/constants/app_roles.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../collection_schedule/screens/home_dashboard_screen.dart';
import '../collection_schedule/screens/collection_schedule_screen.dart';
import '../collection_schedule/screens/collection_history_screen.dart';
import '../collection_schedule/screens/missed_collection_report_screen.dart';
import '../collection_schedule/screens/recycling_tips_screen.dart';
import '../collection_schedule/screens/recycling_centre_locator_screen.dart';
import '../screens/resident_dashboard_screen.dart';
import '../screens/schedule_management_screen.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';
import 'municipal_shell.dart';

/// Centralized router configuration for the CleanCycle application.
///
/// This class manages navigation and route building for the app.
/// It provides a consistent interface for navigation across the application
/// and supports role restrictions using the authenticated AppUser profile.
///
/// Currently uses Flutter's standard Navigator with MaterialApp.
/// Named routes use the integrated AuthController role. These UI guards do
/// not replace server-side Firestore authorization.
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
          builder: (context) => const AuthGate(),
          settings: settings,
        );
      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (context) => const CreateAccountScreen(),
          settings: settings,
        );

      // Resident routes
      case AppRoutes.residentDashboard:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.resident,
            child: HomeDashboardScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.collectionSchedule:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.resident,
            child: CollectionScheduleScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.collectionHistory:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.resident,
            child: CollectionHistoryScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.missedCollection:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.resident,
            child: MissedCollectionReportScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.recycling:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.resident,
            child: RecyclingTipsScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.recyclingCentres:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.resident,
            child: RecyclingCentreLocatorScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.collectionDetails:
      case AppRoutes.specialPickup:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.resident,
            child: ResidentDashboardScreen(),
          ),
          settings: settings,
        );

      // Driver routes
      case AppRoutes.driverDashboard:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.driver,
            child: DriverDashboardScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.assignedRoutes:
      case AppRoutes.routeDetails:
      case AppRoutes.collectionStatus:
      case AppRoutes.collectionIssue:
        return MaterialPageRoute(
          builder: (context) => const _AuthenticatedRoute(
            role: AppRoles.driver,
            child: DriverDashboardScreen(),
          ), // Placeholder
          settings: settings,
        );

      // Municipal Officer routes
      case AppRoutes.municipalDashboard:
      case AppRoutes.vehicleManagement:
      case AppRoutes.driverManagement:
      case AppRoutes.staffManagement:
      case AppRoutes.reportsAnalytics:
        return MaterialPageRoute(
          builder: (context) => _AuthenticatedRoute(
            role: AppRoles.municipalOfficer,
            child: Theme(
              data: AppTheme.lightTheme,
              child: MunicipalShell(initialRoute: settings.name!),
            ),
          ),
          settings: settings,
        );
      case AppRoutes.scheduleManagement:
        return MaterialPageRoute(
          builder: (context) => _AuthenticatedRoute(
            role: AppRoles.municipalOfficer,
            child: Theme(
              data: AppTheme.lightTheme,
              child: const ScheduleManagementScreen(),
            ),
          ),
          settings: settings,
        );

      // Existing Member 01 profile and notification settings.
      case AppRoutes.profile:
      case AppRoutes.settings:
      case AppRoutes.driverProfile:
        return MaterialPageRoute(
          builder: (context) =>
              const _AuthenticatedRoute(child: AccountSettingsScreen()),
          settings: settings,
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (context) =>
              const _AuthenticatedRoute(child: NotificationSettingsScreen()),
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

/// Reject stale routes after logout or a role change. Firestore rules remain
/// responsible for data authorization; a UI guard grants no permissions.
class _AuthenticatedRoute extends StatelessWidget {
  const _AuthenticatedRoute({required this.child, this.role});
  final Widget child;
  final String? role;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final allowed =
        auth.status == AuthStatus.authenticated &&
        auth.firebaseUser != null &&
        !auth.firebaseUser!.isAnonymous &&
        !auth.needsEmailVerification &&
        auth.profile != null &&
        (role == null || auth.profile!.role == role);
    return allowed ? child : const AuthGate();
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
