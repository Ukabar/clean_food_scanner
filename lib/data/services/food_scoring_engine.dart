import '../models/product_model.dart';
import '../models/score_result.dart';
import 'product_data_completeness_evaluator.dart';

class FoodScoringEngine {
  const FoodScoringEngine({
    this.completenessEvaluator = const ProductDataCompletenessEvaluator(),
  });

  final ProductDataCompletenessEvaluator completenessEvaluator;

  ScoreResult score(ProductModel product) {
    final completeness = completenessEvaluator.evaluate(product);
    var score = 100;
    final reasons = <ScoreReason>[];

    int apply(
      String title,
      String description,
      int impact,
      ScoreReasonType type,
      int severity,
    ) {
      reasons.add(
        ScoreReason(
          title: title,
          shortDescription: description,
          impact: impact,
          type: type,
          severity: severity,
        ),
      );
      return impact;
    }

    final nutrition = product.nutrition;
    if (nutrition.sugarsPer100g case final sugar?) {
      final penalty = sugar <= 5
          ? 0
          : sugar <= 10
          ? 5
          : sugar <= 20
          ? 10
          : 20;
      if (penalty > 0) {
        score -= apply(
          'High sugar content',
          '${sugar.toStringAsFixed(1)} g sugar per 100 g.',
          penalty,
          ScoreReasonType.negative,
          penalty,
        );
      }
    }
    if (nutrition.saltPer100g case final salt?) {
      final penalty = salt <= 0.3
          ? 0
          : salt <= 1
          ? 5
          : salt <= 1.5
          ? 10
          : 15;
      if (penalty > 0) {
        score -= apply(
          'High salt content',
          '${salt.toStringAsFixed(2)} g salt per 100 g.',
          penalty,
          ScoreReasonType.negative,
          penalty,
        );
      }
    }
    if (nutrition.saturatedFatPer100g case final satFat?) {
      final penalty = satFat <= 1.5
          ? 0
          : satFat <= 5
          ? 5
          : satFat <= 10
          ? 10
          : 15;
      if (penalty > 0) {
        score -= apply(
          'High saturated fat',
          '${satFat.toStringAsFixed(1)} g saturated fat per 100 g.',
          penalty,
          ScoreReasonType.negative,
          penalty,
        );
      }
    }
    if (nutrition.fiberPer100g case final fiber?) {
      final bonus = fiber >= 6
          ? 6
          : fiber >= 3
          ? 3
          : 0;
      if (bonus > 0) {
        score += apply(
          'Good source of fiber',
          '${fiber.toStringAsFixed(1)} g fiber per 100 g.',
          bonus,
          ScoreReasonType.positive,
          bonus,
        );
      }
    }
    if (nutrition.proteinsPer100g case final protein?) {
      final bonus = protein >= 20
          ? 6
          : protein >= 10
          ? 4
          : protein >= 5
          ? 2
          : 0;
      if (bonus > 0) {
        score += apply(
          'High protein content',
          '${protein.toStringAsFixed(1)} g protein per 100 g.',
          bonus,
          ScoreReasonType.positive,
          bonus,
        );
      }
    }
    if (product.novaGroup case final nova?) {
      final penalty = switch (nova) {
        1 => 0,
        2 => 3,
        3 => 8,
        4 => 15,
        _ => 0,
      };
      if (penalty > 0) {
        score -= apply(
          'Processed product',
          'NOVA group $nova based on available data.',
          penalty,
          ScoreReasonType.negative,
          penalty,
        );
      }
    }
    final additiveCount = product.additives
        .map(
          (item) =>
              item.trim().toLowerCase().split(':').last.replaceAll('-', ''),
        )
        .where((item) => item.isNotEmpty)
        .toSet()
        .length;
    final additivePenalty = additiveCount == 0
        ? 0
        : additiveCount <= 2
        ? 3
        : additiveCount <= 5
        ? 7
        : 12;
    if (additivePenalty > 0) {
      score -= apply(
        'Contains several additives',
        '$additiveCount listed additive(s).',
        additivePenalty,
        ScoreReasonType.negative,
        additivePenalty,
      );
    }
    if (product.nutriScoreGrade case final grade?) {
      final adjustment = switch (grade.toUpperCase()) {
        'A' => 5,
        'B' => 2,
        'C' => 0,
        'D' => -4,
        'E' => -8,
        _ => 0,
      };
      if (adjustment != 0) {
        score += adjustment;
        reasons.add(
          ScoreReason(
            title: 'Nutri-Score ${grade.toUpperCase()}',
            shortDescription:
                'Used as a supporting signal, not as the only factor.',
            impact: adjustment.abs(),
            type: adjustment > 0
                ? ScoreReasonType.positive
                : ScoreReasonType.negative,
            severity: adjustment.abs(),
          ),
        );
      }
    }

    final confidence = _confidence(product, completeness);
    final availability = _availability(product, completeness);
    final reliable = completeness.canCalculateScore;
    if (!reliable) {
      reasons.add(
        const ScoreReason(
          title: 'Insufficient product data',
          shortDescription:
              'A numeric score needs more nutrition and ingredient details.',
          impact: 0,
          type: ScoreReasonType.neutral,
          severity: 1,
        ),
      );
    }

    final clamped = score.clamp(0, 100);
    final sortedReasons = [...reasons]
      ..sort((a, b) => b.severity.compareTo(a.severity));

    return ScoreResult(
      score: reliable ? clamped.toDouble() : null,
      rating: reliable ? _rating(clamped) : 'Not enough data',
      availability: availability,
      confidence: confidence,
      reasons: sortedReasons,
      hasReliableScore: reliable,
    );
  }

  ConfidenceLevel _confidence(
    ProductModel product,
    ProductDataCompleteness completeness,
  ) {
    var points = 0;
    if ((product.ingredientsText?.isNotEmpty ?? false) ||
        product.ingredients.isNotEmpty) {
      points++;
    }
    points += _nutritionSignalCount(product);
    if (product.additives.isNotEmpty) points++;
    if (product.allergens.isNotEmpty) points++;
    if (product.nutriScoreGrade != null) points++;
    if (product.novaGroup != null) points++;
    if (product.imageUrl != null) points++;
    if ((product.completeness ?? 0) >= 0.6) points++;
    if (completeness.canCalculateScore) points += 2;
    if (points >= 7) return ConfidenceLevel.high;
    if (points >= 4) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  ScoreAvailability _availability(
    ProductModel product,
    ProductDataCompleteness completeness,
  ) {
    if (completeness.canCalculateScore) {
      return ScoreAvailability.available;
    }
    if (completeness.hasAnyUsableData) {
      return ScoreAvailability.limited;
    }
    return ScoreAvailability.unavailable;
  }

  int _nutritionSignalCount(ProductModel product) {
    final nutrition = product.nutrition;
    return [
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
  }

  String _rating(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }
}
