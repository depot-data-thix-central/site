import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_web_plugins/url_strategy.dart';

import 'theme.dart';
import 'security.dart';
import 'sections.dart';
import 'admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    debugPrint('Erreur Supabase.initialize: $e\n$st');
    // On continue quand même pour afficher le site
  }

  runApp(const SonathixApp());

  // Retire le loading après le premier rendu
  WidgetsBinding.instance.addPostFrameCallback((_) => removeLoading());

  // Sécurité supplémentaire (au cas où)
  Future.delayed(const Duration(milliseconds: 800), removeLoading);
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
