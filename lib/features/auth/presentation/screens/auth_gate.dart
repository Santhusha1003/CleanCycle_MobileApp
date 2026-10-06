import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../placeholders/app_shell.dart';
import '../auth_controller.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

/// Routes the user after Auth state + Firestore role are known.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.status == AuthStatus.unknown) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.status == AuthStatus.unauthenticated || auth.firebaseUser == null) {
      return const LoginScreen();
    }

    if (auth.needsEmailVerification) {
      return const VerificationScreen();
    }

    final profile = auth.profile;
    if (profile == null) {
      return Scaffold(
        body: AppStateMessage(
          icon: Icons.person_off_outlined,
          message: 'We signed you in but could not load your profile.',
          actionLabel: 'Sign out',
          onAction: auth.signOut,
        ),
      );
    }

    return const AppShell();
  }
}
