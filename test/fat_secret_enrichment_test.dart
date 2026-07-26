import 'dart:convert';

import 'package:clean_food_scanner/core/errors/app_exception.dart';
import 'package:clean_food_scanner/core/utils/barcode_normalizer.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:clean_food_scanner/data/models/nutrition_model.dart';
import 'package:clean_food_scanner/data/models/product_model.dart';
import 'package:clean_food_scanner/data/providers/food_data_provider.dart';
import 'package:clean_food_scanner/data/repositories/product_repository.dart';
import 'package:clean_food_scanner/data/services/fat_secret_provider.dart';
import 'package:clean_food_scanner/data/services/food_scoring_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocalStorage> storageWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final storage = LocalStorage.instance;
    await storage.initialize();
    return storage;
  }

  test('complete OFF product does not call FatSecret', () async {
    final storage = await storageWith({});
    final off = _FakeProvider(
      'openFoodFacts',
      ProviderProductFound(_product('3017620422003', nutrition: _complete())),
    );
    final fat = _FakeProvider(
      'fatSecret',
      ProviderProductFound(_product('3017620422003', source: 'fatSecret')),
    );
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [off, fat],
    );

    final result = await repo.getProduct('3017620422003');

    expect(result.primarySource, 'openFoodFacts');
    expect(fat.calls, 0);
  });

  test(
    'partial OFF product calls FatSecret and merges missing nutrition',
    () async {
      final storage = await storageWith({});
      final off = _FakeProvider(
        'openFoodFacts',
        ProviderProductFound(
          _product(
            '3017620422003',
            nutrition: const NutritionModel(energyKcalPer100g: 120),
          ),
        ),
      );
      final fat = _FakeProvider(
        'fatSecret',
        ProviderProductFound(
          _product(
            '3017620422003',
            source: 'fatSecret',
            nutrition: _complete(energy: 130),
          ),
        ),
      );
      final repo = MultiSourceProductRepository(
        storage: storage,
        providers: [off, fat],
      );

      final result = await repo.getProduct('3017620422003');

      expect(fat.calls, 1);
      expect(result.nutrition.energyKcalPer100g, 120);
      expect(result.nutrition.fatPer100g, 6);
      expect(result.sourcesUsed, containsAll(['openFoodFacts', 'fatSecret']));
    },
  );

  test('OFF not found and FatSecret found returns FatSecret product', () async {
    final storage = await storageWith({});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider('openFoodFacts', const ProviderProductNotFound()),
        _FakeProvider(
          'fatSecret',
          ProviderProductFound(
            _product('01234567', source: 'fatSecret', nutrition: _complete()),
          ),
        ),
      ],
    );

    final result = await repo.getProduct('01234567');

    expect(result.primarySource, 'fatSecret');
  });

  test('both providers not found throws ProductNotFound', () async {
    final storage = await storageWith({});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider('openFoodFacts', const ProviderProductNotFound()),
        _FakeProvider('fatSecret', const ProviderProductNotFound()),
      ],
    );

    await expectLater(
      repo.getProduct('3017620422003'),
      throwsA(
        isA<AppException>().having(
          (error) => error.type,
          'type',
          AppErrorType.productNotFound,
        ),
      ),
    );
  });

  test('partial OFF and FatSecret timeout returns partial OFF', () async {
    final storage = await storageWith({});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider(
          'openFoodFacts',
          ProviderProductFound(
            _product(
              '3017620422003',
              nutrition: const NutritionModel(energyKcalPer100g: 120),
            ),
          ),
        ),
        _FakeProvider('fatSecret', const ProviderTimeout()),
      ],
    );

    final result = await repo.getProduct('3017620422003');
    final score = const FoodScoringEngine().score(result);

    expect(result.primarySource, 'openFoodFacts');
    expect(score.score, isNull);
    expect(score.rating, 'Not enough data');
  });

  test('conflicting nutrition does not replace OFF primary values', () async {
    final storage = await storageWith({});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider(
          'openFoodFacts',
          ProviderProductFound(
            _product(
              '3017620422003',
              nutrition: const NutritionModel(energyKcalPer100g: 100),
            ),
          ),
        ),
        _FakeProvider(
          'fatSecret',
          ProviderProductFound(
            _product(
              '3017620422003',
              source: 'fatSecret',
              nutrition: _complete(energy: 900),
            ),
          ),
        ),
      ],
    );

    final result = await repo.getProduct('3017620422003');

    expect(result.nutrition.energyKcalPer100g, 100);
    expect(result.nutrition.fatPer100g, 6);
  });

  test('UPC-A converts to GTIN-13 and leading zero is preserved', () {
    expect(normalizeToGtin13('123456789012'), '0123456789012');
    expect(normalizeToGtin13('0123456789012'), '0123456789012');
  });

  test(
    'FatSecret per serving without serving weight is ignored for score',
    () async {
      final provider = _fatSecretProvider({
        'found': true,
        'barcode': '3017620422003',
        'product': {
          'name': 'Product',
          'nutritionBasis': 'per_serving',
          'energyKcal': 120,
          'fat': 6,
        },
      });

      final result = await provider.findByBarcode('3017620422003');

      expect(result, isA<ProviderProductFound>());
      final product = (result as ProviderProductFound).product;
      expect(product.nutrition.hasAnyData, isFalse);
    },
  );

  test(
    'FatSecret per serving with serving weight converts to per 100g',
    () async {
      final provider = _fatSecretProvider({
        'found': true,
        'barcode': '3017620422003',
        'product': {
          'name': 'Product',
          'nutritionBasis': 'per_serving',
          'servingSizeGrams': 50,
          'energyKcal': 100,
          'fat': 5,
          'saturatedFat': 1,
          'carbohydrates': 10,
          'sugars': 4,
          'protein': 3,
        },
      });

      final result = await provider.findByBarcode('3017620422003');
      final product = (result as ProviderProductFound).product;

      expect(product.nutrition.energyKcalPer100g, 200);
      expect(product.nutrition.fatPer100g, 10);
      expect(product.barcode, '3017620422003');
    },
  );

  test('product name conflict prevents merge', () async {
    final storage = await storageWith({});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider(
          'openFoodFacts',
          ProviderProductFound(
            _product(
              '3017620422003',
              name: 'Chocolate cereal',
              nutrition: const NutritionModel(energyKcalPer100g: 120),
            ),
          ),
        ),
        _FakeProvider(
          'fatSecret',
          ProviderProductFound(
            _product(
              '3017620422003',
              source: 'fatSecret',
              name: 'Tomato soup',
              nutrition: _complete(),
            ),
          ),
        ),
      ],
    );

    final result = await repo.getProduct('3017620422003');

    expect(result.sourcesUsed, isNot(contains('fatSecret')));
    expect(result.nutrition.fatPer100g, isNull);
    expect(result.fieldSources['mergeConflict'], 'fatSecret');
  });

  test(
    'score is calculated after merge provides five core fields and energy',
    () async {
      final storage = await storageWith({});
      final repo = MultiSourceProductRepository(
        storage: storage,
        providers: [
          _FakeProvider(
            'openFoodFacts',
            ProviderProductFound(
              _product(
                '3017620422003',
                nutrition: const NutritionModel(energyKcalPer100g: 120),
              ),
            ),
          ),
          _FakeProvider(
            'fatSecret',
            ProviderProductFound(
              _product(
                '3017620422003',
                source: 'fatSecret',
                nutrition: const NutritionModel(
                  fatPer100g: 6,
                  saturatedFatPer100g: 1,
                  carbohydratesPer100g: 20,
                  sugarsPer100g: 5,
                  proteinsPer100g: 4,
                ),
              ),
            ),
          ),
        ],
      );

      final result = await repo.getProduct('3017620422003');

      expect(const FoodScoringEngine().score(result).score, isNotNull);
    },
  );

  test(
    'score remains unavailable when merged data is still insufficient',
    () async {
      final storage = await storageWith({});
      final repo = MultiSourceProductRepository(
        storage: storage,
        providers: [
          _FakeProvider(
            'openFoodFacts',
            ProviderProductFound(
              _product(
                '3017620422003',
                nutrition: const NutritionModel(energyKcalPer100g: 120),
              ),
            ),
          ),
          _FakeProvider(
            'fatSecret',
            ProviderProductFound(
              _product(
                '3017620422003',
                source: 'fatSecret',
                nutrition: const NutritionModel(fatPer100g: 6),
              ),
            ),
          ),
        ],
      );

      final result = await repo.getProduct('3017620422003');

      expect(const FoodScoringEngine().score(result).score, isNull);
    },
  );

  test(
    'duplicate FatSecret providers do not make duplicate requests',
    () async {
      final storage = await storageWith({});
      final duplicate = _FakeProvider(
        'fatSecret',
        ProviderProductFound(_product('3017620422003', source: 'fatSecret')),
      );
      final repo = MultiSourceProductRepository(
        storage: storage,
        providers: [
          _FakeProvider(
            'openFoodFacts',
            ProviderProductFound(
              _product(
                '3017620422003',
                nutrition: const NutritionModel(energyKcalPer100g: 120),
              ),
            ),
          ),
          duplicate,
          _FakeProvider(
            'fatSecret',
            ProviderProductFound(
              _product('3017620422003', source: 'fatSecret'),
            ),
          ),
        ],
      );

      await repo.getProduct('3017620422003');

      expect(duplicate.calls, 1);
    },
  );

  test(
    'history stores merged result while FatSecret data stays out of local cache',
    () async {
      final storage = await storageWith({});
      final repo = MultiSourceProductRepository(
        storage: storage,
        providers: [
          _FakeProvider(
            'openFoodFacts',
            ProviderProductFound(
              _product(
                '3017620422003',
                nutrition: const NutritionModel(energyKcalPer100g: 120),
              ),
            ),
          ),
          _FakeProvider(
            'fatSecret',
            ProviderProductFound(
              _product(
                '3017620422003',
                source: 'fatSecret',
                nutrition: _complete(),
              ),
            ),
          ),
        ],
      );

      await repo.getProduct('3017620422003');

      expect(storage.getHistory().single.barcode, '3017620422003');
      expect(storage.getProductCache(), isEmpty);
    },
  );
}

