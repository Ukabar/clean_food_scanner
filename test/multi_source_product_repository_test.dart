import 'package:clean_food_scanner/core/errors/app_exception.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:clean_food_scanner/data/models/nutrition_model.dart';
import 'package:clean_food_scanner/data/models/product_model.dart';
import 'package:clean_food_scanner/data/providers/food_data_provider.dart';
import 'package:clean_food_scanner/data/repositories/product_repository.dart';
import 'package:clean_food_scanner/data/services/product_merger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocalStorage> storageWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final storage = LocalStorage.instance;
    await storage.initialize();
    return storage;
  }

  UnifiedProduct product(
    String barcode, {
    String source = 'fakeA',
    String? name = 'Product',
    String? brand,
    List<String> allergens = const [],
    List<String> additives = const [],
    NutritionModel nutrition = const NutritionModel(
      sugarsPer100g: 4,
      saltPer100g: 0.2,
      saturatedFatPer100g: 1,
    ),
  }) {
    return UnifiedProduct(
      barcode: barcode,
      name: name,
      brand: brand,
      allergens: allergens,
      additives: additives,
      nutrition: nutrition,
      primarySource: source,
      sourcesUsed: [source],
      fieldSources: {'name': source, 'nutrition': source},
      fetchedAt: DateTime.now(),
    );
  }

  test('returns product from cache before calling providers', () async {
    final storage = await storageWith({});
    await storage.saveProduct(product('11111111'));
    final provider = _FakeProvider('fakeA', const ProviderProductNotFound());
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [provider],
    );

    final result = await repo.getProduct('11111111');

    expect(result.name, 'Product');
    expect(provider.calls, 0);
  });

  test('returns product found in first provider', () async {
    final storage = await storageWith({});
    final provider = _FakeProvider(
      'fakeA',
      ProviderProductFound(product('22222222')),
    );
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [provider],
    );

    final result = await repo.getProduct('22222222');

    expect(result.primarySource, 'fakeA');
    expect(provider.calls, 1);
  });

  test('falls back when first provider returns not found', () async {
    final storage = await storageWith({});
    final first = _FakeProvider('fakeA', const ProviderProductNotFound());
    final second = _FakeProvider(
      'fakeB',
      ProviderProductFound(product('33333333', source: 'fakeB')),
    );
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [first, second],
    );

    final result = await repo.getProduct('33333333');

    expect(result.primarySource, 'fakeB');
    expect(first.calls, 1);
    expect(second.calls, 1);
  });

  test('not found in all providers throws productNotFound', () async {
    final storage = await storageWith({});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider('fakeA', const ProviderProductNotFound()),
        _FakeProvider('fakeB', const ProviderProductNotFound()),
      ],
    );

    expect(
      repo.getProduct('44444444'),
      throwsA(
        isA<AppException>().having(
          (error) => error.type,
          'type',
          AppErrorType.productNotFound,
        ),
      ),
    );
  });

  test('invalid barcode stops provider chain', () async {
    final storage = await storageWith({});
    final first = _FakeProvider('fakeA', const ProviderInvalidBarcode());
    final second = _FakeProvider(
      'fakeB',
      ProviderProductFound(product('55555555')),
    );
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [first, second],
    );

    await expectLater(repo.getProduct('abc'), throwsA(isA<AppException>()));
    expect(second.calls, 0);
  });

  test('no internet stops provider chain', () async {
    final storage = await storageWith({});
    final first = _FakeProvider('fakeA', const ProviderNoConnection());
    final second = _FakeProvider(
      'fakeB',
      ProviderProductFound(product('66666666')),
    );
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [first, second],
    );

    await expectLater(
      repo.getProduct('66666666'),
      throwsA(
        isA<AppException>().having(
          (error) => error.type,
          'type',
          AppErrorType.noInternet,
        ),
      ),
    );
    expect(second.calls, 0);
  });

  test('timeout can fall back to next provider', () async {
    final storage = await storageWith({});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider('fakeA', const ProviderTimeout()),
        _FakeProvider(
          'fakeB',
          ProviderProductFound(product('77777777', source: 'fakeB')),
        ),
      ],
    );

    final result = await repo.getProduct('77777777');

    expect(result.primarySource, 'fakeB');
  });

  test('server failure can fall back to next provider', () async {
    final storage = await storageWith({});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider('fakeA', const ProviderServerFailure(500)),
        _FakeProvider(
          'fakeB',
          ProviderProductFound(product('88888888', source: 'fakeB')),
        ),
      ],
    );

    final result = await repo.getProduct('88888888');

    expect(result.primarySource, 'fakeB');
  });

  test('duplicate provider ids do not cause duplicate requests', () async {
    final storage = await storageWith({});
    final first = _FakeProvider('fakeA', const ProviderProductNotFound());
    final duplicate = _FakeProvider(
      'fakeA',
      ProviderProductFound(product('99999999')),
    );
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [first, duplicate],
    );

    await expectLater(
      repo.getProduct('99999999'),
      throwsA(isA<AppException>()),
    );

    expect(first.calls, 1);
    expect(duplicate.calls, 0);
  });

  test('merger fills missing field and preserves source metadata', () {
    const merger = ProductMerger();
    final primary = product('12121212', source: 'fakeA', brand: null);
    final secondary = product('12121212', source: 'fakeB', brand: 'Brand B');

    final merged = merger.merge(primary, secondary);

    expect(merged.brand, 'Brand B');
    expect(merged.fieldSources['brand'], 'fakeB');
    expect(merged.sourcesUsed, containsAll(['fakeA', 'fakeB']));
  });

  test('merger does not replace primary value', () {
    const merger = ProductMerger();
    final primary = product('13131313', source: 'fakeA', name: 'Primary');
    final secondary = product('13131313', source: 'fakeB', name: 'Secondary');

    final merged = merger.merge(primary, secondary);

    expect(merged.name, 'Primary');
  });

  test('merger rejects mismatched barcodes', () {
    const merger = ProductMerger();

    expect(
      () => merger.merge(product('14141414'), product('15151515')),
      throwsArgumentError,
    );
  });

  test('merger deduplicates allergens and additives', () {
    const merger = ProductMerger();
    final primary = product(
      '16161616',
      allergens: const ['milk', 'nuts'],
      additives: const ['e250'],
    );
    final secondary = product(
      '16161616',
      source: 'fakeB',
      allergens: const ['Milk', 'soy'],
      additives: const ['E250', 'e621'],
    );

    final merged = merger.merge(primary, secondary);

    expect(merged.allergens, ['milk', 'nuts', 'soy']);
    expect(merged.additives, ['e250', 'e621']);
  });

  test('corrupted cache does not crash repository', () async {
    final storage = await storageWith({'product_cache': '{bad-json'});
    final repo = MultiSourceProductRepository(
      storage: storage,
      providers: [
        _FakeProvider('fakeA', ProviderProductFound(product('17171717'))),
      ],
    );

    final result = await repo.getProduct('17171717');

    expect(result.barcode, '17171717');
  });
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
