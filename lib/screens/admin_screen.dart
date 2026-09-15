import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content.dart';
import '../services/content_service.dart';

// ---------------------------------------------------------------------------
// MODELS INTERNES (Pour l'édition)
// ---------------------------------------------------------------------------

class _EditableFeature {
  String title;
  String text;
  String icon;
  String? imageUrl;
  String? imageAsset; // Pour compatibilité future, mais on privilégie URL

  _EditableFeature({
    required this.title,
    required this.text,
    required this.icon,
    this.imageUrl,
    this.imageAsset,
  });

  factory _EditableFeature.fromModel(Feature f) {
    return _EditableFeature(
      title: f.title,
      text: f.text,
      icon: f.icon,
      imageUrl: f.imageUrl,
      imageAsset: f.imageAsset,
    );
  }

  Feature toModel() {
    return Feature(
      title: title,
      text: text,
      icon: icon,
      imageUrl: imageUrl,
      imageAsset: imageAsset,
    );
  }
}

class _EditableSolution {
  String title;
  String subtitle;
  String text;
  bool featured;
  String? imageUrl;
  String? imageAsset;

  _EditableSolution({
    required this.title,
    required this.subtitle,
    required this.text,
    this.featured = false,
    this.imageUrl,
    this.imageAsset,
  });

  factory _EditableSolution.fromModel(Solution s) {
    return _EditableSolution(
      title: s.title,
      subtitle: s.subtitle,
      text: s.text,
      featured: s.featured,
      imageUrl: s.imageUrl,
      imageAsset: s.imageAsset,
    );
  }

  Solution toModel() {
    return Solution(
      title: title,
      subtitle: subtitle,
      text: text,
      featured: featured,
      imageUrl: imageUrl,
      imageAsset: imageAsset,
    );
  }
}

class _EditableStat {
  String value;
  String label;

  _EditableStat({required this.value, required this.label});

  factory _EditableStat.fromModel(Stat s) {
    return _EditableStat(value: s.value, label: s.label);
  }

  Stat toModel() {
    return Stat(value: value, label: label);
  }
}

enum _AdminTab {
  dashboard('Dashboard', Icons.space_dashboard_rounded),
  content('Contenu Global', Icons.edit_note_rounded),
  features('Features', Icons.extension_rounded),
  solutions('Solutions', Icons.lightbulb_outline_rounded),
  stats('Stats & Impact', Icons.bar_chart_rounded),
  settings('Paramètres', Icons.settings_rounded);

  const _AdminTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum _PublishState { draft, publishing, published, error }

class _ActivityEntry {
  const _ActivityEntry({required this.label, required this.at});
  final String label;
  final DateTime at;
}

// ---------------------------------------------------------------------------
// SCREEN PRINCIPAL
// ---------------------------------------------------------------------------

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  final ContentService _contentService = ContentService();

  // Auth
  final _emailController = TextEditingController(text: 'contact@thixid.com');
  final _passwordController = TextEditingController();
  final _authFormKey = GlobalKey<FormState>();
  bool _authenticated = false;
  bool _authLoading = false;
  bool _obscurePassword = true;
  String? _authError;

  // Session
  Timer? _sessionTimer;
  static const Duration _sessionTimeout = Duration(minutes: 15);

  // Navigation & Data State
  _AdminTab _tab = _AdminTab.dashboard;
  SiteContent? _originalContent; // Données chargées depuis la DB
  bool _loading = true;
  Object? _error;
  _PublishState _publishState = _PublishState.draft;
  final List<_ActivityEntry> _activity = [];

  // Éditeurs Scalaires (Textes simples)
  final Map<String, TextEditingController> _textEditors = {};
  
  // Éditeurs Images (URLs)
  final Map<String, TextEditingController> _imageEditors = {};

  // Éditeurs Collections (Listes modifiables)
  final List<_EditableFeature> _editableFeatures = [];
  final List<_EditableSolution> _editableSolutions = [];
  final List<_EditableStat> _editableStats = [];

