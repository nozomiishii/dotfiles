---
status: accepted
date: 2026-08-23
---

# tap trust は Brewfile にパッケージ単位で書く

## 背景と課題

Homebrew は非公式 tap の formula / cask / external command を読み込む前に trust を要求する。未 trust だと `brew bundle` が毎回警告を出し、outdated 判定もスキップされる。

```text
Warning: Cannot check whether smudge/smudge/nightlight is outdated because its tap is not trusted.
```

trust の保存先は `$XDG_CONFIG_HOME/homebrew/trust.json`、未設定なら `~/.homebrew/trust.json`。どちらもこの repo の管理外なので、そのままでは新しい Mac ごとに `brew trust` を叩き直すことになる。

対象は 3 つ。`nozomiishii/tap/brooklyn`、`smudge/smudge/nightlight`、`stripe/stripe-cli/stripe`。

## 検討した選択肢

| 選択肢 | 評価 |
| --- | --- |
| `brew trust` を手で叩く | trust.json は repo 外。新しい Mac でセットアップ手順が増える |
| `HOMEBREW_NO_REQUIRE_TAP_TRUST=1` で検査を無効化 | Homebrew が非推奨とし、後のリリースで削除予定。全 tap がまとめて対象になる |
| `tap "...", trusted: true` | tap 全体を trust する。その tap に将来追加される formula / cask / command も自動で対象になる |
| `brew "...", trusted: true` / `cask "...", trusted: true` | Brewfile に書いた package だけを trust する |

`brew bundle install` は fetch より前に Brewfile の `trusted` を trust store へ書き込む ([bundle/installer.rb](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/installer.rb))。どの書き方でも `make homebrew` だけで完結する点は変わらない。

## 決定

Brewfile の package 行に `trusted: true` を付ける。tap 単位の trust は使わない。

## 結果

### 良くなったこと

- 新しい Mac でも `make homebrew` だけで trust が揃う
- trust の範囲が Brewfile に書いた package と一致し、tap に後から増えたものは自動では trust されない

### 引き受けたコスト

- 非公式 tap の package を足すたびに `trusted: true` を書く必要がある

### 保留した論点

- なし
