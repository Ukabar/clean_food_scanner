import 'package:clean_food_scanner/data/models/nutrition_model.dart';
import 'package:clean_food_scanner/data/models/product_model.dart';
import 'package:clean_food_scanner/data/models/score_result.dart';
import 'package:clean_food_scanner/data/services/food_scoring_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = FoodScoringEngine();

  NutritionModel completeForScoringWhenBroad(NutritionModel nutrition) {
    final signalCount = [
      nutrition.energyKcalPer100g,
      nutrition.proteinsPer100g,
      nutrition.carbohydratesPer100g,
      nutrition.sugarsPer100g,
      nutrition.fatPer100g,
      nutrition.saturatedFatPer100g,
      nutrition.fiberPer100g,
      nutrition.saltPer100g,
      nutrition.sodiumPer100g,
    ].whereType<double>().length;
    if (signalCount < 3) return nutrition;
    return nutrition.copyWith(
      energyKcalPer100g: nutrition.energyKcalPer100g ?? 180,
      carbohydratesPer100g: nutrition.carbohydratesPer100g ?? 20,
      fatPer100g: nutrition.fatPer100g ?? 6,
      proteinsPer100g: nutrition.proteinsPer100g ?? 1,
      fiberPer100g: nutrition.fiberPer100g ?? 1,
    );
  }

  ProductModel product({
    NutritionModel nutrition = const NutritionModel(
      sugarsPer100g: 4,
      saltPer100g: 0.2,
      saturatedFatPer100g: 1,
      fiberPer100g: 4,
      proteinsPer100g: 8,
    ),
    List<String> additives = const [],
    List<String> allergens = const ['milk'],
    String? nutriScoreGrade,
    int? novaGroup,
    String? imageUrl = 'https://example.com/p.png',
    double? completeness = 0.8,
  }) {
    final effectiveNutrition = completeForScoringWhenBroad(nutrition);
    return ProductModel(
      barcode: '3017620422003',
      name: 'Test product',
      ingredientsText: 'Milk, cocoa',
      allergens: allergens,
      additives: additives,
      nutrition: effectiveNutrition,
      nutriScoreGrade: nutriScoreGrade,
      novaGroup: novaGroup,
      imageUrl: imageUrl,
      completeness: completeness,
      lastScannedAt: DateTime(2026),
    );
  }

  test('sugar scoring applies expected penalties', () {
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 4,
                saltPer100g: 0.1,
                saturatedFatPer100g: 0.5,
              ),
            ),
          )
          .score,
      100,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 8,
                saltPer100g: 0.1,
                saturatedFatPer100g: 0.5,
              ),
            ),
          )
          .score,
      95,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 15,
                saltPer100g: 0.1,
                saturatedFatPer100g: 0.5,
              ),
            ),
          )
          .score,
      90,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 25,
                saltPer100g: 0.1,
                saturatedFatPer100g: 0.5,
              ),
            ),
          )
          .score,
      80,
    );
  });

  test('salt scoring applies expected penalties', () {
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 2,
                saltPer100g: 0.2,
                saturatedFatPer100g: 0.5,
              ),
            ),
          )
          .score,
      100,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 2,
                saltPer100g: 0.7,
                saturatedFatPer100g: 0.5,
              ),
            ),
          )
          .score,
      95,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 2,
                saltPer100g: 1.2,
                saturatedFatPer100g: 0.5,
              ),
            ),
          )
          .score,
      90,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 2,
                saltPer100g: 2,
                saturatedFatPer100g: 0.5,
              ),
            ),
          )
          .score,
      85,
    );
  });

  test('saturated fat scoring applies expected penalties', () {
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 2,
                saltPer100g: 0.1,
                saturatedFatPer100g: 1,
              ),
            ),
          )
          .score,
      100,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 2,
                saltPer100g: 0.1,
                saturatedFatPer100g: 4,
              ),
            ),
          )
          .score,
      95,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 2,
                saltPer100g: 0.1,
                saturatedFatPer100g: 8,
              ),
            ),
          )
          .score,
      90,
    );
    expect(
      engine
          .score(
            product(
              nutrition: const NutritionModel(
                sugarsPer100g: 2,
                saltPer100g: 0.1,
                saturatedFatPer100g: 12,
              ),
            ),
          )
          .score,
      85,
    );
  });

  test('fiber and protein bonuses are applied', () {
    expect(engine.score(product()).score, 100);
  });

  test('NOVA, Nutri-Score, additives and clamp work', () {
    final result = engine.score(
      product(
        nutrition: const NutritionModel(
          sugarsPer100g: 100,
          saltPer100g: 3,
          saturatedFatPer100g: 30,
        ),
        additives: const ['e250', 'e621', 'e951', 'e202', 'e100', 'e300'],
        nutriScoreGrade: 'E',
        novaGroup: 4,
      ),
    );
    expect(result.score, inInclusiveRange(0, 100));
    expect(result.rating, 'Poor');
  });

  test(
    'missing data lowers confidence without creating a misleading score',
    () {
      final result = engine.score(
        ProductModel(barcode: '12345678', lastScannedAt: DateTime(2026)),
      );
      expect(result.score, isNull);
      expect(result.availability, ScoreAvailability.unavailable);
      expect(result.confidence, ConfidenceLevel.low);
      expect(result.hasReliableScore, isFalse);
    },
  );

  test('confidence can be high with broad available data', () {
    final result = engine.score(product(nutriScoreGrade: 'B', novaGroup: 1));
    expect(result.confidence, ConfidenceLevel.high);
    expect(result.hasReliableScore, isTrue);
  });

  test('one nutrient alone does not produce a misleading excellent score', () {
    final result = engine.score(
      product(nutrition: const NutritionModel(sugarsPer100g: 4)),
    );
    expect(result.score, isNull);
    expect(result.availability, ScoreAvailability.limited);
  });

  test('NOVA alone does not produce a numeric score', () {
    final result = engine.score(
      ProductModel(
        barcode: '12345678',
        novaGroup: 1,
        lastScannedAt: DateTime(2026),
      ),
    );
    expect(result.score, isNull);
    expect(result.rating, 'Not enough data');
  });

  test('duplicate additives are counted once', () {
    final result = engine.score(
      product(additives: const ['e250', 'E250', ' en:e250 ', 'e621']),
    );

    final additiveReason = result.reasons.singleWhere(
      (reason) => reason.title == 'Contains several additives',
    );
    expect(additiveReason.shortDescription, '2 listed additive(s).');
  });

  test('extreme nutrition values do not produce a misleading score', () {
    final result = engine.score(
      product(
        nutrition: const NutritionModel(
          sugarsPer100g: 1000,
          saltPer100g: 1000,
          saturatedFatPer100g: 1000,
        ),
        additives: const ['e1', 'e2', 'e3', 'e4', 'e5', 'e6'],
        nutriScoreGrade: 'E',
        novaGroup: 4,
      ),
    );

    expect(result.score, isNull);
    expect(result.rating, 'Not enough data');
  });

  test('invalid Nutri-Score and NOVA values do not crash or adjust score', () {
    final result = engine.score(product(nutriScoreGrade: 'Z', novaGroup: 99));

    expect(result.score, isNotNull);
    expect(
      result.reasons.where((reason) => reason.title.startsWith('Nutri-Score')),
      isEmpty,
    );
  });

  test('reasons are sorted by severity', () {
    final result = engine.score(
      product(
        nutrition: const NutritionModel(sugarsPer100g: 25, saltPer100g: 0.7),
      ),
    );

    final severities = result.reasons.map((reason) => reason.severity).toList();
    expect(severities, [...severities]..sort((a, b) => b.compareTo(a)));
  });
}
