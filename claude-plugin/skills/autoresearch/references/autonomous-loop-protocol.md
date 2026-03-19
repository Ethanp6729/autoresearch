# Autonomous Loop Protocol

Detailed protocol for the autoresearch iteration loop. SKILL.md has the summary; this file has the full rules.

## Loop Modes

Autoresearch supports two loop modes:

- **Unbounded (default):** Loop forever until manually interrupted (`Ctrl+C`)
- **Bounded:** Loop exactly N times when `Iterations: N` is set in the inline config (or `--iterations N` flag for CLI/CI)

When bounded, track `current_iteration` against `max_iterations`. After the final iteration, print a summary and stop.

## Phase 0: Precondition Checks (before loop starts)

**MUST complete ALL checks before entering the loop. Fail fast if any check fails.**

```bash
# 1. Verify git repo exists
git rev-parse --git-dir 2>/dev/null || echo "FAIL: not a git repo"
# → If not a git repo: ask user to run `git init` or abort

# 2. Check for dirty working tree
git status --porcelain
# → If dirty: warn user and ask to stash or commit first
#   NEVER proceed with uncommitted user changes — explicit git add will stage them

# 3. Check for stale lock files
ls .git/index.lock 2>/dev/null && echo "WARN: stale lock"
# → If lock exists: remove it (rm .git/index.lock) or warn user

# 4. Check for detached HEAD
git symbolic-ref HEAD 2>/dev/null || echo "WARN: detached HEAD"
# → If detached: warn user, suggest `git checkout <branch>`

# 5. Check for git hooks that might interfere
ls .git/hooks/pre-commit .git/hooks/commit-msg 2>/dev/null && echo "INFO: git hook detected"
ls .husky/pre-commit .husky/commit-msg 2>/dev/null && echo "INFO: husky hook detected"
ls .pre-commit-config.yaml 2>/dev/null && echo "INFO: pre-commit framework detected"
# → If hooks exist: note in setup log. If hook blocks commits during loop,
#   treat as crash and log "hook blocked commit" — do NOT use --no-verify
```

**If any FAIL:** Stop and inform user. Do not enter the loop with broken preconditions.
**If any WARN:** Log the warning, proceed with caution, inform user.

## Phase 1: Review (30 seconds)

Before each iteration, build situational awareness. **You MUST complete ALL 6 steps — git history is critical for learning from past iterations.**

```
1. Read current state of in-scope files (full context)
2. Read last 10-20 entries from results log
3. MUST run: git log --oneline -20 to see recent changes
4. MUST run: git diff HEAD~1 (if last iteration was "keep") to review what worked
5. Identify: what worked, what failed, what's untried — based on BOTH results log AND git history
6. If bounded: check current_iteration vs max_iterations
```

**Why read git history every time?** Git IS the memory. After rollbacks, state may differ from what you expect. The git log shows which experiments were kept vs reverted. The git diff of kept changes reveals WHAT specifically improved the metric — use this to inform the next iteration. Never assume — always verify.

**Git history usage pattern:**
- `git log --oneline -20` → see the sequence of experiments (kept commits remain, discarded ones are reverted)
- `git diff HEAD~1` → inspect the last kept change to understand WHY it worked
- `git log --all --oneline` → if working on a branch, see full experiment history
- Use commit messages (e.g., "experiment: increase batch size") to avoid repeating failed approaches

## Git as Memory — Configuration

Git as Memory is **always enabled** — it's a core behavior, not optional. The agent reads its own git history every iteration to learn from past experiments.

### Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Memory depth | 20 commits | How far back to read history |
| Diff review | HEAD~1 | How far back to diff kept changes |
| Full history | disabled | Read all branches |

### How It Works (step by step)

At the start of EVERY iteration (Phase 1), the agent runs:

```bash
# Step 1: Read recent experiment history
git log --oneline -20
# Shows: kept commits remain, discarded ones were reverted

# Step 2: Inspect the last successful change
git diff HEAD~1
# Shows: exact diff that improved the metric — informs next experiment

# Step 3: Check what was tried (avoid repeating failures)
git log --oneline -20 | grep "experiment"
# Shows: all experiment descriptions

# Step 4: Deep-dive a specific success
git show abc1234 --stat
# Shows: which files were changed in a successful experiment
```

### Example: Memory in Action

