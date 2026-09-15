import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color surfaceDark = Color(0xFF10203A);
  static const Color gold        = Color(0xFFC9A227);
  static const Color goldLight   = Color(0xFFE3C04B);
  static const Color lightGray   = Color(0xFFF5F7FA);
  static const Color textMuted   = Color(0xFF8A94A6);
  static const Color success     = Color(0xFF16A34A);
  static const Color danger      = Color(0xFFDC2626);

  static const LinearGradient goldGradient =
      LinearGradient(colors: [Color(0xFFD9B23A), Color(0xFFB8860B)]);
  static const LinearGradient heroGradient = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF0B1B33), Color(0xFF0A1628), Color(0xFF071120)]);
}

class AppTheme {
  static const TextStyle buttonLabel = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: AppColors.primaryDark, letterSpacing: .3);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.dark(
            primary: AppColors.gold, surface: AppColors.primaryDark),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 44, height: 1.15,
              fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
              color: AppColors.primaryDark, letterSpacing: -0.3),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        popupMenuTheme: const PopupMenuThemeData(
            color: AppColors.surfaceDark,
            textStyle: TextStyle(color: Colors.white, fontSize: 13)),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        fontFamily: 'Inter',
        fontFamilyFallback: const ['Inter', 'Segoe UI', 'Roboto',
            'Helvetica Neue', 'Arial', 'Noto Sans'],
      );
}

class R {
  static const double maxContent = 1200;
  static double width(BuildContext c) => MediaQuery.sizeOf(c).width;
  static bool isDesktop(BuildContext c) => width(c) >= 1024;

  static Widget centered(Widget child, {double padding = 24}) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContent),
          child: Padding(padding: EdgeInsets.symmetric(horizontal: padding), child: child),
        ),
      );

  static Widget grid(List<Widget> children,
      {int desktop = 4, int tablet = 2, int mobile = 1,
       double spacing = 16, double runSpacing = 16}) {
    return LayoutBuilder(builder: (context, c) {
      final n = c.maxWidth >= 1024 ? desktop : (c.maxWidth >= 640 ? tablet : mobile);
      final cw = (c.maxWidth - spacing * (n - 1)) / n;
      return Wrap(spacing: spacing, runSpacing: runSpacing,
          children: [for (final ch in children) SizedBox(width: cw, child: ch)]);
    });
  }
}

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
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryDark))
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
            Text(label, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: color)),
            if (icon != null) ...[
              const SizedBox(width: 8), Icon(icon, size: 14, color: color)],
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
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 24, height: 2, color: AppColors.gold),
        const SizedBox(width: 10),
        Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 11, letterSpacing: 1.6,
                fontWeight: FontWeight.w700, color: AppColors.gold)),
      ]);
}
