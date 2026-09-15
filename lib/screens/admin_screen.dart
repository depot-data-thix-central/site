import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/content.dart';
import '../services/content_service.dart';

// ═══════════════════════════════════════════════════════════════
// Palette alignée homepage (blanc + slate, zéro or)
// ═══════════════════════════════════════════════════════════════
class _A {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const danger = Color(0xFFB91C1C);
  static const success = Color(0xFF16A34A);
}

// ═══════════════════════════════════════════════════════════════
// Modèles éditables
// ═══════════════════════════════════════════════════════════════
class _EditableFeature {
  String title, text, icon;
  String? imageUrl;
  _EditableFeature({required this.title, required this.text, required this.icon, this.imageUrl});
  factory _EditableFeature.fromModel(Feature f) =>
      _EditableFeature(title: f.title, text: f.text, icon: f.icon, imageUrl: f.imageUrl);
  Feature toModel() => Feature(title: title, text: text, icon: icon, imageUrl: imageUrl);
}

class _EditableSolution {
  String title, subtitle, text;
  bool featured;
  String? imageUrl;
  _EditableSolution({
    required this.title,
    required this.subtitle,
    required this.text,
    this.featured = false,
    this.imageUrl,
  });
  factory _EditableSolution.fromModel(Solution s) => _EditableSolution(
        title: s.title,
        subtitle: s.subtitle,
        text: s.text,
        featured: s.featured,
        imageUrl: s.imageUrl,
      );
  Solution toModel() =>
      Solution(title: title, subtitle: subtitle, text: text, featured: featured, imageUrl: imageUrl);
}

class _EditableStat {
  String value, label;
  _EditableStat({required this.value, required this.label});
  factory _EditableStat.fromModel(Stat s) => _EditableStat(value: s.value, label: s.label);
  Stat toModel() => Stat(value: value, label: label);
}

enum _AdminTab {
  dashboard('Dashboard', Icons.space_dashboard_rounded),
  content('Contenu', Icons.edit_note_rounded),
  features('Features', Icons.extension_rounded),
  solutions('Solutions', Icons.lightbulb_outline_rounded),
  stats('Stats', Icons.bar_chart_rounded),
  settings('Paramètres', Icons.settings_rounded);

  const _AdminTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum _PublishState { draft, publishing, published, error }

// ═══════════════════════════════════════════════════════════════
// ADMIN SCREEN
// ═══════════════════════════════════════════════════════════════
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _contentService = ContentService();

  // Auth
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authFormKey = GlobalKey<FormState>();
  bool _authenticated = false;
  bool _authLoading = false;
  bool _obscure = true;
  String? _authError;

  // State
  _AdminTab _tab = _AdminTab.dashboard;
  SiteContent? _original;
  bool _loading = true;
  Object? _error;
  _PublishState _publishState = _PublishState.draft;
  
  // Variables pour l'upload d'images
  final Set<String> _uploading = {};

  // Editors
  final Map<String, TextEditingController> _text = {};
  final Map<String, TextEditingController> _images = {};
  final List<_EditableFeature> _features = [];
  final List<_EditableSolution> _solutions = [];
  final List<_EditableStat> _stats = [];

  static const _scalarKeys = [
    'seoTitle', 'seoDescription', 'seoKeywords', 'seoCanonicalUrl',
    'heroTitle', 'heroHighlight', 'heroParagraph', 'ctaPrimary', 'ctaSecondary',
    'managerName', 'managerMessage',
    'impactQuote', 'visionText', 'consentText', 'footerLegal',
  ];
  static const _imageKeys = [
    'seoOgImage', 'heroImageUrl', 'visionImageUrl', 'managerPhotoUrl'
  ];