```
# Agent reads git log and sees:
# a1b2c3d experiment(api): add response caching — KEPT (metric improved)
# d4e5f6g Revert "experiment(api): increase cache TTL to 60s" — REVERTED
# c3d4e5f experiment(api): add cache invalidation on write — KEPT
#
# Agent learns:
# ✓ Caching works (2 kept commits)
# ✗ Increasing TTL didn't help (reverted)
# → Next: try a different cache strategy, NOT longer TTL
```

## Phase 2: Ideate (Strategic)

Pick the NEXT change. **MUST consult git history and results log before deciding.**

**How to use git as memory:**
- Run `git log --oneline -10` — read commit messages to see what was tried
- For each "keep" in results log, run `git show <commit-hash> --stat` to see what files/patterns worked
- For discarded approaches, read the commit message to understand what was attempted and avoid repeating it
- Look for patterns: if 3 commits improved metric by touching file X, focus on file X

**Priority order:**

1. **Fix crashes/failures** from previous iteration first
2. **Exploit successes** — run `git diff` on last kept commit, try variants in same direction
3. **Explore new approaches** — cross-reference results log AND git history to find untried approaches
4. **Combine near-misses** — two changes that individually didn't help might work together
5. **Simplify** — remove code while maintaining metric. Simpler = better
6. **Radical experiments** — when incremental changes stall, try something dramatically different

**Anti-patterns:**
- Don't repeat exact same change that was already discarded — CHECK git log first
- Don't make multiple unrelated changes at once (can't attribute improvement)
- Don't chase marginal gains with ugly complexity
- Don't ignore git history — it's the primary learning mechanism between iterations

**Bounded mode consideration:** If remaining iterations are limited (<3 left), prioritize exploiting successes over exploration.

## Phase 3: Modify (One Atomic Change)

- Make ONE focused change to in-scope files
- The change should be explainable in one sentence
- Write the description BEFORE making the change (forces clarity)

### Multi-File Atomic Changes

One logical change may span multiple files. This is still ONE change if it serves a single purpose.

**The one-sentence test:** If you need "and" to describe it, it's two changes. Split them.

| One Change (OK) | Two Changes (Split) |
|-----------------|---------------------|
| Change port 3000→8080 in Dockerfile + compose + nginx | Change port AND add new service |
| Update Node 18→20 in Dockerfile + CI + package.json | Update Node AND switch to pnpm |
| Add Redis in compose + app config + env vars | Add Redis AND refactor auth module |

#### DevOps Example

```bash
# Iteration 1: Enable Docker layer caching (2 files, one intent)
git add Dockerfile .github/workflows/ci.yml
git commit -m "experiment(ci): enable Docker layer caching"
# ✓ One change: "enable caching" — same intent across files

# Iteration 2: Parallelize test jobs (1 file)
git add .github/workflows/ci.yml
git commit -m "experiment(ci): parallelize tests with matrix strategy"
# ✓ One change: "parallelize tests"
```

### Enforcing Atomicity — Self-Check

```bash
# After modifying but before committing, validate atomicity:
FILES_CHANGED=$(git diff --name-only | wc -l)

# Heuristic: >5 files likely means multiple changes — review
if [ "$FILES_CHANGED" -gt 5 ]; then
  echo "WARN: ${FILES_CHANGED} files changed — verify single intent"
fi

# The one-sentence test: describe the change in ONE sentence
# If you need "and", split into separate iterations
```

## Phase 4: Commit (Before Verification)

**You MUST commit before running verification.** This enables clean rollback if the experiment fails.

```bash
# Stage ONLY in-scope files (safer than git add -A)
# List the specific files you modified and add them individually:
git add <file1> <file2> ...
# AVOID git add -A — it stages ALL files including .env, node_modules, and user's unrelated work

# Check if there's actually something to commit
git diff --cached --quiet
# → If exit code 0 (no staged changes): skip commit, log as "no-op", go to next iteration
# → If exit code 1 (changes exist): proceed with commit

# Commit with descriptive experiment message
git commit -m "experiment(<scope>): <one-sentence description of what you changed and why>"
```

**"Nothing to commit" handling:** If `git add <files>` followed by `git diff --cached --quiet` shows no changes, the modification phase produced no actual diff. This is NOT a crash — log as `status=no-op` with description of what was attempted, skip verification, and proceed to next iteration. Do NOT create an empty commit.

