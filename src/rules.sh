#!/bin/bash
# Claude Code Permission Popup - Risk Classification & Japanese Explanation Engine
#
# ルールにマッチ → 日本語説明（即時）
# マッチしない  → Claude Codeの description をそのまま表示（設定不要）

# ── Bash コマンドのリスク判定 ──
classify_bash_risk() {
    local cmd="$1"
    local first_word="${cmd%% *}"

    # CRITICAL: 破壊的・特権昇格
    case "$cmd" in
        sudo\ *)          echo "critical"; return ;;
        *rm\ *-rf*)       echo "critical"; return ;;
        *rm\ *-fr*)       echo "critical"; return ;;
        dd\ if=*)         echo "critical"; return ;;
        mkfs*)            echo "critical"; return ;;
        *git\ push*--force*) echo "critical"; return ;;
        *git\ reset\ --hard*) echo "critical"; return ;;
        *\|\ sh*|*\|\ bash*) echo "critical"; return ;;
        curl*\|*sh*)      echo "critical"; return ;;
    esac

    # HIGH: ファイル削除・権限変更・リモート操作
    case "$first_word" in
        rm|chmod|chown) echo "high"; return ;;
    esac
    case "$cmd" in
        git\ push*)          echo "high"; return ;;
        git\ checkout\ --*) echo "high"; return ;;
        git\ restore*)      echo "high"; return ;;
        git\ clean*)        echo "high"; return ;;
        mv\ *)              echo "high"; return ;;
    esac

    # MEDIUM: インストール・コミット・ネットワーク
    case "$cmd" in
        curl\ *|wget\ *)               echo "medium"; return ;;
        npm\ install*|npm\ i\ *)       echo "medium"; return ;;
        bun\ add*|bun\ install*)       echo "medium"; return ;;
        yarn\ add*|yarn\ install*)     echo "medium"; return ;;
        pip\ install*|pip3\ install*)  echo "medium"; return ;;
        brew\ install*)                echo "medium"; return ;;
        gem\ install*)                 echo "medium"; return ;;
        cargo\ install*)               echo "medium"; return ;;
        git\ commit*|git\ merge*)     echo "medium"; return ;;
        git\ rebase*|git\ stash*)     echo "medium"; return ;;
        docker\ *)                     echo "medium"; return ;;
        npx\ *|bunx\ *)               echo "medium"; return ;;
    esac

    # LOW: 情報取得・ビルド・テスト
    case "$cmd" in
        npm\ run\ *|npm\ test*|npm\ start*|npm\ dev*|npm\ build*|npm\ lint*) echo "low"; return ;;
        bun\ run\ *|bun\ test*)       echo "low"; return ;;
        yarn\ run\ *|yarn\ test*)     echo "low"; return ;;
        pnpm\ run\ *|pnpm\ test*)     echo "low"; return ;;
        git\ status*|git\ diff*|git\ log*|git\ branch*|git\ show*|git\ remote*) echo "low"; return ;;
        node\ *|python\ *|python3\ *|ruby\ *|swift\ *) echo "low"; return ;;
        make\ *|make|cmake\ *)        echo "low"; return ;;
        cargo\ build*|cargo\ test*|cargo\ run*) echo "low"; return ;;
        go\ build*|go\ test*|go\ run*) echo "low"; return ;;
    esac
    case "$first_word" in
        find|grep|rg|ag|fd) echo "low"; return ;;
    esac

    # SAFE: 読み取り専用
    case "$first_word" in
        ls|pwd|echo|date|whoami|cat|head|tail|wc|which|type|file|stat|env|printenv|uname)
            echo "safe"; return ;;
    esac

    # デフォルト: medium
    echo "medium"
}

