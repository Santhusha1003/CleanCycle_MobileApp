import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../widgets/password_strength_indicator.dart';

/// Create Account — Variant 3: form + password strength (Milestone 02).
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _acceptedTerms = false;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      _toast('Please accept the Terms & Conditions.');
      return;
    }
    final auth = context.read<AuthController>();
    final ok = await auth.signUpResident(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      addressZone: _address.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (ok || auth.firebaseUser != null) {
      Navigator.of(context).pop();
      return;
    }
    if (auth.errorMessage != null) {
      _toast(auth.errorMessage!);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLegal(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
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
          tooltip: 'Back',
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
                Text(
                  AppStrings.createAccountTitle,
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.createAccountSubtitle,
                  style: AppTextStyles.screenSubtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: AppStrings.fullName,
                  hintText: 'John Doe',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: AppStrings.emailAddress,
                  hintText: 'name@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: AppStrings.phoneNumber,
                  hintText: '0771234567',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: Validators.phone,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: AppStrings.addressZone,
                  hintText: 'Street, city or collection zone',
                  controller: _address,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  validator: Validators.addressZone,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  label: AppStrings.password,
                  hintText: 'Create a password',
                  controller: _password,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                ),
                PasswordStrengthIndicator(password: _password.text),
                const SizedBox(height: 16),
                PasswordField(
                  label: AppStrings.confirmPassword,
                  hintText: 'Re-enter password',
                  controller: _confirm,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) =>
                      Validators.confirmPassword(value, _password.text),
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          children: [
                            const Text(AppStrings.termsPrefix),
                            GestureDetector(
                              onTap: () => _showLegal(
                                AppStrings.terms,
                                'CleanCycle is a university project. By creating an '
                                'account you agree to use the app for coursework '
                                'demonstration only and to provide accurate details.',
                              ),
                              child: const Text(
                                AppStrings.terms,
                                style: AppTextStyles.link,
                              ),
                            ),
                            const Text(' and '),
                            GestureDetector(
                              onTap: () => _showLegal(
                                AppStrings.privacyPolicy,
                                'We store your name, email, phone, address/zone and '
                                'role in Firebase so collection scheduling can work. '
                                'You can delete your account from Account Settings.',
                              ),
                              child: const Text(
                                AppStrings.privacyPolicy,
                                style: AppTextStyles.link,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_confirm.text.isNotEmpty &&
                    _confirm.text != _password.text)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Passwords do not match.',
                      style: AppTextStyles.error,
                      textAlign: TextAlign.center,
                    ),
                  ),
                PrimaryButton(
                  label: AppStrings.createAccount,
                  isLoading: auth.busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount,
                      style: AppTextStyles.caption,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(AppStrings.loginLink, style: AppTextStyles.link),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
