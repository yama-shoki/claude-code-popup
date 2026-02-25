# cc-permission-popup

Claude Code の権限リクエストを macOS ネイティブポップアップで表示するツール。

コマンドの内容を日本語で解説し、リスクレベルを5段階で色分け表示。許可/拒否をポップアップから直接操作できます。

<img width="526" height="487" alt="スクリーンショット 2026-02-25 12 47 29" src="https://github.com/user-attachments/assets/4a9e78cb-01c2-4994-a3f0-b26b79c6f949" />

<img width="526" height="412" alt="スクリーンショット 2026-02-25 12 47 49" src="https://github.com/user-attachments/assets/8d11b9fd-1b8b-4089-978a-2a8b489a01bb" />

<details>
<summary><strong>Claude Code に貼るだけ！対話式セットアッププロンプト</strong></summary>

以下のプロンプトを Claude Code に貼り付けてください。対話形式で環境を確認しながら、あなたのワークフローに合わせた最適な設定を構築します。

````
cc-permission-popup の対話式セットアップを開始して。
以下のガイドに従って、ステップごとにユーザーに確認しながら進めて。
各ステップで何をするか日本語で説明してから実行すること。

---

## ステップ1: 自己紹介と概要説明

ユーザーにこう伝えて:

「cc-permission-popup をセットアップします！
これは Claude Code がツールを実行する時に、macOS ネイティブポップアップで
日本語の説明付きで許可/拒否を選べるようにするツールです。

セットアップでは以下を行います:
1. 必要なツールの確認
2. ビルド＆インストール
3. あなたの開発環境に合わせた権限設定

それでは始めましょう！」

## ステップ2: 環境チェック

以下の3つを確認して、結果をまとめてユーザーに報告:

- jq がインストールされているか (`which jq`)
- swiftc が利用可能か (`which swiftc`)
- macOS バージョンが 14.0 以上か (`sw_vers -productVersion`)

不足があれば、インストール方法を案内して続行するか聞く:
- jq: `brew install jq`
- swiftc: `xcode-select --install`

全て揃っていたら「環境OK！次に進みます」と伝える。

## ステップ3: クローン＆インストール

ユーザーに伝えて:
「リポジトリをクローンしてビルドします。
インストール先: ~/.claude/hooks/permission-popup/」

実行:
1. `git clone https://github.com/yama-shoki/claude-code-popup.git ~/claude-code-popup` (既にあればスキップ)
2. `cd ~/claude-code-popup && ./install.sh`

結果をユーザーに報告。

## ステップ4: 開発環境ヒアリング

ユーザーに以下を聞く（番号で答えてもらう）:

「あなたの開発環境を教えてください。permissions 設定を最適化します。

**Q1. メインのパッケージマネージャーは？**（複数可）
1. npm
2. bun
3. yarn
4. pnpm
5. pip (Python)
6. cargo (Rust)
7. go modules

**Q2. よく使う言語/ランタイムは？**（複数可）
1. Node.js / TypeScript
2. Python
3. Go
4. Rust
5. Ruby
6. Swift
7. Java

**Q3. 以下で使っているものは？**（複数可）
1. Docker
2. Terraform
3. AWS CLI
4. MCP サーバー（Supabase, Playwright 等）
5. 特になし

**Q4. データベースは？**（複数可）
1. PostgreSQL
2. MySQL
3. MongoDB
4. SQLite
5. Supabase
6. 特になし」

## ステップ5: permissions 設定を構築

ユーザーの回答に基づいて `~/.claude/settings.json` の permissions を構築する。

### ベース allow（全員共通）:
```json
[
  "Read", "Glob", "Grep",
  "Edit", "Write", "MultiEdit",
  "Task", "WebSearch", "WebFetch",
  "Bash(ls:*)", "Bash(pwd:*)", "Bash(which:*)",
  "Bash(wc:*)", "Bash(file:*)", "Bash(echo:*)",
  "Bash(cat:*)", "Bash(head:*)", "Bash(tail:*)",
  "Bash(date:*)", "Bash(whoami:*)", "Bash(uname:*)",
  "Bash(stat:*)", "Bash(env:*)", "Bash(printenv:*)",
  "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)",
  "Bash(git branch:*)", "Bash(git show:*)", "Bash(git remote:*)"
]
```

