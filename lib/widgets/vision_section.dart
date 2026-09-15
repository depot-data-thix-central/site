import 'package:flutter/material.dart';

class VisionSection extends StatelessWidget {
  const VisionSection({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .displayMedium
            ?.copyWith(fontSize: 22),
      ),
    );
  }
}
