import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'security.dart';

/// ═══════════ REGISTRE D'ICÔNES ═══════════
const kIcons = <String, IconData>{
  'shield': Icons.verified_user_outlined, 'doc': Icons.description_outlined,
  'hub': Icons.hub_outlined, 'fingerprint': Icons.fingerprint,
  'ai': Icons.psychology_outlined, 'school': Icons.school_outlined,
  'wifi': Icons.wifi, 'care': Icons.favorite_outline,
  'food': Icons.eco_outlined, 'group': Icons.business_outlined,
  'bulb': Icons.lightbulb_outline, 'social': Icons.volunteer_activism_outlined,
  'leaf': Icons.eco_outlined, 'award': Icons.workspace_premium_outlined,
};
IconData iconOf(String? key) => kIcons[key ?? ''] ?? Icons.auto_awesome;

/// ═══════════ ANCRES DE NAVIGATION ═══════════
enum SectionId { home, about, solutions, impact, vision, actualites, contact }

/// ═══════════ MODÈLE DE CONTENU ═══════════
String _s(Map j, String k, [String d = '']) => (j[k] as String?) ?? d;
bool _b(Map j, String k, [bool d = false]) => (j[k] as bool?) ?? d;
List<Map<String, dynamic>> _l(Map j, String k) =>
    ((j[k] as List?) ?? const []).whereType<Map<String, dynamic>>().toList();

class Seo {
  String title, description;
  Seo({this.title = '', this.description = ''});
  Seo.fromJson(Map j)
      : title = _s(j, 'title'),
        description = _s(j, 'description');
  Map<String, dynamic> toJson() => {'title': title, 'description': description};
}

class NavLink {
  String label, target;
  NavLink({this.label = '', this.target = 'home'});
  NavLink.fromJson(Map j)
      : label = _s(j, 'label'),
        target = _s(j, 'target');
  Map<String, dynamic> toJson() => {'label': label, 'target': target};
}

class Nav {
  String ctaLabel;
  List<NavLink> links;
  Nav({this.ctaLabel = '', List<NavLink>? links}) : links = links ?? [];
  Nav.fromJson(Map j)
      : ctaLabel = _s(j, 'cta_label'),
        links = [for (final e in _l(j, 'links')) NavLink.fromJson(e)];
  Map<String, dynamic> toJson() =>
      {'cta_label': ctaLabel, 'links': [for (final l in links) l.toJson()]};
}

class HeroCard {
  String brand, nomLabel, name, idLabel, status, nfc;
  HeroCard({
    this.brand = '',
    this.nomLabel = '',
    this.name = '',
    this.idLabel = '',
    this.status = '',
    this.nfc = '',
  });
  HeroCard.fromJson(Map j)
      : brand = _s(j, 'brand'),
        nomLabel = _s(j, 'nom_label'),
        name = _s(j, 'name'),
        idLabel = _s(j, 'id_label'),
        status = _s(j, 'status'),
        nfc = _s(j, 'nfc');
  Map<String, dynamic> toJson() => {
        'brand': brand,
        'nom_label': nomLabel,
        'name': name,
        'id_label': idLabel,
        'status': status,
        'nfc': nfc,
      };
}

class Hero {
  List<String> eyebrow;
  String titleA, highlight, paragraph, ctaPrimary, ctaSecondary, badgeTitle, badgeText;
  HeroCard card;
  Hero({
    List<String>? eyebrow,
    this.titleA = '',
    this.highlight = '',
    this.paragraph = '',
    this.ctaPrimary = '',
    this.ctaSecondary = '',
    this.badgeTitle = '',
    this.badgeText = '',
    HeroCard? card,
  })  : eyebrow = eyebrow ?? [],
        card = card ?? HeroCard();
  Hero.fromJson(Map j)
      : eyebrow = ((j['eyebrow'] as List?) ?? const []).cast<String>(),
        titleA = _s(j, 'title_a'),
        highlight = _s(j, 'title_highlight'),
        paragraph = _s(j, 'paragraph'),
        ctaPrimary = _s(j, 'cta_primary'),
        ctaSecondary = _s(j, 'cta_secondary'),
        badgeTitle = _s(j, 'badge_title'),
        badgeText = _s(j, 'badge_text'),
        card = HeroCard.fromJson((j['card'] as Map?) ?? const {});
  Map<String, dynamic> toJson() => {
        'eyebrow': eyebrow,
        'title_a': titleA,
        'title_highlight': highlight,
        'paragraph': paragraph,
        'cta_primary': ctaPrimary,
        'cta_secondary': ctaSecondary,
        'badge_title': badgeTitle,
        'badge_text': badgeText,
        'card': card.toJson(),
      };
}

