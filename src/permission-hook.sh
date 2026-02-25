#!/bin/bash
# Claude Code PermissionRequest Hook
# macOS ネイティブポップアップで権限リクエストを日本語表示
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POPUP_BIN="${SCRIPT_DIR}/bin/cc-permission-popup"
TIMEOUT=120

# stdin からJSON入力を読み取り
input=$(cat)

# ツール情報を抽出
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
tool_input=$(echo "$input" | jq -c '.tool_input // {}')

# ツール名がなければフォールスルー（通常のターミナルプロンプト）
if [ -z "$tool_name" ]; then
    exit 0
fi

# ルールエンジンを読み込み
source "${SCRIPT_DIR}/rules.sh"

# ── description フィールド取得（Claude Code が付与した説明）──
tool_description=$(echo "$tool_input" | jq -r '.description // ""')
export _TOOL_DESCRIPTION="$tool_description"

# ── リスクレベル判定 & 表示用コマンド抽出 ──
case "$tool_name" in
    "Bash")
        cmd=$(echo "$tool_input" | jq -r '.command // ""')
        risk=$(classify_bash_risk "$cmd")
        command_display="$cmd"
        ;;
    "Edit"|"MultiEdit")
        file_path=$(echo "$tool_input" | jq -r '.file_path // ""')
        risk=$(classify_file_risk "$file_path")
        command_display="$file_path"
        ;;
    "Write")
        file_path=$(echo "$tool_input" | jq -r '.file_path // ""')
        risk=$(classify_file_risk "$file_path")
        command_display="$file_path"
        ;;
    "WebFetch")
        url=$(echo "$tool_input" | jq -r '.url // ""')
        risk="low"
        command_display="$url"
        ;;
    "WebSearch")
        query=$(echo "$tool_input" | jq -r '.query // ""')
        risk="low"
        command_display="$query"
        ;;
    "Task")
        desc=$(echo "$tool_input" | jq -r '.description // ""')
        risk="low"
        command_display="$desc"
        ;;
    "Glob"|"Grep"|"Read")
        risk="safe"
        command_display=$(echo "$tool_input" | jq -r '.pattern // .file_path // ""')
        ;;
    mcp__*)
        risk="medium"
        command_display=$(echo "$tool_input" | jq -r 'to_entries | map(.key + ": " + (.value | tostring)) | join(", ")' 2>/dev/null || echo "$tool_name")
        ;;
    *)
        risk="medium"
        command_display=$(echo "$tool_input" | jq -r 'to_entries | map(.key + ": " + (.value | tostring)) | join(", ")' 2>/dev/null || echo "$tool_name")
        ;;
esac

# ── 日本語説明生成 ──
explanation=$(generate_explanation "$tool_name" "$tool_input")
impact=$(generate_impact "$tool_name" "$risk" "$tool_input")

# ── GUIが利用可能かチェック ──
has_gui() {
    if [ -n "${SSH_CONNECTION:-}" ] && [ -z "${DISPLAY:-}" ]; then
        return 1
    fi
    return 0
}

# ── ポップアップ表示 ──
if has_gui && [ -x "$POPUP_BIN" ]; then
    decision=$("$POPUP_BIN" \
        --tool "$tool_name" \
        --risk "$risk" \
        --command "$command_display" \
        --explanation "$explanation" \
        --impact "$impact" \
        --timeout "$TIMEOUT" \
        2>/dev/null || echo "")

    # バイナリが失敗した場合はフォールスルー
    if [ -z "$decision" ]; then
        exit 0
    fi
elif has_gui; then
    # osascript フォールバック
    risk_label=""
    case "$risk" in
        "safe")     risk_label="安全" ;;
        "low")      risk_label="低" ;;
        "medium")   risk_label="中" ;;
        "high")     risk_label="高" ;;
        "critical") risk_label="危険" ;;
    esac

    icon_type="note"
    if [ "$risk" = "high" ] || [ "$risk" = "critical" ]; then
        icon_type="caution"
    fi

    dialog_text="ツール: ${tool_name}
リスク: ${risk_label}

コマンド:
${command_display}

${explanation}"

    dialog_text="${dialog_text//\\/\\\\}"
    dialog_text="${dialog_text//\"/\\\"}"

    decision=$(osascript -e "
        tell application \"System Events\"
            activate
            try
                set theResult to display dialog \"${dialog_text}\" buttons {\"拒否\", \"許可\"} default button \"許可\" cancel button \"拒否\" with title \"Claude Code 権限リクエスト\" with icon ${icon_type} giving up after ${TIMEOUT}
                if gave up of theResult then
                    return \"deny\"
                end if
                return \"allow\"
            on error
                return \"deny\"
            end try
        end tell
    " 2>/dev/null || echo "deny")
else
    exit 0
fi

# ── Claude Code形式のJSONを出力 ──
if [ "$decision" = "allow" ]; then
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PermissionRequest",
            decision: {
                behavior: "allow"
            }
        }
    }'
else
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PermissionRequest",
            decision: {
                behavior: "deny",
                message: "ユーザーがポップアップから拒否しました"
            }
        }
    }'
fi
