import 'package:cleancycle_mobileapp/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty and invalid', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a simple address', () {
      expect(Validators.email('resident@cleancycle.app'), isNull);
    });
  });

  group('Validators.password', () {
    test('requires 8 characters', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short1!'), isNotNull);
      expect(Validators.password('longenough'), isNull);
    });

    test('loginPassword only checks non-empty', () {
      expect(Validators.loginPassword(''), isNotNull);
      expect(Validators.loginPassword('x'), isNull);
    });
  });

  group('Validators.strength and reset rules', () {
    test('weak / medium / strong', () {
      expect(Validators.strength('abc'), PasswordStrength.weak);
      expect(Validators.strength('abcdefgh'), PasswordStrength.weak);
      expect(Validators.strength('abcdefg1'), PasswordStrength.medium);
      expect(Validators.strength('abcdefg!'), PasswordStrength.medium);
      expect(Validators.strength('abcdefg1!'), PasswordStrength.strong);
    });

    test('meetsResetRules needs length, number and special', () {
      expect(Validators.meetsResetRules('abcdefgh'), isFalse);
      expect(Validators.meetsResetRules('abcdefg1'), isFalse);
      expect(Validators.meetsResetRules('abcdefg1!'), isTrue);
    });
  });

  group('Validators.name / phone / address / confirm', () {
    test('name', () {
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Ann'), isNull);
    });

    test('phone', () {
      expect(Validators.phone('12'), isNotNull);
      expect(Validators.phone('0771234567'), isNull);
    });

    test('addressZone', () {
      expect(Validators.addressZone('ab'), isNotNull);
      expect(Validators.addressZone('Zone 3'), isNull);
    });

    test('confirmPassword', () {
      expect(Validators.confirmPassword('a', 'b'), isNotNull);
      expect(Validators.confirmPassword('same', 'same'), isNull);
    });
  });
}