class Feature {
  String icon, title, text;
  Feature({this.icon = 'shield', this.title = '', this.text = ''});
  Feature.fromJson(Map j)
      : icon = _s(j, 'icon', 'shield'),
        title = _s(j, 'title'),
        text = _s(j, 'text');
  Map<String, dynamic> toJson() => {'icon': icon, 'title': title, 'text': text};
}

class SolutionMain {
  String icon, title, subtitle, text;
  bool featured;
  SolutionMain({
    this.icon = 'fingerprint',
    this.title = '',
    this.subtitle = '',
    this.text = '',
    this.featured = false,
  });
  SolutionMain.fromJson(Map j)
      : icon = _s(j, 'icon'),
        title = _s(j, 'title'),
        subtitle = _s(j, 'subtitle'),
        text = _s(j, 'text'),
        featured = _b(j, 'featured');
  Map<String, dynamic> toJson() => {
        'icon': icon,
        'title': title,
        'subtitle': subtitle,
        'text': text,
        'featured': featured,
      };
}

class SolutionMini {
  String icon, title, subtitle;
  SolutionMini({this.icon = 'wifi', this.title = '', this.subtitle = ''});
  SolutionMini.fromJson(Map j)
      : icon = _s(j, 'icon'),
        title = _s(j, 'title'),
        subtitle = _s(j, 'subtitle');
  Map<String, dynamic> toJson() => {'icon': icon, 'title': title, 'subtitle': subtitle};
}

class Solutions {
  String label, title, paragraph, cta, linkLabel;
  List<SolutionMain> main;
  List<SolutionMini> minis;
  Solutions({
    this.label = '',
    this.title = '',
    this.paragraph = '',
    this.cta = '',
    this.linkLabel = '',
    List<SolutionMain>? main,
    List<SolutionMini>? minis,
  })  : main = main ?? [],
        minis = minis ?? [];
  Solutions.fromJson(Map j)
      : label = _s(j, 'label'),
        title = _s(j, 'title'),
        paragraph = _s(j, 'paragraph'),
        cta = _s(j, 'cta'),
        linkLabel = _s(j, 'link_label'),
        main = [for (final e in _l(j, 'main')) SolutionMain.fromJson(e)],
        minis = [for (final e in _l(j, 'minis')) SolutionMini.fromJson(e)];
  Map<String, dynamic> toJson() => {
        'label': label,
        'title': title,
        'paragraph': paragraph,
        'cta': cta,
        'link_label': linkLabel,
        'main': [for (final m in main) m.toJson()],
        'minis': [for (final m in minis) m.toJson()],
      };
}

