# ~/.claude/settings.json リファレンス

最終更新: 2026-08-26

## 背景

Claude Code にはローカル実行（CLI）とクラウド実行（Web）の2つの実行環境がある。

クラウド実行は Anthropic のサンドボックス内で `--dangerously-skip-permissions` 相当の自律実行ができるが、`~/.claude/settings.json` や MCP サーバー等のローカル設定が読まれない。ローカル実行はその逆で、設定の自由度は高いが、デフォルトでは毎回パーミッション確認が入り作業が止まる。

この設定は「クラウド実行の自律性 + ローカルの設定資産」のいいとこ取りを目指したもの。sandbox による OS レベルの分離を有効にすることで、`--dangerously-skip-permissions` なしでもほぼ止まらずに動く環境を実現している。

## 設定の全体構成

### env

```jsonc
"env": {
  "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1"  // セッション品質サーベイのみ無効化
}
```

セッション品質サーベイをオフにする。テレメトリ（Statsig）やエラーログ（Sentry）は無効化しない。

以前は `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"` で一括無効化していたが、この環境変数は Remote Control（`/remote-control`）の eligibility check もブロックしてしまうため廃止した。同様に `DISABLE_TELEMETRY` も Remote Control をブロックする。Remote Control と競合する環境変数の一覧：

| 環境変数 | Remote Control への影響 |
|---|---|
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | ブロック |
| `DISABLE_TELEMETRY` | ブロック |
| `DISABLE_ERROR_REPORTING` | 影響なし |
| `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` | 影響なし |

参考: https://docs.anthropic.com/en/docs/claude-code/remote-control

### attribution

```jsonc
"attribution": { "commit": "", "pr": "", "sessionUrl": false }  // PR・コミット・セッション URL の Claude Code フッター非表示
```

### permissions

#### permissions.allow

```jsonc
"allow": [
  "Read", "Edit",          // 全ファイルの読み書き
  "Bash(npm:*)",           // パッケージマネージャ系
  "Bash(git:*)",           // Git 操作全般
  "Bash(gh:*)",            // GitHub CLI
  "Bash(git push --force-with-lease:*)", // 安全な force push のみ許可
  "Bash(python3:*)",       // Python
  "Bash(nix:*)",           // Nix
  "Bash(home-manager:*)",  // Home Manager
  "Bash(brew:*)",          // Homebrew
  "Bash(docker run:*)",    // Docker 実行（sandbox 外でフォールバック）
  // ... 他、開発でよく使うコマンド群
]
```

元の設定にあったプロジェクト固有のフルパス（`/Users/nozomiishii/Code/...` や worktrees パス）はセッション中の承認蓄積だったため、sandbox 有効化に伴い汎用パターンに整理した。

#### permissions.deny

```jsonc
"deny": [
  // --- git force push 制御 ---
  "Bash(git push --force:*)",  // 危険：リモート履歴を破壊
  "Bash(git push -f:*)",       // --force の短縮形

  // --- GitHub PR マージ保護（元の設定から保持） ---
  "Bash(gh pr merge:*)",
  "Bash(gh api repos/*/pulls/*/merge*)",
  "mcp__github__merge_pull_request",  // GitHub MCP (user scope の github server) の merge tool

  // --- GitHub リポジトリ作成・削除保護（勝手な作成・削除を防止） ---
  "Bash(gh repo create:*)",
  "Bash(gh repo delete:*)",

  // --- 危険コマンド ---
  "Bash(sudo:*)", "Bash(su:*)",
  "Bash(rm -rf /)", "Bash(rm -rf ~)",
  "Bash(shutdown:*)", "Bash(reboot:*)",
  "Bash(launchctl:*)", "Bash(diskutil:*)",

  // --- 1Password CLI 保護（prompt injection 対策） ---
  "Bash(op:*)",                   // op CLI の直接実行をブロック

  // --- DNS exfiltration 対策（CVE-2025-55284 系） ---
  "Bash(dig:*)",                  // DNS クエリのサブドメインにシークレットを埋め込む攻撃を防止
  "Bash(nslookup:*)",
  "Bash(host:*)"
]
```

