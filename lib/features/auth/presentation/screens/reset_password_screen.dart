import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_controller.dart';
import '../widgets/password_rules_checklist.dart';

/// Create a New Password — Variant 3: reset + password rules.
///
/// * [loggedIn]: UPDATE via re-auth + `updatePassword`.
/// * Forgot flow: the email link is what actually resets a logged-out account;
///   this screen still matches Figma and validates the new password rules.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen.forgot({super.key, this.email})
      : loggedIn = false;

  const ResetPasswordScreen.changeExisting({super.key})
      : email = null,
        loggedIn = true;

  final String? email;
  final bool loggedIn;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _rulesMet => Validators.meetsResetRules(_password.text);

  bool get _valid {
    if (!_rulesMet) return false;
    if (Validators.confirmPassword(_confirm.text, _password.text) != null) {
      return false;
    }
    if (widget.loggedIn && Validators.loginPassword(_current.text) != null) {
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false) || !_rulesMet) return;

    if (!widget.loggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.email == null
                ? AppStrings.resetEmailSent
                : 'Open the reset link sent to ${widget.email} to apply your new password, then log in.',
          ),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final auth = context.read<AuthController>();
    final ok = await auth.updatePasswordLoggedIn(
      currentPassword: _current.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Could not update password.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated.')),
    );
    Navigator.of(context).pop();
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
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.createNewPassword,
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.resetSubtitle,
                  style: AppTextStyles.screenSubtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (widget.loggedIn) ...[
                  PasswordField(
                    label: AppStrings.currentPassword,
                    hintText: 'Enter current password',
                    controller: _current,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.loginPassword,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                ],
                PasswordField(
                  label: AppStrings.newPassword,
                  hintText: 'New password',
                  controller: _password,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  label: AppStrings.confirmPassword,
                  hintText: 'Confirm password',
                  controller: _confirm,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) =>
                      Validators.confirmPassword(value, _password.text),
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                PasswordRulesChecklist(password: _password.text),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: AppStrings.resetPassword,
                  enabled: _valid,
                  isLoading: auth.busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    if (widget.loggedIn) {
                      Navigator.pop(context);
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: Text(
                    widget.loggedIn ? 'Cancel' : AppStrings.backToLogin,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
