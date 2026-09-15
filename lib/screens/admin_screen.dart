import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/content.dart';
import '../services/content_service.dart';

// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------

enum _AdminTab {
  dashboard('Dashboard', Icons.space_dashboard_rounded),
  content('Contenu', Icons.edit_note_rounded),
  collections('Collections', Icons.layers_rounded),
  activity('Activité', Icons.history_rounded),
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
// SCREEN
// ---------------------------------------------------------------------------

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  final ContentService _contentService = ContentService();

  // Auth
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authFormKey = GlobalKey<FormState>();
  bool _authenticated = false;
  bool _authLoading = false;
  bool _obscurePassword = true;
  String? _authError;

  // Session
  Timer? _sessionTimer;
  static const Duration _sessionTimeout = Duration(minutes: 15);

  // Nav + data
  _AdminTab _tab = _AdminTab.dashboard;
  SiteContent? _content;
  bool _loading = true;
  Object? _error;
  _PublishState _publishState = _PublishState.draft;
  final List<_ActivityEntry> _activity = [];

  // Content editors
  final Map<String, TextEditingController> _editors = {};

  static const List<String> _scalarKeys = [
    'heroTitle',
    'heroHighlight',
    'heroParagraph',
    'ctaPrimary',
    'ctaSecondary',
    'impactQuote',
    'visionText',
    'footerLegal',
    'consentText',
  ];

  @override
  void initState() {
    super.initState();
    for (final key in _scalarKeys) {
      _editors[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    for (final c in _editors.values) {
      c.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // SECURITY / LOGGING
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

  // -------------------------------------------------------------------------
  // AUTH
  // -------------------------------------------------------------------------

  Future<void> _login() async {
    if (!(_authFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _authLoading = true;
      _authError = null;
    });

    final email = _AdminSecurity.sanitize(_emailController.text, maxLength: 120);
    final password = _passwordController.text;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));

      final ok = email.isNotEmpty && password.length >= 8;

      if (!mounted) return;

      if (ok) {
        setState(() {
          _authenticated = true;
        });
        _startSession();
        _track('Connexion réussie');
        _loadContent();
      } else {
        setState(() {
          _authLoading = false;
          _authError = 'Identifiants invalides ou mot de passe trop court.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authLoading = false;
        _authError = 'Erreur de connexion. Réessayez.';
      });
    } finally {
      _passwordController.clear();
    }
  }

  void _logout({String? reason}) {
    setState(() {
      _authenticated = false;
      _tab = _AdminTab.dashboard;
      _authError = null;
      _emailController.clear();
      _passwordController.clear();
    });
    _sessionTimer?.cancel();

    if (reason != null && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(reason)),
        );
    }
  }

  // -------------------------------------------------------------------------
  // CONTENT
  // -------------------------------------------------------------------------

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final content = await _contentService.loadPublished();
      if (!mounted) return;

      final c = content;

      _editors['heroTitle']?.text = c.heroTitle;
      _editors['heroHighlight']?.text = c.heroHighlight;
      _editors['heroParagraph']?.text = c.heroParagraph;
      _editors['ctaPrimary']?.text = c.ctaPrimary;
      _editors['ctaSecondary']?.text = c.ctaSecondary;
      _editors['impactQuote']?.text = c.impactQuote;
      _editors['visionText']?.text = c.visionText;
      _editors['footerLegal']?.text = c.footerLegal;
      _editors['consentText']?.text = c.consentText;

      setState(() {
        _content = c;
        _loading = false;
        _publishState = _PublishState.published;
      });

