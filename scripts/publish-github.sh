#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_URL="${1:-${GITHUB_REMOTE_URL:-}}"
BRANCH="${BRANCH:-main}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-Initial cli-anything-dolphinscheduler harness}"

usage() {
  cat <<'EOF'
Usage: ./scripts/publish-github.sh <remote-url>

Examples:
  ./scripts/publish-github.sh git@github.com:<OWNER>/cli-anything-dolphinscheduler.git
  ./scripts/publish-github.sh https://github.com/<OWNER>/cli-anything-dolphinscheduler.git

Environment:
  GITHUB_REMOTE_URL  Remote URL when no positional argument is passed.
  BRANCH             Branch to push (default: main).
  COMMIT_MESSAGE     Commit message for the first/new commit.
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [[ -z "$REMOTE_URL" ]]; then
  usage >&2
  exit 2
fi

cd "$ROOT_DIR"

if [[ ! -e "$ROOT_DIR/.git" ]]; then
  git init
fi

git add .

if ! git diff --cached --quiet; then
  git commit -m "$COMMIT_MESSAGE"
else
  echo "No staged changes to commit."
fi

git branch -M "$BRANCH"

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

git push -u origin "$BRANCH"
