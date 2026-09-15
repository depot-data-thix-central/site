import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/content.dart';
import '../services/content_service.dart';
import '../widgets/consent_banner.dart';
import '../widgets/features_section.dart';
import '../widgets/footer.dart';
import '../widgets/hero_section.dart';
import '../widgets/impact_section.dart';
import '../widgets/navbar.dart';
import '../widgets/solutions_section.dart';
import '../widgets/vision_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ContentService _contentService = ContentService();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showBackToTop = ValueNotifier(false);
  final ValueNotifier<bool> _consentVisible = ValueNotifier(false);

  SiteContent? _content;
  bool _loading = true;
  Object? _error;
  bool? _consent;
  Timer? _consentTimer;

  late final AnimationController _entranceController;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;
  late final List<Animation<double>> _sectionFades;
  late final List<Animation<Offset>> _sectionSlides;

  static const int _sectionCount = 7;
  static const Duration _loadTimeout = Duration(seconds: 12);
  static const int _maxAttempts = 3;
  static const Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();

    // Session-only fallback.
    // In real production, replace this by a secure persisted consent store.
    _consent = _ConsentMemory.choice;

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pageFade = _entranceController.drive(
      CurveTween(
        curve: const Interval(
          0.0,
          0.55,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(_pageFade);

    _sectionFades = List.generate(
      _sectionCount,
      (index) => _entranceController.drive(
        CurveTween(curve: _sectionInterval(index)),
      ),
    );

    _sectionSlides = List.generate(
      _sectionCount,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.07),
        end: Offset.zero,
      ).animate(_sectionFades[index]),
    );

    _scrollController.addListener(_handleScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _entranceController.dispose();
    _consentTimer?.cancel();
    _showBackToTop.dispose();
    _consentVisible.dispose();
    super.dispose();
  }

  Interval _sectionInterval(int index) {
    const double stagger = 0.08;
    const double visibleDuration = 0.45;

    final double start =
        (index * stagger).clamp(0.0, 1.0 - visibleDuration).toDouble();

    final double end =
        (start + visibleDuration).clamp(start, 1.0).toDouble();

    return Interval(
      start,
      end,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _load({bool isRefresh = false}) async {
    if (!mounted) return;

    if (!isRefresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final content = await _fetchWithRetry();
      if (!mounted) return;

      _consentTimer?.cancel();

      final safeContent = content ?? const SiteContent();
      final safeConsentText = _ContentSecurity.text(
        safeContent.consentText,
        maxLength: 600,
      );

      setState(() {
        _content = safeContent;
        _loading = false;
        _error = null;
      });

      if (!isRefresh) {
        _entranceController
          ..reset()
          ..forward();
      } else if (_entranceController.isDismissed) {
        _entranceController.forward();
      }

      if (_consent == null && safeConsentText.isNotEmpty) {
        if (!_consentVisible.value) {
          _consentVisible.value = false;
          _consentTimer = Timer(const Duration(milliseconds: 650), () {
            if (mounted) {
              _consentVisible.value = true;
            }
          });
        }
      } else {
        _consentVisible.value = false;
      }
    } on TimeoutException catch (error) {
      _safeLog('home_load_timeout', error);
      _handleLoadError(error, isRefresh: isRefresh);
    } catch (error, stackTrace) {
      _safeLog('home_load_failed', error, stackTrace);
      _handleLoadError(error, isRefresh: isRefresh);
    }
  }

  Future<SiteContent?> _fetchWithRetry() async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await _contentService.loadPublished().timeout(_loadTimeout);
      } on TimeoutException catch (error) {
        lastError = error;
        _safeLog('home_fetch_timeout', error, null, {'attempt': attempt});
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        _safeLog(
          'home_fetch_attempt_failed',
          error,
          stackTrace,
          {'attempt': attempt},
        );
      }

      if (attempt < _maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));

        if (!mounted) {
          throw StateError('HomeScreen disposed during retry delay');
        }
      }
    }

    Error.throwWithStackTrace(
      lastError ?? StateError('Unknown content loading error'),
      lastStackTrace ?? StackTrace.current,
    );
  }

  void _handleLoadError(Object error, {required bool isRefresh}) {
    if (!mounted) return;

    if (isRefresh && _content != null) {
      _showRefreshError();
      return;
    }

    setState(() {
      _loading = false;
      _error = error;
    });
  }

  void _showRefreshError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF111827),
          content: const Text(
            'Impossible de rafraîchir la page. Réessayez.',
            style: TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _load(isRefresh: true),
          ),
        ),
      );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final shouldShow = _scrollController.offset > 600;
    if (shouldShow != _showBackToTop.value) {
      _showBackToTop.value = shouldShow;
    }
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;

    await HapticFeedback.selectionClick();
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _setConsent(bool accepted) async {
    _consentTimer?.cancel();
    await HapticFeedback.selectionClick();

    _safeLog('consent_choice', null, null, {'accepted': accepted});

    _ConsentMemory.choice = accepted;
    _consentVisible.value = false;

    // Production:
    // persist consent in a secure/auditable store.
    // Example: SharedPreferences/flutter_secure_storage + server-side audit.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    setState(() {
      _consent = accepted;
    });
  }

  void _safeLog(
    String event, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  ]) {
    if (!kDebugMode) return;

    final buffer = StringBuffer('[HomeScreen] $event');

    if (context != null && context.isNotEmpty) {
      buffer.write(
        ' | ${context.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
    }

    // Security:
    // Never log raw remote content, tokens, PII, or full exception messages
    // in release mode.
    if (error != null) {
      buffer.write(' | errorType=${error.runtimeType}');
    }

    debugPrint(buffer.toString());

    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _backgroundColor,
        systemNavigationBarColor: _backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const Key('home_screen'),
        backgroundColor: _backgroundColor,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _HomeLoadingSkeleton();
    }

    if (_error != null) {
      return _HomeErrorView(
        isTimeout: _error is TimeoutException,
        onRetry: () => _load(),
      );
    }

    final content = _content ?? const SiteContent();
    final safeConsentText = _ContentSecurity.text(
      content.consentText,
      maxLength: 600,
    );
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Stack(
      children: [
        _buildContent(content),

        ValueListenableBuilder<bool>(
          valueListenable: _showBackToTop,
          builder: (context, scrollShow, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _consentVisible,
              builder: (context, consentVisible, _) {
                final show =
                    scrollShow && !(_consent == null && consentVisible);

                return Positioned(
                  right: 16,
                  bottom: 20 + bottomPadding,
                  child: ExcludeSemantics(
                    excluding: !show,
                    child: ExcludeFocus(
                      excluding: !show,
                      child: AnimatedOpacity(
                        opacity: show ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: AnimatedScale(
                          scale: show ? 1 : 0.86,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: IgnorePointer(
                            ignoring: !show,
                            child: _BackToTopButton(
                              onPressed: _scrollToTop,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        if (_consent == null && safeConsentText.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomPadding,
            child: ValueListenableBuilder<bool>(
              valueListenable: _consentVisible,
              builder: (context, visible, _) {
                return ExcludeSemantics(
                  excluding: !visible,
                  child: ExcludeFocus(
                    excluding: !visible,
                    child: AnimatedOpacity(
                      opacity: visible ? 1 : 0,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      child: AnimatedPadding(
                        padding: EdgeInsets.only(
                          bottom: visible ? 0.0 : 14.0,
                        ),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        child: ConsentBanner(
                          text: safeConsentText,
                          onAccept: () => _setConsent(true),
                          onRefuse: () => _setConsent(false),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildContent(SiteContent content) {
    return RefreshIndicator(
      color: const Color(0xFF111827),
      backgroundColor: _backgroundColor,
      onRefresh: () => _load(isRefresh: true),
      child: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section(0, Navbar(content: content)),
                _section(1, HeroSection(content: content)),
                _section(2, FeaturesSection(features: content.features)),
                _section(3, SolutionsSection(solutions: content.solutions)),
                _section(
                  4,
                  ImpactSection(
                    stats: content.stats,
                    quote: content.impactQuote,
                  ),
                ),
                _section(5, VisionSection(text: content.visionText)),
                _section(6, Footer(legal: content.footerLegal)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(int index, Widget child) {
    return FadeTransition(
      opacity: _sectionFades[index],
      child: SlideTransition(
        position: _sectionSlides[index],
        child: child,
      ),
    );
  }
}

class _ContentSecurity {
  const _ContentSecurity._();

  static String text(String? value, {int maxLength = 4000}) {
    if (value == null || value.isEmpty) return '';

    // Remove control chars, BOM, and bidirectional override characters.
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

class _ConsentMemory {
  const _ConsentMemory._();

  // Session-only storage.
  // Replace by persisted secure storage in production.
  static bool? choice;
}

class _HomeLoadingSkeleton extends StatefulWidget {
  const _HomeLoadingSkeleton();

  @override
  State<_HomeLoadingSkeleton> createState() => _HomeLoadingSkeletonState();
}

class _HomeLoadingSkeletonState extends State<_HomeLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulse = _controller.drive(
      CurveTween(curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final opacity = 0.40 + (_pulse.value * 0.60);

        return Semantics(
          label: 'Chargement de la page',
          child: SafeArea(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              children: [
                Opacity(
                  opacity: opacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _box(
                            44,
                            width: 44,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _box(18)),
                          const SizedBox(width: 24),
                          _box(
                            40,
                            width: 120,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ],
                      ),
                      const SizedBox(height: 56),
                      _box(
                        20,
                        width: 160,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      const SizedBox(height: 18),
                      _box(56, borderRadius: BorderRadius.circular(18)),
                      const SizedBox(height: 12),
                      _box(
                        56,
                        width: MediaQuery.of(context).size.width * 0.72,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      const SizedBox(height: 18),
                      _box(16, borderRadius: BorderRadius.circular(10)),
                      const SizedBox(height: 10),
                      _box(
                        16,
                        width: MediaQuery.of(context).size.width * 0.82,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 34),
                      _box(240, borderRadius: BorderRadius.circular(28)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _box(
                              170,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _box(
                              170,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _box(
                              170,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _box(
                              170,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _box(220, borderRadius: BorderRadius.circular(28)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _box(
    double height, {
    double? width,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F7),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({
    required this.onRetry,
    this.isTimeout = false,
  });

  final VoidCallback onRetry;
  final bool isTimeout;

  @override
  Widget build(BuildContext context) {
    final title =
        isTimeout ? 'Délai dépassé' : 'Impossible de charger la page';

    final message = isTimeout
        ? 'Le service met trop de temps à répondre. Vérifiez votre connexion puis réessayez.'
        : 'Une erreur est survenue pendant le chargement sécurisé du contenu. Aucune donnée sensible n’a été exposée.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  const _BackToTopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Revenir en haut de page',
      button: true,
      child: Material(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(999),
        elevation: 6,
        shadowColor: const Color.fromRGBO(0, 0, 0, 0.18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
