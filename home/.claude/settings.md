# ~/.claude/settings.json リファレンス

最終更新: 2026-04-03

## 背景

Claude Code にはローカル実行（CLI）とクラウド実行（Web）の2つの実行環境がある。

クラウド実行は Anthropic のサンドボックス内で `--dangerously-skip-permissions` 相当の自律実行ができるが、`~/.claude/settings.json` や MCP サーバー等のローカル設定が読まれない。ローカル実行はその逆で、設定の自由度は高いが、デフォルトでは毎回パーミッション確認が入り作業が止まる。

この設定は「クラウド実行の自律性 + ローカルの設定資産」のいいとこ取りを目指したもの。sandbox による OS レベルの分離を有効にすることで、`--dangerously-skip-permissions` なしでもほぼ止まらずに動く環境を実現している。

## 設定の全体構成

### sandbox

```jsonc
"sandbox": {
  "enabled": true,                // サンドボックス有効化（macOS は Seatbelt、Linux は bubblewrap）
  "autoAllowBashIfSandboxed": true, // sandbox 内の bash は許可プロンプトなしで自動実行
  "allowUnsandboxedCommands": true, // sandbox 非対応コマンドは通常の許可フローにフォールバック
  "excludedCommands": ["docker:*", "docker-compose:*", "podman:*", "git:*", "gh:*"], // sandbox 外で実行するコマンド（`:*` で全サブコマンドにマッチ。git は lefthook→commitlint の子プロセスが sandbox と競合するため。gh は認証トークン読み取りと API 通信が sandbox と競合するため）
  ...
}
```

sandbox は OS カーネルレベルでファイルシステムとネットワークを分離する。LLM の判断に頼る Auto Mode と異なり、物理的にアクセスをブロックするため安全性が高い。Anthropic の社内テストでは許可プロンプトが 84% 削減されたとのこと。

`autoAllowBashIfSandboxed: true` がキーで、sandbox 内で実行可能な bash コマンドは承認なしで自動実行される。これにより `/sandbox` を毎回打つ必要もなくなる。

`--dangerously-skip-permissions` は sandbox の制限をバイパスしない（パーミッションプロンプトをスキップするだけ）。そのため sandbox + skip-permissions は安全な組み合わせとして成立する。ただし通常のインタラクティブ開発では `claude` だけで十分で、skip-permissions は CI/CD やバッチ処理等の完全無人実行時のみ使う想定。

### sandbox.filesystem

```jsonc
"filesystem": {
  "denyRead": [
    "~/.ssh",              // SSH 鍵
    "~/.aws/credentials",  // AWS クレデンシャル
    "~/.gnupg",            // GPG 鍵
    "~/.config/gh/hosts.yml", // GitHub CLI トークン
    "~/.netrc",            // 認証情報
    "~/.config/op"         // 1Password CLI 設定（デバイスID、アカウント情報）
  ],
  "allowWrite": ["/tmp", "~/.npm", "~/Library/pnpm/store"]
}
```

sandbox のデフォルトではカレントディレクトリとサブディレクトリのみ書き込み可能で、読み取りはシステム全体。ここでは読み取りすら不要な機密ファイルを明示的にブロックしている。sandbox のバイパス事例（パストリックによる脱出等）も報告されているため、二重防御として設定。

### sandbox.network

```jsonc
"network": {
  "allowLocalBinding": true, // dev server のポートバインド許可
  "allowUnixSockets": [
    "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock", // 1Password SSH Agent（git push/pull 用）。op CLI 用ソケット（s.sock 等）は意図的に未許可 — prompt injection で op コマンドを悪用されるリスクを防ぐため
    "~/Library/Application Support/cmux/cmux.sock"  // cmux IPC（ペイン間通信）
  ],
  "allowedDomains": [
    "github.com", "*.github.com",
    "*.npmjs.org", "*.npmjs.com", "registry.yarnpkg.com",
    "pypi.org", "files.pythonhosted.org",
    "crates.io", "*.crates.io",
    "deno.land",
    "cdn.jsdelivr.net", "unpkg.com", "esm.sh",
    "api.anthropic.com"
  ]
}
```

すべてのネットワークトラフィックはプロキシ経由で、許可されたドメインのみ通信可能。クラウド実行と同等のネットワーク分離をローカルで再現している。新しいドメインが必要になったら初回だけ承認プロンプトが出て、以降は記憶される。

ドメイン追加時は可能な限りワイルドカード（`*.example.com`）で正規化する。同一ドメインのサブドメインが複数必要になった場合、個別に列挙せずワイルドカードで統合すること。

### permissions.defaultMode

```jsonc
"defaultMode": "plan"
```

Plan Mode をデフォルトに設定。セッション開始時は読み取り専用で議論・計画に集中し、実装準備ができたら `shift+tab` で実行モードに切り替える。議論→仕様固め→実装のワークフローに最適化。

