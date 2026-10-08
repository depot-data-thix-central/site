import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// Palette harmonisée — cohérente avec home_screen.dart
// ═══════════════════════════════════════════════════════════════
class _H {
  static const bg = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const surface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const subtext = Color(0xFF94A3B8);
  static const lightBorder = Color(0xFFCBD5E1);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFFEFF6FF);
}

// ═══════════════════════════════════════════════════════════════
// ÉCHELLE TYPOGRAPHIQUE — identique à home_screen.dart
// ═══════════════════════════════════════════════════════════════
class _T {
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
    fontSize: 18,
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
// ÉCRAN LÉGAL — Politique de confidentialité + CGU
// ═══════════════════════════════════════════════════════════════
enum LegalMode { privacy, terms, both }

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, this.mode = LegalMode.both});
  final LegalMode mode;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final _scroll = ScrollController();
  late final LegalMode _effectiveMode;

  @override
  void initState() {
    super.initState();
    _effectiveMode = widget.mode;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
        body: SingleChildScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LegalNavbar(),
              const _LegalHero(),
              if (_effectiveMode == LegalMode.both) ...[
                const _PrivacyContent(),
                const _TermsContent(),
              ],
              if (_effectiveMode == LegalMode.privacy) const _PrivacyContent(),
              if (_effectiveMode == LegalMode.terms) const _TermsContent(),
              const _LegalFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NAVBAR LÉGAL
// ═══════════════════════════════════════════════════════════════
class _LegalNavbar extends StatelessWidget {
  const _LegalNavbar();

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
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.of(context).pushNamed('/'),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: _H.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text('S',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ),
                const SizedBox(width: 10),
                const Text('SONATHIX',
                    style: TextStyle(
                        color: _H.ink,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 15)),
              ],
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Retour à l\'accueil',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _H.ink,
              side: const BorderSide(color: _H.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HERO LÉGAL
// ═══════════════════════════════════════════════════════════════
class _LegalHero extends StatelessWidget {
  const _LegalHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Container(
      width: double.infinity,
      color: _H.surface,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 72 : 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
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
                  'MENTIONS LÉGALES',
                  style: TextStyle(
                    color: _H.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Transparence & confiance.',
                style: _T.h1(isDesktop),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre vie privée et vos droits comptent. Cette page détaille comment SONATHIX GROUP collecte, utilise et protège vos données, ainsi que les conditions qui régissent l\'utilisation de notre site.',
                style: _T.body,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(width: 24, height: 2, color: _H.accent),
                  const SizedBox(width: 12),
                  const Text(
                    'Dernière mise à jour : 9 octobre 2026',
                    style: _T.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTENU — POLITIQUE DE CONFIDENTIALITÉ
// ═══════════════════════════════════════════════════════════════
class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('POLITIQUE DE CONFIDENTIALITÉ', style: _T.label),
              const SizedBox(height: 12),
              Text(
                'Comment nous protégeons vos données',
                style: _T.h2(MediaQuery.sizeOf(context).width >= 900),
              ),
              const SizedBox(height: 32),
              const _SectionBlock(
                number: '01',
                title: 'Responsable du traitement',
                content:
                    'Le site sonathix.com est édité par SONATHIX GROUP. Le responsable du traitement des données à caractère personnel est SONATHIX GROUP, joignable par e-mail à l\'adresse : contact@sonathix.com.',
              ),
              const _SectionBlock(
                number: '02',
                title: 'Données collectées',
                content:
                    'Nous collectons uniquement les données strictement nécessaires à la gestion de vos demandes : nom, prénom, adresse e-mail, numéro de téléphone et contenu de vos messages lorsque vous remplissez notre formulaire de contact.\n\nNous pouvons également collecter des données de navigation anonymes (cookies techniques) pour assurer le bon fonctionnement du site.',
              ),
              const _SectionBlock(
                number: '03',
                title: 'Finalités du traitement',
                content:
                    'Vos données sont traitées pour les finalités suivantes :\n\n• Répondre à vos demandes de contact et de renseignements\n• Vous informer sur nos services et solutions (avec votre consentement)\n• Assurer la sécurité et le bon fonctionnement du site\n• Respecter nos obligations légales et réglementaires',
              ),
              const _SectionBlock(
                number: '04',
                title: 'Durée de conservation',
                content:
                    'Les données transmises via notre formulaire de contact sont conservées pendant une durée maximale de 36 mois à compter du dernier échange. Les données de navigation techniques sont supprimées dans un délai de 13 mois.',
              ),
              const _SectionBlock(
                number: '05',
                title: 'Vos droits',
                content:
                    'Conformément à la réglementation en vigueur, vous disposez des droits suivants sur vos données :\n\n• Droit d\'accès — obtenir une copie de vos données\n• Droit de rectification — corriger des données inexactes\n• Droit à l\'effacement — demander la suppression de vos données\n• Droit à la limitation — restreindre le traitement\n• Droit d\'opposition — vous opposer au traitement\n• Droit à la portabilité — recevoir vos données dans un format structuré\n\nPour exercer ces droits, contactez-nous à : privacy@sonathix.com',
              ),
              const _SectionBlock(
                number: '06',
                title: 'Cookies',
                content:
                    'Notre site utilise uniquement des cookies techniques indispensables à son fonctionnement. Aucun cookie publicitaire ou de suivi n\'est déployé sans votre consentement explicite. Vous pouvez configurer votre navigateur pour refuser les cookies, mais cela peut affecter votre expérience.',
              ),
              const _SectionBlock(
                number: '07',
                title: 'Sécurité des données',
                content:
                    'Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données contre tout accès non autorisé, toute altération, divulgation ou destruction. Notre infrastructure repose sur Supabase, une plateforme conforme aux standards de sécurité les plus exigeants (chiffrement AES-256, TLS 1.3, conformité SOC 2).',
              ),
              const _SectionBlock(
                number: '08',
                title: 'Transferts internationaux',
                content:
                    'Vos données sont hébergées dans des centres de données sécurisés. En cas de transfert hors de votre juridiction, nous veillons à ce que des garanties appropriées soient en place (clauses contractuelles types, certifications reconnues).',
              ),
              const _SectionBlock(
                number: '09',
                title: 'Modifications de la politique',
                content:
                    'Nous nous réservons le droit de modifier cette politique à tout moment. Toute modification substantielle sera communiquée via une mise à jour de la date figurant en tête de cette page. Nous vous invitons à la consulter régulièrement.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTENU — CONDITIONS D'UTILISATION
// ═══════════════════════════════════════════════════════════════
class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _H.surface,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CONDITIONS GÉNÉRALES D'UTILISATION", style: _T.label),
              const SizedBox(height: 12),
              Text(
                'Cadre légal de votre utilisation',
                style: _T.h2(MediaQuery.sizeOf(context).width >= 900),
              ),
              const SizedBox(height: 32),
              const _SectionBlock(
                number: '01',
                title: 'Objet',
                content:
                    'Les présentes Conditions Générales d\'Utilisation (CGU) ont pour objet de définir les modalités d\'accès et d\'utilisation du site sonathix.com (ci-après « le Site ») édité par SONATHIX GROUP (ci-après « l\'Éditeur »).\n\nL\'accès et l\'utilisation du Site impliquent l\'acceptation pleine et entière des présentes CGU par tout visiteur (ci-après « l\'Utilisateur »).',
              ),
              const _SectionBlock(
                number: '02',
                title: 'Accès au site',
                content:
                    'Le Site est accessible gratuitement à tout Utilisateur disposant d\'un accès à Internet. L\'Éditeur ne saurait être tenu responsable des dommages de toute nature résultant de l\'accès au Site ou de son utilisation.\n\nL\'Éditeur se réserve le droit de suspendre, restreindre ou interrompre l\'accès au Site, en tout ou partie, sans préavis ni indemnité, notamment pour des raisons de maintenance.',
              ),
              const _SectionBlock(
                number: '03',
                title: 'Propriété intellectuelle',
                content:
                    'L\'ensemble des éléments constituant le Site (textes, graphismes, logiciels, photographies, images, vidéos, sons, plans, noms, logos, marques, créations et œuvres protégeables diverses, bases de données, etc.) ainsi que le Site lui-même, relèvent des législations sur le droit d\'auteur et sur le droit des marques.\n\nCes éléments sont la propriété exclusive de SONATHIX GROUP. Toute reproduction, représentation, modification, publication ou adaptation de tout ou partie des éléments du Site, quel que soit le moyen ou le procédé utilisé, est interdite sans autorisation écrite préalable de l\'Éditeur.',
              ),
              const _SectionBlock(
                number: '04',
                title: 'Responsabilités',
                content:
                    'SONATHIX GROUP s\'efforce de fournir sur le Site des informations aussi précises que possible. Toutefois, l\'Éditeur ne pourra être tenu responsable des omissions, inexactitudes ou carences dans la mise à jour, qu\'elles soient de son fait ou du fait des tiers partenaires qui lui fournissent ces informations.\n\nToutes les informations proposées sur le Site sont données à titre indicatif et sont susceptibles d\'évoluer. L\'Utilisateur est invité à vérifier leur exactitude.',
              ),
              const _SectionBlock(
                number: '05',
                title: 'Obligations de l\'Utilisateur',
                content:
                    'L\'Utilisateur s\'engage à :\n\n• Ne pas utiliser le Site à des fins illégales ou non autorisées\n• Ne pas tenter d\'obtenir un accès non autorisé aux systèmes informatiques de l\'Éditeur\n• Ne pas diffuser de contenu diffamatoire, injurieux, haineux ou portant atteinte aux droits d\'autrui\n• Ne pas altérer, dégrader ou perturber le bon fonctionnement du Site\n• Respecter les droits de propriété intellectuelle de l\'Éditeur',
              ),
              const _SectionBlock(
                number: '06',
                title: 'Liens hypertextes',
                content:
                    'Le Site peut contenir des liens hypertextes vers d\'autres sites Internet. SONATHIX GROUP ne contrôle pas ces sites tiers et décline toute responsabilité quant à leur contenu, leurs pratiques en matière de collecte de données ou tout autre aspect.',
              ),
              const _SectionBlock(
                number: '07',
                title: 'Force majeure',
                content:
                    'La responsabilité de SONATHIX GROUP ne pourra être engagée en cas de force majeure, telle que définie par la jurisprudence, ou en cas de dysfonctionnement du réseau Internet, d\'hébergeur ou d\'un prestataire technique indépendant de sa volonté.',
              ),
              const _SectionBlock(
                number: '08',
                title: 'Droit applicable',
                content:
                    'Les présentes CGU sont régies par le droit applicable dans la juridiction du siège social de SONATHIX GROUP. En cas de litige, et à défaut de résolution amiable, les tribunaux compétents de cette juridiction seront seuls compétents.',
              ),
              const _SectionBlock(
                number: '09',
                title: 'Contact',
                content:
                    'Pour toute question relative aux présentes CGU ou à l\'utilisation du Site, vous pouvez nous contacter à :\n\n📧 legal@sonathix.com\n🏢 SONATHIX GROUP — Direction Juridique',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BLOC DE SECTION RÉUTILISABLE
// ═══════════════════════════════════════════════════════════════
class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.number,
    required this.title,
    required this.content,
  });

  final String number;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _H.border),
        boxShadow: [
          BoxShadow(
            color: _H.ink.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _H.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: _H.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _T.h3),
                    const SizedBox(height: 12),
                    Text(content, style: _T.body),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FOOTER LÉGAL
// ═══════════════════════════════════════════════════════════════
class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
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
                spacing: 24,
                runSpacing: 8,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/legal?mode=privacy'),
                    child: const Text('Politique de confidentialité',
                        style: TextStyle(
                            color: _H.lightBorder,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/legal?mode=terms'),
                    child: const Text("Conditions d'utilisation",
                        style: TextStyle(
                            color: _H.lightBorder,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/'),
                    child: const Text('Accueil',
                        style: TextStyle(
                            color: _H.lightBorder,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text('SONATHIX GROUP',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 14)),
              const SizedBox(height: 8),
              const Text('Technology  •  Innovation  •  Africa',
                  style: TextStyle(color: _H.subtext, fontSize: 12)),
              const SizedBox(height: 20),
              const Text('© 2026 SONATHIX GROUP. Tous droits réservés.',
                  style: TextStyle(color: _H.muted, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
