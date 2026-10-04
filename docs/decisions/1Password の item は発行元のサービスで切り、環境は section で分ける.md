---
status: accepted
date: 2026-10-03
---

# 1Password の item は発行元のサービスで切り、環境は section で分ける

## 背景と課題

`dev` repo の `apps/home` に [Better Auth を移す作業](https://github.com/nozomiishii/dev/issues/3215)で、Worker に secret を足すことになった。`dev` vault の既存の item は流儀がそろっていなかった。

- `cloudflare`: field は `credential` と `account-id`
- `storybook`: field は環境変数名
- `sentry`: 未使用

決めるのは 4 つ。item の切り方、section の名前、全環境で同じ値の置き方、環境の分け方。

## 検討した選択肢

### item の切り方

| 選択肢 | 評価 |
| --- | --- |
| `.env.tpl` 1 本ごとに item を 1 つ | 判断が要らない。同じ値を複数の item にコピーするので、ローテーションで直し漏れる |
| 発行元のサービスごとに item を 1 つ。値が複数要るときは section で分ける | 複数の `.env.tpl` が同じ item を参照するので、値をコピーしない |
| 鍵 1 つごとに item を 1 つ。組み込みの `credential` / `username` field を使う | infra・release の vault とそろう。item を複製して値を変えないまま使い回す事故が起きやすい。1Password 上で環境変数名が見えない |

### section の名前

| 選択肢 | 評価 |
| --- | --- |
| 発行元の画面で付けた鍵の名前に合わせる | アプリをまたぐ鍵にも付けられる |
| 使う範囲 `<app>-<env>` | アプリをまたぐ鍵には範囲の名前を付けにくい |

### 全環境で同じ値の置き方

| 選択肢 | 評価 |
| --- | --- |
| `<app>-shared` の section に置き、既定値として読ませる | 1 箇所に書けば済む。1Password には継承が無いので、本番用の section を足しても `.env.tpl` の直し忘れがエラーにならない |
| 環境ごとの section に同じ値を書く | 環境の数だけ同じ値を書く |

### 環境の分け方

| 選択肢 | 評価 |
| --- | --- |
| 環境ごとに vault を分ける (`op://$APP_ENV/...`) | 1Password 公式が[例に挙げている形](https://www.1password.dev/cli/secrets-environment-variables)。service account が読める vault は[作成後に変えられない](https://www.1password.dev/service-accounts/manage-service-accounts)。分けるには GitHub に 2 本目の token が要る |
| 1 つの vault の中を section で分ける | token は 1 本のまま |

## 決定

参照の決め方は [global AGENTS.md の「シークレット管理」](../../home/AGENTS.md#シークレット管理)に書いた。ここには理由を残す。

ブラウザに配る値は bundle で公開されるので、1Password に入れても隠せない。Sentry の DSN も公開してよいと [Sentry が明記している](https://docs.sentry.io/concepts/key-terms/dsn-explainer/)。

次の vault は、鍵 1 つごとの item と組み込みの field を使う今の形のまま変えない。

- `nozomiishii-release`: 複数 repo の release が共有する用途名の vault
- `cloudflare-access`: infra が作った Access の service token を置く用途名の vault

### item の切り方

発行元のサービスごとに item を 1 つ作る。鍵 1 つごとの item は infra・release とそろうが、item を複製して値を変えないまま使い回す事故を重く見て採らない。

### section の名前

使う範囲 `<app>-<env>` にする。section は値を分ける必要が出たときだけ作る。Cloudflare の API token のようにアプリをまたぐ鍵は値を分けないので section が要らず、範囲の名前で足りる。

後から section で分けても、移し忘れた参照が黙って別の値を読むことはない。同じ label の field が 1 つの item に 2 つ以上あると、section を書かない参照は op がエラーで止めると [1Password 社員が回答している](https://www.1password.community/developers-69/how-to-specify-password-that-is-not-in-section-11038)。

### 全環境で同じ値の置き方

`<app>-shared` は作らない。Better Auth の oAuthProxy が使う `OAUTH_PROXY_SECRET` のように全環境で同じ値が要るものは、環境ごとの section に同じ値を書く。

### 環境の分け方

環境は vault で分けず、1 つの vault の中を section で分ける。本番の値だけ別 vault に移しても、PR の CI が触れる範囲は変わらない。preview を作る Cloudflare の API token は、Workers Scripts の権限が account 単位で付く。同じ Worker に本番 deploy もできる。

## 結果

### 良くなったこと

- 値を item 間でコピーしないので、ローテーションで直す item が 1 つで済む
- 1Password 上で field 名から環境変数名が分かる
- GitHub に置く secret は `OP_SERVICE_ACCOUNT_TOKEN` 1 本のまま

### 引き受けたコスト

- infra・release の vault と item の流儀がそろわない
- 全環境で同じ値は section の数だけ書くので、ローテーションの直し漏れが section の単位で残る
- PR の CI が使う service account から本番の値も読める

### 保留した論点

- 全環境で同じ値が要る環境変数が増えたら、`<app>-shared` を作らない判断を見直す
