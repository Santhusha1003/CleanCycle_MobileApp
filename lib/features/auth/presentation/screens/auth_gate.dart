import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../navigation/municipal_shell.dart';
import '../../../../theme/app_theme.dart' as municipal;
import '../../../../collection_schedule/screens/home_dashboard_screen.dart';
import '../../../../vishani/screens/tracking_dashboard_screen.dart';
import '../auth_controller.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

/// Routes the user after Auth state + Firestore role are known.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    // TEMPORARY runtime diagnostics for the installed role-flow build.
    void trace(String destination) {
      if (kDebugMode) {
        debugPrint(
          '[AUTH DEBUG] role-flow runtime trace v1; '
          'AuthGate UID: ${auth.firebaseUser?.uid}; '
          'role: ${auth.profile?.role}; destination: $destination',
        );
      }
    }

    if (auth.status == AuthStatus.unknown) {
      trace('Loading');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.status == AuthStatus.unauthenticated ||
        auth.firebaseUser == null) {
      trace('LoginScreen');
      return const LoginScreen();
    }

    if (auth.needsEmailVerification) {
      trace(
        auth.canShowEmailVerification
            ? 'VerificationScreen'
            : 'LoginScreen (verification required)',
      );
      return auth.canShowEmailVerification
          ? const VerificationScreen()
          : const LoginScreen();
    }

    final profile = auth.profile;
    if (profile == null) {
      trace('Profile support state');
      return Scaffold(
        body: AppStateMessage(
          icon: Icons.person_off_outlined,
          message: 'We signed you in but could not load your profile.',
          actionLabel: 'Sign out',
          onAction: auth.signOut,
        ),
      );
    }

    // Match the stored role explicitly. No shared placeholder shell and no
    // Resident fallback for missing, unsupported or future role values.
    switch (profile.role) {
      case AppRoles.resident:
        trace('Member 02 HomeDashboardScreen');
        return const HomeDashboardScreen();
      case AppRoles.driver:
        trace('Member 03 TrackingDashboardScreen');
        return const TrackingDashboardScreen();
      case AppRoles.municipalOfficer:
        trace('MunicipalShell');
        return Theme(
          data: municipal.AppTheme.lightTheme,
          child: const MunicipalShell(),
        );
      default:
        trace('Unsupported-role support state');
        return Scaffold(
          body: AppStateMessage(
            message:
                'Your account role is not supported. Please contact support.',
            actionLabel: 'Sign out',
            onAction: auth.signOut,
          ),
        );
    }
  }
}