class Stat {
  String value, label;
  Stat({this.value = '', this.label = ''});
  Stat.fromJson(Map j)
      : value = _s(j, 'value'),
        label = _s(j, 'label');
  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

class Impact {
  String label, title, paragraph, cta, quote;
  List<Stat> stats;
  Impact({
    this.label = '',
    this.title = '',
    this.paragraph = '',
    this.cta = '',
    this.quote = '',
    List<Stat>? stats,
  }) : stats = stats ?? [];
  Impact.fromJson(Map j)
      : label = _s(j, 'label'),
        title = _s(j, 'title'),
        paragraph = _s(j, 'paragraph'),
        cta = _s(j, 'cta'),
        quote = _s(j, 'quote'),
        stats = [for (final e in _l(j, 'stats')) Stat.fromJson(e)];
  Map<String, dynamic> toJson() => {
        'label': label,
        'title': title,
        'paragraph': paragraph,
        'cta': cta,
        'quote': quote,
        'stats': [for (final s in stats) s.toJson()],
      };
}

class ValueItem {
  String icon, title, text;
  ValueItem({this.icon = 'bulb', this.title = '', this.text = ''});
  ValueItem.fromJson(Map j)
      : icon = _s(j, 'icon'),
        title = _s(j, 'title'),
        text = _s(j, 'text');
  Map<String, dynamic> toJson() => {'icon': icon, 'title': title, 'text': text};
}

class Vision {
  String label, title, before, bold, after, cta;
  List<ValueItem> values;
  Vision({
    this.label = '',
    this.title = '',
    this.before = '',
    this.bold = '',
    this.after = '',
    this.cta = '',
    List<ValueItem>? values,
  }) : values = values ?? [];
  Vision.fromJson(Map j)
      : label = _s(j, 'label'),
        title = _s(j, 'title'),
        before = _s(j, 'text_before'),
        bold = _s(j, 'text_bold'),
        after = _ss(j, 'text_after'),
        cta = _s(j, 'cta'),
        values = [for (final e in _l(j, 'values')) ValueItem.fromJson(e)];
  Map<String, dynamic> toJson() => {
        'label': label,
        'title': title,
        'text_before': before,
        'text_bold': bold,
        'text_after': after,
        'cta': cta,
        'values': [for (final v in values) v.toJson()],
      };
}

class Social {
  String icon, url;
  Social({this.icon = 'linkedin', this.url = ''});
  Social.fromJson(Map j)
      : icon = _s(j, 'icon'),
        url = _s(j, 'url');
  Map<String, dynamic> toJson() => {'icon': icon, 'url': url};
}

class FooterData {
  String tagline, navTitle, socialTitle, nlTitle, nlText, nlPlaceholder, privacyNote, legal, signature;
  List<Social> socials;
  FooterData({
    this.tagline = '',
    this.navTitle = '',
    this.socialTitle = '',
    this.nlTitle = '',
    this.nlText = '',
    this.nlPlaceholder = '',
    this.privacyNote = '',
    this.legal = '',
    this.signature = '',
    List<Social>? socials,
  }) : socials = socials ?? [];
  FooterData.fromJson(Map j)
      : tagline = _s(j, 'tagline'),
        navTitle = _s(j, 'nav_title'),
        socialTitle = _s(j, 'social_title'),
        nlTitle = _s(j, 'newsletter_title'),
        nlText = _s(j, 'newsletter_text'),
        nlPlaceholder = _s(j, 'newsletter_placeholder'),
        privacyNote = _s(j, 'privacy_note'),
        legal = _s(j, 'legal'),
        signature = _s(j, 'signature'),
        socials = [for (final e in _l(j, 'socials')) Social.fromJson(e)];
  Map<String, dynamic> toJson() => {
        'tagline': tagline,
        'nav_title': navTitle,
        'social_title': socialTitle,
        'newsletter_title': nlTitle,
        'newsletter_text': nlText,
        'newsletter_placeholder': nlPlaceholder,
        'privacy_note': privacyNote,
        'legal': legal,
        'signature': signature,
        'socials': [for (final s in socials) s.toJson()],
      };
}

class SiteContent {
  Seo seo;
  Nav nav;
  Hero hero;
  List<Feature> features;
  Solutions solutions;
  Impact impact;
  Vision vision;
  FooterData footer;
  String consentText;

  SiteContent({
    Seo? seo,
    Nav? nav,
    Hero? hero,
    List<Feature>? features,
    Solutions? solutions,
    Impact? impact,
    Vision? vision,
    FooterData? footer,
    this.consentText = '',
  })  : seo = seo ?? Seo(),
        nav = nav ?? Nav(),
        hero = hero ?? Hero(),
        features = features ?? [],
        solutions = solutions ?? Solutions(),
        impact = impact ?? Impact(),
        vision = vision ?? Vision(),
        footer = footer ?? FooterData();

  factory SiteContent.empty() => SiteContent();

  factory SiteContent.fromJson(Map<String, dynamic> j) => SiteContent(
        seo: Seo.fromJson((j['seo'] as Map?) ?? const {}),
        nav: Nav.fromJson((j['nav'] as Map?) ?? const {}),
        hero: Hero.fromJson((j['hero'] as Map?) ?? const {}),
        features: [for (final e in _l(j, 'features')) Feature.fromJson(e)],
        solutions: Solutions.fromJson((j['solutions'] as Map?) ?? const {}),
        impact: Impact.fromJson((j['impact'] as Map?) ?? const {}),
        vision: Vision.fromJson((j['vision'] as Map?) ?? const {}),
        footer: FooterData.fromJson((j['footer'] as Map?) ?? const {}),
        consentText: _s((j['consent'] as Map?) ?? const {}, 'text'),
      );

