# Home Visual Correction Report

## Files modified

- `lib/features/home/home_screen.dart`
- `lib/app/app_shell.dart`
- `pubspec.yaml`
- `test/home_navigation_redesign_test.dart`

## Files added

- `assets/home/home_hero_product.png`
- `HOME_VISUAL_CORRECTION_REPORT.md`

## Root causes

### Oversized title

The previous Home hero used a large `42px` title inside a constrained text area. On the phone width, each sentence wrapped internally, producing:

- `Scan`
- `smarter.`
- `Choose`
- `better.`

The corrected version uses responsive title sizes:

- small width: `27px`
- medium width: `31px`
- larger phone width: `35px`

The title is now built as two explicit lines:

- `Scan smarter.`
- `Choose better.`

### Cropped illustration

The previous illustration was drawn with `CustomPaint` inside a stack with a negative right offset. That made the right-side product appear clipped.

The corrected version uses a dedicated cropped illustration asset:

- `assets/home/home_hero_product.png`

It is displayed with `BoxFit.contain` in a bounded `SizedBox`, so it stays inside the screen.

### Bottom navigation covering content

`AppShell` previously used `extendBody: true`, allowing the bottom navigation to float over the page body. The Home content also needed explicit bottom padding.

The corrected version removes `extendBody: true` and keeps Home list bottom padding at:

- `MediaQuery.padding.bottom + 112`

## Previous measurements

- Hero title: fixed `42px`
- Hero area: stack-based, min height around `170`
- Hero illustration: `178x150` with negative right positioning
- Scan card: content-driven height with `26px` padding
- Quick action cards: `190px`
- Bottom navigation: overlaid because of `extendBody: true`

## New measurements

- Header logo: `40x40`
- Header title: `19px`, semibold
- Hero title: `27px`, `31px`, or `35px` depending on width
- Hero illustration:
  - small: `106x132`
  - medium: `132x154`
  - larger phone: `158x172`
- Scan card:
  - normal small: `250px`
  - normal medium: `202px`
  - normal larger phone: `218px`
  - expands for high text scale
- Quick actions:
  - normal: `174px`
  - small: `178px`
  - expands for high text scale
- Bottom nav no longer overlays the body from the shell.

## Navigation and behavior

- Bottom navigation order remains:
  1. Home
  2. Scan
  3. Favorites
  4. History
  5. Settings
- `More` is still removed.
- Settings remains reachable from bottom navigation only.
- Manual remains first quick action and opens `/manual-barcode`.
- `Scan now` opens `/scanner`.

## Tests added or updated

Updated Home tests verify:

- title area stays within two-line proportions
- hero illustration stays inside screen bounds
- scan card height stays in the expected range
- Manual, Favorites, History quick actions remain ordered correctly
- Recent scans is visible
- bottom nav does not cover quick actions
- no overflow on:
  - `360x800`
  - `390x844`
  - `430x932`
- no overflow with text scale `1.3`
- no overflow on small screen with text scale `1.5`

## Verification results

- `dart format .` - passed, no changes pending.
- `flutter analyze` - passed, no issues found.
- `flutter test` - passed, 95 tests.
- `flutter build apk --debug` - passed.

APK output:

- `build/app/outputs/flutter-apk/app-debug.apk`

## Phone test

Detected phone:

- `23108RN04Y`, Android 15 API 35

Phone installation failed:

- `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`

`flutter run -d GAOFQWYTAQLJJZYP --no-resident` also failed at the install step with the same error.

Because the phone blocked installation, the corrected interface was not visually confirmed on the real phone and no fresh screenshot was captured.

## Remaining visual difference risk

The implementation is much closer in proportions and fixes the confirmed problems, but I cannot claim it is visually identical to the reference until it is installed and viewed on the actual phone.
