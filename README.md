# Claude Autoresearch Skill

> Turn [Claude Code](https://docs.anthropic.com/en/docs/claude-code) into a relentless improvement engine.

Based on [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) — the principle that **constraint + mechanical metric + autonomous iteration = compounding gains**.

[![Claude Code Skill](https://img.shields.io/badge/Claude_Code-Skill-blue?logo=anthropic&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code)
[![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)](https://github.com/uditgoenka/autoresearch/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Based on](https://img.shields.io/badge/Based_on-Karpathy's_Autoresearch-orange)](https://github.com/karpathy/autoresearch)

---

## Commands Reference

| Command | Description | Since |
|---------|-------------|-------|
| `/autoresearch` | Run the autonomous iteration loop (unlimited) | v1.0.0 |
| `/loop N /autoresearch` | Run exactly N iterations then stop | v1.0.1 |
| `/autoresearch:plan` | Interactive wizard: Goal → Scope, Metric, Verify config | v1.0.2 |
| `/autoresearch:security` | Autonomous STRIDE + OWASP + red-team security audit | v1.0.3 |
| `/autoresearch:security --diff` | Delta mode — only audit files changed since last audit | v1.0.3 |
| `/autoresearch:security --fix` | Auto-fix confirmed Critical/High findings after audit | v1.0.3 |
| `/autoresearch:security --fail-on critical` | Exit non-zero if severity threshold met (CI/CD gate) | v1.0.3 |
| `/loop N /autoresearch:security` | Bounded security audit (N iterations) | v1.0.3 |
| `Guard: <command>` | Optional safety net — must pass for changes to be kept (regression prevention) | v1.0.4 |
| `/autoresearch:ship` | Universal shipping workflow — ship code, content, marketing, sales, research, design | v1.1.0 |
| `/autoresearch:ship --dry-run` | Validate everything but don't actually ship (stop before delivery) | v1.1.0 |
| `/autoresearch:ship --auto` | Auto-approve dry-run gate if no errors found | v1.1.0 |
| `/autoresearch:ship --rollback` | Undo the last ship action (if reversible) | v1.1.0 |
| `/autoresearch:ship --monitor N` | Post-ship health monitoring for N minutes | v1.1.0 |
| `/autoresearch:ship --checklist-only` | Generate and evaluate pre-ship checklist without shipping | v1.1.0 |
| `/autoresearch:ship --type <type>` | Override auto-detection (code-pr, deployment, content, marketing-email, sales, research, design) | v1.1.0 |

**Security audit includes:** STRIDE threat model, OWASP Top 10 (70+ checks), 4 red-team adversarial personas (Security Adversary, Supply Chain Attacker, Insider Threat, Infrastructure Attacker), proof-of-concept validation, structured report folder, historical comparison.

### Flag Combinations

```bash
# Full combo: delta + auto-fix + CI gate
/loop 15 /autoresearch:security --diff --fix --fail-on critical

# CI/CD: quick delta check, block on criticals
/loop 5 /autoresearch:security --diff --fail-on critical

# Overnight: comprehensive audit with auto-remediation
/autoresearch:security --fix

# Plan then run: wizard builds config, launches immediately
/autoresearch:plan

# Ship a PR with auto-approve
/autoresearch:ship --auto

# Dry-run a deployment before going live
/autoresearch:ship --type deployment --dry-run

# Ship with post-deploy monitoring (10 minutes)
/autoresearch:ship --type deployment --monitor 10

# Iterate on readiness then ship
/loop 5 /autoresearch:ship

# Just check if something is ready to ship
/autoresearch:ship --checklist-only
```

### Quick Decision Guide

| I want to... | Use |
|--------------|-----|
| Improve test coverage / reduce bundle size / any metric | `/autoresearch` or `/loop N /autoresearch` |
| Don't know what metric to use | `/autoresearch:plan` |
| Run a security audit | `/autoresearch:security` or `/loop 10 /autoresearch:security` |
| Red-team my codebase | `/autoresearch:security` (includes 4 adversarial personas) |
| Audit only changed files (PR review) | `/autoresearch:security --diff` |
| Auto-fix security issues | `/autoresearch:security --fix` |
| Block CI pipeline on vulnerabilities | `/autoresearch:security --fail-on critical` |
| Optimize without breaking existing tests | Add `Guard: npm test` to your config |
| Ship a PR / deployment / release | `/autoresearch:ship` or `/autoresearch:ship --auto` |
| Ship a blog post or documentation | `/autoresearch:ship --type content` |
| Ship a marketing email / campaign | `/autoresearch:ship --type marketing-email` |
| Ship a sales deck or proposal | `/autoresearch:ship --type sales` |
| Check if something is ready to ship | `/autoresearch:ship --checklist-only` |
| Validate before shipping (no side effects) | `/autoresearch:ship --dry-run` |
| Rollback a bad deployment | `/autoresearch:ship --rollback` |

### Guard — Prevent Regressions While Optimizing (v1.0.4)

When optimizing a metric (e.g., benchmark time), the loop might break existing behavior. **Guard** is an optional safety net — a command that must ALWAYS pass for a change to be kept.

```
/autoresearch
Goal: Reduce API response time to under 100ms
Metric: p95 response time in ms (lower is better)
Verify: npm run bench:api | grep "p95"
Guard: npm test
Scope: src/api/**/*.ts
```

**How it works:**
- **Verify** = "Did the metric improve?" (the goal)
- **Guard** = "Did anything else break?" (the safety net)

If the metric improves but the guard fails, Claude **reworks the optimization** (up to 2 attempts) to find an approach that improves the metric WITHOUT breaking the guard. Guard/test files are never modified.

**When to use Guard:**

| Scenario | Verify | Guard |
|----------|--------|-------|
| Reduce bundle size | `npm run build \| grep size` | `npm test` |
| Optimize Lighthouse | `npx lighthouse --output json` | `npm test` |
| Reduce LOC (refactoring) | `wc -l src/**/*.ts` | `npm test && npm run typecheck` |
| Improve benchmark time | `npm run bench` | `npm test` |
| Increase coverage | `jest --coverage` | *(no guard needed — tests ARE the metric)* |

Guard is **optional** — if not specified, the loop works exactly as before.

> **Credit:** Guard was contributed by [@pronskiy](https://github.com/pronskiy) (JetBrains) in [PR #7](https://github.com/uditgoenka/autoresearch/pull/7).

### Ship — Universal Shipping Workflow (v1.1.0)

Ship anything through a structured 8-phase workflow: **Identify → Inventory → Checklist → Prepare → Dry-run → Ship → Verify → Log.**

The key insight: shipping has a universal pattern regardless of what you're shipping. `/autoresearch:ship` applies autoresearch loop principles to the last mile — taking any artifact from "done" to "deployed/published/delivered."

**9 supported shipment types** (auto-detected from context):

| Type | What Gets Shipped | Example Ship Action |
|------|-------------------|---------------------|
| `code-pr` | Pull request | `gh pr create` with description |
| `code-release` | Version release | Git tag + GitHub release |
| `deployment` | Production deploy | CI/CD trigger, `kubectl apply` |
| `content` | Blog post / docs | Publish via CMS or content branch |
| `marketing-email` | Newsletter / campaign | Send via ESP (SendGrid, Mailchimp) |
| `marketing-campaign` | Ad campaign | Activate in ad platform |
| `sales` | Deck / proposal | Send email, share link |
| `research` | Paper / report | Upload to repository |
| `design` | Assets / mockups | Export and share with stakeholders |

**How it works:**

1. **Auto-detects** what you're shipping from context (or accept `--type`)
2. **Generates domain-specific checklist** — every item is mechanically verifiable (pass/fail)
3. **Runs autoresearch loop** to iteratively fix failing checklist items until 100% pass
4. **Dry-runs** the ship action without side effects (draft PR, test email, local build)
5. **Ships** — executes the actual delivery (merge, deploy, publish, send)
6. **Verifies** the thing actually landed (health checks, delivery confirmation)
7. **Logs** the shipment to `ship-log.tsv` for traceability

**Flags:** `--dry-run`, `--auto`, `--force`, `--rollback`, `--monitor N`, `--type <type>`, `--checklist-only`

```bash
# Ship with interactive approval
/autoresearch:ship

# Full auto — ship if checklist passes
/autoresearch:ship --auto

# Validate deployment without deploying
/autoresearch:ship --type deployment --dry-run

# Ship with 10-minute post-deploy monitoring
/autoresearch:ship --monitor 10

# Iterate on readiness before shipping
/loop 5 /autoresearch:ship

# Just check if ready to ship (no action)
/autoresearch:ship --checklist-only

# Undo a bad ship
/autoresearch:ship --rollback
```

**Composite readiness metric** (for bounded loops): `ship_score = (checklist_passing/total)*80 + (dry_run_passed ? 15 : 0) + (no_blockers ? 5 : 0)`. Score of 100 = ready. Below 80 = not shippable.

Non-reversible actions (email send) are flagged before execution. Rollback protocol supports all reversible ship types.

---

## What Is This?

A [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills) that makes Claude iterate autonomously on ANY task with a measurable outcome — like Karpathy's autoresearch, but generalized beyond ML.

```
You set the GOAL → Claude runs the LOOP → You wake up to results
```

**The loop:**

```
LOOP (FOREVER or N times):
  1. Review current state + git history + results log
  2. Pick the next change (based on what worked, what failed, what's untried)
  3. Make ONE focused change
  4. Git commit (before verification)
  5. Run mechanical verification (tests, benchmarks, scores)
  6. If improved → keep. If worse → git revert. If crashed → fix or skip.
  7. Log the result
  8. Repeat. Default: NEVER STOP. With /loop N: stop after N iterations.
```

Every improvement stacks. Every failure auto-reverts. Progress is logged in TSV format.

---

## Why This Exists

[Karpathy's autoresearch](https://github.com/karpathy/autoresearch) demonstrated that a 630-line Python script could autonomously improve ML models overnight — **100 experiments per night** — by following simple principles:

- **One metric** (validation loss)
- **Constrained scope** (one file)
- **Fast verification** (5-minute training runs)
- **Automatic rollback** on failure
- **Git as memory** for tracking what worked

**Claude Autoresearch generalizes these principles to ANY domain.** Not just ML — software engineering, content, sales, marketing, HR, operations, or anything with a number you can measure.

The insight: **autonomy scales when you constrain scope, clarify success, and mechanize verification.**

---

## Quick Start

### 1. Install the Skill

Clone this repo and copy the skill to your Claude Code skills directory:

```bash
# Clone
git clone https://github.com/uditgoenka/autoresearch.git

# Copy skill + subcommands to your project's Claude Code directory
cp -r autoresearch/skills/autoresearch .claude/skills/autoresearch
cp -r autoresearch/commands/autoresearch .claude/commands/autoresearch
```

Or copy directly into your global config:

```bash
cp -r autoresearch/skills/autoresearch ~/.claude/skills/autoresearch
cp -r autoresearch/commands/autoresearch ~/.claude/commands/autoresearch
```

> **Note:** The `commands/` directory is required for subcommands (`/autoresearch:ship`, `/autoresearch:plan`, `/autoresearch:security`) to be recognized by Claude Code. Without it, only `/autoresearch` will work.

### 2. Invoke It

Open Claude Code in your project and run:

```
/autoresearch
Goal: Increase test coverage from 72% to 90%
Scope: src/**/*.test.ts, src/**/*.ts
Metric: coverage % (higher is better)
Verify: npm test -- --coverage | grep "All files"
```

Or use the namespaced trigger:

```
/ug:autoresearch
Goal: Reduce bundle size below 200KB
Scope: src/**/*.tsx, src/**/*.ts
Metric: bundle size in KB (lower is better)
Verify: npm run build 2>&1 | grep "First Load JS"
```

### 3. Walk Away

Claude will:
1. Read all in-scope files
2. Establish a baseline measurement
3. Start iterating — one change at a time
4. Keep improvements, auto-revert failures
5. Log every iteration in `autoresearch-results.tsv`
6. Print a summary every 10 iterations
7. **Never stop until you interrupt** (or until N iterations complete in bounded mode)

---

## Plan Your Run with `/autoresearch:plan` (v1.0.2)

The hardest part of autoresearch isn't the loop — it's **defining Scope, Metric, and Verify** correctly. Get these wrong and the loop wastes iterations. Get them right and it's unstoppable.

`/autoresearch:plan` is an interactive wizard that converts your plain-language goal into a validated, ready-to-execute configuration.

### Usage

```
/autoresearch:plan
Goal: Make the API respond faster
```

Or inline:

```
/autoresearch:plan Increase test coverage to 95%
```

### What It Does

The wizard walks you through 5 questions (max) to nail down your configuration:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Step 1: CAPTURE GOAL                                   │
│  "What do you want to improve?"                         │
│                                                         │
│  Step 2: DEFINE SCOPE                                   │
│  "Which files can autoresearch modify?"                 │
│  → Scans codebase, suggests globs, validates matches    │
│                                                         │
│  Step 3: DEFINE METRIC                                  │
│  "What number tells you if things got better?"          │
│  → Suggests mechanical metrics based on your tooling    │
│  → REJECTS subjective metrics ("looks better")          │
│                                                         │
│  Step 4: DEFINE DIRECTION                               │
│  "Higher or lower is better?"                           │
│                                                         │
│  Step 5: DEFINE & VALIDATE VERIFY COMMAND               │
│  → Constructs the shell command                         │
│  → DRY-RUNS it on your codebase (mandatory)             │
│  → Confirms it outputs a parseable number               │
│  → Records baseline metric value                        │
│                                                         │
│  Step 6: CONFIRM & LAUNCH                               │
│  → Shows complete config                                │
│  → Option: launch now (unlimited or bounded) or copy    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Critical Validation Gates

The wizard **refuses to proceed** until:

| Gate | Requirement |
|------|-------------|
| Scope | Glob resolves to ≥1 file |
| Metric | Outputs a parseable number (not "PASS"/"FAIL"/subjective) |
| Verify | Dry-run succeeds (exit code 0 + extractable metric) |

This means when you launch, you **know** the loop will work. No wasted iterations debugging a broken verify command.

### Example Session

```
> /autoresearch:plan Reduce bundle size

[Scope]    Which files? → src/**/*.tsx, src/**/*.ts (127 files)
[Metric]   Bundle size in KB (lower is better)
[Verify]   npm run build 2>&1 | grep "First Load JS" | awk '{print $4}'
[Dry run]  ✓ Exit 0 — Baseline: 287KB

Ready-to-use:

  /autoresearch
  Goal: Reduce bundle size below 200KB
  Scope: src/**/*.tsx, src/**/*.ts
  Metric: bundle size in KB (lower is better)
  Verify: npm run build 2>&1 | grep "First Load JS" | awk '{print $4}'

Launch now? → [Unlimited] [Bounded] [Copy only]
```

### More Examples

**Test Coverage (Node.js)**
```
> /autoresearch:plan Increase test coverage to 95%

[Context]  Detected: Jest, TypeScript, 84 source files
[Scope]    src/**/*.ts, src/**/*.test.ts (84 + 31 files)
[Metric]   Coverage % from Jest (higher is better)
[Verify]   npx jest --coverage --silent 2>&1 | grep "All files" | awk '{print $4}'
[Dry run]  ✓ Exit 0 — Baseline: 72.3%

  /autoresearch
  Goal: Increase test coverage to 95%
  Scope: src/**/*.ts, src/**/*.test.ts
  Metric: coverage % (higher is better)
  Verify: npx jest --coverage --silent 2>&1 | grep "All files" | awk '{print $4}'
```

**Lighthouse Performance (Next.js)**
```
> /autoresearch:plan Improve page load speed

[Context]  Detected: Next.js, React, Tailwind, 23 components
[Scope]    src/app/**/*.tsx, src/components/**/*.tsx (41 files)
[Metric]   Lighthouse performance score 0-100 (higher is better)
[Verify]   npx lighthouse http://localhost:3000 --output json --quiet | jq '.categories.performance.score * 100'
[Dry run]  ✓ Exit 0 — Baseline: 68

  /autoresearch
  Goal: Lighthouse performance score above 90
  Scope: src/app/**/*.tsx, src/components/**/*.tsx
  Metric: Lighthouse performance score (higher is better)
  Verify: npx lighthouse http://localhost:3000 --output json --quiet | jq '.categories.performance.score * 100'
```

**TypeScript Strictness**
```
> /autoresearch:plan Eliminate all any types

[Context]  Detected: TypeScript 5.x, 147 source files
[Scope]    src/**/*.ts, src/**/*.tsx (147 files)
[Metric]   Count of `any` type annotations (lower is better)
[Verify]   grep -r ":\s*any" src/ --include="*.ts" --include="*.tsx" | wc -l | tr -d ' '
[Dry run]  ✓ Exit 0 — Baseline: 34

  /autoresearch
  Goal: Eliminate all TypeScript any types
  Scope: src/**/*.ts, src/**/*.tsx
  Metric: any count (lower is better)
  Verify: grep -r ":\s*any" src/ --include="*.ts" --include="*.tsx" | wc -l | tr -d ' '
```

**Python ML Training**
```
> /autoresearch:plan Reduce validation loss

[Context]  Detected: PyTorch, train.py, config.yaml
[Scope]    train.py, model.py (2 files)
[Metric]   val_bpb from training output (lower is better)
[Verify]   uv run train.py --epochs 1 2>&1 | grep "val_bpb" | tail -1 | awk '{print $NF}'
[Dry run]  ✓ Exit 0 — Baseline: 1.0821

  /autoresearch
  Goal: Reduce validation loss (val_bpb)
  Scope: train.py, model.py
  Metric: val_bpb (lower is better)
  Verify: uv run train.py --epochs 1 2>&1 | grep "val_bpb" | tail -1 | awk '{print $NF}'
```

**Content SEO Scoring**
```
> /autoresearch:plan Improve blog SEO scores

[Context]  Detected: Markdown blog posts, custom scoring script
[Scope]    content/blog/*.md (12 files)
[Metric]   Average SEO score across posts (higher is better)
[Verify]   node scripts/seo-score.js content/blog/ | grep "average" | awk '{print $2}'
[Dry run]  ✓ Exit 0 — Baseline: 64

  /autoresearch
  Goal: All blog posts score 80+ on SEO audit
  Scope: content/blog/*.md
  Metric: average SEO score (higher is better)
  Verify: node scripts/seo-score.js content/blog/ | grep "average" | awk '{print $2}'
```

**Docker Image Size**
```
> /autoresearch:plan Reduce Docker image size

[Context]  Detected: Dockerfile, .dockerignore, Node.js app
[Scope]    Dockerfile, .dockerignore (2 files)
[Metric]   Image size in MB (lower is better)
[Verify]   docker build -t bench . -q 2>&1 && docker images bench --format "{{.Size}}" | sed 's/MB//'
[Dry run]  ✓ Exit 0 — Baseline: 487

  /autoresearch
  Goal: Reduce Docker image size below 200MB
  Scope: Dockerfile, .dockerignore
  Metric: image size in MB (lower is better)
  Verify: docker build -t bench . -q 2>&1 && docker images bench --format "{{.Size}}" | sed 's/MB//'
```

### When to Use

| Situation | Use |
|-----------|-----|
| First time using autoresearch | `/autoresearch:plan` — learn the format |
| Unsure what metric to use | `/autoresearch:plan` — it suggests options |
| Want to validate before a long run | `/autoresearch:plan` — dry-run confirms it works |
| Know exactly what you want | `/autoresearch` directly — skip the wizard |
| Running overnight | `/autoresearch:plan` then launch — confidence before sleep |

---

## Autonomous Security Audit with `/autoresearch:security` (v1.0.3)

Turn Claude into an autonomous security auditor that iteratively discovers vulnerabilities using **STRIDE threat modeling**, **OWASP Top 10 sweeps**, and **red-team adversarial analysis**.

### Usage

```
# Unlimited — keep finding vulnerabilities until interrupted
/autoresearch:security

# Bounded — exactly 10 security sweep iterations
/loop 10 /autoresearch:security

# With focused scope
/autoresearch:security
Scope: src/api/**/*.ts, src/middleware/**/*.ts
Focus: authentication and authorization flows
```

### How It Works

Unlike standard autoresearch (which modifies code), `/autoresearch:security` is **read-only** — it analyzes code and reports findings without changing anything.

```
┌─────────────────────────────────────────────────────────────┐
│                    SETUP PHASE (once)                       │
│                                                             │
│  1. Codebase Recon     Scan tech stack, deps, configs       │
│  2. Asset Inventory    Data stores, auth, APIs, inputs      │
│  3. Trust Boundaries   Client↔Server, Public↔Auth, etc.     │
│  4. STRIDE Model       Full threat model per asset+boundary │
│  5. Attack Surface     Entry points, data flows, abuse paths│
│  6. Baseline           Run npm audit / existing tools       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    AUTONOMOUS LOOP                          │
│                                                             │
│  LOOP (FOREVER or N times):                                 │
│    1. Select untested attack vector from threat model       │
│    2. Deep-dive into target code                            │
│    3. Validate with code evidence (file:line + scenario)    │
│    4. Classify: severity + OWASP category + STRIDE tag      │
│    5. Log to security-audit-results.tsv                     │
│    6. Print coverage summary every 5 iterations             │
│    7. Repeat                                                │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    STRUCTURED REPORT FOLDER                 │
│                                                             │
│  security/260315-0945-stride-owasp-full-audit/              │
│  ├── overview.md              Executive summary + links     │
│  ├── threat-model.md          STRIDE analysis + assets      │
│  ├── attack-surface-map.md    Entry points + abuse paths    │
│  ├── findings.md              All findings by severity      │
│  ├── owasp-coverage.md        Coverage matrix per category  │
│  ├── dependency-audit.md      npm/pip/go audit results      │
│  ├── recommendations.md       Prioritized fixes + code      │
│  └── security-audit-results.tsv  Iteration log             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### STRIDE Threat Model

The setup phase generates a full threat model using Microsoft's STRIDE framework:

| Threat | Question | Example Findings |
|--------|----------|------------------|
| **S**poofing | Can an attacker impersonate a user/service? | Weak auth, missing CSRF, forged JWTs |
| **T**ampering | Can data be modified in transit/at rest? | Missing validation, SQL injection |
| **R**epudiation | Can actions be denied without evidence? | Missing audit logs, unsigned transactions |
| **I**nfo Disclosure | Can sensitive data leak? | PII in logs, verbose errors, debug endpoints |
| **D**enial of Service | Can the service be disrupted? | Missing rate limits, regex DoS |
| **E**levation of Privilege | Can a user gain unauthorized access? | IDOR, broken access control, path traversal |

### OWASP Top 10 Coverage

Each iteration targets uncovered OWASP categories. Coverage is tracked and reported:

| ID | Category | Checks |
|----|----------|--------|
| A01 | Broken Access Control | IDOR, missing auth middleware, privilege escalation |
| A02 | Cryptographic Failures | Plaintext secrets, weak hashing, missing encryption |
| A03 | Injection | SQL/NoSQL/command/XSS/template injection |
| A04 | Insecure Design | Missing rate limits, race conditions, CSRF gaps |
| A05 | Security Misconfiguration | Debug mode, default creds, missing headers |
| A06 | Vulnerable Components | Known CVEs in dependencies |
| A07 | Auth Failures | JWT flaws, session fixation, weak passwords |
| A08 | Data Integrity Failures | Unsigned webhooks, insecure deserialization |
| A09 | Logging Failures | Missing audit logs, sensitive data in logs |
| A10 | SSRF | Unvalidated URLs, DNS rebinding |

### Red-Team Adversarial Lenses

Inspired by the `/plan red-team` workflow, the security audit adopts four hostile perspectives:

| Persona | Mindset | Focus |
|---------|---------|-------|
| **Security Adversary** | "I'm a hacker breaching this system" | Auth bypass, injection, data exposure |
| **Supply Chain Attacker** | "I'm compromising deps or CI/CD" | CVEs, typosquatting, unsigned artifacts |
| **Insider Threat** | "I'm a malicious employee" | Privilege escalation, data exfiltration |
| **Infrastructure Attacker** | "I'm attacking deployment, not code" | Container escape, exposed services, env vars |

### Coverage Summary (Every 5 Iterations)

```
=== Security Audit Progress (iteration 10) ===
STRIDE Coverage: S[✓] T[✓] R[✗] I[✓] D[✓] E[✓] — 5/6
OWASP Coverage: A01[✓] A02[✗] A03[✓] A04[✗] A05[✓] A06[✓] A07[✓] A08[✗] A09[✗] A10[✗] — 5/10
Findings: 4 Critical, 2 High, 3 Medium, 1 Low
Confirmed: 7 | Likely: 2 | Possible: 1
```

### Example Session

```
> /loop 10 /autoresearch:security

[Setup] Scanning codebase...
  Tech stack: Next.js 16, TypeScript, MongoDB, JWT auth
  Assets: 3 data stores, 14 API routes, 2 external services
  Trust boundaries: 4 identified
  STRIDE threats: 18 modeled
  Attack vectors: 22 mapped
  Baseline: 3 npm audit warnings

[Iteration 1] Testing: IDOR on /api/users/:id
  → CONFIRMED HIGH (A01/EoP) — src/api/users.ts:42
    GET /api/users/:id returns any user data without ownership check

[Iteration 2] Testing: JWT validation
  → CONFIRMED CRITICAL (A07/Spoofing) — src/middleware/auth.ts:18
    JWT secret from env but no algorithm restriction — "none" algorithm accepted

[Iteration 3] Testing: Rate limiting on /api/auth/login
  → CONFIRMED MEDIUM (A04/DoS) — src/api/auth.ts:15
    No rate limiting on login endpoint — brute force possible

...

=== Security Audit Complete (10/10 iterations) ===
STRIDE Coverage: S[✓] T[✓] R[✗] I[✓] D[✓] E[✓] — 5/6
OWASP Coverage: A01[✓] A02[✓] A03[✓] A04[✓] A05[✓] A06[✓] A07[✓] A08[✗] A09[✗] A10[✗] — 7/10
Findings: 2 Critical, 3 High, 4 Medium, 1 Low

Report saved to:
  security/260315-0945-stride-owasp-full-audit/
  ├── overview.md           ← Start here
  ├── threat-model.md
  ├── attack-surface-map.md
  ├── findings.md
  ├── owasp-coverage.md
  ├── dependency-audit.md
  ├── recommendations.md
  └── security-audit-results.tsv
```

### Proof-of-Concept Validation (Inspired by Strix)

Every finding requires **code evidence** — no theoretical fluff:

```markdown
### [CRITICAL] Finding: JWT Algorithm Confusion
- **OWASP:** A07 — Auth Failures
- **STRIDE:** Spoofing
- **Location:** `src/middleware/auth.ts:18`
- **Confidence:** Confirmed
- **Attack Scenario:**
  1. Attacker crafts JWT with `"alg": "none"`
  2. Server accepts token without signature verification
  3. Attacker gains access as any user
- **Code Evidence:**
  ```typescript
  // Line 18 — no algorithm restriction
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  ```
- **Mitigation:**
  ```typescript
  const decoded = jwt.verify(token, process.env.JWT_SECRET, {
    algorithms: ['HS256'] // Explicitly restrict algorithms
  });
  ```
```

### Metric

The loop uses a composite coverage + findings metric:

```
metric = (owasp_tested/10)*50 + (stride_tested/6)*30 + min(findings, 20)
```

- **Direction:** higher is better (more coverage + more findings = more thorough)
- **Max theoretical:** 100
- Incentivizes covering ALL categories before going deep on any one

### Flags

| Flag | Purpose | Example |
|------|---------|---------|
| `--diff` | Only audit files changed since last audit | `/autoresearch:security --diff` |
| `--fix` | Auto-fix confirmed Critical/High after audit | `/autoresearch:security --fix` |
| `--fail-on` | Exit non-zero if severity threshold met | `--fail-on critical` |

Flags combine: `/loop 15 /autoresearch:security --diff --fix --fail-on critical`

**Execution order:** `--diff` narrows scope → audit runs → `--fix` remediates → `--fail-on` gates remaining findings.

### Delta Mode (`--diff`)

Only audits files changed since the last security audit. Reads the most recent `security/` subfolder for baseline.

```
/autoresearch:security --diff
```

Output includes a delta summary:

```
## Delta Summary (vs 260310-1430-stride-owasp-full-audit)

| Status | Count |
|--------|-------|
| New findings | 3 |
| Fixed | 2 |
| Recurring | 5 |
| Files changed | 12 |
```

### Auto-Fix Mode (`--fix`)

After the audit completes, switches to standard autoresearch modify→verify loop to fix confirmed findings:

```
/loop 15 /autoresearch:security --fix
```

- Only fixes **Confirmed Critical and High** findings
- Uses mitigations from `recommendations.md` as guidance
- Commits each fix, verifies the vulnerability is gone, reverts if tests break
- Maximum 3 attempts per finding, then skips
- Creates `fix-log.md` in the audit folder

### CI/CD Gate (`--fail-on`)

Exits non-zero if findings meet severity threshold — designed for pipeline blocking:

```
/loop 10 /autoresearch:security --fail-on critical
```

| Value | Blocks on |
|-------|-----------|
| `critical` | Any Critical finding |
| `high` | Any Critical or High |
| `medium` | Any Critical, High, or Medium |

### CI/CD GitHub Action (Auto-Generated)

When a `.github/workflows/` directory is detected, the wizard offers to generate a security audit workflow:

```yaml
# .github/workflows/security-audit.yml (auto-generated)
name: Security Audit
on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * 1'  # Weekly Monday 2am

jobs:
  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Security Audit
        run: |
          # Delta on PRs, full on schedule
          if [ "${{ github.event_name }}" = "pull_request" ]; then
            claude -p "/loop 5 /autoresearch:security --diff --fail-on critical"
          else
            claude -p "/loop 15 /autoresearch:security --fail-on high"
          fi
      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: security-report
          path: security/
```

### Historical Comparison

When previous audits exist in `security/`, the current run auto-generates a comparison:

```
## Historical Comparison (vs 260310 audit)

| Metric | Previous | Current | Change |
|--------|----------|---------|--------|
| Critical | 3 | 1 | ↓ -2 |
| High | 4 | 5 | ↑ +1 |
| Total | 9 | 9 | → 0 |
| OWASP coverage | 6/10 | 8/10 | ↑ +2 |

Finding Status:
  Fixed: 4 | New: 4 | Recurring: 5
```

Each finding in `findings.md` gets tagged: 🆕 New, 🔄 Recurring, or ✅ Fixed.

### When to Use

| Scenario | Recommendation |
|----------|---------------|
| Before a major release | `/loop 15 /autoresearch:security` |
| Quick sanity check | `/loop 5 /autoresearch:security` |
| Comprehensive overnight audit | `/autoresearch:security` (unlimited) |
| CI/CD security gate | `/loop 10 /autoresearch:security --fail-on critical` |
| PR review (changed files only) | `/loop 5 /autoresearch:security --diff` |
| After adding auth/API changes | `/autoresearch:security --diff --fix` |
| Compliance preparation | `/loop 20 /autoresearch:security` (max coverage) |
| Track security posture over time | Run weekly, review historical comparison |

---

## Controlled Iterations with `/loop` (v1.0.1)

> **Requires:** Claude Code **v1.0.32+** (the `/loop` command was introduced in this version)

By default, autoresearch loops **forever** until manually interrupted. Starting in v1.0.1, you can optionally specify a **loop count** using Claude Code's built-in `/loop` command to run a fixed number of iterations.

### Usage

**Unlimited (default) — loop forever:**
```
/autoresearch
Goal: Increase test coverage to 90%
```

**Bounded — run exactly N iterations:**
```
/loop 25 /autoresearch
Goal: Increase test coverage to 90%
```

This chains `/autoresearch` with `/loop 25`, running exactly 25 iteration cycles. After 25 iterations, Claude stops and prints a final summary.

### When to Use Bounded Loops

| Scenario | Recommendation |
|----------|---------------|
| Run overnight, review in morning | Unlimited (default) |
| Quick 30-min improvement session | `/loop 10 /autoresearch` |
| Targeted fix with known scope | `/loop 5 /autoresearch` |
| Exploratory — see if approach works | `/loop 15 /autoresearch` |
| CI/CD pipeline integration | `/loop N /autoresearch` (set N based on time budget) |

### Behavior with Loop Count

When a loop count is specified:
- Claude runs exactly **N iterations** through the autoresearch loop
- After iteration N, Claude prints a **final summary** with baseline → current best, keeps/discards/crashes
- If the goal is achieved before N iterations, Claude prints **early completion** and stops
- All other rules (atomic changes, mechanical verification, auto-rollback) still apply
- When **fewer than 3 iterations remain**, Claude prioritizes **exploiting successes** over exploration

### Final Summary Format

```
=== Autoresearch Complete (25/25 iterations) ===
Baseline: 72.0% → Final: 89.3% (+17.3%)
Keeps: 12 | Discards: 11 | Crashes: 2
Best iteration: #18 — add tests for payment processing edge cases
```

---

## How It Works

### The Setup Phase

Before looping, Claude performs a one-time setup:

| Step | What Happens |
|------|-------------|
| 1. Read context | Reads all in-scope files for full understanding |
| 2. Define goal | Extracts or asks for a mechanical metric |
| 3. Define scope | Identifies which files can be modified vs read-only |
| 4. Create results log | Initializes `autoresearch-results.tsv` |
| 5. Establish baseline | Runs verification on current state (iteration #0) |
| 6. Confirm and go | Shows setup to user, then begins the loop |

### The Autonomous Loop

Each iteration follows an 8-phase protocol:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  Phase 1: REVIEW                                    │
│  Read current files + git log + results log         │
│                                                     │
│  Phase 2: IDEATE                                    │
│  Pick next change based on patterns and gaps        │
│                                                     │
│  Phase 3: MODIFY                                    │
│  Make ONE atomic change (explainable in 1 sentence) │
│                                                     │
│  Phase 4: COMMIT                                    │
│  Git commit BEFORE verification (clean rollback)    │
│                                                     │
│  Phase 5: VERIFY                                    │
│  Run mechanical metric command                      │
│                                                     │
│  Phase 6: DECIDE                                    │
│  Improved → keep | Worse → revert | Crash → fix    │
│                                                     │
│  Phase 7: LOG                                       │
│  Append result to autoresearch-results.tsv          │
│                                                     │
│  Phase 8: REPEAT                                    │
│  Go to Phase 1. Default: forever. /loop N: N times. │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Results Tracking

Every iteration is logged in TSV format:

```tsv
iteration	commit	metric	delta	status	description
0	a1b2c3d	85.2	0.0	baseline	initial state — test coverage 85.2%
1	b2c3d4e	87.1	+1.9	keep	add tests for auth middleware edge cases
2	-	86.5	-0.6	discard	refactor test helpers (broke 2 tests)
3	-	0.0	0.0	crash	add integration tests (DB connection failed)
4	c3d4e5f	88.3	+1.2	keep	add tests for error handling in API routes
5	d4e5f6g	89.0	+0.7	keep	add boundary value tests for validators
```

Every 10 iterations, Claude prints a summary:

```
=== Autoresearch Progress (iteration 20) ===
Baseline: 85.2% → Current best: 92.1% (+6.9%)
Keeps: 8 | Discards: 10 | Crashes: 2
Last 5: keep, discard, discard, keep, keep
```

---

## Usage Examples

### Software Engineering

**Increase test coverage**
```
/autoresearch
Goal: Increase test coverage from 72% to 90%
Scope: src/**/*.test.ts, src/**/*.ts
Metric: coverage % (higher is better)
Verify: npm test -- --coverage | grep "All files"
```

Bounded variant — run 20 iterations then stop:
```
/loop 20 /autoresearch
Goal: Increase test coverage from 72% to 90%
Scope: src/**/*.test.ts, src/**/*.ts
Metric: coverage % (higher is better)
Verify: npm test -- --coverage | grep "All files"
```
Claude adds tests one-by-one. Each iteration: write test → run coverage → keep if % increased → discard if not → repeat.

**Reduce bundle size**
```
/loop 15 /autoresearch
Goal: Reduce production bundle size
Scope: src/**/*.tsx, src/**/*.ts
Metric: bundle size in KB (lower is better)
Verify: npm run build 2>&1 | grep "First Load JS"
```
Claude tries: tree-shaking unused imports, lazy-loading routes, replacing heavy libraries, code-splitting — one change at a time. 15 iterations is usually enough to find the big wins.

**Fix flaky tests**
```
/loop 10 /autoresearch
Goal: Zero flaky tests (all tests pass 5 consecutive runs)
Scope: src/**/*.test.ts
Metric: failure count across 5 runs (lower is better)
Verify: for i in {1..5}; do npm test 2>&1; done | grep -c "FAIL"
```

**Performance optimization**
```
/autoresearch
Goal: API response time under 100ms (p95)
Scope: src/api/**/*.ts, src/services/**/*.ts
Metric: p95 response time in ms (lower is better)
Verify: npm run bench:api | grep "p95"
```

Bounded — quick 30-minute session:
```
/loop 10 /autoresearch
Goal: API response time under 100ms (p95)
Scope: src/api/**/*.ts, src/services/**/*.ts
Metric: p95 response time in ms (lower is better)
Verify: npm run bench:api | grep "p95"
```

**Eliminate TypeScript `any` types**
```
/loop 25 /autoresearch
Goal: Eliminate all TypeScript `any` types
Scope: src/**/*.ts
Metric: count of `any` occurrences (lower is better)
Verify: grep -r ":\s*any" src/ --include="*.ts" | wc -l
```

**Reduce lines of code**
```
/loop 20 /autoresearch
Goal: Reduce lines of code in src/services/ by 30% while keeping all tests green
Metric: LOC count (lower is better)
Verify: npm test && find src/services -name "*.ts" | xargs wc -l | tail -1
```

---

### Sales

**Cold email optimization**
```
/loop 15 /autoresearch
Goal: Improve cold email reply rate prediction score
Scope: content/email-templates/*.md
Metric: readability score + personalization token count (higher is better)
Verify: node scripts/score-email-template.js
```
Claude iterates on subject lines, opening hooks, CTAs, personalization variables — keeping changes that score higher. 15 iterations for a focused session.

**Sales deck refinement**
```
/loop 10 /autoresearch
Goal: Reduce slide count while maintaining all key points
Scope: content/sales-deck/*.md
Metric: slide count (lower is better), constraint: key-points-checklist.md must all be present
Verify: node scripts/check-deck-coverage.js && wc -l content/sales-deck/*.md
```

**Objection handling docs**
```
/loop 20 /autoresearch
Goal: Cover all 20 common objections with responses under 50 words each
Scope: content/objection-responses.md
Metric: objections covered + avg word count per response (more covered + fewer words = better)
Verify: node scripts/score-objections.js
```

---

### Marketing

**SEO content optimization**
```
/autoresearch
Goal: Maximize SEO score for target keywords
Scope: content/blog/*.md
Metric: SEO score from audit tool (higher is better)
Verify: node scripts/seo-score.js --file content/blog/target-post.md
```
Claude tweaks headings, keyword density, meta descriptions, internal links — one change per iteration. Run unlimited overnight, or bounded:
```
/loop 25 /autoresearch
Goal: Maximize SEO score for target keywords
```

**Landing page copy**
```
/loop 15 /autoresearch
Goal: Maximize Flesch readability + keyword density for "AI automation"
Scope: content/landing-pages/ai-automation.md
Metric: readability_score * 0.7 + keyword_density_score * 0.3 (higher is better)
Verify: node scripts/content-score.js content/landing-pages/ai-automation.md
```

**Email sequence optimization**
```
/loop 20 /autoresearch
Goal: Optimize 7-day nurture sequence for clarity and CTA strength
Scope: content/email-sequences/onboarding/*.md
Metric: avg readability + CTA score per email (higher is better)
Verify: node scripts/score-email-sequence.js onboarding
```

**Ad copy variants**
```
/loop 25 /autoresearch
Goal: Generate and refine 20 ad copy variants, each under 90 chars with power words
Scope: content/ads/facebook-q1.md
Metric: variants meeting criteria (higher is better)
Verify: node scripts/validate-ad-copy.js
```

---

### HR & People Ops

**Job description optimization**
```
/loop 15 /autoresearch
Goal: Improve job descriptions — bias-free language, clear requirements, inclusive tone
Scope: content/job-descriptions/*.md
Metric: inclusivity score from textio-style checker (higher is better)
Verify: node scripts/jd-inclusivity-score.js
```

**Policy document clarity**
```
/loop 10 /autoresearch
Goal: Reduce average reading level of HR policies to grade 8
Scope: content/policies/*.md
Metric: Flesch-Kincaid grade level (lower is better)
Verify: node scripts/readability.js content/policies/
```

**Interview question bank**
```
/loop 20 /autoresearch
Goal: Ensure all questions are behavioral (STAR format) + cover all competencies
Scope: content/interview-questions.md
Metric: STAR-format compliance % + competency coverage % (higher is better)
Verify: node scripts/interview-quality.js
```

---

### Operations

**Runbook optimization**
```
/loop 15 /autoresearch
Goal: Reduce average runbook steps while maintaining completeness
Scope: docs/runbooks/*.md
Metric: avg steps per runbook (lower is better), constraint: all checklist items preserved
Verify: node scripts/runbook-audit.js
```

**Process documentation**
```
/loop 10 /autoresearch
Goal: Standardize all SOPs to template format with <100 words per step
Scope: docs/sops/*.md
Metric: template compliance % + avg words per step (higher compliance + lower words = better)
Verify: node scripts/sop-score.js
```

**Incident response playbooks**
```
/loop 20 /autoresearch
Goal: Ensure all playbooks have decision trees, escalation paths, rollback steps
Scope: docs/incident-playbooks/*.md
Metric: completeness checklist score (higher is better)
Verify: node scripts/playbook-completeness.js
```

---

### Performance Marketing

**Google Ads copy optimization**
```
/loop 30 /autoresearch
Goal: Generate 50 ad headline variants (max 30 chars) with power words + CTA
Scope: content/ads/google-search/*.md
Metric: headlines meeting char limit + power word + CTA criteria (higher is better)
Verify: node scripts/google-ads-validator.js --type headlines
```
Claude generates headline variants, scores each for character limits, emotional triggers, and CTA presence — discarding any that don't meet criteria. 30 iterations to build up 50 variants.

**Landing page CRO (Conversion Rate Optimization)**
```
/loop 15 /autoresearch
Goal: Maximize landing page quality score — clear CTA, social proof, urgency, mobile-friendly structure
Scope: content/landing-pages/product-launch.md
Metric: CRO checklist score (higher is better)
Verify: node scripts/cro-score.js content/landing-pages/product-launch.md
```

**Meta/Facebook ad copy variants**
```
/loop 25 /autoresearch
Goal: Create 30 primary text variants (max 125 chars) optimized for engagement
Scope: content/ads/meta/*.md
Metric: variants meeting criteria + avg engagement score (higher is better)
Verify: node scripts/meta-ad-validator.js
```

**A/B test hypothesis generation**
```
/loop 20 /autoresearch
Goal: Generate 20 testable hypotheses for checkout page, each with metric + expected lift
Scope: content/experiments/checkout-hypotheses.md
Metric: valid hypotheses with metric + lift prediction (higher is better)
Verify: node scripts/hypothesis-validator.js
```

**UTM campaign taxonomy**
```
/loop 10 /autoresearch
Goal: Standardize all campaign URLs with consistent UTM parameters
Scope: content/campaigns/utm-tracker.csv
Metric: UTM compliance % (higher is better)
Verify: node scripts/utm-validator.js
```

**Email subject line A/B testing**
```
/loop 30 /autoresearch
Goal: Generate 40 subject lines for product launch — max 50 chars, personalization token, urgency
Scope: content/emails/subject-lines.md
Metric: lines meeting all criteria (higher is better)
Verify: node scripts/subject-line-scorer.js
```

---

### Data Science & Analytics

**Data pipeline quality**
```
/loop 20 /autoresearch
Goal: Increase data validation pass rate from 85% to 99%
Scope: scripts/validators/*.py
Metric: validation pass rate % (higher is better)
Verify: python scripts/run_validations.py | grep "pass_rate"
```

**SQL query optimization**
```
/loop 15 /autoresearch
Goal: Reduce total query execution time for dashboard queries
Scope: queries/dashboard/*.sql
Metric: total execution time in ms (lower is better)
Verify: psql -f scripts/bench-queries.sql | grep "total_ms"
```

**Report template automation**
```
/loop 10 /autoresearch
Goal: Standardize all weekly reports — consistent sections, KPI coverage, action items
Scope: templates/reports/*.md
Metric: template compliance score (higher is better)
Verify: node scripts/report-template-audit.js
```

---

### DevOps & Infrastructure

**Dockerfile optimization**
```
/loop 10 /autoresearch
Goal: Reduce Docker image size and build time
Scope: Dockerfile, .dockerignore
Metric: image size in MB (lower is better)
Verify: docker build -t bench . 2>&1 && docker images bench --format "{{.Size}}"
```

**CI/CD pipeline speed**
```
/loop 15 /autoresearch
Goal: Reduce CI pipeline duration from 12min to under 5min
Scope: .github/workflows/*.yml
Metric: pipeline duration in seconds (lower is better)
Verify: node scripts/estimate-ci-time.js
```

**Terraform/IaC compliance**
```
/loop 20 /autoresearch
Goal: Pass all tfsec security checks + reduce resource count
Scope: infra/*.tf
Metric: tfsec violations (lower is better)
Verify: tfsec . --format json | jq '.results | length'
```

---

### Design & Accessibility

**Accessibility audit**
```
/loop 25 /autoresearch
Goal: Reach WCAG 2.1 AA compliance — zero axe violations
Scope: src/components/**/*.tsx
Metric: axe violation count (lower is better)
Verify: npx playwright test a11y.spec.ts | grep "violations"
```

**Design token consistency**
```
/loop 20 /autoresearch
Goal: Replace all hardcoded colors/spacing with design tokens
Scope: src/**/*.tsx, src/**/*.css
Metric: hardcoded values count (lower is better)
Verify: grep -rE "#[0-9a-fA-F]{3,6}|px\b" src/ --include="*.tsx" --include="*.css" | wc -l
```

---

## Combining with MCP Servers

Claude Code supports [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) servers, which give Claude access to external tools and APIs. When combined with autoresearch, this unlocks **real-time data-driven iteration loops**.

### How It Works

MCP servers expose tools that Claude can call during the autoresearch loop. Instead of just reading files and running scripts, Claude can:

- **Query databases** to verify data changes
- **Call APIs** to test integrations
- **Fetch analytics** to measure real-world impact
- **Interact with external services** as part of verification

### Pattern: Database-Driven Iteration

Use a PostgreSQL MCP server to iterate on query performance:

```
/autoresearch
Goal: Optimize slow dashboard queries — reduce p95 query time
Scope: queries/dashboard/*.sql
Metric: avg query time in ms (lower is better)
Verify: Use MCP postgres tool to run EXPLAIN ANALYZE on each query, sum total costs
```

Claude rewrites queries one at a time, uses the MCP Postgres tool to benchmark each change, and keeps only improvements.

### Pattern: API Integration Testing

Use an HTTP/API MCP server to verify endpoint behavior:

```
/autoresearch
Goal: All API endpoints return valid JSON with correct status codes in <200ms
Scope: src/api/**/*.ts
Metric: endpoints passing all checks (higher is better)
Verify: Use MCP HTTP tool to hit each endpoint, validate response schema + timing
```

### Pattern: Analytics-Driven Content Optimization

Use a Google Analytics or Plausible MCP server:

```
/autoresearch
Goal: Improve blog post structure based on engagement metrics
Scope: content/blog/*.md
Metric: avg time on page for modified posts (higher is better)
Verify: Use MCP analytics tool to fetch page metrics, compare against baseline
```

### Pattern: CRM + Sales Automation

Use a HubSpot/Salesforce MCP server:

```
/autoresearch
Goal: Optimize email templates based on actual open/reply rates
Scope: content/email-templates/*.md
Metric: avg open rate from CRM data (higher is better)
Verify: Use MCP CRM tool to pull latest campaign metrics for template variants
```

### Pattern: Cloud Infrastructure Monitoring

Use an AWS/GCP MCP server:

```
/autoresearch
Goal: Reduce Lambda cold start times across all functions
Scope: src/lambdas/**/*.ts
Metric: avg cold start time in ms (lower is better)
Verify: Use MCP CloudWatch tool to query p95 cold start durations
```

### Pattern: GitHub Issue Triage

Use the GitHub MCP server:

```
/autoresearch
Goal: Auto-label and categorize 100+ open issues by type and priority
Scope: scripts/issue-triage.js
Metric: issues correctly labeled (higher is better)
Verify: Use MCP GitHub tool to fetch issues, compare labels against rules
```

### Recommended MCP Servers for Autoresearch

| MCP Server | Use Case | Metric Source |
|---|---|---|
| **PostgreSQL** | Query optimization, data validation | Query execution time, row counts |
| **GitHub** | Issue triage, PR quality, CI status | Issue counts, check pass rates |
| **Filesystem** | File organization, cleanup | File counts, directory depth |
| **Puppeteer/Playwright** | Visual regression, performance | Lighthouse scores, screenshot diffs |
| **Slack** | Notification quality, alert tuning | Message delivery, response times |
| **Stripe** | Payment flow optimization | Checkout completion rates |
| **Sentry** | Error reduction | Error count, crash-free rate |
| **Cloudflare** | Edge performance | Cache hit rate, TTFB |

---

## Combining with APIs

Beyond MCP, Claude can call APIs directly via scripts in the verification step. This enables real-world measurement loops.

### Pattern: Lighthouse via API

```javascript
// scripts/lighthouse-score.js
const { exec } = require('child_process');
exec('npx lighthouse http://localhost:3000 --output json --quiet', (err, stdout) => {
  const report = JSON.parse(stdout);
  const perf = report.categories.performance.score * 100;
  console.log(`SCORE: ${perf}`);
  process.exit(perf > 0 ? 0 : 1);
});
```

```
/autoresearch
Goal: Lighthouse performance score above 95
Scope: src/components/**/*.tsx, src/app/**/*.tsx
Metric: Lighthouse performance score (higher is better)
Verify: node scripts/lighthouse-score.js
```

### Pattern: OpenAI/Anthropic API for Content Scoring

Use an LLM API call as the verification step to score content quality:

```javascript
// scripts/content-quality-scorer.js
const Anthropic = require('@anthropic-ai/sdk');
const fs = require('fs');

const content = fs.readFileSync(process.argv[2], 'utf-8');
const client = new Anthropic();

async function score() {
  const msg = await client.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 100,
    messages: [{ role: 'user', content: `Score this content 0-100 for clarity, engagement, and SEO. Return ONLY a number.\n\n${content}` }]
  });
  const score = parseInt(msg.content[0].text.trim());
  console.log(`SCORE: ${score}`);
  process.exit(0);
}
score();
```

```
/autoresearch
Goal: All blog posts score 80+ on AI-assessed quality
Scope: content/blog/*.md
Metric: quality score from Haiku (higher is better)
Verify: node scripts/content-quality-scorer.js content/blog/latest.md
```

### Pattern: PageSpeed Insights API

```javascript
// scripts/pagespeed-score.js
const https = require('https');
const url = `https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=${process.argv[2]}&key=${process.env.PSI_API_KEY}`;
https.get(url, res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const score = JSON.parse(data).lighthouseResult.categories.performance.score * 100;
    console.log(`SCORE: ${score}`);
  });
});
```

### Pattern: Stripe Checkout Flow Testing

```
/autoresearch
Goal: Reduce checkout page load time and increase Stripe test payment success rate
Scope: src/checkout/**/*.tsx
Metric: checkout flow success rate % (higher is better)
Verify: node scripts/test-checkout-flow.js
```

### Pattern: Email Deliverability Scoring

```
/autoresearch
Goal: Improve email deliverability — reduce spam score across all templates
Scope: content/email-templates/*.html
Metric: SpamAssassin score (lower is better)
Verify: node scripts/spam-score.js content/email-templates/
```

---

## Claude Code Patterns

### Pattern 1: "Run Overnight"

Tell Claude to iterate while you sleep. The loop never stops until you interrupt.

```
/autoresearch
Goal: Improve lighthouse score from 72 to 95+
I'm going to sleep — iterate all night. Don't ask me anything.
```

### Pattern 2: "Controlled Sprint"

Run a fixed number of iterations for a focused improvement session (requires Claude Code v1.0.32+).

```
/loop 15 /autoresearch
Goal: Increase test coverage from 72% to 85%
Focus on the modules with lowest coverage first.
```

### Pattern 3: "Compound Improvements"

Stack small wins. Each kept commit builds on the last.

```
/autoresearch
Goal: Reduce TypeScript errors from 47 to 0
Start with the easiest fixes. Build momentum. Save hardest for last.
```

### Pattern 4: "Explore and Exploit"

Let Claude try bold experiments, auto-reverting failures.

```
/autoresearch
Goal: Reduce API response time
Try radical approaches too — different data structures, caching strategies, query rewrites.
If stuck after 5 discards, try something completely different.
```

### Pattern 5: "Refactor Without Breaking"

Safe refactoring with automatic rollback safety net.

```
/autoresearch
Goal: Reduce lines of code in src/services/ by 30% while keeping all tests green
Metric: LOC count (lower is better)
Verify: npm test && find src/services -name "*.ts" | xargs wc -l | tail -1
```

### Pattern 6: "Content Factory"

Batch-produce content that meets quality gates.

```
/autoresearch
Goal: Write 20 blog post outlines, each with 5+ sections, 3+ internal link opportunities
Scope: content/outlines/*.md
Metric: outlines meeting criteria (higher is better)
Verify: node scripts/outline-validator.js
```

### Pattern 7: "Progressive Hardening"

Start lenient, tighten criteria as baseline improves.

```
/autoresearch
Goal: Phase 1 — all tests pass. Phase 2 — coverage >80%. Phase 3 — zero linting errors.
Advance to next phase only when current is stable for 3 consecutive iterations.
```

---

## Writing Verification Scripts

The skill works best when verification is **fast and mechanical**. Here's a template:

```javascript
// scripts/score-example.js — Template for custom scoring
const fs = require('fs');
const file = process.argv[2];
const content = fs.readFileSync(file, 'utf-8');

// Your scoring logic here
const score = content.split('\n').filter(l => l.startsWith('- ')).length;

// Output MUST be a single number on its own line for easy parsing
console.log(`SCORE: ${score}`);
process.exit(score > 0 ? 0 : 1);
```

**Rules for good verification:**

| Rule | Why |
|------|-----|
| Runs in under 10 seconds | Fast = more iterations = more experiments |
| Outputs a single parseable number | Claude needs to extract the metric mechanically |
| Exit code 0 = success, non-zero = crash | Clean pass/fail signal |
| No human judgment required | Agent must decide autonomously |
| Deterministic (same input = same output) | Non-deterministic metrics break the feedback loop |

---

## Core Principles

These 7 principles are extracted from [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) and generalized to any domain:

### 1. Constraint = Enabler

Autonomy succeeds through intentional constraint, not despite it.

| Autoresearch | Generalized |
|---|---|
| 630-line codebase | Bounded scope that fits agent context |
| 5-minute time budget | Fixed iteration cost |
| One metric (val_bpb) | Single mechanical success criterion |

### 2. Separate Strategy from Tactics

Humans set direction (**what** to improve). Agents execute iterations (**how** to improve it).

| Strategic (Human) | Tactical (Agent) |
|---|---|
| "Improve page load speed" | "Lazy-load images, code-split routes" |
| "Increase test coverage" | "Add tests for uncovered edge cases" |
| "Refactor auth module" | "Extract middleware, simplify handlers" |

### 3. Metrics Must Be Mechanical

If you can't verify with a command, you can't iterate autonomously.

**Good:** `npm test -- --coverage | grep "All files"` → outputs `87.3%`

**Bad:** "Looks better", "probably improved", "seems cleaner" → kills the loop.

### 4. Verification Must Be Fast

| Fast (enables iteration) | Slow (kills iteration) |
|---|---|
| Unit tests (seconds) | Full E2E suite (minutes) |
| Type check (seconds) | Manual QA (hours) |
| Lint check (instant) | Code review (async) |

### 5. Iteration Cost Shapes Behavior

- **Cheap iteration** → bold exploration, many experiments
- **Expensive iteration** → conservative, few experiments

Autoresearch: 5-minute cost → 100 experiments/night.
Software: 10-second test → 360 experiments/hour.

### 6. Git as Memory

Every successful change is committed. Failures are reverted. This enables causality tracking, stacking wins, pattern learning, and human review.

### 7. Honest Limitations

If the agent hits a wall (missing permissions, external dependency, needs human judgment), it says so clearly instead of guessing.

---

## 8 Critical Rules

These rules govern Claude's behavior during the autonomous loop:

| # | Rule | Why |
|---|------|-----|
| 1 | **Loop until done** | Unbounded: loop until interrupted. Bounded (`/loop N`): loop N times then summarize. |
| 2 | **Read before write** | Always understand full context before modifying. |
| 3 | **One change per iteration** | Atomic changes — if it breaks, you know exactly why. |
| 4 | **Mechanical verification only** | No subjective "looks good." Use metrics. |
| 5 | **Automatic rollback** | Failed changes revert instantly. No debates. |
| 6 | **Simplicity wins** | Equal results + less code = KEEP. Tiny gain + ugly complexity = DISCARD. |
| 7 | **Git is memory** | Every kept change committed. Agent reads history to learn patterns. |
| 8 | **When stuck, think harder** | Re-read files, combine near-misses, try radical changes. |

---

## Crash Recovery

Claude handles failures automatically:

| Failure Type | Response |
|---|---|
| Syntax error | Fix immediately, don't count as separate iteration |
| Runtime error | Attempt fix (max 3 tries), then move on |
| Resource exhaustion (OOM) | Revert, try smaller variant |
| Infinite loop / hang | Kill after timeout, revert, avoid that approach |
| External dependency failure | Skip, log, try different approach |

---

## Repository Structure

```
autoresearch/
├── README.md                                          ← You are here
├── LICENSE                                            ← MIT License
└── skills/
    └── autoresearch/
        ├── SKILL.md                                   ← Main skill (loaded by Claude Code)
        └── references/
            ├── autonomous-loop-protocol.md            ← Detailed 8-phase loop protocol
            ├── core-principles.md                     ← 7 universal principles
            ├── plan-workflow.md                        ← /autoresearch:plan wizard protocol
            ├── security-workflow.md                   ← /autoresearch:security audit protocol
            └── results-logging.md                     ← TSV tracking format + reporting
```

---

## About Karpathy's Autoresearch

[Autoresearch](https://github.com/karpathy/autoresearch) is Andrej Karpathy's framework for autonomous ML research. Key insights:

- **630 lines of Python** — intentionally small so an LLM can hold the entire codebase in context
- **One GPU, one file, one metric** — constraints enable autonomy
- **5-minute training runs** — cheap iterations mean bold experiments
- **100 experiments per night** — compound gains while humans sleep
- **Git as memory** — every experiment tracked, successes committed, failures reverted

**Claude Autoresearch takes these principles and generalizes them.** Instead of training ML models, Claude can autonomously iterate on:

- Code quality (tests, coverage, performance, bundle size)
- Content quality (readability, SEO, keyword density)
- Documentation (completeness, clarity, compliance)
- Any task where "better" = a number you can measure with a command

The meta-principle:

> Autonomy scales when you constrain scope, clarify success, mechanize verification, and let agents optimize tactics while humans optimize strategy.

---

## FAQ

**Q: I don't know what metric or verify command to use. How do I get started?**
A: Run `/autoresearch:plan` — the planning wizard analyzes your codebase, suggests metrics based on your tooling, constructs a verify command, and dry-runs it before you launch. It's the easiest way to get started.

**Q: Can autoresearch do security audits?**
A: Yes! Run `/autoresearch:security` (or `/loop 10 /autoresearch:security` for bounded). It generates a full STRIDE threat model, maps attack surfaces, then iteratively tests each vulnerability vector with code evidence. Reports findings ranked by severity with OWASP Top 10 mapping and concrete mitigations. It's read-only — analyzes code without modifying it.

**Q: Does /autoresearch:security actually modify my code?**
A: No. Unlike standard `/autoresearch` which modifies and tests code, `/autoresearch:security` is **read-only**. It analyzes your codebase and produces a structured report folder at `security/{date}-{time}-{slug}/` with 7 markdown files covering threat model, findings, OWASP coverage, dependency audit, and prioritized recommendations. It does not fix vulnerabilities — that's your decision.

**Q: Where are the security reports saved?**
A: Each run creates a timestamped folder inside `security/` at your project root — e.g., `security/260315-0945-stride-owasp-full-audit/`. Start reading at `overview.md` which links to all other files. Reports are designed to be committed and shared with your team.

**Q: Does this work with any Claude Code project?**
A: Yes. Copy the skill to `.claude/skills/autoresearch/` in any project. It works with any language, framework, or domain.

**Q: How do I stop the loop?**
A: Press `Ctrl+C` or close the terminal. Or use `/loop N /autoresearch` to run exactly N iterations and stop automatically. Claude commits before verifying, so your last successful state is always preserved in git.

**Q: How do I run a fixed number of iterations?**
A: Use `/loop N /autoresearch` (requires Claude Code v1.0.32+). For example, `/loop 25 /autoresearch` runs exactly 25 iterations then prints a summary and stops. See the "Controlled Iterations" section above.

**Q: What if my verification takes too long?**
A: Aim for under 10 seconds. Longer verification = fewer experiments = slower progress. Use the fastest check that still catches real problems.

**Q: Can I use this for non-code tasks?**
A: Absolutely. Sales emails, marketing copy, HR policies, runbooks — anything with a measurable metric. See the examples above.

**Q: What happens if Claude gets stuck?**
A: After 5+ consecutive discards, Claude automatically: re-reads all files, reviews the results log for patterns, tries combining near-misses, attempts the opposite of what hasn't been working, and tries radical changes.

**Q: Is the results log committed to git?**
A: No. Add `autoresearch-results.tsv` to `.gitignore`. It's a working file for the agent, not part of your codebase.

**Q: Can I review what Claude did?**
A: Yes. Every kept change is a git commit with a descriptive message. Run `git log --oneline` to see the full history of experiments.

**Q: Can I use MCP servers with autoresearch?**
A: Yes. Any MCP server configured in your Claude Code environment is available during the loop. Claude can query databases, call APIs, fetch analytics, and interact with external services as part of the verification step. See the "Combining with MCP Servers" section above.

**Q: Can I use an LLM API call as the verification metric?**
A: Yes, but carefully. Use a fast, cheap model (like Haiku) for scoring. The verification must be deterministic-ish — same content should score similarly. Avoid using the same model that's making the changes to score them (confirmation bias). See the API patterns section for examples.

**Q: What about rate limits when using APIs for verification?**
A: Add a small delay in your verification script if needed. The loop is still fast — even with a 2-second API call, you get 1,800 iterations per hour. Most API rate limits won't be hit at this pace.

---

## Contributing

Contributions welcome! Open an issue or PR.

Areas of interest:
- New domain examples (data science, design, DevOps, etc.)
- Better verification script templates
- Integration with CI/CD pipelines
- Performance benchmarks from real-world usage

---

## License

MIT — see [LICENSE](LICENSE).

---

## Credits

- **[Andrej Karpathy](https://github.com/karpathy)** — for [autoresearch](https://github.com/karpathy/autoresearch) and the insight that constraint + metric + iteration = compounding gains
- **[Anthropic](https://anthropic.com)** — for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and the skills system that makes this possible

---

## About the Author

<a href="https://udit.co">
  <img src="https://avatars.githubusercontent.com/uditgoenka" width="100" align="left" style="margin-right: 16px; border-radius: 50%;" alt="Udit Goenka" />
</a>

**[Udit Goenka](https://udit.co)** — AI Product Expert, Founder & Angel Investor

Self-taught builder who went from a slow internet connection in India to founding multiple companies and helping 700+ startups generate over ~$25m in revenue.

<br clear="left" />

### What I'm Building

- **[TinyCheque](https://tinycheque.com)** — India's first agentic AI venture studio, building [seoengine.ai](https://seoengine.ai), [autoposting.ai](https://autoposting.ai), [niyam.ai](https://niyam.ai), and [qcall.ai](https://qcall.ai)
- **[Firstsales.io](https://firstsales.io)** — Sales automation platform

### Angel Investing

38 startups backed, 6 exits. Focused on early-stage AI and SaaS founders.

### Connect

- **Website:** [udit.co](https://udit.co)
- **Twitter/X:** [@iuditg](https://x.com/iuditg)
- **GitHub:** [@uditgoenka](https://github.com/uditgoenka)
- **Newsletter:** [udit.co/blog](https://udit.co/blog) — AI news, product building, and startup insights

### Why I Built This

I use Claude Code daily to build products across all my ventures. When I saw Karpathy's autoresearch, I realized the same principles could make Claude Code dramatically more productive for **any** domain — not just ML research. Claude Autoresearch is how I let Claude work autonomously on tasks while I focus on strategy.

> *"Autonomy scales when you constrain scope, clarify success, mechanize verification, and let agents optimize tactics while humans optimize strategy."*
