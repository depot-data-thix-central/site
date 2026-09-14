import 'package:flutter/material.dart';

class R {
  static const double maxContent = 1200;
  static double width(BuildContext c) => MediaQuery.sizeOf(c).width;
  static bool isMobile(BuildContext c)  => width(c) < 640;
  static bool isDesktop(BuildContext c) => width(c) >= 1024;

  static Widget centered(BuildContext context, Widget child,
          {double padding = 24}) =>
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContent),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding), child: child),
        ),
      );

  /// Grille responsive sans GridView (compatible SingleChildScrollView).
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
