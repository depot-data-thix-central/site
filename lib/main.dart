import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_web_plugins/url_strategy.dart';

import 'theme.dart';
import 'security.dart';
import 'sections.dart';
import 'admin.dart';

// ✅ NOUVEAU : dernière erreur capturée, affichée à l'écran quel que soit
// le mode de build (debug ou release), pour diagnostiquer sans devtools.
String? _lastErrorDetails;

void _reportError(Object error, StackTrace stack, {String source = 'unknown'}) {
  final msg = 'ERREUR [$source]: $error\n$stack';
  debugPrint(msg);
  _lastErrorDetails = msg;
}

Future<void> main() async {
  // ✅ NOUVEAU : capture toute exception non gérée (async ou synchrone,
  // dans ou hors du cycle de build Flutter).
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ✅ NOUVEAU : affiche l'erreur à l'écran au lieu du rectangle gris
    // silencieux par défaut du mode release. Actif dans TOUS les modes.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _DebugErrorScreen(
        error: details.exceptionAsString(),
        stack: details.stack.toString(),
      );
    };

    // ✅ NOUVEAU : les erreurs Flutter (build/layout/paint) sont aussi
    // loggées explicitement, en plus d'être affichées via ErrorWidget.
    FlutterError.onError = (FlutterErrorDetails details) {
      _reportError(details.exception, details.stack ?? StackTrace.empty,
          source: 'FlutterError');
      FlutterError.presentError(details);
    };

    // URLs propres : / et /admin (au lieu de /#/ et /#/admin)
    if (kIsWeb) {
      usePathUrlStrategy();
    }

    // Fonction pour retirer l'écran de chargement HTML
    void removeLoading() {
      try {
        web.document.getElementById('loading')?.remove();
      } catch (_) {}
    }

    // Initialisation Supabase (clé publique)
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey, // ← nouveau nom (remplace anonKey)
      );
    } catch (e, st) {
      _reportError(e, st, source: 'Supabase.initialize');
      // On continue quand même pour afficher le site
    }

    runApp(const SonathixApp());

    // Retire le loading après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) => removeLoading());

    // Sécurité supplémentaire (au cas où)
    Future.delayed(const Duration(milliseconds: 800), removeLoading);
  }, (error, stack) {
    // ✅ NOUVEAU : filet de sécurité final — toute erreur qui échapperait
    // à FlutterError.onError (ex: erreur async dans un Future non-awaité)
    // finit ici.
    _reportError(error, stack, source: 'runZonedGuarded');
  });
}

/// ✅ NOUVEAU : écran d'erreur lisible, actif en debug ET en release.
/// Remplace le rectangle gris par défaut de Flutter.
class _DebugErrorScreen extends StatelessWidget {
  const _DebugErrorScreen({required this.error, required this.stack});
  final String error;
  final String stack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2D0A0A),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Erreur de rendu',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SelectableText(error,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
            const SizedBox(height: 8),
            SelectableText(stack,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class SonathixApp extends StatelessWidget {
  const SonathixApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SONATHIX GROUP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: (settings) {
          final isAdmin =
              Uri.parse(settings.name ?? '/').path.startsWith('/admin');
          return MaterialPageRoute(
            builder: (_) => isAdmin ? const AdminPage() : const PublicPage(),
          );
        },
      );
}
