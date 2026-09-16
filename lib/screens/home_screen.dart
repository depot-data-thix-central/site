
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/content.dart';
import '../services/content_service.dart';

// ═══════════════════════════════════════════════════════════════
// Palette harmonisée — Blanc & Slate + accent bleu (zéro or)
// ═══════════════════════════════════════════════════════════════
class _H {
  static const bg = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const surface = Color(0xFFF8FAFC);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const subtext = Color(0xFF94A3B8);
  static const lightBorder = Color(0xFFCBD5E1);
  // ✅ NOUVEAU : accent bleu, cohérent avec l'identité THIX (logo bleu),
  // utilisé avec parcimonie pour les liens, puces et petits repères visuels.
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFFEFF6FF);
  static const placeholderBg = Color(0xFFEEF2F7);
}

// ✅ NOUVEAU : échelle typographique centralisée, pour une lisibilité
// cohérente sur tout le site (au lieu de tailles ad hoc dispersées).

  static TextStyle h1(bool desktop) => TextStyle(
        fontSize: desktop ? 44 : 32,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: _H.ink,
        letterSpacing: -0.9,
      );
  static TextStyle h2(bool desktop) => TextStyle(
        fontSize: desktop ? 30 : 24,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: _H.ink,
        letterSpacing: -0.5,
      );
  static const h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: _H.ink,
    height: 1.3,
  );
  static const body = TextStyle(fontSize: 15.5, height: 1.7, color: _H.muted);
  static const bodySmall = TextStyle(fontSize: 13.5, height: 1.6, color: _H.muted);
  static const label = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: _H.muted,
    letterSpacing: 1.4,
  );
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
  // ✅ Étendu à 8 ancres nommées (au lieu d'indices numériques magiques)
  final _navKeys = <String, GlobalKey>{
    'home': GlobalKey(),
    'about': GlobalKey(),
    'team': GlobalKey(),
    'solutions': GlobalKey(),
    'gallery': GlobalKey(),
    'impact': GlobalKey(),
    'contact': GlobalKey(),
  };

  SiteContent? _content;
  bool _loading = true;
  Object? _error;
  bool? _consent;
  Timer? _consentTimer;

  late final AnimationController _entrance;
  late final Animation<double> _pageFade;
  late final List<Animation<double>> _sectionFades;

  static const _sectionCount = 11;
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
            (i * 0.06).clamp(0.0, 0.6),
            ((i * 0.06) + 0.4).clamp(0.0, 1.0),
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

  void _scrollToKey(String key) {
    final ctx = _navKeys[key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
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
                  _sec(0, KeyedSubtree(key: _navKeys['home'], child: _Navbar(content: c, onNavKey: _scrollToKey))),
                  _sec(1, _Hero(content: c, onCtaTap: () => _scrollToKey('about'))),
                  // ✅ Mot du manager déplacé juste après le hero, comme demandé.
                  _sec(2, _ManagerSection(content: c)),
                  _sec(3, KeyedSubtree(key: _navKeys['about'], child: _AboutUs(content: c))),
                  _sec(4, _Vision(content: c)),
                  _sec(5, KeyedSubtree(key: _navKeys['team'], child: _Team(content: c))),
                  _sec(6, KeyedSubtree(key: _navKeys['solutions'], child: _Solutions(content: c))),
                  _sec(7, KeyedSubtree(key: _navKeys['gallery'], child: _Gallery(content: c))),
                  _sec(8, _ProductHighlight(content: c)),
                  _sec(9, KeyedSubtree(key: _navKeys['impact'], child: _Impact(content: c))),
                  _sec(10, KeyedSubtree(key: _navKeys['contact'], child: _CtaBand(content: c))),
                  _Footer(content: c, onNavKey: _scrollToKey),
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
// HELPERS D'IMAGES — placeholder cohérent au lieu de disparaître
// ═══════════════════════════════════════════════════════════════

/// ✅ NOUVEAU : remplace le `errorBuilder: (_, __, ___) => SizedBox.shrink()`
/// utilisé partout auparavant. Une image cassée qui disparaît laisse un
/// vide inexpliqué dans la mise en page (surtout en grille) — on affiche
/// à la place un bloc neutre avec une icône, qui garde la mise en page
/// stable et signale clairement "image indisponible" plutôt que rien.
Widget _imgOrPlaceholder(
  String? url, {
  required double height,
  double? width,
  BoxFit fit = BoxFit.cover,
  IconData placeholderIcon = Icons.image_outlined,
}) {
  final has = url != null && url.trim().isNotEmpty;
  if (!has) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: _H.placeholderBg,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: _H.subtext, size: 28),
    );
  }
  return Image.network(
    url,
    height: height,
    width: width ?? double.infinity,
    fit: fit,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return Container(
        height: height,
        width: width ?? double.infinity,
        color: _H.placeholderBg,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _H.accent),
        ),
      );
    },
    errorBuilder: (_, __, ___) => Container(
      height: height,
      width: width ?? double.infinity,
      color: _H.placeholderBg,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: _H.subtext, size: 28),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// NAVBAR
