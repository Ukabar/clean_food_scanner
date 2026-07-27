# iOS Readiness Report

Date: 2026-07-26

## Status Summary

Approximate readiness: 65%.

The iOS project has the minimum structure needed for Codemagic preparation, but it has not been built on macOS/Xcode yet. It is ready for CI setup and first iOS archive attempt, not ready for TestFlight or App Store submission.

## Bundle ID

Status: improved.

`PRODUCT_BUNDLE_IDENTIFIER` now uses `com.labelora.foodscanner` for the iOS Runner target. Confirm this Bundle ID exists in Apple Developer before creating signing files.

## Signing

Status: not configured locally.

Codemagic workflow uses App Store Connect integration and automatic signing file fetch. Required manual setup:

- Apple Developer account.
- App Store Connect API key/integration in Codemagic.
- Bundle ID registered in Apple Developer portal.
- App Store distribution certificate and provisioning profile, or allow Codemagic to create/fetch them.

## Info.plist

Status: mostly ready.

- `CFBundleDisplayName`: `Labelora: Food Scanner`.
- `NSCameraUsageDescription`: present and specific.
- No photo permission added.
- No broad ATS exception found.
- `CFBundleIdentifier` uses `$(PRODUCT_BUNDLE_IDENTIFIER)`.

## AppDelegate

Status: current Flutter scene-template style.

The project uses `FlutterAppDelegate`, `FlutterImplicitEngineDelegate`, and `GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)`. No manual plugin registrar or messenger access was found.

## Podfile

Status: added.

`ios/Podfile` now sets iOS 13.0, uses Flutter podhelper, installs Flutter iOS pods, and applies `flutter_additional_ios_build_settings`.

## Deployment Target

Status: iOS 13.0.

This is a stable baseline for the current Flutter/plugin set. Do not lower it without verifying `mobile_scanner` and all plugins.

## Plugin Compatibility

Status: needs CI confirmation.

Plugins relevant to iOS include camera/scanner, shared preferences, cached images, URL launcher, and package info. CocoaPods resolution must be verified on Codemagic or macOS.

## Icons And Launch Screen

Status: present but needs brand review.

`AppIcon.appiconset` and `LaunchScreen.storyboard` exist. App Store icon alpha/channel and final branding should be checked on macOS before submission.

## Privacy

Status: partially ready.

No secrets were found. Camera usage is declared. Privacy Policy and Terms URLs are placeholders in app constants and must be replaced before store review.

## App Store Policy Risks

- Placeholder legal links.
- Premium screen is a coming-soon placeholder; it does not activate purchases, but it should be reviewed before submission.
- Medical/health claims should remain educational and non-diagnostic.
- Open Food Facts attribution is present in settings and disclaimers.

## Codemagic Readiness

Status: workflow created, account-specific setup required.

`codemagic.yaml` is ready for first CI configuration but will not work until `APP_STORE_CONNECT_INTEGRATION_NAME` and signing setup exist in Codemagic.

## TestFlight Readiness

Status: not ready.

Needs successful iOS archive, signing, upload, and manual smoke testing.
