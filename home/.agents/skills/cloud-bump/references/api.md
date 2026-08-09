# cloud 環境 内部 API リファレンス

/cloud-bump が使う claude.ai の未文書化 API の詳細。公式 API ではないため、動かなくなったら「エンドポイントの再発見」で調査し直す。

## エンドポイント

`https://claude.ai/v1/environment_providers/private/organizations/{org_id}/environments/{env_id}`

GET で現在の環境設定を取得し、同じ URL への POST で更新する。org_id と env_id は GET のレスポンス、または環境セレクタ操作時のネットワークログから取得する。

## API レスポンス構造

```json
{
  "environment_id": "env_...",
  "name": "Default",
  "config": {
    "environment_type": "anthropic",
    "sub_type": "ccr",
    "cwd": "/home/user",
    "init_script": "# bump ...\ncurl ...",
    "environment": {},
    "languages": [{ "name": "python", "version": "3.11" }, ...],
    "network_config": { "allowed_hosts": ["*"], "allow_default_hosts": true }
  }
}
```

UI の「Setup script」は `config.init_script`、「Environment variables」は `config.environment`。

## POST リクエストの必須フィールド

`name`, `description`, `config` が必要。`description` は GET に既存値があればそのまま返し、既存の説明文を空文字列で上書きしない。GET に `description` が無い環境では空文字列で補う。実測では undefined は JSON.stringify で field ごと脱落して 400 (`description: Field required`)、null も 400、空文字列は成功する。

## bump 行の形式

変更は init_script 先頭の日時コメント行 `# bump YYYY-MM-DD HH:MM` の追加・更新のみで、他の行に触れない。再構築のトリガーは欄のテキストが変わることなので、同日に複数回 bump しても変化が出るよう時刻まで書く。

## エンドポイントの再発見

API が変更されて動かなくなった場合の調査手順。

- Claude in Chrome で <https://claude.ai/code> を開く
- ネットワーク観察が利用できることを確認し、ログをクリアする。利用できなければ手動フォールバック URL を案内して止まる
- 下部バーの環境タブ（雲アイコン）→ 歯車アイコンでダイアログを開く
- ダイアログを開いた時点の GET リクエストの URL からエンドポイントのパス・org_id・env_id が分かる
- ダイアログ表示と GET だけを観察する。Setup script や他の項目は変更せず、「Save changes」をクリックしない
- GET のレスポンスと、既存の frontend bundle 内の request 定義から method、URL、payload のフィールド名を確認する
- 読み取りだけで POST の仕様を特定できなければ、環境を変更せず手動フォールバック URL を案内して止まる。再発見のための試験 POST はユーザー承認前に行わない
