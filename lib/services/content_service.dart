import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/content.dart';
import 'supabase_service.dart';

/// Service de chargement du contenu publié depuis Supabase.
///
/// Caractéristiques :
/// - Retry automatique avec backoff exponentiel (max 3 tentatives)
/// - Timeout configurable
/// - Validation des données reçues
/// - Cache mémoire pour éviter les requêtes répétées
/// - Logs sécurisés (pas de données sensibles en production)
/// - Jamais de crash, toujours un fallback
class ContentService {
  ContentService();

  static const Duration _requestTimeout = Duration(seconds: 8);
  static const int _maxRetries = 3;
  static const Duration _cacheTTL = Duration(minutes: 5);

  // Cache mémoire
  SiteContent? _cachedContent;
  DateTime? _cacheTimestamp;

  /// Charge le contenu publié depuis Supabase.
  ///
  /// Utilise un cache mémoire avec TTL de 5 minutes pour optimiser
  /// les performances et réduire les appels réseau.
  ///
  /// En cas d'erreur, retourne toujours un [SiteContent] vide
  /// pour éviter les crashes.
  Future<SiteContent> loadPublished({bool forceRefresh = false}) async {
    // Vérifier le cache si pas de refresh forcé
    if (!forceRefresh && _isCacheValid()) {
      _safeLog('cache_hit');
      return _cachedContent!;
    }

    final client = SupabaseService.client;
    if (client == null) {
      _safeLog('supabase_not_ready');
      return _emptyContent();
    }

    Object? lastError;

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final content = await _fetchWithTimeout(client);
        if (!kReleaseMode) {
          _safeLog('load_success', {'attempt': attempt});
        }

        // Mettre en cache
        _cachedContent = content;
        _cacheTimestamp = DateTime.now();

        return content;
      } on TimeoutException catch (e) {
        lastError = e;
        _safeLog('timeout', {
          'attempt': attempt,
          'timeout': _requestTimeout.inSeconds,
        });
      } catch (e) {
        lastError = e;
        _safeLog('fetch_failed', {
          'attempt': attempt,
          'errorType': e.runtimeType.toString(),
        });
      }

      // Attendre avant de réessayer (backoff exponentiel)
      if (attempt < _maxRetries) {
        await Future<void>.delayed(
          Duration(milliseconds: 300 * attempt),
        );
      }
    }

    // Toutes les tentatives ont échoué
    _safeLog('all_retries_failed', {
      'errorType': lastError?.runtimeType.toString() ?? 'unknown',
    });

    return _emptyContent();
  }

  /// Effectue la requête Supabase avec timeout.
  Future<SiteContent> _fetchWithTimeout(dynamic client) async {
    final row = await client
        .from('content_published')
        .select('data')
        .eq('id', 1)
        .maybeSingle()
        .timeout(_requestTimeout);

    if (row == null || row['data'] == null) {
      _safeLog('no_data_found');
      return _emptyContent();
    }

    final rawData = row['data'];

    // Validation du type
    if (rawData is! Map) {
      _safeLog('invalid_data_type', {
        'expected': 'Map',
        'actual': rawData.runtimeType.toString(),
      });
      return _emptyContent();
    }

    // Conversion sécurisée
    final Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(rawData);
    } catch (e) {
      _safeLog('map_conversion_failed', {
        'errorType': e.runtimeType.toString(),
      });
      return _emptyContent();
    }

    // Validation de la structure (optionnel, peut être étendu)
    if (!_validateStructure(data)) {
      _safeLog('invalid_structure');
      return _emptyContent();
    }

    // Parsing du modèle
    try {
      return SiteContent.fromJson(data);
    } catch (e) {
      _safeLog('json_parse_failed', {
        'errorType': e.runtimeType.toString(),
      });
      return _emptyContent();
    }
  }

  /// Vérifie si le cache est encore valide.
  bool _isCacheValid() {
    if (_cachedContent == null || _cacheTimestamp == null) return false;

    final age = DateTime.now().difference(_cacheTimestamp!);
    return age < _cacheTTL;
  }

  /// Valide la structure minimale des données.
  ///
  /// Cette méthode peut être étendue pour vérifier la présence
  /// de champs requis selon les besoins métier.
  bool _validateStructure(Map<String, dynamic> data) {
    // Vérifications basiques, peut être étendu selon les besoins
    // Exemple : vérifier la présence de clés critiques
    // final requiredKeys = ['heroTitle', 'heroParagraph'];
    // return requiredKeys.every((key) => data.containsKey(key));

    return true;
  }

  /// Retourne un contenu vide.
  SiteContent _emptyContent() {
    return const SiteContent();
  }

  /// Invalide le cache pour forcer un rechargement au prochain appel.
  void invalidateCache() {
    _cachedContent = null;
    _cacheTimestamp = null;
    _safeLog('cache_invalidated');
  }

  /// Log sécurisé : aucune donnée sensible en production.
  void _safeLog(String event, [Map<String, Object?>? context]) {
    // En production, on log uniquement les erreurs critiques
    // et jamais les données utilisateur
    if (kReleaseMode && event != 'all_retries_failed') {
      return;
    }

    final buffer = StringBuffer('[ContentService] $event');

    if (context != null && context.isNotEmpty) {
      buffer.write(
        ' | ${context.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
    }

    debugPrint(buffer.toString());
  }
}
