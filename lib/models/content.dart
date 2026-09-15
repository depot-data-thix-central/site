import 'package:flutter/foundation.dart';

/// Modèle complet du site.
///
/// Caractéristiques :
/// - Immutabilité garantie (listes unmodifiable)
/// - Validation de longueur et sanitization des caractères dangereux
/// - Serialization JSON complète (from/to)
/// - Méthodes copyWith() et merge() pour édition admin
/// - Support images (URL + asset) pour features/solutions/hero/manager/vision
/// - SEO enrichi (OG tags, canonical, etc.)
/// - Métadonnées admin (version, lastUpdated)
/// - Aucun contenu métier hardcodé
@immutable
class SiteContent {
  // SEO
  final String seoTitle;
  final String seoDescription;
  final String seoKeywords;
  final String seoOgImage;
  final String seoCanonicalUrl;

  // Hero
  final String heroTitle;
  final String heroHighlight;
  final String heroParagraph;
  final String ctaPrimary;
  final String ctaSecondary;
  final String? heroImageUrl;
  final String? heroImageAsset;

  // Collections
  final List<Feature> features;
  final List<Solution> solutions;
  final List<Stat> stats;

  // Impact & Vision
  final String impactQuote;
  final String visionText;
  final String? visionImageUrl;
  final String? visionImageAsset;

  // Manager / Direction
  final String managerName;
  final String managerMessage;
  final String? managerPhotoUrl;

  // Consent & Footer
  final String consentText;
  final String footerLegal;

  // Admin metadata
  final int version;
  final DateTime? lastUpdated;
  final String? updatedBy;

  const SiteContent({
    this.seoTitle = '',
    this.seoDescription = '',
    this.seoKeywords = '',
    this.seoOgImage = '',
    this.seoCanonicalUrl = '',
    this.heroTitle = '',
    this.heroHighlight = '',
    this.heroParagraph = '',
    this.ctaPrimary = '',
    this.ctaSecondary = '',
    this.heroImageUrl,
    this.heroImageAsset,
    this.features = const [],
    this.solutions = const [],
    this.stats = const [],
    this.impactQuote = '',
    this.visionText = '',
    this.visionImageUrl,
    this.visionImageAsset,
    this.managerName = '',
    this.managerMessage = '',
    this.managerPhotoUrl,
    this.consentText = '',
    this.footerLegal = '',
    this.version = 1,
    this.lastUpdated,
    this.updatedBy,
  });

  /// Instance vierge. Tout le contenu est géré via l'administration/backend.
  factory SiteContent.empty() {
    return const SiteContent();
  }

  /// Alias pour compatibilité de test, retourne une instance vierge sans texte en dur.
  factory SiteContent.demo() {
    return const SiteContent();
  }

  /// Crée une instance depuis un JSON.
  ///
  /// Sanitize automatiquement les textes et valide les longueurs.
  /// Ne crash jamais : retourne une instance vide en cas d'erreur.
  factory SiteContent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SiteContent();

