/// Canonical role values stored in Firestore `users/{uid}.role`.
///
/// Registration always writes [resident]. Driver / officer accounts are
/// provisioned out-of-band (admin). Signup selections are requests, not grants.
class AppRoles {
  AppRoles._();

  static const String resident = 'resident';
  static const String driver = 'driver';
  static const String municipalOfficer = 'municipal_officer';

  static const Set<String> all = {
    resident,
    driver,
    municipalOfficer,
  };

  static bool isValid(String? role) => role != null && all.contains(role);

  static String displayLabel(String role) => switch (role) {
        driver => 'Driver',
        municipalOfficer => 'Municipal Officer',
        _ => 'Resident',
      };

  static String label(String role) {
    switch (role) {
      case driver:
        return 'driver';
      case municipalOfficer:
        return 'municipal officer';
      default:
        return 'resident';
    }
  }
}
