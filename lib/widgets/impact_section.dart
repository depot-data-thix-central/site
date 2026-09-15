import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme.dart';
import 'loading.dart';

class ImpactSection extends StatefulWidget {
  const ImpactSection({
    super.key,
    required this.stats,
    required this.quote,
    this.imageUrl,
    this.imageAsset,
  });

  final List<Stat> stats;
  final String quote;
  final String? imageUrl;
  final String? imageAsset;

  @override
  State<ImpactSection> createState() => _ImpactSectionState();
}

class _ImpactSectionState extends State<ImpactSection>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _imageHover = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Interval _interval(int index, int total) {
    const visible = 0.35;
    final step = total <= 1 ? 0.0 : (1.0 - visible) / (total - 1);
    final start = (index * step).clamp(0.0, 1.0).toDouble();
    final end = (start + visible).clamp(0.0, 1.0).toDouble();
    return Interval(start, end, curve: Curves.easeOutCubic);
  }

  Widget _animated(int index, int total, Widget child) {
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _statsGrid(double width, int totalAnim) {
    final cols = math.max(
      1,
      math.min(widget.stats.length, width < 560 ? 2 : 4),
    );

    final cards = <Widget>[];
    for (var i = 0; i < widget.stats.length; i++) {
      cards.add(
        _animated(
          i,
          totalAnim,
          _StatCard(stat: widget.stats[i], index: i),
        ),
      );
    }

    final rows = _chunk(cards, cols);

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildRow(row, cols),
          ),
      ],
    );
  }

  Widget _quoteBlock(String quote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.format_quote_rounded,
          color: AppColors.gold,
          size: 44,
        ),
        const SizedBox(height: 8),
        Text(
          quote,
          style: const TextStyle(
            fontSize: 22,
            height: 1.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 64,
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
        ),
      ],
    );
  }

  Widget _photo() {
    final safeUrl = _ImpactSecurity.isSafeImageUrl(widget.imageUrl)
        ? widget.imageUrl
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _imageHover = true),
      onExit: (_) => setState(() => _imageHover = false),
      child: AnimatedScale(
        scale: _imageHover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 18,
              left: 18,
              right: -14,
              bottom: -14,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: safeUrl != null
                    ? Image.network(
                        safeUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: AppLoading());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _photoPlaceholder();
                        },
                      )
                    : widget.imageAsset != null
                        ? Image.asset(
                            widget.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _photoPlaceholder();
                            },
                          )
                        : _photoPlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Icon(
        Icons.image_outlined,
        size: 48,
        color: Color(0xFF9CA3AF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final quote = _ImpactSecurity.text(widget.quote, maxLength: 400);
    final hasImage = widget.imageUrl != null || widget.imageAsset != null;

    if (stats.isEmpty && quote.isEmpty && !hasImage) {
      return const SizedBox.shrink();
    }

    final totalAnim = stats.length + 2;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 900;

              final quoteWidget = quote.isNotEmpty
                  ? _animated(stats.length, totalAnim, _quoteBlock(quote))
                  : null;

              final photoWidget = hasImage
                  ? _animated(stats.length + 1, totalAnim, _photo())
                  : null;

              Widget bottom;
              if (isSmall) {
                bottom = Column(
                  children: [
                    if (quoteWidget != null) quoteWidget,
                    if (quoteWidget != null && photoWidget != null)
                      const SizedBox(height: 48),
                    if (photoWidget != null)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: photoWidget,
                        ),
                      ),
                  ],
                );
              } else if (quoteWidget != null && photoWidget != null) {
                bottom = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: quoteWidget),
                    const SizedBox(width: 56),
                    Expanded(child: photoWidget),
                  ],
                );
              } else if (photoWidget != null) {
                bottom = Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: photoWidget,
                  ),
                );
              } else if (quoteWidget != null) {
                bottom = Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: quoteWidget,
                  ),
                );
              } else {
                bottom = const SizedBox.shrink();
              }

              return Column(
                children: [
                  if (stats.isNotEmpty) _statsGrid(constraints.maxWidth, totalAnim),
                  if (stats.isNotEmpty &&
                      (quote.isNotEmpty || hasImage))
                    const SizedBox(height: 56),
                  bottom,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({required this.stat, required this.index});

  final Stat stat;
  final int index;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countController;
  _StatValue? _parsed;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _parsed = _StatValue.parse(widget.stat.value);
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    Future.delayed(
      Duration(milliseconds: 200 + widget.index * 120),
      () {
        if (mounted) _countController.forward();
      },
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = Curves.easeOutCubic.transform(_countController.value);

    final value = _parsed != null
        ? _parsed!.format(curved)
        : _ImpactSecurity.text(widget.stat.value, maxLength: 24);

    final label = _ImpactSecurity.text(widget.stat.label, maxLength: 80);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hover
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, _hover ? 0.10 : 0.05),
                blurRadius: _hover ? 24 : 14,
                offset: Offset(0, _hover ? 10 : 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFB8860B),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatValue {
  const _StatValue({
    required this.prefix,
    required this.target,
    required this.decimals,
    required this.separator,
    required this.suffix,
  });

  final String prefix;
  final double target;
  final int decimals;
  final String separator;
  final String suffix;

  static _StatValue? parse(String raw) {
    final match = RegExp(r'^(\D*?)(\d+(?:[.,]\d+)?)(.*)$')
        .firstMatch(raw.trim());

    if (match == null) return null;

    final numStr = match.group(2)!;
    final separator = numStr.contains(',')
        ? ','
        : numStr.contains('.')
            ? '.'
            : '';
    final decimals =
        separator.isEmpty ? 0 : numStr.split(separator).last.length;
    final target = double.tryParse(numStr.replaceAll(',', '.'));

    if (target == null) return null;

    return _StatValue(
      prefix: match.group(1)!,
      target: target,
      decimals: decimals,
      separator: separator,
      suffix: match.group(3)!,
    );
  }

  String format(double progress) {
    final current = target * progress;
    final fixed = current.toStringAsFixed(decimals);
    final displayed =
        separator == ',' ? fixed.replaceAll('.', ',') : fixed;
    return '$prefix$displayed$suffix';
  }
}

class _ImpactSecurity {
  const _ImpactSecurity._();

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

  static bool isSafeImageUrl(String? value) {
    if (value == null || value.isEmpty) return false;

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return false;

    return uri.isScheme('https');
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
