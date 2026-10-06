import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/error_mapper.dart';
import '../../notifications/data/fcm_service.dart';
import '../data/auth_repository.dart';
import '../data/email_otp.dart';
import '../data/user_repository.dart';
import '../models/app_user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Orchestrates Auth + Firestore for Login (and later Register / Verify).
///
/// Screens call these methods; they should not talk to Firebase directly.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required this.firebaseReady,
    FcmService? fcmService,
  })  : _auth = authRepository,
        _users = userRepository,
        _fcm = fcmService {
    if (!firebaseReady) {
      status = AuthStatus.unauthenticated;
      return;
    }
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _auth;
  final UserRepository _users;
  final FcmService? _fcm;
  final bool firebaseReady;

  StreamSubscription<User?>? _authSub;

  AuthStatus status = AuthStatus.unknown;
  User? firebaseUser;
  AppUser? profile;
  bool busy = false;
  String? errorMessage;
  bool awaitingEmailOtp = false;

  bool get needsEmailVerification {
    if (firebaseUser == null) return false;
    if (awaitingEmailOtp) return true;
    if (profile?.emailVerified == true) return false;
    final usedPassword = firebaseUser!.providerData
        .any((info) => info.providerId == 'password');
    if (usedPassword) return true;
    if (firebaseUser!.emailVerified) return false;
    return true;
  }

  Future<void> _onAuthChanged(User? user) async {
    // Ignore listener events while a sign-in/sign-up is still writing Firestore.
    if (busy) return;
    await _syncUser(user);
  }

  Future<void> _syncUser(User? user) async {
    firebaseUser = user;
    if (user == null) {
      profile = null;
      status = AuthStatus.unauthenticated;
      _fcm?.detachUser();
      notifyListeners();
      return;
    }
    profile = await _users.getById(user.uid);
    status = AuthStatus.authenticated;
    notifyListeners();
    await _fcm?.attachUser(user.uid);
  }

  Future<bool> signUpResident({
    required String name,
    required String email,
    required String phone,
    required String addressZone,
    required String password,
  }) {
    return _runAuth(() async {
      final user = await _auth.signUpWithEmail(email: email, password: password);
      await _auth.updateDisplayName(name);
      try {
        await _users.createResidentProfile(
          authUser: user,
          name: name,
          phone: phone,
          addressZone: addressZone,
        );
      } catch (error) {
        // Avoid an Auth user with no Firestore profile.
        await _auth.deleteAuthUser();
        rethrow;
      }
      awaitingEmailOtp = true;
      final typedEmail = email.trim();
      final code = EmailOtp.generate();
      await _users.saveEmailOtp(
        uid: user.uid,
        hash: EmailOtp.hash(code, user.uid),
        expiresAt: DateTime.now().add(EmailOtp.validFor),
      );
      try {
        await EmailOtp.send(toEmail: typedEmail, code: code);
      } catch (error) {
        errorMessage = ErrorMapper.from(error);
      }
    }, signOutOnError: false);
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
    String? expectedRole,
  }) {
    return _runAuth(() async {
      final user = await _auth.signInWithEmail(email: email, password: password);
      await _afterSignIn(user, expectedRole: expectedRole, isGoogle: false);
    });
  }

  Future<bool> signInWithGoogle({String? expectedRole}) {
    return _runAuth(() async {
      final user = await _auth.signInWithGoogle();
      await _afterSignIn(user, expectedRole: expectedRole, isGoogle: true);
    });
  }

  Future<bool> signInWithApple() {
    return _runAuth(() => _auth.signInWithApple());
  }

  /// READ profile + role, then UPDATE `lastLogin`.
  Future<void> _afterSignIn(
    User user, {
    String? expectedRole,
    required bool isGoogle,
  }) async {
    if (isGoogle) {
      await _users.ensureResidentProfile(user);
    }
    if (expectedRole != null) {
      await _users.requireRole(user.uid, expectedRole);
    } else {
      final existing = await _users.getById(user.uid);
      if (existing == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Your profile could not be found. Please register first.',
        );
      }
    }
    await _users.updateLastLogin(user.uid);
    await _auth.reloadCurrentUser();
  }

  Future<bool> resendVerificationEmail() {
    return _runAuth(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'You need to be signed in to resend the code.',
        );
      }
      await _sendSixDigitCode(user);
    }, signOutOnError: false);
  }

  Future<void> _sendSixDigitCode(User user, {String? toEmail}) async {
    final email = (toEmail ?? user.email)?.trim() ?? '';
    if (email.isEmpty) {
      throw OtpSendException(
        'This account has no email address to send a code to.',
      );
    }
    final code = EmailOtp.generate();
    await _users.saveEmailOtp(
      uid: user.uid,
      hash: EmailOtp.hash(code, user.uid),
      expiresAt: DateTime.now().add(EmailOtp.validFor),
    );
    await EmailOtp.send(toEmail: email, code: code);
  }

  Future<bool> verifyEmailOtp(String code) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        errorMessage = 'You need to be signed in to verify.';
        return false;
      }
      final trimmed = code.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
        errorMessage = 'Enter the 6-digit code from your email.';
        return false;
      }
      final stored = await _users.getEmailOtp(user.uid);
      if (stored == null) {
        errorMessage = 'No code was found. Tap Resend to get a new one.';
        return false;
      }
      if (DateTime.now().isAfter(stored.expiresAt)) {
        errorMessage = 'That code has expired. Tap Resend to get a new one.';
        return false;
      }
      if (stored.hash != EmailOtp.hash(trimmed, user.uid)) {
        errorMessage = 'That code is incorrect. Check the email and try again.';
        return false;
      }
      await _users.markEmailOtpVerified(user.uid);
      awaitingEmailOtp = false;
      profile = (await _users.getById(user.uid))?.copyWith(emailVerified: true) ??
          profile?.copyWith(emailVerified: true);
      return true;
    } catch (error) {
      errorMessage = ErrorMapper.from(error);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// CREATE: Firebase password-reset email (unauthenticated flow).
  Future<bool> sendPasswordReset(String email) {
    return _runAuth(
      () => _auth.sendPasswordResetEmail(email),
      signOutOnError: false,
    );
  }

  /// UPDATE: re-authenticate, then change the password (logged-in flow).
  Future<bool> updatePasswordLoggedIn({
    required String currentPassword,
    required String newPassword,
  }) {
    return _runAuth(() async {
      await _auth.reauthenticateWithPassword(currentPassword);
      await _auth.updatePassword(newPassword);
    }, signOutOnError: false);
  }

  Future<void> signOut() async {
    errorMessage = null;
    awaitingEmailOtp = false;
    await _clearTokenQuietly();
    await _auth.signOut();
  }

  Future<void> _clearTokenQuietly() async {
    final uid = firebaseUser?.uid;
    _fcm?.detachUser();
    if (uid == null) return;
    try {
      await _users.clearFcmToken(uid);
    } catch (_) {}
  }

  Future<bool> _runAuth(
    Future<void> Function() action, {
    bool signOutOnError = true,
  }) async {
    if (!firebaseReady) {
      errorMessage =
          'Firebase is not configured yet. Run flutterfire configure and rebuild.';
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      await _syncUser(_auth.currentUser);
      return true;
    } catch (error) {
      if (ErrorMapper.isCancelled(error)) {
        return false;
      }
      errorMessage = ErrorMapper.from(error);
      if (signOutOnError) {
        try {
          await _clearTokenQuietly();
          await _auth.signOut();
        } catch (_) {}
      } else if (_auth.currentUser != null) {
        await _syncUser(_auth.currentUser);
      }
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
