import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../utils/validators.dart';

sealed class NewsletterResult {
  const NewsletterResult(this.message);
  final String message;
}
class Success      extends NewsletterResult { const Success(super.m); }
class InvalidInput extends NewsletterResult { const InvalidInput(super.m); }
class RateLimited  extends NewsletterResult { const RateLimited(super.m); }
class NetworkError extends NewsletterResult { const NetworkError(super.m); }
class ServerError  extends NewsletterResult { const ServerError(super.m); }
class ConfigError  extends NewsletterResult { const ConfigError(super.m); }

/// Inscription newsletter : validation, rate-limiting client, timeout,
/// HTTPS-only, aucun log de l'e-mail, aucune tentative infinie.
class NewsletterService {
  NewsletterService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout  = Duration(seconds: 10);
  static const Duration _cooldown = Duration(seconds: 30);
  static const int _maxAttempts   = 5;

  DateTime? _lastSubmit;
  int _attempts = 0;

  Future<NewsletterResult> subscribe(String email) async {
    final clean = Validators.sanitizeInput(email);
    final error = Validators.validateEmail(clean);
    if (error != null) return InvalidInput(error);

    final now = DateTime.now();
    if (_lastSubmit != null && now.difference(_lastSubmit!) < _cooldown) {
      final wait = _cooldown.inSeconds - now.difference(_lastSubmit!).inSeconds;
      return RateLimited('Merci de patienter encore ${wait}s.');
    }
    if (_attempts >= _maxAttempts) {
      return RateLimited('Trop de tentatives. Réessayez plus tard.');
    }
    _attempts++;
    _lastSubmit = now;

    final endpoint = Env.newsletterEndpoint;
    if (endpoint == null) {
      if (Env.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return const Success('Merci ! Inscription enregistrée (mode démo).');
      }
      return const ConfigError('Service newsletter non configuré.');
    }

    try {
      final res = await _client
          .post(endpoint,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'email': clean, 'consent': true, 'source': 'web'}))
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return const Success('Merci ! Vous êtes inscrit(e) à la newsletter.');
      }
      if (res.statusCode == 429) return const RateLimited('Trop de requêtes.');
      return const ServerError('Erreur serveur. Réessayez plus tard.');
    } on TimeoutException {
      return const NetworkError('Délai dépassé. Vérifiez votre connexion.');
    } on http.ClientException {
      return const NetworkError('Connexion impossible au serveur.');
    } catch (_) {
      return const NetworkError('Erreur réseau inattendue.');
    }
  }
}