### Q1 回答に応じて allow に追加:
- npm → `"Bash(npm run:*)"`, `"Bash(npm test:*)"`, `"Bash(npx:*)"`
- bun → `"Bash(bun run:*)"`, `"Bash(bun test:*)"`, `"Bash(bunx:*)"`
- yarn → `"Bash(yarn run:*)"`, `"Bash(yarn test:*)"`, `"Bash(yarn dlx:*)"`
- pnpm → `"Bash(pnpm run:*)"`, `"Bash(pnpm test:*)"`, `"Bash(pnpm dlx:*)"`
- pip → `"Bash(python:*)"`, `"Bash(python3:*)"`, `"Bash(pytest:*)"`
- cargo → `"Bash(cargo build:*)"`, `"Bash(cargo test:*)"`, `"Bash(cargo run:*)"`, `"Bash(cargo check:*)"`
- go → `"Bash(go build:*)"`, `"Bash(go test:*)"`, `"Bash(go run:*)"`

### Q2 回答に応じて allow に追加:
- Node.js → `"Bash(node:*)"`, `"Bash(tsc:*)"`
- Python → `"Bash(python:*)"`, `"Bash(python3:*)"`
- Go → `"Bash(go:*)"`
- Rust → `"Bash(rustc:*)"`
- Ruby → `"Bash(ruby:*)"`, `"Bash(bundle:*)"`
- Swift → `"Bash(swift:*)"`, `"Bash(swiftc:*)"`
- Java → `"Bash(java:*)"`, `"Bash(javac:*)"`, `"Bash(gradle:*)"`, `"Bash(mvn:*)"`

### ベース deny（全員共通）:
```json
[
  "Bash(sudo:*)", "Bash(rm:*)", "Bash(rm -rf:*)",
  "Bash(git push:*)", "Bash(git reset:*)", "Bash(git rebase:*)",
  "Read(.env*)", "Read(id_rsa)", "Read(id_ed25519)",
  "Read(**/*.key)", "Read(**/*.pem)", "Read(**/*credentials*)",
  "Edit(.env*)", "Edit(**/*.key)", "Edit(**/*.pem)",
  "Edit(**/*credentials*)", "Edit(**/secrets/**)",
  "Write(.env*)", "Write(**/secrets/**)",
  "Write(**/*.key)", "Write(**/*.pem)",
  "Bash(curl:*)", "Bash(wget:*)", "Bash(nc:*)",
  "Bash(npm uninstall:*)", "Bash(npm remove:*)"
]
```

### Q3/Q4 回答に応じて deny に追加:
- PostgreSQL → `"Bash(psql:*)"`
- MySQL → `"Bash(mysql:*)"`
- MongoDB → `"Bash(mongod:*)"`
- Supabase MCP → `"mcp__supabase__execute_sql"`
- Terraform → `"Bash(terraform destroy:*)"` (allow に `"Bash(terraform plan:*)"`, `"Bash(terraform init:*)"` を追加)
- Docker → deny に `"Bash(docker rm:*)"`, `"Bash(docker rmi:*)"` (allow に `"Bash(docker ps:*)"`, `"Bash(docker logs:*)"` を追加)

## ステップ6: 設定内容の確認

構築した permissions を見やすくフォーマットしてユーザーに提示:

「以下の設定を適用します:

**自動許可 (allow):** XX 個のルール
- 読み取り系: Read, Glob, Grep, ...
- 編集系: Edit, Write, ...
- Bash: ls, git status, npm run, ...（あなたの環境に合わせたもの）

**自動拒否 (deny):** XX 個のルール
- 破壊操作: rm, sudo, git push, ...
- 機密ファイル: .env, .key, credentials, ...

**ポップアップが出るもの（上記以外）:**
npm install, git commit, docker run など

この設定でよいですか？（変更したい項目があれば教えてください）」

ユーザーがOKしたら次へ。変更があれば調整する。

## ステップ7: 適用

1. `~/.claude/settings.json` を読み取り
2. 既存の設定（hooks, env, statusLine 等）はそのまま維持
3. permissions.allow と permissions.deny だけを構築した内容で更新
4. 保存

## ステップ8: 完了報告

「セットアップ完了！

