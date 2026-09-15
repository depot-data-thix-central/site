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

  // URLs propres
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // On retire le loading le plus tôt possible
  void removeLoading() {
    try {
      web.document.getElementById('loading')?.remove();
    } catch (_) {}
  }

  // Initialisation Supabase avec protection
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } catch (e, st) {
    debugPrint('Erreur Supabase.initialize: $e\n$st');
    // On continue quand même pour afficher le site (même sans contenu)
  }

  runApp(const SonathixApp());

  // Sécurité supplémentaire : on enlève le loading après le premier frame
  WidgetsBinding.instance.addPostFrameCallback((_) => removeLoading());

  // Et aussi après un petit délai au cas où
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
