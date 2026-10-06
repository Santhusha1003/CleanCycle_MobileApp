import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../profile_controller.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const options = ['English', 'Sinhala', 'Tamil'];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final current = profile.user?.language ?? 'English';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.language)),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          for (final option in options)
            ListTile(
              title: Text(option),
              trailing: current == option
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : const Icon(Icons.circle_outlined, color: AppColors.navInactive),
              onTap: () async {
                final ok = await profile.updateProfile(language: option);
                if (!context.mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        profile.errorMessage ?? 'Could not save language.',
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
