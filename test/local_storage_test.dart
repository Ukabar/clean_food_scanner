import 'package:clean_food_scanner/core/constants/app_constants.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:clean_food_scanner/data/models/favorite_item.dart';
import 'package:clean_food_scanner/data/models/product_model.dart';
import 'package:clean_food_scanner/data/models/scan_history_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocalStorage> storageWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final storage = LocalStorage.instance;
    await storage.initialize();
    return storage;
  }

  test('corrupted history JSON returns an empty history', () async {
    final storage = await storageWith({'scan_history': '{not-json'});
    expect(storage.getHistory(), isEmpty);
  });

  test('corrupted product cache JSON returns an empty cache', () async {
    final storage = await storageWith({'product_cache': '{not-json'});
    expect(storage.getProductCache(), isEmpty);
  });

  test(
    'history upsert replaces duplicate scan and keeps newest first',
    () async {
      final storage = await storageWith({});
      await storage.upsertHistory(
        ScanHistoryItem(
          barcode: '3017620422003',
          productName: 'Old',
          scannedAt: DateTime(2026),
        ),
      );
      await storage.upsertHistory(
        ScanHistoryItem(
          barcode: '3017620422003',
          productName: 'New',
          scannedAt: DateTime(2026, 1, 2),
        ),
      );

      final history = storage.getHistory();
      expect(history, hasLength(1));
      expect(history.single.productName, 'New');
    },
  );

  test('history is limited to maxHistoryItems', () async {
    final storage = await storageWith({});
    for (var index = 0; index < AppConstants.maxHistoryItems + 5; index++) {
      await storage.upsertHistory(
        ScanHistoryItem(
          barcode: '1234567$index',
          productName: 'Product $index',
          scannedAt: DateTime(2026, 1, 1, 0, index),
        ),
      );
    }

    expect(storage.getHistory(), hasLength(AppConstants.maxHistoryItems));
  });

  test('favorites are stored separately from history', () async {
    final storage = await storageWith({});
    await storage.saveFavorites([
      FavoriteItem(
        barcode: '3017620422003',
        productName: 'Favorite',
        addedAt: DateTime(2026),
      ),
    ]);
    await storage.upsertHistory(
      ScanHistoryItem(
        barcode: '96385074',
        productName: 'History',
        scannedAt: DateTime(2026),
      ),
    );

    expect(storage.getFavorites().single.productName, 'Favorite');
    expect(storage.getHistory().single.productName, 'History');
  });

  test(
    'cached product expires but remains available as fallback cache',
    () async {
      final storage = await storageWith({});
      final product = ProductModel(
        barcode: '3017620422003',
        name: 'Cached',
        lastScannedAt: DateTime.now().subtract(AppConstants.cacheDuration * 2),
      );
      await storage.saveProduct(product);

      expect(storage.getCachedProduct(product.barcode), isNull);
      expect(storage.getAnyCachedProduct(product.barcode)?.name, 'Cached');
    },
  );
}
