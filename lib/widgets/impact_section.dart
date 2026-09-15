import 'package:flutter/material.dart';
import '../models/content.dart';
import '../theme.dart';

class ImpactSection extends StatelessWidget {
  const ImpactSection({super.key, required this.stats, required this.quote});
  final List<Stat> stats;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      color: AppColors.surface,
      child: Column(
        children: [
          if (stats.isNotEmpty)
            Wrap(
              spacing: 40,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: stats
                  .map((s) => Column(
                        children: [
                          Text(s.value,
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(s.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ))
                  .toList(),
            ),
          if (quote.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(quote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
