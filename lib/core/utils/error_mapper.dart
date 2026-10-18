import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_roles.dart';

/// Turns Firebase / network exceptions into short, user-facing sentences.
///
/// HCI: help users recognise, diagnose and recover from errors — never show
/// raw `wrong-password` codes on screen.
class ErrorMapper {
  ErrorMapper._();

  static String from(Object error) {
    if (error is RoleMismatchException) {
      return 'This sign-in is for ${error.expectedLabel} accounts. '
          'Your account is registered as a ${error.actualLabel}.';
    }
    if (error is OtpSendException) {
      return error.message;
    }
    if (error is AppleSignInUnavailableException) {
      return error.toString();
    }
    if (error is FirebaseAuthException) {
      return _fromAuth(error);
    }
    if (error is SocketException) {
      return 'No network connection. Check your internet and try again.';
    }
    if (error is FirebaseException) {
      return error.message ?? 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static bool isCancelled(Object error) {
    return error is FirebaseAuthException &&
        (error.code == 'aborted' || error.code == 'canceled');
  }

  static String _fromAuth(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'aborted':
      case 'canceled':
        return 'Sign-in was cancelled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'That email is already registered. Try logging in.';
      case 'weak-password':
        return 'Password is too weak. Use 8+ characters, a number and a symbol.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'No network connection. Check your internet and try again.';
      case 'requires-recent-login':
        return 'Please confirm your password again to continue.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled yet.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

/// Thrown when a Driver / Officer login is attempted with the wrong stored role.
class RoleMismatchException implements Exception {
  RoleMismatchException(this.expected, this.actual);

  final String expected;
  final String actual;

  String get expectedLabel => AppRoles.label(expected);
  String get actualLabel => AppRoles.label(actual);

  @override
  String toString() =>
      'This login is for $expectedLabel accounts. Your account role is $actualLabel.';
}

class AppleSignInUnavailableException implements Exception {
  @override
  String toString() => 'Apple Sign-In is coming soon.';
}

class OtpSendException implements Exception {
  OtpSendException(this.message);
  final String message;
  @override
  String toString() => message;
}
