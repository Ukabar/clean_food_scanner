# Multi Provider Implementation Report

## Architecture

The app now keeps Open Food Facts as the primary product source and supports a second enrichment provider through a backend proxy only.

- `OpenFoodFactsProvider` remains the first provider.
- `FatSecretProvider` calls only a configured backend endpoint.
- `MultiSourceProductRepository` decides when to call the next provider.
- `ProductMerger` fills missing fields only.
- `ProductDataCompletenessEvaluator` decides whether nutrition data is sufficient for a real score.
- `FoodScoringEngine` now refuses to calculate a numeric score when data is insufficient or unrealistic.

FatSecret is enabled only when the non-secret build configuration `FATSECRET_PROXY_BASE_URL` is provided. No FatSecret Client ID, Client Secret, OAuth token generation, or token logging exists in Flutter.

## Why FatSecret Is Called

FatSecret is called only when:

- Open Food Facts returns `notFound`, or
- Open Food Facts returns a product but `ProductDataCompletenessEvaluator` says the product cannot receive a reliable score.

FatSecret is not called when Open Food Facts already has enough normalized nutrition fields.

If Open Food Facts returned a partial product and FatSecret fails, the app returns the partial Open Food Facts result and the score remains `Not enough data`.

## Completeness Rules

The evaluator requires all of the following before `FoodScoringEngine` can return a numeric score:

- `energyKcalPer100g` is present.
- At least 5 core nutrition fields are present.
- Sodium or salt counts as one core field.
- Values are normalized per 100 g or 100 ml before scoring.
- Values must not be negative or obviously unrealistic.

Core fields:

- energyKcal
- fat
- saturatedFat
- carbohydrates
- sugars
- protein
- sodium or salt
- fiber

## Merge Rules

Open Food Facts remains the primary source.

`ProductMerger`:

- Does not overwrite existing Open Food Facts values.
- Fills missing nutrition fields from FatSecret only after normalization.
- Preserves Open Food Facts as `primarySource`.
- Keeps `sourcesUsed` and `fieldSources` metadata internally.
- Rejects barcode mismatches.
- Avoids merging when product name or brand similarity shows a strong conflict.
- Deduplicates allergens and additives.

## Barcode Normalization

Added `normalizeToGtin13(String barcode)`.

Rules:

- Removes spaces and hyphens only.
- Rejects non-numeric content.
- Keeps values as `String`.
- Keeps EAN-13 unchanged.
- Converts UPC-A length 12 to GTIN-13 by adding a leading zero.
- Converts EAN-8 by left-padding zeros to length 13.
- Does not alter the original barcode stored for display.

## Backend Contract

Flutter expects the backend proxy to expose:

```http
GET /api/products/barcode/{gtin13}
```

Success:

```json
{
  "found": true,
  "barcode": "0611101850148",
  "product": {
    "name": "...",
    "brand": "...",
    "nutritionBasis": "per_100g",
    "energyKcal": 0,
    "fat": 0,
    "saturatedFat": 0,
    "carbohydrates": 0,
    "sugars": 0,
    "protein": 0,
    "fiber": null,
    "sodium": 0,
    "servingSizeGrams": 2
  }
}
```

Not found:

```json
{
  "found": false,
  "barcode": "..."
}
```

The backend must never return OAuth secrets or access tokens.

## Caching

Open Food Facts keeps the existing persistent local cache policy.

FatSecret data is not written to SharedPreferences by default. Products that include FatSecret data use a short in-memory cache in `MultiSourceProductRepository`.

This is intentional because FatSecret's official documentation and terms include attribution and storage restrictions:

- https://platform.fatsecret.com/attribution
- https://platform.fatsecret.com/terms
- https://platform.fatsecret.com/docs/guides/storable-data

## UI

No FatSecret attribution or provider name was added to Product Details.

The existing About text remains only:

```text
Uses Open Food Facts data.
```

FatSecret should not be shown in the UI until the account plan, attribution rules, store listing text, and display placement are reviewed.

## Modified Files

- `lib/core/constants/app_constants.dart`
- `lib/core/utils/barcode_normalizer.dart`
- `lib/data/models/nutrition_model.dart`
- `lib/data/models/product_model.dart`
- `lib/data/providers/food_data_provider.dart`
- `lib/data/repositories/product_repository.dart`
- `lib/data/services/fat_secret_provider.dart`
- `lib/data/services/food_scoring_engine.dart`
- `lib/data/services/product_data_completeness_evaluator.dart`
- `lib/data/services/product_merger.dart`
- `test/fat_secret_enrichment_test.dart`
- `test/food_scoring_engine_test.dart`

## Tests Added

Covered:

- Complete Open Food Facts product does not call FatSecret.
- Partial Open Food Facts product calls FatSecret.
- Open Food Facts not found and FatSecret found returns FatSecret.
- Both providers not found returns ProductNotFound.
- Partial Open Food Facts plus FatSecret timeout returns partial Open Food Facts.
- Conflicting nutrition preserves Open Food Facts primary values.
- UPC-A to GTIN-13 conversion.
- Leading zero preservation.
- FatSecret per serving without serving weight is ignored.
- FatSecret per serving with serving weight converts to per 100 g.
- Product name conflict prevents merge.
- Score is calculated after merge when enough fields exist.
- Score remains unavailable when merged data is still insufficient.
- Duplicate providers do not duplicate requests.
- History stores the displayed result while FatSecret data stays out of persistent local cache.

## Verification

- `dart format .`: passed.
- `flutter analyze`: passed with `No issues found!`.
- `flutter test`: passed with `70 tests`.
- `flutter build apk --debug`: passed.

APK:

```text
<project-root>\build\app\outputs\flutter-apk\app-debug.apk
```

APK size: `205,949,866 bytes`

Build warning: Flutter reported that `mobile_scanner` still applies the Kotlin Gradle Plugin directly. The APK build succeeded, but this plugin should be monitored/upgraded before future Flutter releases that require Built-in Kotlin plugin migration.

## External Setup Needed

To enable FatSecret enrichment in production:

- Create a secure backend proxy.
- Store FatSecret credentials only on the backend.
- Implement OAuth/token handling on the backend.
- Configure Flutter with a public backend base URL:

```bash
--dart-define=FATSECRET_PROXY_BASE_URL=https://your-backend.example
```

This value is not a secret, but it should point only to a backend that enforces its own abuse controls.

## Not Tested On iOS

iOS was not built or run in this Windows environment. The Dart-side implementation is platform-neutral, but iOS runtime behavior should still be tested on macOS before release.

## FatSecret Plan And Storage Constraints

FatSecret attribution and storage rules vary by account/plan and content type. Before displaying or persisting FatSecret-derived content beyond the short memory cache, review the active FatSecret contract and implement the required attribution in every place where FatSecret content is displayed.
