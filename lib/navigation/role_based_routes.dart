import '../models/authentication_provider.dart';
import '../models/user_role.dart';
import 'app_routes.dart';

/// Role-based route groups.
///
/// This class organizes routes by role to make it easy to check
/// if a route is accessible by a particular role.
class RoleBasedRoutes {
  RoleBasedRoutes._();

  /// Routes accessible to authenticated residents only.
  static const List<String> residentRoutes = [
    AppRoutes.residentDashboard,
    AppRoutes.collectionSchedule,
    AppRoutes.collectionDetails,
    AppRoutes.recycling,
    AppRoutes.collectionHistory,
    AppRoutes.missedCollection,
    AppRoutes.specialPickup,
    AppRoutes.recyclingCentres,
  ];

  /// Routes accessible to authenticated drivers only.
  static const List<String> driverRoutes = [
    AppRoutes.driverDashboard,
    AppRoutes.assignedRoutes,
    AppRoutes.routeDetails,
    AppRoutes.collectionStatus,
    AppRoutes.collectionIssue,
  ];

  /// Routes accessible to municipal officers only.
  static const List<String> officerRoutes = [
    AppRoutes.municipalDashboard,
    AppRoutes.vehicleManagement,
    AppRoutes.driverManagement,
    AppRoutes.staffManagement,
    AppRoutes.reportsAnalytics,
    AppRoutes.scheduleManagement,
  ];

  /// Routes accessible to all authenticated users (shared across roles).
  static const List<String> commonAuthenticatedRoutes = [
    AppRoutes.profile,
    AppRoutes.settings,
    AppRoutes.notifications,
  ];

  /// Public routes (no authentication required).
  static const List<String> publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
  ];

  /// Check if a route is role-restricted.
  static bool isRoleRestricted(String? routeName) {
    if (routeName == null) return false;
    return residentRoutes.contains(routeName) ||
        driverRoutes.contains(routeName) ||
        officerRoutes.contains(routeName);
  }

  /// Check if a user with a given role can access a route.
  static bool canAccessRoute(UserRole role, String? routeName) {
    if (routeName == null) return false;

    // Everyone can access common authenticated routes
    if (commonAuthenticatedRoutes.contains(routeName)) return true;

    // Check role-specific routes
    switch (role) {
      case UserRole.resident:
        return residentRoutes.contains(routeName);
      case UserRole.driver:
        return driverRoutes.contains(routeName);
      case UserRole.officer:
        return officerRoutes.contains(routeName);
    }
  }

  /// Get the home route for a given role.
  static String getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.resident:
        return AppRoutes.residentDashboard;
      case UserRole.driver:
        return AppRoutes.driverDashboard;
      case UserRole.officer:
        return AppRoutes.municipalDashboard;
    }
  }
}

/// Navigation guard for role-based access control.
///
/// This is called by AppRouter to determine if a route should be allowed.
/// It checks:
/// 1. If user is authenticated (via AuthenticationProvider)
/// 2. If the route requires authentication
/// 3. If the user has the correct role for the route
///
/// If access is denied, it redirects to the appropriate screen:
/// - Unauthenticated users → login
/// - Authenticated users without correct role → home page (for their role)
class NavigationGuard {
  NavigationGuard._();

  /// Check if a user can access a route.
  ///
  /// Returns:
  /// - null if access is allowed
  /// - redirect route if access is denied
  static Future<String?> checkAccess(String? routeName) async {
    try {
      final authProvider = getAuthProvider();
      final isAuthenticated = await authProvider.isAuthenticated();

      // Public routes (no authentication required)
      if (RoleBasedRoutes.publicRoutes.contains(routeName)) {
        return null; // Allow access
      }

      // Protected routes (authentication required)
      if (!isAuthenticated) {
        return AppRoutes.login; // Redirect to login
      }

      // Role-restricted routes
      if (RoleBasedRoutes.isRoleRestricted(routeName)) {
        final userRole = await authProvider.getUserRole();

        if (userRole == null) {
          // Role not loaded yet
          return AppRoutes.splash; // Go back to splash to reload
        }

        if (!RoleBasedRoutes.canAccessRoute(userRole, routeName)) {
          // User doesn't have permission for this route
          return RoleBasedRoutes.getHomeRouteForRole(userRole);
        }
      }

      // Access allowed
      return null;
    } catch (e) {
      // If authentication provider is not initialized, redirect to splash
      return AppRoutes.splash;
    }
  }

  /// Get the initial route based on authentication status and role.
  ///
  /// This is used by main.dart to determine the starting route.
  /// The logic should be:
  /// 1. If not authenticated → splash (which may redirect to login)
  /// 2. If authenticated → role's home screen
  static Future<String> getInitialRoute() async {
    try {
      final authProvider = getAuthProvider();
      final isAuthenticated = await authProvider.isAuthenticated();

      if (!isAuthenticated) {
        return AppRoutes.splash;
      }

      final userRole = await authProvider.getUserRole();
      if (userRole == null) {
        return AppRoutes.splash; // Go to splash to load role
      }

      return RoleBasedRoutes.getHomeRouteForRole(userRole);
    } catch (e) {
      // If anything goes wrong, go to splash
      return AppRoutes.splash;
    }
  }
}
