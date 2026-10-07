import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';

class CollectionBottomNav extends StatelessWidget {
  final int currentIndex;

  const CollectionBottomNav({super.key, required this.currentIndex});

  static const Color primaryGreen = Color(0xFF159447);

  void _openScreen(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  void _onTap(BuildContext context, int index) {
    // Already on selected tab
    if (index == currentIndex) {
      return;
    }

    switch (index) {
      // HOME
      case 0:
        _openScreen(context, AppRoutes.residentDashboard);
        break;

      // SCHEDULE
      case 1:
        _openScreen(context, AppRoutes.collectionSchedule);
        break;

      // RECYCLING
      case 2:
        _openScreen(context, AppRoutes.recycling);
        break;

      // PROFILE
      case 3:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        _onTap(context, index);
      },

      type: BottomNavigationBarType.fixed,

      backgroundColor: Colors.white,

      selectedItemColor: primaryGreen,

      unselectedItemColor: Colors.grey,

      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),

      unselectedLabelStyle: const TextStyle(fontSize: 11),

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
          icon: Icon(Icons.recycling_outlined),
          activeIcon: Icon(Icons.recycling),
          label: 'Recycling',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
