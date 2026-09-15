import 'package:flutter/material.dart';
import '../models/content.dart';
import '../theme.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key, required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: AppColors.primary,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFD9B23A), Color(0xFFB8860B)],
              ),
            ),
            child: const Center(
              child: Text('S',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          const Text('SONATHIX',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          const Spacer(),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }
}
