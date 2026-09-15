import 'package:flutter/material.dart';
import '../theme.dart';

class Footer extends StatelessWidget {
  const Footer({super.key, required this.legal});
  final String legal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: AppColors.primary,
      child: Text(
        legal,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