# ── Edit/Write ファイルのリスク判定 ──
classify_file_risk() {
    local file_path="$1"

    # 機密ファイル: HIGH
    case "$file_path" in
        *.env|*.pem|*.key|*.secret|*.credentials) echo "high"; return ;;
        */.env.*|*/credentials.*|*/secrets.*) echo "high"; return ;;
        */.ssh/*|*/.aws/*) echo "high"; return ;;
    esac

    # 設定ファイル: MEDIUM
    case "$file_path" in
        */package.json|*/tsconfig*|*/.eslintrc*|*/.prettierrc*) echo "medium"; return ;;
        */Dockerfile*|*/docker-compose*|*/Makefile) echo "medium"; return ;;
        */.github/*|*/.claude/*) echo "medium"; return ;;
    esac

    # ソースコード: LOW
    echo "low"
}

# ── 日本語説明生成: Bash ──
generate_bash_explanation() {
    local cmd="$1"

    case "$cmd" in
        # npm/bun/yarn install (パッケージ指定あり)
        "npm install "*)
            local pkg="${cmd#npm install }"
            pkg="${pkg%% *}"
            echo "パッケージ「${pkg}」をインストールします。"$'\n'"node_modules にファイルが追加されます。"
            return ;;
        "npm i "*)
            local pkg="${cmd#npm i }"
            pkg="${pkg%% *}"
            echo "パッケージ「${pkg}」をインストールします。"$'\n'"node_modules にファイルが追加されます。"
            return ;;
        "bun add "*)
            local pkg="${cmd#bun add }"
            pkg="${pkg%% *}"
            echo "パッケージ「${pkg}」をインストールします。"
            return ;;
        "yarn add "*)
            local pkg="${cmd#yarn add }"
            pkg="${pkg%% *}"
            echo "パッケージ「${pkg}」をインストールします。"
            return ;;

        # npm/bun/yarn install (パッケージ指定なし)
        "npm install"|"npm i"|"bun install"|"yarn install"|"yarn"|"pnpm install")
            echo "package.json に基づいて依存関係をインストールします。"
            return ;;

        # pip install
        "pip install "*)
            local pkg="${cmd#pip install }"
            echo "Pythonパッケージ「${pkg}」をインストールします。"
            return ;;
        "pip3 install "*)
            local pkg="${cmd#pip3 install }"
            echo "Pythonパッケージ「${pkg}」をインストールします。"
            return ;;

        # brew install
        "brew install "*)
            local pkg="${cmd#brew install }"
            echo "Homebrew で「${pkg}」をインストールします。"
            return ;;

        # git push --force
        "git push "*"--force"*|"git push "*"-f"*)
            echo "リモートリポジトリに強制プッシュします。"$'\n'"リモートの履歴が上書きされます。"
            return ;;
        "git push"*)
            echo "リモートリポジトリにプッシュします。"$'\n'"変更が公開されます。"
            return ;;

        # git commit
        "git commit"*)
            echo "変更をコミットします。"
            return ;;

        # git reset --hard
        "git reset --hard"*)
            echo "作業ディレクトリの変更をすべて破棄します。"$'\n'"コミットされていない変更は失われます。"
            return ;;

        # git checkout/restore
        "git checkout -- "*)
            echo "ファイルの変更を元に戻します。"$'\n'"未コミットの変更が失われる可能性があります。"
            return ;;
        "git restore "*)
            echo "ファイルの変更を元に戻します。"$'\n'"未コミットの変更が失われる可能性があります。"
            return ;;

        # rm -rf
        rm\ *-r*)
            local target="${cmd##* }"
            echo "「${target}」を再帰的に削除します。"$'\n'"この操作は元に戻せません。"
            return ;;

        # rm (単体)
        "rm "*)
            local target="${cmd#rm }"
            target="${target#-* }"
            echo "ファイル「${target}」を削除します。"
            return ;;

        # sudo
        "sudo "*)
            local subcmd="${cmd#sudo }"
            echo "管理者権限でコマンドを実行します。"$'\n'"コマンド: ${subcmd}"
            return ;;

        # npm/bun/yarn run
        "npm run "*)
            local script="${cmd#npm run }"
            echo "スクリプト「${script}」を実行します。"
            return ;;
        "bun run "*)
            local script="${cmd#bun run }"
            echo "スクリプト「${script}」を実行します。"
            return ;;
        "yarn run "*)
            local script="${cmd#yarn run }"
            echo "スクリプト「${script}」を実行します。"
            return ;;
        "pnpm run "*)
            local script="${cmd#pnpm run }"
            echo "スクリプト「${script}」を実行します。"
            return ;;

        # test
        *" test"|*" test "*)
            echo "テストスイートを実行します。"
            return ;;

        # build
        *" build"|*" build "*)
            echo "プロジェクトをビルドします。"
            return ;;

        # dev
        *" dev"|*" dev "*)
            echo "開発サーバーを起動します。"
            return ;;

        # curl/wget
        "curl "*)
            echo "HTTPリクエストを送信します。"
            return ;;
        "wget "*)
            echo "ファイルをダウンロードします。"
            return ;;

        # docker
        "docker "*)
            echo "Dockerコンテナを操作します。"
            return ;;

        # npx/bunx
        "npx "*)
            local pkg="${cmd#npx }"
            pkg="${pkg%% *}"
            echo "「${pkg}」をワンタイム実行します。"
            return ;;
        "bunx "*)
            local pkg="${cmd#bunx }"
            pkg="${pkg%% *}"
            echo "「${pkg}」をワンタイム実行します。"
            return ;;

        # chmod/chown
        "chmod "*)
            echo "ファイルのアクセス権限を変更します。"
            return ;;
        "chown "*)
            echo "ファイルの所有者を変更します。"
            return ;;

        # mv
        "mv "*)
            echo "ファイルを移動/名前変更します。"
            return ;;

        # mkdir
        "mkdir "*)
            echo "ディレクトリを作成します。"
            return ;;

        # for ループ
        "for "*)
            echo "ループ処理を実行します。"$'\n'"内容を確認してください。"
            return ;;
    esac

    # 読み取り専用系
    local first_word="${cmd%% *}"
    case "$first_word" in
        cat|head|tail|less|more)
            echo "ファイルの内容を読み取ります（安全）。"
            return ;;
        ls)
            echo "ディレクトリの内容を一覧表示します（安全）。"
            return ;;
        find|grep|rg|ag|fd)
            echo "ファイルを検索します（安全）。"
            return ;;
        echo|pwd|which|type|whoami|date|uname)
            echo "情報を表示します（安全）。"
            return ;;
    esac

    # パイプを含むコマンド
    if [[ "$cmd" == *"|"* ]]; then
        local first_cmd="${cmd%%|*}"
        first_cmd="${first_cmd%% }"
        echo "パイプライン処理を実行します。"$'\n'"先頭コマンド: ${first_cmd}"
        return
    fi

    # フォールバック: descriptionがあればそれを表示
    if [ -n "${_TOOL_DESCRIPTION:-}" ]; then
        echo "${_TOOL_DESCRIPTION}"
    else
        echo "コマンドを実行します。"
    fi
}

# ── 日本語説明生成: メイン ──
generate_explanation() {
    local tool_name="$1"
    local tool_input_json="$2"

    case "$tool_name" in
        "Bash")
            local cmd
            cmd=$(echo "$tool_input_json" | jq -r '.command // ""')
            generate_bash_explanation "$cmd"
            ;;
        "Edit"|"MultiEdit")
            local file_path
            file_path=$(echo "$tool_input_json" | jq -r '.file_path // ""')
            local filename="${file_path##*/}"
            echo "ファイル「${filename}」を編集します。"$'\n'"変更内容はdiffとして確認できます。"
            ;;
        "Write")
            local file_path
            file_path=$(echo "$tool_input_json" | jq -r '.file_path // ""')
            local filename="${file_path##*/}"
            if [ -f "$file_path" ]; then
                echo "ファイル「${filename}」を上書きします。"
            else
                echo "ファイル「${filename}」を新規作成します。"
            fi
            ;;
        "WebFetch")
            local url
            url=$(echo "$tool_input_json" | jq -r '.url // ""')
            local domain
            domain=$(echo "$url" | sed 's|https\{0,1\}://\([^/]*\).*|\1|')
            echo "「${domain}」からWebページを取得します（読み取り専用）。"
            ;;
        "WebSearch")
            local query
            query=$(echo "$tool_input_json" | jq -r '.query // ""')
            echo "「${query}」でWeb検索を実行します（読み取り専用）。"
            ;;
        "Task")
            local desc
            desc=$(echo "$tool_input_json" | jq -r '.description // ""')
            local agent
            agent=$(echo "$tool_input_json" | jq -r '.subagent_type // ""')
            if [ -n "$agent" ]; then
                echo "サブエージェント（${agent}）を起動します。"$'\n'"タスク: ${desc}"
            else
                echo "サブエージェントタスクを起動します。"
            fi
            ;;
        "Glob")
            local pattern
            pattern=$(echo "$tool_input_json" | jq -r '.pattern // ""')
            echo "パターン「${pattern}」でファイルを検索します（安全）。"
            ;;
        "Grep")
            local pattern
            pattern=$(echo "$tool_input_json" | jq -r '.pattern // ""')
            echo "パターン「${pattern}」でファイル内容を検索します（安全）。"
            ;;
        "Read")
            local file_path
            file_path=$(echo "$tool_input_json" | jq -r '.file_path // ""')
            local filename="${file_path##*/}"
            echo "ファイル「${filename}」を読み取ります（安全）。"
            ;;
        mcp__*)
            local mcp_name="${tool_name#mcp__}"
            local server="${mcp_name%%__*}"
            local method="${mcp_name#*__}"
            echo "MCPサーバー「${server}」の「${method}」を実行します。"
            ;;
        *)
            echo "ツール「${tool_name}」を実行します。"
            ;;
    esac
}

