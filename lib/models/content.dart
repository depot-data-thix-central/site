class SiteContent {
  final String seoTitle;
  final String seoDescription;
  final String heroTitle;
  final String heroHighlight;
  final String heroParagraph;
  final String ctaPrimary;
  final String ctaSecondary;
  final List<Feature> features;
  final List<Solution> solutions;
  final List<Stat> stats;
  final String impactQuote;
  final String visionText;
  final String consentText;
  final String footerLegal;

  const SiteContent({
    this.seoTitle = 'SONATHIX GROUP',
    this.seoDescription = '',
    this.heroTitle = 'Construire la confiance numérique de ',
    this.heroHighlight = 'demain.',
    this.heroParagraph =
        'SONATHIX GROUP développe des solutions technologiques pour une Afrique plus connectée, sécurisée et innovante.',
    this.ctaPrimary = 'Découvrir THIX ID',
    this.ctaSecondary = 'Notre vision',
    this.features = const [],
    this.solutions = const [],
    this.stats = const [],
    this.impactQuote = 'Une Afrique plus connectée, plus forte, plus libre.',
    this.visionText =
        'Mettre la technologie au service des hommes et des territoires.',
    this.consentText =
        'Nous n\'utilisons aucun cookie publicitaire. Un stockage local strictement nécessaire peut être utilisé.',
    this.footerLegal = '© 2026 SONATHIX GROUP. Tous droits réservés.',
  });

  factory SiteContent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SiteContent();

    final hero = json['hero'] as Map<String, dynamic>? ?? {};
    final seo = json['seo'] as Map<String, dynamic>? ?? {};
    final impact = json['impact'] as Map<String, dynamic>? ?? {};
    final vision = json['vision'] as Map<String, dynamic>? ?? {};
    final footer = json['footer'] as Map<String, dynamic>? ?? {};
    final consent = json['consent'] as Map<String, dynamic>? ?? {};

    return SiteContent(
      seoTitle: seo['title']?.toString() ?? 'SONATHIX GROUP',
      seoDescription: seo['description']?.toString() ?? '',
      heroTitle: hero['title_a']?.toString() ?? 'Construire la confiance numérique de ',
      heroHighlight: hero['title_highlight']?.toString() ?? 'demain.',
      heroParagraph: hero['paragraph']?.toString() ?? '',
      ctaPrimary: hero['cta_primary']?.toString() ?? 'Découvrir THIX ID',
      ctaSecondary: hero['cta_secondary']?.toString() ?? 'Notre vision',
      features: _parseFeatures(json['features']),
      solutions: _parseSolutions(json['solutions']),
      stats: _parseStats(impact['stats']),
      impactQuote: impact['quote']?.toString() ?? '',
      visionText: vision['text_bold']?.toString() ?? '',
      consentText: consent['text']?.toString() ?? '',
      footerLegal: footer['legal']?.toString() ?? '© 2026 SONATHIX GROUP',
    );
  }

  static List<Feature> _parseFeatures(dynamic list) {
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => Feature(
              title: e['title']?.toString() ?? '',
              text: e['text']?.toString() ?? '',
              icon: e['icon']?.toString() ?? 'shield',
            ))
        .toList();
  }

  static List<Solution> _parseSolutions(dynamic data) {
    if (data is! Map) return [];
    final main = data['main'];
    if (main is! List) return [];
    return main
        .whereType<Map>()
        .map((e) => Solution(
              title: e['title']?.toString() ?? '',
              subtitle: e['subtitle']?.toString() ?? '',
              text: e['text']?.toString() ?? '',
              featured: e['featured'] == true,
            ))
        .toList();
  }

  static List<Stat> _parseStats(dynamic list) {
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => Stat(
              value: e['value']?.toString() ?? '',
              label: e['label']?.toString() ?? '',
            ))
        .toList();
  }
}

class Feature {
  final String title;
  final String text;
  final String icon;
  const Feature({this.title = '', this.text = '', this.icon = 'shield'});
}

class Solution {
  final String title;
  final String subtitle;
  final String text;
  final bool featured;
  const Solution({
    this.title = '',
    this.subtitle = '',
    this.text = '',
    this.featured = false,
  });
}

class Stat {
  final String value;
  final String label;
  const Stat({this.value = '', this.label = ''});
}
