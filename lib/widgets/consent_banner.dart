import 'package:flutter/material.dart';
import '../theme.dart';

class ConsentBanner extends StatelessWidget {
  const ConsentBanner({
    super.key,
    required this.text,
    required this.onAccept,
    required this.onRefuse,
  });

  final String text;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(14),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRefuse,
                  child: const Text('Refuser'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Accepter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
