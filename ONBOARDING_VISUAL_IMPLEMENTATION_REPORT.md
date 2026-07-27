# Onboarding Visual Implementation Report

## Image Preparation

The three onboarding illustrations were created as independent transparent PNG assets inside the project. They are not screenshots and do not include a status bar, system navigation bar, page indicator, onboarding buttons, or page title/description text.

The assets use a warm light visual style with soft white cards, calm green accents, botanical decorations, and simple health-tech UI illustrations.

The first page scan line is animated in Flutter rather than baked into the image, so the asset remains a clean static illustration and the animation stays controlled by the app.

## Assets

All assets are stored in:

```text
assets/onboarding/
```

Files:

- `assets/onboarding/onboarding_scan.png`
- `assets/onboarding/onboarding_details.png`
- `assets/onboarding/onboarding_score.png`

Dimensions:

- `1200 x 900`

Format:

- PNG with transparent background.

## Screen Implementation

Updated `OnboardingScreen` to use:

- `SafeArea`
- `Column`
- `Expanded(PageView)`
- fixed bottom controls area with system bottom padding
- `LayoutBuilder`
- flexible illustration sizing
- `SingleChildScrollView` for short screens and large text scale

The onboarding background is intentionally fixed to a warm light color, even if the app is in dark mode, matching the design requirement for first launch.

## Text Content

Page 1:

- Title: `Scan food products`
- Description: `Use your camera to scan product barcodes and view available food information.`
- Features: `Ingredient Details`, `Product Insights`, `Smarter Choices`

Page 2:

- Title: `Understand ingredients`
- Description: `Review nutrition, additives, allergens, and processing information.`
- Features: `Clear Breakdown`, `Potential Concerns`, `Informed Choices`

Page 3:

- Title: `Choose with more context`
- Description: `Get a simple score when enough product information is available.`
- Features: `Simple Product Score`, `Better Context`, `Clear Reasons`

The score value `82` is only part of the illustration. The asset labels it as `Sample`, and it is not connected to product data, history, or scanning.

## Responsive Behavior

The layout was built for:

- `320 x 568`
- `375 x 667`
- `390 x 844`
- larger iPhone and tall Android screens

On shorter screens:

- the illustration scales down
- spacing is reduced
- the bottom button remains visible
- content may scroll internally when needed

The bottom controls use `MediaQuery.paddingOf(context).bottom` so they stay above system navigation.

## Animations

Page 1:

- Flutter overlay animates the scan line vertically.

Page 2:

- The analysis rows are represented in the asset; no heavy animation was added to keep the first-launch flow light.

Page 3:

- Flutter overlay animates the sample score ring to `82%`.

Animations stop or collapse when `MediaQuery.disableAnimationsOf(context)` is true.

## Accessibility

- Image assets are excluded from their own semantics.
- The illustration wrapper provides a concise semantic label.
- Page titles, descriptions, features, and buttons remain real Flutter widgets.
- The layout was tested at text scale `1.5`.

## Modified Files

- `pubspec.yaml`
- `lib/features/onboarding/onboarding_screen.dart`
- `test/onboarding_visual_test.dart`
- `assets/onboarding/onboarding_scan.png`
- `assets/onboarding/onboarding_details.png`
- `assets/onboarding/onboarding_score.png`

## Tests

Added `test/onboarding_visual_test.dart` covering:

- correct asset per page
- no reference phone chrome as Flutter widgets
- `Next` moves between pages
- third page shows `Get Started`
- no overflow on `320 x 568`
- no overflow with text scale `1.5`
- bottom controls stay above system navigation padding
- third page includes a sample score indicator
- onboarding appears only on first launch
- `Get Started` opens Home and saves onboarding state

## Verification

- `dart format .`: passed.
- `flutter analyze`: passed with `No issues found!`.
- `flutter test`: passed with `78 tests`.
- `flutter build apk --debug`: passed.

APK:

```text
<project-root>\build\app\outputs\flutter-apk\app-debug.apk
```

APK size: `205,964,079 bytes`.

Build warning: Flutter reported that `mobile_scanner` still applies the Kotlin Gradle Plugin directly. The APK build succeeded, but this dependency should be upgraded when a Built-in Kotlin compatible version is available.

## Real Device Test

Flutter detected this Android device:

```text
23108RN04Y (mobile) - Android 15 (API 35)
```

Attempted install:

```text
flutter install --debug -d GAOFQWYTAQLJJZYP
```

Result:

```text
INSTALL_FAILED_USER_RESTRICTED: Install canceled by user
```

The APK was not installed or manually verified on the phone because Android rejected the install from the device side.
