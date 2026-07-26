# Multi-Provider Product Data Architecture

## Goal

Clean Food Scanner now has a provider abstraction for product lookup without adding any commercial API or secrets to the Flutter app.

Current active order:

1. Local cache
2. Open Food Facts

No second live provider is enabled.

## Core Abstraction

```dart
abstract interface class FoodDataProvider {
  String get providerId;
  Future<ProviderProductResult> findByBarcode(String barcode);
}
```

Provider results are explicit sealed types:

- `ProviderProductFound`
- `ProviderProductNotFound`
- `ProviderInvalidBarcode`
- `ProviderTimeout`
- `ProviderNoConnection`
- `ProviderServerFailure`
- `ProviderUnauthorized`
- `ProviderMalformedResponse`

The repository never uses `null` to represent these states.

## Unified Product

The app uses `UnifiedProduct` as the internal product model. `ProductModel` remains as a compatibility alias for the existing UI.

`UnifiedProduct` includes:

- Product fields such as barcode, name, brand, image, ingredients, allergens, additives, nutrition, Nutri-Score, NOVA, quantity, serving size, and completeness.
- `primarySource`
- `sourcesUsed`
- `fieldSources`
- `fetchedAt`
- `schemaVersion`

## Fallback Policy

`MultiSourceProductRepository` follows this policy:

- Cache hit: return immediately.
- `notFound`: try next provider.
- `timeout`: try next provider.
- `serverFailure`: try next provider.
- `unauthorized`: continue to next provider.
- `invalidBarcode`: stop immediately.
- `noConnection`: stop and surface no-internet.
- `malformedResponse`: stop and surface temporary/unavailable product information, not product-not-found.

Duplicate provider IDs are ignored to avoid duplicate requests.

## Product Merging

`ProductMerger` is independent and unit tested.

Rules:

- Never replace an existing valid primary value with `null`.
- Never automatically replace a primary value with a different secondary value.
- Fill missing fields only.
- Reject mismatched barcodes.
- Do not merge nutrition from a secondary provider until unit normalization exists.
- Preserve field source metadata.
- Deduplicate allergens and additives.
- Do not treat an empty allergen/additive list as proof that none exist.

No enrichment from a second provider is active today.

## Cache

Local cache stores unified products including:

- Source metadata.
- `fetchedAt`.
- `schemaVersion`.

Negative product-not-found cache is separate and short-lived. It is not stored forever.

## Secrets And Commercial Providers

Commercial providers such as USDA, FatSecret, GS1, or nutrition databases that require API secrets must not be called directly from Flutter.

Do not put secrets in:

- Dart source.
- Assets.
- Bundled `.env`.
- `Info.plist`.
- `AndroidManifest.xml`.
- `codemagic.yaml` as plaintext.

Use a backend to:

- Store secrets.
- Sign requests.
- Enforce quotas and abuse protection.
- Normalize provider responses.
- Merge and audit field sources server-side if needed.

Codemagic secrets should be stored only as protected environment variables or integrations.