### permissions.allow

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

### permissions.deny

```jsonc
"deny": [
  // --- .env 保護（元の設定から保持） ---
  "Read(**/.env)", "Read(**/.env.*)",
  "Edit(**/.env)", "Edit(**/.env.*)",
  "Bash(*.env*)",

  // --- git force push 制御 ---
  "Bash(git push --force:*)",  // 危険：リモート履歴を破壊
  "Bash(git push -f:*)",       // --force の短縮形

  // --- GitHub PR マージ保護（元の設定から保持） ---
  "Bash(gh pr merge:*)",
  "Bash(gh api repos/*/pulls/*/merge*)",

  // --- 危険コマンド ---
  "Bash(sudo:*)", "Bash(su:*)",
  "Bash(rm -rf /)", "Bash(rm -rf ~)",
  "Bash(shutdown:*)", "Bash(reboot:*)",
  "Bash(launchctl:*)", "Bash(diskutil:*)",

  // --- 1Password CLI 保護（prompt injection 対策） ---
  "Bash(op:*)", "Bash(op :*)",   // op CLI の直接実行をブロック

  // --- DNS exfiltration 対策（CVE-2025-55284 系） ---
  "Bash(dig:*)",                  // DNS クエリのサブドメインにシークレットを埋め込む攻撃を防止
  "Bash(nslookup:*)",
  "Bash(host:*)"
]
```

deny ルールの評価順序: deny → ask → allow で、最初にマッチしたルールが勝つ。そのため `Bash(git:*)` で git 全般を allow しつつ、`Bash(git push --force:*)` で force push だけ deny できる。`--force-with-lease` は allow に明示的に入れているため通る。

### env

```jsonc
"env": {
  "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"  // テレメトリ・エラーログ・フィードバックサーベイを一括無効化
}
```

Statsig（使用メトリクス）、Sentry（エラーログ）、セッション品質サーベイをすべてオフにする。個別に制御したい場合は `DISABLE_TELEMETRY`、`DISABLE_ERROR_REPORTING`、`CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` をそれぞれ設定可能。

### hooks

```jsonc
"hooks": {
  "SessionStart": [
    {
      "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/check-local-settings.sh" }]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "echo '{\"hookSpecificOutput\":{...\"additionalContext\":\"'$(date '+%Y-%m-%d %H:%M:%S %Z')'\"}}'",
          "timeout": 5
        }
      ]
    }
  ]
}
```

- **SessionStart**: セッション開始時に `check-local-settings.sh` を実行。settings.local.json にルールが溜まっていないかチェックする
- **PreToolUse** (`matcher: "Bash"`): `block-op-cli.sh` で Bash コマンド文字列内の `op` CLI パターンを検出・ブロック。deny リストでは防げない間接実行（`bash -c "op ..."`, `sh -c "op ..."` 等）への二重防御。CVE-2025-55284 等の prompt injection 攻撃対策
- **PreToolUse** (`matcher: "*"`): 全ツール実行前に `date` の出力を `hookSpecificOutput.additionalContext` 経由で Claude のコンテキストに注入。ロングバッチ時に Claude が時間感覚を持てるようにする
- hook で判断制御（allow/deny）を返す場合、旧フィールド `decision`/`reason` は **deprecated**。`hookSpecificOutput.permissionDecision` / `hookSpecificOutput.permissionDecisionReason` を使うこと

### その他

```jsonc
"enabledPlugins": {}  // プラグインなし
"attribution": { "pr": "", "commit": "" } // PR・コミットの Claude Code フッター非表示
"alwaysThinkingEnabled": true         // Extended thinking を全セッションでデフォルト有効
"cleanupPeriodDays": 90               // セッション履歴を 90 日保持（デフォルトは 30 日）
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }  // cmux surface ref をステータスラインに表示
```

`alwaysThinkingEnabled` は思考トークン（アウトプットトークンとして課金）が追加されるため、単純なタスクには過剰な場合もある。セッション内で `Option+T` や `/effort` でいつでも調整可能。

## 使い方

```bash
# 通常の開発（これだけでほぼ止まらず動く）
claude

# 完全無人実行（CI/CD・バッチ処理用。sandbox が効いているので安全）
claude -p --dangerously-skip-permissions "全テストを実行して失敗を修正して"
```

## 注意事項

- `settings.json` は Claude Code がセッション中に自動書き換えすることがある（パーミッション承認の蓄積等）。JSON 再シリアライズ時にコメントは消えるため、設定の意図はこのファイルに記録している
- sandbox のバイパス事例（パストリック、sandbox 自体の無効化）が報告されているため、Git ブランチを切ってから作業させる・機密ファイルはプロジェクトディレクトリに置かない等の運用上の工夫も併用すること
- クラウド実行（Web）では `~/.claude/settings.json` は読まれない。リポジトリ内の `.claude/settings.json` と `CLAUDE.md` のみが反映される
