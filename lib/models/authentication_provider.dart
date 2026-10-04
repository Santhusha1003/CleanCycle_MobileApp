import 'user_role.dart';

/// Abstract interface for authentication provider.
///
/// This interface is designed to be implemented by Member 01 (Authentication team).
/// It abstracts away the implementation details of Firebase Authentication
/// and provides a clean contract for the navigation system to use.
///
/// **IMPORTANT**: This is NOT the actual implementation.
/// Member 01 should create a concrete implementation in their authentication module.
///
/// Example implementation (created by Member 01):
/// ```dart
/// class FirebaseAuthenticationProvider implements AuthenticationProvider {
///   @override
///   Future<bool> isAuthenticated() async {
///     return FirebaseAuth.instance.currentUser != null;
///   }
///
///   @override
///   Future<String?> getCurrentUserId() async {
///     return FirebaseAuth.instance.currentUser?.uid;
///   }
///
///   @override
///   Future<UserRole?> getUserRole() async {
///     // Query Firestore for user role
///   }
/// }
/// ```
abstract class AuthenticationProvider {
  /// Check if a user is currently authenticated.
  Future<bool> isAuthenticated();

  /// Get the current user's unique ID.
  ///
  /// Returns null if no user is authenticated.
  Future<String?> getCurrentUserId();

  /// Get the current user's role.
  ///
  /// Returns null if no user is authenticated or role is not yet loaded.
  /// This may query Firestore or cache the role from login.
  Future<UserRole?> getUserRole();

  /// Logout the current user.
  ///
  /// This is a placeholder for Member 01's logout implementation.
  Future<void> logout();
}

/// Singleton instance of the authentication provider.
///
/// This should be initialized by Member 01 in the app initialization.
/// Example:
/// ```dart
/// void main() async {
///   authProvider = FirebaseAuthenticationProvider();
///   // ... rest of initialization
///   runApp(const MyApp());
/// }
/// ```
AuthenticationProvider? authProvider;

/// Helper function to get the authentication provider.
///
/// Throws an error if the provider is not initialized.
/// This ensures Member 01 initializes authentication before navigation needs it.
AuthenticationProvider getAuthProvider() {
  if (authProvider == null) {
    throw StateError(
      'AuthenticationProvider not initialized. '
      'Initialize authProvider in main() before running the app.',
    );
  }
  return authProvider!;
}
