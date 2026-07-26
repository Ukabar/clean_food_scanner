import '../models/product_model.dart';

class ProductDataCompletenessEvaluator {
  const ProductDataCompletenessEvaluator();

  ProductDataCompleteness evaluate(UnifiedProduct product) {
    final nutrition = product.nutrition;
    final invalidFields = <String>[];

    void check(String field, double? value, {double max = 100}) {
      if (value == null) return;
      if (value < 0 || value > max) invalidFields.add(field);
    }

    check('energyKcal', nutrition.energyKcalPer100g, max: 1000);
    check('fat', nutrition.fatPer100g);
    check('saturatedFat', nutrition.saturatedFatPer100g);
    check('carbohydrates', nutrition.carbohydratesPer100g);
    check('sugars', nutrition.sugarsPer100g);
    check('protein', nutrition.proteinsPer100g);
    check('fiber', nutrition.fiberPer100g);
    check('salt', nutrition.saltPer100g);
    check('sodium', nutrition.sodiumPer100g);

    final sodiumOrSalt = nutrition.sodiumPer100g ?? nutrition.saltPer100g;
    final coreValues = <double?>[
      nutrition.energyKcalPer100g,
      nutrition.fatPer100g,
      nutrition.saturatedFatPer100g,
      nutrition.carbohydratesPer100g,
      nutrition.sugarsPer100g,
      nutrition.proteinsPer100g,
      sodiumOrSalt,
      nutrition.fiberPer100g,
    ];
    final coreFieldCount = coreValues.whereType<double>().length;
    final hasEnergy = nutrition.energyKcalPer100g != null;
    final hasAnyUsableData =
        nutrition.hasAnyData ||
        (product.ingredientsText?.isNotEmpty ?? false) ||
        product.ingredients.isNotEmpty ||
        product.novaGroup != null;

    return ProductDataCompleteness(
      hasEnergy: hasEnergy,
      coreFieldCount: coreFieldCount,
      hasInvalidValues: invalidFields.isNotEmpty,
      invalidFields: invalidFields,
      hasAnyUsableData: hasAnyUsableData,
      canCalculateScore:
          hasEnergy && coreFieldCount >= 5 && invalidFields.isEmpty,
    );
  }
}

class ProductDataCompleteness {
  const ProductDataCompleteness({
    required this.hasEnergy,
    required this.coreFieldCount,
    required this.hasInvalidValues,
    required this.invalidFields,
    required this.hasAnyUsableData,
    required this.canCalculateScore,
  });

  final bool hasEnergy;
  final int coreFieldCount;
  final bool hasInvalidValues;
  final List<String> invalidFields;
  final bool hasAnyUsableData;
  final bool canCalculateScore;
}
