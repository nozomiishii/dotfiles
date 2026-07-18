# セキュリティヘッダー実装パターン

Next.js(App Router)での HSTS / X-Frame-Options / X-Content-Type-Options / CSP の入れ方。

## 配置

- next.config の headers() はビルド時評価。CSP が環境変数(Supabase URL 等)に依存するなら、middleware(proxy)で全レスポンスに付ける。env なしの CI ビルドでも壊れない
- middleware の matcher 除外(/_next/static 等)にはヘッダーが付かない。文書レスポンスに付けば実用上足りる。完全網羅するなら headers() 併用だが二重管理になるため単一箇所を優先する
- ヘッダーの組み立ては純粋関数(例: buildSecurityHeaders(): Record<string, string>)に切り出すと単体テストできる

## ヘッダーの値

- Strict-Transport-Security: `max-age=63072000; includeSubDomains`(2年)。preload は不可逆性が高いため、hstspreload.org へ申請するときに別途判断する。dev の http でも送って無害(ブラウザは http 上の HSTS を無視する)
- X-Content-Type-Options: `nosniff`
- X-Frame-Options: `DENY`。旧ブラウザ向けで、新ブラウザは CSP の frame-ancestors が優先される

## CSP の組み立て

先にブラウザから外に出る通信を実コードから洗い出す。観点:

- 認証・DB SDK のブラウザ直接続(Supabase 等)は connect-src。環境変数の URL は `new URL(...).origin` でオリジンに正規化する
- 音声認識系 SDK の websocket は connect-src。Azure Speech は `wss://*.stt.speech.microsoft.com`(リージョンが実行時に決まるためワイルドカード)
- エラートラッキング。tunnel(Sentry の tunnelRoute 等)経由なら同一オリジンで追加不要。Session Replay を使うなら worker-src に blob: が必要
- 決済。サーバーサイド SDK + リダイレクト遷移だけなら追加不要。Stripe.js をブラウザで読み込む構成なら script-src / frame-src に js.stripe.com
- 外部画像。next/image(/_next/image プロキシ)経由なら img-src 'self' で足りる
- 外部の音源・動画は media-src。任意ホスト配信なら https:、録音・生成データの再生は blob:
- Realtime / WebSocket 機能を将来使うときは connect-src への追加が必要になる

ベースライン:

- `default-src 'self'`、`base-uri 'self'`、`form-action 'self'`、`object-src 'none'`、`frame-ancestors 'none'`
- `script-src 'self' 'unsafe-inline'`。Next.js が埋め込むインラインスクリプトのため。nonce + strict-dynamic 方式は全ページが動的レンダリング強制になるため、トレードオフを明記して判断する
- `style-src 'self' 'unsafe-inline'`。Next.js のインラインスタイルのため
- dev のみ script-src に 'unsafe-eval'(HMR・エラーオーバーレイ)、connect-src に ws:(HMR)を足す

## 検証

- 単体テスト: CSP をディレクティブに分解し、環境別(dev / 本番)にアサートする。本番に 'unsafe-eval' と ws: が無いことを含める
- E2E を CSP 有効の実ブラウザで全 spec 回し、console に CSP violation が出ないことを確認する
- 本番モード(build + start)に curl し、ページ(200)・リダイレクト(30x)・API(401 等)の全レスポンスにヘッダーが付くことを確認する
