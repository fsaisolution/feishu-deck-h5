# Install — agent-readable spec

> This file is the canonical install procedure for `feishu-deck-h5`.
> If you are a Claude (or any AI agent) and the user asked you to install
> this skill from a git URL, follow these steps in order.
> If you are a human, [README.md](./README.md) is friendlier.

## TL;DR for the user

Tell your Claude agent:

> "帮我安装 feishu-deck-h5 这个 skill：`https://github.com/fuqiang/feishu-deck-h5.git`"

The agent will detect your harness, pick the right install path, and verify.

---

## Decision tree (for the agent)

Run these checks **in order**, stop at the first match:

### 1. Plugin marketplace path (Claude Code with `/plugin` support)

**Detect:** the user is running Claude Code CLI / Claude Desktop and `/plugin marketplace add` is a known slash command.

**Action — instruct the user to run:**

```
/plugin marketplace add https://github.com/fuqiang/feishu-deck-h5.git
/plugin install feishu-deck-h5@feishu-deck-h5
```

Then restart the session. (Slash commands cannot be invoked by an agent — the user has to type them.)

**Verify:** after restart, `bash ~/.claude/skills/feishu-deck-h5/assets/preflight.sh` should print `PREFLIGHT OK`.

### 2. install.sh path (any harness with `~/.claude/skills/` convention)

**Detect:** plugin marketplace not available, but `~/.claude/skills/` (or `$CLAUDE_DIR/skills/`) is the skill registration directory.

**Action — run as the user:**

```bash
git clone https://github.com/fuqiang/feishu-deck-h5.git /tmp/feishu-deck-h5-installer
bash /tmp/feishu-deck-h5-installer/install.sh
rm -rf /tmp/feishu-deck-h5-installer
```

For non-Claude-Code harnesses (e.g. openclaw if it uses a different skill root), set `CLAUDE_DIR` first:

```bash
CLAUDE_DIR=~/.openclaw bash install.sh
```

**Verify:** the script auto-runs `preflight.sh` at the end. Look for `PREFLIGHT OK`.

### 3. Manual path (fallback when nothing else fits)

```bash
git clone https://github.com/fuqiang/feishu-deck-h5.git ~/Projects/feishu-deck-h5
mkdir -p ~/.claude/skills
ln -s ~/Projects/feishu-deck-h5/skills/feishu-deck-h5 ~/.claude/skills/feishu-deck-h5
bash ~/.claude/skills/feishu-deck-h5/assets/preflight.sh
```

---

## Prerequisites (verify before installing)

- `python3` 3.11+, `bash`, `node` on PATH (used by build/validate)
- For strict visual CI or local visual audits: `pip install -r skills/feishu-deck-h5/requirements-dev.txt` and `python -m playwright install chromium`
- SSH access is only required when `REPO_URL` uses `git@github.com:...`.

If the HTTPS clone fails, treat it as a network or repository-access problem.
If an SSH clone fails, ask the user to set up their SSH key first.

### Don't have collaborator access yet?

If `git ls-remote git@github.com:FuQiang/feishu-deck-h5.git HEAD` fails with
"Repository not found" or "Permission denied" but `ssh -T git@github.com`
works, the user has SSH set up but is not yet a collaborator on the SSH-only
remote they are trying to use.

`install.sh` detects this and exits with **code 2**, printing a copy-pasteable
Lark/Feishu message template (with the user's GitHub username pre-filled) for
them to send to FuQiang. The agent should:

1. Show the printed template to the user verbatim
2. Tell them to paste it into Lark to FuQiang
3. Wait for them to confirm the GitHub invitation email arrived + was accepted
4. Re-run `install.sh`

Do **not** try to add them as a collaborator via `gh api` — only the repo owner can do that.

---

## Repo structure (so agents know what they cloned)

```
.claude-plugin/marketplace.json   ← present means: plugin path supported
.claude-plugin/plugin.json
skills/feishu-deck-h5/SKILL.md    ← present means: manual/install.sh path supported
install.sh                        ← present means: install.sh path supported
INSTALL.md                        ← this file
README.md                         ← human-facing docs
```

Any of the three indicators present → that install path is supported.
