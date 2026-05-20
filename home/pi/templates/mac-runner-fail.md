You are diagnosing a CircleCI Mac job that is failing, slow, or behaving differently from local.

Gather first:
1. **Job link and the failing step** — paste the log excerpt or attach the job URL.
2. **Local vs CI delta** — Xcode version, Fastlane Match credentials, simulator runtime, code-signing identity, env vars present on one but not the other.
3. **Executor type** — hosted Mac executor or self-hosted Mac runner. They have different debug surfaces and different available toolchain versions.
4. **Recent changes** — `.circleci/config.yml`, `.xcode-version`, signing certs in the Match repo, dependency bumps, orb version bumps.

Check, in order of likelihood:
- Xcode version pinning (`.xcode-version` / orb config) vs the version available on the runner.
- Fastlane Match credentials — `MATCH_PASSWORD`, deploy key, 1Password access to the certs repo.
- Code-signing identity vs provisioning profile mismatch.
- Simulator availability — runtime version, device type, boot state.

Do not run `match nuke`, modify production signing certs, or attempt hardware flashing without explicit confirmation.

Deeper playbook: the `local--circleci-mac-runner-debug` skill in this environment.
