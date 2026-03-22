#!/usr/bin/env bash
set -euo pipefail

# oh-no-coauthor uninstaller
# Removes hooks and restores previous configuration.

HOOK_DIR_NAME=".oh-no-coauthor"
GLOBAL_HOOK_DIR="$HOME/$HOOK_DIR_NAME/hooks"
BACKUP_SUFFIX=".pre-oh-no-coauthor"
CONFIG_FILE="$HOME/$HOOK_DIR_NAME/config"

usage() {
    echo "Usage: uninstall.sh [--global | --local]"
    echo ""
    echo "  --global   Remove global hooks (default)"
    echo "  --local    Remove hooks from the current repo only"
}

remove_hook() {
    local hook_path="$1"
    local hook_name
    hook_name=$(basename "$hook_path")

    if [ -f "$hook_path" ] && grep -q "oh-no-coauthor" "$hook_path"; then
        rm "$hook_path"
        echo "  Removed $hook_name"

        # Restore backup if it exists
        if [ -f "${hook_path}${BACKUP_SUFFIX}" ]; then
            mv "${hook_path}${BACKUP_SUFFIX}" "$hook_path"
            echo "  Restored previous $hook_name from backup"
        fi
    fi
}

uninstall_global() {
    echo "Removing oh-no-coauthor global hooks..."
    echo ""

    if [ ! -d "$GLOBAL_HOOK_DIR" ]; then
        echo "Nothing to remove — oh-no-coauthor is not installed globally."
        exit 0
    fi

    remove_hook "$GLOBAL_HOOK_DIR/prepare-commit-msg"
    remove_hook "$GLOBAL_HOOK_DIR/commit-msg"

    # Restore previous hooksPath
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
        if [ -n "${previous_hooks_path:-}" ]; then
            echo "  Restoring previous core.hooksPath: $previous_hooks_path"
            git config --global core.hooksPath "$previous_hooks_path"
        else
            git config --global --unset core.hooksPath || true
        fi
        rm "$CONFIG_FILE"
    else
        # Check if hooksPath still points to our dir
        current_hooks_path=$(git config --global core.hooksPath 2>/dev/null || echo "")
        if echo "$current_hooks_path" | grep -q "\.oh-no-coauthor"; then
            git config --global --unset core.hooksPath || true
            echo "  Removed core.hooksPath config"
        fi
    fi

    # Clean up directory if empty
    remaining=$(find "$GLOBAL_HOOK_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$remaining" = "0" ]; then
        rm -rf "$HOME/$HOOK_DIR_NAME"
        echo "  Cleaned up $HOME/$HOOK_DIR_NAME"
    else
        echo "  Note: $GLOBAL_HOOK_DIR still has other hooks, leaving directory intact"
    fi

    echo ""
    echo "Done. oh-no-coauthor has been removed."
}

uninstall_local() {
    echo "Removing oh-no-coauthor hooks from this repo..."
    echo ""

    if [ ! -d ".git" ]; then
        echo "Error: not in a git repository. Run this from the root of a git repo."
        exit 1
    fi

    remove_hook ".git/hooks/prepare-commit-msg"
    remove_hook ".git/hooks/commit-msg"

    echo ""
    echo "Done. oh-no-coauthor hooks removed from this repo."
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
    global) uninstall_global ;;
    local)  uninstall_local ;;
esac
