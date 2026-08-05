# rollback ワンクリック化の実装パターン

異常時の初期対応を、手作業の CLI 手順ではなく「対象と version を選んで戻す → 戻した後の smoke 確認」の 1 操作にする。GitHub Actions の workflow_dispatch + Cloudflare Workers(wrangler rollback)を例にする。実例は nozomiishii/dance の rollback.yaml([dance#58](https://github.com/nozomiishii/dance/pull/58))。

## 設計

- workflow_dispatch の inputs は、戻す対象(choice。全対象をまとめて戻す選択肢も置く)、version ID(空なら直前のデプロイ)、理由(デプロイ履歴に残す。wrangler なら --message)の 3 つにする
- rollback コマンドは非対話で実行する(wrangler なら --yes)。確認プロンプトで止まる workflow は初期対応に使えない
- version ID は対象ごとに別物。複数対象 + version ID 指定の組み合わせは rollback 実行前に検査して弾き、一部だけ戻った中途半端な状態を作らない
- inputs は run へ直接埋め込まず env 経由で渡す(script injection 対策)
- secrets と承認は deploy と同じ GitHub Environments(production)を使う。rollback 専用の権限を新設しない
- concurrency group を deploy と共有し、deploy と rollback の同時実行を防ぐ
- rollback 後にヘルスチェックエンドポイントへの smoke test まで同じ workflow で実行する。失敗したら「さらに前の version への rollback を検討する」とエラーで案内する

## 注意

- rollback はコードだけ戻す。DB migration・secrets・環境変数は戻らないため、それらの変更を含むデプロイを戻すときは互換性を確認してから実行する

## 検証

- 初回デプロイ後に一度実行して、戻る・smoke が通ることを確認する。障害の最中に初めて動かさない
