# cc-permission-popup

Claude Code の権限リクエストを macOS ネイティブポップアップで表示するツール。

コマンドの内容を日本語で解説し、リスクレベルを5段階で色分け表示。許可/拒否をポップアップから直接操作できます。

<img width="526" height="487" alt="スクリーンショット 2026-02-25 12 40 41" src="https://github.com/user-attachments/assets/8d1b710c-2fd9-4059-8c8c-14381beebbc2" />

<img width="526" height="490" alt="スクリーンショット 2026-02-25 12 41 01" src="https://github.com/user-attachments/assets/6d6dd83a-2262-4e58-8f54-28d653009e94" />

## 特徴

- **日本語で解説** — コマンドの意味と影響を日本語で表示
- **リスク5段階表示** — 安全(緑) / 低(青) / 中(橙) / 高(赤) / 危険(赤)
- **ポップアップから直接操作** — 拒否 / 許可 / 常に許可 の3択
- **全ツール対応** — Bash, Edit, Write, WebFetch, WebSearch, Task, MCP
- **設定不要** — インストールするだけ。API key 不要
- **ネイティブ UI** — SwiftUI + SF Symbols、すりガラス背景
- **高速** — ポップアップ表示まで ~90ms

## 動作の仕組み

```
Claude Code がツール実行を要求
  → PermissionRequest フック発火
    → ルールエンジンでリスク判定 + 日本語説明生成
      → SwiftUI ポップアップ表示
        → ユーザーが 拒否 / 許可 / 常に許可
          → Claude Code に結果を返却
```

ルールにマッチしないコマンドは、Claude Code が自動付与する `description` フィールド（AI が生成した説明）をそのまま表示します。

## 必要環境

- **macOS 14.0+** (Sonoma 以降)
- **Claude Code** がインストール済み
- **jq** (`brew install jq`)
- **Xcode Command Line Tools** (`xcode-select --install`)

## インストール

```bash
git clone https://github.com/yama-shoki/claude-code-popup.git
cd claude-code-popup
./install.sh
```

次回の Claude Code セッションから自動的に有効になります。

## アンインストール

```bash
cd claude-code-popup
./uninstall.sh
```

## ファイル構成

```
claude-code-popup/
├── install.sh              # インストーラー
├── uninstall.sh            # アンインストーラー
├── src/
│   ├── permission-hook.sh  # フックエントリーポイント
│   ├── rules.sh            # リスク判定 + 日本語説明エンジン
│   └── swift/
│       └── popup.swift     # SwiftUI ポップアップ
└── README.md
```

インストール先: `~/.claude/hooks/permission-popup/`

## リスク判定

| レベル | 色 | コマンド例 |
|---|---|---|
| **critical** | 赤 | `sudo`, `rm -rf`, `git push --force`, `git reset --hard` |
| **high** | オレンジ | `rm`, `chmod`, `git push`, `mv` |
| **medium** | 黄 | `npm install`, `curl`, `git commit`, `docker` |
| **low** | 青 | `npm run`, `git status`, `find`, `node` |
| **safe** | 緑 | `ls`, `pwd`, `echo`, `cat` |

## 注意

- `permissions.deny` に設定されたコマンドは Claude Code が事前にブロックするため、ポップアップは表示されません
- `permissions.allow` に設定されたコマンドは自動許可されるため、ポップアップは表示されません
- ポップアップが表示されるのは **deny にも allow にも該当しない操作** のみです
- 120秒操作がなければ自動で拒否されます（安全側に倒す）

## License

MIT
