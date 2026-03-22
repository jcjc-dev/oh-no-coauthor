#!/usr/bin/env bash
set -euo pipefail

# oh-no-coauthor installer
# Installs git hooks that strip AI-generated Co-authored-by trailers.

HOOK_DIR_NAME=".oh-no-coauthor"
GLOBAL_HOOK_DIR="$HOME/$HOOK_DIR_NAME/hooks"
BACKUP_SUFFIX=".pre-oh-no-coauthor"
CONFIG_FILE="$HOME/$HOOK_DIR_NAME/config"

# --- AI patterns to block ---
# This awk pattern matches Co-authored-by lines from known AI tools.
# Add new patterns here as AI tools evolve.
read -r -d '' AWK_PATTERN << 'AWKEOF' || true
/^[[:space:]]*Co-authored-by[[:space:]]*:/ {
    line = tolower($0)
    if (line ~ /copilot/ ||
        line ~ /claude/ ||
        line ~ /codex/ ||
        line ~ /openai/ ||
        line ~ /anthropic/ ||
        line ~ /codeium/ ||
        line ~ /tabnine/ ||
        line ~ /cursor[[:space:]]*</ ||
        line ~ /ai[- ]?assistant/ ||
        line ~ /github[[:space:]]*</ ||
        line ~ /\+copilot@users\.noreply\.github\.com/ ||
        line ~ /copilot@github\.com/ ||
        line ~ /@anthropic\.com/ ||
        line ~ /@openai\.com/) {
        blocked++
        next
    }
}
{ print }
AWKEOF

# --- Hook contents ---

generate_prepare_commit_msg() {
    cat << 'HOOKEOF'
#!/usr/bin/env bash
# oh-no-coauthor: prepare-commit-msg hook
# Strips AI Co-authored-by trailers before the editor opens.

COMMIT_MSG_FILE="$1"

HOOKEOF
    cat << HOOKEOF
# --- begin ai pattern filter ---
tmpfile=\$(mktemp)
awk '
$AWK_PATTERN
END { if (blocked > 0) print "[oh-no-coauthor] stripped " blocked " AI co-author trailer(s)" > "/dev/stderr" }
' "\$COMMIT_MSG_FILE" > "\$tmpfile" && mv "\$tmpfile" "\$COMMIT_MSG_FILE"
# --- end ai pattern filter ---
HOOKEOF
    cat << 'HOOKEOF'

# Chain to previous hook if it exists
if [ -f "$0.pre-oh-no-coauthor" ]; then
    exec "$0.pre-oh-no-coauthor" "$@"
fi
HOOKEOF
}

generate_commit_msg() {
    cat << 'HOOKEOF'
#!/usr/bin/env bash
# oh-no-coauthor: commit-msg hook
# Final safety net — catches any AI Co-authored-by trailers that survived.

COMMIT_MSG_FILE="$1"

HOOKEOF
    cat << HOOKEOF
# --- begin ai pattern filter ---
tmpfile=\$(mktemp)
awk '
$AWK_PATTERN
END { if (blocked > 0) print "[oh-no-coauthor] commit-msg hook caught " blocked " AI co-author trailer(s)" > "/dev/stderr" }
' "\$COMMIT_MSG_FILE" > "\$tmpfile" && mv "\$tmpfile" "\$COMMIT_MSG_FILE"
# --- end ai pattern filter ---
HOOKEOF
    cat << 'HOOKEOF'

# Chain to previous hook if it exists
if [ -f "$0.pre-oh-no-coauthor" ]; then
    exec "$0.pre-oh-no-coauthor" "$@"
fi
HOOKEOF
}

# --- Install logic ---

usage() {
    echo "Usage: install.sh [--global | --local]"
    echo ""
    echo "  --global   Install hooks globally for all repos (default)"
    echo "  --local    Install hooks in the current repo only"
    echo ""
    echo "Global install sets core.hooksPath to $GLOBAL_HOOK_DIR"
    echo "Local install copies hooks into .git/hooks/ of the current repo"
}

install_hook() {
    local target_dir="$1"
    local hook_name="$2"
    local hook_content="$3"
    local hook_path="$target_dir/$hook_name"

    # Back up existing hook if it's not ours
    if [ -f "$hook_path" ] && ! grep -q "oh-no-coauthor" "$hook_path"; then
        echo "  Backing up existing $hook_name → ${hook_name}${BACKUP_SUFFIX}"
        mv "$hook_path" "${hook_path}${BACKUP_SUFFIX}"
    fi

    echo "$hook_content" > "$hook_path"
    chmod +x "$hook_path"
    echo "  Installed $hook_name"
}

install_global() {
    echo "Installing oh-no-coauthor hooks globally..."
    echo ""

    mkdir -p "$GLOBAL_HOOK_DIR"
    mkdir -p "$(dirname "$CONFIG_FILE")"

    # Save previous hooksPath if set
    local prev_hooks_path
    prev_hooks_path=$(git config --global core.hooksPath 2>/dev/null || echo "")
    if [ -n "$prev_hooks_path" ] && [ "$prev_hooks_path" != "$GLOBAL_HOOK_DIR" ]; then
        echo "  Saving previous core.hooksPath: $prev_hooks_path"
        echo "previous_hooks_path=$prev_hooks_path" > "$CONFIG_FILE"

        # Copy existing hooks from the old path
        if [ -d "$prev_hooks_path" ]; then
            for hook in "$prev_hooks_path"/*; do
                [ -f "$hook" ] && cp "$hook" "$GLOBAL_HOOK_DIR/"
            done
        fi
    fi

    install_hook "$GLOBAL_HOOK_DIR" "prepare-commit-msg" "$(generate_prepare_commit_msg)"
    install_hook "$GLOBAL_HOOK_DIR" "commit-msg" "$(generate_commit_msg)"

    git config --global core.hooksPath "$GLOBAL_HOOK_DIR"
    echo ""
    echo "Done. core.hooksPath set to $GLOBAL_HOOK_DIR"
    echo "AI co-author trailers will be stripped from all repos."
    echo ""
    echo "To undo: curl -fsSL https://raw.githubusercontent.com/jcjc-dev/oh-no-coauthor/main/uninstall.sh | bash"
}

install_local() {
    echo "Installing oh-no-coauthor hooks in this repo..."
    echo ""

    if [ ! -d ".git" ]; then
        echo "Error: not in a git repository. Run this from the root of a git repo."
        exit 1
    fi

    local hook_dir=".git/hooks"
    mkdir -p "$hook_dir"

    install_hook "$hook_dir" "prepare-commit-msg" "$(generate_prepare_commit_msg)"
    install_hook "$hook_dir" "commit-msg" "$(generate_commit_msg)"

    echo ""
    echo "Done. Hooks installed in .git/hooks/"
    echo "AI co-author trailers will be stripped in this repo."
}

# --- Main ---

MODE="global"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --global) MODE="global"; shift ;;
        --local)  MODE="local"; shift ;;
        --help|-h) usage; exit 0 ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

case "$MODE" in
    global) install_global ;;
    local)  install_local ;;
esac
