import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/local_storage.dart';
import 'models/product_model.dart';
import 'repositories/product_repository.dart';
import 'services/food_scoring_engine.dart';

final localStorageProvider = Provider<LocalStorage>(
  (ref) => LocalStorage.instance,
);

final scoringEngineProvider = Provider<FoodScoringEngine>(
  (ref) => const FoodScoringEngine(),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(
    storage: ref.watch(localStorageProvider),
    scoringEngine: ref.watch(scoringEngineProvider),
  ),
);

final productProvider = FutureProvider.family<ProductModel, String>((
  ref,
  barcode,
) {
  return ref.watch(productRepositoryProvider).getProduct(barcode);
});
