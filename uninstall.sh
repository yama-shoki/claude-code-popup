#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/.claude/hooks/permission-popup"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo ""
echo "  cc-permission-popup アンインストール"
echo ""

# ── settings.json からフック削除 ──

if [ -f "$SETTINGS_FILE" ]; then
    tmp=$(mktemp)
    jq --arg cmd "${INSTALL_DIR}/permission-hook.sh" '
        if .hooks.PermissionRequest then
            .hooks.PermissionRequest = [
                .hooks.PermissionRequest[] |
                .hooks = [.hooks[] | select(.command != $cmd)] |
                select(.hooks | length > 0)
            ] |
            if (.hooks.PermissionRequest | length) == 0 then
                del(.hooks.PermissionRequest)
            else . end
        else . end
    ' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    echo "✓ settings.json から permission-popup フックを削除"
fi

# ── ファイル削除 ──

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "✓ ${INSTALL_DIR}/ を削除"
fi

echo ""
echo "  ✅ アンインストール完了"
echo "  次回の Claude Code セッションから無効になります。"
echo ""
