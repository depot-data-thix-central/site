import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme.dart';

class SolutionsSection extends StatefulWidget {
  const SolutionsSection({super.key, required this.solutions});

  final List<Solution> solutions;

  @override
  State<SolutionsSection> createState() => _SolutionsSectionState();
}

class _SolutionsSectionState extends State<SolutionsSection>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  int _columns(double width) {
    if (width < 640) return 1;
    if (width < 960) return 2;
    if (width < 1280) return 3;
    return 4;
  }

  Interval _interval(int index, int total) {
    const visible = 0.35;
    final step = total <= 1 ? 0.0 : (1.0 - visible) / (total - 1);
    final start = (index * step).clamp(0.0, 1.0).toDouble();
    final end = (start + visible).clamp(0.0, 1.0).toDouble();
    return Interval(start, end, curve: Curves.easeOutCubic);
  }

  Widget _animatedCard(int index, int total, Widget child) {
    final animation = _entranceController.drive(
      CurveTween(curve: _interval(index, total)),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  List<List<Widget>> _chunk(List<Widget> cards, int cols) {
    final rows = <List<Widget>>[];
    for (var i = 0; i < cards.length; i += cols) {
      final end = (i + cols) > cards.length ? cards.length : i + cols;
      rows.add(cards.sublist(i, end));
    }
    return rows;
  }

  Widget _buildRow(List<Widget> row, int cols) {
    final children = <Widget>[];
    for (var i = 0; i < cols; i++) {
      if (i > 0) children.add(const SizedBox(width: 20));
      if (i < row.length) {
        children.add(Expanded(child: row[i]));
      } else {
        children.add(const Expanded(child: SizedBox.shrink()));
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nos solutions',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Container(
              width: 72 * value,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.7),
                    AppColors.gold,
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.solutions;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = _columns(constraints.maxWidth);

              final cards = <Widget>[];
              for (var i = 0; i < items.length; i++) {
                cards.add(
                  _animatedCard(
                    i,
                    items.length,
                    _SolutionCard(solution: items[i]),
                  ),
                );
              }

              final rows = _chunk(cards, cols);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 36),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildRow(row, cols),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SolutionCard extends StatefulWidget {
  const _SolutionCard({required this.solution});

  final Solution solution;

  @override
  State<_SolutionCard> createState() => _SolutionCardState();
}

class _SolutionCardState extends State<_SolutionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.solution;
    final featured = s.featured;

    final title = _SolutionsSecurity.text(s.title, maxLength: 90);
    final subtitle = _SolutionsSecurity.text(s.subtitle, maxLength: 130);
    final text = _SolutionsSecurity.text(s.text, maxLength: 420);

    final titleColor = featured ? Colors.white : const Color(0xFF111827);
    final subtitleColor =
        featured ? AppColors.gold : const Color(0xFFB45309);
    final textColor = featured ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: featured ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: featured
                  ? AppColors.gold.withValues(alpha: _hover ? 0.75 : 0.35)
                  : const Color(0xFFE5E7EB),
              width: featured ? 1.4 : 1,
            ),
            boxShadow: [
              if (featured)
                BoxShadow(
                  color: AppColors.gold
                      .withValues(alpha: _hover ? 0.28 : 0.14),
                  blurRadius: _hover ? 32 : 22,
                  offset: const Offset(0, 14),
                )
              else
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, _hover ? 0.12 : 0.06),
                  blurRadius: _hover ? 28 : 18,
                  offset: Offset(0, _hover ? 12 : 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (featured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 13,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'À la une',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolutionsSecurity {
  const _SolutionsSecurity._();

  static String text(String? value, {int maxLength = 400}) {
    if (value == null || value.isEmpty) return '';

    final cleaned = value
        .replaceAll(
          RegExp(
            r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFEFF\u202A-\u202E\u2066-\u2069]',
          ),
          '',
        )
        .trim();

    return _truncateSafely(cleaned, maxLength);
  }

  static String _truncateSafely(String value, int maxLength) {
    if (value.length <= maxLength) return value;

    final truncated = value.substring(0, maxLength);
    if (truncated.isEmpty) return '';

    final last = truncated.codeUnitAt(truncated.length - 1);
    if (last >= 0xD800 && last <= 0xDBFF) {
      return truncated.substring(0, truncated.length - 1);
    }

    return truncated;
  }
}