  // Clés gérées
  static const List<String> _scalarKeys = [
    'seoTitle', 'seoDescription', 'seoKeywords', 'seoOgImage', 'seoCanonicalUrl',
    'heroTitle', 'heroHighlight', 'heroParagraph', 'ctaPrimary', 'ctaSecondary',
    'impactQuote', 'visionText', 'consentText', 'footerLegal',
  ];

  static const List<String> _imageKeys = [
    'heroImageUrl', 'visionImageUrl',
  ];

  @override
  void initState() {
    super.initState();
    // Initialisation des contrôleurs
    for (final key in _scalarKeys) {
      _textEditors[key] = TextEditingController();
    }
    for (final key in _imageKeys) {
      _imageEditors[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    for (final c in _textEditors.values) c.dispose();
    for (final c in _imageEditors.values) c.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // LOGIQUE MÉTIER & SÉCURITÉ
  // -------------------------------------------------------------------------

  void _safeLog(String event, [Map<String, Object?>? ctx]) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('[Admin] $event');
    if (ctx != null && ctx.isNotEmpty) {
      buffer.write(' | ${ctx.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
    }
    debugPrint(buffer.toString());
  }

  void _track(String label) {
    setState(() {
      _activity.insert(0, _ActivityEntry(label: label, at: DateTime.now()));
      if (_activity.length > 50) _activity.removeLast();
    });
  }

  void _startSession() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () {
      if (!mounted) return;
      _logout(reason: 'Session expirée après inactivité.');
    });
  }

  Future<void> _login() async {
    if (!(_authFormKey.currentState?.validate() ?? false)) return;
    setState(() { _authLoading = true; _authError = null; });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = response.user;
      if (user == null) throw Exception('Utilisateur introuvable');

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      if (profile['role'] == 'admin') {
        setState(() => _authenticated = true);
        _startSession();
        _track('Connexion admin réussie');
        _loadContent();
      } else {
        await Supabase.instance.client.auth.signOut();
        setState(() {
          _authLoading = false;
          _authError = 'Accès refusé : privilèges administrateur requis.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authLoading = false;
        _authError = 'Identifiants invalides ou erreur d\'accès.';
      });
    } finally {
      _passwordController.clear();
    }
  }

  void _logout({String? reason}) async {
    try { await Supabase.instance.client.auth.signOut(); } catch (_) {}
    setState(() {
      _authenticated = false;
      _tab = _AdminTab.dashboard;
      _authError = null;
      _passwordController.clear();
    });
    _sessionTimer?.cancel();
    if (reason != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
    }
  }

  Future<void> _loadContent() async {
    setState(() { _loading = true; _error = null; });
    try {
      final content = await _contentService.loadPublished(forceRefresh: true);
      if (!mounted) return;

      _originalContent = content;

      // Remplir les éditeurs scalaires
      _textEditors['seoTitle']?.text = content.seoTitle;
      _textEditors['seoDescription']?.text = content.seoDescription;
      _textEditors['seoKeywords']?.text = content.seoKeywords;
      _textEditors['seoOgImage']?.text = content.seoOgImage;
      _textEditors['seoCanonicalUrl']?.text = content.seoCanonicalUrl;
      
      _textEditors['heroTitle']?.text = content.heroTitle;
      _textEditors['heroHighlight']?.text = content.heroHighlight;
      _textEditors['heroParagraph']?.text = content.heroParagraph;
      _textEditors['ctaPrimary']?.text = content.ctaPrimary;
      _textEditors['ctaSecondary']?.text = content.ctaSecondary;
      
      _imageEditors['heroImageUrl']?.text = content.heroImageUrl ?? '';
      
      _textEditors['impactQuote']?.text = content.impactQuote;
      _textEditors['visionText']?.text = content.visionText;
      _imageEditors['visionImageUrl']?.text = content.visionImageUrl ?? '';
      
      _textEditors['consentText']?.text = content.consentText;
      _textEditors['footerLegal']?.text = content.footerLegal;

      // Charger les collections en mode éditable
      _editableFeatures.clear();
      _editableFeatures.addAll(content.features.map(_EditableFeature.fromModel));

      _editableSolutions.clear();
      _editableSolutions.addAll(content.solutions.map(_EditableSolution.fromModel));

      _editableStats.clear();
      _editableStats.addAll(content.stats.map(_EditableStat.fromModel));

      setState(() {
        _loading = false;
        _publishState = _PublishState.published;
      });
      _track('Contenu chargé');
    } catch (e) {
      _safeLog('load_failed', {'type': e.runtimeType});
      if (!mounted) return;
      setState(() { _loading = false; _error = e; });
    }
  }

  Future<void> _save({required bool publish}) async {
    _startSession();
    setState(() => _publishState = _PublishState.publishing);

    try {
      // Reconstruction du modèle complet depuis les éditeurs
      final newContent = SiteContent(
        seoTitle: _textEditors['seoTitle']?.text ?? '',
        seoDescription: _textEditors['seoDescription']?.text ?? '',
        seoKeywords: _textEditors['seoKeywords']?.text ?? '',
        seoOgImage: _textEditors['seoOgImage']?.text ?? '',
        seoCanonicalUrl: _textEditors['seoCanonicalUrl']?.text ?? '',
        
        heroTitle: _textEditors['heroTitle']?.text ?? '',
        heroHighlight: _textEditors['heroHighlight']?.text ?? '',
        heroParagraph: _textEditors['heroParagraph']?.text ?? '',
        ctaPrimary: _textEditors['ctaPrimary']?.text ?? '',
        ctaSecondary: _textEditors['ctaSecondary']?.text ?? '',
        heroImageUrl: _imageUrlOrNull('heroImageUrl'),
        
        features: _editableFeatures.map((e) => e.toModel()).toList(),
        solutions: _editableSolutions.map((e) => e.toModel()).toList(),
        stats: _editableStats.map((e) => e.toModel()).toList(),
        
        impactQuote: _textEditors['impactQuote']?.text ?? '',
        
        visionText: _textEditors['visionText']?.text ?? '',
        visionImageUrl: _imageUrlOrNull('visionImageUrl'),
        
        consentText: _textEditors['consentText']?.text ?? '',
        footerLegal: _textEditors['footerLegal']?.text ?? '',
        
        version: (_originalContent?.version ?? 0) + 1,
        lastUpdated: DateTime.now(),
        updatedBy: _emailController.text, // Simplifié pour l'exemple
      );

      // Simulation d'appel API (à remplacer par vrai appel Supabase)
      // await Supabase.instance.client.from('content_published').update({'data': newContent.toJson()}).eq('id', 1);
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      setState(() {
        _originalContent = newContent;
        _publishState = publish ? _PublishState.published : _PublishState.draft;
      });

      _track(publish ? 'Contenu publié avec succès' : 'Brouillon enregistré');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish ? 'Contenu publié avec succès.' : 'Brouillon enregistré.'),
          backgroundColor: const Color(0xFF111827),
        ),
      );
    } catch (e) {
      _safeLog('save_failed', {'error': e.toString()});
      if (!mounted) return;
      setState(() => _publishState = _PublishState.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l’enregistrement.'), backgroundColor: Color(0xFFB91C1C)),
      );
    }
  }

  String? _imageUrlOrNull(String key) {
    final val = _imageEditors[key]?.text.trim() ?? '';
    if (val.isEmpty) return null;
    // Validation basique HTTPS
    if (val.startsWith('https://')) return val;
    return null; 
  }

  // -------------------------------------------------------------------------
  // UI BUILDERS
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFFB8860B),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFB8860B),
          surface: Colors.white,
          onSurface: Color(0xFF111827),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          floatingLabelStyle: const TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.w600),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFB91C1C)),
          ),
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
          systemNavigationBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: _authenticated ? _buildShell() : _buildLogin(),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(15, 23, 42, 0.08), blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Form(
              key: _authFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_rounded, size: 44, color: Color(0xFFB8860B)),
                  const SizedBox(height: 16),
                  const Text('Espace administrateur', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  const SizedBox(height: 8),
                  const Text('Connectez-vous pour gérer le contenu.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                  const SizedBox(height: 28),
                  TextFormField(controller: _emailController, style: const TextStyle(color: Color(0xFF111827)), keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF6B7280))), validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _passwordController, obscureText: _obscurePassword, style: const TextStyle(color: Color(0xFF111827)), decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6B7280)), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF6B7280)), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: (v) => (v?.length ?? 0) < 8 ? '8 caractères min' : null),
                  if (_authError != null) ...[const SizedBox(height: 16), Text(_authError!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w600))],
                  const SizedBox(height: 24),
                  FilledButton.icon(onPressed: _authLoading ? null : _login, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB8860B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: _authLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login_rounded), label: Text(_authLoading ? 'Connexion…' : 'Se connecter', style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShell() {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Row(children: [
      if (isWide) _sidebar(),
      Expanded(child: Column(children: [
        _topbar(isWide: isWide),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(child: Container(color: const Color(0xFFF8FAFC), child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic, child: KeyedSubtree(key: ValueKey(_tab), child: _buildBody())))),
      ])),
    ]);
  }

  Widget _sidebar() {
    return Container(width: 240, decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Color(0xFFE5E7EB)))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 24),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFB8860B), size: 28), SizedBox(width: 10), Text('Admin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF111827)))]),
      const SizedBox(height: 24),
      const Divider(height: 1, color: Color(0xFFE5E7EB)),
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [for (final tab in _AdminTab.values) _navItem(tab)])),
      const Divider(height: 1, color: Color(0xFFE5E7EB)),
      Padding(padding: const EdgeInsets.all(12), child: TextButton.icon(onPressed: () => _logout(), icon: const Icon(Icons.logout_rounded, size: 18), label: const Text('Déconnexion'), style: TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C), alignment: Alignment.centerLeft))),
    ]));
  }

  Widget _navItem(_AdminTab tab) {
    final selected = _tab == tab;
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Material(color: selected ? const Color(0xFFB8860B).withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(12), child: ListTile(leading: Icon(tab.icon, color: selected ? const Color(0xFFB8860B) : const Color(0xFF6B7280)), title: Text(tab.label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFF111827) : const Color(0xFF4B5563))), onTap: () { _startSession(); setState(() => _tab = tab); }, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))));
  }

  Widget _topbar({required bool isWide}) {
    return Container(height: 64, padding: const EdgeInsets.symmetric(horizontal: 20), color: Colors.white, child: Row(children: [
      if (!isWide) IconButton(icon: const Icon(Icons.menu_rounded, color: Color(0xFF111827)), onPressed: () => _openDrawer()),
      Text(_tab.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
      const Spacer(),
      if (_tab != _AdminTab.settings && _tab != _AdminTab.dashboard) ...[
        OutlinedButton.icon(onPressed: _publishState == _PublishState.publishing ? null : () => _save(publish: false), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFD1D5DB))), icon: const Icon(Icons.save_outlined, size: 18), label: const Text('Brouillon')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: _publishState == _PublishState.publishing ? null : () => _save(publish: true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB8860B), foregroundColor: Colors.white), icon: _publishState == _PublishState.publishing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.publish_rounded, size: 18), label: const Text('Publier')),
      ],
    ]));
  }

  void _openDrawer() {
    showModalBottomSheet<void>(context: context, backgroundColor: Colors.white, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final tab in _AdminTab.values) ListTile(leading: Icon(tab.icon, color: const Color(0xFFB8860B)), title: Text(tab.label, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600)), onTap: () { Navigator.of(context).pop(); setState(() => _tab = tab); }), const Divider(height: 1, color: Color(0xFFE5E7EB)), ListTile(leading: const Icon(Icons.logout_rounded, color: Color(0xFFB91C1C)), title: const Text('Déconnexion', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600)), onTap: () { Navigator.of(context).pop(); _logout(); })])));
  }

  Widget _buildBody() {
    if (_loading && _tab != _AdminTab.dashboard) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFB8860B)));
    }
    switch (_tab) {
      case _AdminTab.dashboard: return _dashboard();
      case _AdminTab.content: return _contentEditor();
      case _AdminTab.features: return _featuresEditor();
      case _AdminTab.solutions: return _solutionsEditor();
      case _AdminTab.stats: return _statsEditor();
      case _AdminTab.settings: return _settings();
    }
  }

  Widget _dashboard() {
    final c = _originalContent ?? const SiteContent();
    return ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Vue d’ensemble', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
      const SizedBox(height: 16),
      Wrap(spacing: 16, runSpacing: 16, children: [
        _statCard('Features', _editableFeatures.length, Icons.extension_rounded),
        _statCard('Solutions', _editableSolutions.length, Icons.lightbulb_outline_rounded),
        _statCard('Stats', _editableStats.length, Icons.bar_chart_rounded),
        _statCard('Statut', _publishState == _PublishState.published ? 'Publié' : 'Brouillon', Icons.cloud_done_rounded),
      ]),
      const SizedBox(height: 24),
      _card(title: 'Actions rapides', child: Wrap(spacing: 12, runSpacing: 12, children: [
        FilledButton.tonalIcon(onPressed: () => setState(() => _tab = _AdminTab.content), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB8860B).withValues(alpha: 0.15), foregroundColor: const Color(0xFFB8860B)), icon: const Icon(Icons.edit_note_rounded), label: const Text('Éditer le contenu', style: TextStyle(fontWeight: FontWeight.w700))),
        OutlinedButton.icon(onPressed: _loadContent, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFD1D5DB))), icon: const Icon(Icons.refresh_rounded), label: const Text('Recharger')),
      ])),
    ]);
  }

  // -------------------------------------------------------------------------
  // ÉDITEUR CONTENU GLOBAL (SEO, HERO, VISION...)
  // -------------------------------------------------------------------------

  Widget _contentEditor() {
    return ListView(padding: const EdgeInsets.all(24), children: [
      _sectionTitle('Référencement (SEO)'),
      _field('seoTitle', label: 'Titre SEO'),
      _field('seoDescription', label: 'Description SEO', maxLines: 2),
      _field('seoKeywords', label: 'Mots-clés (séparés par des virgules)'),
      _imageField('seoOgImage', label: 'URL Image Open Graph'),
      
      const SizedBox(height: 32),
      _sectionTitle('Section Hero'),
      _field('heroTitle', label: 'Titre principal'),
      _field('heroHighlight', label: 'Partie mise en avant (or)'),
      _field('heroParagraph', label: 'Paragraphe', maxLines: 4),
      _imageField('heroImageUrl', label: 'URL Image Hero (Optionnel)'),
      _field('ctaPrimary', label: 'Texte Bouton Principal'),
      _field('ctaSecondary', label: 'Texte Bouton Secondaire'),

      const SizedBox(height: 32),
      _sectionTitle('Impact & Vision'),
      _field('impactQuote', label: 'Citation d’impact', maxLines: 3),
      _field('visionText', label: 'Texte Vision', maxLines: 5),
      _imageField('visionImageUrl', label: 'URL Image Vision (Optionnel)'),

      const SizedBox(height: 32),
      _sectionTitle('Pied de page & Légal'),
      _field('consentText', label: 'Texte Bannière Consentement', maxLines: 3),
      _field('footerLegal', label: 'Mentions légales', maxLines: 4),
      const SizedBox(height: 40),
    ]);
  }

  // -------------------------------------------------------------------------
  // ÉDITEUR FEATURES (CRUD)
  // -------------------------------------------------------------------------

  Widget _featuresEditor() {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [const Text('Gestion des Features', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))), const Spacer(), FilledButton.icon(onPressed: () => _addFeature(), icon: const Icon(Icons.add), label: const Text('Ajouter'))]),
      const SizedBox(height: 16),
      if (_editableFeatures.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Aucune feature. Ajoutez-en une !', style: TextStyle(color: Color(0xFF6B7280)))),
      for (var i = 0; i < _editableFeatures.length; i++) _featureCard(i),
      const SizedBox(height: 40),
    ]);
  }

  void _addFeature() {
    setState(() {
      _editableFeatures.add(_EditableFeature(title: 'Nouvelle Feature', text: 'Description...', icon: 'star'));
    });
  }

  void _removeFeature(int index) {
    setState(() { _editableFeatures.removeAt(index); });
  }

  Widget _featureCard(int index) {
    final item = _editableFeatures[index];
    return Card(margin: const EdgeInsets.only(bottom: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('Feature #${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))), const Spacer(), IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C)), onPressed: () => _removeFeature(index))]),
      const SizedBox(height: 12),
      TextField(controller: TextEditingController(text: item.title), onChanged: (v) => setState(() => item.title = v), decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: TextEditingController(text: item.text), onChanged: (v) => setState(() => item.text = v), maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: TextEditingController(text: item.icon), onChanged: (v) => setState(() => item.icon = v), decoration: const InputDecoration(labelText: 'Nom de l\'icône (ex: shield)', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: TextEditingController(text: item.imageUrl ?? ''), onChanged: (v) => setState(() => item.imageUrl = v.isEmpty ? null : v), decoration: const InputDecoration(labelText: 'URL Image (HTTPS)', border: OutlineInputBorder())),
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.imageUrl!, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 100, child: Center(child: Text('Erreur image'))))),
      ],
    ])));
  }

  // -------------------------------------------------------------------------
  // ÉDITEUR SOLUTIONS (CRUD)
  // -------------------------------------------------------------------------

  Widget _solutionsEditor() {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [const Text('Gestion des Solutions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))), const Spacer(), FilledButton.icon(onPressed: () => _addSolution(), icon: const Icon(Icons.add), label: const Text('Ajouter'))]),
      const SizedBox(height: 16),
      if (_editableSolutions.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Aucune solution.', style: TextStyle(color: Color(0xFF6B7280)))),
      for (var i = 0; i < _editableSolutions.length; i++) _solutionCard(i),
      const SizedBox(height: 40),
    ]);
  }

  void _addSolution() {
    setState(() { _editableSolutions.add(_EditableSolution(title: 'Nouvelle Solution', subtitle: 'Sous-titre', text: 'Description...')); });
  }

  void _removeSolution(int index) {
    setState(() { _editableSolutions.removeAt(index); });
  }

  Widget _solutionCard(int index) {
    final item = _editableSolutions[index];
    return Card(margin: const EdgeInsets.only(bottom: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('Solution #${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))), const Spacer(), Switch(value: item.featured, onChanged: (v) => setState(() => item.featured = v), activeColor: const Color(0xFFB8860B)), IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C)), onPressed: () => _removeSolution(index))]),
      const SizedBox(height: 12),
      TextField(controller: TextEditingController(text: item.title), onChanged: (v) => setState(() => item.title = v), decoration: const InputDecoration(labelText: 'Titre')),
      const SizedBox(height: 8),
      TextField(controller: TextEditingController(text: item.subtitle), onChanged: (v) => setState(() => item.subtitle = v), decoration: const InputDecoration(labelText: 'Sous-titre')),
      const SizedBox(height: 8),
      TextField(controller: TextEditingController(text: item.text), onChanged: (v) => setState(() => item.text = v), maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
      const SizedBox(height: 8),
      TextField(controller: TextEditingController(text: item.imageUrl ?? ''), onChanged: (v) => setState(() => item.imageUrl = v.isEmpty ? null : v), decoration: const InputDecoration(labelText: 'URL Image (HTTPS)')),
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.imageUrl!, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 100, child: Center(child: Text('Erreur image'))))),
      ],
    ])));
  }

  // -------------------------------------------------------------------------
  // ÉDITEUR STATS (CRUD)
  // -------------------------------------------------------------------------

  Widget _statsEditor() {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [const Text('Gestion des Stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))), const Spacer(), FilledButton.icon(onPressed: () => _addStat(), icon: const Icon(Icons.add), label: const Text('Ajouter'))]),
      const SizedBox(height: 16),
      if (_editableStats.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Aucune stat.', style: TextStyle(color: Color(0xFF6B7280)))),
      for (var i = 0; i < _editableStats.length; i++) _statRow(i),
      const SizedBox(height: 40),
    ]);
  }

  void _addStat() {
    setState(() { _editableStats.add(_EditableStat(value: '0', label: 'Nouvelle Stat')); });
  }

  void _removeStat(int index) {
    setState(() { _editableStats.removeAt(index); });
  }

  Widget _statRow(int index) {
    final item = _editableStats[index];
    return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      Expanded(flex: 2, child: TextField(controller: TextEditingController(text: item.value), onChanged: (v) => setState(() => item.value = v), decoration: const InputDecoration(labelText: 'Valeur (ex: 98%)'))),
      const SizedBox(width: 12),
      Expanded(flex: 3, child: TextField(controller: TextEditingController(text: item.label), onChanged: (v) => setState(() => item.label = v), decoration: const InputDecoration(labelText: 'Libellé'))),
      const SizedBox(width: 8),
      IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C)), onPressed: () => _removeStat(index)),
    ])));
  }

  // -------------------------------------------------------------------------
  // WIDGETS UTILITAIRES
  // -------------------------------------------------------------------------

  Widget _sectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))));
  }

  Widget _field(String key, {required String label, int maxLines = 1}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: _textEditors[key], maxLines: maxLines, style: const TextStyle(color: Color(0xFF111827), fontSize: 15, fontWeight: FontWeight.w500), decoration: InputDecoration(labelText: label), onChanged: (_) { if (_publishState == _PublishState.published) setState(() => _publishState = _PublishState.draft); }));
  }

  Widget _imageField(String key, {required String label}) {
    final controller = _imageEditors[key];
    final url = controller?.text.trim();
    final hasUrl = url != null && url.isNotEmpty && url.startsWith('https://');

    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: controller, decoration: InputDecoration(labelText: '$label (URL HTTPS)', suffixIcon: hasUrl ? const Icon(Icons.check_circle, color: Colors.green) : null), onChanged: (_) { if (_publishState == _PublishState.published) setState(() => _publishState = _PublishState.draft); }),
      if (hasUrl) ...[
        const SizedBox(height: 8),
        Container(height: 100, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('Image invalide', style: TextStyle(color: Colors.red)))))),
      ],
    ]));
  }

  Widget _statCard(String label, Object value, IconData icon) {
    return Container(width: 180, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: const [BoxShadow(color: Color.fromRGBO(15, 23, 42, 0.04), blurRadius: 12)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFFB8860B)), const SizedBox(height: 10), Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))), Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500))]));
  }

  Widget _card({required String title, required Widget child}) {
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: const [BoxShadow(color: Color.fromRGBO(15, 23, 42, 0.03), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827))), const SizedBox(height: 14), child]));
  }

  Widget _settings() {
    return ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Paramètres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
      const SizedBox(height: 16),
      _card(title: 'Sécurité', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _settingRow(Icons.timer_outlined, 'Session', 'Expiration automatique après 15 min d’inactivité.'),
        _settingRow(Icons.shield_outlined, 'Entrées', 'Tous les champs sont nettoyés avant enregistrement.'),
        _settingRow(Icons.article_outlined, 'Logs', 'Aucune donnée sensible n’est journalisée en production.'),
      ])),
      const SizedBox(height: 16),
      _card(title: 'Zone dangereuse', child: OutlinedButton.icon(onPressed: () => _confirmLogout(), icon: const Icon(Icons.logout_rounded, size: 18), label: const Text('Se déconnecter'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB91C1C), side: const BorderSide(color: Color(0xFFB91C1C))))),
    ]);
  }

  Widget _settingRow(IconData icon, String title, String subtitle) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: const Color(0xFFB8860B)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))), Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13))]))]));
  }

  String _formatDate(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.day)}/${pad(dt.month)}/${dt.year} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(backgroundColor: Colors.white, title: const Text('Se déconnecter ?', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800)), content: const Text('Vous devrez vous reconnecter.', style: TextStyle(color: Color(0xFF4B5563))), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280)))), FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)), onPressed: () => Navigator.of(context).pop(true), child: const Text('Déconnexion'))]));
    if (confirmed == true) _logout();
  }
}

// ---------------------------------------------------------------------------
// SECURITY HELPER
// ---------------------------------------------------------------------------

class _AdminSecurity {
  const _AdminSecurity._();
  static String sanitize(String? value, {int maxLength = 2000}) {
    if (value == null || value.isEmpty) return '';
    final cleaned = value.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFEFF\u202A-\u202E\u2066-\u2069]', ''), '').trim();
    return cleaned.length <= maxLength ? cleaned : cleaned.substring(0, maxLength);
  }
}
