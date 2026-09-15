import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';

class SonathixApp extends StatelessWidget {
  const SonathixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SONATHIX GROUP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
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