class _FakeProvider implements FoodDataProvider {
  _FakeProvider(this.providerId, this.result);

  @override
  final String providerId;

  final ProviderProductResult result;
  int calls = 0;

  @override
  Future<ProviderProductResult> findByBarcode(String barcode) async {
    calls++;
    return result;
  }
}

FatSecretProvider _fatSecretProvider(Map<String, dynamic> body) {
  return FatSecretProvider(
    backendBaseUrl: Uri.parse('https://proxy.example'),
    regionFallbacks: const [''],
    client: MockClient((request) async {
      return http.Response(jsonEncode(body), 200);
    }),
  );
}

UnifiedProduct _product(
  String barcode, {
  String source = 'openFoodFacts',
  String name = 'Product',
  NutritionModel nutrition = const NutritionModel(),
}) {
  return UnifiedProduct(
    barcode: barcode,
    name: name,
    brand: 'Brand',
    nutrition: nutrition,
    primarySource: source,
    sourcesUsed: [source],
    fieldSources: {'name': source, 'nutrition': source},
    fetchedAt: DateTime(2026),
  );
}

NutritionModel _complete({double energy = 180}) {
  return NutritionModel(
    energyKcalPer100g: energy,
    fatPer100g: 6,
    saturatedFatPer100g: 1,
    carbohydratesPer100g: 20,
    sugarsPer100g: 5,
    proteinsPer100g: 4,
    fiberPer100g: 2,
  );
}
