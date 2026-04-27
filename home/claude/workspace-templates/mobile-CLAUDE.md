# <REPO-NAME>

> Mobile app — copy this template into a new mobile repo and fill in. Delete this header line.

## What this is

<one paragraph: app purpose, target platforms (iOS / Android / both), public-facing or internal>

## Stack

| Component | Choice |
|---|---|
| Platform(s) | iOS <version+>, Android API <level+> |
| Language(s) | Swift / Kotlin / TypeScript (RN) — pick one row, delete others |
| UI framework | SwiftUI / UIKit / Jetpack Compose / React Native |
| State management | <choice> |
| Networking | URLSession / Alamofire / Retrofit / fetch — pick |
| Persistence | Core Data / SQLDelight / Room / async-storage — pick |
| Analytics | <vendor or "none"> |
| Crash reporting | <vendor> |
| CI | CircleCI (hosted Mac executor / self-hosted runner) |
| Distribution | TestFlight + App Store / Google Play Internal Testing + Play Store |

## Build / test / run

```bash
# iOS
xcodebuild -workspace <Workspace>.xcworkspace -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild -workspace <Workspace>.xcworkspace -scheme <Scheme> test

# Android
./gradlew assembleDebug
./gradlew test
./gradlew connectedAndroidTest

# RN (if applicable)
pnpm install
pnpm ios     # or pnpm android
pnpm test
```

## Conventions

- **Style:** <SwiftFormat / ktlint / Prettier> per the config in this repo.
- **Branch:** `feature/<TICKET-KEY>-<short-description>`.
- **Commits:** conventional commits.
- **PRs target:** `develop` (gitflow) / `main` — verify and edit.

### iOS specifics
- Code-signing: Match (cert repo: `<repo-or-S3-bucket>`) — see `~/.claude/skills/local--circleci-mac-runner-debug` for CI signing patterns.
- Provisioning profiles handled by Match; do not manually edit `*.mobileprovision` in repo.

### Android specifics
- Keystore: <where it lives + how unlocked in CI>
- Min/target SDK: <numbers>

## Tracker

- Jira project: <KEY> — `https://greatergoods.atlassian.net/jira/software/projects/<KEY>/boards/...`
- Or GitHub Issues if applicable.

## Deploy

- iOS: <fastlane lane> → TestFlight → App Store
- Android: <fastlane lane> → Internal Testing → Play Store
- Release cadence: <weekly / sprint-end / on-demand>
- Release notes: `<location>`

## Healthcare context (delete if not applicable)

This app handles PHI. Per dmdbrands HIPAA practice:
- No PHI in logs, analytics events, crash reports without explicit policy.
- All API calls over TLS 1.2+ with cert pinning.
- Local persistence: encrypted at rest (Core Data with encryption key from Keychain / Android EncryptedSharedPreferences).
- Authentication: <Auth0 / Authentik / Cognito> — never plaintext passwords.

## Session continuity

- Session state: `./docs/SESSION-STATE.md`
- TODO list: `./docs/TODO.md`
- Plans: `./docs/PLAN-*.md`
- Use `local--session-start` skill to resume.

## Open repo-specific questions

<things future-you needs to know that aren't obvious from the code>
