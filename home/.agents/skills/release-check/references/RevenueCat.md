# RevenueCat

RevenueCat を採用する repo だけで読む。着手時に公式ドキュメントと料金を再確認し、repo 固有の issue へ次を展開する。

## 正本と識別子

- [ ] 各情報の正本を決める。ストアの取引は Apple または Google、契約状態の取得は RevenueCat、アプリの認可判定は自前 DB の entitlement とする。クライアントの判定だけで機能を解放しない
- [ ] Web 決済とストア決済が同時に存在する場合の優先順位、期限、猶予、返金、二重契約を決める。1 ユーザー 1 機能の行に複数契約元を上書きする設計なら、先にデータモデルを直す
- [ ] App User ID に認証基盤の不変な user ID を使う。メールアドレス、端末 ID、表示名を使わない。認証前に匿名購入を許すか決め、`configure` と `logIn` の順序を固定する
- [ ] RevenueCat の entitlement ID を repo で使っている機能 ID に合わせ、全ストアの商品を同じ entitlement へ割り当てる

## セットアップとアプリ

- [ ] RevenueCat project とストアごとの app を作り、Bundle ID / package name を一致させる
- [ ] App Store Connect または Google Play の subscription、期間、価格、subscription group を作り、RevenueCat の product、entitlement、offering に結び付ける
- [ ] SDK を公式手順で導入する。Capacitor は `@revenuecat/purchases-capacitor` を追加し、iOS target の In-App Purchase capability を有効にして `cap sync` 後の native project を確認する
- [ ] public SDK key と server secret を分離する。server secret をアプリへ含めず、環境ごとに secret 管理する
- [ ] アプリ内に購入、購入の復元、契約管理への導線を置く。ストア課金が必要な面では Web 決済のボタンを表示しない
- [ ] RevenueCat が一時的に利用できない場合の表示と認可を決める。期限不明の entitlement を無期限に有効化しない

## Webhook と同期

- [ ] Webhook の Authorization と HMAC 署名を検証する。HMAC は JSON parse 前の raw body で検証し、timestamp の許容範囲と定数時間比較を使う
- [ ] event ID を保存し、同じ event の複数配送を冪等に処理する。未知の field と event type を受けても既知イベントの処理を壊さない
- [ ] Webhook 受信後に RevenueCat API から subscriber を取得し、正規化した現在状態を自前 DB へ反映する。イベント順だけから現在状態を推測しない
- [ ] sandbox と production をログ、監視、更新対象で区別する
- [ ] 配送失敗の再送、手動 retry、定期 reconcile を用意する。Webhook の成功だけを整合性の根拠にしない

## 検証と公開

- [ ] sandbox で新規購入、自動更新、支払い失敗、猶予、解約、期限切れ、返金、取り消しを確認する
- [ ] 復元ボタン、再インストール、別端末、別プラットフォーム、ログアウト、アカウント切り替えを確認する。Project の restore behavior が意図した所有権移転になるか確認する
- [ ] Web とストアの両方で契約した場合、片方だけ解約した場合、アカウント削除後に遅延通知が来た場合を確認する
- [ ] unit、API integration、ストア sandbox の実機を通す。TestFlight または内部テストで本番 backend と結線した成果物を確認する
- [ ] プライバシーポリシー、App Privacy、データ削除手順、問い合わせ手順へ RevenueCat と送信データを反映する
- [ ] [料金ページ](https://www.revenuecat.com/pricing)を確認日付きで残し、売上増加時の費用アラートを設定する

## 公式資料

- [Capacitor SDK](https://www.revenuecat.com/docs/getting-started/installation/capacitor)
- [ユーザー識別](https://www.revenuecat.com/docs/customers/identifying-customers)
- [Webhook](https://www.revenuecat.com/docs/integrations/webhooks)
- [購入の復元](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [Restore behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
