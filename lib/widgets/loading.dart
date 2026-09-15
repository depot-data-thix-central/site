import 'package:flutter/material.dart';
import '../theme.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(color: AppColors.gold);
  }
}
