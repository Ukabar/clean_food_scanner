# Multi-Provider Report

Date: 2026-07-26

## Files Modified

- `lib/data/models/product_model.dart`
- `lib/data/providers/food_data_provider.dart`
- `lib/data/services/open_food_facts_api.dart`
- `lib/data/services/product_merger.dart`
- `lib/data/repositories/product_repository.dart`
- `lib/data/local/local_storage.dart`
- `lib/features/product/product_result_screen.dart`
- `test/multi_source_product_repository_test.dart`
- Existing affected tests after model changes.
- `MULTI_PROVIDER_ARCHITECTURE.md`
- `MULTI_PROVIDER_REPORT.md`

## New Abstraction

Added:

```dart
abstract interface class FoodDataProvider {
  String get providerId;
  Future<ProviderProductResult> findByBarcode(String barcode);
}
```

Added explicit provider result types for found, notFound, invalidBarcode, timeout, noConnection, serverFailure, unauthorized, and malformedResponse.

## Active Providers

Current active order:

1. Local cache
2. Open Food Facts

No second provider is active. Fake providers exist only in tests.

## Fallback Policy

- `notFound`: continue.
- `timeout`: continue.
- `serverFailure`: continue.
- `unauthorized`: continue.
- `invalidBarcode`: stop.
- `noConnection`: stop.
- `malformedResponse`: stop with temporary/unavailable information.

## Merge Policy

`ProductMerger` fills only missing fields, keeps primary values, rejects barcode mismatches, deduplicates allergens/additives, preserves metadata, and does not merge nutrition until unit normalization exists.

## Error Cases

User-facing behavior:

- All providers not found: Product not found.
- No internet: No internet connection.
- Server/malformed provider issue: Product information is temporarily unavailable.

## Tests

Added coverage for:

- Cache hit before providers.
- First provider success.
- First not found, second success.
- Not found in all providers.
- Invalid barcode stops chain.
- No internet stops chain.
- Timeout fallback.
- Server failure fallback.
- Duplicate provider IDs.
- Product merger missing-field fill.
- Product merger primary value preservation.
- Barcode mismatch rejection.
- Allergen/additive deduplication.
- Source metadata.
- Corrupted cache safety.

## Verification Results

Last completed before this report:

- `flutter analyze`: passed.
- `flutter test`: passed with 49 tests.

- `flutter build apk --debug`: passed.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`
- APK size: `205,928,583 bytes`

## Adding USDA Or FatSecret Later

Required work:

- Create a backend endpoint.
- Store provider keys only on the backend.
- Add a backend-backed `FoodDataProvider` in Flutter that calls your own API.
- Normalize response to `UnifiedProduct`.
- Add tests for provider mapping and error states.
- Add server-side monitoring and quota handling.

## What Needs Backend

- Any API requiring secrets.
- OAuth/token exchange.
- Paid API quota management.
- Request signing.
- Cross-provider enrichment.
- Server-side caching if provider terms allow it.

## iOS And App Store Risks

- Do not ship API secrets in the iOS app bundle.
- Privacy policy must disclose data sources and network calls.
- If commercial nutrition providers are added, review licensing and attribution.
- If backend is added, review App Store privacy questionnaire and data collection claims.
