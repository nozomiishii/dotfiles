---
name: new-repo
description: >-
  新しいリポジトリを作るフローの正本。
  「新しいリポジトリを作りたい」「リポジトリを切り出したい」と言ったとき、
  または nozomiishii 配下に新しいリポジトリを作る作業を始める前に使用する。
---

# /new-repo

リポジトリの作成・設定・保護の正本は nozomiishii/infra の `iac/stacks/github/main.tf`。GitHub を直接操作して作らない。

## 禁止

- `gh repo create`、`gh repo edit`、ruleset API による作成・設定変更。既存 repo の設定を `gh repo view` や API で観察して手動複製するのも同じ扱い。
  - 「既存 repo と同じ設定を gh で再現すれば結果は同じ」→ 同じに見えるだけで tfstate と HCL に存在しない。以後の plan に現れず、管理から外れ続ける。

## サインインの選定・設定

- Google / Apple サインインを検討する場合、必要な情報を一度に 1 つずつインタビューし、採用する方式と設定内容をユーザーと決める。
- 管理画面の設定は、ユーザーが見えるブラウザでエージェントが行う。本人の操作が必要なところだけユーザーへ渡す。
- 資格情報を安全に保存し、アプリでサインインできる状態まで確認する。

## リポジトリ作成 (infra)

- `iac/stacks/github/main.tf` の `locals.repositories` にエントリを追加して PR を作る。visibility と description をここで決める。visibility はユーザーに確認する。公開なら GitHub Actions が無料になる。
- plan / apply は infra の AGENTS.md の実行境界に従う。apply はユーザーが行う。
- `auto_init = false` で作り、GitHub の README と `Initial commit` を生成しない。手元のコミット履歴を取り込み、main 保護まで適用して完了とする。認証と作成の順序は [infra の運用](https://github.com/nozomiishii/infra/blob/main/docs/運用.md#新しい-repo-を追加する)に従う。
- repo 固有の CI を必須チェックにする場合、workflow に集約 `required` job を作り、infra 側の `required_status_checks` に `<workflow> / required` で登録する。正本は infra の docs/required_status_checksの命名と最小構成.md。共通チェックの `recommended / required` は infra が付ける。
- private repo の CI は自宅 Mac mini の self-hosted runner で動く。runner に拾わせる次の手作業をユーザーに伝える。正本は infra の [runner の運用](https://github.com/nozomiishii/infra/blob/main/docs/github-runner.md#repo-を足す外す)。
  - repo の作成後、runner の fine-grained PAT の Repository access に追加する
  - infra の PR の merge 後、Mac mini で `mise run github-runner-update` を実行する

## 初期セットアップ

初回に取り込むコミットには次を揃える。初回取り込み後の変更は PR にする。

- configs 一式: `@nozomiishii/commitlint-config` `eslint-config` `lefthook-config` `oxfmt-config` `postinstall` `tsconfig` と各設定ファイル。`cspell-config` と `markdownlint-cli2-config` は非推奨のため導入しない。
- 標準 workflow: `_recommended.yaml` を configs からコピーする。実体は [nozomiishii/workflows](https://github.com/nozomiishii/workflows) の reusable workflow を SHA pin で呼ぶ薄い caller。main の必須チェックが要求するため、無いと PR をマージできない。
  - private では無料枠に収めるため、`_recommended.yaml` から `with: runs-on: self-hosted` を渡す。repo 固有の workflow も `runs-on: self-hosted` にする。
- `.github/renovate.json`: `{ "extends": ["github>nozomiishii/renovate"] }`
- SessionStart hook: Claude Code 用の `.claude/settings.json` と Codex 用の `.codex/hooks.json` から `.hooks/setup.sh` を呼ぶ。3 つとも [dotfiles](https://github.com/nozomiishii/dotfiles) の同じパスのファイルを写す。
- README.md と README.ja.md を同じ構成で作る。

## 登録 (infra)

- ローカル登録も infra が正本。infra の `iac/stacks/github/main.tf` の `locals.repositories` と、infra 直下の `projects.json` を、リポジトリ作成と同じ 1 つの PR で両方更新する。新しく作る repo 側には `projects.json` を置かない。

## リリースフロー

- npm 配布するリポジトリは configs と同型の release-please 構成 (`.github/.release-please-config.json` + release.yaml) を後続 PR で入れる。

## スタイリング

- Tailwind CSS を使う repo では、props で見た目を切り替えるコンポーネントを [tailwind-variants](https://www.tailwind-variants.org/) で書く。tailwind-variants は必要になるまで入れない。

## 経緯

設計判断を調べるときだけ参照する。設計の判断は [ADR](https://github.com/nozomiishii/dotfiles/blob/main/docs/decisions/新しいリポジトリ作成のフローは%20new-repo%20スキルを正本にする.md)、テスト記録は [dotfiles#1393](https://github.com/nozomiishii/dotfiles/issues/1393)。