dotenv ファイルの deny ルールは置いていない。この環境の dotenv は 1Password の `op://` 参照だけを持ち、実シークレットを含まないため。特に `Bash(*.env*)` は Bash コマンド文字列全体に対するグロブで、`runner.environment` や `process.env` を含むだけのコマンドまで拒否してしまうので戻さないこと。

`Read(./secrets/**)` も置いていない。守る対象の `secrets/` ディレクトリがどの repo にも存在せず、参照しているのがこのルール自身だけだったため。

deny ルールの評価順序: deny → ask → allow で、最初にマッチしたルールが勝つ。そのため `Bash(git:*)` で git 全般を allow しつつ、`Bash(git push --force:*)` で force push だけ deny できる。`--force-with-lease` は allow に明示的に入れているため通る。

`mcp__github__merge_pull_request` は、tha / pr skill が GitHub 操作に使う user scope の GitHub MCP server (server 名 `github`) の merge tool を封じる。server の登録は次のコマンドで行い、初回は対話セッションの `/mcp` で OAuth 認証する。remote server の header は toolset 単位の絞り込みしかできず merge tool だけを除外できないため、client 側の deny で防ぐ。

```sh
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --scope user \
  --header "X-MCP-Toolsets: context,repos,pull_requests,actions"
```

#### permissions.defaultMode

```jsonc
"defaultMode": "auto"
```

Auto Mode をデフォルトに設定。sandbox による OS レベルの分離を前提に、パーミッション確認で止まらず自律実行させるワークフロー。議論モードに戻したい時は `shift+tab` で `plan` に切り替える。

