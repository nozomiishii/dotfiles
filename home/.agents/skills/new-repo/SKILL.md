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
- Better Auth の secret の値をユーザーに作ってもらうときは、[Better Auth の CLI の Secret](https://better-auth.com/docs/concepts/cli#secret) を作り方として添える。

## リポジトリ作成 (infra)

完了は、新しい repo が infra の `iac/stacks/github/main.tf` の `locals.repositories` の定義どおり GitHub に作られ、手元のコミット履歴と main 保護が反映された状態。

- infra への変更は PR で入れる。visibility と description はこの PR で決める。visibility はユーザーに確認する。公開なら GitHub Actions が無料になる。
- plan / apply は infra の AGENTS.md の実行境界に従う。apply はユーザーが行う。
- `auto_init` は false にし、GitHub の README と `Initial commit` を生成させない。認証と作成の順序は [infra の運用](https://github.com/nozomiishii/infra/blob/main/docs/運用.md#新しい-repo-を追加する)に従う。
- repo 固有の CI を必須チェックにするときは、workflow に集約 `required` job を持たせ、infra の `required_status_checks` に `<workflow> / required` の名前で登録された状態にする。正本は infra の docs/required_status_checksの命名と最小構成.md。共通チェックの `recommended / required` は infra が付ける。
- private repo の CI は自宅 Mac mini の self-hosted runner で動く。runner が新しい repo の job を拾うには、ユーザーの手作業が要る。次の条件を[runner の運用](https://github.com/nozomiishii/infra/blob/main/docs/github-runner.md#repo-を足す外す)と一緒にユーザーに伝える。
  - 作成された repo が、runner の fine-grained PAT の Repository access に含まれている
  - infra の PR の merge 後、Mac mini に新しい repo 用の runner が登録されている

## 初期セットアップ

初回に取り込むコミットには次を揃える。初回取り込み後の変更は PR にする。

- configs 一式: `@nozomiishii/commitlint-config` `eslint-config` `lefthook-config` `oxfmt-config` `postinstall` `tsconfig` と各設定ファイル。`cspell-config` と `markdownlint-cli2-config` は非推奨のため導入しない。
- 標準 workflow: configs と同じ `_recommended.yaml`。実体は [nozomiishii/workflows](https://github.com/nozomiishii/workflows) の reusable workflow を SHA pin で呼ぶ薄い caller。main の必須チェックが要求するため、無いと PR をマージできない。
  - private では無料枠に収めるため、`_recommended.yaml` は `with: runs-on: self-hosted` を渡す。repo 固有の workflow も `runs-on: self-hosted` にする。
- `.github/renovate.json`: `{ "extends": ["github>nozomiishii/renovate"] }`
- SessionStart hook: Claude Code 用の `.claude/settings.json` と Codex 用の `.codex/hooks.json` が `.hooks/setup.sh` を呼ぶ。3 つとも [dotfiles](https://github.com/nozomiishii/dotfiles) の同じパスのファイルと同じ内容にする。
- README.md と README.ja.md。2 つは同じ構成にする。

## 登録 (infra)

- ローカル登録も infra が正本。infra 直下の `projects.json` への登録は、`locals.repositories` への定義と同じ 1 つの PR に含める。新しく作る repo 側には `projects.json` を置かない。

## リリースフロー

- npm 配布するリポジトリは configs と同型の release-please 構成 (`.github/.release-please-config.json` + release.yaml) を後続 PR で入れる。

## スタイリング

- CSS でスタイルを当てる repo は、既定で Tailwind CSS を使う。
  - size や color などの見た目を props で切り替えるコンポーネントは [tailwind-variants](https://www.tailwind-variants.org/) で書く。tailwind-variants は初期セットアップでは入れず、該当するコンポーネントを初めて書くときに入れる。

## 経緯

設計判断を調べるときだけ参照する。設計の判断は [ADR](https://github.com/nozomiishii/dotfiles/blob/main/docs/decisions/新しいリポジトリ作成のフローは%20new-repo%20スキルを正本にする.md)、テスト記録は [dotfiles#1393](https://github.com/nozomiishii/dotfiles/issues/1393)。
