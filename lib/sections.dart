import 'package:flutter/material.dart' hide Hero;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';
import 'security.dart';
import 'content.dart';

IconData socialIconOf(String? key) => const {
      'linkedin': FontAwesomeIcons.linkedin, 'x': FontAwesomeIcons.xTwitter,
      'youtube': FontAwesomeIcons.youtube, 'telegram': FontAwesomeIcons.telegram,
    }[key] ?? FontAwesomeIcons.globe;

SectionId _sectionOf(String target) =>
    SectionId.values.firstWhere((e) => e.name == target, orElse: () => SectionId.home);

/// ═══════════ PAGE PUBLIQUE ═══════════
class PublicPage extends StatefulWidget {
  const PublicPage({super.key});
  @override
  State<PublicPage> createState() => _PublicPageState();
}

class _PublicPageState extends State<PublicPage> {
  late final ContentController _ctrl = ContentController(ContentRepository());
  final ConsentService _consent = ConsentService();
  final Map<SectionId, GlobalKey> _keys = {for (final s in SectionId.values) s: GlobalKey()};
  bool? _consentChoice;

  @override
  void initState() {
    super.initState();
    _consent.load().then((c) { if (mounted) setState(() => _consentChoice = c); });
    _ctrl.addListener(_onContent);
    _ctrl.loadPublic();
    // NOTE : web.document.getElementById('loading')?.remove() est dans main.dart
  }

  @override
  void dispose() { _ctrl.removeListener(_onContent); _ctrl.dispose(); super.dispose(); }

  /// SEO dynamique : titre + meta description injectés depuis le contenu publié.
  void _onContent() {
    if (!mounted) return;
    setState(() {});
    final seo = _ctrl.published?.seo;
    if (seo != null && seo.title.isNotEmpty) {
      // Note : sur web uniquement, ces appels fonctionnent
      try {
        final doc = _getDocument();
        doc.title = seo.title;
        final meta = doc.querySelector('meta[name="description"]');
        meta?.setAttribute('content', seo.description);
      } catch (_) {}
    }
  }

  void _scrollTo(SectionId id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic, alignment: 0.0);
  }

  Widget _wrap(SectionId id, Widget child) => KeyedSubtree(key: _keys[id], child: child);

  @override
  Widget build(BuildContext context) {
    if (_ctrl.loading) {
      return const Scaffold(backgroundColor: AppColors.primaryDark,
          body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }
    final c = _ctrl.published;
    if (c == null) {
      return Scaffold(backgroundColor: AppColors.primaryDark,
          body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, color: AppColors.gold, size: 40),
            const SizedBox(height: 14),
            Text(_ctrl.error ?? 'Site en cours de configuration.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 18),
            GoldButton(label: 'Réessayer', onTap: _ctrl.loadPublic),
          ])));
    }
    return Scaffold(
      body: Stack(children: [
        SingleChildScrollView(child: Column(children: [
          _wrap(SectionId.home, Navbar(content: c, onNavigate: _scrollTo)),
          _wrap(SectionId.home, HeroSection(h: c.hero, onNavigate: _scrollTo)),
          _wrap(SectionId.about, FeaturesStrip(items: c.features)),
          _wrap(SectionId.solutions, SolutionsGrid(s: c.solutions)),
          _wrap(SectionId.impact, ImpactSection(im: c.impact)),
          _wrap(SectionId.vision, VisionSection(v: c.vision)),
          _wrap(SectionId.contact, Footer(f: c.footer, nav: c.nav, onNavigate: _scrollTo)),
        ])),
        if (_consentChoice == null && c.consentText.isNotEmpty)
          Positioned(left: 16, right: 16, bottom: 16,
              child: ConsentBanner(text: c.consentText, onChoice: (g) async {
                setState(() => _consentChoice = g);
                await _consent.save(g);
              })),
      ]),
    );
  }
}

// Helper pour accéder au document web (compatible web/universal)
dynamic _getDocument() {
  try {
    // ignore: avoid_web_libraries_in_flutter
    return (const bool.fromEnvironment('dart.library.html')) 
        ? (dynamic web) => web.document 
        : null;
  } catch (_) {
    return null;
  }
}

