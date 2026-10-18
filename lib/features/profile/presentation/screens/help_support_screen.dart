import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.helpSupport)),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          Text('Frequently asked', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          const ListTile(
            title: Text('How do I reset my password?'),
            subtitle: Text(
              'Use Forgot Password on the login screen, or Change Password in Account Settings if you are signed in.',
            ),
          ),
          const ListTile(
            title: Text('Why can’t I choose Driver at sign-up?'),
            subtitle: Text(
              'New accounts are always residents. Driver and municipal officer roles are assigned by the municipality.',
            ),
          ),
          const SizedBox(height: 16),
          Text('Contact', style: AppTextStyles.sectionTitle),
          const ListTile(
            leading: Icon(Icons.mail_outline, color: AppColors.primary),
            title: Text('support@cleancycle.app'),
            subtitle: Text('University project help desk (placeholder).'),
          ),
        ],
      ),
    );
  }
}
