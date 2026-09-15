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
      expect(Validators.validateEmail('x@y.${'a' * 64}'), isNotNull);
    });
  });

  group('Validators.sanitizeInput', () {
    test('supprime caractères de contrôle et espaces multiples', () {
      // ⚠️ Caractères de contrôle en échappements Unicode (copier-coller sûr)
      expect(Validators.sanitizeInput('a\u0000b\u0007c\u001B'), 'abc');
      expect(Validators.sanitizeInput('bonjour\u0009monde\u000D!'), 'bonjourmonde!');
      expect(Validators.sanitizeInput('  multi   espaces '), 'multi espaces');
    });

    test('tronque à maxLength', () {
      expect(Validators.sanitizeInput('a' * 300, maxLength: 10).length, 10);
    });

    test('conserve les caractères accentués et la ponctuation', () {
      expect(Validators.sanitizeInput('  Afrique & sécurité  '),
          'Afrique & sécurité');
    });
  });
}
