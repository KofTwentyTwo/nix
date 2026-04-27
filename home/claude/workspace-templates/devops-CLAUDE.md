# <REPO-NAME>

> DevOps / infrastructure — copy this template into a new infra repo and fill in. Delete this header line.

## What this is

<one paragraph: what infra this manages, which environments, who depends on it>

## Stack

| Component | Choice |
|---|---|
| IaC | Terraform / OpenTofu — pick |
| Cloud | AWS (Greater Goods Control Tower) / GCP / Azure |
| Orchestration | Kubernetes (EKS / GKE / self-hosted) / ECS / Lambda — pick |
| GitOps | ArgoCD / Flux / direct apply — pick |
| Container registry | GHCR / ECR / Docker Hub |
| State backend | S3 + DynamoDB lock / Terraform Cloud — pick |
| Secrets | SOPS-nix / SealedSecrets / Vault / AWS Secrets Manager — pick |
| CI | CircleCI / GitHub Actions |
| Observability | CloudWatch / Datadog / Grafana / Prometheus — pick |

## Layout

```
.
├── modules/              # reusable terraform modules
│   └── <module-name>/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── shared/               # state backend, providers, common locals
└── docs/
```

## Build / test / run

```bash
# Per environment
cd environments/<env>
terraform init
terraform fmt -check
terraform validate
terraform plan                                # never run apply autonomously

# Module-level
cd modules/<module>
terraform fmt
terraform validate
```

## Conventions

- **Style:** `terraform fmt` enforced in pre-commit.
- **Naming:** `snake_case` for resources; `kebab-case` for resource Name tags / cloud-side names.
- **Module boundaries:** one concern per module. Compose in environments.
- **Variables:** type-constrained, with descriptions. Defaults only when sensible.
- **Outputs:** declared even when not consumed externally — they document intent.
- **Branch:** `feature/<TICKET-KEY>-<short-description>`.
- **Commits:** conventional commits.

## Apply protocol

- `terraform apply` is **never** autonomous (per `~/.ai/3-rules.md` section 13). Plan, review, get approval, then apply.
- For non-trivial changes: post `terraform plan` output as a PR comment for review before merging the PR.
- Production applies: pair-review or async-approve via PR.
- Rollback: every PR's plan should be inspected for unexpected `~` (in-place) and `-` (destroy) operations.

## Tracker

- Jira project: <KEY> for prioritized work
- GitHub Issues for repo-specific bugs

## Secrets

- **Never commit** plaintext secrets. Don't even `terraform plan` with secrets in env vars unless the shell history is also wiped.
- AWS credentials: SSO via `aws sso login --profile <profile>` (e.g., `greater_goods_control_tower`).
- Per-environment secrets: <SOPS / SealedSecrets / AWS Secrets Manager>.
- Rotation cadence: <documented?>

## CD / deployment flow

- Branch → environment:
  - `develop` → dev environment (auto-apply on merge, if approved)
  - `staging` → staging (manual approve in CI)
  - `main` → prod (manual approve in CI; pair-reviewed)
- For ArgoCD-managed workloads: see `~/.ai/5-learnings.md` "ArgoCD" section for known gotchas (AppProject permissions, ExternalSecret defaults, tracking labels, ignoreDifferences).

## Drift detection

- `terraform plan` against `main` runs daily in CI; non-empty plan triggers an alert.
- ArgoCD reports OutOfSync — investigate via the dashboard, then either reconcile state or fix the manifest.

## Cost controls

- Budget alerts at <threshold>.
- Spend dashboard: `<URL>`.
- Tagging: every resource has `Owner`, `Environment`, `CostCenter` tags.

## Session continuity

- Session state: `./docs/SESSION-STATE.md`
- TODO list: `./docs/TODO.md`
- Plans: `./docs/PLAN-*.md`

## Healthcare context (delete if not applicable)

This infra hosts PHI workloads. Per dmdbrands HIPAA practice:
- All data stores encrypted at rest. KMS keys per environment.
- Network egress restricted; VPC endpoints for AWS service traffic where possible.
- Audit logging on (CloudTrail, VPC Flow Logs, S3 access logs, RDS query logs as appropriate).
- BAA in place with: <list of HIPAA-eligible AWS services in use>.

## Open repo-specific questions

<things that are obvious to the maintainer but not from the code: AWS account IDs, who owns the on-call, what the SLOs are, etc.>
