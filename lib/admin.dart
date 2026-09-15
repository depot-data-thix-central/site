import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'security.dart';
import 'content.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) => SupabaseAuthState(
        childBuilder: (_, session) =>
            session == null ? const _Login() : const _Dashboard(),
      );
}

/// ═══════════ CONNEXION ═══════════
class _Login extends StatefulWidget {
  const _Login();
  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final _email = TextEditingController(), _pwd = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
          email: _email.text.trim(), password: _pwd.text);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connexion impossible.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380),
          child: Card(color: AppColors.surfaceDark, child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 46, height: 46, decoration: const BoxDecoration(
                  shape: BoxShape.circle, gradient: AppColors.goldGradient),
                  child: const Center(child: Text('S', style: TextStyle(
                      color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 22)))),
              const SizedBox(height: 16),
              const Text('Espace administrateur', style: TextStyle(color: Colors.white,
                  fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('SONATHIX GROUP', style: TextStyle(color: AppColors.gold,
                  fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 22),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _deco('E-mail professionnel')),
              const SizedBox(height: 12),
              TextField(controller: _pwd, obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onSubmitted: (_) => _signIn(),
                  decoration: _deco('Mot de passe')),
              if (_error != null) ...[const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 11))],
              const SizedBox(height: 20),
              SizedBox(width: double.infinity,
                  child: GoldButton(label: 'Se connecter', loading: _busy, onTap: _signIn)),
            ])))));

  InputDecoration _deco(String hint) => InputDecoration(
      isDense: true, hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 12),
      filled: true, fillColor: Colors.white.withValues(alpha: .06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none));
}

/// ═══════════ TABLEAU DE BORD ═══════════
class _Dashboard extends StatefulWidget {
  const _Dashboard();
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  late final ContentController _ctrl = ContentController(ContentRepository());

  @override
  void initState() { super.initState(); _ctrl.addListener(_refresh); _ctrl.loadDraft(); }
  @override
  void dispose() { _ctrl.removeListener(_refresh); _ctrl.dispose(); super.dispose(); }
  void _refresh() => setState(() {});

  void _edit(void Function(SiteContent c) f) => _ctrl.edit(f);

