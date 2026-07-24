---
name: new-repo
description: >-
  新しいリポジトリを作るフローの正本。
  Claude Code で /new-repo、Codex で $new-repo と入力したとき、
  または「新しいリポジトリを作りたい」「リポジトリを切り出したい」と言ったとき、
  または nozomiishii 配下に新しいリポジトリを作る作業を始める前に使用する。
---

# /new-repo

リポジトリの作成・設定・保護の正本は nozomiishii/infra の `stacks/github/main.tf`。GitHub を直接操作して作らない。設計の経緯は [dotfiles#1393](https://github.com/nozomiishii/dotfiles/issues/1393)。

## 禁止

- `gh repo create`、`gh repo edit`、ruleset API による作成・設定変更。既存 repo の設定を `gh repo view` や API で観察して手動複製するのも同じ扱い。
  - 「既存 repo と同じ設定を gh で再現すれば結果は同じ」→ 同じに見えるだけで tfstate と HCL に存在しない。以後の plan に現れず、管理から外れ続ける。
  - 「ruleset を最後に付ければ main への初回 push が通る」→ 順序の工夫は不要。`auto_init = true` が作成時に initial commit を作るので、main は最初から存在し保護も同時に付く。

## リポジトリ作成 (infra)

- `stacks/github/main.tf` の `locals.repositories` にエントリを追加して PR を作る。visibility と description をここで決める。visibility はユーザーに確認する。公開なら GitHub Actions が無料になる。
- plan / apply は infra の AGENTS.md の実行境界に従う。apply はユーザーが行う。
- initial commit は auto_init が作る。メッセージは "Initial commit" 固定で Conventional Commits 外だが、release-please は非準拠コミットを無視するため実害はない。気になる場合は release-please の `bootstrap-sha` で収集範囲から外せる。
- repo 固有の CI を必須チェックにする場合、workflow に集約 `required` job を作り、infra 側の `required_status_checks` に `<workflow> / required` で登録する。正本は infra の docs/required_status_checksの命名と最小構成.md。共通の必須チェック 3 つと GitGuardian はモジュールが自動で付ける。

## 足場 (最初の PR)

clone して次を揃え、1 つの PR にする。完成形の実例は nozomiishii/design#1。

- configs 一式: `@nozomiishii/commitlint-config` `eslint-config` `lefthook-config` `postinstall` `prettier-config` `tsconfig` と各設定ファイル。`cspell-config` と `markdownlint-cli2-config` は非推奨のため導入しない。
- 標準 workflow: `_pull-request.yaml` `_github-actions.yaml` `_secret-scan.yaml` を configs からコピーする。main の必須チェックが要求するため、無いと PR をマージできない。
- `.github/renovate.json`: `{ "extends": ["github>nozomiishii/renovate"] }`
- SessionStart hook: `.claude/settings.json` と `.hooks/setup.sh` (`pnpm install`)。
- README.md と README.ja.md を同じ構成で作る。

## 登録 (workspaces)

- nozomiishii/workspaces の `projects.json` にエントリを追加する PR を作る。別 repo の変更なので /wt の切り出しに従う。

## リリースフロー

- npm 配布するリポジトリは configs と同型の release-please 構成 (`.github/.release-please-config.json` + release.yaml) を後続 PR で入れる。
