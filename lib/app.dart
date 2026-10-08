import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/legal_screen.dart'; // ✅ AJOUTER CETTE LIGNE

class SonathixApp extends StatelessWidget {
  const SonathixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SONATHIX GROUP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0F172A),
          surface: Colors.white,
          onSurface: Color(0xFF0F172A),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path;
        
        // ✅ AJOUTER : route /legal
        if (path == '/legal' || path == '/politique-de-confidentialite' || path == '/conditions-d-utilisation') {
          LegalMode mode = LegalMode.both;
          if (uri.queryParameters['mode'] == 'privacy') mode = LegalMode.privacy;
          if (uri.queryParameters['mode'] == 'terms') mode = LegalMode.terms;
          return MaterialPageRoute(builder: (_) => LegalScreen(mode: mode));
        }
        
        if (path.startsWith('/admin')) {
          return MaterialPageRoute(builder: (_) => const AdminScreen());
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
    );
  }
}