**WARNING:** NEVER use `git add -A` — it stages ALL files including .env, credentials, and user's unrelated work. Always use `git add <file1> <file2> ...` with explicit file paths. After staging, verify with `git diff --cached --name-only` that only in-scope files are staged.

**Commit message format:** Use conventional commit format with `experiment` type: `experiment(<scope>): <description>`. This keeps compatibility with commit-lint while clearly marking autoresearch iterations. Example: `experiment(auth): increase timeout from 5s to 30s — hypothesis: reduces flaky test failures`.

**Hook failure handling:** If a pre-commit hook blocks the commit:
1. Read the hook's error output to understand WHY it blocked
2. If fixable (lint error, formatting): fix the issue, re-stage, and retry the commit — do NOT use `--no-verify`
3. If not fixable within 2 attempts: log as `status=hook-blocked`, revert the in-scope file changes (`git checkout -- <files>`), and move to next iteration
4. NEVER bypass hooks with `--no-verify` — hooks exist to protect code quality

**Rollback strategy (if experiment fails):**
```bash
# Preferred: git revert (safe, preserves history)
git revert HEAD --no-edit

# Alternative: git reset (if revert conflicts)
git revert --abort && git reset --hard HEAD~1
```

**IMPORTANT:** Prefer `git revert` over `git reset --hard` — revert preserves the experiment in history (so you can learn from it), while reset destroys it. Use `git reset --hard` only if revert produces merge conflicts.

## Phase 5: Verify (Mechanical Only)

Run the agreed-upon verification command. Capture output.

**Timeout rule:** If verification exceeds 2x normal time, kill and treat as crash.

**Extract metric:** Parse the verification output for the specific metric number.

### Verification Command Templates by Language

| Language | Verify Command | Metric | Direction |
|----------|---------------|--------|-----------|
| **Node.js** | `npx jest --coverage 2>&1 \| grep 'All files' \| awk '{print $4}'` | Coverage % | higher |
| **Python** | `pytest --cov=src --cov-report=term 2>&1 \| grep TOTAL \| awk '{print $4}'` | Coverage % | higher |
| **Rust** | `cargo test 2>&1 \| grep -oP '\d+ passed' \| grep -oP '\d+'` | Tests passed | higher |
| **Go** | `go test -count=1 ./... 2>&1 \| grep -c '^ok'` | Packages passing | higher |
| **Java** | `mvn test 2>&1 \| grep 'Tests run:' \| tail -1 \| grep -oP 'Failures: \d+' \| grep -oP '\d+'` | Failures | lower |
| **Bundle** | `npx esbuild src/index.ts --bundle --minify \| wc -c` | Bytes | lower |
| **Lighthouse** | `npx lighthouse http://localhost:3000 --output=json \| jq '.categories.performance.score * 100'` | Score 0-100 | higher |
| **Latency** | `wrk -t2 -c10 -d10s http://localhost:3000/api 2>&1 \| grep 'Avg Lat' \| awk '{print $2}'` | ms | lower |

## Phase 5.1: Noise Handling (for Volatile Metrics)

Some metrics are inherently noisy — benchmark times, ML accuracy, Lighthouse scores. A single measurement can mislead. Use these strategies to prevent false keep/discard decisions.

### Strategy 1: Multi-Run Verification

Run verify N times and use the median to filter outliers:

```bash
# Single run (unreliable for noisy metrics):
npm run benchmark  # might report 142ms or 158ms randomly

# Multi-run with median (reliable):
for i in 1 2 3; do
  npm run benchmark 2>&1 | grep 'avg' | awk '{print $2}'
done | sort -n | sed -n '2p'  # median of 3 runs
```

Configure via inline config:
```
/autoresearch
Verify: npm run benchmark 2>&1 | grep 'avg' | awk '{print $2}'
Noise: high           # triggers 3-run median automatically
Noise-Runs: 5         # custom: 5 runs instead of default 3
```

### Strategy 2: Minimum Improvement Threshold

Ignore improvements smaller than the noise floor:

```
# Configuration:
Min-Delta: 2.0   # only keep if improvement > 2%

# Decision logic (extends Phase 6):
IF metric_improved AND delta > min_delta:
    STATUS = "keep"
ELIF metric_improved AND delta <= min_delta:
    STATUS = "discard"
    LOG "NOISE: delta {delta} below threshold {min_delta}"
```

