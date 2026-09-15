import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme.dart';
import 'loading.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({
    super.key,
    required this.content,
    this.imageUrl,
    this.imageAsset,
    this.badgeText,
    this.onPrimaryTap,
    this.onSecondaryTap,
  });

  final SiteContent content;
  final String? imageUrl;
  final String? imageAsset;
  final String? badgeText;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

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
    const visible = 0.40;
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
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.gold),
           const SizedBox(width: 6),
          const Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textColumn({
    required bool isSmall,
    required int startIndex,
    required int total,
  }) {
    final content = widget.content;

    final title = _HeroSecurity.text(content.heroTitle, maxLength: 140);
    final highlight =
        _HeroSecurity.text(content.heroHighlight, maxLength: 140);
    final paragraph =
        _HeroSecurity.text(content.heroParagraph, maxLength: 600);
    final ctaPrimary =
        _HeroSecurity.text(content.ctaPrimary, maxLength: 40);
    final ctaSecondary =
        _HeroSecurity.text(content.ctaSecondary, maxLength: 40);
    final badge = _HeroSecurity.text(widget.badgeText, maxLength: 40);

    final baseTitleStyle =
        Theme.of(context).textTheme.displayLarge ?? const TextStyle();

    final titleStyle = baseTitleStyle.copyWith(
      fontSize: isSmall ? 34 : 48,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.8,
      color: const Color(0xFF111827),
    );

    final paragraphStyle =
        (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(
      fontSize: 16,
      height: 1.65,
      color: const Color(0xFF6B7280),
    );

    var index = startIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge.isNotEmpty) ...[
          _animated(index++, total, _badge(badge)),
          const SizedBox(height: 20),
        ],
        _animated(
          index++,
          total,
          Semantics(
            header: true,
            child: RichText(
              text: TextSpan(
                style: titleStyle,
                children: [
                  TextSpan(text: title),
                  TextSpan(
                    text: highlight,
                    style: titleStyle.copyWith(
                      color: const Color(0xFFB8860B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (paragraph.isNotEmpty) ...[
          const SizedBox(height: 20),
          _animated(
            index++,
            total,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(paragraph, style: paragraphStyle),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _animated(
          index++,
          total,
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (ctaPrimary.isNotEmpty)
                _PrimaryCta(
                  label: ctaPrimary,
                  onTap: widget.onPrimaryTap ?? () {},
                ),
              if (ctaSecondary.isNotEmpty)
                _SecondaryCta(
                  label: ctaSecondary,
                  onTap: widget.onSecondaryTap ?? () {},
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _HeroSecurity.text(widget.badgeText, maxLength: 40);
    final total = 4 + (badge.isNotEmpty ? 1 : 0);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 960;

              final textColumn = _textColumn(
                isSmall: isSmall,
                startIndex: 0,
                total: total,
              );

              final visual = _animated(
                total - 1,
                total,
                _HeroVisual(
                  imageUrl: widget.imageUrl,
                  imageAsset: widget.imageAsset,
                  content: widget.content,
                ),
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textColumn,
                    const SizedBox(height: 48),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: visual,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: textColumn),
                  const SizedBox(width: 56),
                  Expanded(child: visual),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroVisual extends StatefulWidget {
  const _HeroVisual({
    required this.content,
    this.imageUrl,
    this.imageAsset,
  });

  final SiteContent content;
  final String? imageUrl;
  final String? imageAsset;

  @override
  State<_HeroVisual> createState() => _HeroVisualState();
}

class _HeroVisualState extends State<_HeroVisual> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final safeUrl = _HeroSecurity.isSafeImageUrl(widget.imageUrl)
        ? widget.imageUrl
        : null;

    final stat = widget.content.stats.isNotEmpty
        ? widget.content.stats.first
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1.0,
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
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
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
                          return _fallbackVisual();
                        },
                      )
                    : widget.imageAsset != null
                        ? Image.asset(
                            widget.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _fallbackVisual();
                            },
                          )
                        : _fallbackVisual(),
              ),
            ),
            if (stat != null)
              Positioned(
                left: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(15, 23, 42, 0.12),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _HeroSecurity.text(stat.value, maxLength: 24),
                        style: const TextStyle(
                          color: Color(0xFFB8860B),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _HeroSecurity.text(stat.label, maxLength: 60),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackVisual() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.30),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFD9B23A), Color(0xFFB8860B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(184, 134, 11, 0.40),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatefulWidget {
  const _PrimaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD9B23A), Color(0xFFB8860B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                      184,
                      134,
                      11,
                      _hover ? 0.45 : 0.25,
                    ),
                    blurRadius: _hover ? 20 : 12,
                    offset: Offset(0, _hover ? 8 : 5),
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatefulWidget {
  const _SecondaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_SecondaryCta> createState() => _SecondaryCtaState();
}

class _SecondaryCtaState extends State<_SecondaryCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: _hover ? const Color(0xFFF9FAFB) : Colors.white,
              border: Border.all(
                color: _hover
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSecurity {
  const _HeroSecurity._();

  static String text(String? value, {int maxLength = 600}) {
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
