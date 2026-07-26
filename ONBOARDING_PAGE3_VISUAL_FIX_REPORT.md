# Onboarding Page 3 Visual Fix Report

## Scope

Fixed only the third onboarding page: `Choose with more context`.

Pages 1 and 2, navigation, SharedPreferences flow, Home screen, scoring logic, and provider logic were not changed.

## Root Cause

- The third page used the same generic onboarding layout as the other pages, so its illustration was too constrained and left too much empty space.
- A custom sample score overlay drew an extra score ring on top of the image, which made the score graphic cover the right-side labels.
- The title used the generic responsive text rules, allowing `Choose with more context` to wrap on the target phone.
- The score illustration asset was not aligned with the requested reference proportions.
- The page background color did not match the reference asset background, making a rectangular image boundary visible.

## Files Modified

- `lib/features/onboarding/onboarding_screen.dart`
- `test/onboarding_visual_test.dart`
- `assets/onboarding/onboarding_score.png`
- `page3_screenshot.png` captured from the connected Android phone for visual verification

## Changes

- Added a dedicated prominent layout mode for the third onboarding page.
- Increased the third page illustration area while keeping it responsive.
- Removed the extra programmatic score ring overlay.
- Forced the third page title to stay on one line with `FittedBox`.
- Replaced the third page score illustration with a cleaner crop from the provided reference.
- Matched onboarding background to the reference image background to remove the visible square edge.
- Kept the requested text:
  - `Choose with more context`
  - `Get a simple score when enough product information is available.`
  - `Simple Product Score`
  - `Better Context`
  - `Clear Reasons`
- Added widget coverage to confirm the third page uses the score asset, keeps the title compact, shows a large illustration, and no longer renders the old overlay ring.

## Visual Check

Tested on connected Android phone:

- Device: `23108RN04Y`
- App package reset with `pm clear`
- Onboarding opened from first launch
- Navigated to page 3
- Screenshot captured at `page3_screenshot.png`

Observed result:

- Camera/score illustration is large and centered.
- No score ring overlaps the text labels.
- Title stays on one line.
- Bottom controls remain above system navigation.
- Third page matches the supplied reference much more closely.

## Verification

- `dart format .` passed.
- `flutter analyze` passed with `No issues found`.
- `flutter test` passed: `96` tests.
- `flutter build apk --debug` passed.
- `flutter run -d GAOFQWYTAQLJJZYP --no-resident` passed and installed/launched on the connected phone.

## Notes

- Build output still shows the existing Flutter warning that `mobile_scanner` applies the Kotlin Gradle Plugin. This is not caused by this change.
- iOS simulator/device was not run in this environment.
