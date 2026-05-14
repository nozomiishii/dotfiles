# グローバル指示

## 言語

- 日本語で応答する。コード・コマンド・技術用語はそのまま使用してよい。

## パーミッション・sandbox

- コマンド実行の許可を確認する時は、Bash ツールの `description` に「何をするコマンドか」と「なぜこの実行が必要か」を日本語で簡潔に記述すること。例: 「PR を作成（GitHub API へのネットワークアクセスのため sandbox 外）」
- sandbox 外でコマンドを実行する場合は、`description` になぜ sandbox 外になるのか理由を含めること。sandbox エラーが発生しても、勝手に sandbox 外で再実行しない。
- 新しいネットワークドメインの許可を確認する時は、なぜそのドメインが必要なのか説明すること。
- sandbox エラーが発生した場合は、原因と回避策を説明してからリトライすること。

## ファイル編集

- Edit / Write を呼ぶ前に、対象ファイルを必ず Read で読んでおくこと。Read していないファイルへの Edit / Write は「File must be read first」エラーで失敗し、作業が中断する。
- 既に編集済みのファイルでも、長い作業で context が圧縮された後に再編集する場合や、sub-agent から親が作ったファイルを編集する場合は、改めて Read してから Edit を呼ぶこと。
- もし「File must be read first」エラーが出たら、すぐに対象ファイルを Read してから Edit / Write を再試行すること。エラーをそのまま受け流して別の方向に進まない。

## Git

- git 操作の前にブランチを確認し、main への直接コミットを避けること。
- `cd <path> && git` の複合コマンドは使わず、`git -C <path>` を使用すること（bare repository attack 防止の sandbox 制約を回避するため）。

## GitHub / PR

- **PR タイトル**: Conventional Commits 形式（英語）で `<type>: <subject>` と書く。許可 type は `feat` / `fix` / `chore`（リポジトリで追加されている場合はそれに従う）。**scope は付けない**（`feat(api): ...` ではなく `feat: ...`）。caller 側で nozomiishii/workflows の `pull-request.yaml` に `scopes` input を渡している repo に限り scope 可（その場合は input で許可された scope のみ）。subject は小文字始まり / ASCII のみ / 末尾スペース禁止。これは nozomiishii/workflows の semantic pull request チェック（amannn/action-semantic-pull-request）と同じ規則で、違反すると CI が落ちる。
- **PR 本文**: プルリクエストの本文（body）は日本語で記述する。
- **PR マージ**: マージは必ずユーザーが手動で行う。AI が `gh pr merge` や GitHub API 経由でマージを実行してはならない。
- **PR 作成・更新・push**: これらは AI が実行してよい。マージの最終判断のみ常にユーザーに委ねる。
- **PR 作成時**: `gh pr create` は `--body-file` を使う。HEREDOC で `--body` に直接渡すと、Markdown の `#` 見出しが command injection 検出に引っかかり毎回承認ダイアログが出る。

例:

```sh
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
## Summary
...
EOF
gh pr create --title "..." --body-file "$BODY_FILE"
```

## GitHub Issue 検索

- Closed as duplicate の Issue は結果に含めない。duplicate chain を辿って、現在 Open の canonical issue を返すこと。
- 「subscribe / watch する価値があるか」を user に提案する場合、以下を必ず**実物で確認**してから引用すること:
  - `state: OPEN` (CLOSED は提案しない)
  - `stateReason` が `DUPLICATE` でない (canonical issue を辿る、`gh issue view <n> --json comments -q '.comments[].body'` で "duplicate of #..." を探す)
  - 直近 3 ヶ月以内に update / コメントがある (= 活発に議論中)
  - thumbsup や comment 数で community traction を示す
- 推測や sub-agent / WebSearch の output を鵜呑みにせず、**必ず `gh issue view <number>` で state / updatedAt / stateReason / comments を実物確認する**。一度ダメ出しされた経験あり (2026-05-14: closed 済みや duplicate 済みの issue を「open で active」と紹介してしまった)。
- 引用 / リストアップ時は state と直近 update 日付を併記すると user の検証コストが下がる。リンク化ルール (下記コミュニケーション section 参照) も守る:

