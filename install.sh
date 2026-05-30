#!/usr/bin/env bash
# feishu-deck-h5 · install script
#
# Installs this skill into Claude Code, Codex, or any compatible harness by:
#   1. Cloning to $INSTALL_DIR (default: ~/Projects/feishu-deck-h5)
#   2. Symlinking skills/feishu-deck-h5 into $HARNESS_DIR/skills/feishu-deck-h5
#   3. Running preflight to verify
#
# Usage:
#   bash install.sh                              # from inside an existing clone
#   git clone <url> tmp && bash tmp/install.sh   # one-shot from anywhere
#
# Environment variables:
#   INSTALL_DIR   where to keep the working clone (default: ~/Projects/feishu-deck-h5)
#   HARNESS       claude | codex | openclaw (default: claude)
#   HARNESS_DIR   skill registration root (default depends on HARNESS)
#   CLAUDE_DIR    backward-compatible alias for HARNESS_DIR
#   REPO_URL      override the git remote (default: https://github.com/FuQiang/feishu-deck-h5.git)

set -e

REPO_URL="${REPO_URL:-https://github.com/FuQiang/feishu-deck-h5.git}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Projects/feishu-deck-h5}"
HARNESS="${HARNESS:-claude}"

REPO_WEB_URL="$REPO_URL"
case "$REPO_WEB_URL" in
  git@github.com:*)
    REPO_WEB_URL="https://github.com/${REPO_WEB_URL#git@github.com:}"
    ;;
  ssh://git@github.com/*)
    REPO_WEB_URL="https://github.com/${REPO_WEB_URL#ssh://git@github.com/}"
    ;;
esac
REPO_WEB_URL="${REPO_WEB_URL%.git}"

case "$HARNESS" in
  claude)
    DEFAULT_HARNESS_DIR="$HOME/.claude"
    ;;
  codex)
    DEFAULT_HARNESS_DIR="${CODEX_HOME:-$HOME/.codex}"
    ;;
  openclaw)
    DEFAULT_HARNESS_DIR="$HOME/.openclaw"
    ;;
  *)
    echo "ERROR — unknown HARNESS '$HARNESS'. Use claude, codex, openclaw, or set HARNESS_DIR directly." >&2
    exit 64
    ;;
esac

if [ -n "${HARNESS_DIR+x}" ]; then
  ROOT_SOURCE="HARNESS_DIR"
elif [ -n "${CLAUDE_DIR+x}" ]; then
  ROOT_SOURCE="CLAUDE_DIR alias"
else
  ROOT_SOURCE="HARNESS=$HARNESS"
fi
HARNESS_DIR="${HARNESS_DIR:-${CLAUDE_DIR:-$DEFAULT_HARNESS_DIR}}"
if [ "$ROOT_SOURCE" = "HARNESS=$HARNESS" ]; then
  DISPLAY_HARNESS="$HARNESS"
else
  DISPLAY_HARNESS="custom ($ROOT_SOURCE)"
fi
SKILLS_DIR="$HARNESS_DIR/skills"
LINK_PATH="$SKILLS_DIR/feishu-deck-h5"

echo "==> feishu-deck-h5 install"
echo "    repo:    $REPO_URL"
echo "    target:  $INSTALL_DIR"
echo "    harness: $DISPLAY_HARNESS"
echo "    root:    $HARNESS_DIR"
echo "    symlink: $LINK_PATH"
echo

# Prereq: verify remote access. SSH remotes get an SSH-key hint; HTTPS remotes
# do not require GitHub SSH setup.
GH_USER=""
case "$REPO_URL" in
  git@github.com:*|ssh://git@github.com/*)
    SSH_OUT="$(ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1 || true)"
    if ! echo "$SSH_OUT" | grep -q "successfully authenticated\|Hi "; then
      echo "ERROR — SSH to github.com failed. Make sure your SSH key is registered:"
      echo "  https://github.com/settings/keys"
      echo "  Test with: ssh -T git@github.com"
      exit 1
    fi
    GH_USER="$(echo "$SSH_OUT" | sed -n 's/^Hi \([^!]*\)!.*/\1/p')"
    ;;
esac

if ! git ls-remote "$REPO_URL" HEAD >/dev/null 2>&1; then
  if [ -n "$GH_USER" ]; then
    cat <<EOF

ERROR — your SSH key works, but you don't have access to this SSH remote.
Send this message to the repo owner on Lark/Feishu:

  ──────────────────────────────────────────────────────────────
  你好，想用一下 feishu-deck-h5 这个 skill，
  请把我加为仓库 collaborator：

  · GitHub 用户名: ${GH_USER:-<你的 GitHub username, 在 https://github.com 登录后右上角>}
  · 仓库: $REPO_WEB_URL
  · 添加入口（仓库管理员这边点）:
    $REPO_WEB_URL/settings/access
  ──────────────────────────────────────────────────────────────

收到 GitHub 邀请邮件后点 "Accept invitation"，然后重新运行本脚本。

EOF
  else
    cat <<EOF

ERROR — cannot access $REPO_URL.

If this is a public repo, check your network and the URL.
If this is a private fork, authenticate with GitHub or set REPO_URL to a
remote you can read.

EOF
  fi
  exit 2
fi

# 1. clone (or update if exists)
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "==> existing clone found at $INSTALL_DIR, pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "==> cloning..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 2. symlink into $HARNESS_DIR/skills/
mkdir -p "$SKILLS_DIR"
if [ -L "$LINK_PATH" ] || [ -e "$LINK_PATH" ]; then
  echo "==> removing existing $LINK_PATH..."
  rm -rf "$LINK_PATH"
fi
ln -s "$INSTALL_DIR/skills/feishu-deck-h5" "$LINK_PATH"
echo "==> symlinked: $LINK_PATH -> $INSTALL_DIR/skills/feishu-deck-h5"

# 3. verify
echo
echo "==> running preflight..."
if bash "$LINK_PATH/assets/preflight.sh"; then
  echo
  echo "==> DONE. Restart your Claude Code / Codex / harness session to pick up the new skill."
else
  echo
  echo "WARN — preflight failed. The skill is installed but the current directory"
  echo "may not be a writable mount. cd into a real project before generating decks."
  echo "(See SKILL.md PREFLIGHT for details.)"
  exit 1
fi
