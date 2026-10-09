import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/password_field.dart';
import '../profile_controller.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileController>().user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.privacySecurity)),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          Text('Your data', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'We store your name, email, phone, address/zone, language and '
            'notification preferences in your private Firestore profile. '
            'Your role cannot be changed from this app.',
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Email verified'),
            trailing: Text(user?.emailVerified == true ? 'Yes' : 'No'),
          ),
          ListTile(
            title: const Text('Last login'),
            trailing: Text(
              user?.lastLogin == null
                  ? '—'
                  : '${user!.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year}',
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: () => _deleteAccount(context),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This removes your Firestore profile and Firebase Auth user. '
              'This cannot be undone.',
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: AppStrings.password,
              controller: passwordController,
              hintText: 'Required for email accounts',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      passwordController.dispose();
      return;
    }
    final profile = context.read<ProfileController>();
    final ok = await profile.deleteAccount(password: passwordController.text);
    passwordController.dispose();
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profile.errorMessage ?? 'Could not delete account.')),
      );
    }
  }
}
