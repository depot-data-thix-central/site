import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';

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
        final path = Uri.parse(settings.name ?? '/').path;
        if (path.startsWith('/admin')) {
          return MaterialPageRoute(builder: (_) => const AdminScreen());
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
    );
  }
}
