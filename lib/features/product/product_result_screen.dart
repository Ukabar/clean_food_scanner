import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/design_system.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/responsive_content.dart';
import '../../data/models/product_model.dart';
import '../../data/models/score_result.dart';
import '../../data/providers.dart';
import '../../data/services/product_data_completeness_evaluator.dart';
import '../favorites/favorites_controller.dart';

class ProductResultScreen extends ConsumerWidget {
  const ProductResultScreen({required this.barcode, super.key});

  final String barcode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(barcode));
    return product.when(
      loading: () => const _LoadingScreen(),
      error: (error, _) {
        if (error is AppException &&
            error.type == AppErrorType.productNotFound) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/not-found/$barcode');
          });
        }
        return _ErrorScreen(
          message: error is AppException ? error.message : 'Unknown error.',
          onRetry: () => ref.invalidate(productProvider(barcode)),
        );
      },
      data: (product) => _ProductDetails(product: product),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading product')),
      body: ResponsiveContent(
        maxWidth: 720,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            ResponsiveInsets.compactHorizontal(context),
            16,
            ResponsiveInsets.compactHorizontal(context),
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: List.generate(
            4,
            (index) => Container(
              height: index == 0 ? 150 : 76,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product lookup')),
      body: SafeArea(
        child: Center(
          child: ResponsiveContent(
            maxWidth: 520,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: Text(AppLocalizations.of(context).retry),
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

class _ProductDetails extends ConsumerWidget {
  const _ProductDetails({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(scoringEngineProvider).score(product);
    final isFavorite = ref
        .watch(favoritesControllerProvider)
        .any((item) => item.barcode == product.barcode);
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.xl;
    final horizontalPadding = ResponsiveInsets.compactHorizontal(context);
    final completeness = const ProductDataCompletenessEvaluator().evaluate(
      product,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: () =>
                ref.read(favoritesControllerProvider.notifier).toggle(product),
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_outline),
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 720,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            bottom,
          ),
          children: [
            if (product.isFromCache)
              const _NoticeCard(
                icon: Icons.cached_outlined,
                message:
                    'Showing saved product data. Some information may be outdated.',
              ),
            _ProductHeader(product: product),
            _ScoreCard(result: score),
            _IngredientsSection(product: product),
            _ProductInformationSection(product: product),
            if (product.allergens.isNotEmpty)
              _ChipSection(title: 'Allergens', items: product.allergens),
            if (product.additives.isNotEmpty)
              _ChipSection(title: 'Additives', items: product.additives),
            _NutritionSection(product: product),
            _UnavailableInformationSection(
              product: product,
              completeness: completeness,
            ),
            if (_shouldShowReasons(score))
              _ReasonsSection(
                reasons: score.reasons,
                scoreAvailable: score.hasReliableScore,
                completeness: completeness,
              ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowReasons(ScoreResult score) {
    if (score.hasReliableScore) return score.reasons.isNotEmpty;
    return score.reasons.isNotEmpty;
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final imageSize = MediaQuery.sizeOf(context).width < 360 ? 96.0 : 108.0;
    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(imageUrl: product.imageUrl, size: imageSize),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? 'Unknown product',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      height: 1.08,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.brand?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.brand!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Barcode ${product.barcode}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(result);
    if (!result.hasReliableScore || result.score == null) {
      return const _SurfaceCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SoftIcon(icon: Icons.info_outline),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score unavailable',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'This product does not include enough nutrition information to calculate a score.',
                      style: TextStyle(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final scoreText = result.score!.round().toString();
    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 78,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: 78,
                    child: CircularProgressIndicator(
                      value: result.score! / 100,
                      strokeWidth: 7,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.14),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    scoreText,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.rating,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${result.confidenceLabel}. ${_firstReason(result)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstReason(ScoreResult result) {
    final reason = result.reasons.firstOrNull;
    return reason?.shortDescription ?? 'Based on available product data.';
  }

  Color _scoreColor(ScoreResult result) {
    final score = result.score;
    if (score == null) return AppColors.unavailable;
    if (score >= 85) return AppColors.excellent;
    if (score >= 70) return AppColors.good;
    if (score >= 50) return AppColors.mixed;
    if (score >= 30) return AppColors.lessFavorable;
    return AppColors.poor;
  }
}

class _IngredientsSection extends StatefulWidget {
  const _IngredientsSection({required this.product});

  final ProductModel product;

  @override
  State<_IngredientsSection> createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<_IngredientsSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ingredients = widget.product.ingredientsText?.trim();
    if (ingredients == null || ingredients.isEmpty) {
      return const _Section(
        title: 'Ingredients',
        compact: true,
        child: Text('Ingredient information unavailable.'),
      );
    }

    final isLong = ingredients.length > 220;
    return _Section(
      title: 'Ingredients',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ingredients,
            maxLines: isLong && !_expanded ? 5 : null,
            overflow: isLong && !_expanded
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (isLong) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show less' : 'Show more'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: items.map((item) => Chip(label: Text(item))).toList(),
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  const _NutritionSection({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final n = product.nutrition;
    final rows = <String, String>{
      if (n.energyKcalPer100g != null)
        'Energy': '${n.energyKcalPer100g!.toStringAsFixed(0)} kcal',
      if (n.proteinsPer100g != null) 'Protein': _grams(n.proteinsPer100g),
      if (n.carbohydratesPer100g != null)
        'Carbohydrates': _grams(n.carbohydratesPer100g),
      if (n.sugarsPer100g != null) 'Sugars': _grams(n.sugarsPer100g),
      if (n.fatPer100g != null) 'Fat': _grams(n.fatPer100g),
      if (n.saturatedFatPer100g != null)
        'Saturated fat': _grams(n.saturatedFatPer100g),
      if (n.fiberPer100g != null) 'Fiber': _grams(n.fiberPer100g),
      if (n.saltPer100g != null) 'Salt': _grams(n.saltPer100g),
      if (n.sodiumPer100g != null) 'Sodium': _grams(n.sodiumPer100g),
    };

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Section(
      title: 'Nutrition per 100 g',
      child: Column(
        children: rows.entries
            .map((entry) => _FactRow(entry.key, entry.value))
            .toList(),
      ),
    );
  }

  static String _grams(double? value) => '${value!.toStringAsFixed(1)} g';
}

class _ProductInformationSection extends StatelessWidget {
  const _ProductInformationSection({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      if (_validValue(product.quantity))
        MapEntry('Quantity', product.quantity!),
      if (_validValue(product.servingSize))
        MapEntry('Serving size', product.servingSize!),
      if (product.completeness != null)
        MapEntry(
          'Data completeness',
          '${(product.completeness! * 100).toStringAsFixed(0)}%',
        ),
      if (_validValue(product.nutriScoreGrade))
        MapEntry('Nutri-Score', product.nutriScoreGrade!.toUpperCase()),
      if (product.novaGroup != null && product.novaGroup! > 0)
        MapEntry('NOVA group', product.novaGroup!.toString()),
      if (product.categories.isNotEmpty)
        MapEntry('Category', product.categories.first),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'Product information',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 310 ? 1 : 2;
          final spacing = AppSpacing.sm;
          final width =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: rows
                .map(
                  (entry) => SizedBox(
                    width: width,
                    child: _InfoTile(label: entry.key, value: entry.value),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  bool _validValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return false;
    final lower = normalized.toLowerCase();
    return lower != 'unknown' && lower != 'unavailable' && lower != '--';
  }
}

class _UnavailableInformationSection extends StatelessWidget {
  const _UnavailableInformationSection({
    required this.product,
    required this.completeness,
  });

  final ProductModel product;
  final ProductDataCompleteness completeness;

  @override
  Widget build(BuildContext context) {
    final missing = <_MissingInfo>[
      if (!product.nutrition.hasAnyData)
        const _MissingInfo(Icons.restaurant_menu_outlined, 'Nutrition facts'),
      if (product.allergens.isEmpty)
        const _MissingInfo(Icons.info_outline, 'Allergen information'),
    ];

    if (missing.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'Unavailable information',
      compact: true,
      child: Column(
        children: [
          ...missing.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item.label)),
                  Text(
                    'Not available',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Always verify the product package.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonsSection extends StatelessWidget {
  const _ReasonsSection({
    required this.reasons,
    required this.scoreAvailable,
    required this.completeness,
  });

  final List<ScoreReason> reasons;
  final bool scoreAvailable;
  final ProductDataCompleteness completeness;

  @override
  Widget build(BuildContext context) {
    final visibleReasons = scoreAvailable
        ? reasons
        : _missingScoreReasons(completeness);
    if (visibleReasons.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: scoreAvailable ? 'Why this result?' : 'Why no score?',
      compact: true,
      child: Column(
        children: visibleReasons
            .map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      switch (reason.type) {
                        ScoreReasonType.positive => Icons.add_circle_outline,
                        ScoreReasonType.negative => Icons.remove_circle_outline,
                        ScoreReasonType.neutral => Icons.info_outline,
                      },
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reason.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reason.shortDescription,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<ScoreReason> _missingScoreReasons(ProductDataCompleteness completeness) {
    final result = <ScoreReason>[];
    if (!completeness.hasEnergy) {
      result.add(
        const ScoreReason(
          title: 'Nutrition information is unavailable.',
          shortDescription: 'Energy per 100 g is missing.',
          impact: 0,
          type: ScoreReasonType.neutral,
          severity: 2,
        ),
      );
    }
    if (completeness.coreFieldCount < 5) {
      result.add(
        const ScoreReason(
          title: 'Not enough core nutrition fields were found.',
          shortDescription:
              'A score needs more complete nutrition values per 100 g.',
          impact: 0,
          type: ScoreReasonType.neutral,
          severity: 1,
        ),
      );
    }
    if (completeness.hasInvalidValues) {
      result.add(
        ScoreReason(
          title: 'Some nutrition values look invalid.',
          shortDescription: completeness.invalidFields.join(', '),
          impact: 0,
          type: ScoreReasonType.neutral,
          severity: 3,
        ),
      );
    }
    return result;
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.compact = false,
  });

  final String title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _SurfaceCard(
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.lg : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _SurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.brightness == Brightness.light
              ? Colors.white
              : scheme.surfaceContainerHighest.withValues(alpha: 0.44),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
          boxShadow: scheme.brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.11),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: primary, size: 24),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingInfo {
  const _MissingInfo(this.icon, this.label);

  final IconData icon;
  final String label;
}
