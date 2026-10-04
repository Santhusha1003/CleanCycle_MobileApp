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
// TEMPORARY: Routes directly to MunicipalDashboard for testing before
// authentication is integrated.
//
// TO REMOVE: Delete the [_DevBypassState] class and replace [_SplashScreenState]
// with the production auth-check implementation. Revert this file to the
// original StatelessWidget or replace it with the real splash implementation.
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
    // TEMPORARY DEV BYPASS — navigate to Municipal Dashboard after first frame.
    // Remove this and implement real auth-based routing here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.municipalDashboard);
    });
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