/// ═══════════ NAVBAR ═══════════
class Navbar extends StatelessWidget {
  const Navbar({super.key, required this.content, required this.onNavigate});
  final SiteContent content;
  final void Function(SectionId) onNavigate;

  @override
  Widget build(BuildContext context) {
    final desktop = R.isDesktop(context);
    final links = content.nav.links;
    return Container(color: AppColors.primaryDark,
      child: R.centered(SizedBox(height: 72, child: Row(children: [
        _logo(),
        if (desktop) ...[
          const SizedBox(width: 36),
          for (var i = 0; i < links.length; i++)
            links[i].target == 'solutions'
                ? _solutionsMenu()
                : _link(links[i], i == 0),
          const Spacer(), _lang(), const SizedBox(width: 12),
          GoldButton(label: content.nav.ctaLabel,
              onTap: () => onNavigate(SectionId.contact)),
        ] else ...[
          const Spacer(), _lang(),
          IconButton(icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _sheet(context, links)),
        ],
      ]))));
  }

  Widget _logo() => GestureDetector(onTap: () => onNavigate(SectionId.home),
    child: Row(children: [
      Container(width: 38, height: 38,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient),
          child: const Center(child: Text('S', style: TextStyle(color: AppColors.primaryDark,
              fontWeight: FontWeight.w900, fontSize: 20)))),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('SONATHIX', style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 15)),
        Text('G R O U P', style: TextStyle(
            color: Colors.white.withValues(alpha: .6), fontSize: 8, letterSpacing: 4)),
      ]),
    ]));

  Widget _link(NavLink l, bool active) => TextButton(
    onPressed: () => onNavigate(_sectionOf(l.target)),
    style: TextButton.styleFrom(foregroundColor: Colors.white),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(l.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(height: 2, width: 24,
          color: active ? AppColors.gold : Colors.transparent),
    ]));

  /// Menu déroulant alimenté par les solutions publiées.
  Widget _solutionsMenu() => PopupMenuButton<String>(
    onSelected: (_) => onNavigate(SectionId.solutions),
    itemBuilder: (_) => [for (final s in content.solutions.main)
      PopupMenuItem(value: s.title, child: Text(s.title))],
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(content.nav.links.firstWhere((l) => l.target == 'solutions',
            orElse: () => NavLink(label: 'Nos solutions', target: 'solutions')).label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        Icon(Icons.expand_more, size: 18, color: Colors.white.withValues(alpha: .7)),
      ])));

  Widget _lang() => PopupMenuButton<String>(onSelected: (_) {},
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'fr', child: Text('🇫🇷  Français')),
      PopupMenuItem(value: 'en', enabled: false, child: Text('🇬🇧  English (bientôt)'))],
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🇫🇷', style: TextStyle(fontSize: 13)), const SizedBox(width: 6),
        const Text('FR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        Icon(Icons.expand_more, size: 16, color: Colors.white.withValues(alpha: .7))])));

  void _sheet(BuildContext context, List<NavLink> links) => showModalBottomSheet<void>(
    context: context, backgroundColor: AppColors.surfaceDark,
    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      for (final l in links)
        ListTile(title: Text(l.label, style: const TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); onNavigate(_sectionOf(l.target)); }),
    ])));
}

