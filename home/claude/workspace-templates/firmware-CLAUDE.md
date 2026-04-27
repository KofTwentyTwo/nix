# <REPO-NAME>

> Firmware (Zephyr / nRF Connect SDK) — copy this template into a new firmware repo and fill in. Delete this header line.

## What this is

<one paragraph: device purpose, RF profile, key sensors/actuators, role in the larger system>

## Stack

| Component | Choice |
|---|---|
| RTOS | Zephyr <version> via NCS <version> |
| Target chip(s) | nRF52840 / nRF5340 / nRF7002 / ... |
| Target board(s) | <board-name(s)> + custom board overlays in `boards/` |
| Bootloader | MCUboot / SUIT (NCS 2.7+) |
| OTA / DFU | <Nordic Cloud / custom MQTT-based / serial-only> |
| Comms | BLE / Wi-Fi / LTE / Thread / Matter |
| Cloud | AWS IoT Core (see `local--mqtt-topic-design` skill) |
| Security | TF-M / Secure Boot / signed images / HKDF / ... |
| CI | CircleCI / GitHub Actions |
| Testing | Twister + on-target hardware tests |

## Build / test / run

```bash
# Initial setup (once)
west init -m <manifest-repo> -- <workspace>
cd <workspace>
west update

# Build
west build -b <target-board> app -p auto      # with sysbuild (NCS 2.7+ default)
west build -b <target-board>_<variant> app    # board variant (e.g., _ns for non-secure)

# Flash
west flash --runner <jlink|nrfjprog|pyocd>

# Erase + reflash full
west flash --erase

# Monitor
nrfjprog --reset && minicom -D /dev/cu.usbmodem<id> -b 115200
# or:
west espressif monitor    # if applicable
```

### Twister tests
```bash
west twister -T tests/ -p <board>           # run hardware-independent tests
west twister -T tests/ -p <board> --device-testing --device-serial /dev/cu.usbmodem<id>
```

## Conventions

- **Style:** Zephyr coding style (kernel-derived: tabs, K&R, 80-col soft).
- **Naming:** `snake_case` matching Zephyr.
- **Logging:** Zephyr logging subsystem — `LOG_INF/WRN/ERR/DBG` only. No `printk` in production.
- **Configuration:** Kconfig + devicetree, never hardcoded constants.
- **Branch:** `feature/<TICKET-KEY>-<short-description>`.
- **Commits:** conventional commits with scope (e.g., `feat(driver-bme280): add temperature offset config`).
- **PRs target:** `develop` (gitflow) — verify per repo.

## Devicetree & Kconfig hygiene

- Board base files (`zephyr/boards/` or `nrf/boards/`) are read-only — never edit. Use overlays in `boards/<board>.overlay`.
- Per-app config goes in `prj.conf`. Per-board overrides in `boards/<board>.conf` or `<board>_defconfig`.
- For sysbuild builds, child-image configs go in `sysbuild/<image-name>/`.
- When a config "doesn't take effect" check precedence: prj.conf > board defconfig > Kconfig defaults.
- Use `local--firmware-build-doctor` agent for build failures.

## Drivers

- Out-of-tree drivers under `drivers/<class>/<part>/` (preferred) — easier to maintain than upstreaming.
- Each driver has a binding in `dts/bindings/<class>/<vendor>,<part>.yaml`.
- Use `local--hub-firmware-driver` agent to scaffold new drivers.

## Tracker

- Jira project: <KEY>
- Hardware revisions tracked separately: `<spreadsheet/Confluence>`

## Cloud topics (if MQTT)

Topic schema documented at: `<wiki-link>` or `docs/MQTT-TOPICS.md`
- Use `local--mqtt-topic-design` skill before adding new topics.
- Reserved AWS topics (`$aws/...`) for shadow / Jobs / Basic Ingest only.

## OTA / DFU

- Image format: signed `.zip` for MCUboot / `.suit` for SUIT
- Update path: <serial / BLE / Wi-Fi / LTE>
- Rollback: <enabled / not enabled> — verify in `pm_static.yml` partition map
- Version scheme: <semver / custom>

## Hardware revisions

| Rev | Released | Notes / known issues |
|---|---|---|
| A | <date> | <issues> |
| B | <date> | <issues> |

## Session continuity

- Session state: `./docs/SESSION-STATE.md`
- TODO list: `./docs/TODO.md`
- Build logs: `./build/<config>/build.log` (transient — don't commit)
- Plans: `./docs/PLAN-*.md`

## Healthcare context (delete if not applicable)

This device handles patient data. Per dmdbrands HIPAA practice:
- Device serial is OK in topics/logs; patient identifiers are not.
- Encryption at rest if device stores PHI — use crypto subsystem, not custom.
- Watchdog and brown-out behavior must be reviewed for any clinical-impact path.
- Side-channel concerns: timing, power analysis, RF leakage — escalate when unclear.

## Open repo-specific questions

<things future-you needs to know that aren't obvious from the code, the wiki, or the test results>
