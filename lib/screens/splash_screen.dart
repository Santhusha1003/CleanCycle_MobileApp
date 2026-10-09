import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/auth_gate.dart';

/// Legacy splash entry now delegates to the integrated authentication flow.
/// Anonymous development sign-in has been replaced by Member 01 authentication.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthGate();
}
