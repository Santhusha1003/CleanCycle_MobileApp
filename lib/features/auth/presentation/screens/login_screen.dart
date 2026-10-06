import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_controller.dart';
import '../widgets/social_login_buttons.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';

/// Login — Variant 2: Social login + email (Milestone 02 selection).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Null = main login (any stored role). Driver / Officer entry points set this.
  String? _expectedRole;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _formValid =>
      Validators.email(_emailController.text) == null &&
      Validators.loginPassword(_passwordController.text) == null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    final ok = await auth.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
      expectedRole: _expectedRole,
    );
    if (!mounted) return;
    if (!ok && auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  Future<void> _google() async {
    final auth = context.read<AuthController>();
    final ok = await auth.signInWithGoogle(expectedRole: _expectedRole);
    if (!mounted) return;
    if (!ok && auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  Future<void> _apple() async {
    final auth = context.read<AuthController>();
    await auth.signInWithApple();
    if (!mounted) return;
    _showError(auth.errorMessage ?? AppStrings.appleComingSoon);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        visible: auth.busy,
        child: SafeArea(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: ListView(
                padding: AppTheme.screenPadding,
                children: [
                  const SizedBox(height: 24),
                  const BrandHeader(),
                  if (_expectedRole != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Signing in as ${AppRoles.label(_expectedRole!)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SocialLoginButtons(onGoogle: _google, onApple: _apple),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: AppStrings.emailAddress,
                    hintText: 'name@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    label: AppStrings.password,
                    hintText: 'Enter password',
                    controller: _passwordController,
                    validator: Validators.loginPassword,
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: AppStrings.login,
                    enabled: _formValid,
                    isLoading: auth.busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(AppStrings.dontHaveAccount, style: AppTextStyles.caption),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CreateAccountScreen(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(AppStrings.signUp, style: AppTextStyles.link),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(
                      () => _expectedRole = AppRoles.municipalOfficer,
                    ),
                    child: const Text(AppStrings.loginAsOfficer),
                  ),
                  TextButton(
                    onPressed: () => setState(
                      () => _expectedRole = AppRoles.driver,
                    ),
                    child: const Text(AppStrings.loginAsDriver),
                  ),
                  if (_expectedRole != null)
                    TextButton(
                      onPressed: () => setState(() => _expectedRole = null),
                      child: const Text('Back to resident login'),
                    ),
                  if (!auth.firebaseReady) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Firebase is not configured. Run flutterfire configure.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.error,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
