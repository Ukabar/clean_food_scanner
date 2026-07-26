import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_system.dart';
import '../../core/widgets/responsive_content.dart';
import '../../data/local/local_storage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  static const _pages = [
    _OnboardingPageData(
      asset: 'assets/onboarding/onboarding_scan.png',
      title: 'Scan food products',
      description:
          'Use your camera to scan product barcodes and view available food information.',
      features: [
        _FeatureData(Icons.list_alt_outlined, 'Ingredient\nDetails'),
        _FeatureData(Icons.insights_outlined, 'Product\nInsights'),
        _FeatureData(Icons.trending_up_rounded, 'Smarter\nChoices'),
      ],
      illustration: _IllustrationType.scan,
    ),
    _OnboardingPageData(
      asset: 'assets/onboarding/onboarding_details.png',
      title: 'Understand ingredients',
      description:
          'Review nutrition, additives, allergens, and processing information.',
      features: [
        _FeatureData(Icons.fact_check_outlined, 'Clear\nBreakdown'),
        _FeatureData(Icons.info_outline, 'Potential\nConcerns'),
        _FeatureData(Icons.check_circle_outline, 'Informed\nChoices'),
      ],
      illustration: _IllustrationType.details,
    ),
    _OnboardingPageData(
      asset: 'assets/onboarding/onboarding_score.png',
      title: 'Choose with more context',
      description:
          'Get a simple score when enough product information is available.',
      features: [
        _FeatureData(Icons.speed_rounded, 'Simple Product\nScore'),
        _FeatureData(Icons.tune_rounded, 'Better\nContext'),
        _FeatureData(Icons.notes_rounded, 'Clear\nReasons'),
      ],
      illustration: _IllustrationType.score,
      prominentScoreLayout: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await LocalStorage.instance.setOnboardingComplete(true);
    if (mounted) context.go('/');
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: _OnboardingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),
            ResponsiveContent(
              maxWidth: 650,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveInsets.compactHorizontal(context),
                  8,
                  ResponsiveInsets.compactHorizontal(context),
                  bottomPadding + 24,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 340;
                    return Row(
                      children: [
                        SizedBox(
                          width: narrow ? 48 : 56,
                          child: _StepCounter(
                            current: _index + 1,
                            total: _pages.length,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _Dots(index: _index, total: _pages.length),
                          ),
                        ),
                        SizedBox(
                          width: narrow ? 126 : 148,
                          height: narrow ? 52 : 54,
                          child: Semantics(
                            button: true,
                            label: _index == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            child: FilledButton(
                              key: const ValueKey('onboarding_next_action'),
                              onPressed: _next,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                backgroundColor: _OnboardingColors.emerald,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _index == _pages.length - 1
                                          ? 'Get Started'
                                          : 'Next',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 610;
        final compact = constraints.maxHeight < 700;
        final scorePage = data.prominentScoreLayout;
        final illustrationHeight = scorePage
            ? constraints.maxHeight * (short ? 0.50 : 0.58)
            : constraints.maxHeight * (short ? 0.39 : 0.45);
        final topPadding = scorePage
            ? (short ? 0.0 : 6.0)
            : (short ? 8.0 : 24.0);
        final afterIllustration = scorePage
            ? (short ? 8.0 : 20.0)
            : (short ? 10.0 : AppSpacing.lg);
        final titleSize = scorePage
            ? (compact ? 29.0 : 34.0)
            : (compact ? 28.0 : 34.0);

        final tablet = constraints.maxWidth >= 700;
        return ResponsiveContent(
          maxWidth: 650,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              ResponsiveInsets.horizontal(context),
              topPadding,
              ResponsiveInsets.horizontal(context),
              12,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: illustrationHeight
                        .clamp(scorePage ? 300 : 220, scorePage ? 430 : 385)
                        .toDouble(),
                    child: _OnboardingIllustration(data: data),
                  ),
                  SizedBox(height: afterIllustration),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data.title,
                      maxLines: scorePage ? 1 : null,
                      softWrap: !scorePage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _OnboardingColors.title,
                        fontSize: tablet ? 40 : titleSize,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: short ? 8 : 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _OnboardingColors.body,
                        fontSize: tablet
                            ? 20
                            : (scorePage
                                  ? (compact ? 15.5 : 17)
                                  : (compact ? 15.5 : 18)),
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: scorePage ? (short ? 14 : 28) : (short ? 16 : 30),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.features
                        .map((feature) => _FeatureBadge(feature: feature))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: _semanticsLabel(data.illustration),
      image: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            data.asset,
            key: ValueKey('onboarding_asset_${data.asset}'),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          if (data.illustration == _IllustrationType.scan)
            _AnimatedScanLine(reduceMotion: reduceMotion),
        ],
      ),
    );
  }

  String _semanticsLabel(_IllustrationType type) => switch (type) {
    _IllustrationType.scan => 'Illustration of scanning a food barcode',
    _IllustrationType.details => 'Illustration of product information rows',
    _IllustrationType.score => 'Illustration of a sample product score',
  };
}

class _AnimatedScanLine extends StatefulWidget {
  const _AnimatedScanLine({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_AnimatedScanLine> createState() => _AnimatedScanLineState();
}

class _AnimatedScanLineState extends State<_AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (!widget.reduceMotion) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AnimatedScanLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = widget.reduceMotion ? 0.5 : _controller.value;
            return Align(
              alignment: Alignment(0, -0.18 + value * 0.34),
              child: FractionallySizedBox(
                widthFactor: 0.46,
                child: Container(
                  key: const ValueKey('onboarding_scan_line'),
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42F4BE),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF42F4BE).withValues(alpha: 0.55),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.feature});

  final _FeatureData feature;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF5F0),
            ),
            child: Icon(
              feature.icon,
              color: _OnboardingColors.emerald,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            feature.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _OnboardingColors.title,
              fontSize: 13.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCounter extends StatelessWidget {
  const _StepCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page $current of $total',
      child: RichText(
        key: const ValueKey('onboarding_step_counter'),
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF9AA19D),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(
              text: '$current',
              style: const TextStyle(color: _OnboardingColors.emerald),
            ),
            TextSpan(text: ' / $total'),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page indicator, page ${index + 1} of $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (dotIndex) {
          final active = dotIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? 11 : 10,
            height: active ? 11 : 10,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? _OnboardingColors.emerald
                  : const Color(0xFFE4E7E4),
            ),
          );
        }),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.asset,
    required this.title,
    required this.description,
    required this.features,
    required this.illustration,
    this.prominentScoreLayout = false,
  });

  final String asset;
  final String title;
  final String description;
  final List<_FeatureData> features;
  final _IllustrationType illustration;
  final bool prominentScoreLayout;
}

class _FeatureData {
  const _FeatureData(this.icon, this.label);

  final IconData icon;
  final String label;
}

enum _IllustrationType { scan, details, score }

class _OnboardingColors {
  const _OnboardingColors._();

  static const background = Color(0xFFF8F7F5);
  static const emerald = Color(0xFF157347);
  static const title = Color(0xFF203B35);
  static const body = Color(0xFF6F7773);
}
