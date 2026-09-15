import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key, required this.content});

  final SiteContent content;

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _logoHover = false;
  bool _ctaHover = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _onContactTap() {
    // TODO: navigation vers la page / section Contact.
  }

  Widget _logo() {
    return MouseRegion(
      onEnter: (_) => setState(() => _logoHover = true),
      onExit: (_) => setState(() => _logoHover = false),
      child: AnimatedScale(
        scale: _logoHover ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
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
      ),
    );
  }

  Widget _cta(String label) {
    return MouseRegion(
      onEnter: (_) => setState(() => _ctaHover = true),
      onExit: (_) => setState(() => _ctaHover = false),
      child: AnimatedScale(
        scale: _ctaHover ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onContactTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
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
                      _ctaHover ? 0.45 : 0.25,
                    ),
                    blurRadius: _ctaHover ? 18 : 10,
                    offset: Offset(0, _ctaHover ? 6 : 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileMenu(String contactLabel) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      icon: const Icon(
        Icons.menu_rounded,
        color: Color(0xFF111827),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelected: (value) {
        if (value == 'contact') {
          _onContactTap();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'contact',
          child: Row(
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 18,
                color: Color(0xFFB8860B),
              ),
              const SizedBox(width: 10),
              Text(contactLabel),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = _NavbarSecurity.text('SONATHIX', maxLength: 40);
    final contactLabel = _NavbarSecurity.text('Contact', maxLength: 30);
    final isSmall = MediaQuery.of(context).size.width < 640;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(
        opacity: _entranceController,
        child: Semantics(
          label: 'Barre de navigation',
          container: true,
          child: Container(
            height: 72,
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.05),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _logo(),
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
                const Spacer(),
                if (isSmall)
                  _mobileMenu(contactLabel)
                else
                  _cta(contactLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavbarSecurity {
  const _NavbarSecurity._();

  static String text(String? value, {int maxLength = 60}) {
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