/// ═══════════ HERO ═══════════
class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.h, required this.onNavigate});
  final Hero h;
  final void Function(SectionId) onNavigate;

  @override
  Widget build(BuildContext context) {
    final desktop = R.isDesktop(context);
    return Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: CustomPaint(painter: NetworkPainter(),
        child: R.centered(Padding(padding: EdgeInsets.symmetric(vertical: desktop ? 56 : 40),
          child: desktop
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(flex: 5, child: _text(context)), const SizedBox(width: 24),
                Expanded(flex: 6, child: _visual(context))])
            : Column(children: [_text(context), const SizedBox(height: 40), _visual(context)])))));
  }

  Widget _text(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    RichText(text: TextSpan(
        style: const TextStyle(fontSize: 11, letterSpacing: 2,
            color: AppColors.textMuted, fontWeight: FontWeight.w600),
        children: [for (var i = 0; i < h.eyebrow.length; i++) ...[
          if (i > 0) const TextSpan(text: '  /  ', style: TextStyle(color: AppColors.gold)),
          TextSpan(text: h.eyebrow[i]),
        ]])),
    const SizedBox(height: 18),
    RichText(text: TextSpan(style: Theme.of(context).textTheme.displayLarge, children: [
      TextSpan(text: h.titleA),
      TextSpan(text: h.highlight, style: const TextStyle(color: AppColors.gold)), // CORRECTION: highlight au lieu de titleHighlight
    ])),
    const SizedBox(height: 18),
    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430),
        child: Text(h.paragraph,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14))),
    const SizedBox(height: 28),
    Wrap(spacing: 14, runSpacing: 14, children: [
      GoldButton(label: h.ctaPrimary, onTap: () => onNavigate(SectionId.solutions)),
      OutlineButton(label: h.ctaSecondary, icon: Icons.play_arrow,
          onTap: () => onNavigate(SectionId.vision)),
    ]),
  ]);

  Widget _visual(BuildContext context) => LayoutBuilder(builder: (context, c) {
    final showPhone = c.maxWidth >= 560;
    final cardW = c.maxWidth.clamp(260.0, 370.0);
    return SizedBox(height: showPhone ? 430 : 300,
      child: Stack(clipBehavior: Clip.none, children: [
        if (showPhone) const Positioned(right: 0, top: 0, child: PhoneMock()),
        Positioned(left: 0, top: showPhone ? 110 : 0, child: ThixCardMock(card: h.card, width: cardW)),
        if (showPhone) Positioned(right: 6, top: -14,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(h.badgeTitle, style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1)),
              Text(h.badgeText, textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, letterSpacing: 1.2,
                      color: AppColors.goldLight.withValues(alpha: .85), fontWeight: FontWeight.w700)),
            ])),
        Positioned(left: -12, top: showPhone ? 170 : 60,
            child: _nfc(h.card.nfc)),
      ]));
  });

  Widget _nfc(String label) => Column(children: [
    Container(width: 44, height: 44,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.nfc_rounded, color: AppColors.primaryDark, size: 22)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 10,
        fontWeight: FontWeight.w700, letterSpacing: 1)),
  ]);
}

class ThixCardMock extends StatelessWidget {
  const ThixCardMock({super.key, required this.card, this.width = 360});
  final HeroCard card;
  final double width;

  @override
  Widget build(BuildContext context) => Container(width: width,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF12253F), Color(0xFF0B1930)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: .55)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14))]),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(width: 30, height: 24, decoration: BoxDecoration(
            color: AppColors.gold, borderRadius: BorderRadius.circular(5))),
        const SizedBox(width: 10),
        Text(card.brand, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 15)),
        const Spacer(),
        const Icon(Icons.fingerprint, color: AppColors.gold, size: 38),
      ]),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 62, height: 74, decoration: BoxDecoration(
            color: const Color(0xFF2A3B55), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.person, color: Colors.white70, size: 40)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(card.nomLabel, style: const TextStyle(fontSize: 9, letterSpacing: 1, color: AppColors.textMuted)),
          Text(card.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(card.idLabel, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
              child: Text(card.status, style: const TextStyle(color: Colors.white,
                  fontSize: 9.5, fontWeight: FontWeight.w700))),
        ])),
        const Icon(Icons.qr_code_2, color: Colors.white, size: 46),
      ]),
      const SizedBox(height: 14),
      Align(alignment: Alignment.centerLeft,
          child: Container(width: 90, height: 5, color: Colors.white24)),
    ]));
}

class PhoneMock extends StatelessWidget {
  const PhoneMock({super.key});
  static const _rows = [
    (Icons.folder_outlined, 'Mes documents'), (Icons.person_outline, 'Mon profil'),
    (Icons.verified_outlined, 'Mes certifications'), (Icons.work_outline, 'Mes opportunités')];

