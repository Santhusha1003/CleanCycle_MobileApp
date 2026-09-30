import 'package:flutter/material.dart';

/// Temporary login screen placeholder.
///
/// TODO: Replace with actual login screen implementation by Member 01
/// This screen should handle:
/// - Email/password input
/// - Firebase Authentication
/// - Role loading
/// - Error handling
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Login Screen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To be implemented by Member 01',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
