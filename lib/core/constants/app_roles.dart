/// Canonical role values stored in Firestore `users/{uid}.role`.
///
/// Registration always writes [resident]. Driver / officer accounts are
/// provisioned out-of-band (admin); the client never lets a user pick a role.
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
