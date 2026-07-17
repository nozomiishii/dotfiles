# SEO・OGP・PWA 資産の実装パターン

Next.js(App Router)での title / canonical / OGP / robots / アイコン / PWA manifest の入れ方。

## サイト情報の正本

- サービス名・説明・OG 画像定義を 1 ファイル(例: lib/site.ts)に集約する。名前が未定でも仮名で構造を先に作り、確定時にそこだけ差し替える
- 公開 URL(ドメイン)の正本はデプロイ設定の環境変数に置き、site.ts に持たせて二重管理にしない

## Metadata API の罠

- metadataBase が無いと相対 URL の canonical / og:url / og:image がビルドエラーになる。CI が環境変数なしでビルドする構成では、環境変数に localhost フォールバックを付けた getter を使う
- 相対 canonical("./" や "/path")は metadataBase 基点で解決される。root layout に canonical を置くと全ページがルートを canonical 宣言してしまう。canonical は公開ページごとに設定する
- ページ側で openGraph を部分上書きすると親 layout の値が丸ごと消える(ファイル規約由来の og:image も)。共通部を定数(defaultOpenGraph)にして各ページでスプレッド展開する
- title は template 形式(`{ default: name, template: "%s | name" }`)にする
- html の lang 属性を UI の言語に合わせる

## 認証ミドルウェアとの衝突

- 未ログインを一律リダイレクトする構成では、/robots.txt・/manifest.webmanifest・OG 画像がクローラーから 30x になる。メタデータ資産のパスを素通しさせ、素通りの単体テストを足す
- クローラーが実際に見られるページ(未ログインで到達可能なページ)がどれかを意識する。全ページ保護ならログインページが実質唯一のクロール対象

## 資産の実装

- robots.txt / manifest は app/robots.ts・app/manifest.ts のコード規約で書く(site.ts を参照できる)。robots は /api/ と OAuth コールバックを Disallow
- OG 画像は ImageResponse で生成する。ファイル規約(opengraph-image.tsx)は alt / size 等の export が react-refresh/only-export-components 系 lint と衝突しうる。route handler(app/opengraph-image/route.tsx)にすると回避でき、og:image の寸法宣言は site.ts 側に持たせる
- アイコンはブランド確定までプレースホルダーで良い: favicon.ico・icon.svg・apple-icon.png(Next が自動リンク)+ manifest 用 PNG(192 / 512、maskable はグリフを 0.7 倍にして safe zone 内に収める)
- インデックスさせたくない公開前は robots の Disallow: / への一時変更を検討する

## 検証

- 環境変数なしの next build(CI 同等)が通ること。ルート表で robots / manifest / OG 画像が配信されることを確認
- curl で head を確認: title の template 動作、canonical の絶対 URL、og:一式、twitter:card、manifest・アイコンのリンク
- クローラー UA(facebookexternalhit 等)でも取得できること
- 認証まわりの E2E で proxy 変更の回帰がないこと
