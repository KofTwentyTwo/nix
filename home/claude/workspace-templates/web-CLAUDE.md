# <REPO-NAME>

> Web app — copy this template into a new web repo and fill in. Delete this header line.

## What this is

<one paragraph: app purpose, public-facing or internal, who uses it>

## Stack

| Component | Choice |
|---|---|
| Framework | Next.js <version> (App Router / Pages Router) — pick |
| Language | TypeScript (strict) |
| Styling | Tailwind / CSS Modules / styled-components — pick |
| Data fetching | React Query / SWR / native fetch + Suspense — pick |
| Auth | Authentik / Auth0 / NextAuth / Clerk — pick |
| Forms | React Hook Form / native — pick |
| Validation | Zod / Yup — pick |
| Testing | Vitest + Testing Library / Jest + RTL — pick |
| E2E | Playwright / Cypress — pick |
| Package manager | pnpm |
| CI | CircleCI / GitHub Actions |
| Hosting | Vercel / self-hosted (k8s) / static + CloudFront — pick |

## Build / test / run

```bash
pnpm install
pnpm dev                                     # local dev server
pnpm build                                   # production build
pnpm test                                    # unit + integration
pnpm test:e2e                                # end-to-end (Playwright)
pnpm lint                                    # eslint
pnpm typecheck                               # tsc --noEmit
```

## Conventions

- **Style:** Prettier + ESLint per repo config.
- **Branch:** `feature/<TICKET-KEY>-<short-description>`.
- **Commits:** conventional commits.
- **PRs target:** `develop` (gitflow) / `main` — verify and edit.

### Next.js specifics

Pre-flight before writing any Next.js code in this repo:

- App Router or Pages Router? (don't mix without a deliberate plan)
- Server Components vs Client Components: default to server; opt into client with `'use client'` only when the page actually needs DOM/state/effects
- Route groups: `(auth)`, `(dashboard)` etc. directory names DO NOT appear in URLs (per `~/.ai/5-learnings.md`)
- Image domains: restricted via `next.config.mjs` `images.remotePatterns` — never use `'**'` (security; see learnings)
- For API deduplication in App Router pages, wrap fetchers in `React.cache()` (see learnings)

### TypeScript specifics

- `strict: true` — non-negotiable
- No `any`. Use `unknown` and narrow.
- Path aliases configured in `tsconfig.json` (e.g., `@/components/...`)

## Tracker

- Jira project: <KEY> at `https://greatergoods.atlassian.net/jira/software/projects/<KEY>/...`
- Or GitHub Issues.

## Deploy

- Branch → environment mapping:
  - `develop` → dev environment
  - `staging` → staging
  - `main` → production (manual approval gate)
- Image registry: <GHCR / ECR / Docker Hub>
- CD: <ArgoCD / Vercel / direct k8s apply>
- Health check URL: `<url>`

## Performance budget

- LCP < <ms>
- CLS < 0.1
- Bundle size: <main.js cap>
- Lighthouse CI: <enabled? threshold?>

## Healthcare context (delete if not applicable)

This app surfaces PHI. Per dmdbrands HIPAA practice:
- No PHI in `console.log`, analytics events, error tracking (Sentry/etc.) without policy.
- Auth tokens never in localStorage if the app's threat model includes XSS — use httpOnly cookies.
- All API calls over TLS; CSP configured; HSTS on.
- Patient identifiers in URLs: avoid in path segments; if unavoidable, use opaque IDs not MRNs.

## Session continuity

- Session state: `./docs/SESSION-STATE.md`
- TODO list: `./docs/TODO.md`
- Plans: `./docs/PLAN-*.md`

## Open repo-specific questions

<things future-you needs to know that aren't obvious from the code>
