import 'package:flutter/material.dart';

/// Temporary driver dashboard placeholder.
///
/// TODO: Replace with actual driver dashboard by responsible team member
/// This screen should show:
/// - Today's assigned routes
/// - Collection progress
/// - Navigation controls
/// - Bottom navigation for driver
class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Driver Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To be implemented',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
