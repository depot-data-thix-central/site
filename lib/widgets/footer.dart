import 'package:flutter/material.dart';

import '../theme.dart';

class Footer extends StatefulWidget {
  const Footer({
    super.key,
    required this.legal,
    this.brandName = 'SONATHIX',
    this.onBackToTop,
  });

  final String legal;
  final String brandName;
  final VoidCallback? onBackToTop;

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _logoHover = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _logo(String brand) {
    return MouseRegion(
      onEnter: (_) => setState(() => _logoHover = true),
      onExit: (_) => setState(() => _logoHover = false),
      child: AnimatedScale(
        scale: _logoHover ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFD9B23A), Color(0xFFB8860B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(184, 134, 11, 0.25),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              brand,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final legal = _FooterSecurity.text(widget.legal, maxLength: 1200);
    final brand = _FooterSecurity.text(widget.brandName, maxLength: 40);
    final year = DateTime.now().year;

    return Semantics(
      label: 'Pied de page',
      container: true,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: FadeTransition(
              opacity: _entranceController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _entranceController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onBackToTop != null) ...[
                      _FooterTopButton(onTap: widget.onBackToTop!),
                      const SizedBox(height: 28),
                    ],
                    _logo(brand),
                    const SizedBox(height: 20),
                    if (legal.isNotEmpty) ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Text(
                          legal,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Container(
                          width: 120 * value,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gold.withValues(alpha: 0.5),
                                AppColors.gold,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© $year $brand',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterTopButton extends StatefulWidget {
  const _FooterTopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FooterTopButton> createState() => _FooterTopButtonState();
}

class _FooterTopButtonState extends State<_FooterTopButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Retour en haut de page',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedScale(
          scale: _hover ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hover ? const Color(0xFFF9FAFB) : Colors.white,
                  border: Border.all(
                    color: _hover
                        ? AppColors.gold.withValues(alpha: 0.6)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(
                        15,
                        23,
                        42,
                        _hover ? 0.10 : 0.05,
                      ),
                      blurRadius: _hover ? 18 : 12,
                      offset: Offset(0, _hover ? 8 : 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterSecurity {
  const _FooterSecurity._();

  static String text(String? value, {int maxLength = 1200}) {
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
