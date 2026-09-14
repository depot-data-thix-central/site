/// Validation & sanitisation strictes de toutes les entrées utilisateur.
class Validators {
  static final RegExp _email =
      RegExp(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,63}$");

  static String? validateEmail(String? value) {
    final v = sanitizeInput(value ?? '');
    if (v.isEmpty) return 'Veuillez saisir votre adresse e-mail.';
    if (v.length > 254 || !_email.hasMatch(v)) return 'Adresse e-mail invalide.';
    return null;
  }

  /// Supprime caractères de contrôle, bornes Unicode, collapse espaces, tronque.
  static String sanitizeInput(String raw, {int maxLength = 254}) {
    final cleaned = StringBuffer();
    for (final r in raw.runes) {
      if (r == 0x20 || (r >= 0x21 && r <= 0x7E) || r >= 0xA0) {
        cleaned.writeCharCode(r);
      }
    }
    final s = cleaned.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.length > maxLength ? s.substring(0, maxLength) : s;
  }
}