      _track('Contenu chargé');
    } catch (e) {
      _safeLog('load_failed', {'type': e.runtimeType});
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _save({required bool publish}) async {
    _startSession();

    setState(() => _publishState = _PublishState.publishing);

    final payload = <String, String>{};
    for (final key in _scalarKeys) {
      payload[key] = _AdminSecurity.sanitize(_editors[key]?.text ?? '');
    }

    payload['featuresCount'] = '${_content?.features.length ?? 0}';
    payload['solutionsCount'] = '${_content?.solutions.length ?? 0}';
    payload['statsCount'] = '${_content?.stats.length ?? 0}';

    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      setState(() {
        _publishState = publish ? _PublishState.published : _PublishState.draft;
      });

      _track(publish ? 'Contenu publié' : 'Brouillon enregistré');

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(publish ? 'Contenu publié avec succès.' : 'Brouillon enregistré.'),
            backgroundColor: const Color(0xFF111827),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishState = _PublishState.error);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Échec de l’enregistrement.'),
            backgroundColor: Color(0xFFB91C1C),
          ),
        );
    }
  }

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _authenticated ? _buildShell() : _buildLogin(),
      ),
    );
  }

  // ----------------------------- LOGIN -------------------------------------

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _authFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_rounded, size: 44, color: Color(0xFFB8860B)),
                const SizedBox(height: 16),
                const Text(
                  'Espace administrateur',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connectez-vous pour gérer le contenu du site.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Email requis';
                    if (!value.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 8) return '8 caractères minimum';
                    return null;
                  },
                ),
                if (_authError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _authError!,
                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _authLoading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB8860B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _authLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(_authLoading ? 'Connexion…' : 'Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------- SHELL -------------------------------------

  Widget _buildShell() {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Row(
      children: [
        if (isWide) _sidebar(),
        Expanded(
          child: Column(
            children: [
              _topbar(isWide: isWide),
              const Divider(height: 1),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: _buildBody(),
                  ),
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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color: Color(0xFFB8860B)),
              SizedBox(width: 8),
              Text(
                'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final tab in _AdminTab.values) _navItem(tab),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: () => _logout(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Déconnexion'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
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
        color: selected ? const Color(0xFFB8860B).withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(tab.icon, color: selected ? const Color(0xFFB8860B) : const Color(0xFF6B7280)),
          title: Text(
            tab.label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? const Color(0xFF111827) : const Color(0xFF374151),
            ),
          ),
          onTap: () {
            _startSession();
            setState(() => _tab = tab);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _topbar({required bool isWide}) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _openDrawer(),
            ),
          Text(
            _tab.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const Spacer(),
          if (_tab == _AdminTab.content) ...[
            OutlinedButton.icon(
              onPressed: _publishState == _PublishState.publishing
                  ? null
                  : () => _save(publish: false),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Brouillon'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _publishState == _PublishState.publishing
                  ? null
                  : () => _save(publish: true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                foregroundColor: Colors.white,
              ),
              icon: _publishState == _PublishState.publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final tab in _AdminTab.values)
                ListTile(
                  leading: Icon(tab.icon),
                  title: Text(tab.label),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _tab = tab);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFB91C1C)),
                title: const Text('Déconnexion',
                    style: TextStyle(color: Color(0xFFB91C1C))),
                onTap: () {
                  Navigator.of(context).pop();
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------- BODY --------------------------------------

  Widget _buildBody() {
    switch (_tab) {
      case _AdminTab.dashboard:
        return _dashboard();
      case _AdminTab.content:
        return _contentEditor();
      case _AdminTab.collections:
        return _collections();
      case _AdminTab.activity:
        return _activityLog();
      case _AdminTab.settings:
        return _settings();
    }
  }

  Widget _dashboard() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final c = _content ?? const SiteContent();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Vue d’ensemble',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard('Features', c.features.length, Icons.extension_rounded),
            _statCard('Solutions', c.solutions.length, Icons.lightbulb_outline_rounded),
            _statCard('Stats', c.stats.length, Icons.bar_chart_rounded),
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
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Éditer le contenu'),
              ),
              OutlinedButton.icon(
                onPressed: _loadContent,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Recharger'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contentEditor() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Erreur de chargement du contenu.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadContent,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Hero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _field('heroTitle', label: 'Titre'),
        _field('heroHighlight', label: 'Partie mise en avant (or)'),
        _field('heroParagraph', label: 'Paragraphe', maxLines: 4),
        const SizedBox(height: 24),
        const Text('Call-to-action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _field('ctaPrimary', label: 'CTA principal')),
            const SizedBox(width: 12),
            Expanded(child: _field('ctaSecondary', label: 'CTA secondaire')),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Impact & Vision', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _field('impactQuote', label: 'Citation d’impact', maxLines: 3),
        const SizedBox(height: 12),
        _field('visionText', label: 'Texte vision', maxLines: 4),
        const SizedBox(height: 24),
        const Text('Légal & Consentement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _field('footerLegal', label: 'Mentions légales (footer)', maxLines: 4),
        const SizedBox(height: 12),
        _field('consentText', label: 'Texte de consentement', maxLines: 3),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _collections() {
    final c = _content ?? const SiteContent();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Collections',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gérez ici les listes (features, solutions, stats). À connecter à ton backend.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        _collectionList('Features', c.features.map((f) => f.title).toList()),
        _collectionList('Solutions', c.solutions.map((s) => s.title).toList()),
        _collectionList('Stats', c.stats.map((s) => '${s.value} · ${s.label}').toList()),
      ],
    );
  }

  Widget _activityLog() {
    if (_activity.isEmpty) {
      return const Center(child: Text('Aucune activité pour le moment.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _activity.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _activity[index];
        return ListTile(
          leading: const Icon(Icons.history_rounded, color: Color(0xFFB8860B)),
          title: Text(entry.label),
          subtitle: Text(_formatDate(entry.at)),
        );
      },
    );
  }

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Paramètres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _card(
          title: 'Sécurité',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _settingRow(Icons.timer_outlined, 'Session', 'Expiration automatique après 15 min d’inactivité.'),
              _settingRow(Icons.shield_outlined, 'Entrées', 'Tous les champs sont nettoyés avant enregistrement.'),
              _settingRow(Icons.article_outlined, 'Logs', 'Aucune donnée sensible n’est journalisée en production.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Zone dangereuse',
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              side: const BorderSide(color: Color(0xFFB91C1C)),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------- UI BITS -----------------------------------

  Widget _field(
    String key, {
    required String label,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _editors[key],
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) {
          if (_publishState == _PublishState.published) {
            setState(() => _publishState = _PublishState.draft);
          }
        },
      ),
    );
  }

  Widget _statCard(String label, Object value, IconData icon) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(15, 23, 42, 0.04), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB8860B)),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _collectionList(String title, List<String> items) {
    return _card(
      title: '$title (${items.length})',
      child: items.isEmpty
          ? const Text('Aucun élément.', style: TextStyle(color: Color(0xFF6B7280)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Color(0xFFB8860B)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _AdminSecurity.sanitize(item, maxLength: 120),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _settingRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFB8860B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.day)}/${pad(dt.month)}/${dt.year} '
        '${pad(dt.hour)}:${pad(dt.minute)}';
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez vous reconnecter pour accéder à l’admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) _logout();
  }
}

// ---------------------------------------------------------------------------
// SECURITY
// ---------------------------------------------------------------------------

class _AdminSecurity {
  const _AdminSecurity._();

  static String sanitize(String? value, {int maxLength = 2000}) {
    if (value == null || value.isEmpty) return '';

    final cleaned = value
        .replaceAll(
          RegExp(
            r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFEFF\u202A-\u202E\u2066-\u2069]',
          ),
          '',
        )
        .trim();

    if (cleaned.length <= maxLength) return cleaned;
    return cleaned.substring(0, maxLength);
  }
}
