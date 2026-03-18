#!/usr/bin/env bash
# Release script for autoresearch plugin.
# Creates a release branch, bumps versions, prompts for doc review,
# creates a detailed PR, and merges only after confirmation.
#
# Usage: ./scripts/release.sh <version> [--title "Release title"]
# Example: ./scripts/release.sh 1.7.0 --title "New Feature X"
#
# Versioning:
#   v1.6.X  — patch: bugfixes, small updates
#   v1.X.0  — minor: new features, significant changes
#   v2.0.0+ — major: reserved for future

set -euo pipefail

# --- Parse arguments ---
VERSION=""
TITLE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    *) VERSION="${VERSION:-$1}"; shift ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  echo "Usage: ./scripts/release.sh <version> [--title \"Release title\"]"
  echo ""
  echo "Versioning guide:"
  echo "  v1.6.X  — patch: bugfixes, small updates"
  echo "  v1.X.0  — minor: new features, significant changes"
  echo ""
  echo "Example: ./scripts/release.sh 1.7.0 --title \"Scenario Explorer\""
  exit 1
fi

# Strip leading 'v' if provided
VERSION="${VERSION#v}"
TAG="v${VERSION}"
BRANCH="release/${VERSION}"
PLUGIN_JSON=".claude-plugin/plugin.json"
MARKETPLACE_JSON=".claude-plugin/marketplace.json"

# --- Preflight checks ---
if [[ ! -f "$PLUGIN_JSON" ]]; then
  echo "Error: $PLUGIN_JSON not found. Run from repo root."
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not found. Install: https://cli.github.com"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: Working tree is dirty. Commit or stash changes first."
  exit 1
fi

# Ensure we're on master
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "master" ]]; then
  echo "Error: Must be on master branch. Currently on: $CURRENT_BRANCH"
  exit 1
fi

git pull origin master --quiet

# Read current version
CURRENT=$(grep -o '"version": "[^"]*"' "$PLUGIN_JSON" | cut -d'"' -f4)
echo ""
echo "=== autoresearch release ==="
echo "  Current version: $CURRENT"
echo "  New version:     $VERSION"
echo "  Tag:             $TAG"
echo "  Branch:          $BRANCH"
echo ""

# --- Create release branch ---
echo "[1/6] Creating release branch: $BRANCH"
git checkout -b "$BRANCH"

# --- Bump version in plugin.json and marketplace.json ---
echo "[2/6] Bumping versions: $CURRENT → $VERSION"
for JSON_FILE in "$PLUGIN_JSON" "$MARKETPLACE_JSON"; do
  if [[ -f "$JSON_FILE" ]]; then
    echo "    Updating $JSON_FILE"
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$VERSION\"/g" "$JSON_FILE"
    else
      sed -i "s/\"version\": \"$CURRENT\"/\"version\": \"$VERSION\"/g" "$JSON_FILE"
    fi
  fi
done

# --- Bump version badges in README.md and guide/README.md ---
for DOC_FILE in README.md guide/README.md; do
  if [[ -f "$DOC_FILE" ]] && grep -q "version-.*-blue" "$DOC_FILE"; then
    echo "    Updating version badge in $DOC_FILE"
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s/version-[0-9]*\.[0-9]*\.[0-9]*-blue/version-${VERSION}-blue/" "$DOC_FILE"
    else
      sed -i "s/version-[0-9]*\.[0-9]*\.[0-9]*-blue/version-${VERSION}-blue/" "$DOC_FILE"
    fi
  fi
done

# --- Doc review prompt ---
echo ""
echo "[3/6] Documentation review"
echo "────────────────────────────────────────"
echo "  Before continuing, review these files for accuracy:"
echo ""
echo "  README.md        — version refs, command table, feature descriptions"
echo "  guide/           — individual command guides, examples, advanced patterns"
echo "  CONTRIBUTING.md  — repo structure, file table, sub-command steps"
echo ""

