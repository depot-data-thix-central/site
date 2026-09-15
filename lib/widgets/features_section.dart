import 'package:flutter/material.dart';
import '../models/content.dart';
import '../theme.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key, required this.features});
  final List<Feature> features;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: features
            .map((f) => SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(f.text,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
