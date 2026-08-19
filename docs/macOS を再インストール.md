# macOS を再インストール

macOS を入れ直す前にやること。上から順に進める。

## Bluetooth デバイスのペア解除

System Preferences > Bluetooth で、登録済みのデバイスをすべてペア解除する。

## 後片付け

- SSH 鍵は 1Password SSH agent の管理で、このマシンには無い
- 任意で [GitHub CLI の認可](https://github.com/settings/apps/authorizations)を失効できる。全マシンの gh トークンが無効になる

## iCloud からサインアウト

- System Preferences > Apple ID > iCloud で「Mac を探す」をオフにする
- System Preferences > Apple ID > Overview でサインアウトする

## ライセンスの無効化

🐘 TablePlus > ライセンスを登録 から解除する。

## すべてのコンテンツを消去

- 画面左上の Apple メニューから「システム設定」を開く
- メニューバーの「システム設定」から「すべてのコンテンツと設定を消去」を選ぶ

Apple のサポート記事: [Japanese](https://support.apple.com/ja-jp/HT201065) | [English](https://support.apple.com/en-gb/HT201065)
