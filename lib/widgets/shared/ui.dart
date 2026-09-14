import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.label, this.onTap,
      this.icon = Icons.arrow_forward, this.loading = false});
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: loading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(
                    color: Color(0x33C9A227), blurRadius: 18, offset: Offset(0, 6))]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (loading)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: AppColors.primaryDark))
              else ...[
                Text(label, style: AppTheme.buttonLabel),
                const SizedBox(width: 8),
                Icon(icon, size: 16, color: AppColors.primaryDark),
              ],
            ]),
          ),
        ),
      );
}

class OutlineButton extends StatelessWidget {
  const OutlineButton({super.key, required this.label, this.onTap,
      this.icon, this.onLight = false});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final color = onLight ? AppColors.primaryDark : Colors.white;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withValues(alpha: .45))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 14, color: color)],
          ]),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 24, height: 2, color: AppColors.gold),
        const SizedBox(width: 10),
        Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 11, letterSpacing: 1.6,
                fontWeight: FontWeight.w700, color: AppColors.gold)),
      ]);
}
