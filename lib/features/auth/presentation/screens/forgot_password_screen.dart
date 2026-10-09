import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_controller.dart';
import 'reset_password_screen.dart';

/// Step 1 of Forgot / Reset: send a Firebase reset email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _valid => Validators.email(_email.text) == null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    final ok = await auth.sendPasswordReset(_email.text);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Could not send reset email.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.resetEmailSent)),
    );
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordScreen.forgot(email: _email.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.backToLogin,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
      ),
      body: LoadingOverlay(
        visible: auth.busy,
        child: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: ListView(
              padding: AppTheme.screenPadding,
              children: [
                const BrandHeader(compact: true),
                const SizedBox(height: 24),
                Text(
                  AppStrings.forgotTitle,
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.forgotSubtitle,
                  style: AppTextStyles.screenSubtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: AppStrings.emailAddress,
                  hintText: 'name@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: AppStrings.sendResetLink,
                  enabled: _valid,
                  isLoading: auth.busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.backToLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
