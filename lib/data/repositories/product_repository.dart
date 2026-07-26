import '../../core/errors/app_exception.dart';
import '../../core/constants/app_constants.dart';
import '../local/local_storage.dart';
import '../models/product_model.dart';
import '../models/scan_history_item.dart';
import '../providers/food_data_provider.dart';
import '../services/fat_secret_provider.dart';
import '../services/food_scoring_engine.dart';
import '../services/open_food_facts_api.dart';
import '../services/product_data_completeness_evaluator.dart';
import '../services/product_merger.dart';

class MultiSourceProductRepository {
  MultiSourceProductRepository({
    List<FoodDataProvider>? providers,
    LocalStorage? storage,
    FoodScoringEngine? scoringEngine,
    ProductMerger? productMerger,
    ProductDataCompletenessEvaluator? completenessEvaluator,
    this.cacheDuration,
    this.fatSecretMemoryCacheDuration = const Duration(minutes: 15),
  }) : _providers = _dedupeProviders(providers ?? _defaultProviders()),
       _storage = storage ?? LocalStorage.instance,
       _scoringEngine = scoringEngine ?? const FoodScoringEngine(),
       _productMerger = productMerger ?? const ProductMerger(),
       _completenessEvaluator =
           completenessEvaluator ?? const ProductDataCompletenessEvaluator();

  final List<FoodDataProvider> _providers;
  final LocalStorage _storage;
  final FoodScoringEngine _scoringEngine;
  final ProductMerger _productMerger;
  final ProductDataCompletenessEvaluator _completenessEvaluator;
  final Map<String, _MemoryCachedProduct> _volatileProductCache = {};
  final Duration? cacheDuration;
  final Duration fatSecretMemoryCacheDuration;

  Future<UnifiedProduct> getProduct(String barcode) async {
    final cleanBarcode = barcode.trim();
    final volatile = _getVolatileCache(cleanBarcode);
    if (volatile != null) {
      await _recordHistory(volatile);
      return volatile;
    }
    final cached = _storage.getCachedProduct(
      cleanBarcode,
      maxAge: cacheDuration,
    );
    if (cached != null) {
      await _recordHistory(cached);
      return cached;
    }
    if (_storage.isNegativeCached(cleanBarcode)) {
      throw const AppException(
        AppErrorType.productNotFound,
        'Product not found.',
      );
    }

    ProviderProductResult? lastFailure;
    UnifiedProduct? primaryProduct;
    for (var index = 0; index < _providers.length; index++) {
      final provider = _providers[index];
      final result = await provider.findByBarcode(cleanBarcode);
      switch (result) {
        case ProviderProductFound(:final product):
          if (primaryProduct == null) {
            primaryProduct = product;
            if (_completenessEvaluator.evaluate(product).canCalculateScore ||
                index == _providers.length - 1) {
              await _cacheProduct(product);
              await _recordHistory(product);
              return product;
            }
            continue;
          }

          final merged = _productMerger.merge(primaryProduct, product);
          await _cacheProduct(merged);
          await _recordHistory(merged);
          return merged;
        case ProviderProductNotFound():
          lastFailure = result;
          if (primaryProduct != null) {
            await _cacheProduct(primaryProduct);
            await _recordHistory(primaryProduct);
            return primaryProduct;
          }
          continue;
        case ProviderTimeout():
        case ProviderServerFailure():
        case ProviderUnauthorized():
        case ProviderRateLimited():
          lastFailure = result;
          if (primaryProduct != null) {
            await _cacheProduct(primaryProduct);
            await _recordHistory(primaryProduct);
            return primaryProduct;
          }
          continue;
        case ProviderInvalidBarcode():
          throw const AppException(
            AppErrorType.invalidBarcode,
            'Invalid barcode.',
          );
        case ProviderNoConnection():
          if (primaryProduct != null) {
            await _cacheProduct(primaryProduct);
            await _recordHistory(primaryProduct);
            return primaryProduct;
          }
          final fallback = _storage.getAnyCachedProduct(cleanBarcode);
          if (fallback != null) return fallback;
          throw const AppException(
            AppErrorType.noInternet,
            'No internet connection.',
          );
        case ProviderMalformedResponse():
          if (primaryProduct != null) {
            await _cacheProduct(primaryProduct);
            await _recordHistory(primaryProduct);
            return primaryProduct;
          }
          throw const AppException(
            AppErrorType.invalidApiResponse,
            'Product information is temporarily unavailable.',
          );
      }
    }

    if (primaryProduct != null) {
      await _cacheProduct(primaryProduct);
      await _recordHistory(primaryProduct);
      return primaryProduct;
    }

    if (lastFailure is ProviderProductNotFound || lastFailure == null) {
      await _storage.saveNegativeCache(cleanBarcode);
      throw const AppException(
        AppErrorType.productNotFound,
        'Product not found.',
      );
    }
    if (lastFailure is ProviderTimeout) {
      throw const AppException(AppErrorType.timeout, 'Request timed out.');
    }
    throw const AppException(
      AppErrorType.unknown,
      'Product information is temporarily unavailable.',
    );
  }

  Future<void> recordDisplayedProduct(UnifiedProduct product) =>
      _recordHistory(product);

  Future<void> _cacheProduct(UnifiedProduct product) async {
    if (product.sourcesUsed.contains('fatSecret') ||
        product.primarySource == 'fatSecret') {
      _volatileProductCache[product.barcode] = _MemoryCachedProduct(
        product,
        DateTime.now().add(fatSecretMemoryCacheDuration),
      );
      return;
    }
    await _storage.saveProduct(product);
  }

  UnifiedProduct? _getVolatileCache(String barcode) {
    final cached = _volatileProductCache[barcode];
    if (cached == null) return null;
    if (DateTime.now().isAfter(cached.expiresAt)) {
      _volatileProductCache.remove(barcode);
      return null;
    }
    return cached.product.copyWith(isFromCache: true);
  }

  Future<void> _recordHistory(UnifiedProduct product) {
    final score = _scoringEngine.score(product);
    return _storage.upsertHistory(
      ScanHistoryItem(
        barcode: product.barcode,
        productName: product.name ?? 'Unnamed product',
        brand: product.brand,
        imageUrl: product.imageUrl,
        score: score.score?.round(),
        rating: score.rating,
        scannedAt: DateTime.now(),
      ),
    );
  }

  static List<FoodDataProvider> _dedupeProviders(
    List<FoodDataProvider> providers,
  ) {
    final seen = <String>{};
    final result = <FoodDataProvider>[];
    for (final provider in providers) {
      if (seen.add(provider.providerId)) result.add(provider);
    }
    return result;
  }

  static List<FoodDataProvider> _defaultProviders() {
    final providers = <FoodDataProvider>[OpenFoodFactsProvider()];
    final baseUrl = AppConstants.fatSecretProxyBaseUrl.trim();
    if (baseUrl.isNotEmpty) {
      providers.add(FatSecretProvider(backendBaseUrl: Uri.parse(baseUrl)));
    }
    return providers;
  }
}

typedef ProductRepository = MultiSourceProductRepository;

class _MemoryCachedProduct {
  const _MemoryCachedProduct(this.product, this.expiresAt);

  final UnifiedProduct product;
  final DateTime expiresAt;
}
