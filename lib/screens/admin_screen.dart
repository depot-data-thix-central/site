import 'package:flutter/material.dart';
import '../theme.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: AppColors.surface,
      ),
      body: const Center(
        child: Text(
          'Espace admin (à connecter plus tard)',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
