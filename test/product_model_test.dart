import 'package:clean_food_scanner/data/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses complete Open Food Facts product response', () {
    final product = ProductModel.fromOpenFoodFacts({
      'code': '3017620422003',
      'status': 1,
      'product': {
        'code': '3017620422003',
        'product_name': 'Hazelnut spread',
        'brands': 'Example Brand',
        'image_front_url': 'https://example.com/image.jpg',
        'ingredients_text': 'Sugar, hazelnuts, cocoa',
        'ingredients': [
          {'text': 'Sugar'},
          {'text': 'Hazelnuts'},
        ],
        'allergens_tags': ['en:nuts'],
        'additives_tags': ['en:e322'],
        'categories_tags': ['en:spreads'],
        'nutriscore_grade': 'e',
        'nutriscore_score': 26,
        'nova_group': 4,
        'quantity': '400 g',
        'serving_size': '15 g',
        'completeness': 0.9,
        'nutriments': {
          'energy-kcal_100g': 539,
          'proteins_100g': 6.3,
          'carbohydrates_100g': 57.5,
          'sugars_100g': 56.3,
          'fat_100g': 30.9,
          'saturated-fat_100g': 10.6,
          'fiber_100g': 3.4,
          'salt_100g': 0.1,
          'sodium_100g': 0.04,
        },
      },
    });

    expect(product.barcode, '3017620422003');
    expect(product.name, 'Hazelnut spread');
    expect(product.ingredients, contains('Sugar'));
    expect(product.allergens, contains('nuts'));
    expect(product.nutriScoreGrade, 'E');
    expect(product.nutrition.sugarsPer100g, 56.3);
  });

  test('supports incomplete product data', () {
    final product = ProductModel.fromOpenFoodFacts({
      'code': '12345678',
      'status': 1,
      'product': {'code': '12345678'},
    });

    expect(product.name, isNull);
    expect(product.nutrition.hasAnyData, isFalse);
  });

  test('throws on invalid API response', () {
    expect(
      () => ProductModel.fromOpenFoodFacts({'status': 1}),
      throwsFormatException,
    );
  });

  test('parses nutrition values from mixed numeric types', () {
    final product = ProductModel.fromOpenFoodFacts({
      'code': '12345678',
      'status': 1,
      'product': {
        'code': '12345678',
        'nutriments': {
          'energy-kcal_100g': '120',
          'proteins_100g': 8,
          'sugars_100g': 4.5,
          'salt_100g': '',
        },
      },
    });

    expect(product.nutrition.energyKcalPer100g, 120);
    expect(product.nutrition.proteinsPer100g, 8);
    expect(product.nutrition.sugarsPer100g, 4.5);
    expect(product.nutrition.saltPer100g, isNull);
  });

  test('cleans tags and ignores empty tag values', () {
    final product = ProductModel.fromOpenFoodFacts({
      'code': '12345678',
      'status': 1,
      'product': {
        'code': '12345678',
        'allergens_tags': ['en:milk', '', 'fr:gluten-free'],
        'additives_tags': ['en:e250', 42],
      },
    });

    expect(product.allergens, containsAll(['milk', 'gluten free']));
    expect(product.additives, containsAll(['e250', '42']));
  });

  test('keeps optional product fields null when source values are empty', () {
    final product = ProductModel.fromOpenFoodFacts({
      'code': '12345678',
      'status': 1,
      'product': {
        'code': '12345678',
        'product_name': '',
        'brands': '   ',
        'image_url': null,
      },
    });

    expect(product.name, isNull);
    expect(product.brand, isNull);
    expect(product.imageUrl, isNull);
  });

  test('filters price-like quantity values', () {
    final product = ProductModel.fromOpenFoodFacts({
      'code': '12345678',
      'status': 1,
      'product': {'code': '12345678', 'quantity': '8.5 dh'},
    });

    expect(product.quantity, isNull);
  });

  test('keeps real food quantity values', () {
    final product = ProductModel.fromOpenFoodFacts({
      'code': '12345678',
      'status': 1,
      'product': {'code': '12345678', 'quantity': '500 g'},
    });

    expect(product.quantity, '500 g');
  });
}
