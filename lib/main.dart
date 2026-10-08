import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:web/web.dart' as web;

import 'app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // ✅ CORRECTIF : Supabase ne doit JAMAIS empêcher le démarrage.
  // Avant : une exception ici bloquait runApp() → splash infini.
  try {
    await SupabaseService.init().timeout(const Duration(seconds: 10));
  } catch (e, st) {
    debugPrint('[Main] Supabase init échouée (mode dégradé) : $e');
    if (kDebugMode) debugPrint('$st');
  }

  // ✅ CORRECTIF : garantie que le spinner HTML disparaît,
  // même si le premier frame tarde ou échoue.
  _removeSplash();

  runApp(const SonathixApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _removeSplash();
  });
}

/// Retire le spinner HTML de index.html (idempotent).
void _removeSplash() {
  try {
    web.document.getElementById('loading')?.remove();
  } catch (_) {}
}