  @override
  Widget build(BuildContext context) => Container(width: 205, height: 410,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF132743), Color(0xFF0A1628)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .18), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 34, offset: Offset(0, 18))]),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('9:41', style: TextStyle(color: Colors.white70, fontSize: 9)),
        Row(children: [for (final i in [Icons.signal_cellular_alt, Icons.wifi, Icons.battery_full])
          Icon(i, size: 10, color: Colors.white70)]),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        const Icon(Icons.shield_outlined, color: AppColors.gold, size: 14),
        const SizedBox(width: 6),
        const Text('THIX ID', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        const Spacer(), const Icon(Icons.menu, color: Colors.white54, size: 14),
      ]),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const CircleAvatar(radius: 13, backgroundColor: Color(0xFF2A3B55),
                child: Icon(Icons.person, size: 15, color: Colors.white70)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LUMINA Nathan', style: TextStyle(color: Colors.white,
                  fontSize: 10.5, fontWeight: FontWeight.w700)),
              Row(children: [
                const Icon(Icons.check_circle, size: 9, color: AppColors.success),
                const SizedBox(width: 3),
                Text('Identité vérifiée', style: TextStyle(fontSize: 8.5,
                    color: AppColors.success.withValues(alpha: .9))),
              ]),
            ]),
          ])),
      const SizedBox(height: 10),
      for (final r in _rows)
        Padding(padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Container(width: 26, height: 26, decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(7)),
                  child: Icon(r.$1, size: 13, color: Colors.white70)),
              const SizedBox(width: 8),
              Text(r.$2, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
              const Spacer(), const Icon(Icons.chevron_right, size: 13, color: Colors.white38),
            ])),
      const Spacer(),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Icon(Icons.home_filled, size: 15, color: AppColors.gold),
        Icon(Icons.person_outline, size: 15, color: Colors.white38),
        Icon(Icons.more_horiz, size: 15, color: Colors.white38),
      ]),
    ]));
}

class NetworkPainter extends CustomPainter {
  static const _pts = <(double, double)>[
    (.08, .25), (.18, .12), (.30, .30), (.45, .15), (.60, .28), (.75, .10),
    (.88, .30), (.15, .60), (.35, .75), (.55, .60), (.78, .70), (.92, .55)];
  static const _edges = <(int, int)>[
    (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (2, 7), (7, 8),
    (8, 9), (9, 10), (10, 11), (4, 9), (6, 11)];
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = Colors.white.withValues(alpha: .07)..strokeWidth = 1;
    final dot = Paint()..color = AppColors.gold.withValues(alpha: .35);
    final p = [for (final e in _pts) Offset(e.$1 * size.width, e.$2 * size.height)];
    for (final e in _edges) canvas.drawLine(p[e.$1], p[e.$2], line);
    for (final pt in p) canvas.drawCircle(pt, 2.2, dot);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ═══════════ ATOUTS ═══════════
class FeaturesStrip extends StatelessWidget {
  const FeaturesStrip({super.key, required this.items});
  final List<Feature> items;
  @override
  Widget build(BuildContext context) => Container(color: AppColors.lightGray,
    child: R.centered(Padding(padding: const EdgeInsets.symmetric(vertical: 34),
      child: R.grid([for (final f in items)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(
              color: AppColors.primaryDark, borderRadius: BorderRadius.circular(10)),
              child: Icon(iconOf(f.icon), color: Colors.white, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.title, style: const TextStyle(fontSize: 14.5,
                fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            const SizedBox(height: 6),
            Text(f.text, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textMuted)),
          ])),
        ])], desktop: 3, tablet: 1, mobile: 1, spacing: 40))));
}

/// ═══════════ SOLUTIONS ═══════════
class SolutionsGrid extends StatelessWidget {
  const SolutionsGrid({super.key, required this.s});
  final Solutions s;

