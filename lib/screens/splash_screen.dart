import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

/// Temporary splash screen placeholder.
///
/// TODO: Replace with actual splash screen implementation
/// This screen should eventually:
/// - Check authentication status
/// - Load user role
/// - Redirect to appropriate home screen
/// - Show splash/loading UI

// ─── DEV BYPASS ──────────────────────────────────────────────────────────────
// TEMPORARY: Signs in anonymously so that the Firestore rules
// (request.auth != null) are satisfied during development testing, then routes
// directly to MunicipalDashboard.
//
// TO REMOVE when Member 01's auth is integrated:
//   1. Delete the anonymous sign-in block inside _SplashScreenState.initState.
//   2. Replace with the real auth-check / role-based routing implementation.
//   3. Remove the 'dart:developer' import if no longer needed.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // ── TEMPORARY DEV AUTH ──────────────────────────────────────────────────
    // Sign in anonymously so that request.auth != null is satisfied for
    // Firestore rules on vehicles / drivers / staff / schedules collections.
    //
    // This is NOT the production auth flow. Remove this block when Member 01's
    // Firebase Authentication and role management are integrated.
    await _ensureAnonymousSignIn();
    // ── END TEMPORARY DEV AUTH ──────────────────────────────────────────────

    // TEMPORARY DEV BYPASS — navigate to Municipal Dashboard after sign-in.
    // Remove this and implement real auth-based routing here.
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.municipalDashboard);
  }

  /// Signs in anonymously if no Firebase user session is currently active.
  ///
  /// TEMPORARY DEVELOPMENT ONLY — satisfies Firestore security rules
  /// (`request.auth != null`) so the Municipal Operations screens can read
  /// and write Firestore data during testing before Member 01 completes
  /// the production authentication system.
  ///
  /// - If a session already exists (anonymous or otherwise), this is a no-op.
  /// - If sign-in fails, the error is logged and the app continues so the
  ///   development bypass is not blocked by an auth failure.
  Future<void> _ensureAnonymousSignIn() async {
    try {
      final auth = FirebaseAuth.instance;

      if (auth.currentUser != null) {
        // A session is already active — nothing to do.
        developer.log(
          '[DEV AUTH] Firebase user already signed in: ${auth.currentUser!.uid}',
          name: 'SplashScreen',
        );
        return;
      }

      final credential = await auth.signInAnonymously();
      developer.log(
        '[DEV AUTH] Anonymous sign-in successful. uid=${credential.user?.uid}',
        name: 'SplashScreen',
      );
    } on FirebaseAuthException catch (e) {
      // Log but do not block navigation — development should continue even if
      // anonymous auth fails (e.g. network unavailable).
      developer.log(
        '[DEV AUTH] Anonymous sign-in failed: ${e.code} — ${e.message}',
        name: 'SplashScreen',
        error: e,
      );
    } on Exception catch (e) {
      developer.log(
        '[DEV AUTH] Unexpected error during anonymous sign-in: $e',
        name: 'SplashScreen',
        error: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recycling, size: 64),
            SizedBox(height: 16),
            Text(
              'CleanCycle',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
