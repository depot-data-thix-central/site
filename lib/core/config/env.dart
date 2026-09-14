/// Configuration injectée UNIQUEMENT au build (--dart-define).
/// Aucun secret ne doit jamais être embarqué côté client.
class Env {
  static const String rawApiUrl = String.fromEnvironment('API_URL');
  static const bool demoMode    = bool.fromEnvironment('DEMO_MODE');
  static const String contactEmail = String.fromEnvironment(
      'CONTACT_EMAIL', defaultValue: 'contact@sonathix.group');

  /// Endpoint newsletter. Refusé si non-HTTPS (fail-safe).
  static Uri? get newsletterEndpoint {
    if (rawApiUrl.isEmpty) return null;
    final u = Uri.tryParse(rawApiUrl);
    if (u == null || u.scheme != 'https' || !u.hasAuthority) return null;
    final path = u.path.endsWith('/') ? 'v1/newsletter' : '/v1/newsletter';
    return u.replace(path: '${u.path}$path');
  }
}
