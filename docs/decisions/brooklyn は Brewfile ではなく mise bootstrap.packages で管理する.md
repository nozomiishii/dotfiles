---
status: accepted
date: 2026-08-31
---

# brooklyn は Brewfile ではなく mise bootstrap.packages で管理する

## 背景と課題

Brewfile 全体の mise 移行は[追跡 issue](https://github.com/nozomiishii/dotfiles/issues/1688)で見送り中。その調査で brooklyn は「構造的に不可能」と判定された唯一の cask だった。Brooklyn 2.0.0 のアプリ化と [tap 側の対応](https://github.com/nozomiishii/homebrew-tap/issues/63)でこの判定が外れ、mise の `brew-cask:` から入るようになった。[dotfiles のリンクを stow から mise へ移した](<dotfiles のリンクは GNU Stow ではなく mise で管理する.md>)のと同じ、宣言を mise に寄せる方針に沿って管理を移す。

## 検討した選択肢

- Brewfile のまま維持する: cask の管理が 1 箇所に揃う
- mise `[bootstrap.packages]` へ移す: mise から Brooklyn を入れる経路が dotfiles で常用され、壊れたら気づける

## 決定

home/.config/mise/config.toml の `[bootstrap.packages]` に `brew-cask:nozomiishii/tap/brooklyn` を置く。実機で install からスクリーンセーバー extension の登録まで動くことは検証済み。

`mise install` は `[bootstrap.packages]` を処理しないため、apply と upgrade を `mise run packages` タスクにまとめ、toolchains の末尾と post-merge hook から呼ぶ。post-merge は homebrew → packages の順の直列にする。brew 所有のマシンでは `brew bundle --cleanup` が Brewfile から外れた brooklyn を消し、直後の apply が mise 版を入れ直す。merge を pull するだけで所有権が brew から mise へ移る。

戻すときは次の順で行う。

- config からエントリを消して `mise bootstrap packages prune --manager brew-cask --yes` で mise の実体と receipt を除去する
- Brewfile にエントリを戻して `mise run homebrew` を実行する

## 結果

### 良くなったこと

- mise 経由の install 経路が週次 CI の install.sh で回帰検証される
- brooklyn 専用だった `tap "nozomiishii/tap"` と `brew trust` の entry が消える

### 引き受けたコスト

- cask の管理が Brewfile と mise config の 2 箇所に割れる
- mise 管理中に `brew reinstall --cask nozomiishii/tap/brooklyn` すると Caskroom の symlink 衝突で壊れる ([tap 側の検証記録](https://github.com/nozomiishii/homebrew-tap/issues/63#issuecomment-5354544338))。戻す手順の順序はこの衝突を避けるためにある
- post-merge で homebrew の後の packages が失敗すると、`mise run packages` を再実行するまで brooklyn が入っていない状態になる
- brew-cask はバージョンピンに対応せず、Renovate も `[bootstrap.packages]` を解析しない。更新は brew 時代と同じ実行時の latest 追従になる

### 保留した論点

- 残りの cask の移行は[追跡 issue](https://github.com/nozomiishii/dotfiles/issues/1688)の終了条件に従う
