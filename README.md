# cc-permission-popup

Claude Code の権限リクエストを macOS ネイティブポップアップで表示するツール。

コマンドの内容を日本語で解説し、リスクレベルを5段階で色分け表示。許可/拒否をポップアップから直接操作できます。

<img width="526" height="487" alt="スクリーンショット 2026-02-25 12 47 29" src="https://github.com/user-attachments/assets/4a9e78cb-01c2-4994-a3f0-b26b79c6f949" />

<img width="526" height="412" alt="スクリーンショット 2026-02-25 12 47 49" src="https://github.com/user-attachments/assets/8d11b9fd-1b8b-4089-978a-2a8b489a01bb" />

## セットアップ

**以下をコピーして Claude Code に貼り付けるだけ。** インストールと権限設定が自動で完了します。

### この設定で何が起きる？

```
✅ 確認なしで自動実行（ポップアップ出ない）
   ファイルの読み書き・編集・検索
   git status / diff / log / branch
   npm run / bun run / テスト実行
   ls / cat / echo 等の安全なコマンド

⚠️ ポップアップで都度確認
   npm install 等のパッケージ追加
   git commit / merge / stash
   docker コマンド
   MCP サーバー操作

🚫 自動でブロック（実行できない）
   rm / sudo / git push / git reset
   .env / 秘密鍵 / credentials の読み書き
   curl / wget（意図しない外部通信を防止）
   データベース直接操作（psql / mysql）
```

### プロンプト

````
cc-permission-popup をセットアップして。以下の手順を順番に実行して、各ステップの結果を報告して。

■ ステップ1: 環境チェック
以下を確認:
- jq がインストールされているか (なければ brew install jq を案内)
- swiftc が利用可能か (なければ xcode-select --install を案内)
- macOS バージョンが 14.0 以上か

■ ステップ2: インストール
git clone https://github.com/yama-shoki/claude-code-popup.git ~/claude-code-popup
cd ~/claude-code-popup && ./install.sh

■ ステップ3: 権限設定
~/.claude/settings.json の permissions を以下で更新。
既存の設定（hooks, env, statusLine 等）はそのまま維持して、permissions だけ差し替え。

{
  "permissions": {
    "allow": [
      "Read", "Glob", "Grep",
      "Edit", "Write", "MultiEdit",
      "Task", "WebSearch", "WebFetch",
      "Bash(ls:*)", "Bash(pwd:*)", "Bash(which:*)",
      "Bash(wc:*)", "Bash(file:*)", "Bash(echo:*)",
      "Bash(cat:*)", "Bash(head:*)", "Bash(tail:*)",
      "Bash(date:*)", "Bash(whoami:*)", "Bash(uname:*)",
      "Bash(stat:*)", "Bash(env:*)", "Bash(printenv:*)",
      "Bash(git status:*)", "Bash(git diff:*)",
      "Bash(git log:*)", "Bash(git branch:*)",
      "Bash(git show:*)", "Bash(git remote:*)",
      "Bash(npm run:*)", "Bash(bun run:*)",
      "Bash(npm test:*)", "Bash(bun test:*)",
      "Bash(node:*)", "Bash(npx:*)", "Bash(bunx:*)"
    ],
    "deny": [
      "Bash(sudo:*)", "Bash(rm:*)", "Bash(rm -rf:*)",
      "Bash(git push:*)", "Bash(git reset:*)", "Bash(git rebase:*)",
      "Read(.env*)", "Read(id_rsa)", "Read(id_ed25519)",
      "Read(**/*.key)", "Read(**/*.pem)", "Read(**/*credentials*)",
      "Edit(.env*)", "Edit(**/*.key)", "Edit(**/*.pem)",
      "Edit(**/*credentials*)", "Edit(**/secrets/**)",
      "Write(.env*)", "Write(**/secrets/**)",
      "Write(**/*.key)", "Write(**/*.pem)",
      "Bash(curl:*)", "Bash(wget:*)", "Bash(nc:*)",
      "Bash(npm uninstall:*)", "Bash(npm remove:*)",
      "Bash(psql:*)", "Bash(mysql:*)", "Bash(mongod:*)"
    ]
  }
}

■ 完了したら
「セットアップ完了」と伝えて、次回のセッションから有効になることを教えて。
````

## 特徴

- **日本語で解説** — コマンドの意味と影響を日本語で表示
- **リスク5段階表示** — 安全(緑) / 低(青) / 中(橙) / 高(赤) / 危険(赤)
- **リスク別ボタン構成** — 危険な操作ほどボタンを制限
- **全ツール対応** — Bash, Edit, Write, WebFetch, WebSearch, Task, MCP
- **設定不要** — インストールするだけ。API key 不要
- **ネイティブ UI** — SwiftUI + SF Symbols、すりガラス背景
- **高速** — ポップアップ表示まで ~90ms

## ボタン構成

| リスク | ボタン |
|--------|--------|
| **safe** | ポップアップなし（自動許可） |
| **low / medium** | 拒否 / 許可 / このセッション中は許可 |
| **high / critical** | 拒否 / 許可 のみ |

| ボタン | 動作 |
|--------|------|
| **許可** | 今回の1回だけ許可 |
| **このセッション中は許可** | セッション中は同パターンを自動許可 |
| **拒否** | 実行を拒否 |

## 動作の仕組み

```
Claude Code がツール実行を要求
  → PermissionRequest フック発火
    → ルールエンジンでリスク判定 + 日本語説明生成
      → safe: 自動許可（ポップアップなし）
      → low/medium: SwiftUI ポップアップ（3ボタン）
      → high/critical: SwiftUI ポップアップ（2ボタン）
        → ユーザーが操作
          → Claude Code に結果を返却
```

## 必要環境

- **macOS 14.0+** (Sonoma 以降)
- **Claude Code** がインストール済み
- **jq** (`brew install jq`)
- **Xcode Command Line Tools** (`xcode-select --install`)

## 手動インストール

```bash
git clone https://github.com/yama-shoki/claude-code-popup.git
cd claude-code-popup
./install.sh
```

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

| レベル | 色 | コマンド例 | ポップアップ |
|---|---|---|---|
| **critical** | 赤 | `sudo`, `rm -rf`, `git push --force` | 2ボタン |
| **high** | オレンジ | `rm`, `chmod`, `git push`, `mv` | 2ボタン |
| **medium** | 黄 | `npm install`, `git commit`, `docker` | 3ボタン |
| **low** | 青 | `npm run`, `git status`, `node` | 3ボタン |
| **safe** | 緑 | `ls`, `pwd`, `echo`, `cat` | なし |

## 注意

- `permissions.allow` のコマンドは自動許可（ポップアップなし）
- `permissions.deny` のコマンドは自動拒否（実行不可）
- ポップアップが出るのは **どちらにも該当しない操作だけ**
- 120秒操作がなければ自動で拒否（安全側に倒す）

## License

MIT
