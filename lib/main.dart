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

  // Supabase (ne bloque jamais le démarrage)
  await SupabaseService.init();

  runApp(const SonathixApp());

  // Retire le spinner HTML
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      web.document.getElementById('loading')?.remove();
    } catch (_) {}
  });
}
