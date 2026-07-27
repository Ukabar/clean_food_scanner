# Home Navigation Redesign Report

## Files changed

- `lib/app/app_shell.dart`
- `lib/app/router.dart`
- `lib/features/home/home_screen.dart`
- `pubspec.yaml`
- `test/home_navigation_redesign_test.dart`
- `test/manual_navigation_test.dart`
- `test/onboarding_visual_test.dart`

## Home redesign

- Rebuilt the Home screen to match the provided premium health-tech direction.
- Removed the top Settings button from Home.
- Added a header with the app icon and `Labelora: Food Scanner`.
- Added the hero copy:
  - `Scan smarter.`
  - `Choose better.`
  - `Understand ingredients, nutrition, and processing before you buy.`
- Added a large green scan card with scanner artwork, product lookup copy, and `Scan now`.
- Added a recent scans card with an empty state and `View all`.
- Added the app icon asset folder to `pubspec.yaml`.

## Quick actions order

Current Home quick action order:

1. Manual - `Enter a barcode`
2. Favorites - `View saved products`
3. History - `See recent scans`

Manual opens `/manual-barcode` only. It does not open the scanner.

## Bottom navigation order

The bottom navigation now uses:

1. Home - `/`
2. Scan - `/scanner`
3. Favorites - `/favorites`
4. History - `/history`
5. Settings - `/settings`

`More` was not added. Settings is available from the bottom navigation only.

## Navigation architecture

- Added `AppShell` for the main app tabs.
- Wrapped `/`, `/favorites`, `/history`, and `/settings` inside a `ShellRoute`.
- Kept `/scanner` outside the shell so the camera screen remains independent/fullscreen.
- Kept `/manual-barcode` outside the shell and independent from `/scanner`.
- Repeated taps on an already selected bottom tab do not push duplicate routes.

## Manual and scanner routes

- Scanner route: `/scanner`
- Manual barcode route: `/manual-barcode`

`Scan now` and the bottom `Scan` item open `/scanner`.
`Manual` opens `/manual-barcode`.

## Tests added or updated

- Home has no top Settings button.
- Bottom nav includes Home, Scan, Favorites, History, Settings.
- Bottom nav has no More item.
- Settings opens from bottom nav.
- Scan tab opens Scanner.
- Scan now opens Scanner.
- Manual opens Manual Barcode Entry route.
- Manual does not start camera.
- Quick actions are ordered Manual, Favorites, History.
- Recent scans empty state is shown.
- View all opens History.
- Small screen and large text scale do not overflow.
- Dark mode is supported.
- Repeated bottom tab tap does not duplicate navigation.
- Existing onboarding test updated for the new two-line Home title.

Leaving scanner stopping the camera is handled by the scanner screen lifecycle and `mobile_scanner`; it was not manually verified on a real device in this run because Android blocked installation.

## Verification results

- `dart format .` - passed, no pending formatting changes.
- `flutter analyze` - passed, no issues found.
- `flutter test` - passed, 87 tests.
- `flutter build apk --debug` - passed, built `build/app/outputs/flutter-apk/app-debug.apk`.

## Phone testing

- Device detected: `23108RN04Y`, Android 15 API 35.
- `flutter install --debug -d GAOFQWYTAQLJJZYP` failed because the phone rejected installation:
  - `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`

Because installation was blocked by the device, the Home -> Manual -> lookup -> back -> Scan now flow was not physically tested on the phone by Codex.

## Notes

- The design uses Flutter widgets and custom painters, not a static screenshot background.
- No iPhone/TestFlight testing was performed.
