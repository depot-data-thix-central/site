import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/content_service.dart';
import '../theme.dart';
import '../widgets/loading.dart';
import '../widgets/navbar.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/solutions_section.dart';
import '../widgets/impact_section.dart';
import '../widgets/vision_section.dart';
import '../widgets/footer.dart';
import '../widgets/consent_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ContentService();
  SiteContent? _content;
  bool _loading = true;
  bool? _consent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final content = await _service.loadPublished();
    if (!mounted) return;
    setState(() {
      _content = content;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: AppLoading()),
      );
    }

    final c = _content ?? const SiteContent();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Navbar(content: c),
                HeroSection(content: c),
                FeaturesSection(features: c.features),
                SolutionsSection(solutions: c.solutions),
                ImpactSection(stats: c.stats, quote: c.impactQuote),
                VisionSection(text: c.visionText),
                Footer(legal: c.footerLegal),
              ],
            ),
          ),
          if (_consent == null && c.consentText.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: ConsentBanner(
                text: c.consentText,
                onAccept: () => setState(() => _consent = true),
                onRefuse: () => setState(() => _consent = false),
              ),
            ),
        ],
      ),
    );
  }
}
