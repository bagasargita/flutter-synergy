# GitLab CI/CD (Play Store + TestFlight)

This project uses [`.gitlab-ci.yml`](../.gitlab-ci.yml) plus [Fastlane](../fastlane/Fastfile) for release automation.

## Pipeline overview

| Stage   | Job                 | Runner   | Purpose |
|---------|---------------------|----------|---------|
| verify  | `flutter_verify`    | Linux    | `dart format`, `flutter analyze`, `flutter test` |
| build   | `build_android_release` | Linux | Release **AAB** (signed when Android secrets are set) |
| build   | `build_ios_release` | **macOS** | **IPA** via `flutter build ipa` (+ optional Match) |
| deploy  | `deploy_play_store` | Linux    | Upload AAB with Fastlane |
| deploy  | `deploy_testflight` | macOS    | Upload IPA with Fastlane |

- **Android**: runs on the default Linux runner using the [`cirruslabs/flutter`](https://github.com/cirruslabs/docker-images-flutter) image (`FLUTTER_CHANNEL`, default `stable`).
- **iOS**: requires a **macOS** runner. Set the job tag `macos` in `.gitlab-ci.yml` to match your runner (GitLab.com SaaS examples: `saas-macos-medium-m1`, `saas-macos-large-m1`). Install **Flutter** on that runner and ensure `flutter` is on `PATH`.

Deploy jobs are **manual** so production uploads stay deliberate. Tagged releases matching `v*` (e.g. `v1.0.0`) trigger Android/iOS **build** jobs automatically; default-branch builds are **manual** where noted in the YAML.

## One-time store setup

### Google Play

1. Create a **Google Play Console** app listing if you have not already.
2. In Play Console → **Setup → API access**, link a Google Cloud project and create a **service account** with permission to release apps (e.g. “Release to production” / appropriate role for your org).
3. Download the service account **JSON key**. You will store its **full JSON string** in GitLab (below).

### Apple (TestFlight / App Store Connect)

1. In [App Store Connect](https://appstoreconnect.apple.com/) → Users and Access → **Keys** (API), create an **App Store Connect API** key with **Developer** (or **App Manager**) access.
2. Note **Key ID**, **Issuer ID**, and download the **.p8** private key file.
3. Base64-encode the **entire .p8 file** (single line, no newlines) for `APP_STORE_CONNECT_KEY_CONTENT` (same pattern Fastlane expects with `is_key_content_base64: true`).
4. Set **Apple Team ID** in `ios/ExportOptions.plist` (replace `REPLACE_WITH_TEAM_ID`) or supply `APPLE_TEAM_ID` in CI so [`scripts/ci/patch_ios_team_id.sh`](../scripts/ci/patch_ios_team_id.sh) can patch it at build time.

### iOS code signing (recommended: Match)

For CI builds, use [fastlane match](https://docs.fastlane.tools/actions/match/) with a private certificates repo and these variables (typical):

- `MATCH_GIT_URL` — SSH or HTTPS URL of the encrypted certs repo
- `MATCH_PASSWORD` — encryption passphrase for the match repo
- `MATCH_GIT_BASIC_AUTHORIZATION` — if using HTTPS to the match repo (Base64 `username:token`), or use SSH deploy keys on the runner

The pipeline runs `bundle exec fastlane ios sync_match` before `build_ipa` when `MATCH_GIT_URL` is set.

Alternatively, install distribution cert + provisioning profile on the macOS runner manually (not ideal for shared runners).

## GitLab CI/CD variables

Add under **Settings → CI/CD → Variables**. Mark sensitive values as **Masked** and **Protected** if you only deploy from protected branches/tags.

### Android (release signing)

| Variable | Masked | Description |
|----------|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Yes | Base64 of the upload keystore file (`.jks` / `.keystore`) |
| `ANDROID_KEYSTORE_PASSWORD` | Yes | Keystore password |
| `ANDROID_KEY_ALIAS` | Yes | Key alias (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | Yes | Optional; if omitted, `ANDROID_KEYSTORE_PASSWORD` is used for the key |

[`scripts/ci/setup_android_signing.sh`](../scripts/ci/setup_android_signing.sh) writes `android/upload-keystore.jks` and `android/key.properties`. See also [`android/key.properties.example`](../android/key.properties.example).

If `ANDROID_KEYSTORE_BASE64` is unset, the script skips signing setup; release may still build with debug signing (not valid for Play).

### Google Play upload

| Variable | Masked | Description |
|----------|--------|-------------|
| `PLAY_STORE_JSON_KEY_DATA` | Yes | **Entire** service account JSON as a single string (Fastlane `json_key_data`) |
| `PLAY_STORE_TRACK` | No | Optional; default `internal`. Other values: `alpha`, `beta`, `production` |
| `PLAY_RELEASE_STATUS` | No | Optional; default `completed`. Use `draft` if you prefer to finish the release in Console |

### Apple upload (TestFlight)

| Variable | Masked | Description |
|----------|--------|-------------|
| `APP_STORE_CONNECT_KEY_ID` | No | API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | No | Issuer ID from App Store Connect |
| `APP_STORE_CONNECT_KEY_CONTENT` | Yes | Base64-encoded `.p8` body |

### iOS build (optional)

| Variable | Masked | Description |
|----------|--------|-------------|
| `APPLE_TEAM_ID` | No | 10-character Team ID; patches `ios/ExportOptions.plist` in CI |

## Local Fastlane

From the repo root (Ruby + Bundler):

```bash
bundle install
bundle exec fastlane android deploy_play_store   # after flutter build appbundle --release
bundle exec fastlane ios build_ipa               # on macOS with signing configured
bundle exec fastlane ios deploy_testflight       # after IPA exists
```

For a single lane that runs Match (if `MATCH_GIT_URL` is set), build, and upload:

```bash
bundle exec fastlane ios deploy_ios_ci
```

## Versioning

Play and App Store use `version` / build number from [`pubspec.yaml`](../pubspec.yaml) (`version: x.y.z+build`). Bump before tagging a release.

## Troubleshooting

- **Play upload fails with permissions**: Confirm the service account is invited in Play Console with the right role and the app exists.
- **iOS build fails on signing**: Run `sync_match` locally or fix Match variables; ensure `ExportOptions.plist` has the correct `teamID`.
- **JSON / multiline variables**: GitLab variable type **File** can be easier for large JSON; if you switch to a file path, adjust the Fastlane lane to use `json_key: ENV["PLAY_STORE_JSON_KEY_FILE"]` instead of `json_key_data`.
