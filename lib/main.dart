import 'dart:async'; // ← Requis pour runZonedGuarded
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_web_plugins/url_strategy.dart';

import 'theme.dart';
import 'security.dart';
import 'sections.dart';
import 'admin.dart';

void _reportError(Object error, StackTrace stack, {String source = 'unknown'}) {
  final msg = 'ERREUR [$source]: $error\n$stack';
  debugPrint(msg);
}

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Ecran d'erreur personnalisé
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _DebugErrorScreen(
        error: details.exceptionAsString(),
        stack: details.stack.toString(),
      );
    };

    // Logging des erreurs Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      _reportError(details.exception, details.stack ?? StackTrace.empty,
          source: 'FlutterError');
      FlutterError.presentError(details);
    };

    // URLs propres sans /#/
    if (kIsWeb) {
      usePathUrlStrategy();
    }

    void removeLoading() {
      try {
        web.document.getElementById('loading')?.remove();
      } catch (_) {}
    }

    // Initialisation Supabase
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
    } catch (e, st) {
      _reportError(e, st, source: 'Supabase.initialize');
    }

    runApp(const SonathixApp());

    // Retrait de l'écran de chargement
    WidgetsBinding.instance.addPostFrameCallback((_) => removeLoading());
    Future.delayed(const Duration(milliseconds: 800), removeLoading);
  }, (error, stack) {
    _reportError(error, stack, source: 'runZonedGuarded');
  });
}

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
