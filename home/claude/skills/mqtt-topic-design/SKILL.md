---
name: mqtt-topic-design
description: "Design MQTT topic schemas conforming to AWS IoT Core conventions and limits. Covers topic structure, wildcards, reserved topics, shadows, rules engine routing, and the differences between standard and Basic Ingest. Use when designing a new IoT messaging schema, reviewing an existing topic plan, or debugging topic-routing problems on AWS IoT Core."
when_to_use: "When the user mentions MQTT topic design, AWS IoT Core, device messaging, telemetry routing, device shadows, or asks 'how should I structure these topics'. Especially relevant for dmdbrands healthcare device work."
argument-hint: "[--design | --review | --debug]"
---

# MQTT Topic Design (AWS IoT Core)

Design topic schemas that scale, route cleanly, and respect AWS IoT Core's specific limits and conventions.

## Hard limits (AWS IoT Core, current as of 2026-04)

| Limit | Standard publish/subscribe | Basic Ingest |
|---|---|---|
| Topic max bytes | 256 (UTF-8) | 256 |
| Max levels (slashes) | 7 (paid path); historically 8 with shared subscriptions; verify in current AWS docs | 7 |
| Reserved prefixes | `$aws/...`, `$AWS/...` | n/a (Basic Ingest doesn't broker) |
| Max in-flight inbound (per connection) | 100 | n/a |
| Wildcards | `+` (single level), `#` (multi level, terminal only) | `+` and `#` in rules engine |
| TLS | required | required |
| Retained messages | supported | not supported |
| QoS | 0, 1 (no QoS 2) | n/a (one-shot to rules engine) |

Always confirm against current AWS docs when limits matter — they evolve.

## Standard topic vs. Basic Ingest

- **Standard topic** (`telemetry/...`): broker stores, supports retained messages, supports subscribers, billed for messages + connection minutes.
- **Basic Ingest** (`$aws/rules/<rule_name>/...`): bypasses the broker and goes directly to a rules-engine rule. Cheaper. No subscribers possible. No retained messages. Use for fire-and-forget telemetry where no device subscribes.

Decision: if no device or service ever subscribes to this topic on the broker side, use Basic Ingest. Otherwise use a standard topic.

## Recommended structure

```
<vendor-or-org>/<product>/<env>/<device-id>/<channel>/<subchannel>
```

For dmdbrands healthcare devices, a defensible default:

```
dmd/<product-line>/<env>/<device-serial>/<channel>[/<subchannel>]
```

| Segment | Purpose | Example |
|---|---|---|
| `dmd` | Org / vendor namespace | `dmd` |
| `<product-line>` | Product family (hub, sensor, gateway) | `hub` |
| `<env>` | Environment (separates prod/staging telemetry) | `prod`, `dev`, `qa` |
| `<device-serial>` | Globally unique device identifier | `SN-A1B2C3` |
| `<channel>` | High-level routing axis | `telemetry`, `events`, `commands`, `firmware` |
| `<subchannel>` | Optional fine-grain routing | `vitals`, `battery`, `error`, `dfu/progress` |

This fits in 7 levels with one to spare. Keep segments short (avoid hashes longer than necessary).

### Why these choices
- **Env in the path** is debated. The alternative is per-account separation — different AWS accounts per env, same topic structure. Per-account is cleaner if you have it. If everything's in one account, env-in-path beats post-hoc filtering.
- **Device ID before channel** lets you scope subscriptions by device cleanly: `dmd/hub/prod/SN-A1B2C3/#`. The reverse (`channel/.../device`) makes that subscription multi-segment and harder to reason about.
- **Channels separate purposes** so rules-engine routing is cheap. Telemetry → analytics + storage; events → alerting; commands → device-side ack flow; firmware → DFU pipeline.

## Reserved AWS topics (do not use as your own)

- `$aws/things/<thingName>/shadow/...` — device shadow (state sync)
- `$aws/things/<thingName>/jobs/...` — IoT Jobs (deployment, OTA orchestration)
- `$aws/events/...` — fleet-level events
- `$aws/rules/<ruleName>/...` — Basic Ingest entry
- `$aws/sites/...`, `$aws/things/.../streams/...` — fleet provisioning, file streaming

If you see `$aws` in your design, you're either consuming an AWS feature or making a mistake — verify which.

## Device Shadow conventions

For per-device state sync, use named shadows when you have multiple state contexts:

```
$aws/things/<thingName>/shadow/name/<shadowName>/update
$aws/things/<thingName>/shadow/name/<shadowName>/get
$aws/things/<thingName>/shadow/name/<shadowName>/delete
```

Common named-shadow patterns:
- `device` — current configuration (sync source-of-truth)
- `firmware` — desired firmware version + DFU state
- `network` — connectivity profile (Wi-Fi creds, BLE pairing, cellular profile)

Avoid the unnamed (classic) shadow for new designs — named shadows are clearer and let you ACL/route them separately.

## Rules engine routing

Each topic family should have an obvious rules-engine destination:

| Channel | Destination |
|---|---|
| `telemetry/*` | Timestream / Kinesis / S3 (cold storage) |
| `events/*` | EventBridge → alarms, on-call paging |
| `commands/*` | DynamoDB ack table (per-device command idempotency) |
| `firmware/dfu/*` | Lambda → DFU orchestrator |
| `errors/*` | CloudWatch Logs + alerting |

Document this map alongside the topic schema. Without it, the topic structure is half a spec.

## Subscriptions and wildcards

- `dmd/hub/prod/+/telemetry/#` — all telemetry from any prod hub. Use for fleet-wide analytics consumers.
- `dmd/hub/prod/SN-A1B2C3/#` — everything from one device. Use for per-device dashboards.
- `dmd/+/+/+/commands/+` — all commands across all products/envs/devices. Use for command-routing consumers (auditing, replay).

Wildcards cost nothing on subscriptions but client subscriptions count against connection limits. Don't fan out hundreds of `+` patterns from a single client.

## Healthcare / PHI considerations (dmdbrands)

- **No PHI in the topic itself.** The topic is logged, indexed, monitored. A device serial is fine; a patient identifier is not. If a topic must distinguish per-patient context, use an opaque identifier (e.g., a per-device-context UUID in the device shadow), not the patient's name or MRN.
- **Payload encryption.** TLS gives in-transit; consider per-message payload encryption for highly sensitive PHI even within an HIPAA-eligible AWS account.
- **Retention.** Be deliberate about how long messages live in S3/Timestream. HIPAA's minimum-necessary principle pushes toward shorter retention than engineering instinct does.

## Anti-patterns to avoid

| Pattern | Why it's wrong |
|---|---|
| `device-events-vital-signs-update` | Single segment with embedded structure — can't wildcard, can't route. |
| `<deviceId>/<patientName>/...` | PHI in topic. |
| 8+ segments | Bumps the limit. Easy to add one more later and break things. |
| Mixing standard and Basic Ingest in the same family | Confusing; pick one per channel. |
| Cryptic IDs (`X9Y2Z`) when you mean `firmware-progress` | Future-you will not remember what `X9Y2Z` was. |
| Versioning via topic (`telemetry/v1/...`) | Use payload schema versioning instead — topic versioning forces double-publish on every consumer migration. |

## Output formats

### `--design`
Produce: schema spec + rules-engine routing map + subscription patterns + sample payloads. Validate against limits.

### `--review`
Take an existing schema, run it through the limits and anti-patterns, list problems with severity and proposed fixes. Don't rewrite — recommend.

### `--debug`
The user has a topic that isn't routing as expected. Walk through:
1. Is this Basic Ingest (`$aws/rules/...`) or a broker topic?
2. Does the rule's SQL `FROM` clause match the topic exactly (no extra slashes)?
3. Wildcards: is `#` only at the end? Is `+` matching exactly one segment?
4. Reserved prefix collision (`$aws/...`)?
5. ACL / IoT Policy: does the device have publish permission on this topic? (Check `iot:Publish` resource patterns.)
6. Connection state: is the device actually connected? `aws iot describe-thing-connectivity`.

## Rules

- Always check current AWS limits when proposing a design. They evolve.
- For dmdbrands healthcare work, escalate any PHI-touching topic decisions to the user — don't proceed with a design that touches patient identity without explicit confirmation.
- A topic schema without a rules-engine routing map is incomplete.
- Don't propose changes to deployed schemas without a migration plan (consumers, retained messages, in-flight commands).