次回の Claude Code セッションから有効になります。
（現在のセッションでは反映されないので、新しいセッションを開始してください）

ポップアップの動作:
- 安全な操作 → 確認なしで自動実行
- 中程度のリスク → ポップアップで確認（永久許可ボタンあり）
- 危険な操作 → ポップアップで確認（許可/拒否のみ）
- 禁止操作 → 自動拒否

後から設定を変えたい場合:
- ~/.claude/settings.json の permissions を編集
- ポップアップの「永久に許可」ボタンでも追加可能」
````

</details>

## 特徴

- **日本語で解説** — コマンドの意味と影響を日本語で表示
- **リスク5段階表示** — 安全(緑) / 低(青) / 中(橙) / 高(赤) / 危険(赤)
- **4段階の許可制御** — リスクレベルに応じたボタン構成で安全に操作
- **全ツール対応** — Bash, Edit, Write, WebFetch, WebSearch, Task, MCP
- **設定不要** — インストールするだけ。API key 不要
- **ネイティブ UI** — SwiftUI + SF Symbols、すりガラス背景
- **高速** — ポップアップ表示まで ~90ms

## ボタン構成

リスクレベルに応じて表示されるボタンが変わります。

| リスク | ボタン構成 | 持続範囲 |
|--------|-----------|----------|
| **safe** | ポップアップなし | 自動許可 |
| **low** | 拒否 / 許可 / このセッション中は許可 / **永久に許可** | — |
| **medium** | 拒否 / 許可 / このセッション中は許可 / **永久に許可** | — |
| **high / critical** | 拒否 / 許可 のみ | — |

| ボタン | 動作 |
|--------|------|
| **許可** | 今回の1回だけ許可 |
| **このセッション中は許可** | 現在のセッション中は同パターンを自動許可 |
| **永久に許可** | `~/.claude/settings.json` にルール追加、次回以降も自動許可 |
| **拒否** | 実行を拒否 |

## 動作の仕組み

```
Claude Code がツール実行を要求
  → PermissionRequest フック発火
    → ルールエンジンでリスク判定 + 日本語説明生成
      → safe: 自動許可（ポップアップなし）
      → low/medium: SwiftUI ポップアップ（4ボタン）
      → high/critical: SwiftUI ポップアップ（2ボタン）
        → ユーザーが操作
          → Claude Code に結果を返却
```

ルールにマッチしないコマンドは、Claude Code が自動付与する `description` フィールド（AI が生成した説明）をそのまま表示します。

## 推奨 permissions 設定

`~/.claude/settings.json` の `permissions` で allow/deny ルールを設定すると、ポップアップの表示頻度を最適化できます。

<details>
<summary><strong>allow（自動許可）一覧</strong></summary>

| カテゴリ | ルール | 説明 |
|----------|--------|------|
| **読み取り専用ツール** | `Read` | ファイル読み取り |
| | `Glob` | ファイルパターン検索 |
| | `Grep` | ファイル内容検索 |
| **編集ツール** | `Edit` | ファイル編集（deny で .env 等はガード） |
| | `Write` | ファイル書き込み（同上） |
| | `MultiEdit` | 複数箇所編集 |
| **その他ツール** | `Task` | サブエージェント起動 |
| | `WebSearch` | Web検索 |
| | `WebFetch` | Webページ取得 |
| **Bash（安全）** | `Bash(ls:*)` | ディレクトリ一覧 |
| | `Bash(pwd:*)` | カレントディレクトリ |
| | `Bash(which:*)` | コマンド所在 |
| | `Bash(wc:*)` | 行数カウント |
| | `Bash(file:*)` | ファイル種別 |
| | `Bash(echo:*)` | テキスト出力 |
| | `Bash(cat:*)` | ファイル内容表示 |
| | `Bash(head:*)` | 先頭行表示 |
| | `Bash(tail:*)` | 末尾行表示 |
| | `Bash(date:*)` | 日時表示 |
| | `Bash(whoami:*)` | ユーザー名 |
| | `Bash(uname:*)` | OS情報 |
| | `Bash(stat:*)` | ファイル情報 |
| | `Bash(env:*)` | 環境変数表示 |
| | `Bash(printenv:*)` | 環境変数表示 |
| **Bash（Git読み取り）** | `Bash(git status:*)` | ステータス確認 |
| | `Bash(git diff:*)` | 差分表示 |
| | `Bash(git log:*)` | 履歴表示 |
| | `Bash(git branch:*)` | ブランチ一覧 |
| | `Bash(git show:*)` | コミット詳細 |
| | `Bash(git remote:*)` | リモート情報 |
| **Bash（開発）** | `Bash(npm run:*)` | npm スクリプト実行 |
| | `Bash(bun run:*)` | bun スクリプト実行 |
| | `Bash(npm test:*)` | npm テスト |
| | `Bash(bun test:*)` | bun テスト |
| | `Bash(node:*)` | Node.js 実行 |
| | `Bash(npx:*)` | npx 実行 |
| | `Bash(bunx:*)` | bunx 実行 |

