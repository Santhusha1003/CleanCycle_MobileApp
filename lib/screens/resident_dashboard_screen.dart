import 'package:flutter/material.dart';

/// Temporary resident dashboard placeholder.
///
/// TODO: Replace with actual resident dashboard by responsible team member
/// This screen should show:
/// - Upcoming collection schedules
/// - Recent activities
/// - Quick links to features
/// - Bottom navigation for resident
class ResidentDashboardScreen extends StatelessWidget {
  const ResidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resident Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Resident Dashboard',
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
