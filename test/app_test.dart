import 'package:flutter_test/flutter_test.dart';
import 'package:sonathix_web/security.dart';

void main() {
  group('Validators.validateEmail', () {
    test('accepte les e-mails valides', () {
      expect(Validators.validateEmail('nathan@sonathix.group'), isNull);
      expect(Validators.validateEmail('a.b+c@d.co'), isNull);
    });
    test('rejette les e-mails invalides', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('pas-un-email'), isNotNull);
      expect(Validators.validateEmail('a@b'), isNotNull);
    });
  });

  group('Validators.sanitizeInput', () {
    test('supprime caractères de contrôle et espaces multiples', () {
      expect(Validators.sanitizeInput('a�bc'), 'abc');
      expect(Validators.sanitizeInput('  multi   espaces '), 'multi espaces');
    });
    test('tronque à maxLength', () {
      expect(Validators.sanitizeInput('a' * 300, maxLength: 10).length, 10);
    });
  });
}