</details>

<details>
<summary><strong>deny（自動拒否）一覧</strong></summary>

| カテゴリ | ルール | 理由 |
|----------|--------|------|
| **破壊的コマンド** | `Bash(sudo:*)` | 特権昇格 |
| | `Bash(rm:*)` | ファイル削除 |
| | `Bash(rm -rf:*)` | 再帰削除 |
| **Git 破壊操作** | `Bash(git push:*)` | リモートへの公開 |
| | `Bash(git reset:*)` | 履歴巻き戻し |
| | `Bash(git rebase:*)` | 履歴改変 |
| **機密ファイル読取** | `Read(.env*)` | 環境変数ファイル |
| | `Read(id_rsa)` | SSH秘密鍵 |
| | `Read(id_ed25519)` | SSH秘密鍵 |
| | `Read(**/*.key)` | 秘密鍵ファイル |
| | `Read(**/*.pem)` | 証明書/鍵ファイル |
| | `Read(**/*credentials*)` | 認証情報 |
| **機密ファイル編集** | `Edit(.env*)` | 環境変数ファイル |
| | `Edit(**/*.key)` | 秘密鍵ファイル |
| | `Edit(**/*.pem)` | 証明書/鍵ファイル |
| | `Edit(**/*credentials*)` | 認証情報 |
| | `Edit(**/secrets/**)` | シークレットディレクトリ |
| **機密ファイル書込** | `Write(.env*)` | 環境変数ファイル |
| | `Write(**/secrets/**)` | シークレットディレクトリ |
| | `Write(**/*.key)` | 秘密鍵ファイル |
| | `Write(**/*.pem)` | 証明書/鍵ファイル |
| **ネットワーク** | `Bash(curl:*)` | HTTP リクエスト |
| | `Bash(wget:*)` | ファイルダウンロード |
| | `Bash(nc:*)` | ネットワーク接続 |
| **パッケージ削除** | `Bash(npm uninstall:*)` | パッケージ削除 |
| | `Bash(npm remove:*)` | パッケージ削除 |
| **データベース** | `Bash(psql:*)` | PostgreSQL |
| | `Bash(mysql:*)` | MySQL |
| | `Bash(mongod:*)` | MongoDB |

</details>

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

| レベル | 色 | コマンド例 | ポップアップ |
|---|---|---|---|
| **critical** | 赤 | `sudo`, `rm -rf`, `git push --force`, `git reset --hard` | 2ボタン |
| **high** | オレンジ | `rm`, `chmod`, `git push`, `mv` | 2ボタン |
| **medium** | 黄 | `npm install`, `curl`, `git commit`, `docker` | 4ボタン |
| **low** | 青 | `npm run`, `git status`, `find`, `node` | 4ボタン |
| **safe** | 緑 | `ls`, `pwd`, `echo`, `cat` | なし（自動許可） |

## 注意

- `permissions.deny` に設定されたコマンドは Claude Code が事前にブロックするため、ポップアップは表示されません
- `permissions.allow` に設定されたコマンドは自動許可されるため、ポップアップは表示されません
- ポップアップが表示されるのは **deny にも allow にも該当しない操作** のみです
- safe リスクの操作（Read, Glob, Grep 等）はフック内で自動許可されます
- 120秒操作がなければ自動で拒否されます（安全側に倒す）
- 「永久に許可」は `~/.claude/settings.json` の allow リストにルールを追加します

## License

MIT