# ── 影響範囲生成 ──
generate_impact() {
    local tool_name="$1"
    local risk="$2"
    local tool_input_json="$3"

    case "$risk" in
        "critical")
            echo "・システムに重大な影響を及ぼす可能性があります"
            echo "・元に戻せない変更が含まれる可能性があります"
            ;;
        "high")
            echo "・ファイルの削除や変更が発生します"
            echo "・影響範囲を事前に確認してください"
            ;;
        "medium")
            case "$tool_name" in
                "Bash")
                    local cmd
                    cmd=$(echo "$tool_input_json" | jq -r '.command // ""')
                    case "$cmd" in
                        npm\ install*|npm\ i\ *|bun\ add*|bun\ install*|yarn\ add*)
                            echo "・ディスク使用量が増加します"
                            echo "・package.json が更新される可能性があります"
                            ;;
                        git\ commit*)
                            echo "・リポジトリの履歴が更新されます"
                            ;;
                        curl\ *|wget\ *)
                            echo "・ネットワークアクセスが発生します"
                            ;;
                        *)
                            echo "・プロジェクトのファイルが変更される可能性があります"
                            ;;
                    esac
                    ;;
                *)
                    echo "・プロジェクトのファイルが変更されます"
                    ;;
            esac
            ;;
        "low")
            case "$tool_name" in
                "WebFetch"|"WebSearch")
                    echo "・ネットワークアクセスが発生します"
                    echo "・ファイル変更はありません"
                    ;;
                *)
                    echo "・副作用は限定的です"
                    ;;
            esac
            ;;
        "safe")
            echo "・読み取り専用の安全な操作です"
            ;;
    esac
}