# Show what changed since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [[ -n "$LAST_TAG" ]]; then
  echo "  Changes since $LAST_TAG:"
  git log "$LAST_TAG"..HEAD --oneline --no-decorate | sed 's/^/    /'
  echo ""
fi

echo "  If any docs need updates, edit them now"
echo "  in another terminal, then come back here and continue."
echo ""
read -rp "  Press ENTER when docs are ready (or 'skip' to continue as-is): " DOC_RESPONSE

if [[ "$DOC_RESPONSE" != "skip" ]]; then
  # Check if README or EXAMPLES were modified
  if [[ -n "$(git status --porcelain -- README.md guide/ CONTRIBUTING.md)" ]]; then
    echo "    Staging doc updates..."
    git add README.md guide/ CONTRIBUTING.md 2>/dev/null || true
  fi
fi

# --- Commit all release changes ---
echo ""
echo "[4/6] Committing release changes"
git add -A
if git diff --cached --quiet; then
  echo "    No changes to commit."
else
  git commit -m "chore: prepare release $TAG"
fi

# --- Push branch and create PR ---
echo ""
echo "[5/6] Pushing branch and creating PR"
git push -u origin "$BRANCH"

# Build PR body with changelog
CHANGELOG=""
if [[ -n "$LAST_TAG" ]]; then
  CHANGELOG=$(git log "$LAST_TAG"..HEAD --oneline --no-decorate | sed 's/^/- /')
fi

PR_TITLE="${TITLE:-"Release $TAG"}"
if [[ ${#PR_TITLE} -gt 70 ]]; then
  PR_TITLE="Release $TAG"
fi

PR_URL=$(gh pr create \
  --base master \
  --head "$BRANCH" \
  --title "$PR_TITLE" \
  --body "$(cat <<EOF
## Release $TAG

**Version bump:** \`$CURRENT\` → \`$VERSION\`

### Changes since $LAST_TAG
${CHANGELOG:-"No previous tag found — initial release."}

### Checklist
- [x] plugin.json version bumped to $VERSION
- [x] marketplace.json version bumped to $VERSION
- [x] README.md version badge updated
- [x] guide/README.md version badge updated
- [ ] README.md content reviewed for accuracy
- [ ] guide/ reviewed — command guides, examples, chains
- [ ] CONTRIBUTING.md reviewed — repo structure, file table
- [ ] All tests passing

### Files changed
$(git diff --name-only master..."$BRANCH" 2>/dev/null | sed 's/^/- /' || echo "- (branch just created)")
EOF
)")

echo ""
echo "  PR created: $PR_URL"
echo ""

# --- Wait for merge confirmation ---
echo "[6/6] Waiting for merge confirmation"
echo "────────────────────────────────────────"
echo "  Review the PR: $PR_URL"
echo ""
read -rp "  Type 'merge' to merge, tag, and release (or 'abort' to cancel): " MERGE_RESPONSE

if [[ "$MERGE_RESPONSE" != "merge" ]]; then
  echo ""
  echo "  Aborted. The PR remains open at: $PR_URL"
  echo "  To merge later: gh pr merge $PR_URL --merge --delete-branch"
  echo "  To clean up:    git checkout master && git branch -D $BRANCH"
  exit 0
fi

# --- Merge, tag, and release ---
echo ""
echo "  Merging PR..."
gh pr merge "$PR_URL" --merge --delete-branch

echo "  Switching to master and pulling..."
git checkout master
git pull origin master --quiet

echo "  Creating tag $TAG..."
git tag -a "$TAG" -m "Release $TAG"
git push origin "$TAG"

echo "  Creating GitHub release..."
RELEASE_TITLE="${TAG}"
if [[ -n "$TITLE" ]]; then
  RELEASE_TITLE="$TAG — $TITLE"
fi
gh release create "$TAG" --title "$RELEASE_TITLE" --generate-notes

echo ""
echo "=== Released $TAG ==="
echo "  GitHub release: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/$TAG"
echo "  Plugin version: $VERSION"
