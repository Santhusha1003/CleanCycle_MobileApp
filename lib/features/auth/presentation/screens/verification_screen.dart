import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_controller.dart';

/// Figma 6-digit layout. A 6-digit code is emailed to the registered address.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const _otpLength = 6;
  static const _validSeconds = 90;

  final _nodes = List.generate(_otpLength, (_) => FocusNode());
  final _controllers = List.generate(_otpLength, (_) => TextEditingController());
  Timer? _timer;
  int _remaining = _validSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = context.read<AuthController>().errorMessage;
      if (message != null) _toast(message);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final node in _nodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  String get _clock {
    final minutes = _remaining ~/ 60;
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _validSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, _otpLength - 1);
      _nodes[next].requestFocus();
      setState(() {});
      return;
    }
    if (value.isNotEmpty && index < _otpLength - 1) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _resend() async {
    if (_remaining > 0) return;
    final auth = context.read<AuthController>();
    final ok = await auth.resendVerificationEmail();
    if (!mounted) return;
    if (ok) {
      for (final controller in _controllers) {
        controller.clear();
      }
      _nodes.first.requestFocus();
      _startTimer();
      _toast('A new 6-digit code was sent. Check inbox and Spam.');
    } else if (auth.errorMessage != null) {
      _toast(auth.errorMessage!);
    }
  }

  Future<void> _verify() async {
    final auth = context.read<AuthController>();
    final verified = await auth.verifyEmailOtp(_code);
    if (!mounted) return;
    if (verified) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    _toast(auth.errorMessage ?? 'Enter the 6-digit code from your email.');
  }

  Future<void> _changeEmail() async {
    await context.read<AuthController>().signOut();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final email = auth.firebaseUser?.email ?? auth.profile?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        visible: auth.busy,
        child: SafeArea(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Column(
              children: [
                const SizedBox(height: 24),
                const BrandHeader(compact: true),
                const SizedBox(height: 28),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.verificationTitle,
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email.isEmpty
                      ? '${AppStrings.verificationSubtitle} your email.'
                      : '${AppStrings.verificationSubtitle} $email',
                  style: AppTextStyles.screenSubtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_otpLength, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _nodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: index == _otpLength - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        style: AppTextStyles.screenTitle,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(index == 0 ? 6 : 1),
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputFill,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onDigitChanged(index, value),
                        onSubmitted: (_) {
                          if (_code.length == 6) _verify();
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (_remaining > 0)
                  Text(
                    '${AppStrings.didntReceiveCode} $_clock',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  )
                else
                  TextButton(
                    onPressed: _resend,
                    child: const Text(AppStrings.resendCode),
                  ),
                TextButton(
                  onPressed: _changeEmail,
                  child: const Text(AppStrings.changeEmail),
                ),
                const Spacer(),
                PrimaryButton(
                  label: AppStrings.verify,
                  isLoading: auth.busy,
                  onPressed: _verify,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
