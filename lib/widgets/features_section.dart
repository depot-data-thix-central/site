import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme.dart';
import 'loading.dart';

class FeaturesSection extends StatefulWidget {
  const FeaturesSection({
    super.key,
    required this.features,
    this.imageUrls,
  });

  final List<Feature> features;
  final List<String>? imageUrls;

  @override
  State<FeaturesSection> createState() => _FeaturesSectionState();
}

class _FeaturesSectionState extends State<FeaturesSection>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  static const List<IconData> _icons = [
    Icons.rocket_launch_rounded,
    Icons.shield_moon_rounded,
    Icons.insights_rounded,
    Icons.bolt_rounded,
    Icons.workspace_premium_rounded,
    Icons.groups_rounded,
    Icons.auto_awesome_rounded,
    Icons.speed_rounded,
  ];

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

  @override
  Widget build(BuildContext context) {
    final features = widget.features;
    if (features.isEmpty) return const SizedBox.shrink();

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
              for (var i = 0; i < features.length; i++) {
                final imageUrl = (widget.imageUrls != null &&
                        i < widget.imageUrls!.length)
                    ? widget.imageUrls![i]
                    : null;

                cards.add(
                  _animatedCard(
                    i,
                    features.length,
                    _FeatureCard(
                      feature: features[i],
                      icon: _icons[i % _icons.length],
                      imageUrl: imageUrl,
                    ),
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
            },
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.feature,
    required this.icon,
    this.imageUrl,
  });

  final Feature feature;
  final IconData icon;
  final String? imageUrl;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  Widget _iconBadge() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Icon(
        widget.icon,
        size: 22,
        color: const Color(0xFFB8860B),
      ),
    );
  }

  Widget _image(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: AppLoading());
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF3F4F6),
              child: const Icon(
                Icons.image_outlined,
                color: Color(0xFF9CA3AF),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _FeaturesSecurity.text(widget.feature.title, maxLength: 90);
    final text = _FeaturesSecurity.text(widget.feature.text, maxLength: 420);
    final safeUrl = _FeaturesSecurity.isSafeImageUrl(widget.imageUrl)
        ? widget.imageUrl
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 220),
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
                blurRadius: _hover ? 26 : 16,
                offset: Offset(0, _hover ? 12 : 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (safeUrl != null) ...[
                _image(safeUrl),
                const SizedBox(height: 16),
              ] else ...[
                _iconBadge(),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesSecurity {
  const _FeaturesSecurity._();

  static String text(String? value, {int maxLength = 420}) {
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
