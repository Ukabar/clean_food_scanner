# IOS CODEMAGIC FULL FIX REPORT

## 1. Real root cause

The current repository on branch `main` does not contain `google_mobile_ads` in `pubspec.yaml`, `pubspec.lock`, `.flutter-plugins-dependencies`, `lib/`, `ios/`, or `android/`.

Because `google_mobile_ads` is absent, `webview_flutter_wkwebview` is not part of the current dependency graph. If Codemagic still prints:

```text
Unable to find a specification for `webview_flutter_wkwebview`
depended upon by `google_mobile_ads`
```

then Codemagic is building a stale commit, a different branch, or a different project state than the current `main`.

## 2. Podfile status before correction

`ios/Podfile` was present, tracked, and already standard after the previous fix. It did not contain manual Flutter plugin pods.

## 3. Final Podfile content

```ruby
platform :ios, '15.0'

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

## 4. Is platform iOS 15 present?

Yes: `platform :ios, '15.0'` is the first Podfile setting and is not commented out.

## 5. Is Flutter podhelper present?

Yes. The Podfile requires Flutter `podhelper` and contains:

- `flutter_ios_podfile_setup`
- `flutter_install_all_ios_pods`
- `flutter_additional_ios_build_settings`

## 6. Flutter version

```text
Flutter 3.44.0 stable
```

## 7. Dart version

```text
Dart SDK 3.12.0
```

## 8. google_mobile_ads version

Requested: none.

Resolved: none.

`google_mobile_ads` is not currently part of this project.

## 9. webview_flutter_wkwebview version

Resolved in this project: none.

Local Pub Cache contains several versions, but none is resolved by this project.

## 10. Is webview_flutter_wkwebview in pubspec.lock?

No. `Select-String` returned no matches.

This is expected because `google_mobile_ads` is absent.

## 11. Is webview_flutter_wkwebview in .flutter-plugins-dependencies?

No. `Select-String` returned no matches.

This is expected because `google_mobile_ads` is absent.

## 12. Local Podspec path

Available local Pub Cache podspecs include:

```text
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.23.5\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.24.2\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.24.5\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.25.1\darwin\webview_flutter_wkwebview.podspec
C:\Users\hp\AppData\Local\Pub\Cache\hosted\pub.dev\webview_flutter_wkwebview-3.26.0\darwin\webview_flutter_wkwebview.podspec
```

## 13. Does the Podspec exist?

Yes, in local Pub Cache. No resolved project plugin path exists because the package is not in the current dependency graph.

## 14. Was Pub Cache corrupt?

No evidence of Pub Cache corruption was found. `flutter pub get` completed successfully and local `webview_flutter_wkwebview` podspec files exist in Pub Cache.

## 15. Was codemagic.yaml running pod install twice?

Current state: no standalone `pod install`, `pod install --repo-update`, or `pod repo update` remains in `codemagic.yaml`.

`flutter build ipa` is the single path that will run Flutter's iOS build flow on Codemagic.

## 16. Modified files

- `codemagic.yaml`
- `IOS_CODEMAGIC_FULL_FIX_REPORT.md`

## 17. Bundle ID

`com.labelora.foodscanner`

Verified in `ios/Runner.xcodeproj/project.pbxproj` and Codemagic signing vars.

## 18. GADApplicationIdentifier status

Not present.

This is correct for the current project state because `google_mobile_ads` is not installed or used. No fake or Android AdMob ID was added.

## 19. NSCameraUsageDescription status

Present:

```text
Labelora uses the camera to scan food product barcodes.
```

## 20. TARGETED_DEVICE_FAMILY status

Present as `TARGETED_DEVICE_FAMILY = "1,2"` for iPhone and iPad support.

## 21. Deployment target

- Podfile: iOS 15.0
- Xcode project: iOS 15.0

## 22. flutter analyze result

Passed:

```text
No issues found
```

## 23. flutter test result

Passed:

```text
129 tests passed
```

## 24. APK build result

Passed:

```text
Built build\app\outputs\flutter-apk\app-debug.apk
```

Non-blocking Android warning: `mobile_scanner` applies Kotlin Gradle Plugin and may need a future plugin migration.

## 25. Current branch

```text
main
```

## 26. Latest commit

Before this uncommitted report/update:

```text
fa75e75 Let Flutter iOS build manage CocoaPods
```

## 27. Is Podfile tracked?

Yes:

```text
ios/Podfile
```

It is not ignored by Git.

## 28. Required Git commands

```sh
git add codemagic.yaml IOS_CODEMAGIC_FULL_FIX_REPORT.md
git commit -m "Improve Codemagic iOS diagnostics"
git push origin main
```

Do not add generated or secret files:

- `ios/Pods`
- `ios/.symlinks`
- `.dart_tool`
- `build`
- `.p8`
- `.p12`
- provisioning profiles
- secrets

## 29. Codemagic new build steps

Use `Start new build`, select branch `main`, and confirm the log prints:

- the latest commit
- `git log -1 --oneline`
- `platform :ios, '15.0'`
- `flutter_ios_podfile_setup`
- `flutter_install_all_ios_pods`
- current `ios/Podfile` content

Do not use Rebuild on an old commit.

## 30. Final verdict

Ready for Codemagic build.

This is not a claim that iOS succeeded on Windows. The issue is only fully closed after a new Codemagic build succeeds.
