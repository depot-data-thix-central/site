import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/content.dart';
import '../services/content_service.dart';

// ═══════════════════════════════════════════════════════════════
// Palette harmonisée (Blanc & Slate - zéro or)
// ═══════════════════════════════════════════════════════════════
class _H {
  static const bg = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const surface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const subtext = Color(0xFF94A3B8);
  static const lightBorder = Color(0xFFCBD5E1);
}

// ═══════════════════════════════════════════════════════════════
// HOMEPAGE COMPLÈTE — tout centralisé, zéro hardcode métier
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _service = ContentService();
  final _scroll = ScrollController();
  final _showBackToTop = ValueNotifier(false);
  final _consentVisible = ValueNotifier(false);

  // Clés globales pour le défilement fluide vers les sections
  final sectionKeys = List.generate(7, (_) => GlobalKey());

  SiteContent? _content;
  bool _loading = true;
  Object? _error;
  bool? _consent;
  Timer? _consentTimer;

  late final AnimationController _entrance;
  late final Animation<double> _pageFade;
  late final List<Animation<double>> _sectionFades;

  static const _sectionCount = 9;
  static const _timeout = Duration(seconds: 12);
  static const _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    _consent = _ConsentMemory.choice;

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pageFade = _entrance.drive(
      CurveTween(curve: const Interval(0, 0.5, curve: Curves.easeOutCubic)),
    );
    _sectionFades = List.generate(
      _sectionCount,
      (i) => _entrance.drive(
        CurveTween(
          curve: Interval(
            (i * 0.07).clamp(0.0, 0.55),
            ((i * 0.07) + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _scroll.addListener(() {
      final show = _scroll.hasClients && _scroll.offset > 560;
      if (show != _showBackToTop.value) _showBackToTop.value = show;
    });

    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _entrance.dispose();
    _consentTimer?.cancel();
    _showBackToTop.dispose();
    _consentVisible.dispose();
    super.dispose();
  }

  // ── Chargement sécurisé ──────────────────────────────────────
  Future<void> _load({bool refresh = false}) async {
    if (!mounted) return;
    if (!refresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final c = await _fetchWithRetry();
      if (!mounted) return;

      final safe = c ?? const SiteContent();
      final consentText = _safeText(safe.consentText, 600);

      setState(() {
        _content = safe;
        _loading = false;
        _error = null;
      });

      if (!refresh) {
        _entrance
          ..reset()
          ..forward();
      }

      if (_consent == null && consentText.isNotEmpty) {
        _consentVisible.value = false;
        _consentTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) _consentVisible.value = true;
        });
      } else {
        _consentVisible.value = false;
      }
    } catch (e, st) {
      _log('load_failed', e, st);
      if (!mounted) return;
      if (refresh && _content != null) {
        _snack('Impossible de rafraîchir. Réessayez.', () => _load(refresh: true));
      } else {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  Future<SiteContent?> _fetchWithRetry() async {
    Object? last;
    StackTrace? lastSt;
    for (var i = 1; i <= _maxAttempts; i++) {
      try {
        return await _service.loadPublished().timeout(_timeout);
      } catch (e, st) {
        last = e;
        lastSt = st;
        _log('fetch_attempt', e, st, {'n': i});
        if (i < _maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 300 * i));
          if (!mounted) throw StateError('disposed');
        }
      }
    }
    Error.throwWithStackTrace(last ?? StateError('load error'), lastSt ?? StackTrace.current);
  }

  Future<void> _setConsent(bool accepted) async {
    _consentTimer?.cancel();
    await HapticFeedback.selectionClick();
    _ConsentMemory.choice = accepted;
    _consentVisible.value = false;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _consent = accepted);
  }

  Future<void> _scrollTop() async {
    if (!_scroll.hasClients) return;
    await HapticFeedback.selectionClick();
    await _scroll.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  void scrollToSection(int index) {
    final context = sectionKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _snack(String msg, VoidCallback retry) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _H.ink,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        action: SnackBarAction(label: 'Réessayer', textColor: Colors.white, onPressed: retry),
      ));
  }

  void _log(String e, [Object? err, StackTrace? st, Map<String, Object?>? ctx]) {
    if (!kDebugMode) return;
    debugPrint('[Home] $e ${ctx ?? ''} ${err?.runtimeType ?? ''}');
    if (st != null) debugPrint('$st');
  }

  static String _safeText(String? v, [int max = 4000]) {
    if (v == null || v.isEmpty) return '';
    final c = v
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFEFF\u202A-\u202E\u2066-\u2069]'), '')
        .trim();
    return c.length <= max ? c : c.substring(0, max);
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _H.bg,
        systemNavigationBarColor: _H.bg,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _H.bg,
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const _Skeleton();
    if (_error != null) {
      return _ErrorView(
        isTimeout: _error is TimeoutException,
        onRetry: _load,
      );
    }

    final c = _content ?? const SiteContent();
    final consent = _safeText(c.consentText, 600);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Stack(
      children: [
        RefreshIndicator(
          color: _H.ink,
          backgroundColor: _H.bg,
          onRefresh: () => _load(refresh: true),
          child: FadeTransition(
            opacity: _pageFade,
            child: SingleChildScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sec(0, KeyedSubtree(key: sectionKeys[0], child: _Navbar(content: c, onNavTap: scrollToSection))),
                  _sec(1, KeyedSubtree(key: sectionKeys[1], child: _Hero(content: c, onCtaTap: () => scrollToSection(2)))),
                  _sec(2, KeyedSubtree(key: sectionKeys[2], child: _About(content: c))),
                  _sec(3, KeyedSubtree(key: sectionKeys[3], child: _Solutions(content: c))),
                  _sec(4, _ManagerSection(content: c)),
                  _sec(5, KeyedSubtree(key: sectionKeys[4], child: _ProductHighlight(content: c))),
                  _sec(6, KeyedSubtree(key: sectionKeys[5], child: _Impact(content: c))),
                  _sec(7, KeyedSubtree(key: sectionKeys[6], child: _CtaBand(content: c))),
                  _sec(8, _Footer(content: c)),
                ],
              ),
            ),
          ),
        ),

        // Back to top
        ValueListenableBuilder<bool>(
          valueListenable: _showBackToTop,
          builder: (_, show, __) => Positioned(
            right: 16,
            bottom: 20 + bottom,
            child: IgnorePointer(
              ignoring: !show,
              child: AnimatedOpacity(
                opacity: show ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _RoundIconButton(
                  icon: Icons.arrow_upward_rounded,
                  onTap: _scrollTop,
                  label: 'Haut de page',
                ),
              ),
            ),
          ),
        ),

        // Consent
        if (_consent == null && consent.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottom,
            child: ValueListenableBuilder<bool>(
              valueListenable: _consentVisible,
              builder: (_, visible, __) => AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !visible,
                  child: _ConsentBanner(
                    text: consent,
                    onAccept: () => _setConsent(true),
                    onRefuse: () => _setConsent(false),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sec(int i, Widget child) => FadeTransition(opacity: _sectionFades[i], child: child);
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ═══════════════════════════════════════════════════════════════

class _Navbar extends StatelessWidget {
  const _Navbar({required this.content, required this.onNavTap});
  final SiteContent content;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _H.border)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _H.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('S',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const SizedBox(width: 10),
          const Text('SONATHIX',
              style: TextStyle(
                  color: _H.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 15)),
          const Spacer(),
          if (!compact) ...[
            _NavLink(label: 'Accueil', onTap: () => onNavTap(1)),
            _NavLink(label: 'À propos', onTap: () => onNavTap(2)),
            _NavLink(label: 'Solutions', onTap: () => onNavTap(3)),
            _NavLink(label: 'Impact', onTap: () => onNavTap(5)),
            const SizedBox(width: 12),
          ],
          FilledButton(
            onPressed: () => onNavTap(6),
            style: FilledButton.styleFrom(
              backgroundColor: _H.ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(content.ctaPrimary.isNotEmpty ? content.ctaPrimary : 'Nous contacter'),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF334155)),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

// ── Hero ───────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({required this.content, required this.onCtaTap});
  final SiteContent content;
  final VoidCallback onCtaTap;

  @override
  Widget build(BuildContext context) {
    final title = content.heroTitle.isNotEmpty
        ? content.heroTitle
        : 'Construire aujourd’hui\nl’Afrique de demain.';
    final highlight = content.heroHighlight;
    final paragraph = content.heroParagraph;
    final cta1 = content.ctaPrimary.isNotEmpty ? content.ctaPrimary : 'À propos du Groupe';
    final heroImage = content.heroImageUrl;

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 80 : 48, horizontal: 24),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: isDesktop ? 6 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TECHNOLOGIE  •  INNOVATION  •  AFRIQUE',
                      style: TextStyle(
                        color: _H.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: isDesktop ? 42 : 32,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: _H.ink,
                          letterSpacing: -0.8,
                        ),
                        children: [
                          TextSpan(text: title),
                          if (highlight.isNotEmpty)
                            TextSpan(
                              text: ' $highlight',
                              style: const TextStyle(color: _H.ink),
                            ),
                        ],
                      ),
                    ),
                    if (paragraph.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        paragraph,
                        style: const TextStyle(fontSize: 16, height: 1.6, color: _H.muted),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: onCtaTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: _H.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(cta1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (heroImage != null && heroImage.isNotEmpty) ...[
                SizedBox(width: isDesktop ? 48 : 0, height: isDesktop ? 0 : 32),
                Expanded(
                  flex: isDesktop ? 5 : 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _H.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.network(
                        heroImage,
                        fit: BoxFit.cover,
                        height: isDesktop ? 380 : 260,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── About / Vision ─────────────────────────────────────────────
class _About extends StatelessWidget {
  const _About({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final vision = content.visionText;
    final visionImage = content.visionImageUrl;
    final features = content.features;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Container(
      width: double.infinity,
      color: _H.surface,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: isDesktop ? 6 : 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NOTRE VISION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _H.muted,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Une vision. Des solutions. Un impact.',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _H.ink,
                            height: 1.25,
                          ),
                        ),
                        if (vision.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            vision,
                            style: const TextStyle(fontSize: 15, height: 1.65, color: _H.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (visionImage != null && visionImage.isNotEmpty) ...[
                    SizedBox(width: isDesktop ? 48 : 0, height: isDesktop ? 0 : 24),
                    Expanded(
                      flex: isDesktop ? 5 : 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          visionImage,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (features.isNotEmpty) ...[
                const SizedBox(height: 48),
                const Text(
                  'Piliers stratégiques',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _H.ink),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 800 ? 3 : (c.maxWidth > 520 ? 2 : 1);
                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: features.map((f) {
                        return SizedBox(
                          width: cols == 1 ? c.maxWidth : (c.maxWidth - 20 * (cols - 1)) / cols,
                          child: _PillarCard(title: f.title, text: f.text, imageUrl: f.imageUrl),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.title, required this.text, this.imageUrl});
  final String title;
  final String text;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _H.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: _H.ink)),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(text, style: const TextStyle(fontSize: 13, height: 1.55, color: _H.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Solutions ──────────────────────────────────────────────────
class _Solutions extends StatelessWidget {
  const _Solutions({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final list = content.solutions;
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NOS SOLUTIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _H.muted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Un écosystème conçu pour répondre aux réalités africaines.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _H.ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 3 : (c.maxWidth > 600 ? 2 : 1);
                  final w = cols == 1 ? c.maxWidth : (c.maxWidth - 20 * (cols - 1)) / cols;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: list.map((s) {
                      return SizedBox(
                        width: w,
                        child: _SolutionCard(
                          title: s.title,
                          subtitle: s.subtitle,
                          text: s.text,
                          featured: s.featured,
                          imageUrl: s.imageUrl,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({
    required this.title,
    required this.subtitle,
    required this.text,
    this.featured = false,
    this.imageUrl,
  });
  final String title;
  final String subtitle;
  final String text;
  final bool featured;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: featured ? _H.ink : _H.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: featured ? _H.ink : _H.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: featured ? Colors.white : _H.ink,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: featured ? _H.subtext : _H.muted,
                    ),
                  ),
                ],
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: featured ? _H.lightBorder : _H.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mot du Manager ─────────────────────────────────────────────

class _ManagerSection extends StatelessWidget {
  const _ManagerSection({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final name = content.managerName;
    final message = content.managerMessage;
    final photoUrl = content.managerPhotoUrl;

    if (name.isEmpty && message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _H.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _H.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (photoUrl != null && photoUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      photoUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: _H.muted),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MOT DE LA DIRECTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _H.muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (message.isNotEmpty)
                        Text(
                          '"$message"',
                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.6, color: _H.ink),
                        ),
                      if (name.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _H.ink),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Produit phare (THIX ID) ────────────────────────────────────
class _ProductHighlight extends StatelessWidget {
  const _ProductHighlight({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final title = content.solutions.isNotEmpty
        ? content.solutions.first.title
        : content.heroTitle;
    final text = content.solutions.isNotEmpty
        ? content.solutions.first.text
        : content.heroParagraph;
    final cta = content.ctaPrimary;

    if (title.isEmpty && text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: _H.ink,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'PRODUIT PHARE',
                style: TextStyle(
                  color: _H.subtext,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _H.lightBorder, fontSize: 15, height: 1.6),
                ),
              ],
              if (cta.isNotEmpty) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _H.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(cta),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Impact ─────────────────────────────────────────────────────
class _Impact extends StatelessWidget {
  const _Impact({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final stats = content.stats;
    final quote = content.impactQuote;
    if (stats.isEmpty && quote.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: _H.surface,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Text(
                'NOTRE IMPACT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _H.muted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Innover. Connecter. Transformer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _H.ink,
                ),
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 36),
                Wrap(
                  spacing: 32,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: stats
                      .map((s) => SizedBox(
                            width: 140,
                            child: Column(
                              children: [
                                Text(
                                  s.value,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: _H.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: _H.muted, height: 1.35),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
              if (quote.isNotEmpty) ...[
                const SizedBox(height: 36),
                Text(
                  quote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _H.ink,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── CTA final ────────────────────────────────________________  
class _CtaBand extends StatelessWidget {
  const _CtaBand({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final cta = content.ctaPrimary.isNotEmpty ? content.ctaPrimary : 'Nous contacter';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              const Text(
                'Construisons ensemble la prochaine génération de solutions africaines.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _H.ink,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vous êtes une entreprise, une institution, un investisseur ou un partenaire ? Parlons de ce que nous pouvons construire ensemble.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.55, color: _H.muted),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: _H.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(cta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final legal = content.footerLegal.isNotEmpty
        ? content.footerLegal
        : '© 2026 SONATHIX GROUP. Tous droits réservés.';

    return Container(
      width: double.infinity,
      color: _H.ink,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'SONATHIX GROUP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Technology  •  Innovation  •  Africa',
            style: TextStyle(color: _H.subtext, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Text(
            legal,
            style: const TextStyle(color: _H.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Consent ────────────────────────────────────────────────────
class _ConsentBanner extends StatelessWidget {
  const _ConsentBanner({
    required this.text,
    required this.onAccept,
    required this.onRefuse,
  });
  final String text;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(14),
      color: _H.ink,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(color: _H.lightBorder, fontSize: 12, height: 1.45)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRefuse,
                  style: TextButton.styleFrom(foregroundColor: _H.subtext),
                  child: const Text('Refuser'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _H.ink,
                  ),
                  child: const Text('Accepter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, required this.label});
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: _H.ink,
        borderRadius: BorderRadius.circular(999),
        elevation: 6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Skeleton / Error ───────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: _H.ink),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, this.isTimeout = false});
  final VoidCallback onRetry;
  final bool isTimeout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isTimeout ? 'Délai dépassé' : 'Impossible de charger la page',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _H.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez votre connexion puis réessayez.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _H.muted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(backgroundColor: _H.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentMemory {
  static bool? choice;
}
