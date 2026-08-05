# App Version Fix Report

## Summary

App Store Connect rejected the previous upload because version train `1.0.0` is closed:

- `90062`: `CFBundleShortVersionString [1.0.0]` must be higher than the previously approved version `1.0.0`.
- `90186`: pre-release train `1.0.0` is closed.

The project app version has been raised to:

- Version: `1.0.1`
- Build Number: `10`

## Old Values

- Previous app version in `pubspec.yaml`: `1.0.0+2`
- Previous Flutter build-name: `1.0.0`
- Previous Flutter build-number: `2`
- Previous expected `CFBundleShortVersionString`: `1.0.0`
- Previous expected `CFBundleVersion`: `2`

## New Values

- New app version in `pubspec.yaml`: `1.0.1+10`
- New Flutter build-name: `1.0.1`
- New Flutter build-number: `10`
- New expected `CFBundleShortVersionString`: `1.0.1`
- New expected `CFBundleVersion`: `10` or higher in Codemagic

## Files Inspected

- `pubspec.yaml`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner/Info.plist`
- `ios/Flutter/Generated.xcconfig`
- `codemagic.yaml`
- `lib/features/settings/settings_screen.dart`

## Files Modified

- `pubspec.yaml`
- `codemagic.yaml`
- `lib/features/settings/settings_screen.dart`
- `APP_VERSION_FIX_REPORT.md`

## Exact Changes

### `pubspec.yaml`

Changed:

```yaml
version: 1.0.0+2
```

to:

```yaml
version: 1.0.1+10
```

### `codemagic.yaml`

Added explicit version variables:

```yaml
APP_BUILD_NAME: 1.0.1
MIN_BUILD_NUMBER: 10
```

Updated `flutter build ipa` to pass:

```sh
--build-name="$APP_BUILD_NAME"
--build-number="$EFFECTIVE_BUILD_NUMBER"
```

`EFFECTIVE_BUILD_NUMBER` is calculated from `PROJECT_BUILD_NUMBER`, but is floored to `10` if Codemagic provides a lower value.

Added `Verify app version inputs` before building to print and validate:

- `pubspec.yaml` version
- `FLUTTER_BUILD_NAME`
- `FLUTTER_BUILD_NUMBER`
- `PROJECT_BUILD_NUMBER`
- effective build number

Extended IPA verification to unzip the generated IPA and read:

- `Payload/*.app/Info.plist` `CFBundleShortVersionString`
- `Payload/*.app/Info.plist` `CFBundleVersion`

The workflow now fails if:

- `CFBundleShortVersionString != 1.0.1`
- `CFBundleVersion < 10`

### `ios/Runner/Info.plist`

No direct value was hardcoded.

It already correctly uses:

```xml
<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>
<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>
```

### `ios/Runner.xcodeproj/project.pbxproj`

No application version override was added.

Runner continues to use:

- `CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)"`

### `lib/features/settings/settings_screen.dart`

Fallback display text was updated from `1.0.0` to `1.0.1`.

## Local Generated Values

After `flutter pub get`, `ios/Flutter/Generated.xcconfig` contains:

```text
FLUTTER_BUILD_NAME=1.0.1
FLUTTER_BUILD_NUMBER=10
```

## Remaining `1.0.0` Search

Remaining `1.0.0` values are not app versions:

- `android/settings.gradle.kts`: Flutter Gradle plugin loader version `1.0.0`
- `pubspec.lock`: dependency package versions `1.0.0`

These were intentionally not changed because changing dependency/plugin versions would be unrelated and risky.

No remaining app version reference to `1.0.0` was found.

## Verification Results

- `flutter clean`: passed
- `flutter pub get`: passed
- `flutter analyze`: passed, `No issues found!`
- `flutter test`: passed, `129 tests passed`

## IPA Verification

An iOS IPA cannot be built or inspected locally in this Windows workspace.

Codemagic now performs the required final IPA verification automatically after `flutter build ipa`:

- Unzips `build/ios/ipa/*.ipa`
- Reads `Payload/*.app/Info.plist`
- Prints `CFBundleShortVersionString`
- Prints `CFBundleVersion`
- Fails the build if the packaged version is not `1.0.1`
- Fails the build if the packaged build number is lower than `10`

Expected final IPA values:

- `CFBundleShortVersionString = 1.0.1`
- `CFBundleVersion >= 10`

## App Store Connect Readiness

The project configuration is ready for a new Codemagic upload to App Store Connect with version train `1.0.1`.

Final success must be confirmed by the next Codemagic macOS build, because that is where the signed IPA is produced and inspected.
