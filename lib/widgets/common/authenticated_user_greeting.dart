import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../theme/app_colors.dart';

/// Uses the existing users/{uid}.name profile, including live profile updates.
class AuthenticatedUserGreeting extends StatelessWidget {
  const AuthenticatedUserGreeting({super.key, this.style, this.textAlign});

  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController?>();
    final auth = context.watch<AuthController?>();
    final user = profile != null ? profile.user : auth?.profile;
    final name = user?.name.trim() ?? '';
    final greeting = name.isEmpty ? 'Hi there 👋' : 'Hi, $name 👋';
    return Tooltip(
      message: greeting,
      child: Text(
        greeting,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            style ??
            const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
