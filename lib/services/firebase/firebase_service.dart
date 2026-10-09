import 'package:cloud_firestore/cloud_firestore.dart';

/// Common Firebase service exception wrapper.
///
/// This keeps Firebase-specific exceptions behind a reusable application-facing
/// exception type while avoiding UI-specific logic.
class FirebaseServiceException implements Exception {
  const FirebaseServiceException({required this.code, required this.message});

  final String code;
  final String message;

  factory FirebaseServiceException.fromFirebaseException(
    FirebaseException exception,
  ) {
    return FirebaseServiceException(
      code: exception.code,
      message: exception.message ?? 'A Firebase operation failed.',
    );
  }

  @override
  String toString() =>
      'FirebaseServiceException(code: $code, message: $message)';
}

/// Common Firebase service foundation.
///
/// This base layer is intentionally generic and reusable across the app.
/// It does not implement feature-specific logic, authentication flows, or
/// notification-related business logic.
abstract class FirebaseService {
  FirebaseFirestore get firestore;

  /// Returns the current instance of Firebase Firestore.
  FirebaseFirestore get instance => firestore;
}
