import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/models/app_user.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/presentation/profile_controller.dart';

/// Toggles persisted to `users/{uid}.notificationPrefs`.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final prefs = profile.user?.notificationPrefs ?? const NotificationPrefs();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.notificationSettings)),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          SwitchListTile(
            activeThumbColor: AppColors.primary,
            title: const Text('Collection reminders'),
            subtitle: const Text('Upcoming household collection days'),
            value: prefs.collectionReminders,
            onChanged: (value) => profile.updateNotificationPrefs(
              prefs.copyWith(collectionReminders: value),
            ),
          ),
          SwitchListTile(
            activeThumbColor: AppColors.primary,
            title: const Text('Special pickup updates'),
            subtitle: const Text('Status of bulky / extra pickups'),
            value: prefs.specialPickupUpdates,
            onChanged: (value) => profile.updateNotificationPrefs(
              prefs.copyWith(specialPickupUpdates: value),
            ),
          ),
          SwitchListTile(
            activeThumbColor: AppColors.primary,
            title: const Text('Service updates'),
            subtitle: const Text('Outages, holidays and policy changes'),
            value: prefs.serviceUpdates,
            onChanged: (value) => profile.updateNotificationPrefs(
              prefs.copyWith(serviceUpdates: value),
            ),
          ),
        ],
      ),
    );
  }
}
