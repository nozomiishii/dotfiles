# このdotfilesをforkして使う

このdotfilesは [nozomiishii](https://github.com/nozomiishii) の個人運用に最適化されており、GitHub アカウント名・メール・固定パス・個人 Homebrew tap・scoped npm package などが各所に直書きされている。fork して自分用に使う場合、以下を書き換える。

repo の置き場所自体は配置非依存にしてあるので([#1057](https://github.com/nozomiishii/dotfiles/issues/1057))、任意のディレクトリで動く。書き換えが要るのは「中身の個人前提」のみ。

## 必須（書き換えないと意図通り動かない）

### アカウント

| ファイル | 内容 |
|---|---|
| [`home/.gitconfig`](../home/.gitconfig) | `name`, `email` |

### リポジトリ・bootstrap

| ファイル | 内容 |
|---|---|
| [`install.sh`](../install.sh) | `DOTFILES_REPO` を自分の fork URL に。`DOTFILES_DIR` は env override 可能なので、`DOTFILES_DIR=... curl ... \| bash` で別パスにも置ける |
| [`scripts/clone_github_repos.sh`](../scripts/clone_github_repos.sh) | `make repo` で clone される個人 repo リスト |
| [`.github/CODEOWNERS`](../.github/CODEOWNERS) | `@nozomiishii` |
| [`Brewfile`](../Brewfile) | `tap "nozomiishii/tap"` と `cask "nozomiishii/tap/brooklyn"` の個人 tap / cask |

### npm scoped packages

[lint・format・commit hook の設定を `@nozomiishii/*` 系の scoped package から取っている](https://www.npmjs.com/search?q=%40nozomiishii)。自分用 scoped package を作るか、公開版に差し替える。

| ファイル | 内容 |
|---|---|
| [`commitlint.config.ts`](../commitlint.config.ts) | `@nozomiishii/commitlint-config` |
| [`lefthook.yaml`](../lefthook.yaml) | `@nozomiishii/lefthook-config` |
| [`prettier.config.ts`](../prettier.config.ts) | `@nozomiishii/prettier-config` |
| [`.markdownlint-cli2.mjs`](../.markdownlint-cli2.mjs) | `@nozomiishii/markdownlint-cli2-config` |
| [`package.json`](../package.json) | 上記 4 + 1 (`@nozomiishii/eslint-config` 等) の devDependencies |

### 固定パス（個人 layout 前提）

| ファイル | 内容 |
|---|---|
| [`home/.zshrc`](../home/.zshrc) | `PM_CONFIG`（projects.json のパス） |
| [`home/.config/zellij/layouts/code.kdl`](../home/.config/zellij/layouts/code.kdl) | 各 tab の `cwd="Code/nozomiishii/<name>"` |
| [`home/Library/Application Support/Code/User/settings.json`](../home/Library/Application%20Support/Code/User/settings.json) | `dotfiles.repository` / `dotfiles.targetPath` / `projectManager.projectsLocation` / `vscode-kubernetes.minikube-path.mac` / `vscode-kubernetes.kubectl-path.mac` / `rufo.exe` |
| [`home/.agents/skills/backlog/SKILL.md`](../home/.agents/skills/backlog/SKILL.md) | `BRAIN`（brain vault のパス） |
| [`home/.agents/skills/broadcast/SKILL.md`](../home/.agents/skills/broadcast/SKILL.md) | projects / repos のパス |

## 任意（個人色、動くが書き換え推奨）

### 自分の情報

| ファイル | 内容 |
|---|---|
| [`home/.npmrc`](../home/.npmrc) | `init-author-name` |
| [`LICENSE`](../LICENSE) / [`package.json`](../package.json) | 著作権表示・`author` |
| [`README.ja.md`](../README.ja.md) / [`README.md`](../README.md) | Apple ID セットアップ例の `Full Name`, `Account name` |

### SNS・bootstrap URL

| ファイル | 内容 |
|---|---|
| `README.*` | Twitter handle `nozomiishii_dev` |
| `README.*` | `curl -L https://nozomiishii.dev/dotfiles/install \| bash` の bootstrap URL。独自ドメインを立てないなら `curl -L https://raw.githubusercontent.com/<you>/dotfiles/main/install.sh \| bash` で代用可能 |
| [`home/.config/raycast/scripts/*`](../home/.config/raycast/scripts/) | Raycast script の `@raycast.author` / `@raycast.authorURL` |
| [`home/.config/tampermonkey/*`](../home/.config/tampermonkey/) | userscript の `@author` / `@namespace` |
| [`home/Library/Application Support/Code/User/snippets/global.code-snippets`](../home/Library/Application%20Support/Code/User/snippets/global.code-snippets) | TODO snippet の `@nozomiishii`、`cSpell.userWords` |

### メタデータ

| ファイル | 内容 |
|---|---|
| [`package.json`](../package.json) | `homepage`, `repository.url`, `bugs.url` |
| [`.devcontainer/Dockerfile`](../.devcontainer/Dockerfile) | `org.opencontainers.image.source` |

## 不要（参考情報、書き換え不要）

- コメント内の issue / PR 参照（例: `home/.zsh/functions.zsh` の `# 設計: nozomiishii/dotfiles#1006`）
- 計測値・例示のコメント（`home/.agents/skills/pr/SKILL.md` の他人 repo 実測値など）

---

最新の網羅状況は次のコマンドで確認できる。

```shell
rg --no-config 'nozomiishii|Nozomi Ishii|/Users/nozomiishii|~/Code/nozomiishii'
```
