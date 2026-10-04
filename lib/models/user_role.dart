/// User roles in the CleanCycle application.
///
/// This enum defines all possible user roles.
/// It is used throughout the app for role-based navigation, access control, and feature flags.
enum UserRole {
  /// Resident who schedules waste collection and views recycling information.
  resident,

  /// Waste collection driver who manages routes and updates collection status.
  driver,

  /// Municipal waste management officer who manages operations and reports.
  officer,
}

/// Extension methods for UserRole.
extension UserRoleExtension on UserRole {
  /// Get the string representation of the role.
  String get displayName {
    switch (this) {
      case UserRole.resident:
        return 'Resident';
      case UserRole.driver:
        return 'Driver';
      case UserRole.officer:
        return 'Municipal Officer';
    }
  }

  /// Get the role from a string (for Firebase or API responses).
  static UserRole? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'resident':
        return UserRole.resident;
      case 'driver':
        return UserRole.driver;
      case 'officer':
      case 'municipal_officer':
        return UserRole.officer;
      default:
        return null;
    }
  }
}
