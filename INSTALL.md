# Install — agent-readable spec

> This file is the canonical install procedure for `feishu-deck-h5`.
> If you are Claude, Codex, or any AI agent and the user asked you to install
> this skill from a git URL, follow these steps in order.
> If you are a human, [README.md](./README.md) is friendlier.

## TL;DR for the user

Tell your Claude / Codex agent:

> "帮我安装 feishu-deck-h5 这个 skill：`https://github.com/FuQiang/feishu-deck-h5.git`"

The agent will detect your harness, pick the right install path, and verify.

---

## Decision tree (for the agent)

Run these checks **in order**, stop at the first match:

### 1. Plugin marketplace path (Claude Code with `/plugin` support)

**Detect:** the user is running Claude Code CLI / Claude Desktop and `/plugin marketplace add` is a known slash command.

**Action — instruct the user to run:**

```
/plugin marketplace add https://github.com/FuQiang/feishu-deck-h5.git
/plugin install feishu-deck-h5@feishu-deck-h5
```

Then restart the session. (Slash commands cannot be invoked by an agent — the user has to type them.)

**Verify:** after restart, `bash ~/.claude/skills/feishu-deck-h5/assets/preflight.sh` should print `PREFLIGHT OK`.

### 2. Codex skills path

**Detect:** the user is running Codex and `~/.codex/skills/` exists, or `$CODEX_HOME` is set.

**Action — run as the user:**

```bash
git clone https://github.com/FuQiang/feishu-deck-h5.git /tmp/feishu-deck-h5-installer
HARNESS=codex bash /tmp/feishu-deck-h5-installer/install.sh
rm -rf /tmp/feishu-deck-h5-installer
```

**Verify:** the script auto-runs `preflight.sh` at the end. Look for `PREFLIGHT OK`.

If Codex uses a custom root, set `HARNESS_DIR` explicitly:

```bash
HARNESS_DIR="${CODEX_HOME:-$HOME/.codex}" bash install.sh
```

### 3. install.sh path (Claude, OpenClaw, or any compatible harness)

**Detect:** plugin marketplace not available, but the harness loads skills from a `<harness-root>/skills/` directory.

**Action — run as the user:**

```bash
git clone https://github.com/FuQiang/feishu-deck-h5.git /tmp/feishu-deck-h5-installer
bash /tmp/feishu-deck-h5-installer/install.sh
rm -rf /tmp/feishu-deck-h5-installer
```

Harness shortcuts:

```bash
HARNESS=claude bash install.sh    # default: ~/.claude/skills
HARNESS=codex bash install.sh     # default: ${CODEX_HOME:-~/.codex}/skills
HARNESS=openclaw bash install.sh  # default: ~/.openclaw/skills
HARNESS_DIR=/path/to/root bash install.sh
```

`CLAUDE_DIR=/path/to/root` is still supported as a backward-compatible alias for `HARNESS_DIR`.

**Verify:** the script auto-runs `preflight.sh` at the end. Look for `PREFLIGHT OK`.

### 4. Manual path (fallback when nothing else fits)

```bash
git clone https://github.com/FuQiang/feishu-deck-h5.git ~/Projects/feishu-deck-h5
mkdir -p ~/.codex/skills
ln -s ~/Projects/feishu-deck-h5/skills/feishu-deck-h5 ~/.codex/skills/feishu-deck-h5
bash ~/.codex/skills/feishu-deck-h5/assets/preflight.sh
```

---

## Prerequisites (verify before installing)

- `python3` 3.11+, `bash`, `node` on PATH (used by build/validate)
- For strict visual CI or local visual audits: `pip install -r skills/feishu-deck-h5/requirements-dev.txt` and `python -m playwright install chromium`
- SSH access is only required when `REPO_URL` uses `git@github.com:...`.

If the HTTPS clone fails, treat it as a network or repository-access problem.
If an SSH clone fails, ask the user to set up their SSH key first.

### Don't have collaborator access yet?

If `git ls-remote <repo-url> HEAD` fails with
"Repository not found" or "Permission denied" but `ssh -T git@github.com`
works, the user has SSH set up but is not yet a collaborator on the SSH-only
remote they are trying to use.

`install.sh` detects this and exits with **code 2**, printing a copy-pasteable
Lark/Feishu message template (with the user's GitHub username pre-filled) for
them to send to the repository owner or admin. The agent should:

1. Show the printed template to the user verbatim
2. Tell them to paste it into Lark to the repository owner/admin
3. Wait for them to confirm the GitHub invitation email arrived + was accepted
4. Re-run `install.sh`

Do **not** try to add them as a collaborator via `gh api` — only the repo owner can do that.

---

## Repo structure (so agents know what they cloned)

```
.claude-plugin/marketplace.json   ← present means: plugin path supported
.claude-plugin/plugin.json
skills/feishu-deck-h5/SKILL.md    ← present means: Codex/manual/install.sh path supported
install.sh                        ← present means: install.sh path supported
INSTALL.md                        ← this file
README.md                         ← human-facing docs
```

Any of the three indicators present → that install path is supported.