  @override
  Widget build(BuildContext context) {
    final c = _ctrl.draft;
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white,
        title: const Text('Administration du contenu', style: TextStyle(fontSize: 15)),
        actions: [
          if (_ctrl.dirty) const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text('● modifié', style: TextStyle(color: AppColors.gold, fontSize: 11)))),
          IconButton(tooltip: 'Importer le contenu initial',
              icon: const Icon(Icons.download), onPressed: _ctrl.importSeed),
          IconButton(tooltip: 'Enregistrer le brouillon',
              icon: const Icon(Icons.save), onPressed: _ctrl.saving ? null : _ctrl.saveDraft),
          IconButton(tooltip: 'Publier sur le site',
              icon: const Icon(Icons.cloud_upload), onPressed: _ctrl.saving ? null : _ctrl.publish),
          IconButton(tooltip: 'Déconnexion', icon: const Icon(Icons.logout),
              onPressed: () => Supabase.instance.client.auth.signOut()),
        ]),
      body: _ctrl.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : c == null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_ctrl.error ?? 'Aucun brouillon.', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 14),
                  GoldButton(label: 'Importer le contenu initial', onTap: _ctrl.importSeed),
                ]))
              : ListView(padding: const EdgeInsets.all(20), children: [
                  if (_ctrl.notice != null)
                    Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(_ctrl.notice!, style: const TextStyle(fontSize: 12,
                            color: Color(0xFF14532D)))),
                  _seo(c), _nav(c), _hero(c), _features(c), _solutions(c),
                  _impact(c), _vision(c), _footer(c), _consent(c),
                  const SizedBox(height: 40),
                ]),
    );
  }

  /// ── Helpers UI génériques ──
  Widget _card(String title, List<Widget> children) => Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E9F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
            color: AppColors.primaryDark)),
        const SizedBox(height: 14), ...children]));

  Widget _tf(String label, String value, ValueChanged<String> on, {int lines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(initialValue: value, minLines: 1, maxLines: lines,
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(labelText: label, isDense: true,
                labelStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            onChanged: on));

  Widget _listHeader(String title, VoidCallback add) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        TextButton.icon(onPressed: add, icon: const Icon(Icons.add, size: 15),
            label: const Text('Ajouter', style: TextStyle(fontSize: 11))),
      ]);

  Widget _itemBox(Widget child, VoidCallback remove) => Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDE3EC)), color: const Color(0xFFF8FAFC)),
      child: Column(children: [child,
        Align(alignment: Alignment.centerRight, child: IconButton(
            visualDensity: VisualDensity.compact, tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
            onPressed: remove))]));

  /// ── Sections éditables ──
  Widget _seo(SiteContent c) => _card('SEO', [
    _tf('Titre (onglet & réseaux)', c.seo.title, (v) => _edit((x) => x.seo.title = v)),
    _tf('Meta description', c.seo.description, (v) => _edit((x) => x.seo.description = v), lines: 3),
  ]);

  Widget _nav(SiteContent c) => _card('Navigation', [
    _tf('Libellé du bouton CTA', c.nav.ctaLabel, (v) => _edit((x) => x.nav.ctaLabel = v)),
    _listHeader('Liens du menu', () => _edit((x) => x.nav.links.add(NavLink(label: 'Nouveau', target: 'home')))),
    for (var i = 0; i < c.nav.links.length; i++)
      _itemBox(Row(children: [
        Expanded(child: _tf('Libellé', c.nav.links[i].label, (v) => _edit((x) => x.nav.links[i].label = v))),
        const SizedBox(width: 8),
        Expanded(child: _tf('Cible (home, about, solutions, impact, vision, actualites, contact)',
            c.nav.links[i].target, (v) => _edit((x) => x.nav.links[i].target = v.trim()))),
      ]), () => _edit((x) => x.nav.links.removeAt(i))),
  ]);

  Widget _hero(SiteContent c) => _card('Hero', [
    _tf('Titre (partie 1)', c.hero.titleA, (v) => _edit((x) => x.hero.titleA = v), lines: 2),
    _tf('Titre (mot doré)', c.hero.titleHighlight, (v) => _edit((x) => x.hero.titleHighlight = v)),
    _tf('Paragraphe', c.hero.paragraph, (v) => _edit((x) => x.hero.paragraph = v), lines: 3),
    _tf('Bouton principal', c.hero.ctaPrimary, (v) => _edit((x) => x.hero.ctaPrimary = v)),
    _tf('Bouton secondaire', c.hero.ctaSecondary, (v) => _edit((x) => x.hero.ctaSecondary = v)),
    _tf('Badge titre', c.hero.badgeTitle, (v) => _edit((x) => x.hero.badgeTitle = v)),
    _tf('Badge texte', c.hero.badgeText, (v) => _edit((x) => x.hero.badgeText = v), lines: 2),
    const Divider(),
    _tf('Carte : marque', c.hero.card.brand, (v) => _edit((x) => x.hero.card.brand = v)),
    _tf('Carte : nom', c.hero.card.name, (v) => _edit((x) => x.hero.card.name = v)),
    _tf('Carte : identifiant', c.hero.card.idLabel, (v) => _edit((x) => x.hero.card.idLabel = v)),
    _tf('Carte : statut', c.hero.card.status, (v) => _edit((x) => x.hero.card.status = v)),
  ]);

  Widget _features(SiteContent c) => _card('Atouts (3 blocs)', [
    _listHeader('Liste', () => _edit((x) => x.features.add(Feature(title: 'Nouvel atout')))),
    for (var i = 0; i < c.features.length; i++)
      _itemBox(Column(children: [
        _tf('Icône (shield, doc, hub…)', c.features[i].icon, (v) => _edit((x) => x.features[i].icon = v.trim())),
        _tf('Titre', c.features[i].title, (v) => _edit((x) => x.features[i].title = v)),
        _tf('Texte', c.features[i].text, (v) => _edit((x) => x.features[i].text = v), lines: 2),
      ]), () => _edit((x) => x.features.removeAt(i))),
  ]);

  Widget _solutions(SiteContent c) => _card('Solutions', [
    _tf('Label', c.solutions.label, (v) => _edit((x) => x.solutions.label = v)),
    _tf('Titre', c.solutions.title, (v) => _edit((x) => x.solutions.title = v), lines: 2),
    _tf('Paragraphe', c.solutions.paragraph, (v) => _edit((x) => x.solutions.paragraph = v), lines: 3),
    _tf('Bouton', c.solutions.cta, (v) => _edit((x) => x.solutions.cta = v)),
    _tf('Libellé des liens', c.solutions.linkLabel, (v) => _edit((x) => x.solutions.linkLabel = v)),
    const Divider(),
    _listHeader('Solutions principales', () => _edit((x) => x.solutions.main.add(SolutionMain(title: 'Nouvelle')))),
    for (var i = 0; i < c.solutions.main.length; i++)
      _itemBox(Column(children: [
        _tf('Icône', c.solutions.main[i].icon, (v) => _edit((x) => x.solutions.main[i].icon = v.trim())),
        _tf('Titre', c.solutions.main[i].title, (v) => _edit((x) => x.solutions.main[i].title = v)),
        _tf('Sous-titre', c.solutions.main[i].subtitle, (v) => _edit((x) => x.solutions.main[i].subtitle = v)),
        _tf('Texte', c.solutions.main[i].text, (v) => _edit((x) => x.solutions.main[i].text = v), lines: 2),
        SwitchListTile(dense: true, contentPadding: EdgeInsets.zero,
            title: const Text('Mise en avant (carte sombre)', style: TextStyle(fontSize: 11)),
            value: c.solutions.main[i].featured,
            onChanged: (v) => _edit((x) => x.solutions.main[i].featured = v)),
      ]), () => _edit((x) => x.solutions.main.removeAt(i))),
    const Divider(),
    _listHeader('Mini-cartes', () => _edit((x) => x.solutions.minis.add(SolutionMini(title: 'Nouvelle')))),
    for (var i = 0; i < c.solutions.minis.length; i++)
      _itemBox(Column(children: [
        _tf('Icône', c.solutions.minis[i].icon, (v) => _edit((x) => x.solutions.minis[i].icon = v.trim())),
        _tf('Titre', c.solutions.minis[i].title, (v) => _edit((x) => x.solutions.minis[i].title = v)),
        _tf('Sous-titre', c.solutions.minis[i].subtitle, (v) => _edit((x) => x.solutions.minis[i].subtitle = v)),
      ]), () => _edit((x) => x.solutions.minis.removeAt(i))),
  ]);

  Widget _impact(SiteContent c) => _card('Impact', [
    _tf('Label', c.impact.label, (v) => _edit((x) => x.impact.label = v)),
    _tf('Titre', c.impact.title, (v) => _edit((x) => x.impact.title = v), lines: 2),
    _tf('Paragraphe', c.impact.paragraph, (v) => _edit((x) => x.impact.paragraph = v), lines: 3),
    _tf('Citation', c.impact.quote, (v) => _edit((x) => x.impact.quote = v), lines: 3),
    _listHeader('Chiffres clés', () => _edit((x) => x.impact.stats.add(Stat(value: '+0', label: 'Libellé')))),
    for (var i = 0; i < c.impact.stats.length; i++)
      _itemBox(Row(children: [
        SizedBox(width: 90, child: _tf('Valeur', c.impact.stats[i].value, (v) => _edit((x) => x.impact.stats[i].value = v))),
        const SizedBox(width: 8),
        Expanded(child: _tf('Libellé', c.impact.stats[i].label, (v) => _edit((x) => x.impact.stats[i].label = v), lines: 2)),
      ]), () => _edit((x) => x.impact.stats.removeAt(i))),
  ]);

  Widget _vision(SiteContent c) => _card('Vision', [
    _tf('Label', c.vision.label, (v) => _edit((x) => x.vision.label = v)),
    _tf('Titre', c.vision.title, (v) => _edit((x) => x.vision.title = v), lines: 2),
    _tf('Texte : début', c.vision.before, (v) => _edit((x) => x.vision.before = v), lines: 2),
    _tf('Texte : partie en gras', c.vision.bold, (v) => _edit((x) => x.vision.bold = v)),
    _tf('Texte : fin', c.vision.after, (v) => _edit((x) => x.vision.after = v), lines: 2),
    _tf('Bouton', c.vision.cta, (v) => _edit((x) => x.vision.cta = v)),
    _listHeader('Valeurs', () => _edit((x) => x.vision.values.add(ValueItem(title: 'Nouvelle valeur')))),
    for (var i = 0; i < c.vision.values.length; i++)
      _itemBox(Column(children: [
        _tf('Icône', c.vision.values[i].icon, (v) => _edit((x) => x.vision.values[i].icon = v.trim())),
        _tf('Titre', c.vision.values[i].title, (v) => _edit((x) => x.vision.values[i].title = v)),
        _tf('Texte', c.vision.values[i].text, (v) => _edit((x) => x.vision.values[i].text = v), lines: 2),
      ]), () => _edit((x) => x.vision.values.removeAt(i))),
  ]);

  Widget _footer(SiteContent c) => _card('Footer', [
    _tf('Tagline', c.footer.tagline, (v) => _edit((x) => x.footer.tagline = v)),
    _tf('Mentions légales', c.footer.legal, (v) => _edit((x) => x.footer.legal = v)),
    _tf('Signature', c.footer.signature, (v) => _edit((x) => x.footer.signature = v)),
    _tf('Newsletter : titre', c.footer.nlTitle, (v) => _edit((x) => x.footer.nlTitle = v)),
    _tf('Newsletter : texte', c.footer.nlText, (v) => _edit((x) => x.footer.nlText = v), lines: 2),
    _tf('Newsletter : note confidentialité', c.footer.privacyNote, (v) => _edit((x) => x.footer.privacyNote = v), lines: 2),
    _listHeader('Réseaux sociaux', () => _edit((x) => x.footer.socials.add(Social(icon: 'linkedin')))),
    for (var i = 0; i < c.footer.socials.length; i++)
      _itemBox(Column(children: [
        _tf('Icône (linkedin, x, youtube, telegram)', c.footer.socials[i].icon,
            (v) => _edit((x) => x.footer.socials[i].icon = v.trim())),
        _tf('URL (https uniquement, domaines approuvés)', c.footer.socials[i].url,
            (v) => _edit((x) => x.footer.socials[i].url = v.trim())),
      ]), () => _edit((x) => x.footer.socials.removeAt(i))),
  ]);

  Widget _consent(SiteContent c) => _card('Bannière de consentement (RGPD)', [
    _tf('Texte (vide = bannière masquée)', c.consentText, (v) => _edit((x) => x.consentText = v), lines: 4),
  ]);
}
