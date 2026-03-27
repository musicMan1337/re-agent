# re-agent

A CLI tool that keeps AI coding agent configurations in sync across tools using a single source of truth.

Write your agent instructions once in `AGENTS.md`. re-agent symlinks it to every tool's expected location so Claude Code, GitHub Copilot, and Cursor all read the same file.

## The problem

Every AI coding tool has its own convention for where agent instructions live:

| Tool           | Expected file                     |
| -------------- | --------------------------------- |
| Claude Code    | `CLAUDE.md`                       |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor         | `.cursor/rules/main.mdc`          |

Managing these separately means they drift apart. Copy-pasting between them is tedious and error-prone. Checking tool-specific config files into version control clutters the repo with redundant files that serve the same purpose.

## The solution

re-agent introduces a single canonical file (`AGENTS.md`) and a git hook that creates symlinks to each tool's expected location on every branch checkout:

```
AGENTS.md           (you edit this)
  -> CLAUDE.md                          (symlink)
  -> .github/copilot-instructions.md    (symlink)
  -> .cursor/rules/main.mdc             (symlink)
```

The symlinks are gitignored. Only `AGENTS.md` is committed. Every tool reads the same content.

## Getting started

### Install

The package is small and has no runtime dependencies — running it directly with npx is usually all you need:

```bash
npx @musicman1337/re-agent init
```

Or install it as a dev dependency first:

```bash
npm install -D @musicman1337/re-agent
npx re-agent init
```

### What `init` does

1. Adds [lefthook](https://github.com/evilmartians/lefthook) to `devDependencies` and wires up a `prepare` script
2. Consolidates any existing config files (`CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/main.mdc`) into `AGENTS.md`
3. Creates `AGENTS.md` with a starter template (if one doesn't already exist)
4. Scaffolds `.agent/skills/` for shared custom commands
5. Creates `lefthook.yml` with a `post-checkout` hook
6. Generates `scripts/setup-agent-symlinks.sh`
7. Updates `.gitignore` to ignore the generated symlinks

### After init

```bash
npm install          # installs lefthook and registers git hooks
git checkout -b test # triggers the post-checkout hook, creating symlinks
```

Edit `AGENTS.md` with your project conventions. Every AI tool will pick them up automatically.

## How it works

The `post-checkout` git hook runs `scripts/setup-agent-symlinks.sh` on every branch switch. The script:

1. Creates symlinks from each tool's config path to `AGENTS.md`
2. Bootstraps `.agent/skills/` if missing
3. Consolidates `.planning/codebase/` into `.agent/codebase/` on demand (see below)
4. Symlinks custom commands from `.agent/skills/` into `.claude/commands/`
5. Cleans up stale symlinks for removed skills

Symlinks are only created if the target exists. If a real file already sits at a symlink location (e.g. someone manually created `CLAUDE.md`), the hook leaves it alone.

## The `.agent/` directory

Beyond the main `AGENTS.md` file, re-agent provides a shared directory for agent resources that would otherwise be scattered across tool-specific locations:

```
.agent/
  skills/       -> .claude/commands/     (custom slash commands)
  codebase/     -> .planning/codebase    (codebase documentation)
```

### Skills

Place custom commands in `.agent/skills/` as subdirectories or individual `.md` files. The hook symlinks them into `.claude/commands/` so they're available as slash commands in Claude Code:

```
.agent/skills/
  review/
    prompt.md
  quick-fix.md
```

These become `/review` and `/quick-fix` in Claude Code.

### Codebase documentation

The `.agent/codebase/` directory is created on demand. If your workflow uses `.planning/codebase/` for codebase documentation, the hook will automatically:

1. Move the contents from `.planning/codebase/` into `.agent/codebase/`
2. Replace `.planning/codebase/` with a symlink back to `.agent/codebase/`

If you don't use a `.planning/codebase/` directory, `.agent/codebase/` is never created, keeping your repo clean.

## What gets committed vs ignored

**Committed** (source of truth):
- `AGENTS.md`
- `.agent/skills/`
- `.agent/codebase/` (when it exists)
- `scripts/setup-agent-symlinks.sh`
- `lefthook.yml`

**Gitignored** (generated symlinks):
- `CLAUDE.md` and `**/CLAUDE.md`
- `.github/copilot-instructions.md`
- `.cursor/rules/main.mdc`
- `.claude/` (commands symlinks)
- `.planning/codebase` (symlink)

## Monorepo support

If your repo has `AGENTS.md` files in subdirectories, the hook creates corresponding `CLAUDE.md` symlinks next to each one. This lets packages in a monorepo have their own agent instructions.

## Migration

If your repo already has real `CLAUDE.md`, `.github/copilot-instructions.md`, or `.cursor/rules/main.mdc` files, `re-agent init` will consolidate them automatically:

- The first file found becomes `AGENTS.md`
- Duplicates are removed
- Files with different content are removed with a warning so you can review `AGENTS.md`

Similarly, existing `.claude/commands/` directories are moved to `.agent/skills/`, and `.planning/codebase/` is moved to `.agent/codebase/`.

## Why you might want this

- **One file to maintain.** Write your conventions, architecture notes, and coding rules in one place. Every tool reads the same instructions.
- **Works with version control.** Only the canonical files are committed. Symlinks are generated locally and gitignored, so they don't clutter PRs or cause merge conflicts.
- **Zero runtime dependencies.** The CLI is pure Node.js. The only dev dependency it adds is lefthook for git hooks.
- **Non-invasive.** It's just symlinks and a post-checkout hook. If you remove re-agent, delete the symlinks and the hook. Your `AGENTS.md` stays.
- **Team-friendly.** When teammates run `npm install`, lefthook is set up automatically via the `prepare` script. The next branch checkout creates their symlinks. No extra steps.

## Disclaimer

The conventions managed by this tool are **emergent and evolving**. There is no formal specification for where AI coding agents should read their instructions. Each tool has adopted its own convention independently, and those conventions will continue to change as the ecosystem matures.

re-agent tracks these conventions so you don't have to. When tools adopt new file locations or configuration formats, re-agent will update to keep your repos compatible. The goal is to shield you from churn in the tooling layer while giving you a stable, single place to manage your agent instructions.

**This is not a standard.** It's a practical tool built on the patterns that exist today. Expect it to evolve.

## License

MIT
