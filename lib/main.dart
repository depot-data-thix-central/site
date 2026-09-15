import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'theme.dart';
import 'security.dart';
import 'sections.dart';
import 'admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) ui_web.usePathUrlStrategy(); // URLs propres : / et /admin
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  runApp(const SonathixApp());
  // Retire l'écran de chargement HTML après le 1er rendu
  WidgetsBinding.instance.addPostFrameCallback(
      (_) => web.document.getElementById('loading')?.remove());
}

class SonathixApp extends StatelessWidget {
  const SonathixApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SONATHIX GROUP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: (settings) {
          final isAdmin = Uri.parse(settings.name ?? '/').path.startsWith('/admin');
          return MaterialPageRoute(
              builder: (_) => isAdmin ? const AdminPage() : const PublicPage());
        },
      );
}
