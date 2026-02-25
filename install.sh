#!/bin/bash
set -euo pipefail

# ── cc-permission-popup installer ──

INSTALL_DIR="$HOME/.claude/hooks/permission-popup"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  cc-permission-popup"
echo "  Claude Code permission requests → macOS native popup"
echo ""

# ── 事前チェック ──

# jq
if ! command -v jq &>/dev/null; then
    echo "❌ jq が見つかりません"
    echo "   brew install jq"
    exit 1
fi
echo "✓ jq"

# swiftc
if ! command -v swiftc &>/dev/null; then
    echo "❌ swiftc が見つかりません"
    echo "   xcode-select --install"
    exit 1
fi
echo "✓ swiftc"

# macOS version check
macos_version=$(sw_vers -productVersion | cut -d. -f1)
if [ "$macos_version" -lt 14 ]; then
    echo "❌ macOS 14.0 以上が必要です (現在: $(sw_vers -productVersion))"
    exit 1
fi
echo "✓ macOS $(sw_vers -productVersion)"

echo ""

# ── ビルド ──

echo "⚙ SwiftUI バイナリをビルド中..."
mkdir -p "${SCRIPT_DIR}/build"
swiftc -o "${SCRIPT_DIR}/build/cc-permission-popup" \
    "${SCRIPT_DIR}/src/swift/popup.swift" \
    -framework AppKit -framework SwiftUI \
    -O 2>&1
echo "✓ ビルド完了"

# ── インストール ──

echo "⚙ ファイルを配置中..."
mkdir -p "${INSTALL_DIR}/bin"
cp "${SCRIPT_DIR}/src/permission-hook.sh" "${INSTALL_DIR}/permission-hook.sh"
cp "${SCRIPT_DIR}/src/rules.sh" "${INSTALL_DIR}/rules.sh"
cp "${SCRIPT_DIR}/build/cc-permission-popup" "${INSTALL_DIR}/bin/cc-permission-popup"
chmod +x "${INSTALL_DIR}/permission-hook.sh"
chmod +x "${INSTALL_DIR}/rules.sh"
chmod +x "${INSTALL_DIR}/bin/cc-permission-popup"
echo "✓ ${INSTALL_DIR}/"

# ── settings.json にフック登録 ──

SETTINGS_FILE="$HOME/.claude/settings.json"

# settings.json が存在しなければ作成
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# 自分のフックが登録済みか確認（コマンドパスで判定）
if jq -e --arg cmd "${INSTALL_DIR}/permission-hook.sh" \
    '.hooks.PermissionRequest[]?.hooks[]? | select(.command == $cmd)' \
    "$SETTINGS_FILE" &>/dev/null; then
    echo "✓ PermissionRequest フックは既に登録済み"
else
    echo "⚙ settings.json にフックを登録中..."
    tmp=$(mktemp)
    jq --arg cmd "${INSTALL_DIR}/permission-hook.sh" '
        .hooks = (.hooks // {}) |
        .hooks.PermissionRequest = (.hooks.PermissionRequest // []) + [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": $cmd,
                        "timeout": 130000
                    }
                ]
            }
        ]
    ' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    echo "✓ settings.json 更新完了"
fi

# ── 完了 ──

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ インストール完了"
echo ""
echo "  次回の Claude Code セッションから有効です。"
echo "  claude を起動して普通に使ってください。"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  アンインストール:"
echo "    ./uninstall.sh"
echo ""
