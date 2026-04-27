---
name: circleci-mac-runner-debug
description: "Diagnose and fix CircleCI Mac runner problems: Xcode version mismatches, Fastlane / Match credential issues, self-hosted runner setup, code-signing on CI, simulator quirks, and the difference between CircleCI's hosted Mac executors and self-hosted Mac runners. Use when a Mac job is failing, slow, or behaving differently from local builds."
when_to_use: "When a CircleCI job on a Mac executor or self-hosted Mac runner fails or hangs, when build artifacts differ between local and CI, when code-signing fails in CI, or when planning Mac runner capacity."
argument-hint: "[--triage | --setup | --signing | --simulator]"
---

# CircleCI Mac Runner Debug

Mac CI on CircleCI has more sharp edges than Linux CI. This skill covers the specific gotchas, in roughly the order they bite people.

## First: which kind of runner is this?

| Type | Indicator | Notes |
|---|---|---|
| **Hosted Mac executor** | `macos:` key in job config (e.g., `macos: { xcode: "15.4.0" }`) | CircleCI-managed VMs, fixed Xcode versions, billed per-minute at premium rate |
| **Self-hosted Mac runner** | `machine: true` + `resource_class: <namespace>/<runner-name>` | Your hardware, your responsibility, lower per-minute cost but you maintain it |

The failure modes overlap but aren't identical. Always confirm which you're on before debugging.

## Hosted Mac executor — common failures

### Xcode version mismatch
The job pins `xcode: "15.4.0"`, but the build references something newer (a SwiftUI API, a new `Sendable` requirement, a Swift compiler flag).

- **Detect:** error log mentions a missing API, `error: 'X' is only available in iOS Y.Z`, or `error: unsupported Swift version`.
- **Fix:** check `https://circleci.com/docs/using-macos/` for the available Xcode versions on hosted executors. Pin to a version that exists. Don't pin to `latest` — it's a moving target that breaks builds without warning.
- **Local–CI drift:** match local Xcode to CI Xcode via `xcode-select -s` and `xcodes` (Homebrew). The user has `xcodes` installable.

### Bundler / CocoaPods cache thrash
Each CI run reinstalls everything if the cache key includes a moving timestamp.

- **Cache key pattern:** `pods-{{ checksum "Podfile.lock" }}` for CocoaPods, `gems-{{ checksum "Gemfile.lock" }}` for Bundler.
- Verify the lock file exists and is committed. CI fails the cache key if `Podfile.lock` isn't in the repo.
- For Pods, also check that `Pods/` is *not* in `.gitignore` if you want to vendor; otherwise rely entirely on cache + reinstall.

### Slow Pod install / Carthage build
- Add `--repo-update` only when Podfile changed; otherwise `pod install --no-repo-update` is faster.
- For Carthage, `carthage bootstrap --use-xcframeworks --platform iOS --cache-builds` is the modern incantation.

### macOS keychain locking
Background processes (Spotlight, fastlane gym signing) can't access a locked keychain on a fresh CI VM.

```bash
security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
security default-keychain -s build.keychain
security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
security set-keychain-settings -t 3600 -u build.keychain
security import certs.p12 -k build.keychain -P "$P12_PASSWORD" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain
```

The last line (`set-key-partition-list`) is the one most people miss. Without it, `codesign` will throw a UI prompt that hangs the build forever.

## Fastlane / Match — credential and signing

### Match wants the SSH key but CircleCI provides HTTPS only
By default, Match clones the certs repo. If your repo is configured for SSH (`git@github.com:...`), CircleCI's checkout step gives you a working SSH agent — but Match in `:readonly` mode sometimes uses git's HTTPS path with a stored credential that's not present.

- Pass `git_url` explicitly with the SSH form to Match, and ensure `add_ssh_keys` is in the job config with the right fingerprint.
- Or: switch to Match Storage Mode `s3` / `gitlab_secure_files` and bypass git entirely.

### Match decryption fails with `OpenSSL::Cipher::CipherError`
Match passphrase encryption changed format around fastlane 2.207. If you have certs encrypted on an old fastlane and decrypt on a new one (or vice versa), it fails.

- **Fix:** pin fastlane in the Gemfile, run `bundle exec fastlane match nuke` against the affected type, regenerate. Painful, do it once.

### `fastlane gym` exit code 65
Generic Xcode build failure. Get the actual error from `~/Library/Logs/gym/<App>-<scheme>.log`.

```yaml
- store_artifacts:
    path: ~/Library/Logs/gym
```

Always store gym logs as artifacts. The default error message hides the real issue.

### Provisioning profile mismatch
`error: No profiles for 'com.example.App' were found`.

- The profile UUID in `project.pbxproj` is stale — Xcode regenerated it locally but didn't commit the change.
- Or: bundle ID changed and the profile is for the old one.
- Match auto-handles this if you call `match(type: "appstore", app_identifier: "com.example.App")` before `gym`.

## Self-hosted Mac runners

### Setup checklist

