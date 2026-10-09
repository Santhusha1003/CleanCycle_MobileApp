import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../auth/presentation/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// Other team members replace this with the resident home / schedule UI.
class HomeResidentPlaceholder extends StatelessWidget {
  const HomeResidentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const _RoleHome(
        title: AppStrings.appName,
        body: AppStrings.tagline,
      );
}

class DriverHomePlaceholder extends StatelessWidget {
  const DriverHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const _RoleHome(
        title: 'Driver home',
        body: 'Driver routes and collection jobs will be implemented by other members.',
      );
}

class OfficerDashboardPlaceholder extends StatelessWidget {
  const OfficerDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const _RoleHome(
        title: 'Municipal officer dashboard',
        body: 'Municipal dashboards will be implemented by other members.',
      );
}

class _RoleHome extends StatelessWidget {
  const _RoleHome({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.screenTitle),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: AppTextStyles.screenSubtitle),
              if (auth.profile != null) ...[
                const SizedBox(height: 16),
                Text(auth.profile!.name, style: AppTextStyles.sectionTitle),
                Text(auth.profile!.email, style: AppTextStyles.caption),
              ],
              const SizedBox(height: 12),
              Text(
                'Open the Account tab to manage your profile.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
