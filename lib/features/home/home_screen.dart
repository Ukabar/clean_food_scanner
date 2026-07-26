import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/design_system.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/responsive_content.dart';
import '../../data/local/local_storage.dart';
import '../../data/models/scan_history_item.dart';
import '../history/history_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _openingScanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!LocalStorage.instance.onboardingComplete && mounted) {
        context.go('/onboarding');
      }
    });
  }

  Future<void> _openScanner() async {
    if (_openingScanner) return;
    setState(() => _openingScanner = true);
    await context.push('/scanner');
    if (mounted) setState(() => _openingScanner = false);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyControllerProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 112;
    final horizontalPadding = ResponsiveInsets.compactHorizontal(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth.clamp(0.0, 720.0);
            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(historyControllerProvider.notifier).refresh(),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      10,
                      horizontalPadding,
                      bottom,
                    ),
                    children: [
                      const _HomeHeader(),
                      const SizedBox(height: 22),
                      const _HomeHeroIntro(),
                      const SizedBox(height: 18),
                      _ScanHeroCard(
                        onTap: _openScanner,
                        buttonKey: const ValueKey('home_scan_now_action'),
                      ),
                      const SizedBox(height: 16),
                      const _QuickActionsRow(),
                      const SizedBox(height: 18),
                      _RecentScansCard(
                        title: AppLocalizations.of(context).recentScans,
                        history: history,
                        onViewAll: () => context.go('/history'),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.asset(
            'assets/app_icon/clean_food_scanner_icon_1024.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.appName,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroIntro extends StatelessWidget {
  const _HomeHeroIntro();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final small = width < 350;
        final tablet = width >= 620;
        final titleSize = small
            ? 28.0
            : (tablet ? 42.0 : (width < 400 ? 31.0 : 34.0));
        final descriptionSize = small
            ? 14.0
            : (tablet ? 19.0 : (width < 400 ? 15.0 : 16.0));
        final imageWidth = small
            ? 92.0
            : (tablet ? 176.0 : (width < 400 ? 112.0 : 138.0));
        final imageHeight = small
            ? 126.0
            : (tablet ? 204.0 : (width < 400 ? 146.0 : 166.0));
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final heroHeight =
            (small ? 194.0 : (tablet ? 250.0 : 206.0)) +
            (textScale > 1.2 ? (small ? 22.0 : 18.0) : 0.0);

        return SizedBox(
          height: heroHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  key: const ValueKey('home_hero_text_column'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          key: const ValueKey('home_hero_title'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Scan smarter.',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: titleSize,
                                height: 1.18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              'Choose better.',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: titleSize,
                                height: 1.18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          left: titleSize * 4.7,
                          right: 18,
                          bottom: -2,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Understand ingredients, nutrition, and processing before you buy.',
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: descriptionSize,
                        height: 1.36,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: small ? 6 : 12),
              Flexible(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.asset(
                      'assets/home/home_hero_product.png',
                      key: const ValueKey('home_hero_product_illustration'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({required this.onTap, this.buttonKey});

  final VoidCallback onTap;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final small = width < 350;
    final tablet = width >= 620;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scanTitleSize = small
        ? 21.0
        : (tablet ? 28.0 : (width < 400 ? 23.0 : 25.0));
    final scanDescriptionSize = small
        ? 14.0
        : (tablet ? 18.0 : (width < 400 ? 15.0 : 16.0));
    final cardMinHeight = small
        ? (textScale > 1.2 ? 306.0 : 250.0)
        : (tablet
              ? (textScale > 1.2 ? 290.0 : 260.0)
              : (textScale > 1.2 ? 258.0 : (width < 400 ? 220.0 : 230.0)));

    return ConstrainedBox(
      key: const ValueKey('home_scan_card'),
      constraints: BoxConstraints(minHeight: cardMinHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(small ? 18 : 20),
              child: Row(
                children: [
                  if (!small) ...[
                    SizedBox(
                      width: tablet ? 124 : 88,
                      child: const _ScannerOrb(),
                    ),
                    SizedBox(width: tablet ? 22 : 12),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan a food product',
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: scanTitleSize,
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Check ingredients, nutrition, and processing.',
                          maxLines: 3,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: scanDescriptionSize,
                                height: 1.36,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 18),
                        _ScanNowButton(key: buttonKey, onTap: onTap),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanNowButton extends StatelessWidget {
  const _ScanNowButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < 350;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 52, maxWidth: small ? 220 : 245),
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFF5DA),
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          minimumSize: Size(0, small ? 48 : 52),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(
            horizontal: small ? 16 : 20,
            vertical: small ? 9 : 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera_outlined, size: small ? 22 : 24),
              SizedBox(width: small ? 10 : 14),
              Text(
                'Scan now',
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: small ? 10 : 14),
              Container(
                width: small ? 34 : 38,
                height: small ? 34 : 38,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('home_quick_actions_row'),
      children: [
        Expanded(
          child: _QuickAction(
            key: const ValueKey('home_manual_action'),
            icon: Icons.keyboard_alt_outlined,
            title: 'Manual',
            subtitle: 'Enter a barcode',
            onTap: () => context.push('/manual-barcode'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            key: const ValueKey('home_favorites_action'),
            icon: Icons.favorite_border_rounded,
            title: 'Favorites',
            subtitle: 'View saved products',
            onTap: () => context.go('/favorites'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            key: const ValueKey('home_history_action'),
            icon: Icons.history_rounded,
            title: 'History',
            subtitle: 'See recent scans',
            onTap: () => context.go('/history'),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final small = MediaQuery.sizeOf(context).width < 350;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardHeight = textScale > 1.2
        ? (small ? 194.0 : 190.0)
        : (small ? 178.0 : 174.0);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: cardHeight,
          padding: EdgeInsets.fromLTRB(
            small ? 10 : 13,
            small ? 10 : 14,
            small ? 9 : 11,
            small ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: small ? 38 : 42,
                height: small ? 38 : 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: small ? 21 : 23,
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: small ? 15 : 16,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: small ? 11.5 : 12.5,
                  height: 1.25,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: small ? 5 : 7),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: small ? 28 : 32,
                  height: small ? 28 : 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: small ? 20 : 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentScansCard extends StatelessWidget {
  const _RecentScansCard({
    required this.title,
    required this.history,
    required this.onViewAll,
  });

  final String title;
  final List<ScanHistoryItem> history;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;

    return Container(
      key: const ValueKey('home_recent_scans_card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('home_recent_view_all'),
                onPressed: onViewAll,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                label: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (history.isEmpty)
            const _RecentEmptyState()
          else
            ...history
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentScanTile(item: item),
                  ),
                ),
        ],
      ),
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  const _RecentScanTile({required this.item});

  final ScanHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final rating = [
      item.brand,
      item.rating,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' - ');
    final score = item.score;

    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        minVerticalPadding: 10,
        leading: ProductImage(imageUrl: item.imageUrl, size: 48),
        title: Text(
          item.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          rating.isEmpty ? 'Not enough data' : rating,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: score == null
            ? const Icon(Icons.chevron_right_rounded)
            : _MiniScore(score: score),
        onTap: () => context.push('/product/${item.barcode}'),
      ),
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(180.0, 280.0);
        final illustrationWidth = (width * 0.88).clamp(180.0, 280.0);
        return Column(
          children: [
            SizedBox(
              key: const ValueKey('home_recent_empty_illustration'),
              width: illustrationWidth,
              height: illustrationWidth * 0.58,
              child: const _BasketIllustration(),
            ),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'No scanned products yet',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                'Scan a product to see recent food checks',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _BasketIllustration extends StatelessWidget {
  const _BasketIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BasketPainter(
        brightness: Theme.of(context).colorScheme.brightness,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BasketPainter extends CustomPainter {
  const _BasketPainter({required this.brightness});

  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final darkMode = brightness == Brightness.dark;
    final deep = darkMode ? const Color(0xFF2E8A67) : const Color(0xFF2F7F43);
    final mid = darkMode ? const Color(0xFF57A878) : const Color(0xFF4A9B43);
    final light = darkMode ? const Color(0xFFB4D8C3) : const Color(0xFFCDE5D3);
    final veryLight = darkMode
        ? const Color(0xFFE7F2EA).withValues(alpha: 0.24)
        : const Color(0xFFE9F4EC);
    final ink = const Color(0xFF22342F);

    Paint blur(Color color, double sigma) => Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

    final blob = Path()
      ..moveTo(size.width * 0.18, size.height * 0.78)
      ..cubicTo(
        size.width * 0.03,
        size.height * 0.62,
        size.width * 0.20,
        size.height * 0.44,
        size.width * 0.26,
        size.height * 0.35,
      )
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.14,
        size.width * 0.61,
        size.height * 0.05,
        size.width * 0.76,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.89,
        size.height * 0.25,
        size.width * 0.96,
        size.height * 0.52,
        size.width * 0.89,
        size.height * 0.78,
      )
      ..lineTo(size.width * 0.18, size.height * 0.78)
      ..close();
    canvas.drawPath(
      blob,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            veryLight.withValues(alpha: darkMode ? 0.24 : 0.86),
            light.withValues(alpha: darkMode ? 0.16 : 0.42),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.56),
      size.width * 0.11,
      Paint()..color = light.withValues(alpha: darkMode ? 0.16 : 0.42),
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.62),
      size.width * 0.10,
      Paint()..color = light.withValues(alpha: darkMode ? 0.10 : 0.22),
    );

    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.38),
      size.width * 0.018,
      Paint()..color = light.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.22),
      size.width * 0.014,
      Paint()..color = light.withValues(alpha: 0.46),
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.30),
      size.width * 0.014,
      Paint()..color = light.withValues(alpha: 0.52),
    );
    final plusPaint = Paint()
      ..color = mid.withValues(alpha: 0.55)
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    final plus = Offset(size.width * 0.80, size.height * 0.17);
    canvas.drawLine(
      Offset(plus.dx - size.width * 0.020, plus.dy),
      Offset(plus.dx + size.width * 0.020, plus.dy),
      plusPaint,
    );
    canvas.drawLine(
      Offset(plus.dx, plus.dy - size.width * 0.020),
      Offset(plus.dx, plus.dy + size.width * 0.020),
      plusPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.53, size.height * 0.85),
        width: size.width * 0.55,
        height: size.height * 0.09,
      ),
      blur(Colors.black.withValues(alpha: darkMode ? 0.10 : 0.08), 8),
    );

    final bottlePath = Path()
      ..moveTo(size.width * 0.32, size.height * 0.56)
      ..lineTo(size.width * 0.32, size.height * 0.33)
      ..cubicTo(
        size.width * 0.37,
        size.height * 0.26,
        size.width * 0.38,
        size.height * 0.20,
        size.width * 0.38,
        size.height * 0.11,
      )
      ..lineTo(size.width * 0.48, size.height * 0.11)
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.20,
        size.width * 0.49,
        size.height * 0.26,
        size.width * 0.53,
        size.height * 0.33,
      )
      ..lineTo(size.width * 0.53, size.height * 0.56)
      ..close();
    canvas.drawPath(
      bottlePath.shift(const Offset(0, 3)),
      blur(Colors.black.withValues(alpha: 0.05), 7),
    );
    canvas.drawPath(
      bottlePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: darkMode ? 0.34 : 0.72),
            light.withValues(alpha: darkMode ? 0.34 : 0.60),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.35,
          size.height * 0.55,
          size.width * 0.14,
          size.height * 0.19,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: darkMode ? 0.26 : 0.58),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.35,
          size.height * 0.05,
          size.width * 0.14,
          size.height * 0.10,
        ),
        const Radius.circular(4),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [deep, mid],
        ).createShader(Offset.zero & size),
    );
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.24),
      Offset(size.width * 0.48, size.height * 0.47),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..strokeWidth = 1.2,
    );

    canvas.save();
    canvas.translate(size.width * 0.58, size.height * 0.12);
    canvas.rotate(0.12);
    final carton = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * 0.24, size.height * 0.50),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      carton.shift(const Offset(0, 3)),
      blur(Colors.black.withValues(alpha: 0.045), 6),
    );
    canvas.drawRRect(
      carton,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: darkMode ? 0.42 : 0.86),
                light.withValues(alpha: darkMode ? 0.30 : 0.58),
              ],
            ).createShader(
              Rect.fromLTWH(0, 0, size.width * 0.24, size.height * 0.5),
            ),
    );
    final cartonTop = Path()
      ..moveTo(0, size.height * 0.10)
      ..lineTo(size.width * 0.07, 0)
      ..lineTo(size.width * 0.24, size.height * 0.04)
      ..lineTo(size.width * 0.18, size.height * 0.16)
      ..close();
    canvas.drawPath(
      cartonTop,
      Paint()..color = light.withValues(alpha: darkMode ? 0.40 : 0.82),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.06, size.height * 0.13)
        ..lineTo(size.width * 0.17, size.height * 0.16)
        ..lineTo(size.width * 0.21, size.height * 0.50)
        ..lineTo(size.width * 0.02, size.height * 0.50)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.26),
    );
    canvas.drawCircle(
      Offset(size.width * 0.11, size.height * 0.27),
      size.width * 0.045,
      Paint()
        ..shader = RadialGradient(colors: [mid, deep]).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.11, size.height * 0.27),
            radius: size.width * 0.05,
          ),
        ),
    );
    canvas.restore();

    final leaf = Path()
      ..moveTo(size.width * 0.74, size.height * 0.49)
      ..cubicTo(
        size.width * 0.79,
        size.height * 0.24,
        size.width * 0.87,
        size.height * 0.34,
        size.width * 0.84,
        size.height * 0.57,
      )
      ..cubicTo(
        size.width * 0.79,
        size.height * 0.55,
        size.width * 0.76,
        size.height * 0.53,
        size.width * 0.74,
        size.height * 0.49,
      )
      ..close();
    canvas.drawPath(
      leaf.shift(const Offset(0, 2)),
      blur(Colors.black.withValues(alpha: 0.08), 5),
    );
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [mid, deep],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.77, size.height * 0.52)
        ..cubicTo(
          size.width * 0.79,
          size.height * 0.45,
          size.width * 0.81,
          size.height * 0.38,
          size.width * 0.84,
          size.height * 0.33,
        ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final rimRect = Rect.fromLTWH(
      size.width * 0.24,
      size.height * 0.48,
      size.width * 0.60,
      size.height * 0.15,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rimRect.shift(const Offset(0, 3)),
        const Radius.circular(9),
      ),
      blur(Colors.black.withValues(alpha: 0.08), 7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, const Radius.circular(9)),
      Paint()
        ..shader = LinearGradient(
          colors: [deep, AppColors.primaryDark],
        ).createShader(rimRect),
    );

    final basket = Path()
      ..moveTo(size.width * 0.28, size.height * 0.59)
      ..lineTo(size.width * 0.80, size.height * 0.59)
      ..lineTo(size.width * 0.76, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.88,
        size.width * 0.64,
        size.height * 0.88,
      )
      ..lineTo(size.width * 0.37, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.88,
        size.width * 0.27,
        size.height * 0.80,
      )
      ..close();
    canvas.drawPath(
      basket,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mid, deep],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.31, size.height * 0.61)
        ..lineTo(size.width * 0.40, size.height * 0.61)
        ..lineTo(size.width * 0.42, size.height * 0.87)
        ..lineTo(size.width * 0.34, size.height * 0.87)
        ..close(),
      Paint()..color = Colors.black.withValues(alpha: 0.05),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.68, size.height * 0.61)
        ..lineTo(size.width * 0.78, size.height * 0.61)
        ..lineTo(size.width * 0.74, size.height * 0.87)
        ..lineTo(size.width * 0.65, size.height * 0.87)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    final labelRect = Rect.fromLTWH(
      size.width * 0.47,
      size.height * 0.68,
      size.width * 0.23,
      size.height * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        labelRect.shift(const Offset(0, 2)),
        const Radius.circular(6),
      ),
      blur(Colors.black.withValues(alpha: 0.08), 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.96),
    );
    final barcodePaint = Paint()
      ..color = ink.withValues(alpha: 0.82)
      ..strokeCap = StrokeCap.round;
    final bars = [0.010, 0.006, 0.012, 0.005, 0.014, 0.008, 0.006, 0.013];
    for (var i = 0; i < bars.length; i++) {
      final x = labelRect.left + labelRect.width * (0.16 + i * 0.075);
      barcodePaint.strokeWidth = size.width * bars[i];
      canvas.drawLine(
        Offset(x, labelRect.top + labelRect.height * 0.20),
        Offset(x, labelRect.bottom - labelRect.height * 0.18),
        barcodePaint,
      );
    }
    final dotPaint = Paint()..color = ink.withValues(alpha: 0.58);
    for (final dx in [0.12, 0.26, 0.43, 0.58, 0.74, 0.88]) {
      canvas.drawCircle(
        Offset(labelRect.left + labelRect.width * dx, labelRect.bottom - 4),
        1.2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BasketPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

class _ScannerOrb extends StatelessWidget {
  const _ScannerOrb();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
