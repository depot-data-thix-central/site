import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// ─────────── CONFIGURATION ───────────
class Env {
  static const String supabaseUrl = 'https://vmqedusamwdgfatgtgck.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtcWVkdXNhbXdkZ2ZhdGd0Z2NrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk0MTIzNTYsImV4cCI6MjEwNDk4ODM1Nn0.-olHKoENMJXjjVTSFP0mMJRpjQs6Mt0jZUxqSux_sJI';
  static bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const String rawApiUrl = String.fromEnvironment('API_URL');
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE');

  static Uri? get newsletterEndpoint {
    if (rawApiUrl.isEmpty) return null;
    final u = Uri.tryParse(rawApiUrl);
    if (u == null || u.scheme != 'https' || !u.hasAuthority) return null;
    final path = u.path.endsWith('/') ? 'v1/newsletter' : '/v1/newsletter';
    return u.replace(path: '${u.path}$path');
  }
}

/// ─────────── VALIDATION & SANITISATION ───────────
class Validators {
  static final RegExp _email =
      RegExp(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,63}$");

  static String? validateEmail(String? value) {
    final v = sanitizeInput(value ?? '');
    if (v.isEmpty) return 'Veuillez saisir votre adresse e-mail.';
    if (v.length > 254 || !_email.hasMatch(v)) return 'Adresse e-mail invalide.';
    return null;
  }

  static String sanitizeInput(String raw, {int maxLength = 254}) {
    final cleaned = StringBuffer();
    for (final r in raw.runes) {
      if (r == 0x20 || (r >= 0x21 && r <= 0x7E) || r >= 0xA0) cleaned.writeCharCode(r);
    }
    final s = cleaned.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.length > maxLength ? s.substring(0, maxLength) : s;
  }
}

/// ─────────── URLS EXTERNES WHITELISTÉES ───────────
class SafeLaunch {
  static const Set<String> _allowedHosts = {
    'sonathix.group', 'www.sonathix.group',
    'linkedin.com', 'www.linkedin.com',
    'x.com', 'www.x.com',
    'youtube.com', 'www.youtube.com',
    't.me', 'telegram.me',
  };

  static Future<bool> open(Uri uri) async {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'mailto') {
      if (Validators.validateEmail(uri.path) != null) return false;
    } else if (scheme == 'https') {
      if (!_allowedHosts.contains(uri.host.toLowerCase())) return false;
      if (uri.userInfo.isNotEmpty) return false;
    } else {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// ─────────── CONSENTEMENT RGPD ───────────
class ConsentService {
  static const _key = 'sonathix_consent_v1';

  Future<bool?> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    return v == null ? null : v == 'granted';
  }

  Future<void> save(bool granted) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, granted ? 'granted' : 'refused');
  }
}

/// ─────────── NEWSLETTER ───────────
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
      return const RateLimited('Trop de tentatives. Réessayez plus tard.');
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
