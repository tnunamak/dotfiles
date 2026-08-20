#!/bin/bash
# Mechanical extraction only. Repo-wide comment endpoints; does NOT capture PR review
# summary bodies (no repo-wide endpoint for those).

set -uo pipefail

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") <org> <repo> <author-login> [outdir]
  outdir defaults to \$HOME/.tmp/callumify-0818/raw/reviews
EOF
  exit 1
}

if [[ $# -lt 3 ]]; then
  usage
fi

ORG="$1"
REPO="$2"
AUTHOR_LOGIN="$3"
OUTDIR="${4:-$HOME/.tmp/callumify-0818/raw/reviews}"

mkdir -p "$OUTDIR"

# Fetch PR review comments
PR_COMMENTS_FILE="$OUTDIR/${REPO}.pull-comments.jsonl"
if [[ -f "$PR_COMMENTS_FILE" ]] && [[ -s "$PR_COMMENTS_FILE" ]]; then
  echo "SKIP $PR_COMMENTS_FILE (already exists and non-empty)"
else
  echo "Fetching PR review comments for $ORG/$REPO ..."
  gh api "repos/$ORG/$REPO/pulls/comments" --paginate \
    | jq -c '.[] | select(.user.login == "'"$AUTHOR_LOGIN"'") | {url, path: (.path // empty), created_at, body}' \
    > "$PR_COMMENTS_FILE"
fi

# Fetch issue comments
ISSUE_COMMENTS_FILE="$OUTDIR/${REPO}.issue-comments.jsonl"
if [[ -f "$ISSUE_COMMENTS_FILE" ]] && [[ -s "$ISSUE_COMMENTS_FILE" ]]; then
  echo "SKIP $ISSUE_COMMENTS_FILE (already exists and non-empty)"
else
  echo "Fetching issue comments for $ORG/$REPO ..."
  gh api "repos/$ORG/$REPO/issues/comments" --paginate \
    | jq -c '.[] | select(.user.login == "'"$AUTHOR_LOGIN"'") | {url, created_at, body}' \
    > "$ISSUE_COMMENTS_FILE"
fi

# Count and report
PR_COUNT=$(grep -c ^ "$PR_COMMENTS_FILE" 2>/dev/null || echo 0)
ISSUE_COUNT=$(grep -c ^ "$ISSUE_COMMENTS_FILE" 2>/dev/null || echo 0)

echo "Done."
echo "  PR review comments: $PR_COUNT"
echo "  Issue comments: $ISSUE_COUNT"
