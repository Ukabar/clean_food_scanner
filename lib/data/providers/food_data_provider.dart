import '../models/product_model.dart';

abstract interface class FoodDataProvider {
  String get providerId;
  Future<ProviderProductResult> findByBarcode(String barcode);
}

sealed class ProviderProductResult {
  const ProviderProductResult();
}

class ProviderProductFound extends ProviderProductResult {
  const ProviderProductFound(this.product);

  final UnifiedProduct product;
}

class ProviderProductNotFound extends ProviderProductResult {
  const ProviderProductNotFound();
}

class ProviderInvalidBarcode extends ProviderProductResult {
  const ProviderInvalidBarcode();
}

class ProviderTimeout extends ProviderProductResult {
  const ProviderTimeout();
}

class ProviderNoConnection extends ProviderProductResult {
  const ProviderNoConnection();
}

class ProviderServerFailure extends ProviderProductResult {
  const ProviderServerFailure([this.statusCode]);

  final int? statusCode;
}

class ProviderUnauthorized extends ProviderProductResult {
  const ProviderUnauthorized();
}

class ProviderRateLimited extends ProviderProductResult {
  const ProviderRateLimited();
}

class ProviderMalformedResponse extends ProviderProductResult {
  const ProviderMalformedResponse();
}

class ExternalProviderPlaceholder implements FoodDataProvider {
  const ExternalProviderPlaceholder(this.providerId);

  @override
  final String providerId;

  @override
  Future<ProviderProductResult> findByBarcode(String barcode) {
    throw UnsupportedError(
      'Commercial providers that require secrets must be called from a backend.',
    );
  }
}
