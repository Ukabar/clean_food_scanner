# iOS 15 Deployment Target Report

## Summary

The iOS minimum deployment target was raised from iOS 14.0 to iOS 15.0 for the Flutter iOS project.

This change addresses Apple's `ITMS-90068: MinimumOSVersion too low` warning.

## Targets Discovered

Targets found in `ios/Runner.xcodeproj/project.pbxproj`:

- `Runner`
- `RunnerTests`

Targets not found in the current iOS project:

- `EssentialLauncherWidget`
- Widget Extension
- Runner UI Tests
- Other app extensions

## Previous Values

- Xcode project deployment target: `IPHONEOS_DEPLOYMENT_TARGET = 14.0`
- Podfile platform: `platform :ios, '14.0'`

## New Values

- Xcode project deployment target: `IPHONEOS_DEPLOYMENT_TARGET = 15.0`
- Runner target Debug/Profile/Release: `IPHONEOS_DEPLOYMENT_TARGET = 15.0`
- RunnerTests target Debug/Profile/Release: `IPHONEOS_DEPLOYMENT_TARGET = 15.0`
- Podfile platform: `platform :ios, '15.0'`

## Files Modified

- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Podfile`
- `codemagic.yaml`
- `CODEMAGIC_COCOAPODS_FIX_REPORT.md`
- `CODEMAGIC_IOS_ROOT_CAUSE_REPORT.md`
- `IOS_PLUGIN_LINKING_FIX_REPORT.md`
- `IOS_CODEMAGIC_FULL_FIX_REPORT.md`
- `IOS_15_DEPLOYMENT_TARGET_REPORT.md`

## Widget Extension Status

No Widget Extension target exists in the current `ios/Runner.xcodeproj/project.pbxproj`.

Because no widget target exists, no widget deployment target, widget bundle ID, widget entitlements, or widget configuration was modified.

## Preserved Settings

The following settings were inspected and left unchanged:

- Main Bundle ID: `com.labelora.foodscanner`
- RunnerTests Bundle ID: `com.labelora.foodscanner.RunnerTests`
- Code signing settings
- Entitlements
- App icon configuration
- `TARGETED_DEVICE_FAMILY = "1,2"`
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`

No `MinimumOSVersion` key was added to `Info.plist`; the value remains derived from the Xcode deployment target.

## Codemagic

`codemagic.yaml` uses:

- `xcode: latest`

The Podfile validation check was updated to expect:

- `platform :ios, '15.0'`

## Remaining 14.0 Values

No remaining `IPHONEOS_DEPLOYMENT_TARGET = 14.0` values were found outside this report's historical "previous values" section.

No remaining `platform :ios, '14.0'` values were found outside this report's historical "previous values" section.

One unrelated Xcode metadata value remains:

- `CreatedOnToolsVersion = 14.0`

This is not an iOS minimum deployment target and was intentionally left unchanged.

## Verification Results

- `dart format .`: passed, `Formatted 57 files (0 changed)`
- `flutter analyze`: passed, `No issues found!`
- `flutter test`: passed, `129 tests passed`
- `flutter build apk --debug`: passed, `build\app\outputs\flutter-apk\app-debug.apk`

Non-blocking Android warnings during APK build:

- `mobile_scanner` applies Kotlin Gradle Plugin directly and may need a future plugin migration.
- Android SDK XML version warning from local Android tooling.

## iOS Build Note

iOS archive/build verification was not run locally because this workspace is on Windows. The change is limited to Xcode project and Podfile deployment target settings for Codemagic/Xcode to build on macOS.

## Files To Upload To GitHub

- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Podfile`
- `codemagic.yaml`
- `CODEMAGIC_COCOAPODS_FIX_REPORT.md`
- `CODEMAGIC_IOS_ROOT_CAUSE_REPORT.md`
- `IOS_PLUGIN_LINKING_FIX_REPORT.md`
- `IOS_CODEMAGIC_FULL_FIX_REPORT.md`
- `IOS_15_DEPLOYMENT_TARGET_REPORT.md`

## Git Commands

```sh
git add ios/Runner.xcodeproj/project.pbxproj ios/Podfile codemagic.yaml CODEMAGIC_COCOAPODS_FIX_REPORT.md CODEMAGIC_IOS_ROOT_CAUSE_REPORT.md IOS_PLUGIN_LINKING_FIX_REPORT.md IOS_CODEMAGIC_FULL_FIX_REPORT.md IOS_15_DEPLOYMENT_TARGET_REPORT.md
git commit -m "Raise iOS deployment target to 15"
git push
```