  @override
  Widget build(BuildContext context) => Container(color: Colors.white,
    child: R.centered(Padding(padding: const EdgeInsets.symmetric(vertical: 64),
      child: LayoutBuilder(builder: (context, c) {
        final intro = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionLabel(text: s.label), const SizedBox(height: 14),
          Text(s.title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 14),
          Text(s.paragraph, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          OutlineButton(label: s.cta, onLight: true),
        ]);
        final grids = Column(children: [
          R.grid([for (final m in s.main) _mainCard(m, s.linkLabel)],
              desktop: 3, tablet: 2, mobile: 1),
          const SizedBox(height: 16),
          R.grid([for (final m in s.minis) _mini(m)], desktop: 4, tablet: 2, mobile: 1),
        ]);
        return c.maxWidth >= 1024
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 350, child: intro), const SizedBox(width: 40), Expanded(child: grids)])
            : Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [intro, const SizedBox(height: 32), grids]);
      }))));

  Widget _mainCard(SolutionMain m, String linkLabel) => Container(padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
        gradient: m.featured
            ? const LinearGradient(colors: [Color(0xFF12253F), Color(0xFF0B1930)])
            : null,
        color: m.featured ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: m.featured ? null : Border.all(color: const Color(0xFFE5E9F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(
          color: m.featured ? AppColors.gold.withValues(alpha: .15) : null,
          border: m.featured ? null : Border.all(color: AppColors.gold.withValues(alpha: .5)),
          shape: BoxShape.circle),
          child: Icon(iconOf(m.icon), color: m.featured ? AppColors.gold : AppColors.primaryDark, size: 20)),
      const SizedBox(height: 14),
      Text(m.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
          color: m.featured ? Colors.white : AppColors.primaryDark)),
      const SizedBox(height: 4),
      Text(m.subtitle, style: TextStyle(fontSize: 11.5,
          color: m.featured ? AppColors.goldLight : AppColors.textMuted)),
      const SizedBox(height: 10),
      Text(m.text, style: TextStyle(fontSize: 11.5, height: 1.55,
          color: m.featured ? Colors.white.withValues(alpha: .65) : AppColors.textMuted)),
      const SizedBox(height: 14),
      Text('$linkLabel  →', style: const TextStyle(color: AppColors.gold,
          fontSize: 11.5, fontWeight: FontWeight.w700)),
    ]));

  Widget _mini(SolutionMini m) => Container(padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(iconOf(m.icon), color: AppColors.primaryDark, size: 20),
      const SizedBox(height: 12),
      Text(m.title, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
      const SizedBox(height: 3),
      Text(m.subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
    ]));
}

/// ═══════════ IMPACT ═══════════
class ImpactSection extends StatelessWidget {
  const ImpactSection({super.key, required this.im});
  final Impact im;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0B1B33), Color(0xFF081426)])),
    child: CustomPaint(painter: SkylinePainter(),
      child: R.centered(Padding(padding: const EdgeInsets.symmetric(vertical: 64),
        child: LayoutBuilder(builder: (context, c) {
          final left = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(text: im.label), const SizedBox(height: 14),
            Text(im.title, style: Theme.of(context).textTheme.displayMedium!
                .copyWith(color: Colors.white, fontSize: 27, height: 1.25)),
            const SizedBox(height: 14),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 330),
                child: Text(im.paragraph, style: TextStyle(fontSize: 12.5,
                    height: 1.6, color: Colors.white.withValues(alpha: .65)))),
            const SizedBox(height: 24), GoldButton(label: im.cta),
          ]);
          final stats = Wrap(spacing: 44, runSpacing: 30, children: [for (final st in im.stats)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(st.value, style: const TextStyle(color: AppColors.gold,
                  fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(st.label, style: TextStyle(fontSize: 11, height: 1.5,
                  color: Colors.white.withValues(alpha: .75))),
            ])]);
          final quote = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(im.quote, style: const TextStyle(color: Colors.white, fontSize: 19,
                fontWeight: FontWeight.w800, height: 1.35)),
            const SizedBox(height: 14), Container(width: 34, height: 3, color: AppColors.gold),
          ]);
          return c.maxWidth >= 1024
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(flex: 4, child: left), const SizedBox(width: 30),
                  Expanded(flex: 4, child: stats), const SizedBox(width: 30),
                  Expanded(flex: 3, child: quote)])
              : Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [left, const SizedBox(height: 40), stats, const SizedBox(height: 40), quote]);
        })))));
}

