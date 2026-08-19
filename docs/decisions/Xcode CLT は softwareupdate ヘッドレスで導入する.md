---
status: accepted
date: 2026-08-12
---

# Xcode CLT は softwareupdate ヘッドレスで導入する

## 背景と課題

素の Mac で `curl -fsSL https://dotfiles.nozo.sh | bash` を叩くと、Xcode Command Line Tools (CLT) が無い場合に 2 段階インストールになっていた。

```text
curl | bash
  → CLT が無ければ Apple の GUI インストーラーを開いて exit 1
  → CLT のダウンロード完了を待つ (数時間かかることがある)
  → curl をもう一度叩く
```

完了を見張って再実行する手間が大きい。

経緯は 2 転している。[#1440](https://github.com/nozomiishii/dotfiles/pull/1440) までは softwareupdate で CLI から直接インストールする方式だった (sudo なしで `softwareupdate -i` を実行する弱点があった)。[#1464](https://github.com/nozomiishii/dotfiles/pull/1464) は新しい Mac へ導入する前に敵対的レビューで直せる箇所を直す依頼から生まれた PR で、安全側の設計判断として GUI 方式へ置き換えられ、この 2 段階が生まれた (当時の Codex セッションの記録より)。

## 検討した選択肢

- `xcode-select --install` で GUI を開いて exit 1 する: Apple 公式の経路。実動検証できない headless インストールより、開いて安全に終了する方が確実という判断だった。curl を 2 回叩くことになる
- sudo 付き softwareupdate でヘッドレスに入れる: curl 1 回で最後まで走り切る。softwareupdate 方式が実機で壊れた記録はない

## 決定

Homebrew install.sh と同じ sudo 付き softwareupdate ヘッドレス方式で CLT をインストールし、curl 1 回で最後まで走り切らせる。

- placeholder ファイル `/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress` を置いて `softwareupdate -l` に CLT を列挙させ、ラベルを `softwareupdate -i` に渡す
- ラベル取得やインストールに失敗したときだけ、従来どおり `xcode-select --install` で GUI を開いて exit 1 し、再実行を促す
- Darwin の呼び出し順は request_admin_privileges → request_documents_access → ensure_xcode_clt とし、人間の操作 (パスワード入力・TCC ダイアログ) を先頭に集約する。CLT の長いダウンロード中もインストール中限定の NOPASSWD sudoers が効いているので、以降は無人で走る

## 結果

### 良くなったこと

- 素の Mac でも curl 1 回でセットアップが完走する。GUI ダイアログの承諾クリックと再実行が不要になる
- CI の素の Mac 相当環境 (CLT と Xcode を削除した macos-latest) で、ヘッドレスインストールが 3 分強で完走することを実機確認済み ([run 31592485654](https://github.com/nozomiishii/dotfiles/actions/runs/31592485654))

### 引き受けたコスト

- #1464 が意図した「CLT が無くて exit するとき sudo を無駄に聞かない」性質は失われるが、exit するのはヘッドレス失敗の稀なケースだけなので許容する
- ラベル抽出は softwareupdate -l の出力フォーマットに依存する。フォーマットが変わって取れなくなっても GUI フォールバックで従来の挙動に戻るだけで、インストール自体は塞がらない
- placeholder の掃除は request_admin_privileges の EXIT trap に集約している。bash の EXIT trap は 1 本しか持てないため、trap を増やすときは既存 trap に追記する

### 保留した論点

なし
