import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_roles.dart';
import '../auth/presentation/auth_controller.dart';
import '../profile/presentation/screens/account_settings_screen.dart';
import 'home_resident_placeholder.dart';

/// Shared bottom navigation so Account Settings matches the Figma tab bar.
/// Home / Schedule / Track are placeholders for other members.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          _HomeTab(),
          _MemberPlaceholder(
            title: 'Schedule',
            message: 'Collection scheduling will be implemented by other members.',
          ),
          _MemberPlaceholder(
            title: 'Track',
            message: 'Live tracking will be implemented by other members.',
          ),
          AccountSettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthController>().profile?.role;
    switch (role) {
      case AppRoles.driver:
        return const DriverHomePlaceholder();
      case AppRoles.municipalOfficer:
        return const OfficerDashboardPlaceholder();
      default:
        return const HomeResidentPlaceholder();
    }
  }
}

class _MemberPlaceholder extends StatelessWidget {
  const _MemberPlaceholder({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      )),
    );
  }
}