class SkylinePainter extends CustomPainter {
  static const _b = <(double, double, double)>[
    (.02, .05, .30), (.09, .04, .45), (.15, .06, .25), (.24, .05, .55),
    (.31, .04, .35), (.40, .07, .48), (.50, .05, .28), (.58, .06, .60),
    (.67, .05, .38), (.75, .07, .50), (.85, .05, .32), (.92, .06, .42)];
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: .28);
    for (final e in _b) {
      canvas.drawRect(Rect.fromLTWH(e.$1 * size.width, size.height - e.$3 * size.height * .5,
          e.$2 * size.width, e.$3 * size.height * .5), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ═══════════ VISION ═══════════
class VisionSection extends StatelessWidget {
  const VisionSection({super.key, required this.v});
  final Vision v;
  @override
  Widget build(BuildContext context) => Container(color: Colors.white,
    child: R.centered(Padding(padding: const EdgeInsets.symmetric(vertical: 64),
      child: LayoutBuilder(builder: (context, c) {
        final visual = const SizedBox(width: 300, height: 300,
            child: CustomPaint(painter: SunrisePainter(), size: Size(300, 300)));
        final middle = Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel(text: v.label), const SizedBox(height: 14),
            Text(v.title, style: Theme.of(context).textTheme.displayMedium!
                .copyWith(fontSize: 26, height: 1.25)),
            const SizedBox(height: 14),
            RichText(text: TextSpan(style: Theme.of(context).textTheme.bodyMedium, children: [
              TextSpan(text: v.before),
              TextSpan(text: v.bold, style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              TextSpan(text: v.after),
            ])),
            const SizedBox(height: 24), GoldButton(label: v.cta),
          ])));
        final values = Expanded(child: Column(children: [for (final val in v.values)
          Padding(padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: .5))),
                  child: Icon(iconOf(val.icon), size: 17, color: AppColors.primaryDark)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(val.title, style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 3),
                Text(val.text, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ])),
            ]))]));
        return c.maxWidth >= 1024
            ? Row(children: [visual, middle, values])
            : Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [visual, const SizedBox(height: 32), middle, const SizedBox(height: 32), values]);
      }))));
}

class SunrisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFF7C873), Color(0xFFE8926A), Color(0xFF8A4B52)]).createShader(rect));
    canvas.drawCircle(Offset(size.width * .38, size.height * .42), 34,
        Paint()..color = const Color(0xFFFFF3C4));
    canvas.drawPath(Path()..moveTo(0, size.height)..lineTo(size.width * .30, size.height * .45)
        ..lineTo(size.width * .62, size.height)..close(),
        Paint()..color = const Color(0xFF5B3A44));
    canvas.drawPath(Path()..moveTo(size.width * .35, size.height)..lineTo(size.width * .72, size.height * .55)
        ..lineTo(size.width * 1.05, size.height)..close(),
        Paint()..color = const Color(0xFF3E2A33));
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ═══════════ FOOTER ═══════════
class Footer extends StatefulWidget {
  const Footer({super.key, required this.f, required this.nav, this.onNavigate});
  final FooterData f;
  final Nav nav;
  final void Function(SectionId)? onNavigate;
  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _service = NewsletterService();
  bool _loading = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final res = await _service.subscribe(_emailCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    final ok = res is Success;
    if (ok) _emailCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message),
        backgroundColor: ok ? AppColors.success
            : (res is RateLimited ? const Color(0xFFB45309) : AppColors.danger)));
  }

  @override
  Widget build(BuildContext context) => Container(color: AppColors.primaryDark,
    child: R.centered(Padding(padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 56, runSpacing: 36, crossAxisAlignment: WrapCrossAlignment.start, children: [
          _brand(), _nav(), _socials(), SizedBox(width: 300, child: _newsletter()),
        ]),
        const SizedBox(height: 40),
        Divider(color: Colors.white.withValues(alpha: .12)),
        const SizedBox(height: 18),
        Wrap(spacing: 20, alignment: WrapAlignment.spaceBetween, children: [
          Text(widget.f.legal, style: TextStyle(fontSize: 10.5,
              color: Colors.white.withValues(alpha: .55))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 26, height: 2, color: AppColors.gold), const SizedBox(width: 10),
            Text(widget.f.signature, style: TextStyle(fontSize: 10.5,
                color: Colors.white.withValues(alpha: .75))),
          ]),
        ]),
      ]))));

  Widget _brand() => SizedBox(width: 230, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 34, height: 34, decoration: const BoxDecoration(
          shape: BoxShape.circle, gradient: AppColors.goldGradient),
          child: const Center(child: Text('S', style: TextStyle(
              color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 17)))),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SONATHIX', style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 13)),
        Text('G R O U P', style: TextStyle(
            color: Colors.white.withValues(alpha: .6), fontSize: 7, letterSpacing: 3)),
      ]),
    ]),
    const SizedBox(height: 14),
    Text(widget.f.tagline, style: TextStyle(fontSize: 11,
        color: Colors.white.withValues(alpha: .7))),
  ]));

  Widget _nav() => SizedBox(width: 200, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(widget.f.navTitle, style: const TextStyle(color: Colors.white,
        fontSize: 12, fontWeight: FontWeight.w800)),
    const SizedBox(height: 12),
    for (final l in widget.nav.links)
      Padding(padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(onTap: () => widget.onNavigate?.call(_sectionOf(l.target)),
              child: Text(l.label, style: TextStyle(fontSize: 11,
                  color: Colors.white.withValues(alpha: .65))))),
  ]));

  Widget _socials() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(widget.f.socialTitle, style: const TextStyle(color: Colors.white,
        fontSize: 12, fontWeight: FontWeight.w800)),
    const SizedBox(height: 12),
    Row(children: [for (final s in widget.f.socials)
      Padding(padding: const EdgeInsets.only(right: 10),
          child: MouseRegion(cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: () => SafeLaunch.open(Uri.parse(s.url)),
                  child: Container(width: 34, height: 34, decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: .25))),
                      child: Icon(socialIconOf(s.icon), size: 13, color: Colors.white70))))),
    ]),
  ]);

  Widget _newsletter() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(widget.f.nlTitle, style: const TextStyle(color: Colors.white,
        fontSize: 12, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    Text(widget.f.nlText, style: TextStyle(fontSize: 11,
        color: Colors.white.withValues(alpha: .65))),
    const SizedBox(height: 14),
    Form(key: _formKey, child: TextFormField(
      controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.send, onFieldSubmitted: (_) => _submit(),
      validator: Validators.validateEmail,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        isDense: true, hintText: widget.f.nlPlaceholder,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 11.5),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: .3))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
        errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 10),
        suffixIcon: _loading
            ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)))
            : IconButton(iconSize: 16,
                icon: Container(width: 30, height: 30, decoration: const BoxDecoration(
                    shape: BoxShape.circle, gradient: AppColors.goldGradient),
                    child: const Icon(Icons.arrow_forward, size: 13, color: AppColors.primaryDark)),
                onPressed: _submit),
      ))),
    const SizedBox(height: 8),
    Text(widget.f.privacyNote, style: TextStyle(fontSize: 9.5,
        color: Colors.white.withValues(alpha: .45))),
  ]);
}

/// ═══════════ BANNIÈRE RGPD ═══════════
class ConsentBanner extends StatelessWidget {
  const ConsentBanner({super.key, required this.text, required this.onChoice});
  final String text;
  final void Function(bool) onChoice;
  @override
  Widget build(BuildContext context) => Material(elevation: 12,
    color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(14),
    child: Padding(padding: const EdgeInsets.all(18),
      child: Wrap(spacing: 20, runSpacing: 14, alignment: WrapAlignment.spaceBetween, children: [
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.cookie_outlined, color: AppColors.gold, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: TextStyle(fontSize: 11.5, height: 1.55,
                  color: Colors.white.withValues(alpha: .85)))),
            ])),
        Row(mainAxisSize: MainAxisSize.min, children: [
          OutlineButton(label: 'Refuser', onTap: () => onChoice(false)),
          const SizedBox(width: 12),
          GoldButton(label: 'Accepter', icon: Icons.check, onTap: () => onChoice(true)),
        ]),
      ])));
}
