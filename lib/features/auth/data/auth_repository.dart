import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/error_mapper.dart';

/// Wraps Firebase Authentication only (no Firestore writes).
///
/// Profile documents are created/updated by [UserRepository]; the upcoming
/// AuthController will call both in the right order.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _authOverride = auth,
        _googleOverride = googleSignIn;

  final FirebaseAuth? _authOverride;
  final GoogleSignIn? _googleOverride;
  GoogleSignIn? _googleCached;

  // Lazy so Login can render before `flutterfire configure`.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn =>
      _googleOverride ?? (_googleCached ??= GoogleSignIn());

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// CREATE: email/password Auth user. Caller then writes `users/{uid}`.
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'internal-error',
        message: 'Account was created but no user was returned.',
      );
    }
    return user;
  }

  /// READ: email/password sign-in.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'internal-error',
        message: 'Sign-in succeeded but no user was returned.',
      );
    }
    return user;
  }

  /// Google Sign-In → Firebase credential.
  Future<User> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'aborted',
        message: 'Google sign-in was cancelled.',
      );
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'internal-error',
        message: 'Google sign-in succeeded but no user was returned.',
      );
    }
    return user;
  }

  /// Apple button is present in the UI but not wired (no Apple Developer team).
  Future<User> signInWithApple() {
    throw AppleSignInUnavailableException();
  }

  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _auth.currentUser;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Required by Firebase before [updatePassword] or [deleteAuthUser].
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to change your password.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to change your password.',
      );
    }
    await user.updatePassword(newPassword);
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// DELETE: Firebase Auth user. Firestore doc must be removed first.
  Future<void> deleteAuthUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }
}
