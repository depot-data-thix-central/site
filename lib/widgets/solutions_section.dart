import 'package:flutter/material.dart';
import '../models/content.dart';
import '../theme.dart';

class SolutionsSection extends StatelessWidget {
  const SolutionsSection({super.key, required this.solutions});
  final List<Solution> solutions;

  @override
  Widget build(BuildContext context) {
    if (solutions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nos solutions',
              style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: solutions
                .map((s) => Container(
                      width: 280,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: s.featured
                            ? AppColors.surface
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: s.featured
                              ? AppColors.gold.withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17)),
                          const SizedBox(height: 4),
                          Text(s.subtitle,
                              style: const TextStyle(
                                  color: AppColors.gold, fontSize: 12)),
                          const SizedBox(height: 10),
                          Text(s.text,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 13)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
