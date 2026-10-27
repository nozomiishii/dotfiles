---
status: accepted
date: 2026-09-13
---

# 開発フローは Superpowers に任せる

## 背景と課題

開発フローの正本は自作の dev スキルだった。プラン・敵対的レビュー・ユーザー判断のゲートをスキルで発動させる狙いは果たしていたが、プラン中の質問の出し方や plan mode の扱いなど、細かな調整を自作スキル側で重ね続けていた。

同じ役割は Superpowers plugin の brainstorming・writing-plans・executing-plans・requesting-code-review などのスキルが持つ。以前は自作スキルとの重複と毎回のスキル確認の負担から [Superpowers を一度削除した](https://github.com/nozomiishii/dotfiles/pull/1291) が、自作スキルの管理を減らせるかを確かめるため再導入を検討した。

## 検討した選択肢

- dev スキルを正本のまま保つ: 挙動を細かく決められるが、フローの調整を自作スキルで抱え続ける
- Superpowers を再導入し、dev スキルと併用する: 同じ場面で 2 つのフローが起動し、以前の削除理由だった重複が再発する
- Superpowers を再導入し、重複する dev・test スキルを削除する: 自作スキルの管理が減る。フローの細部は Superpowers の挙動に従う

## 決定

- 新機能と挙動が変わる修正の開発フローは Superpowers に任せる
- 重複する dev と test スキルを削除する。元ファイルは [archives リポジトリに退避した](https://github.com/nozomiishii/archives/pull/503)
- 仕様書と実装計画の置き場は doc スキルに従い、Superpowers の既定保存先より優先する。この 1 行を AGENTS.md の「設計」セクションに残す

経緯は [Superpowers の再導入](https://github.com/nozomiishii/dotfiles/pull/1796) と [導入後の観察](https://github.com/nozomiishii/dotfiles/issues/1795) にある。2 週間の観察で普段の開発に支障は出なかった。

> Note: 敵対的レビューは導入後に [AGENTS.md のルールとして足し直し](https://github.com/nozomiishii/dotfiles/pull/1804)、プラン提示前のレビューと「Superpowers のフローに従う」の行は [後に AGENTS.md から外した](https://github.com/nozomiishii/dotfiles/pull/1887)。今は Superpowers の起動を Superpowers 側に任せ、AGENTS.md には置き場の 1 行と、実装完了前のレビューだけが残っている。

## 結果

### 良くなったこと

- 開発フローの自作スキルを保守しなくてよくなった

### 引き受けたコスト

- dev スキルで決めていた細部 (プラン確定時と実装完了時の敵対的レビュー、plan mode に入らない規律) はスキルとしては無くなり、Superpowers の挙動か AGENTS.md のルールに任せる
- Superpowers の更新でフローが変わったとき、こちらの規約 (doc スキルの置き場・ADR の書式) とずれていないかを確かめる必要がある

### 保留した論点

- Codex での Superpowers の扱い。今 Superpowers を有効にしているのは Claude Code だけ