```markdown
- [#32018](https://github.com/anthropics/claude-code/issues/32018) [BUG] Archived Code session cannot be unarchived (OPEN, 7👍, last update 2026-05-08)
```

## 設計・spec の管理

- 設計ドキュメント・spec・brainstorming の成果は **GitHub issue にまとめる**。`docs/superpowers/specs/` や `docs/` 配下のファイルとして残さない。
- 理由: 変更行 → `git blame` → PR → linked issue で「なぜこの変更が入ったか」を**逆検索**できる導線を作るため。ファイルで残すとコードの変更行から逆引きする経路が存在しない。
- skill（superpowers/brainstorming, writing-plans, executing-plans 等）が「`docs/superpowers/specs/YYYY-MM-DD-*-design.md` に保存しろ」と指示してきても、それを上書きで **GitHub issue 作成 or 既存 issue 更新**に置き換えること。skill のデフォルトファイルパスは採用しない。
- 既存の関連 issue があれば update（コメント追加 or 本文編集）。なければ新規作成。
- issue タイトルは PR と同じ Conventional Commits 形式（英語）で `<type>: <subject>`。本文は日本語。
- 大型 spec は issue 1 本にまとめ、Phase 分割や検討経緯は section（`## Phase 1` 等）やコメントで構造化する。
- 関連 PR は必ず `closes #N` / `refs #N` で対応 issue を紐付け、逆検索チェーンを成立させる。

## コミュニケーション

- すぐに結論や解決策を出さず、ユーザーと議論しながら段階的に進めること。質問を投げかけたり仮説を共有しながら、一緒に考える姿勢で。
- 「進めましょうか？」「この構成で大丈夫ですか？」のような確認はしない。構成の確定、実装への移行はユーザーが決める。
- Plan mode では、ユーザーが明示的に指示するまでプラン作成や ExitPlanMode を行わない。
- 返答で GitHub の Issue や PR に言及する時は、必ず markdown リンクにする。`Issue #2118` ではなく `[Issue #2118](https://github.com/owner/repo/issues/2118)` のように書き、複数言及する場合はすべてリンクにする。リポジトリが文脈から自明な場合は `#2118` のような短縮表記でよいが、リンク自体は省略しない。

## 横断作業

- 複数プロジェクトにまたがる変更は workspaces リポジトリで行う。

## 設定管理

- ~/.claude/settings.json を変更した場合は、必ず ~/.claude/settings.md も同期して更新すること。
- sandbox の allowedDomains にドメインを追加する際は、可能な限りワイルドカード（`*.example.com`）で正規化すること。個別サブドメインが1つだけの場合はそのままでよい。
- パーミッションの追加・変更は必ず `~/.claude/settings.json`（グローバル設定）に行うこと。プロジェクトの `settings.local.json` には追加しない。`settings.local.json` にルールが溜まっていた場合は、ユーザーにグローバルへの移行を提案すること。

## pnpm allowBuilds コメント

`pnpm-workspace.yaml` の `allowBuilds` 各エントリには、build を許可/拒否する判断根拠が分かるコメントを必ず付けること。フォーマット:

```yaml
<package>: <bool> # <chain> | <用途>
```

- `<chain>`: package.json に書かれた依存（左端）から `<package>` 自身（右端）までの**全経路**を ` → ` で連結する。直接依存はパッケージ名 1 つ（長さ 1）。中間パッケージや「経由」「直接」などの語は省く。経路は `pnpm why <package>` で確認する。
- `<用途>`: そのパッケージの役割と、build が必要（true）/不要（false）な理由を簡潔に書く。fallback で動作する場合などは理由まで含める。
- 直接依存と推移依存をコメントや見出しで区別しない（`<chain>` の長さで一意に判別できるため）。

例:

```yaml
allowBuilds:
  lefthook: false # lefthook | フック登録は @nozomiishii/postinstall 経由で行うため不要
  core-js-pure: true # renovate → @qnighy/marshal → @babel/runtime-corejs3 → core-js-pure | polyfill
  dtrace-provider: false # renovate → bunyan → dtrace-provider | macOS/Solaris の DTrace 連携用 optional 機能。失敗時は no-op fallback で動作するため build 不要
```
