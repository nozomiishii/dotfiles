# /a Stage 1: タブ準備 + 質問送信

Chrome 拡張機能 (Claude in Chrome) を使って、ChatGPT・Claude・Gemini に同じ質問を送信する。

## 質問内容

{{QUESTION}}

## Chrome 状態確認とタブの準備

最初に `tabs_context_mcp` を呼んで現在の Chrome タブ状態を確認する。これで「Chrome が起動中か」がわかる。

新規 Chrome プロセスをむやみに起動しない方針:

- Chrome 起動中（既存タブが見える）→ `tabs_create_mcp` は既存ウィンドウに新規タブを足すだけ（プロセス起動なし）
- Chrome 完全終了中（タブ取得がエラー or 空）→ `tabs_create_mcp` で Chrome がコールドスタートする。これは「Claude in Chrome」拡張機能の仕様上避けられない（既存 Chrome に attach する手段がない）

常に新規タブを 3 つ作成する。既存タブは再利用しない（並列セッション衝突防止）。`tabs_create_mcp` で返ってきた tab ID を 3 つとも記録し、以降のステップでは記録した tab ID のみを操作する。

- ChatGPT: `https://chatgpt.com/`
- Claude: `https://claude.ai/new`
- Gemini: `https://gemini.google.com/app`

各タブでログイン状態を確認。ログイン画面が表示されている場合は停止し、最終応答 JSON の `error` に `"login required: <site>"` を入れて返す（自動でログインしない）。

## Tab group への追加

3 つのタブをすべて Claude tab group に入れる。

## 質問送信

各タブの入力欄に質問を貼り付けて送信。3 タブとも素早く済ませる。

各サイトの入力欄:

- ChatGPT: ページ下部のテキストエリア（`Ask anything` プレースホルダー）
- Claude: ページ下部のテキストエリア（`How can I help you today?` 付近）
- Gemini: ページ下部のテキストエリア（`Ask Gemini` プレースホルダー）

### Gemini の追加手順（送信前にモデルを Pro へ切替）

Gemini はデフォルトで `Fast` モデルになっていることが多い。じっくり考えた回答が欲しいので送信前に Pro へ切り替える。

モデルセレクタのトリガーボタンを `javascript_tool` で開く:

```js
const trigger = document.querySelector('button[aria-label^="Open mode picker"]');
if (!trigger) throw new Error('Gemini model selector not found');
trigger.click();
```

少し待ってからメニュー内の Pro を選択。メニュー項目は `<gem-menu-item>` カスタム要素で、ラベルは `.label` span 内にバージョン番号付きで表示される（例: `"3.1 Pro"`）:

```js
await new Promise(r => setTimeout(r, 300));
const items = [...document.querySelectorAll('gem-menu-item')];
const pro = items.find(item => /\bPro$/.test(item.querySelector('.label')?.textContent.trim() || ''));
if (!pro) throw new Error('Pro option not found in gem-menu-item');
pro.click();
```

切替後、トリガーボタンの `aria-label` が `"Open mode picker, currently Pro"` 相当になっているか確認する。なっていなければメニューを開くところからリトライ（最大 2 回）。その後、質問を入力して送信する。

selector が UI 変更で動かなくなった場合は `read_page` で現在の DOM を観察し、新しい selector に書き換えるか、`computer` でドロップダウン位置をクリックする方法に切り替える。それでも切替できない場合は `Fast` のまま続行し、最終応答 JSON の `error` に `"gemini fast fallback (pro switch failed)"` を入れる。

## URL 取得と最終応答

3 タブとも送信が完了したら、`tabs_context_mcp` で各タブの最新 URL（チャット ID 付き）を取得する。

最終応答は以下の JSON 1 行のみ。テキスト本文・前置き・コードフェンス・説明文を一切含めない:

```
{"chatgpt": "<url>", "claude": "<url>", "gemini": "<url>"}
```

エラー（送信失敗・ログイン要求・レートリミット等）が起きた場合は該当サイトを `null` にし、`error` フィールドを追加:

```
{"chatgpt": "<url or null>", "claude": "<url or null>", "gemini": "<url or null>", "error": "<reason>"}
```

途中報告や追加説明は絶対に出さない。Stage 1 の最終出力は JSON 1 行だけ。
