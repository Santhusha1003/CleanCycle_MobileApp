import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/screens/reset_password_screen.dart';
import '../../../notifications/presentation/notification_settings_screen.dart';
import '../profile_controller.dart';
import '../widgets/profile_avatar.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'language_screen.dart';
import 'privacy_security_screen.dart';

/// Account Settings — Variant 2: profile + settings list (Milestone 02).
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();

    if (profile.loading && profile.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = profile.user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.accountSettings)),
        body: AppStateMessage(
          icon: Icons.person_off_outlined,
          message: profile.errorMessage ?? 'Could not load your profile.',
          actionLabel: 'Retry',
          onAction: () {},
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.accountSettings)),
      body: LoadingOverlay(
        visible: profile.busy,
        child: ListView(
          padding: AppTheme.screenPadding,
          children: [
            const SizedBox(height: 8),
            Center(
              child: ProfileAvatar(
                user: user,
                onEdit: () => _open(context, const EditProfileScreen()),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle,
            ),
            if (user.phone.isNotEmpty)
              Text(
                user.phone,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: PrimaryButton(
                  label: AppStrings.editProfile,
                  onPressed: () => _open(context, const EditProfileScreen()),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  color: const Color(0xFFFB8C00),
                  title: AppStrings.notificationSettings,
                  onTap: () => _open(context, const NotificationSettingsScreen()),
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF1E88E5),
                  title: AppStrings.privacySecurity,
                  onTap: () => _open(context, const PrivacySecurityScreen()),
                ),
                _SettingsTile(
                  icon: Icons.lock_reset_rounded,
                  color: const Color(0xFF8E24AA),
                  title: AppStrings.changePassword,
                  onTap: () => _open(
                    context,
                    const ResetPasswordScreen.changeExisting(),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.language,
                  color: const Color(0xFF43A047),
                  title: AppStrings.language,
                  trailing: user.language,
                  onTap: () => _open(context, const LanguageScreen()),
                ),
                _SettingsTile(
                  icon: Icons.help_outline,
                  color: const Color(0xFF3949AB),
                  title: AppStrings.helpSupport,
                  onTap: () => _open(context, const HelpSupportScreen()),
                ),
                _SettingsTile(
                  icon: Icons.logout,
                  color: AppColors.error,
                  title: AppStrings.logout,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use CleanCycle.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ProfileController>().logout();
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: AppTextStyles.sectionTitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: AppTextStyles.caption),
          const Icon(Icons.chevron_right, color: AppColors.navInactive),
        ],
      ),
      onTap: onTap,
    );
  }
}