  @override
  void initState() {
    super.initState();
    for (final k in _scalarKeys) {
      _text[k] = TextEditingController();
    }
    for (final k in _imageKeys) {
      _images[k] = TextEditingController();
    }
    
    // Vérifier s'il y a déjà une session active au démarrage
    _checkExistingSession();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    for (final c in _text.values) {
      c.dispose();
    }
    for (final c in _images.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Auth ─────────────────────────────────────────────────────
  Future<void> _checkExistingSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .maybeSingle();
            
        if (profile != null && profile['role'] != 'admin') {
          await Supabase.instance.client.auth.signOut();
          return;
        }

        if (mounted) {
          setState(() => _authenticated = true);
          await _loadContent();
        }
      } catch (_) {
        // En cas d'erreur de vérification, on reste sur l'écran de login
      }
    }
  }

  Future<void> _login() async {
    if (!(_authFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _authLoading = true;
      _authError = null;
    });

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (res.user == null) throw Exception('no user');

      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', res.user!.id)
            .maybeSingle();
        if (profile != null && profile['role'] != 'admin') {
          await Supabase.instance.client.auth.signOut();
          throw Exception('not admin');
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() => _authenticated = true);
      await _loadContent();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authLoading = false;
        _authError = 'Identifiants invalides ou accès refusé.';
      });
    } finally {
      _passwordCtrl.clear();
      if (mounted) setState(() => _authLoading = false);
    }
  }

  Future<void> _logout({String? reason}) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _authenticated = false;
      _tab = _AdminTab.dashboard;
      _authError = null;
    });
    if (reason != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
    }
  }

  // ── Upload ───────────────────────────────────────────────────
    Future<String?> _uploadToSupabase(String folder) async {
    try {
      final picker = ImagePicker();
      
      // ❌ L'ERREUR VENAIT D'ICI : On retire `imageQuality: 80`
      // Sur Flutter Web mobile, la tentative de compression révoque le Blob.
      final xfile = await picker.pickImage(source: ImageSource.gallery);
      
      if (xfile == null) return null;

      // Lecture des bytes bruts
      final bytes = await xfile.readAsBytes();
      
      // Extraction de l'extension (avec fallback sur png si introuvable sur le web)
      final ext = xfile.name.split('.').last.toLowerCase();
      final validExt = ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext) ? ext : 'png';
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$validExt';
      final path = '$folder/$fileName';

      // Upload binaire vers Supabase
      await Supabase.instance.client.storage.from('images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$validExt'),
      );

      return Supabase.instance.client.storage.from('images').getPublicUrl(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'upload : $e'), backgroundColor: _A.danger),
        );
      }
      return null;
    }
  }


  // ── Data ─────────────────────────────────────────────────────
  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await _contentService.loadPublished();
      if (!mounted) return;
      _original = content;

      _text['seoTitle']?.text = content.seoTitle;
      _text['seoDescription']?.text = content.seoDescription;
      _text['seoKeywords']?.text = content.seoKeywords;
      _images['seoOgImage']?.text = content.seoOgImage;
      _text['seoCanonicalUrl']?.text = content.seoCanonicalUrl;
      _text['heroTitle']?.text = content.heroTitle;
      _text['heroHighlight']?.text = content.heroHighlight;
      _text['heroParagraph']?.text = content.heroParagraph;
      _text['ctaPrimary']?.text = content.ctaPrimary;
      _text['ctaSecondary']?.text = content.ctaSecondary;
      _images['heroImageUrl']?.text = content.heroImageUrl ?? '';
      
      // Les lignes ci-dessous sont commentées pour éviter les erreurs 
      // si votre modèle SiteContent n'a pas encore ces propriétés.
      // _text['managerName']?.text = content.managerName ?? '';
      // _text['managerMessage']?.text = content.managerMessage ?? '';
      // _images['managerPhotoUrl']?.text = content.managerPhotoUrl ?? '';

      _text['impactQuote']?.text = content.impactQuote;
      _text['visionText']?.text = content.visionText;
      _images['visionImageUrl']?.text = content.visionImageUrl ?? '';
      _text['consentText']?.text = content.consentText;
      _text['footerLegal']?.text = content.footerLegal;

      _features
        ..clear()
        ..addAll(content.features.map(_EditableFeature.fromModel));
      _solutions
        ..clear()
        ..addAll(content.solutions.map(_EditableSolution.fromModel));
      _stats
        ..clear()
        ..addAll(content.stats.map(_EditableStat.fromModel));

      setState(() {
        _loading = false;
        _publishState = _PublishState.published;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _save({required bool publish}) async {
    setState(() => _publishState = _PublishState.publishing);

    try {
      final newContent = SiteContent(
        seoTitle: _text['seoTitle']?.text ?? '',
        seoDescription: _text['seoDescription']?.text ?? '',
        seoKeywords: _text['seoKeywords']?.text ?? '',
        seoOgImage: _images['seoOgImage']?.text ?? '',
        seoCanonicalUrl: _text['seoCanonicalUrl']?.text ?? '',
        heroTitle: _text['heroTitle']?.text ?? '',
        heroHighlight: _text['heroHighlight']?.text ?? '',
        heroParagraph: _text['heroParagraph']?.text ?? '',
        ctaPrimary: _text['ctaPrimary']?.text ?? '',
        ctaSecondary: _text['ctaSecondary']?.text ?? '',
        heroImageUrl: _httpsOrNull(_images['heroImageUrl']?.text),
        
        // managerName: _text['managerName']?.text ?? '',
        // managerMessage: _text['managerMessage']?.text ?? '',
        // managerPhotoUrl: _httpsOrNull(_images['managerPhotoUrl']?.text),

        features: _features.map((e) => e.toModel()).toList(),
        solutions: _solutions.map((e) => e.toModel()).toList(),
        stats: _stats.map((e) => e.toModel()).toList(),
        impactQuote: _text['impactQuote']?.text ?? '',
        visionText: _text['visionText']?.text ?? '',
        visionImageUrl: _httpsOrNull(_images['visionImageUrl']?.text),
        consentText: _text['consentText']?.text ?? '',
        footerLegal: _text['footerLegal']?.text ?? '',
        version: (_original?.version ?? 0) + 1,
        lastUpdated: DateTime.now(),
      );

      final client = Supabase.instance.client;
      await client.from('content_published').upsert({
        'id': 1,
        'data': newContent.toJson(),
        'published_at': DateTime.now().toIso8601String(),
      });

      await client.from('content_draft').upsert({
        'id': 1,
        'data': newContent.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        _original = newContent;
        _publishState = publish ? _PublishState.published : _PublishState.draft;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish ? 'Contenu publié.' : 'Brouillon enregistré.'),
          backgroundColor: _A.ink,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishState = _PublishState.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de l’enregistrement.'),
          backgroundColor: _A.danger,
        ),
      );
    }
  }

  String? _httpsOrNull(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    return s.startsWith('https://') ? s : null;
  }

  void _markDirty() {
    if (_publishState == _PublishState.published) {
      setState(() => _publishState = _PublishState.draft);
    }
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: _A.bg,
        colorScheme: const ColorScheme.light(
          primary: _A.ink,
          surface: _A.surface,
          onSurface: _A.ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _A.surface,
          labelStyle: const TextStyle(color: _A.muted, fontSize: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _A.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _A.ink, width: 1.5),
          ),
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: _A.surface,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: _A.bg,
          body: _authenticated ? _shell() : _buildLogin(),
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
              color: _A.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _A.border),
              boxShadow: const [
                BoxShadow(color: Color.fromRGBO(15, 23, 42, 0.06), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: Form(
              key: _authFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_rounded, size: 40, color: _A.ink),
                  const SizedBox(height: 14),
                  const Text(
                    'Espace administrateur',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _A.ink),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gérez le contenu du site public.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _A.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: _A.muted),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: _A.muted),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: _A.muted),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8) ? '8 caractères min.' : null,
                  ),
                  if (_authError != null) ...[
                    const SizedBox(height: 14),
                    Text(_authError!, style: const TextStyle(color: _A.danger, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _authLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: _A.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _authLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(_authLoading ? 'Connexion…' : 'Se connecter',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shell() {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Row(
      children: [
        if (wide) _sidebar(),
        Expanded(
          child: Column(
            children: [
              _topbar(wide: wide),
              const Divider(height: 1, color: _A.border),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(key: ValueKey(_tab), child: _body()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: _A.surface,
        border: Border(right: BorderSide(color: _A.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: _A.ink, size: 26),
              SizedBox(width: 8),
              Text('Admin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _A.ink)),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _A.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [for (final t in _AdminTab.values) _navItem(t)],
            ),
          ),
          const Divider(height: 1, color: _A.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: () => _logout(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Déconnexion'),
              style: TextButton.styleFrom(foregroundColor: _A.danger, alignment: Alignment.centerLeft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(_AdminTab tab) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? _A.ink.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(tab.icon, color: selected ? _A.ink : _A.muted),
          title: Text(
            tab.label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _A.ink : _A.muted,
            ),
          ),
          onTap: () => setState(() => _tab = tab),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _topbar({required bool wide}) {
    return Container(
      height: 64,
      color: _A.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!wide)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: _A.ink),
              onPressed: _openDrawer,
            ),
          Text(
            _tab.label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _A.ink),
          ),
          const Spacer(),
          if (_tab != _AdminTab.dashboard && _tab != _AdminTab.settings) ...[
            OutlinedButton.icon(
              onPressed: _publishState == _PublishState.publishing ? null : () => _save(publish: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _A.ink,
                side: const BorderSide(color: _A.border),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Brouillon'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _publishState == _PublishState.publishing ? null : () => _save(publish: true),
              style: FilledButton.styleFrom(backgroundColor: _A.ink, foregroundColor: Colors.white),
              icon: _publishState == _PublishState.publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.publish_rounded, size: 18),
              label: const Text('Publier'),
            ),
          ],
        ],
      ),
    );
  }

  void _openDrawer() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _A.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in _AdminTab.values)
              ListTile(
                leading: Icon(t.icon, color: _A.ink),
                title: Text(t.label, style: const TextStyle(fontWeight: FontWeight.w600, color: _A.ink)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _tab = t);
                },
              ),
            const Divider(height: 1, color: _A.border),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: _A.danger),
              title: const Text('Déconnexion', style: TextStyle(color: _A.danger, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _tab != _AdminTab.dashboard) {
      return const Center(child: CircularProgressIndicator(color: _A.ink));
    }
    if (_error != null && _tab != _AdminTab.dashboard) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _A.danger, size: 48),
            const SizedBox(height: 12),
            Text('Erreur de chargement : $_error', style: const TextStyle(color: _A.danger)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadContent,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    switch (_tab) {
      case _AdminTab.dashboard:
        return _dashboard();
      case _AdminTab.content:
        return _contentEditor();
      case _AdminTab.features:
        return _featuresEditor();
      case _AdminTab.solutions:
        return _solutionsEditor();
      case _AdminTab.stats:
        return _statsEditor();
      case _AdminTab.settings:
        return _settings();
    }
  }

  Widget _dashboard() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Vue d’ensemble',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _A.ink)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard('Features', '${_features.length}', Icons.extension_rounded),
            _statCard('Solutions', '${_solutions.length}', Icons.lightbulb_outline_rounded),
            _statCard('Stats', '${_stats.length}', Icons.bar_chart_rounded),
            _statCard(
              'Statut',
              _publishState == _PublishState.published ? 'Publié' : 'Brouillon',
              Icons.cloud_done_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _card(
          title: 'Actions rapides',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => setState(() => _tab = _AdminTab.content),
                style: FilledButton.styleFrom(
                  backgroundColor: _A.ink.withValues(alpha: 0.08),
                  foregroundColor: _A.ink,
                ),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Éditer le contenu', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              OutlinedButton.icon(
                onPressed: _loadContent,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _A.ink,
                  side: const BorderSide(color: _A.border),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Recharger'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Éditeur de contenu principal ───────────────────────────────
  Widget _contentEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Référencement (SEO)'),
        _field('seoTitle', 'Titre SEO'),
        _field('seoDescription', 'Description SEO', maxLines: 2),
        _field('seoKeywords', 'Mots-clés'),
        _imageUploadField('seoOgImage', 'Image Open Graph (SEO)', 'seo'),
        const SizedBox(height: 28),
        
        _sectionTitle('Hero'),
        _field('heroTitle', 'Titre principal'),
        _field('heroHighlight', 'Mise en avant'),
        _field('heroParagraph', 'Paragraphe', maxLines: 4),
        _imageUploadField('heroImageUrl', 'Image principale (Hero)', 'hero'),
        _field('ctaPrimary', 'Bouton principal'),
        _field('ctaSecondary', 'Bouton secondaire'),
        const SizedBox(height: 28),

        // ── SECTION MANAGER ──
        _sectionTitle('Mot du Manager'),
        _field('managerName', 'Nom du manager'),
        _field('managerMessage', 'Message du manager', maxLines: 5),
        _imageUploadField('managerPhotoUrl', 'Photo du manager', 'manager'),
        const SizedBox(height: 28),

        _sectionTitle('Impact & Vision'),
        _field('impactQuote', 'Citation d’impact', maxLines: 3),
        _field('visionText', 'Texte vision', maxLines: 5),
        _imageUploadField('visionImageUrl', 'Image de la section Vision', 'vision'),
        const SizedBox(height: 28),

        _sectionTitle('Pied de page & Légal'),
        _field('consentText', 'Bannière consentement', maxLines: 3),
        _field('footerLegal', 'Mentions légales', maxLines: 3),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _featuresEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const Text('Features', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _A.ink)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => setState(() {
                _features.add(_EditableFeature(title: 'Nouvelle feature', text: '', icon: 'star'));
                _markDirty();
              }),
              style: FilledButton.styleFrom(backgroundColor: _A.ink),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_features.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Aucune feature.', style: TextStyle(color: _A.muted))),
          ),
        for (var i = 0; i < _features.length; i++) _featureCard(i),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _featureCard(int i) {
    final item = _features[i];
    return _editorCard(
      title: 'Feature #${i + 1}',
      onDelete: () => setState(() {
        _features.removeAt(i);
        _markDirty();
      }),
      children: [
        _inlineField('Titre', item.title, (v) {
          item.title = v;
          _markDirty();
        }),
        _inlineField('Description', item.text, (v) {
          item.text = v;
          _markDirty();
        }, maxLines: 3),
        _inlineField('Icône', item.icon, (v) {
          item.icon = v;
          _markDirty();
        }),
        _collectionImageUploadField(
          'Image de la feature',
          item.imageUrl,
          (v) => setState(() {
            item.imageUrl = v.isEmpty ? null : v;
            _markDirty();
          }),
          'feature_$i',
          'features',
        ),
      ],
    );
  }

  Widget _solutionsEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const Text('Solutions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _A.ink)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => setState(() {
                _solutions.add(
                  _EditableSolution(title: 'Nouvelle solution', subtitle: '', text: ''),
                );
                _markDirty();
              }),
              style: FilledButton.styleFrom(backgroundColor: _A.ink),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_solutions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Aucune solution.', style: TextStyle(color: _A.muted))),
          ),
        for (var i = 0; i < _solutions.length; i++) _solutionCard(i),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _solutionCard(int i) {
    final item = _solutions[i];
    return _editorCard(
      title: 'Solution #${i + 1}',
      onDelete: () => setState(() {
        _solutions.removeAt(i);
        _markDirty();
      }),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Phare', style: TextStyle(fontSize: 12, color: _A.muted)),
          Switch(
            value: item.featured,
            activeThumbColor: _A.ink,
            onChanged: (v) => setState(() {
              item.featured = v;
              _markDirty();
            }),
          ),
        ],
      ),
      children: [
        _inlineField('Titre', item.title, (v) {
          item.title = v;
          _markDirty();
        }),
        _inlineField('Sous-titre', item.subtitle, (v) {
          item.subtitle = v;
          _markDirty();
        }),
        _inlineField('Description', item.text, (v) {
          item.text = v;
          _markDirty();
        }, maxLines: 3),
        _collectionImageUploadField(
          'Image de la solution',
          item.imageUrl,
          (v) => setState(() {
            item.imageUrl = v.isEmpty ? null : v;
            _markDirty();
          }),
          'solution_$i',
          'solutions',
        ),
      ],
    );
  }

  Widget _statsEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const Text('Stats & Impact', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _A.ink)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => setState(() {
                _stats.add(_EditableStat(value: '0', label: 'Nouvelle stat'));
                _markDirty();
              }),
              style: FilledButton.styleFrom(backgroundColor: _A.ink),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_stats.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Aucune stat.', style: TextStyle(color: _A.muted))),
          ),
        for (var i = 0; i < _stats.length; i++) _statRow(i),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _statRow(int i) {
    final item = _stats[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: _A.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _A.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: item.value,
                onChanged: (v) {
                  item.value = v;
                  _markDirty();
                },
                decoration: const InputDecoration(labelText: 'Valeur'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: item.label,
                onChanged: (v) {
                  item.label = v;
                  _markDirty();
                },
                decoration: const InputDecoration(labelText: 'Libellé'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: _A.danger),
              onPressed: () => setState(() {
                _stats.removeAt(i);
                _markDirty();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Paramètres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _A.ink)),
        const SizedBox(height: 16),
        _card(
          title: 'Sécurité',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Connexion permanente activée', style: TextStyle(color: _A.muted)),
              SizedBox(height: 6),
              Text('• URLs d’images restreintes à HTTPS', style: TextStyle(color: _A.muted)),
              SizedBox(height: 6),
              Text('• Aucune donnée sensible loguée en production', style: TextStyle(color: _A.muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Zone dangereuse',
          child: OutlinedButton.icon(
            onPressed: () => _logout(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _A.danger,
              side: const BorderSide(color: _A.danger),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers UI & Upload Widgets ───────────────────────────────
  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _A.ink)),
      );

  Widget _field(String key, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _text[key],
        maxLines: maxLines,
        style: const TextStyle(color: _A.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => _markDirty(),
      ),
    );
  }

  // Uploader pour les images uniques gérées avec des TextEditingControllers
  Widget _imageUploadField(String key, String label, String folder) {
    final ctrl = _images[key];
    final url = ctrl?.text.trim() ?? '';
    final ok = url.startsWith('https://');
    final isUploading = _uploading.contains(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: _A.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: const TextStyle(color: _A.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    suffixIcon: ok ? const Icon(Icons.check_circle, color: _A.success) : null,
                  ),
                  onChanged: (_) => _markDirty(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: isUploading
                    ? null
                    : () async {
                        setState(() => _uploading.add(key));
                        final newUrl = await _uploadToSupabase(folder);
                        setState(() => _uploading.remove(key));
                        if (newUrl != null) {
                          ctrl?.text = newUrl;
                          _markDirty();
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _A.ink.withValues(alpha: 0.08),
                  foregroundColor: _A.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                icon: isUploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_rounded),
                label: const Text('Uploader'),
              ),
            ],
          ),
          if (ok) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url, // url est ici garanti d'être une String valide
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: _A.border,
                  child: const Center(child: Text('Image indisponible', style: TextStyle(color: _A.danger))),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Uploader pour les collections (Features et Solutions)
  Widget _collectionImageUploadField(String label, String? currentUrl, ValueChanged<String> onChanged, String uploadKey, String folder) {
    // On extrait l'URL en variable non-nullable locale pour éviter l'utilisation de "!"
    final url = currentUrl?.trim() ?? '';
    final ok = url.startsWith('https://');
    final isUploading = _uploading.contains(uploadKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: _A.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey(url),
                  initialValue: url,
                  style: const TextStyle(color: _A.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    suffixIcon: ok ? const Icon(Icons.check_circle, color: _A.success) : null,
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: isUploading
                    ? null
                    : () async {
                        setState(() => _uploading.add(uploadKey));
                        final newUrl = await _uploadToSupabase(folder);
                        setState(() => _uploading.remove(uploadKey));
                        if (newUrl != null) {
                          onChanged(newUrl);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _A.ink.withValues(alpha: 0.08),
                  foregroundColor: _A.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                icon: isUploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_rounded),
                label: const Text('Uploader'),
              ),
            ],
          ),
          if (ok) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url, // Grâce à la variable non-nullable locale 'url', pas besoin de '!'
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: _A.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inlineField(String label, String value, ValueChanged<String> onChanged, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _editorCard({
    required String title,
    required List<Widget> children,
    VoidCallback? onDelete,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: _A.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _A.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: _A.ink)),
                const Spacer(),
                if (trailing != null) trailing,
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: _A.danger),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _A.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _A.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _A.ink),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _A.ink)),
          Text(label, style: const TextStyle(color: _A.muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _A.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _A.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _A.ink)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
