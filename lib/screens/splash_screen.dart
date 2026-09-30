import 'package:flutter/material.dart';

/// Temporary splash screen placeholder.
///
/// TODO: Replace with actual splash screen implementation
/// This screen should eventually:
/// - Check authentication status
/// - Load user role
/// - Redirect to appropriate home screen
/// - Show splash/loading UI
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.recycling, size: 64),
            const SizedBox(height: 16),
            const Text(
              'CleanCycle',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
