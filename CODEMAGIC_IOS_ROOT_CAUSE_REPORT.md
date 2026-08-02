# CODEMAGIC IOS ROOT CAUSE REPORT

## 1. Real root cause

The repeated Codemagic error mentions:

```text
Unable to find a specification for `webview_flutter_wkwebview`
depended upon by `google_mobile_ads`
```

However, the current repository files on branch `main` do not contain `google_mobile_ads` in:

- `pubspec.yaml`
- `pubspec.lock`
- `.flutter-plugins-dependencies`
- `lib/`
- `ios/`
- `codemagic.yaml`

After `flutter clean` and `flutter pub get`, `webview_flutter_wkwebview` is still absent from `pubspec.lock` and `.flutter-plugins-dependencies` because it is not part of the current dependency graph.

Therefore, if Codemagic still prints that exact `google_mobile_ads` error, Codemagic is almost certainly building an older commit, an older branch, or a different workflow source than the current `main` commit.

## 2. ios/Podfile status before this correction

`ios/Podfile` existed and was tracked by Git.

It already had:

- `platform :ios, '14.0'`
- Flutter `podhelper`
- `flutter_ios_podfile_setup`
- `flutter_install_all_ios_pods`
- `flutter_additional_ios_build_settings`

It was missing the standard nested `RunnerTests` target.

## 3. Final Podfile content

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

## 4. Is platform iOS 14 present?

Yes.

```text
platform :ios, '14.0'
```

It is uncommented and present at the top of `ios/Podfile`.

## 5. google_mobile_ads version

Requested version: none.

Resolved version: none.

`google_mobile_ads` is not present in the current project.

## 6. webview_flutter_wkwebview version

Resolved version in this project: none.

The package exists in the local Pub cache in several versions, but none is resolved for this project because no dependency currently requires it.

## 7. Is webview_flutter_wkwebview present in pubspec.lock?

No.

Command result:

```text
Select-String -Path pubspec.lock -Pattern "webview_flutter_wkwebview"
No matches
```

This is expected for the current dependency graph because `google_mobile_ads` is absent.

## 8. Is webview_flutter_wkwebview present in .flutter-plugins-dependencies?

No.

Command result:

```text
Select-String -Path .flutter-plugins-dependencies -Pattern "webview_flutter_wkwebview"
No matches
```

This is expected for the current dependency graph because `google_mobile_ads` is absent.

## 9. Pub Cache package path

Local Pub cache contains these podspec files:

```text
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.23.5\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.24.2\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.24.5\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.25.1\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.26.0\darwin\webview_flutter_wkwebview.podspec
```

No project-resolved package path exists in `.flutter-plugins-dependencies`.

## 10. Does the package podspec exist?

Yes, in the local Pub cache versions listed above.

No, not as a resolved plugin for this project.

## 11. codemagic.yaml changes

The verification step was renamed to:

```text
Verify iOS project and plugins
```

It now prints:

- current commit
- current branch
- full first 200 lines of `ios/Podfile`

It verifies:

- `ios/Podfile`
- `platform :ios, '14.0'`
- `flutter_install_all_ios_pods`
- `ios/Flutter/Generated.xcconfig`
- `pubspec.lock`
- `.flutter-plugins-dependencies`

It checks `webview_flutter_wkwebview` only if `google_mobile_ads` exists in `pubspec.lock`.

The CocoaPods step now removes stale local symlinks before installation:

```sh
cd ios
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock
pod install --repo-update --verbose
cd ..
```

## 12. Was pod install duplicated?

No.

Current `codemagic.yaml` contains one CocoaPods install command:

```text
pod install --repo-update --verbose
```

There is no separate `pod repo update`.

## 13. Current branch

```text
main
```

## 14. Current commit

Current checked-out commit before the new uncommitted fixes:

```text
0976ae6573912c0a9047680068a3c06f246eecd2
0976ae6 Fix Codemagic iOS CocoaPods configuration
```

The new changes in this report are not committed or pushed yet.

## 15. Is Podfile tracked in Git?

Yes.

```text
git ls-files ios/Podfile
ios/Podfile
```

`codemagic.yaml`, `pubspec.lock`, and `android/gradle.properties` are also tracked.

Generated files are intentionally ignored:

```text
.flutter-plugins-dependencies
ios/Flutter/Generated.xcconfig
```

Codemagic regenerates them after `flutter pub get`.

## 16. Modified files

Modified by this pass:

- `ios/Podfile`
- `codemagic.yaml`
- `android/gradle.properties`
- `CODEMAGIC_IOS_ROOT_CAUSE_REPORT.md`

Existing untracked local file/folder not included in this iOS/Codemagic scope:

- `android/app/src/main/kotlin/com/labelora/clean_food_scanner/`

## 17. flutter analyze result

Passed.

```text
Analyzing clean_food_scanner...
No issues found! (ran in 91.9s)
```

## 18. flutter test result

Passed.

```text
129 tests passed
```

## 19. APK build result

Passed.

```text
Built build\app\outputs\flutter-apk\app-debug.apk
```

Non-blocking warning:

```text
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): mobile_scanner
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
```

## 20. Git commands required to upload the changes

Do not include the unrelated untracked Android package folder unless it is intentionally needed.

Recommended commands:

```sh
git add CODEMAGIC_IOS_ROOT_CAUSE_REPORT.md codemagic.yaml ios/Podfile android/gradle.properties
git commit -m "Harden Codemagic iOS dependency diagnostics"
git push origin main
```

## 21. Final verdict

Ready for Codemagic build.

Important qualification:

This project is ready for a new Codemagic build from the current `main` branch after committing and pushing the new changes. It is not possible to claim that the iOS archive problem is fully solved until a new Codemagic build succeeds.

If the same `google_mobile_ads -> webview_flutter_wkwebview` error appears again after these changes are pushed, Codemagic is not building the current repository state.
