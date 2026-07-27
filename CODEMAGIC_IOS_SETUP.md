# Codemagic iOS Setup

## 1. Put The Project In Git

Create a remote Git repository, preferably GitHub, and push the Flutter project. Codemagic builds from Git.

## 2. Register Bundle ID

In Apple Developer, create or confirm this Bundle ID:

```text
com.labelora.foodscanner
```

If you choose a different final Bundle ID, update both Xcode project settings and `codemagic.yaml`.

## 3. Create App Store Connect App

Create the app record in App Store Connect using:

- Name: `Labelora: Food Scanner`
- Bundle ID: your final Bundle ID
- SKU: your own internal SKU

## 4. Add App Store Connect Integration

In Codemagic:

1. Open Team settings.
2. Add App Store Connect API key integration.
3. Name it clearly.
4. Replace `APP_STORE_CONNECT_INTEGRATION_NAME` in `codemagic.yaml` with that integration name.

## 5. Configure Signing

The workflow uses Codemagic CLI tools:

```sh
app-store-connect fetch-signing-files "$BUNDLE_ID" --type IOS_APP_STORE --create
keychain add-certificates
xcode-project use-profiles
```

These require a valid App Store Connect integration and Apple Developer access.

## 6. Run Workflow

Run the `ios-release` workflow in Codemagic. It will:

- Clean Flutter build output.
- Fetch dependencies.
- Check formatting.
- Analyze.
- Test.
- Fetch signing files.
- Build IPA.

## 7. Artifacts

Find IPA and logs in:

```text
build/ios/ipa/*.ipa
/tmp/xcodebuild_logs/*.log
```

## 8. TestFlight

The workflow currently does not auto-submit to TestFlight:

```yaml
submit_to_testflight: false
```

Set it to `true` only after the first signed IPA is verified.

## 9. Reading Failures

- Signing failures usually mention missing certificates, profiles, team, or Bundle ID mismatch.
- CocoaPods failures usually mention a plugin pod, deployment target, or repo resolution.
- Xcode failures are usually in `/tmp/xcodebuild_logs/*.log`.
