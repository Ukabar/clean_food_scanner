# IOS PLUGIN LINKING FIX REPORT

## Cause of the error

Codemagic reports:

```text
Unable to find a specification for `webview_flutter_wkwebview`
depended upon by `google_mobile_ads`
```

The current checked-out project does not contain `google_mobile_ads` in `pubspec.yaml`, `pubspec.lock`, `.flutter-plugins-dependencies`, Dart code, or iOS files. Because `google_mobile_ads` is absent, `webview_flutter_wkwebview` is not part of the current Flutter dependency graph and is not expected in `pubspec.lock` or `.flutter-plugins-dependencies`.

The actionable CI issue fixed here is that `codemagic.yaml` still had a standalone CocoaPods install step. That step was removed so `flutter build ipa` can run Flutter's iOS build flow and install Pods after `flutter pub get`.

If a new Codemagic build still prints the same `google_mobile_ads -> webview_flutter_wkwebview` error, Codemagic is building a stale commit, a different branch, or a different project state than this repository's current `main`.

## Final Podfile

```ruby
platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. Run flutter pub get first."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise 'FLUTTER_ROOT not found in Generated.xcconfig.'
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

## google_mobile_ads version

Requested version: none.

Resolved version: none.

`google_mobile_ads` is not present in the current dependency graph.

## webview_flutter_wkwebview version

Resolved version in this project: none.

`webview_flutter_wkwebview` is not present in `pubspec.lock` or `.flutter-plugins-dependencies` because `google_mobile_ads` is not present.

Local Pub cache contains podspecs for:

- `webview_flutter_wkwebview-3.23.5`
- `webview_flutter_wkwebview-3.24.2`
- `webview_flutter_wkwebview-3.24.5`
- `webview_flutter_wkwebview-3.25.1`
- `webview_flutter_wkwebview-3.26.0`

## Local podspec path

The package is not resolved for this project, so there is no project plugin path in `.flutter-plugins-dependencies`.

Available local Pub cache podspec paths include:

```text
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.23.5\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.24.2\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.24.5\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.25.1\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.26.0\darwin\webview_flutter_wkwebview.podspec
```

## Files modified

- `codemagic.yaml`
- `IOS_PLUGIN_LINKING_FIX_REPORT.md`

No manual Flutter plugin pods were added to `ios/Podfile`.

## codemagic.yaml changes

Removed the standalone step:

```text
Install CocoaPods dependencies
```

Removed standalone CocoaPods commands:

```text
pod install
pod install --repo-update
pod repo update
```

The workflow now runs:

1. `flutter pub get`
2. iOS project and plugin metadata verification
3. `flutter analyze`
4. `flutter test`
5. `xcode-project use-profiles`
6. `flutter build ipa --release`

`flutter build ipa` is now responsible for the Flutter iOS build flow, including CocoaPods installation on Codemagic/macOS.

## Git status

Current branch:

```text
main
```

Current commit before these uncommitted changes:

```text
50fa03d543dca418b16b84fbb08c6a8b75093891
50fa03d Harden Codemagic iOS dependency diagnostics
```

Tracked files verified:

```text
codemagic.yaml
ios/Podfile
pubspec.lock
```

`ios/Podfile` is not ignored by Git.

Existing unrelated untracked local folder:

```text
android/app/src/main/kotlin/com/labelora/clean_food_scanner/
```

## Validation results

`dart format .`:

```text
Formatted 57 files (0 changed)
```

`flutter analyze`:

```text
No issues found
```

`flutter test`:

```text
129 tests passed
```

`flutter build apk --debug`:

```text
Built build\app\outputs\flutter-apk\app-debug.apk
```

Non-blocking Android warnings:

```text
mobile_scanner applies Kotlin Gradle Plugin; future Flutter versions may require plugin migration.
SDK XML version warning from local Android tooling.
```

## Git commands

Recommended commands to upload only this fix:

```sh
git add IOS_PLUGIN_LINKING_FIX_REPORT.md codemagic.yaml
git commit -m "Let Flutter iOS build manage CocoaPods"
git push origin main
```

Do not include the unrelated untracked Android folder unless it is intentionally needed.

## Final note

Do not consider the iOS issue fully solved until a new Codemagic build succeeds.