### Strategy 3: Confirmation Run

Re-verify before making a final keep decision:

```
IF metric_improved:
    second_metric = run_verify()  # run verify again
    IF abs(second_metric - first_metric) / first_metric < 0.01:
        STATUS = "keep"     # confirmed — both runs agree
    ELSE:
        STATUS = "discard"  # first result was noise
        LOG "NOISE: confirmation run disagreed"
```

### Strategy 4: Environment Pinning

Reduce noise at the source by controlling external factors:

```bash
# Pin random seeds for ML/statistical workloads
PYTHONHASHSEED=42 python train.py --seed 42

# Use deterministic test ordering
pytest -p no:randomly

# Flush caches before benchmarking
redis-cli FLUSHALL 2>/dev/null; npm run benchmark

# Warm up before timing (eliminates JIT/cold-start noise)
node server.js &
sleep 2
wrk -t1 -c1 -d3s http://localhost:3000  # warm-up (discard)
wrk -t2 -c10 -d10s http://localhost:3000  # actual measurement
```

### When to Use Each Strategy

| Metric Type | Noise Level | Strategy |
|-------------|-------------|----------|
| Test coverage (%) | None | No special handling |
| Bundle size (bytes) | None | No special handling |
| Benchmark time (ms) | Medium | Multi-run median (3 runs) |
| Lighthouse score | Medium | Multi-run median (5 runs) |
| ML training loss | High | Environment pinning + confirmation run |
| API response time | High | Warm-up + multi-run + min-delta |

### Preventing Premature Rollbacks

When a metric seems worse but could be noise:

```
IF metric_worse AND abs(delta) < noise_floor:
    second_result = run_verify()  # confirm the regression
    IF second_result also worse:
        STATUS = "discard"    # confirmed regression — revert
    ELSE:
        STATUS = "keep"       # first measurement was noise — keep the change
        LOG "NOISE: initial regression not confirmed on re-run"
```

## Phase 5.5: Guard (Regression Check)

If a **guard** command was defined during setup, run it after verification.

The guard is a command that must ALWAYS pass — it protects existing functionality while the main metric is being optimized. Common guards: `npm test`, `npm run typecheck`, `pytest`, `cargo test`.

**Key distinction:**
- **Verify** answers: "Did the metric improve?" (the goal)
- **Guard** answers: "Did anything else break?" (the safety net)

