import '../../core/utils/barcode_normalizer.dart';
import '../models/nutrition_model.dart';
import '../models/product_model.dart';

class ProductMerger {
  const ProductMerger();

  UnifiedProduct merge(UnifiedProduct primary, UnifiedProduct secondary) {
    if (!_barcodeMatches(primary.barcode, secondary.barcode)) {
      throw ArgumentError('Cannot merge products with different barcodes.');
    }
    if (_hasStrongIdentityConflict(primary, secondary)) {
      return primary.copyWith(
        fieldSources: {
          ...primary.fieldSources,
          'mergeConflict': secondary.primarySource,
        },
      );
    }

    final fieldSources = Map<String, String>.from(primary.fieldSources);
    final sourcesUsed = {
      ...primary.sourcesUsed,
      ...secondary.sourcesUsed,
      if (primary.primarySource != 'unknown') primary.primarySource,
      if (secondary.primarySource != 'unknown') secondary.primarySource,
    }.toList();

    T? fill<T>(String field, T? current, T? fallback) {
      if (_hasValue(current) || !_hasValue(fallback)) return current;
      fieldSources[field] =
          secondary.fieldSources[field] ?? secondary.primarySource;
      return fallback;
    }

    double? fillNutrition(String field, double? current, double? fallback) {
      if (_hasValue(current) || !_hasValue(fallback)) return current;
      fieldSources['nutrition.$field'] =
          secondary.fieldSources['nutrition.$field'] ??
          secondary.fieldSources['nutrition'] ??
          secondary.primarySource;
      return fallback;
    }

    final allergens = _dedupe([...primary.allergens, ...secondary.allergens]);
    if (allergens.length != primary.allergens.length) {
      fieldSources['allergens'] = [
        primary.fieldSources['allergens'],
        secondary.fieldSources['allergens'] ?? secondary.primarySource,
      ].whereType<String>().join(',');
    }
    final additives = _dedupe([...primary.additives, ...secondary.additives]);
    if (additives.length != primary.additives.length) {
      fieldSources['additives'] = [
        primary.fieldSources['additives'],
        secondary.fieldSources['additives'] ?? secondary.primarySource,
      ].whereType<String>().join(',');
    }

    return primary.copyWith(
      name: fill('name', primary.name, secondary.name),
      brand: fill('brand', primary.brand, secondary.brand),
      imageUrl: fill('imageUrl', primary.imageUrl, secondary.imageUrl),
      ingredientsText: fill(
        'ingredientsText',
        primary.ingredientsText,
        secondary.ingredientsText,
      ),
      ingredients: primary.ingredients.isNotEmpty
          ? primary.ingredients
          : secondary.ingredients,
      allergens: allergens,
      additives: additives,
      categories: primary.categories.isNotEmpty
          ? primary.categories
          : secondary.categories,
      nutrition: NutritionModel(
        energyKcalPer100g: fillNutrition(
          'energyKcal',
          primary.nutrition.energyKcalPer100g,
          secondary.nutrition.energyKcalPer100g,
        ),
        fatPer100g: fillNutrition(
          'fat',
          primary.nutrition.fatPer100g,
          secondary.nutrition.fatPer100g,
        ),
        saturatedFatPer100g: fillNutrition(
          'saturatedFat',
          primary.nutrition.saturatedFatPer100g,
          secondary.nutrition.saturatedFatPer100g,
        ),
        carbohydratesPer100g: fillNutrition(
          'carbohydrates',
          primary.nutrition.carbohydratesPer100g,
          secondary.nutrition.carbohydratesPer100g,
        ),
        sugarsPer100g: fillNutrition(
          'sugars',
          primary.nutrition.sugarsPer100g,
          secondary.nutrition.sugarsPer100g,
        ),
        proteinsPer100g: fillNutrition(
          'protein',
          primary.nutrition.proteinsPer100g,
          secondary.nutrition.proteinsPer100g,
        ),
        fiberPer100g: fillNutrition(
          'fiber',
          primary.nutrition.fiberPer100g,
          secondary.nutrition.fiberPer100g,
        ),
        saltPer100g: fillNutrition(
          'salt',
          primary.nutrition.saltPer100g,
          secondary.nutrition.saltPer100g,
        ),
        sodiumPer100g: fillNutrition(
          'sodium',
          primary.nutrition.sodiumPer100g,
          secondary.nutrition.sodiumPer100g,
        ),
      ),
      nutriScoreGrade: fill(
        'nutriScore',
        primary.nutriScoreGrade,
        secondary.nutriScoreGrade,
      ),
      nutriScoreValue: fill(
        'nutriScoreValue',
        primary.nutriScoreValue,
        secondary.nutriScoreValue,
      ),
      novaGroup: fill('novaGroup', primary.novaGroup, secondary.novaGroup),
      quantity: fill('quantity', primary.quantity, secondary.quantity),
      servingSize: fill(
        'servingSize',
        primary.servingSize,
        secondary.servingSize,
      ),
      completeness: fill(
        'completeness',
        primary.completeness,
        secondary.completeness,
      ),
      primarySource: primary.primarySource,
      sourcesUsed: sourcesUsed,
      fieldSources: fieldSources,
    );
  }

  bool _barcodeMatches(String primary, String secondary) {
    if (primary == secondary) return true;
    try {
      return normalizeToGtin13(primary) == normalizeToGtin13(secondary);
    } on FormatException {
      return false;
    }
  }

  bool _hasStrongIdentityConflict(
    UnifiedProduct primary,
    UnifiedProduct secondary,
  ) {
    final primaryName = primary.name;
    final secondaryName = secondary.name;
    if (_hasValue(primaryName) &&
        _hasValue(secondaryName) &&
        _similarity(primaryName!, secondaryName!) < 0.2) {
      return true;
    }
    final primaryBrand = primary.brand;
    final secondaryBrand = secondary.brand;
    if (_hasValue(primaryBrand) &&
        _hasValue(secondaryBrand) &&
        _similarity(primaryBrand!, secondaryBrand!) < 0.35) {
      return true;
    }
    return false;
  }

  double _similarity(String a, String b) {
    final left = _tokens(a);
    final right = _tokens(b);
    if (left.isEmpty || right.isEmpty) return 1;
    final intersection = left.intersection(right).length;
    return (2 * intersection) / (left.length + right.length);
  }

  Set<String> _tokens(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .split(' ')
        .map((item) => item.trim())
        .where((item) => item.length > 1)
        .toSet();
  }

  bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }

  List<String> _dedupe(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final clean = value.trim();
      final key = clean.toLowerCase();
      if (clean.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(clean);
    }
    return result;
  }
}
