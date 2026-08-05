# iOS Codemagic CocoaPods/SPM Fix Report

## Root Cause

Codemagic was seeing a mixed iOS dependency setup:

- The project had a CocoaPods `ios/Podfile`.
- `ios/Runner.xcodeproj/project.pbxproj` still referenced Flutter's generated Swift Package:
  - `FlutterGeneratedPluginSwiftPackage`
  - `XCLocalSwiftPackageReference`
  - `XCSwiftPackageProductDependency`
- Codemagic then ran CocoaPods and Xcode with stale or conflicting CocoaPods state, causing:

```text
The sandbox is not in sync with the Podfile.lock.
```

The fix keeps the project on CocoaPods only for iOS and disables Flutter Swift Package Manager.

## Files Inspected

- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `codemagic.yaml`
- `ios/Podfile`
- `ios/Podfile.lock`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner.xcworkspace`
- `ios/Flutter/`
- `.gitignore`

## Dependency System Status

Before:

- CocoaPods integration: present through `ios/Podfile`
- Flutter Swift Package Manager references: present in Xcode project
- `ios/Podfile.lock`: absent in repository

After:

- CocoaPods integration: kept
- Flutter Swift Package Manager: disabled
- Flutter SPM Xcode references: removed
- `ios/Podfile.lock`: still not committed; Codemagic regenerates it in the reset step

## Files Modified

- `pubspec.yaml`
- `analysis_options.yaml`
- `codemagic.yaml`
- `.gitignore`
- `ios/Runner.xcodeproj/project.pbxproj`
- `IOS_CODEMAGIC_COCOAPODS_SPM_FIX_REPORT.md`

## Exact Changes

### `pubspec.yaml`

Added Flutter configuration without creating a duplicate `flutter:` section:

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

Existing `uses-material-design` and assets were preserved.

### `ios/Runner.xcodeproj/project.pbxproj`

Removed only Flutter SPM references:

- `FlutterGeneratedPluginSwiftPackage in Frameworks`
- `FlutterGeneratedPluginSwiftPackage` file reference
- Runner `packageProductDependencies`
- Project `packageReferences`
- `XCLocalSwiftPackageReference`
- `XCSwiftPackageProductDependency`

No Bundle IDs, signing settings, entitlements, icons, or device family settings were changed.

### `analysis_options.yaml`

Merged required analyzer exclusions into the existing `analyzer:` section:

```yaml
analyzer:
  exclude:
    - audit_backups/**
    - build/**
    - ios/Pods/**
    - ios/.symlinks/**
    - ios/Flutter/**
    - ios/SourcePackages/**
    - .dart_tool/**
    - macos/Pods/**
```

### `.gitignore`

Added explicit generated iOS/CocoaPods ignores:

```gitignore
build/
ios/Pods/
ios/.symlinks/
ios/SourcePackages/
```

### `codemagic.yaml`

Preserved:

- App Store Connect integration: `SpeedTeste`
- iOS signing configuration
- Bundle ID: `com.labelora.foodscanner`
- Environment variables
- Publishing configuration
- Email notifications
- Artifact paths
- App icon verification
- IPA verification

Changed:

- Added a Flutter config step to disable SPM.
- Changed analysis from `flutter analyze` to `flutter analyze lib`.
- Added a single `Reset iOS CocoaPods` step before signing/build.
- Kept `xcode-project use-profiles` after CocoaPods reset.
- Made IPA build use `/Users/builder/export_options.plist` only when it exists.

## Final Codemagic Script Order

1. `Show build environment`
2. `Set Flutter configuration`
3. `Clean Flutter build artifacts`
4. `Get Flutter packages`
5. `Verify iOS project and plugins`
6. `Analyze project`
7. `Run Flutter tests`
8. `Reset iOS CocoaPods`
9. `Set up iOS code signing`
10. `Verify iOS Bundle Identifier`
11. `Verify iPhone and iPad support`
12. `Verify iOS app icons have no alpha`
13. `Build signed IPA`
14. `Verify generated IPA`

## Important Script Blocks

### Set Flutter Configuration

```yaml
- name: Set Flutter configuration
  script: |
    flutter config --no-enable-swift-package-manager
```

### Analyze Project

```yaml
- name: Analyze project
  script: |
    rm -rf build
    flutter analyze lib
```

### Reset iOS CocoaPods

```yaml
- name: Reset iOS CocoaPods
  script: |
    set -e

    flutter config --no-enable-swift-package-manager

    rm -rf build
    rm -rf ios/Pods
    rm -rf ios/.symlinks
    rm -rf ~/Library/Developer/Xcode/DerivedData/*

    flutter pub get

    cd ios
    pod deintegrate || true
    rm -f Podfile.lock
    pod install --repo-update
    cd ..
```

### Build Signed IPA

```yaml
- name: Build signed IPA
  script: |
    if [ -f /Users/builder/export_options.plist ]; then
      flutter build ipa --release \
        --build-number="$PROJECT_BUILD_NUMBER" \
        --export-options-plist=/Users/builder/export_options.plist
    else
      flutter build ipa --release \
        --build-number="$PROJECT_BUILD_NUMBER"
    fi
```

## Swift Package Manager Disabled?

Yes.

- `pubspec.yaml` sets `enable-swift-package-manager: false`.
- Local `flutter config --no-enable-swift-package-manager` succeeded.
- Generated `.flutter-plugins-dependencies` reports:
  - `"swift_package_manager_enabled":{"ios":false,"macos":false}`
- Flutter SPM references were removed from `ios/Runner.xcodeproj/project.pbxproj`.

## CocoaPods Only?

Yes for the iOS build path.

- `ios/Podfile` is present.
- `platform :ios, '15.0'` is present.
- `flutter_ios_podfile_setup` is present.
- `flutter_install_all_ios_pods` is present in target `Runner`.
- Codemagic now runs `pod install --repo-update` after removing stale `ios/Pods`, `.symlinks`, and `Podfile.lock`.

## Local Verification

- `flutter config --no-enable-swift-package-manager`: passed
- `flutter pub get`: passed
- `flutter analyze lib`: passed, `No issues found!`
- `flutter test`: passed, `129 tests passed`

## iOS/CocoaPods Verification

Not run locally because this workspace is Windows and does not provide CocoaPods/Xcode.

Codemagic on macOS will run:

```sh
cd ios
pod deintegrate || true
rm -f Podfile.lock
pod install --repo-update
cd ..
```

## Remaining Errors

No remaining Flutter SPM references were found in the Xcode project.

No local Dart analysis or test failures remain.

The final iOS archive result must be confirmed by a new Codemagic build on macOS.

## Files To Upload To GitHub

- `pubspec.yaml`
- `analysis_options.yaml`
- `codemagic.yaml`
- `.gitignore`
- `ios/Runner.xcodeproj/project.pbxproj`
- `IOS_CODEMAGIC_COCOAPODS_SPM_FIX_REPORT.md`