**Guard rules:**
- Only run if a guard was defined (it's optional)
- Run AFTER verify — no point checking guard if the metric didn't improve
- Guard is pass/fail only (exit code 0 = pass). No metric extraction needed
- If guard fails, revert the optimization and try to rework it (max 2 attempts)
- NEVER modify guard/test files — always adapt the implementation instead
- Log guard failures distinctly so the agent can learn what kinds of changes cause regressions

**Guard failure recovery (max 2 rework attempts):**

When the guard fails but the metric improved, the optimization idea may still be viable — it just needs a different implementation that doesn't break behavior:

1. Revert the change (use `safe_revert()` — try `git revert HEAD --no-edit`, fallback to `git reset --hard HEAD~1` if conflicts)
2. Read the guard output to understand WHAT broke (which tests, which assertions)
3. Rework the optimization to avoid the regression — e.g.:
   - If inlining a function broke callers → try a different optimization angle
   - If changing a data structure broke serialization → preserve the interface
   - If reordering logic broke edge cases → add the optimization more surgically
4. Commit the reworked version, re-run verify + guard
5. If both pass → keep. If guard fails again → one more attempt, then give up

**Critical:** Guard/test files are read-only. The optimization must adapt to the tests, never the other way around. If after 2 rework attempts the optimization can't pass the guard, discard it and move on to a different idea.

## Phase 6: Decide (No Ambiguity)

```bash
# Rollback function — used for all discard/crash decisions
safe_revert() {
  echo "Reverting: $(git log --oneline -1)"

  # Attempt 1: git revert (preserves history — preferred)
  if git revert HEAD --no-edit 2>/dev/null; then
    echo "✓ Reverted via git revert (experiment preserved in history for learning)"
    return 0
  fi

  # Attempt 2: revert conflicted — fallback to reset
  git revert --abort 2>/dev/null
  echo "⚠ Revert conflicted — using git reset --hard HEAD~1"
  git reset --hard HEAD~1
  echo "✓ Reverted via reset (experiment removed from history)"
  return 0
}

# Usage in Phase 6 decision logic:
# if STATUS == "discard" or STATUS == "crash": safe_revert
```

```
IF metric_improved AND (no guard OR guard_passed):
    STATUS = "keep"
    # Do nothing — commit stays. Git history preserves this success.
ELIF metric_improved AND guard_failed:
    safe_revert()
    # Rework the optimization (max 2 attempts)
    FOR attempt IN 1..2:
        Analyze guard output → rework implementation (NOT tests)
        git add <modified-files> && git commit -m "experiment(<scope>): rework — <description>"
        Re-run verify
        IF metric_improved:
            Re-run guard
            IF guard_passed:
                STATUS = "keep (reworked)"
                BREAK
        safe_revert()
    IF still failing after 2 attempts:
        STATUS = "discard"
        REASON = "guard failed, could not rework optimization"
ELIF metric_same_or_worse:
    STATUS = "discard"
    safe_revert()
ELIF crashed:
    # Attempt fix (max 3 tries)
    IF fixable:
        Fix → re-commit → re-verify → re-guard
    ELSE:
        STATUS = "crash"
        safe_revert()
```

**Why `git revert` instead of `git reset --hard`?**
- `git revert` preserves the failed experiment in history — this IS the "memory." Future iterations can read `git log` and see what was tried and failed.
- `git reset --hard` destroys the commit entirely — the agent loses memory of what was attempted.
- `git revert` is also safer in Claude Code — it's a non-destructive operation that doesn't trigger safety warnings.
- Fallback: if `git revert` produces merge conflicts, use `git revert --abort` then `git reset --hard HEAD~1`.

**Simplicity override:** If metric barely improved (+<0.1%) but change adds significant complexity, treat as "discard". If metric unchanged but code is simpler, treat as "keep".

## Phase 7: Log Results

Append to results log (TSV format):

```
iteration  commit   metric   status        description
42         a1b2c3d  0.9821   keep          increase attention heads from 8 to 12
43         -        0.9845   discard       switch optimizer to SGD
44         -        0.0000   crash         double batch size (OOM)
45         -        -        no-op         attempted to modify read-only config (no diff produced)
46         -        -        hook-blocked  pre-commit lint hook rejected formatting in model.py
```

**Valid statuses:** `keep`, `keep (reworked)`, `discard`, `crash`, `no-op`, `hook-blocked`

## Phase 8: Repeat

### Unbounded Mode (default)

Go to Phase 1. **NEVER STOP. NEVER ASK IF YOU SHOULD CONTINUE.**

### Bounded Mode (with Iterations: N)

```
IF current_iteration < max_iterations:
    Go to Phase 1
ELIF goal_achieved:
    Print: "Goal achieved at iteration {N}! Final metric: {value}"
    Print final summary
    STOP
ELSE:
    Print final summary
    STOP
```

**Final summary format:**
```
=== Autoresearch Complete (N/N iterations) ===
Baseline: {baseline} → Final: {current} ({delta})
Keeps: X | Discards: Y | Crashes: Z | Skipped: W (no-ops + hook-blocked)
Best iteration: #{n} — {description}
```

### When Stuck (>5 consecutive discards)

Applies to both modes:
1. Re-read ALL in-scope files from scratch
2. Re-read the original goal/direction
3. Review entire results log for patterns
4. Try combining 2-3 previously successful changes
5. Try the OPPOSITE of what hasn't been working
6. Try a radical architectural change

## Crash Recovery

- Syntax error → fix immediately, don't count as separate iteration
- Runtime error → attempt fix (max 3 tries), then move on
- Resource exhaustion (OOM) → revert, try smaller variant
- Infinite loop/hang → kill after timeout, revert, avoid that approach
- External dependency failure → skip, log, try different approach

## Communication

- **DO NOT** ask "should I keep going?" — in unbounded mode, YES. ALWAYS. In bounded mode, continue until N is reached.
- **DO NOT** summarize after each iteration — just log and continue
- **DO** print a brief one-line status every ~5 iterations (e.g., "Iteration 25: metric at 0.95, 8 keeps / 17 discards")
- **DO** alert if you discover something surprising or game-changing
- **DO** print a final summary when bounded loop completes
