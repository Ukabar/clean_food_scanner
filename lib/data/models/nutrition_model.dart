class NutritionModel {
  const NutritionModel({
    this.energyKcalPer100g,
    this.proteinsPer100g,
    this.carbohydratesPer100g,
    this.sugarsPer100g,
    this.fatPer100g,
    this.saturatedFatPer100g,
    this.fiberPer100g,
    this.saltPer100g,
    this.sodiumPer100g,
  });

  final double? energyKcalPer100g;
  final double? proteinsPer100g;
  final double? carbohydratesPer100g;
  final double? sugarsPer100g;
  final double? fatPer100g;
  final double? saturatedFatPer100g;
  final double? fiberPer100g;
  final double? saltPer100g;
  final double? sodiumPer100g;

  bool get hasAnyData =>
      energyKcalPer100g != null ||
      proteinsPer100g != null ||
      carbohydratesPer100g != null ||
      sugarsPer100g != null ||
      fatPer100g != null ||
      saturatedFatPer100g != null ||
      fiberPer100g != null ||
      saltPer100g != null ||
      sodiumPer100g != null;

  NutritionModel copyWith({
    double? energyKcalPer100g,
    double? proteinsPer100g,
    double? carbohydratesPer100g,
    double? sugarsPer100g,
    double? fatPer100g,
    double? saturatedFatPer100g,
    double? fiberPer100g,
    double? saltPer100g,
    double? sodiumPer100g,
  }) {
    return NutritionModel(
      energyKcalPer100g: energyKcalPer100g ?? this.energyKcalPer100g,
      proteinsPer100g: proteinsPer100g ?? this.proteinsPer100g,
      carbohydratesPer100g: carbohydratesPer100g ?? this.carbohydratesPer100g,
      sugarsPer100g: sugarsPer100g ?? this.sugarsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      saturatedFatPer100g: saturatedFatPer100g ?? this.saturatedFatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      saltPer100g: saltPer100g ?? this.saltPer100g,
      sodiumPer100g: sodiumPer100g ?? this.sodiumPer100g,
    );
  }

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    double? value(String key) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw);
      return null;
    }

    return NutritionModel(
      energyKcalPer100g: value('energy-kcal_100g') ?? value('energy-kcal'),
      proteinsPer100g: value('proteins_100g'),
      carbohydratesPer100g: value('carbohydrates_100g'),
      sugarsPer100g: value('sugars_100g'),
      fatPer100g: value('fat_100g'),
      saturatedFatPer100g: value('saturated-fat_100g'),
      fiberPer100g: value('fiber_100g'),
      saltPer100g: value('salt_100g'),
      sodiumPer100g: value('sodium_100g'),
    );
  }

  Map<String, dynamic> toJson() => {
    'energyKcalPer100g': energyKcalPer100g,
    'proteinsPer100g': proteinsPer100g,
    'carbohydratesPer100g': carbohydratesPer100g,
    'sugarsPer100g': sugarsPer100g,
    'fatPer100g': fatPer100g,
    'saturatedFatPer100g': saturatedFatPer100g,
    'fiberPer100g': fiberPer100g,
    'saltPer100g': saltPer100g,
    'sodiumPer100g': sodiumPer100g,
  };

  factory NutritionModel.fromStorage(Map<String, dynamic> json) =>
      NutritionModel(
        energyKcalPer100g: _double(json['energyKcalPer100g']),
        proteinsPer100g: _double(json['proteinsPer100g']),
        carbohydratesPer100g: _double(json['carbohydratesPer100g']),
        sugarsPer100g: _double(json['sugarsPer100g']),
        fatPer100g: _double(json['fatPer100g']),
        saturatedFatPer100g: _double(json['saturatedFatPer100g']),
        fiberPer100g: _double(json['fiberPer100g']),
        saltPer100g: _double(json['saltPer100g']),
        sodiumPer100g: _double(json['sodiumPer100g']),
      );

  static double? _double(Object? raw) => raw is num ? raw.toDouble() : null;
}
