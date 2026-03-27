#!/bin/bash
# setup-agent-symlinks.sh
# Creates symlinks from tool-specific config files to AGENTS.md

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

make_symlink() {
  local link="$1"
  local target="$2"
  local link_dir="$(dirname "$link")"

  mkdir -p "$link_dir"

  # Verify target exists (resolve relative to link's parent directory)
  if [ ! -e "$link_dir/$target" ]; then
    return
  fi

  if [ -L "$link" ]; then
    rm "$link"
  elif [ -e "$link" ]; then
    return
  fi

  ln -s "$target" "$link"
}

# CLAUDE.md symlink (root)
if [ -f "AGENTS.md" ]; then
  make_symlink "CLAUDE.md" "AGENTS.md"
fi

# CLAUDE.md symlinks (subdirectories — tracked files only)
while IFS= read -r agents_file; do
  dir="$(dirname "$agents_file")"
  [ "$dir" = "." ] && continue
  make_symlink "$dir/CLAUDE.md" "AGENTS.md"
done < <(git ls-files -- '**/AGENTS.md' || true)

# GitHub Copilot
if [ -f "AGENTS.md" ]; then
  make_symlink ".github/copilot-instructions.md" "../AGENTS.md"
fi

# Cursor
if [ -f "AGENTS.md" ]; then
  make_symlink ".cursor/rules/main.mdc" "../../AGENTS.md"
fi

# GSD codebase (symlink .planning/codebase to .agent/codebase)
if [ -d ".agent/codebase" ]; then
  make_symlink ".planning/codebase" "../.agent/codebase"
fi

# Claude Code commands (symlink each skill subfolder)
if [ -d ".agent/skills" ]; then
  # Clean up stale command symlinks
  if [ -d ".claude/commands" ]; then
    for link in .claude/commands/*; do
      [ -L "$link" ] && [ ! -e "$link" ] && rm "$link"
    done
  fi

  for skill_dir in .agent/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    make_symlink ".claude/commands/$skill_name" "../../.agent/skills/$skill_name"
  done

  # Individual skill files
  for skill_file in .agent/skills/*.md; do
    [ -f "$skill_file" ] || continue
    skill_name="$(basename "$skill_file")"
    make_symlink ".claude/commands/$skill_name" "../../.agent/skills/$skill_name"
  done
fi
