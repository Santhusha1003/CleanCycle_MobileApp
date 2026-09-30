/// Centralized route name definitions for the CleanCycle application.
///
/// This class provides a single source of truth for all route names,
/// preventing hardcoded route strings scattered throughout the application.
///
/// Routes are organized by feature/role, but all definitions are centralized here.
/// This makes it easy to navigate to screens without importing multiple files.
class AppRoutes {
  AppRoutes._();

  // Common routes - available to all users
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // Resident routes
  static const String residentDashboard = '/resident/dashboard';
  static const String collectionSchedule = '/resident/collection-schedule';
  static const String collectionDetails = '/resident/collection-details';
  static const String recycling = '/resident/recycling';
  static const String collectionHistory = '/resident/collection-history';
  static const String missedCollection = '/resident/missed-collection';
  static const String specialPickup = '/resident/special-pickup';
  static const String recyclingCentres = '/resident/recycling-centres';

  // Driver routes
  static const String driverDashboard = '/driver/dashboard';
  static const String assignedRoutes = '/driver/assigned-routes';
  static const String routeDetails = '/driver/route-details';
  static const String collectionStatus = '/driver/collection-status';
  static const String collectionIssue = '/driver/collection-issue';
  static const String driverProfile = '/driver/profile';

  // Municipal Officer routes
  static const String municipalDashboard = '/municipal/dashboard';
  static const String vehicleManagement = '/municipal/vehicle-management';
  static const String driverManagement = '/municipal/driver-management';
  static const String staffManagement = '/municipal/staff-management';
  static const String reportsAnalytics = '/municipal/reports-analytics';
  static const String scheduleManagement = '/municipal/schedule-management';
}
