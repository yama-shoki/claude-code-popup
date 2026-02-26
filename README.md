# cc-permission-popup

<details open>
<summary><strong>Claude Code に貼るだけでセットアップ</strong></summary>

以下のプロンプトをコピーして Claude Code に貼り付けるだけ。対話形式でインストールと権限設定が完了します。

### プロンプト

````
cc-permission-popup をセットアップして。
以下の手順を順番に実行して、各ステップの結果をユーザーに報告しながら進めて。

■ ステップ1: これから何をするか説明
ユーザーにこう伝えて:

「cc-permission-popup をセットアップします。
これは Claude Code がコマンドを実行する前に、macOS ネイティブポップアップで
日本語の説明付きで許可/拒否を選べるようにするツールです。

セットアップでは以下を行います:
1. 必要なツールの確認
2. ビルド＆インストール
3. 権限設定（どの操作を自動許可/ブロックするか）

3 の権限設定ではあなたに確認を取りながら進めます。
それでは始めます！」

■ ステップ2: 環境チェック
以下を確認して結果を報告:
- jq がインストールされているか (なければ brew install jq を案内)
- swiftc が利用可能か (なければ xcode-select --install を案内)
- macOS バージョンが 14.0 以上か
全て揃っていたら次へ。不足があればインストール方法を案内。

■ ステップ3: インストール
git clone https://github.com/yama-shoki/claude-code-popup.git ~/claude-code-popup
cd ~/claude-code-popup && ./install.sh
結果を報告して次へ。

■ ステップ4: 権限設定（対話式・カテゴリ別）
ユーザーにまず概要を伝える:

「次に、どの操作を自動許可/ブロックするか設定します。
~/.claude/settings.json の permissions を更新します。
4カテゴリに分けて1つずつ確認していきます。各カテゴリは y でOK、変更したければ内容を教えてください。」

その後、以下の4カテゴリを **1つずつ順番に** ユーザーに提示し、各カテゴリごとにユーザーの回答を待ってから次に進む。
**重要: 全カテゴリを一度に表示しないこと。1つ表示→回答を待つ→次を表示、を繰り返す。**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
カテゴリ 1/4: ファイル操作・情報表示（自動許可）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

「【1/4】ファイル操作・情報表示を自動許可にします。

  自動許可する操作:
    - Read / Edit / Write / Glob / Grep（コードの読み書き）
    - Task / WebSearch / WebFetch（調査・サブタスク）
    - Skill（スキル実行全般）
    - ls / cat / echo / pwd / which / stat / wc / file 等（情報表示）

  理由: 開発の基本動作で、破壊的な操作はありません。

  → これでOK？ (y / 変更内容)」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
カテゴリ 2/4: Git・開発コマンド（自動許可）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

「【2/4】Git・開発コマンド・ユーティリティを自動許可にします。

  自動許可する操作:
    - git（全サブコマンド: status, diff, log, commit, merge 等）
    - npm / bun / bunx / npx / node（パッケージ管理・ランタイム）
    - gh（GitHub CLI）
    - docker（コンテナ操作）
    - find / grep / sort / diff / tree（ファイル検索・比較）
    - python3 / for / while / test / sleep / timeout（スクリプト系）

  ※ git push / git reset / git rebase は deny で別途ブロックされます

  → これでOK？ (y / 変更内容)」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
カテゴリ 3/4: 破壊操作・機密ファイル（自動ブロック）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

「【3/4】危険な操作と機密ファイルへのアクセスを自動ブロックにします。

  ブロックする操作:
    - rm / sudo（ファイル削除・管理者権限）
    - git push / git reset / git rebase（リモート操作・履歴改変）
    - .env / 秘密鍵(.key, .pem) / credentials の読み書き全て

  理由: 事故防止。これらが必要な場合は手動で実行してください。

  → これでOK？ (y / 変更内容)」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
カテゴリ 4/4: ネットワーク・データベース（自動ブロック）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

「【4/4】ネットワーク通信とDB直接操作を自動ブロックにします。

  ブロックする操作:
    - curl / wget / nc（外部通信）
    - npm uninstall / npm remove（パッケージ削除）
    - psql / mysql / mongod（DB直接操作）

  理由: 意図しない外部通信やデータ操作を防止。

  → これでOK？ (y / 変更内容)」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

全4カテゴリの確認が終わったら、ユーザーの回答に応じて以下の permissions を組み立てて
~/.claude/settings.json に適用する。
既存の設定（hooks, env, statusLine 等）はそのまま維持して、permissions だけ更新。

デフォルトの permissions（ユーザーが全て y の場合）:

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
      "Bash(find:*)", "Bash(grep:*)", "Bash(sort:*)",
      "Bash(comm:*)", "Bash(diff:*)", "Bash(tree:*)",
      "Bash(git:*)", "Bash(npm:*)", "Bash(bun:*)",
      "Bash(bunx:*)", "Bash(npx:*)", "Bash(node:*)",
      "Bash(python3:*)", "Bash(gh:*)", "Bash(docker:*)",
      "Bash(for:*)", "Bash(while:*)", "Bash(test:*)",
      "Bash(sleep:*)", "Bash(timeout:*)",
      "Bash(md5:*)", "Bash(openssl:*)",
      "Skill(*)"
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

ポイント:
- allow は `Bash(git:*)` のようにワイルドカードで広く許可し、deny で危険な操作だけピンポイントでブロック
- deny は allow より優先されるので、`Bash(git:*)` で全許可しても `Bash(git push:*)` はブロックされる
- ユーザーが特定のカテゴリで変更を希望した場合は、該当する項目を allow/deny 間で移動、または削除して調整してから適用する

■ ステップ5: 完了報告
「セットアップ完了！

次回の Claude Code セッションから有効になります。
（今のセッションには反映されないので、新しいセッションを開始してください）

ポップアップの動作:
- 安全な操作 → 確認なしで自動実行
- 中程度の操作 → ポップアップで確認
- 危険な操作 → ポップアップで確認（許可/拒否のみ）
- 禁止操作 → 自動ブロック

後から設定を変えたい場合は ~/.claude/settings.json の permissions を編集してください。」
````

</details>

Claude Code の権限リクエストを macOS ネイティブポップアップで表示するツール。

コマンドの内容を日本語で解説し、リスクレベルを5段階で色分け表示。許可/拒否をポップアップから直接操作できます。

<img width="526" height="487" alt="スクリーンショット 2026-02-25 12 47 29" src="https://github.com/user-attachments/assets/4a9e78cb-01c2-4994-a3f0-b26b79c6f949" />

<img width="526" height="412" alt="スクリーンショット 2026-02-25 12 47 49" src="https://github.com/user-attachments/assets/8d11b9fd-1b8b-4089-978a-2a8b489a01bb" />

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
