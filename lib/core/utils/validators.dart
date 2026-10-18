/// Pure validation helpers — no Flutter widgets, easy to unit test.
///
/// HCI: error prevention. Screens use these to disable the CTA until the
/// form is valid and to show inline messages instead of a generic failure.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _digitRegex = RegExp(r'\d');
  static final _specialRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`]');
  static final _phoneRegex = RegExp(r'^\+?[\d\s\-()]{9,18}$');

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your full name.';
    if (text.length < 2) return 'Name must be at least 2 characters.';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email address.';
    if (!_emailRegex.hasMatch(text)) return 'Enter a valid email address.';
    return null;
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your phone number.';
    if (!_phoneRegex.hasMatch(text)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  /// Address / zone is required by the CRUD spec (not shown on the Figma form).
  static String? addressZone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your address or collection zone.';
    if (text.length < 3) return 'Address / zone is too short.';
    return null;
  }

  /// Login only checks that a password was entered (strength is a register rule).
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter a password.';
    if (text.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static bool hasMinLength(String password) => password.length >= 8;

  static bool hasNumber(String password) => _digitRegex.hasMatch(password);

  static bool hasSpecial(String password) => _specialRegex.hasMatch(password);

  /// Live strength used by Create Account (Weak / Medium / Strong).
  static PasswordStrength strength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    final length = hasMinLength(password);
    final number = hasNumber(password);
    final special = hasSpecial(password);
    final score = [length, number, special].where((ok) => ok).length;
    if (!length || score == 1) return PasswordStrength.weak;
    if (score == 2) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Reset-password CTA stays disabled until every rule is green.
  static bool meetsResetRules(String password) =>
      hasMinLength(password) && hasNumber(password) && hasSpecial(password);
}

enum PasswordStrength { empty, weak, medium, strong }

extension PasswordStrengthLabel on PasswordStrength {
  String get label => switch (this) {
        PasswordStrength.empty => '',
        PasswordStrength.weak => 'Weak',
        PasswordStrength.medium => 'Medium',
        PasswordStrength.strong => 'Strong',
      };
}