1. **macOS version** — match CircleCI's supported list. Drift here causes obscure tooling failures.
2. **Runner agent** — install via the official installer; auto-updates by default. Disable auto-updates only if you have a reason.
3. **`launchd` plist** — runner must run as a non-admin user. Don't run as root.
4. **Xcode** — install via `xcodes` for version control. Set with `sudo xcode-select -s /Applications/Xcode-XX.X.app/Contents/Developer`.
5. **Command Line Tools** — `xcode-select --install` and accept the license: `sudo xcodebuild -license accept`.
6. **Homebrew** — install Homebrew under the runner user (not root). Add `/opt/homebrew/bin` to the runner's PATH.
7. **Ruby / fastlane** — use `rbenv` or Homebrew Ruby (not system Ruby). Bundle install per project.
8. **Keychain** — pre-create a `build.keychain` with permissions allowing `codesign` and `xcodebuild` to read certs without UI prompts.
9. **Cache directories** — `~/.gem`, `~/Library/Developer/Xcode/DerivedData`, `~/Library/Caches/CocoaPods` should persist between runs (don't wipe).
10. **Disk space** — Xcode is huge, DerivedData grows fast. Set up a cron to prune builds older than 14 days.

### Runner won't pick up jobs
- `tail -f /opt/circleci-runner/runner.log` (path may vary). Look for connection failures, auth failures, or `task_agent` errors.
- Check the runner status in the CircleCI web UI. If it's "online" but jobs queue forever, the resource_class in `.circleci/config.yml` is wrong (typo, wrong namespace).
- Network: runner must reach `runner.circleci.com` over HTTPS. Corporate firewalls sometimes break this.

### Job hangs forever
- Most often: a UI prompt the user can't see (codesign, keychain, gatekeeper).
- Run `caffeinate -i` as the runner user to keep the system awake. Otherwise idle Macs sleep mid-build.
- Check `Console.app` for `securityd` errors at the time of the hang.

### Resource exhaustion
Self-hosted Macs run out of:
- **Disk** — DerivedData, simulator runtimes, Pods caches
- **Inodes** — many small files in node_modules / Pods. `df -i` shows this
- **Open file descriptors** — `launchctl limit maxfiles` should be at least `65536`

## Simulators

### "Unable to boot the Simulator"
Often a stale `CoreSimulator.framework` after Xcode upgrade. Reset:
```bash
xcrun simctl shutdown all
killall Simulator || true
xcrun simctl erase all
sudo rm -rf ~/Library/Developer/CoreSimulator/Caches
```

### Simulator runtime missing
After an Xcode upgrade, simulator runtimes don't auto-download. Either:
- `xcodebuild -downloadPlatform iOS`
- Or pre-download via `xcrun simctl runtime add` with a downloaded `.dmg`

### `xcodebuild` can't find a simulator
The destination string changed across Xcode versions. Use:
```bash
xcrun simctl list devices available
```
to see actual device IDs. Pin a device + OS pair in your scheme or pass `-destination` with a UDID, not a name.

## Code signing — the always-painful part

### Manual signing in CI
Don't. Use Match (or App Store Connect API key with `xcodebuild -allowProvisioningUpdates`).

### App Store Connect API key
The modern alternative to Apple ID + 2FA in CI. Generate in ASC, store as a CircleCI context:
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT` (base64 of the .p8 file)

Use with `app_store_connect_api_key` action in fastlane or `xcodebuild -authenticationKeyPath`.

### Signing identity vs. team mismatch
If the build chooses the wrong team, force it via `DEVELOPMENT_TEAM` in `xcodebuild` or the project's `XCConfig` files. Don't rely on "first signing identity in keychain" — that's order-dependent.

## Debug workflow

### `--triage`
1. What's the error message? (Get the actual log, not the CircleCI summary.)
2. Hosted vs. self-hosted runner?
3. Did this work yesterday? What changed? (Xcode bump, fastlane bump, dependency bump, branch with new code.)
4. Reproduce locally on a Mac with the matching Xcode. If you can't, suspect runner state.
5. If runner state: `xcrun simctl erase all`, fresh keychain, `bundle install` from clean.

### `--setup`
Walk through self-hosted setup checklist above. Output a verification script the user can run on the new runner.

### `--signing`
Specifically code-signing failures. Check in order: keychain access, profile match, team mismatch, Match passphrase, ASC API key validity.

### `--simulator`
Specifically simulator failures. Reset → re-download runtimes → verify destination string.

## Rules

- Always look at the actual log file, not the CircleCI summary. Mac build errors are usually one informative line buried in 500 lines of noise.
- Don't recommend `xcode-select -s` on a hosted executor (you don't control it). Use the `macos.xcode` config key.
- Never store certificates or .p8 files in the repo. Always CircleCI contexts or fastlane Match.
- Don't install fastlane via `gem install fastlane` directly — use Bundler so the version is reproducible.
- For dmdbrands: any change to the signing/distribution path needs a human signoff. CI can build and test; release decisions are humans.