  Map<String, dynamic> toJson() => {
        'seo': seo.toJson(),
        'nav': nav.toJson(),
        'hero': hero.toJson(),
        'features': [for (final f in features) f.toJson()],
        'solutions': solutions.toJson(),
        'impact': impact.toJson(),
        'vision': vision.toJson(),
        'footer': footer.toJson(),
        'consent': {'text': consentText},
      };
}

// Helper pour éviter le crash si la clé n'existe pas
String _ss(Map j, String k) => (j[k] as String?) ?? '';

/// ═══════════ REPOSITORY ═══════════
class ContentRepository {
  static const _cacheKey = 'sonathix_published_cache_v1';
  
  SupabaseClient? get _sb {
    if (!Env.supabaseConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<SiteContent?> fetchPublished() async {
    final sb = _sb;
    if (sb == null) return null;
    final row = await sb.from('content_published').select('data').eq('id', 1).maybeSingle();
    if (row == null) return null;
    final c = SiteContent.fromJson(Map<String, dynamic>.from(row['data'] as Map));
    final p = await SharedPreferences.getInstance();
    await p.setString(_cacheKey, jsonEncode(c.toJson()));
    return c;
  }

  Future<SiteContent?> readCache() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return SiteContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<SiteContent?> fetchDraft() async {
    final sb = _sb;
    if (sb == null) throw const ConfigError('Supabase non configuré.');
    final row = await sb.from('content_draft').select('data').eq('id', 1).maybeSingle();
    if (row == null) return null;
    return SiteContent.fromJson(Map<String, dynamic>.from(row['data'] as Map));
  }

  Future<void> saveDraft(SiteContent c) async {
    final sb = _sb;
    if (sb == null) throw const ConfigError('Supabase non configuré.');
    await sb.from('content_draft').upsert({
      'id': 1,
      'data': c.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': sb.auth.currentUser?.id,
    });
  }

  Future<void> publish(SiteContent c) async {
    final sb = _sb;
    if (sb == null) throw const ConfigError('Supabase non configuré.');
    await sb.from('content_published').upsert({
      'id': 1,
      'data': c.toJson(),
      'published_at': DateTime.now().toUtc().toIso8601String(),
      'published_by': sb.auth.currentUser?.id,
    });
  }

  Future<SiteContent> loadSeed() async => SiteContent.fromJson(
      jsonDecode(await rootBundle.loadString('assets/seed.json')) as Map<String, dynamic>);
}

/// ═══════════ CONTROLLER ═══════════
class ContentController extends ChangeNotifier {
  ContentController(this.repo);
  final ContentRepository repo;

  SiteContent? published, draft;
  bool loading = false, saving = false, dirty = false;
  String? error, notice;

  Future<void> loadPublic() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      published = await repo.fetchPublished();
      published ??= await repo.readCache();
    } catch (e) {
      published = await repo.readCache();
      if (published == null) error = 'Contenu indisponible. Vérifiez la configuration.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadDraft() async {
    loading = true;
    notifyListeners();
    try {
      draft = await repo.fetchDraft();
      published ??= await repo.fetchPublished();
    } catch (e) {
      error = e is ConfigError ? e.message : 'Erreur de chargement du brouillon.';
    }
    loading = false;
    notifyListeners();
  }

  void edit(void Function(SiteContent c) f) {
    if (draft == null) return;
    f(draft!);
    dirty = true;
    notifyListeners();
  }

  Future<void> saveDraft() async {
    if (draft == null || saving) return;
    saving = true;
    notice = null;
    notifyListeners();
    try {
      await repo.saveDraft(draft!);
      dirty = false;
      notice = 'Brouillon enregistré.';
    } catch (e) {
      notice = e is ConfigError ? e.message : 'Échec de l\'enregistrement.';
    }
    saving = false;
    notifyListeners();
  }

  Future<void> publish() async {
    if (draft == null || saving) return;
    saving = true;
    notice = null;
    notifyListeners();
    try {
      await repo.saveDraft(draft!);
      await repo.publish(draft!);
      dirty = false;
      notice = '✔ Contenu publié sur le site.';
    } catch (e) {
      notice = e is ConfigError ? e.message : 'Échec de la publication.';
    }
    saving = false;
    notifyListeners();
  }

  Future<void> importSeed() async {
    draft = await repo.loadSeed();
    dirty = true;
    notifyListeners();
  }
}
