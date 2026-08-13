#!/usr/bin/env sh
set -eu

target="${1:-codex}"
scope="${2:-user}"
project_path="${3:-$(pwd)}"

case "$target" in
  codex|claude) ;;
  *) echo "Target must be codex or claude." >&2; exit 2 ;;
esac

case "$scope" in
  user|project) ;;
  *) echo "Scope must be user or project." >&2; exit 2 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")
source_dir="$repo_root/skills/run-meta-analysis-r"

if [ "$scope" = "project" ]; then
  if [ "$target" = "codex" ]; then
    destination_root="$project_path/.codex/skills"
  else
    destination_root="$project_path/.claude/skills"
  fi
elif [ "$target" = "codex" ]; then
  destination_root="${CODEX_HOME:-$HOME/.codex}/skills"
else
  destination_root="$HOME/.claude/skills"
fi

destination="$destination_root/run-meta-analysis-r"
if [ -e "$destination" ]; then
  echo "Destination already exists: $destination" >&2
  echo "Remove it deliberately before reinstalling." >&2
  exit 3
fi

mkdir -p "$destination_root"
cp -R "$source_dir" "$destination"
echo "Installed run-meta-analysis-r to: $destination"
echo "Restart the AI application if the skill is not discovered immediately."