// ═══════════════════════════════════════════════════════════════
class _Navbar extends StatelessWidget {
  const _Navbar({required this.content, required this.onNavKey});
  final SiteContent content;
  final ValueChanged<String> onNavKey;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _H.border)),
      ),
      child: Row(
        children: [
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
            _NavLink(label: 'Accueil', onTap: () => onNavKey('home')),
            _NavLink(label: 'À propos', onTap: () => onNavKey('about')),
            _NavLink(label: 'Équipe', onTap: () => onNavKey('team')),
            _NavLink(label: 'Solutions', onTap: () => onNavKey('solutions')),
            _NavLink(label: 'Galerie', onTap: () => onNavKey('gallery')),
            _NavLink(label: 'Impact', onTap: () => onNavKey('impact')),
            const SizedBox(width: 12),
          ],
          FilledButton(
            onPressed: () => onNavKey('contact'),
            style: FilledButton.styleFrom(
              backgroundColor: _H.ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(content.ctaPrimary.isNotEmpty ? content.ctaPrimary : 'Nous contacter'),
          ),
          if (compact) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: _H.ink),
              onPressed: () => _openMobileNav(context),
            ),
          ],
        ],
      ),
    );
  }

  void _openMobileNav(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: _H.border, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            for (final e in const {
              'home': 'Accueil',
              'about': 'À propos',
              'team': 'Équipe',
              'solutions': 'Solutions',
              'gallery': 'Galerie',
              'impact': 'Impact',
              'contact': 'Nous contacter',
            }.entries)
              ListTile(
                title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600, color: _H.ink)),
                onTap: () {
                  Navigator.pop(ctx);
                  onNavKey(e.key);
                },
              ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF334155)),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HERO
// ═══════════════════════════════════════════════════════════════
class _Hero extends StatelessWidget {
  const _Hero({required this.content, required this.onCtaTap});
  final SiteContent content;
  final VoidCallback onCtaTap;

