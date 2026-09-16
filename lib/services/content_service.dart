import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/content.dart';
import 'supabase_service.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  static const Duration _requestTimeout = Duration(seconds: 8);
  static const int _maxRetries = 3;
  static const Duration _cacheTTL = Duration(minutes: 5);

  SiteContent? _cached;
  DateTime? _cachedAt;
  Future<SiteContent>? _inFlightRequest;

  Future<SiteContent> loadPublished({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid()) {
      _log('cache_hit');
      return _cached!;
    }

    // Réutilise la requête en cours si un chargement est déjà lancé
    if (_inFlightRequest != null) {
      _log('joining_in_flight_request');
      return _inFlightRequest!;
    }

    _inFlightRequest = _fetchWithRetry();
    try {
      return await _inFlightRequest!;
    } finally {
      _inFlightRequest = null;
    }
  }

  Future<SiteContent> _fetchWithRetry() async {
    final client = SupabaseService.client;
    if (client == null) {
      _log('supabase_not_ready');
      return _cached ?? _fallback();
    }

    Object? lastError;

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final content = await _fetch(client);
        _cached = content;
        _cachedAt = DateTime.now();
        _log('load_success', {'attempt': attempt});
        return content;
      } on TimeoutException catch (e) {
        lastError = e;
        _log('timeout', {'attempt': attempt});
      } catch (e) {
        lastError = e;
        _log('fetch_failed', {
          'attempt': attempt,
          'errorType': e.runtimeType.toString(),
        });
      }

      if (attempt < _maxRetries) {
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }

    _log('all_retries_failed', {
      'errorType': lastError?.runtimeType.toString() ?? 'unknown',
    });

    if (_cached != null) {
      _log('stale_cache_fallback');
      return _cached!;
    }

    return _fallback();
  }

  Future<SiteContent> _fetch(dynamic client) async {
    final row = await client
        .from('content_published')
        .select('*')
        .eq('id', 1)
        .maybeSingle()
        .timeout(_requestTimeout);

    if (row == null) {
      _log('no_data');
      return _cached ?? _fallback();
    }

    try {
      final data = Map<String, dynamic>.from(row as Map);
      return SiteContent.fromJson(data);
    } catch (e, st) {
      _log('parse_failed', {
        'error': e.toString(),
        'trace': st.toString(),
      });
      return _cached ?? _fallback();
    }
  }

  bool _isCacheValid() {
    if (_cached == null || _cachedAt == null) return false;
    return DateTime.now().difference(_cachedAt!) < _cacheTTL;
  }

  void invalidateCache() {
    _cached = null;
    _cachedAt = null;
    _inFlightRequest = null;
    _log('cache_invalidated');
  }

  SiteContent _fallback() => const SiteContent();

  void _log(String event, [Map<String, Object?>? ctx]) {
    if (kReleaseMode && event != 'all_retries_failed') return;
    final b = StringBuffer('[ContentService] $event');
    if (ctx != null && ctx.isNotEmpty) {
      b.write(
        ' | (${ctx.entries.map((e) => '${e.key}=${e.value}').join(', ')})',
      );
    }
    debugPrint(b.toString());
  }
}