Auto mode の利用可能条件: Max / Team / Enterprise / API プラン + 対応モデル（Max は Opus 4.7、その他プランは Sonnet 4.6 / Opus 4.6 / Opus 4.7）。プランがこれらを満たさない場合 `defaultMode: "auto"` を指定してもセッション起動に失敗するため注意（参考: [anthropics/claude-code#48066](https://github.com/anthropics/claude-code/issues/48066)）。

### enabledMcpjsonServers

```jsonc
"enabledMcpjsonServers": []
```

プロジェクトごとの `.mcp.json` から読み込む MCP サーバーの承認リスト。空配列 = 明示承認なし。現状は MCP サーバーを CLI 経由（`claude mcp add ...`）で管理しているためこのキーは未使用。

### hooks

グローバルの hooks は持たない。キー自体を置かない。

- PR タイトルの検証は CI に任せる。判断の記録は [ADR](https://github.com/nozomiishii/dotfiles/blob/main/docs/decisions/PR%20タイトルの事前検証は手元に持たず%20CI%20に任せる.md) にある
- repo のセットアップ（deps install 等）は各 repo が持つ: `.claude/settings.json` の SessionStart hook が `.hooks/setup.sh` を呼び、Codex は `.codex/hooks.json` から同じスクリプトを呼ぶ（[dotfiles#1268](https://github.com/nozomiishii/dotfiles/issues/1268)）。セットアップ内容はパッケージマネージャ等 repo 固有のため正本を repo に置き、グローバルからの自動実行をやめることで、clone した他人の repo でスクリプトが意図せず発火することも構造的になくなる（repo に入る hook はその repo の PR レビューを通る）。worktree の起点の鮮度は Claude Code 本体が担う（v2.1.208+ で origin/HEAD 起点 + 自動 fetch）
- repo 固有の env（[infra](https://github.com/nozomiishii/infra) の `AWS_PROFILE` 等）は hook で注入しない。`CLAUDE_ENV_FILE` 注入は Codex に効かず[蓄積バグ](https://github.com/anthropics/claude-code/issues/67067)もあり、shell rc 方式は Claude Code の shell snapshot が PATH しか保存しないため機能しない。env の正本は各 repo の `mise.toml` の `[env]`
- hook で判断制御（allow/deny）を返す場合、旧フィールド `decision`/`reason` は deprecated。`hookSpecificOutput.permissionDecision` / `hookSpecificOutput.permissionDecisionReason` を使うこと

### worktree

```jsonc
"worktree": {
  "bgIsolation": "none"  // background セッション（claude --bg / /bg）を worktree 隔離せず本体で動かす
}
```

`worktree.bgIsolation` は background セッションのファイル隔離モード（このリポジトリ単位）。Claude Code 本体のスキーマでは `"worktree"` がデフォルトで、background セッションがメイン checkout に Edit/Write しようとすると `EnterWorktree` を呼ぶまでブロックし、初回編集時に `.claude/worktrees/<id>` へ自動隔離する。`"none"` にすると background ジョブがワーキングコピーを直接編集できる。foreground セッションや `claude --worktree` 起動には影響しない（あれは起動時点で worktree を作る別経路）。

`"none"` を選んだ理由は、worktree のセットアップ（各 repo の `.hooks/setup.sh`）が `SessionStart` hook 頼みのため。`SessionStart` の source は `startup` / `resume` / `clear` / `compact` の 4 つだけで `worktree` は存在せず、background セッションが稼働中に `EnterWorktree` で遅延的に worktree へ移っても `SessionStart` は再発火しない。つまりデフォルトの `"worktree"` だと、新規 worktree に `node_modules` が無いまま整わない可能性がある（`EnterWorktree` は `CwdChanged` も発火しないという報告があり保険にならない: [anthropics/claude-code#61802](https://github.com/anthropics/claude-code/issues/61802)）。`"none"` にすれば background は常に本体（起動時に SessionStart hook が整えた状態）で動くため、この問題が起きない。

トレードオフは、複数の background セッションを同じファイルに並列で走らせると衝突すること。並列編集を多用する運用に変える場合はデフォルトの `"worktree"` に戻し、代わりに `WorktreeCreate` hook 等で全 worktree 作成経路に deps install を配線する必要がある。

### statusLine

```jsonc
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }  // model / worktree / diff / context% / cursor リンクを表示
```

### enabledPlugins

```jsonc
"enabledPlugins": {
  "swift-lsp@claude-plugins-official": true,
  "typescript-lsp@claude-plugins-official": true,
  "sentry-mcp@sentry-mcp": true,
  "codex@openai-codex": true,
  "frontend-design@claude-plugins-official": true,
  "security-guidance@claude-plugins-official": true
}
```

プラグインの有効化状態。`/plugin` で管理する（直接編集しない）。`<plugin-name>@<marketplace-id>` の形式で、値は boolean または version constraint。

現在有効:

- swift-lsp — Swift 用 LSP プラグイン。`/usr/bin/sourcekit-lsp`（Xcode CLT 同梱）を Claude Code に配線し、Brooklyn 等の Swift プロジェクトで go-to-definition / references / diagnostics を有効化する。
- typescript-lsp — TypeScript / JavaScript 用 LSP プラグイン。`typescript-language-server` バイナリ（`scripts/toolchains/node.sh` で npm global インストール）を Claude Code に配線し、`.ts/.tsx/.js/.jsx/.mts/.cts/.mjs/.cjs` で go-to-definition / references / diagnostics を有効化する。
- sentry-mcp — Sentry 公式の MCP プラグイン。Claude Code から Sentry の issue・エラーイベントを参照できる。取得元は下の extraKnownMarketplaces で解決する。
- codex — OpenAI 公式の Codex プラグイン。/codex:* スキルでレビュー・診断・タスク委譲を Codex に投げられる。取得元は下の extraKnownMarketplaces で解決する。
- frontend-design — Anthropic 公式のフロントエンドデザインプラグイン。新規 UI 構築時にテンプレ的でない見た目を作るための指針スキルを提供する。
- security-guidance — Anthropic 公式のセキュリティレビュープラグイン。Claude が書いたコードを 3 層でレビューし、指摘をそのセッション内で修正させる。呼び出すコマンドはなく、有効化するだけで自動で走る。

security-guidance の 3 層は、それぞれ深さとコストが違う（[公式ドキュメント](https://code.claude.com/docs/en/security-guidance)）。

| 層 | 発火 | 内容 | 無効化 |
| :--- | :--- | :--- | :--- |
| per-edit | Edit / Write / NotebookEdit の直後 | `eval(` / `pickle` / `dangerouslySetInnerHTML` / `.github/workflows/` 配下の編集などを文字列マッチ。モデル呼び出しなしで追加コストゼロ | `ENABLE_PATTERN_RULES=0` |
| end-of-turn | Stop | そのターンの working tree の diff を別 Claude に投げ、認可バイパス・injection・SSRF・弱い暗号などをレビュー。バックグラウンド実行で応答は遅延しない | `ENABLE_STOP_REVIEW=0` |
| commit / push | Claude が Bash tool で `git commit` / `git push` した直後 | 呼び出し元やサニタイザまで読む agentic レビュー。false positive を抑える | `ENABLE_COMMIT_REVIEW=0` |

運用上の注意:

- model-backed の 2 層（end-of-turn / commit）は通常の Claude リクエストと同じく使用量を消費する。デフォルトは Opus 4.7 で、`SECURITY_REVIEW_MODEL`（end-of-turn）と `SG_AGENTIC_MODEL`（commit）で変更できる。全部止めるなら `ENABLE_CODE_SECURITY_REVIEW=0`、プラグインごと止めるなら `SECURITY_GUIDANCE_DISABLE=1`
- どの層も write や commit をブロックしない。指摘は Claude への指示として渡るだけなので、CI の静的解析や PR の Code Review を置き換えるものではない
- agentic な commit レビューには Python 3.10 以上が要る（プラグインは `python3.13`〜`python3.10` を優先し、無ければ `python3` にフォールバック）。初回起動時に `~/.claude/security/` へ venv を作り Claude Agent SDK を pip install する。Python が 3.10 未満だと commit レビューは single-shot にフォールバックする
- end-of-turn と commit の 2 層は git の状態を diff するため、git リポジトリ外では無言でスキップされる。per-edit はどこでも動く
- 動かないときは `~/.claude/security/log.txt` を見る
- プロジェクト固有のレビュー観点は `.claude/claude-security-guidance.md`、独自の文字列マッチルールは `.claude/security-patterns.yaml` で追加できる（どちらも追加のみで、組み込みルールは消せない）

### extraKnownMarketplaces

```jsonc
"extraKnownMarketplaces": {
  "sentry-mcp": { "source": { "source": "github", "repo": "getsentry/sentry-mcp" } },  // sentry-mcp プラグインの取得元
  "openai-codex": { "source": { "source": "github", "repo": "openai/codex-plugin-cc" } }  // codex プラグインの取得元
}
```

enabledPlugins の `<plugin>@<marketplace>` は marketplace 名の参照だけで、場所の情報を持たない。CLI 登録（`claude plugin marketplace add`）のローカル状態は dotfiles 管理外のため、ここに source を書いて新しいマシンでも解決できるようにする。

参考: https://code.claude.com/docs/en/settings#plugin-settings

### language

```jsonc
"language": "japanese"  // Claude の応答言語・voice dictation 言語を日本語に固定
```

Claude Code の UI（メニュー・プロンプト・ヘルプ）は英語のまま、Claude の応答テキストだけ日本語になる。以前は グローバル `CLAUDE.md` の「日本語で応答する」というプロンプト指示で対応していたが、専用設定キーへ移した。プロンプト指示と違い context を消費せず、他指示との競合で揺れない。`CLAUDE.md` 側は日本語の書き方ルールに専念させる役割分担。

### outputStyle

```jsonc
"outputStyle": "Concise"  // 応答スタイルを Concise に固定
```

組み込みスタイルは `default` / `Concise` / `Proactive` / `Explanatory` / `Learning` の 5 つ。`Concise` は結論から書き、前置きと実況を省くスタイルで、作業の徹底度そのものは変えない。グローバル `CLAUDE.md` のコミュニケーション規約と同じ方向なので、プロンプト指示に頼らず設定側で固定する。セッション内では `/output-style` で切り替えられる。

参考: https://code.claude.com/docs/en/output-styles

### sandbox

```jsonc
"sandbox": {
  "enabled": true,                // サンドボックス有効化（macOS は Seatbelt、Linux は bubblewrap）
  "autoAllowBashIfSandboxed": true, // sandbox 内の bash は許可プロンプトなしで自動実行
  "allowUnsandboxedCommands": true, // sandbox 非対応コマンドは通常の許可フローにフォールバック
  "excludedCommands": ["docker:*", "docker-compose:*", "podman:*", "git:*", "gh:*", "make:*", "mint:*"], // sandbox 外で実行するコマンド（`:*` で全サブコマンドにマッチ。git は lefthook→commitlint の子プロセスが sandbox と競合するため。gh は認証トークン読み取りと API 通信が sandbox と競合するため。make は xcodegen/xcodebuild が /var/folders 等のシステム temp に書き込むため。mint は Swift CLI ツール実行に必要）
  ...
}
```

sandbox は OS カーネルレベルでファイルシステムとネットワークを分離する。LLM の判断に頼る Auto Mode と異なり、物理的にアクセスをブロックするため安全性が高い。Anthropic の社内テストでは許可プロンプトが 84% 削減されたとのこと。

`autoAllowBashIfSandboxed: true` がキーで、sandbox 内で実行可能な bash コマンドは承認なしで自動実行される。これにより `/sandbox` を毎回打つ必要もなくなる。

`--dangerously-skip-permissions` は sandbox の制限をバイパスしない（パーミッションプロンプトをスキップするだけ）。そのため sandbox + skip-permissions は安全な組み合わせとして成立する。ただし通常のインタラクティブ開発では `claude` だけで十分で、skip-permissions は CI/CD やバッチ処理等の完全無人実行時のみ使う想定。

#### sandbox.network

```jsonc
"network": {
  "allowUnixSockets": [
    "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" // 1Password SSH Agent（git push/pull 用）。op CLI 用ソケット（s.sock 等）は意図的に未許可 — prompt injection で op コマンドを悪用されるリスクを防ぐため
  ],
  "allowLocalBinding": true, // dev server のポートバインド許可
  "allowMachLookup": [
    "org.chromium.Chromium.MachPortRendezvousServer.*", // headless Chromium (playwright) の IPC 用 Mach port。設定しないと `bootstrap_check_in ... Permission denied (1100)` で起動失敗
    "com.apple.trustd.agent" // Go 製 CLI (gh/terraform 等) の TLS 証明書検証用。macOS の Go は SecTrustEvaluateWithError 経由で trustd.agent に Mach IPC するため、許可しないと sandbox 内で `x509: OSStatus -26276` で失敗する（先頭 gh は excludedCommands で sandbox 外だが、シェル関数/ループにネストした gh は sandbox 内で落ちる）
  ],
  "allowedDomains": [
    "github.com", "*.github.com", "github.blog",
    "*.npmjs.org", "*.npmjs.com", "registry.yarnpkg.com",
    "pypi.org", "files.pythonhosted.org",
    "crates.io", "*.crates.io",
    "deno.land",
    "cdn.jsdelivr.net", "unpkg.com", "esm.sh",
    "api.anthropic.com",
    "context7.com", "*.context7.com", // find-docs skill の ctx7 CLI が叩くドキュメント検索 API
    "cdn.playwright.dev", "playwright.download.prss.microsoft.com", // playwright install chromium が Microsoft の CDN から Chromium バイナリを取得する
    "*.cloudflare.com" // weekly-cloudflare-news routine が blog.cloudflare.com / developers.cloudflare.com の RSS・changelog を取得
  ]
}
```

すべてのネットワークトラフィックはプロキシ経由で、許可されたドメインのみ通信可能。クラウド実行と同等のネットワーク分離をローカルで再現している。新しいドメインが必要になったら初回だけ承認プロンプトが出て、以降は記憶される。

ドメイン追加時は可能な限りワイルドカード（`*.example.com`）で正規化する。同一ドメインのサブドメインが複数必要になった場合、個別に列挙せずワイルドカードで統合すること。

#### sandbox.filesystem

```jsonc
"filesystem": {
  "denyRead": [
    "~/.ssh",              // SSH 鍵
    "~/.aws/credentials",  // AWS クレデンシャル
    "~/.gnupg",            // GPG 鍵
    "~/.netrc",            // 認証情報
    "~/.config/op"         // 1Password CLI 設定（デバイスID、アカウント情報）
  ],
  "allowWrite": ["/tmp", "~/.npm", "~/Library/pnpm/store"]
}
```

sandbox のデフォルトではカレントディレクトリとサブディレクトリのみ書き込み可能で、読み取りはシステム全体。ここでは読み取りすら不要な機密ファイルを明示的にブロックしている。sandbox のバイパス事例（パストリックによる脱出等）も報告されているため、二重防御として設定。

`~/.config/gh/hosts.yml` は denyRead に置いていない。gh のトークンは macOS Keychain (keyring) に保存され、hosts.yml には `git_protocol` と user 名しか入らないため機密がない。加えて `gh`・`git` は excludedCommands で sandbox 外で動くため、sandbox 内から hosts.yml を読めても GitHub 操作の認証には影響しない。sandbox 内のコマンドが GitHub 操作で hosts.yml を参照しても止まらないよう、読み取りを許可している。

### spinnerTipsEnabled

```jsonc
"spinnerTipsEnabled": false  // スピナー中の Tip メッセージを非表示
```

### alwaysThinkingEnabled

```jsonc
"alwaysThinkingEnabled": true  // Extended thinking を全セッションでデフォルト有効
```

`alwaysThinkingEnabled` は思考トークン（アウトプットトークンとして課金）が追加されるため、単純なタスクには過剰な場合もある。セッション内で `Option+T` や `/effort` でいつでも調整可能。

### tui

```jsonc
"tui": "fullscreen"  // フルスクリーン (alt screen) レンダラをデフォルトに
```

Claude Code 2.1.110 で追加された TUI レンダラの選択。`"default"` は通常の inline レンダリング、`"fullscreen"` は alt screen バッファを使ったちらつきの少ない描画。`fullscreen` モードでのみ `/focus` が有効になる。セッション内では `/tui default` / `/tui fullscreen` で切り替え可能。

旧来の `CLAUDE_CODE_NO_FLICKER=1` 環境変数の置き換え。`/tui` 実行時に `CLAUDE_CODE_NO_FLICKER` は明示的に unset されるため、env var は将来的に廃止される見込み。settings の `tui` キーが env var より優先される。

### autoMemoryEnabled

```jsonc
"autoMemoryEnabled": false  // auto memory を無効化（デフォルトは true）
```

auto memory は `~/.claude/projects/<project>/memory/` に保存されるためマシン間で共有されず、内容も CLAUDE.md や /doc スキルの保存先と重複する。記録は /doc スキルの判定フローで CLAUDE.md / issue / brain に振り分ける。

### skipWorkflowUsageWarning

```jsonc
"skipWorkflowUsageWarning": true  // Workflow 起動時の使用量警告をスキップ
```

Workflow tool（複数サブエージェントを並列起動するオーケストレーション）を起動すると、「1 回の実行で多数のエージェントが走り使用量を大きく消費する」旨の警告が出る。`true` でこの警告を毎回スキップする。

公式ドキュメントには未記載だが Claude Code 本体が読み取る設定キー。Workflow 自体を無効化する `disableWorkflows`、`workflow` というキーワードでの自動起動を制御する `workflowKeywordTriggerEnabled`（2.1.157 で追加）とは別物で、こちらは Workflow を使う前提で警告だけ消す。挙動が変わったら見直す。

### remoteControlAtStartup

```jsonc
"remoteControlAtStartup": true  // 起動時に Remote Control を自動で有効化
```

Claude Code 2.1.51 で追加。通常は毎セッション `/remote-control` を実行して Remote Control（claude.ai/code の Web UI や Claude モバイルアプリから、手元の Claude Code セッションを遠隔操作する機能）を有効化する必要があるが、この設定を `true` にすると新規インタラクティブセッションで自動的に有効化される。セッション URL / QR コードも自動生成され、別デバイスからすぐ接続できる。

デフォルトは `false`。sandbox と auto mode を常時有効にしている運用と組み合わせて、「Mac で長時間タスクを投げて外出先のスマホから様子を見る」用途を想定。

参考: https://docs.anthropic.com/en/docs/claude-code/remote-control

### skipAutoPermissionPrompt

```jsonc
"skipAutoPermissionPrompt": true  // auto mode 開始時の確認プロンプトをスキップ
```

`defaultMode: "auto"` でセッションを開始したときに表示される「Auto mode を有効にしますか？」の確認プロンプトをスキップする。sandbox を常時有効にしている前提で、auto mode を毎回無言で起動したいための設定。

`permissions.skipDangerousModePermissionPrompt`（bypass permissions 用）と対になる auto mode 版。公式ドキュメントでは明示的に記載されていないが Claude Code 本体が読み取る設定キーとして実装されている。将来挙動が変わる可能性があるため、新しいセッションで確認プロンプトが戻ったらこの記述を見直す。

## 使い方

```bash
# 通常の開発（これだけでほぼ止まらず動く）
claude

# 完全無人実行（CI/CD・バッチ処理用。sandbox が効いているので安全）
claude -p --dangerously-skip-permissions "全テストを実行して失敗を修正して"
```

## 注意事項

- `settings.json` は Claude Code がセッション中に自動書き換えすることがある（パーミッション承認の蓄積等）。JSON 再シリアライズ時にコメントは消えるため、設定の意図はこのファイルに記録している
- `/plugin install` / `/plugin enable` は settings.json 全体を内部 Zod スキーマ順に re-serialize する（[anthropics/claude-code#15339](https://github.com/anthropics/claude-code/issues/15339)）。本ドキュメントのセクション順はその schema 順と一致させている。手動で並び替えても次のプラグイン操作で schema 順に戻るため、schema 順を canonical として受け入れている
- sandbox のバイパス事例（パストリック、sandbox 自体の無効化）が報告されているため、Git ブランチを切ってから作業させる・機密ファイルはプロジェクトディレクトリに置かない等の運用上の工夫も併用すること
- クラウド実行（Web）はネイティブでは `~/.claude/settings.json` を読まず、リポジトリ内の `.claude/settings.json` と `CLAUDE.md` のみを反映する。ただし本リポジトリでは Claude Code on the web の **Setup script** から `home/.claude/settings.json` を `~/.claude/` 配下に取り込んでいるため、クラウド実行でもこのファイルが有効になる。新しい許可ドメイン等を追加するときはこのファイル1箇所を編集すればローカル CLI とクラウド実行の両方に反映される
