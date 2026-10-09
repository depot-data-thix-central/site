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

  try {
    await SupabaseService.init().timeout(const Duration(seconds: 10));
    debugPrint('[Main] ✅ Supabase initialisé');
  } catch (e, st) {
    debugPrint('[Main] ⚠️ Supabase init échouée (mode dégradé) : $e');
    if (kDebugMode) debugPrint('$st');
  }

  _removeSplash();

  try {
    runApp(const SonathixApp());
  } catch (e, st) {
    debugPrint('[Main] ❌ Erreur runApp : $e');
    runApp(_ErrorApp(error: e.toString()));
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _removeSplash();
  });
}

void _removeSplash() {
  try {
    if (kIsWeb) {
      final el = web.document.getElementById('loading');
      el?.remove();
    }
  } catch (_) {}
}

class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFC9A227), size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Impossible de démarrer l\'application',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // ✅ Utilise withValues (compatible Flutter 3.27+)
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(color: Color(0xFFE5E7EB), fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (kIsWeb) web.window.location.reload();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recharger la page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