    try {
      final seo = json['seo'] as Map<String, dynamic>? ?? {};
      final hero = json['hero'] as Map<String, dynamic>? ?? {};
      final impact = json['impact'] as Map<String, dynamic>? ?? {};
      final vision = json['vision'] as Map<String, dynamic>? ?? {};
      final manager = json['manager'] as Map<String, dynamic>? ?? {};
      final footer = json['footer'] as Map<String, dynamic>? ?? {};
      final consent = json['consent'] as Map<String, dynamic>? ?? {};
      final meta = json['meta'] as Map<String, dynamic>? ?? {};

      return SiteContent(
        seoTitle: _safeString(seo['title'], defaultValue: '', maxLength: 80),
        seoDescription: _safeString(seo['description'], defaultValue: '', maxLength: 200),
        seoKeywords: _safeString(seo['keywords'], defaultValue: '', maxLength: 200),
        seoOgImage: _safeString(seo['ogImage'], defaultValue: '', maxLength: 500),
        seoCanonicalUrl: _safeString(seo['canonicalUrl'], defaultValue: '', maxLength: 500),
        heroTitle: _safeString(hero['title_a'], defaultValue: '', maxLength: 140),
        heroHighlight: _safeString(hero['title_highlight'], defaultValue: '', maxLength: 80),
        heroParagraph: _safeString(hero['paragraph'], defaultValue: '', maxLength: 600),
        ctaPrimary: _safeString(hero['cta_primary'], defaultValue: '', maxLength: 40),
        ctaSecondary: _safeString(hero['cta_secondary'], defaultValue: '', maxLength: 40),
        heroImageUrl: _safeUrl(hero['image_url']),
        heroImageAsset: _safeString(hero['image_asset'], defaultValue: null, maxLength: 200),
        features: _parseFeatures(json['features']),
        solutions: _parseSolutions(json['solutions']),
        stats: _parseStats(impact['stats']),
        impactQuote: _safeString(impact['quote'], defaultValue: '', maxLength: 400),
        visionText: _safeString(vision['text_bold'], defaultValue: '', maxLength: 1600),
        visionImageUrl: _safeUrl(vision['image_url']),
        visionImageAsset: _safeString(vision['image_asset'], defaultValue: null, maxLength: 200),
        managerName: _safeString(manager['name'], defaultValue: '', maxLength: 100),
        managerMessage: _safeString(manager['message'], defaultValue: '', maxLength: 600),
        managerPhotoUrl: _safeUrl(manager['photo_url']),
        consentText: _safeString(consent['text'], defaultValue: '', maxLength: 600),
        footerLegal: _safeString(footer['legal'], defaultValue: '', maxLength: 1200),
        version: meta['version'] is int ? meta['version'] as int : 1,
        lastUpdated: meta['lastUpdated'] is String ? DateTime.tryParse(meta['lastUpdated'] as String) : null,
        updatedBy: _safeString(meta['updatedBy'], defaultValue: null, maxLength: 100),
      );
    } catch (_) {
      return const SiteContent();
    }
  }

  /// Sérialise en JSON pour sauvegarde backend/admin.
  Map<String, dynamic> toJson() {
    return {
      'seo': {
        'title': seoTitle,
        'description': seoDescription,
        'keywords': seoKeywords,
        'ogImage': seoOgImage,
        'canonicalUrl': seoCanonicalUrl,
      },
      'hero': {
        'title_a': heroTitle,
        'title_highlight': heroHighlight,
        'paragraph': heroParagraph,
        'cta_primary': ctaPrimary,
        'cta_secondary': ctaSecondary,
        'image_url': heroImageUrl,
        'image_asset': heroImageAsset,
      },
      'features': features.map((f) => f.toJson()).toList(),
      'solutions': {
        'main': solutions.map((s) => s.toJson()).toList(),
      },
      'impact': {
        'stats': stats.map((s) => s.toJson()).toList(),
        'quote': impactQuote,
      },
      'vision': {
        'text_bold': visionText,
        'image_url': visionImageUrl,
        'image_asset': visionImageAsset,
      },
      'manager': {
        'name': managerName,
        'message': managerMessage,
        'photo_url': managerPhotoUrl,
      },
      'consent': {
        'text': consentText,
      },
      'footer': {
        'legal': footerLegal,
      },
      'meta': {
        'version': version,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'updatedBy': updatedBy,
      },
    };
  }

  /// Crée une copie avec certains champs modifiés.
  SiteContent copyWith({
    String? seoTitle,
    String? seoDescription,
    String? seoKeywords,
    String? seoOgImage,
    String? seoCanonicalUrl,
    String? heroTitle,
    String? heroHighlight,
    String? heroParagraph,
    String? ctaPrimary,
    String? ctaSecondary,
    String? heroImageUrl,
    String? heroImageAsset,
    List<Feature>? features,
    List<Solution>? solutions,
    List<Stat>? stats,
    String? impactQuote,
    String? visionText,
    String? visionImageUrl,
    String? visionImageAsset,
    String? managerName,
    String? managerMessage,
    String? managerPhotoUrl,
    String? consentText,
    String? footerLegal,
    int? version,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return SiteContent(
      seoTitle: seoTitle ?? this.seoTitle,
      seoDescription: seoDescription ?? this.seoDescription,
      seoKeywords: seoKeywords ?? this.seoKeywords,
      seoOgImage: seoOgImage ?? this.seoOgImage,
      seoCanonicalUrl: seoCanonicalUrl ?? this.seoCanonicalUrl,
      heroTitle: heroTitle ?? this.heroTitle,
      heroHighlight: heroHighlight ?? this.heroHighlight,
      heroParagraph: heroParagraph ?? this.heroParagraph,
      ctaPrimary: ctaPrimary ?? this.ctaPrimary,
      ctaSecondary: ctaSecondary ?? this.ctaSecondary,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      heroImageAsset: heroImageAsset ?? this.heroImageAsset,
      features: features ?? this.features,
      solutions: solutions ?? this.solutions,
      stats: stats ?? this.stats,
      impactQuote: impactQuote ?? this.impactQuote,
      visionText: visionText ?? this.visionText,
      visionImageUrl: visionImageUrl ?? this.visionImageUrl,
      visionImageAsset: visionImageAsset ?? this.visionImageAsset,
      managerName: managerName ?? this.managerName,
      managerMessage: managerMessage ?? this.managerMessage,
      managerPhotoUrl: managerPhotoUrl ?? this.managerPhotoUrl,
      consentText: consentText ?? this.consentText,
      footerLegal: footerLegal ?? this.footerLegal,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Fusionne avec un autre contenu (utile pour l'administration).
  SiteContent merge(SiteContent other) {
    return copyWith(
      seoTitle: other.seoTitle.isNotEmpty ? other.seoTitle : null,
      seoDescription: other.seoDescription.isNotEmpty ? other.seoDescription : null,
      seoKeywords: other.seoKeywords.isNotEmpty ? other.seoKeywords : null,
      seoOgImage: other.seoOgImage.isNotEmpty ? other.seoOgImage : null,
      seoCanonicalUrl: other.seoCanonicalUrl.isNotEmpty ? other.seoCanonicalUrl : null,
      heroTitle: other.heroTitle.isNotEmpty ? other.heroTitle : null,
      heroHighlight: other.heroHighlight.isNotEmpty ? other.heroHighlight : null,
      heroParagraph: other.heroParagraph.isNotEmpty ? other.heroParagraph : null,
      ctaPrimary: other.ctaPrimary.isNotEmpty ? other.ctaPrimary : null,
      ctaSecondary: other.ctaSecondary.isNotEmpty ? other.ctaSecondary : null,
      heroImageUrl: other.heroImageUrl ?? heroImageUrl,
      heroImageAsset: other.heroImageAsset ?? heroImageAsset,
      impactQuote: other.impactQuote.isNotEmpty ? other.impactQuote : null,
      visionText: other.visionText.isNotEmpty ? other.visionText : null,
      visionImageUrl: other.visionImageUrl ?? visionImageUrl,
      visionImageAsset: other.visionImageAsset ?? visionImageAsset,
      managerName: other.managerName.isNotEmpty ? other.managerName : null,
      managerMessage: other.managerMessage.isNotEmpty ? other.managerMessage : null,
      managerPhotoUrl: other.managerPhotoUrl ?? managerPhotoUrl,
      consentText: other.consentText.isNotEmpty ? other.consentText : null,
      footerLegal: other.footerLegal.isNotEmpty ? other.footerLegal : null,
      features: other.features.isNotEmpty ? other.features : null,
      solutions: other.solutions.isNotEmpty ? other.solutions : null,
      stats: other.stats.isNotEmpty ? other.stats : null,
      version: version + 1,
      lastUpdated: DateTime.now(),
      updatedBy: other.updatedBy ?? updatedBy,
    );
  }

  // -------------------------------------------------------------------------
  // PARSING HELPERS
  // -------------------------------------------------------------------------

  static List<Feature> _parseFeatures(dynamic list) {
    if (list is! List) return const [];

    final parsed = list
        .whereType<Map>()
        .map((e) => Feature(
              title: _safeString(e['title'], defaultValue: '', maxLength: 90),
              text: _safeString(e['text'], defaultValue: '', maxLength: 420),
              icon: _safeString(e['icon'], defaultValue: '', maxLength: 60),
              imageUrl: _safeUrl(e['image_url']),
              imageAsset: _safeString(e['image_asset'], defaultValue: null, maxLength: 200),
            ))
        .toList();

    return List.unmodifiable(parsed);
  }

  static List<Solution> _parseSolutions(dynamic data) {
    if (data is! Map) return const [];
    final main = data['main'];
    if (main is! List) return const [];

    final parsed = main
        .whereType<Map>()
        .map((e) => Solution(
              title: _safeString(e['title'], defaultValue: '', maxLength: 90),
              subtitle: _safeString(e['subtitle'], defaultValue: '', maxLength: 130),
              text: _safeString(e['text'], defaultValue: '', maxLength: 420),
              featured: e['featured'] == true,
              imageUrl: _safeUrl(e['image_url']),
              imageAsset: _safeString(e['image_asset'], defaultValue: null, maxLength: 200),
            ))
        .toList();

    return List.unmodifiable(parsed);
  }

  static List<Stat> _parseStats(dynamic list) {
    if (list is! List) return const [];

    final parsed = list
        .whereType<Map>()
        .map((e) => Stat(
              value: _safeString(e['value'], defaultValue: '', maxLength: 24),
              label: _safeString(e['label'], defaultValue: '', maxLength: 80),
            ))
        .toList();

    return List.unmodifiable(parsed);
  }

  // -------------------------------------------------------------------------
  // SECURITY & SANITIZATION HELPERS
  // -------------------------------------------------------------------------

  static String _safeString(
    dynamic value, {
    String? defaultValue,
    int maxLength = 4000,
  }) {
    if (value == null) return defaultValue ?? '';

    final str = value.toString();

    final cleaned = str
        .replaceAll(
          RegExp(
            r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFEFF\u202A-\u202E\u2066-\u2069]',
          ),
          '',
        )
        .trim();

    if (cleaned.isEmpty) return defaultValue ?? '';

    return _truncateSafely(cleaned, maxLength);
  }

  static String? _safeUrl(dynamic value) {
    if (value == null) return null;

    final str = value.toString().trim();
    if (str.isEmpty) return null;

    final uri = Uri.tryParse(str);
    if (uri == null || !uri.hasScheme) return null;

    if (!uri.isScheme('https')) return null;

    return _truncateSafely(str, 500);
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

  // -------------------------------------------------------------------------
  // EQUALITY
  // -------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SiteContent) return false;

    return seoTitle == other.seoTitle &&
        seoDescription == other.seoDescription &&
        seoKeywords == other.seoKeywords &&
        seoOgImage == other.seoOgImage &&
        seoCanonicalUrl == other.seoCanonicalUrl &&
        heroTitle == other.heroTitle &&
        heroHighlight == other.heroHighlight &&
        heroParagraph == other.heroParagraph &&
        ctaPrimary == other.ctaPrimary &&
        ctaSecondary == other.ctaSecondary &&
        heroImageUrl == other.heroImageUrl &&
        heroImageAsset == other.heroImageAsset &&
        impactQuote == other.impactQuote &&
        visionText == other.visionText &&
        visionImageUrl == other.visionImageUrl &&
        visionImageAsset == other.visionImageAsset &&
        managerName == other.managerName &&
        managerMessage == other.managerMessage &&
        managerPhotoUrl == other.managerPhotoUrl &&
        consentText == other.consentText &&
        footerLegal == other.footerLegal &&
        version == other.version;
  }

    @override
  int get hashCode => Object.hash(
        seoTitle,
        seoDescription,
        seoKeywords,
        seoOgImage,
        seoCanonicalUrl,
        heroTitle,
        heroHighlight,
        heroParagraph,
        ctaPrimary,
        ctaSecondary,
        heroImageUrl,
        heroImageAsset,
        impactQuote,
        visionText,
        visionImageUrl,
        visionImageAsset,
        managerName,
        managerMessage,
        managerPhotoUrl,
        Object.hash(
          consentText,
          footerLegal,
          version,
        ),
      );



/// Feature (caractéristique produit/service).
@immutable
class Feature {
  final String title;
  final String text;
  final String icon;
  final String? imageUrl;
  final String? imageAsset;

  const Feature({
    this.title = '',
    this.text = '',
    this.icon = '',
    this.imageUrl,
    this.imageAsset,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'text': text,
      'icon': icon,
      'image_url': imageUrl,
      'image_asset': imageAsset,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Feature) return false;
    return title == other.title && text == other.text && icon == other.icon;
  }

  @override
  int get hashCode => Object.hash(title, text, icon);
}

/// Solution (offre commerciale).
@immutable
class Solution {
  final String title;
  final String subtitle;
  final String text;
  final bool featured;
  final String? imageUrl;
  final String? imageAsset;

  const Solution({
    this.title = '',
    this.subtitle = '',
    this.text = '',
    this.featured = false,
    this.imageUrl,
    this.imageAsset,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'text': text,
      'featured': featured,
      'image_url': imageUrl,
      'image_asset': imageAsset,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Solution) return false;
    return title == other.title && subtitle == other.subtitle && featured == other.featured;
  }

  @override
  int get hashCode => Object.hash(title, subtitle, featured);
}

/// Stat (chiffre clé).
@immutable
class Stat {
  final String value;
  final String label;

  const Stat({
    this.value = '',
    this.label = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Stat) return false;
    return value == other.value && label == other.label;
  }

  @override
  int get hashCode => Object.hash(value, label);
}
