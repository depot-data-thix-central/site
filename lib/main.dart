import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:web/web.dart' as web;

import 'app.dart';
import 'services/supabase_service.dart';

// ══════════════════════════════════════════════════════════════
// POINT D'ENTRÉE PRINCIPAL
// ═══════════════════════════════════════════════════════════════

Future<void> main() async {
  // Initialisation obligatoire avant tout appel à Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Stratégie d'URL pour le web (sans le # dans l'URL)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // ✅ CORRECTIF 1 : Supabase ne bloque JAMAIS le démarrage
  // (timeout 10s + catch global pour éviter le splash infini)
  try {
    await SupabaseService.init().timeout(const Duration(seconds: 10));
    debugPrint('[Main] ✅ Supabase initialisé avec succès');
  } catch (e, st) {
    debugPrint('[Main] ⚠️ Supabase init échouée (mode dégradé) : $e');
    if (kDebugMode) debugPrint('$st');
  }

  // ✅ CORRECTIF 2 : Annule le garde-fou HTML AVANT runApp
  // (évite que le message d'erreur HTML apparaisse si Flutter démarre)
  _clearHtmlTimeout();

  // ✅ CORRECTIF 3 : Supprime le splash screen AVANT runApp
  // (garantie qu'il disparaît même si runApp plante)
  _removeSplash();

  // ✅ CORRECTIF 4 : runApp dans un try/catch pour ne jamais mourir silencieusement
  try {
    runApp(const SonathixApp());
    debugPrint('[Main] ✅ Flutter démarré avec succès');
  } catch (e, st) {
    debugPrint('[Main] ❌ Erreur runApp : $e');
    if (kDebugMode) debugPrint('$st');
    // Affichage d'une UI d'erreur visible au lieu d'un écran noir
    runApp(_ErrorApp(error: e.toString()));
  }

  // ✅ CORRECTIF 5 : Double sécurité — suppression post-frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _removeSplash();
    debugPrint('[Main] ✅ Premier frame rendu, splash supprimé');
  });
}

// ══════════════════════════════════════════════════════════════
// HELPERS — Suppression du splash HTML
// ═══════════════════════════════════════════════════════════════

/// Annule le timeout de garde-fou dans index.html
void _clearHtmlTimeout() {
  try {
    if (kIsWeb) {
      web.window.callMethod('__clearSplashTimeout'.toJS);
    }
  } catch (_) {}
}

/// Supprime le spinner HTML de index.html (idempotent)
void _removeSplash() {
  try {
    if (kIsWeb) {
      final el = web.document.getElementById('loading');
      el?.remove();
    }
  } catch (_) {}
}

// ═══════════════════════════════════════════════════════════════
// UI D'URGENCE — Affichée si runApp() lui-même plante
// ═══════════════════════════════════════════════════════════════

class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Erreur de démarrage',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC9A227),
          surface: Color(0xFF0F172A),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFC9A227),
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Impossible de démarrer l\'application',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Une erreur critique est survenue lors du démarrage. Veuillez contacter l\'administrateur.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: SelectableText(
                      error,
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      if (kIsWeb) {
                        web.window.location.reload();
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Recharger la page'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A227),
                      foregroundColor: const Color(0xFF0A1628),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
