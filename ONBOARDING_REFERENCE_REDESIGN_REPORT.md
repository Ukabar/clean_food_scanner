# Onboarding Reference Redesign Report

## Files changed

- `lib/features/onboarding/onboarding_screen.dart`
- `test/onboarding_visual_test.dart`
- `assets/onboarding/onboarding_scan.png`
- `assets/onboarding/onboarding_details.png`
- `assets/onboarding/onboarding_score.png`

## Files created

- `ONBOARDING_REFERENCE_REDESIGN_REPORT.md`

Temporary run logs were also produced by the phone launch attempt:

- `flutter_run_stdout.log`
- `flutter_run_stderr.log`

The cleanup command for those logs was blocked by the local command policy.

## Reference image usage

The attached screenshots were not used as full onboarding screens.

Only the upper illustration areas were cropped and saved as standalone onboarding illustration assets. The cropped assets do not include:

- page title
- page description
- bottom feature row
- page counter
- dots
- Next or Get Started button
- status bar
- system navigation bar

## Assets

- `assets/onboarding/onboarding_scan.png` - 725x785, cropped from the scan reference illustration.
- `assets/onboarding/onboarding_details.png` - 745x675, cropped from the ingredients/details reference illustration.
- `assets/onboarding/onboarding_score.png` - 745x790, cropped from the score/context reference illustration.

The score asset was edited so the label under `82` reads `Sample` instead of `Good Choice`.

## Layout

- Kept the existing single onboarding implementation.
- Kept `PageView`, `PageController`, and current onboarding completion flow.
- Bottom controls remain fixed below the `PageView`.
- The page body uses responsive height calculations and scroll support for short screens.
- Onboarding keeps a light off-white visual treatment even if the rest of the app uses dark mode.

## Typography and features

Pages now use the requested copy:

1. `Scan food products`
2. `Understand ingredients`
3. `Choose with more context`

Feature rows remain Flutter widgets, not part of the full screenshot.

## Bottom controls

- Left: `1 / 3`, `2 / 3`, `3 / 3`
- Center: animated page dots
- Right: `Next`, then `Get Started` on page 3
- Added semantics labels for the button, page counter, and page indicator.
- Bottom padding uses `MediaQuery.paddingOf(context).bottom`.

## Onboarding completion

`Get Started` still calls:

- `LocalStorage.instance.setOnboardingComplete(true)`
- `context.go('/')`

No routing, provider, scoring, product details, FatSecret, or Home behavior was changed.

## Tests

Updated onboarding tests cover:

- correct asset per page
- no reference status/navigation chrome as widgets
- Next navigation
- Get Started navigation and storage
- no overflow on `320x568`
- no overflow on `375x667`
- no overflow on `390x844`
- text scale `1.3`
- text scale `1.5`
- bottom controls above system navigation padding
- sample score not saved to history
- first-launch redirect behavior

## Verification

- `dart format lib/features/onboarding/onboarding_screen.dart test/onboarding_visual_test.dart` - passed.
- `flutter analyze` - passed, no issues found.
- `flutter test` - passed, 91 tests.
- `flutter build apk --debug` - passed.

APK output:

- `build/app/outputs/flutter-apk/app-debug.apk`

## Phone testing

Detected Android device:

- `23108RN04Y`, Android 15 API 35

`flutter install --debug -d GAOFQWYTAQLJJZYP` passed and installed the debug APK on the phone.

A short `flutter run -d GAOFQWYTAQLJJZYP` attempt reached the launch/build phase, but the automated background run was stopped after a short window and did not produce a final interactive verification result. Manual visual swiping through the onboarding screens was not performed by Codex.

## iOS

No iPhone, iOS Simulator, or TestFlight run was performed.

The implementation keeps Flutter/SafeArea/MediaQuery-based layout and does not add Android-only APIs, so no iOS-specific code risk was introduced.

## Remaining differences from the reference

- The illustrations are cropped PNG assets, not newly redrawn WebP/vector assets, because no local WebP/image generation tool was available in the environment.
- Some text inside the cropped illustration cards remains part of the illustration artwork.
- The external page titles, descriptions, feature rows, page counter, dots, and buttons are real Flutter widgets.
