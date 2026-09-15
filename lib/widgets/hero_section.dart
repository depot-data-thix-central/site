import 'package:flutter/material.dart';
import '../models/content.dart';
import '../theme.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.displayLarge,
              children: [
                TextSpan(text: content.heroTitle),
                TextSpan(
                  text: content.heroHighlight,
                  style: const TextStyle(color: AppColors.gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              content.heroParagraph,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.primary,
                ),
                child: Text(content.ctaPrimary),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: Text(content.ctaSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