  @override
  Widget build(BuildContext context) {
    final title = content.heroTitle.isNotEmpty
        ? content.heroTitle
        : 'Construire aujourd’hui l’Afrique de demain.';
    final highlight = content.heroHighlight;
    final paragraph = content.heroParagraph;
    final cta1 = content.ctaPrimary.isNotEmpty ? content.ctaPrimary : 'À propos du Groupe';
    final heroImage = content.heroImageUrl;

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 88 : 48, horizontal: 24),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _H.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'TECHNOLOGIE  •  INNOVATION  •  AFRIQUE',
                        style: TextStyle(
                          color: _H.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    RichText(
                      text: TextSpan(
                        style: _T.h1(isDesktop),
                        children: [
                          TextSpan(text: title),
                          if (highlight.isNotEmpty)
                            TextSpan(
                              text: ' $highlight',
                              style: const TextStyle(color: _H.accent),
                            ),
                        ],
                      ),
                    ),
                    if (paragraph.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Text(paragraph, style: _T.body),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: onCtaTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: _H.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(cta1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 56 : 0, height: isDesktop ? 0 : 32),
              Expanded(
                flex: isDesktop ? 5 : 0,
                child: AspectRatio(
                  aspectRatio: isDesktop ? 1.15 : 1.4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _H.border),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _H.ink.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imgOrPlaceholder(
                      heroImage,
                      height: double.infinity,
                      placeholderIcon: Icons.apps_rounded,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MOT DU MANAGER — repositionné juste après le hero
// ═══════════════════════════════════════════════════════════════
class _ManagerSection extends StatelessWidget {
  const _ManagerSection({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final name = content.managerName;
    final message = content.managerMessage;
    final photoUrl = content.managerPhotoUrl;

    if (name.isEmpty && message.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 700;

    return Container(
      width: double.infinity,
      color: _H.surface,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 40 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _H.border),
              boxShadow: [
                BoxShadow(color: _H.ink.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: _imgOrPlaceholder(
                    photoUrl,
                    height: 96,
                    width: 96,
                    placeholderIcon: Icons.person_rounded,
                  ),
                ),
                SizedBox(width: isDesktop ? 28 : 0, height: isDesktop ? 0 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MOT DE LA DIRECTION', style: _T.label),
                      const SizedBox(height: 10),
                      if (message.isNotEmpty)
                        Text(
                          '“$message”',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            height: 1.65,
                            color: _H.ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (name.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(width: 24, height: 2, color: _H.accent),
                            const SizedBox(width: 10),
                            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _H.ink)),
                          ],
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

// ═══════════════════════════════════════════════════════════════
// À PROPOS DE NOUS — section distincte de la vision
// ═══════════════════════════════════════════════════════════════
//
// ⚠️ NÉCESSITE de nouveaux champs dans SiteContent (à ajouter lors de la
// mise à jour du modèle) : aboutTitle, aboutText, aboutImageUrl.
// Tant qu'ils n'existent pas, cette section reste masquée (aboutText vide).
class _AboutUs extends StatelessWidget {
  const _AboutUs({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final title = content.aboutTitle;
    final text = content.aboutText;
    final image = content.aboutImageUrl;

    if (title.isEmpty && text.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: isDesktop ? 5 : 0,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _imgOrPlaceholder(image, height: double.infinity, placeholderIcon: Icons.groups_rounded),
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 56 : 0, height: isDesktop ? 0 : 28),
              Expanded(
                flex: isDesktop ? 6 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('QUI SOMMES-NOUS', style: _T.label),
                    const SizedBox(height: 10),
                    Text(
                      title.isNotEmpty ? title : 'À propos de SONATHIX GROUP',
                      style: _T.h2(isDesktop),
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(text, style: _T.body),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VISION + PILIERS STRATÉGIQUES
// ═══════════════════════════════════════════════════════════════
class _Vision extends StatelessWidget {
  const _Vision({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final vision = content.visionText;
    final visionImage = content.visionImageUrl;
    final features = content.features;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    if (vision.isEmpty && features.isEmpty) return const SizedBox.shrink();

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
              if (vision.isNotEmpty)
                Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: isDesktop ? 6 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NOTRE VISION', style: _T.label),
                          const SizedBox(height: 10),
                          Text('Une vision. Des solutions. Un impact.', style: _T.h2(isDesktop)),
                          const SizedBox(height: 16),
                          Text(vision, style: _T.body),
                        ],
                      ),
                    ),
                    if (visionImage != null && visionImage.isNotEmpty) ...[
                      SizedBox(width: isDesktop ? 48 : 0, height: isDesktop ? 0 : 24),
                      Expanded(
                        flex: isDesktop ? 5 : 0,
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _imgOrPlaceholder(visionImage, height: double.infinity),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              if (features.isNotEmpty) ...[
                SizedBox(height: vision.isNotEmpty ? 48 : 0),
                const Text('Piliers stratégiques', style: _T.h3),
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
        boxShadow: [
          BoxShadow(color: _H.ink.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _imgOrPlaceholder(imageUrl, height: double.infinity, placeholderIcon: Icons.auto_awesome_rounded),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _T.h3),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(text, style: _T.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ÉQUIPE
// ═══════════════════════════════════════════════════════════════
//
// ⚠️ NÉCESSITE un nouveau champ SiteContent.team: List<TeamMember>, avec
// une classe TeamMember { name, role, bio?, photoUrl? } — à ajouter au
// modèle. Section masquée tant que la liste est vide.
class _Team extends StatelessWidget {
  const _Team({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final team = content.team;
    if (team.isEmpty) return const SizedBox.shrink();

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
              const Text('NOTRE ÉQUIPE', style: _T.label),
              const SizedBox(height: 10),
              Text('Les personnes derrière le projet.',
                  style: _T.h2(MediaQuery.sizeOf(context).width >= 900)),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 620 ? 3 : (c.maxWidth > 400 ? 2 : 1));
                  final w = cols == 1 ? c.maxWidth : (c.maxWidth - 20 * (cols - 1)) / cols;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: team.map((m) => SizedBox(width: w, child: _TeamCard(member: m))).toList(),
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

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.member});
  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _H.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _H.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _imgOrPlaceholder(member.photoUrl, height: double.infinity, placeholderIcon: Icons.person_rounded),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _H.ink)),
                if (member.role.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(member.role,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _H.accent)),
                ],
                if (member.bio != null && member.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(member.bio!, style: _T.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SOLUTIONS
// ═══════════════════════════════════════════════════════════════
class _Solutions extends StatelessWidget {
  const _Solutions({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final list = content.solutions;
    if (list.isEmpty) return const SizedBox.shrink();

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
              const Text('NOS SOLUTIONS', style: _T.label),
              const SizedBox(height: 10),
              Text('Un écosystème conçu pour répondre aux réalités africaines.',
                  style: _T.h2(MediaQuery.sizeOf(context).width >= 900)),
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
        color: featured ? _H.ink : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: featured ? _H.ink : _H.border),
        boxShadow: [
          BoxShadow(
            color: (featured ? _H.ink : Colors.black).withValues(alpha: featured ? 0.18 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _imgOrPlaceholder(imageUrl, height: double.infinity, placeholderIcon: Icons.lightbulb_outline_rounded),
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
                      color: featured ? _H.subtext : _H.accent,
                    ),
                  ),
                ],
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
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

// ═══════════════════════════════════════════════════════════════
// GALERIE
// ═══════════════════════════════════════════════════════════════
//
// ⚠️ NÉCESSITE un nouveau champ SiteContent.gallery: List<GalleryItem>,
// avec une classe GalleryItem { url, caption? } — à ajouter au modèle.
// Section masquée tant que la liste est vide.
class _Gallery extends StatelessWidget {
  const _Gallery({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final items = content.gallery;
    if (items.isEmpty) return const SizedBox.shrink();

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
              const Text('GALERIE', style: _T.label),
              const SizedBox(height: 10),
              Text('Le Groupe en images.', style: _T.h2(MediaQuery.sizeOf(context).width >= 900)),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 620 ? 3 : (c.maxWidth > 400 ? 2 : 1));
                  final w = cols == 1 ? c.maxWidth : (c.maxWidth - 14 * (cols - 1)) / cols;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: items
                        .map((g) => SizedBox(
                              width: w,
                              child: _GalleryTile(url: g.url, caption: g.caption),
                            ))
                        .toList(),
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

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.url, this.caption});
  final String url;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _imgOrPlaceholder(url, height: double.infinity, placeholderIcon: Icons.photo_outlined),
            if (caption != null && caption!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0F172A)],
                    ),
                  ),
                  child: Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRODUIT PHARE
// ═══════════════════════════════════════════════════════════════
class _ProductHighlight extends StatelessWidget {
  const _ProductHighlight({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final title = content.solutions.isNotEmpty ? content.solutions.first.title : content.heroTitle;
    final text = content.solutions.isNotEmpty ? content.solutions.first.text : content.heroParagraph;
    final cta = content.ctaPrimary;

    if (title.isEmpty && text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: _H.ink,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text('PRODUIT PHARE',
                  style: TextStyle(color: _H.subtext, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _H.lightBorder, fontSize: 15, height: 1.6)),
              ],
              if (cta.isNotEmpty) ...[
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _H.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(cta, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// IMPACT
// ═══════════════════════════════════════════════════════════════
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
      color: _H.surfaceAlt,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Text('NOTRE IMPACT', style: _T.label),
              const SizedBox(height: 10),
              Text('Innover. Connecter. Transformer.',
                  textAlign: TextAlign.center, style: _T.h2(MediaQuery.sizeOf(context).width >= 900)),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 40),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: stats
                      .map((s) => Container(
                            width: 150,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _H.border),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  s.value,
                                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _H.accent),
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
                const SizedBox(height: 40),
                Text(
                  quote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _H.ink, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CTA FINAL
// ═══════════════════════════════════════════════════════════════
class _CtaBand extends StatelessWidget {
  const _CtaBand({required this.content});
  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    final cta = content.ctaPrimary.isNotEmpty ? content.ctaPrimary : 'Nous contacter';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              const Text(
                'Construisons ensemble la prochaine génération de solutions africaines.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: _H.ink, height: 1.3),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vous êtes une entreprise, une institution, un investisseur ou un partenaire ? Parlons de ce que nous pouvons construire ensemble.',
                textAlign: TextAlign.center,
                style: _T.body,
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: _H.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(cta, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  const _Footer({required this.content, required this.onNavKey});
  final SiteContent content;
  final ValueChanged<String> onNavKey;

  @override
  Widget build(BuildContext context) {
    final legal = content.footerLegal.isNotEmpty
        ? content.footerLegal
        : '© 2026 SONATHIX GROUP. Tous droits réservés.';

    return Container(
      width: double.infinity,
      color: _H.ink,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 8,
                children: [
                  for (final e in const {
                    'home': 'Accueil',
                    'about': 'À propos',
                    'team': 'Équipe',
                    'solutions': 'Solutions',
                    'gallery': 'Galerie',
                    'impact': 'Impact',
                    'contact': 'Contact',
                  }.entries)
                    InkWell(
                      onTap: () => onNavKey(e.key),
                      child: Text(e.value, style: const TextStyle(color: _H.lightBorder, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const Text('SONATHIX GROUP',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 14)),
              const SizedBox(height: 8),
              const Text('Technology  •  Innovation  •  Africa', style: TextStyle(color: _H.subtext, fontSize: 12)),
              const SizedBox(height: 20),
              Text(legal, style: const TextStyle(color: _H.muted, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONSENT
// ═══════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════
// SKELETON / ERROR
// ═══════════════════════════════════════════════════════════════
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
