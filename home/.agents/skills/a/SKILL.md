---
name: a
description: ChatGPT・Claude・Geminiに同じ質問を並列投下して回答を比較
argument-hint: <question>
disable-model-invocation: true
---

# /a wrapper

このコマンドは Sonnet サブエージェントで実行する。親セッションが Opus 1M でも、サブエージェントは Sonnet 標準 context で走るので、Extra Usage 課金 (1M Sonnet) を踏まずに高速・低コストで処理できる。

送信直後にタブ URL をユーザー画面に出すため、2 段階で dispatch する。

## 親セッションが行うこと（最優先・順番厳守）

### Stage 1: タブ準備 + 質問送信

Agent tool を呼ぶ:

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"/a stage 1 (setup + send)"`
- `prompt`: 下記「## Subagent execution」内の「### Stage 1 instructions」セクション全文（`### Stage 2 instructions` の直前まで）。`$ARGUMENTS` は Claude Code が既に置換済みなのでそのまま渡せばよい。

Stage 1 は **JSON 1 行を返す**。受け取ったら parse して、以下のフォーマットでユーザーに**直接表示**する（これが「送信直後の URL 表示」になる）:

```
送信完了。各タブの URL:
- ChatGPT: <chatgpt_url>
- Claude: <claude_url>
- Gemini: <gemini_url>
```

`error` フィールドがあれば素直に伝える（ログイン要求・サイトスキップ等）。3 URL すべて `null` なら Stage 2 をスキップして終了。

### Stage 2: ポーリング + レポート

URL 表示の直後、続けて Agent tool を呼ぶ:

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"/a stage 2 (poll + report)"`
- `prompt`: 下記「### Stage 2 instructions」セクション全文（「## Subagent execution」の末尾まで）。冒頭の「## 入力 URL」プレースホルダ `<chatgpt_url>` 等を Stage 1 で得た値に置換してから渡す。

Stage 2 の戻り値（最終レポート markdown）をそのままユーザーに表示して終了。

---

## Subagent execution

# 3 社並列質問タスク

Chrome 拡張機能（Claude in Chrome）を使って、ChatGPT・Claude・Gemini に同じ質問を投げて、回答を比較する。

## 質問内容

$ARGUMENTS

### Stage 1 instructions

# Stage 1: タブ準備 + 質問送信

## 実行手順

#### 1. Chrome 状態確認 + タブの準備

最初に `tabs_context_mcp` を呼んで現在の Chrome タブ状態を確認する。これで「Chrome が起動中か」がわかる。

新規 Chrome プロセスをむやみに起動しない方針:

- Chrome 起動中（既存タブが見える）→ `tabs_create_mcp` は既存ウィンドウに新規タブを足すだけ（プロセス起動なし）
- Chrome 完全終了中（タブ取得がエラー or 空）→ `tabs_create_mcp` で Chrome がコールドスタートする。これは「Claude in Chrome」拡張機能の仕様上避けられない（既存 Chrome に attach する手段がない）

**常に新規タブを 3 つ作成する**（既存タブは再利用しない、並列セッション衝突防止）。`tabs_create_mcp` で返ってきた tab ID を 3 つとも記録し、以降のステップでは記録した tab ID のみを操作する。

- ChatGPT: `https://chatgpt.com/`
- Claude: `https://claude.ai/new`
- Gemini: `https://gemini.google.com/app`

各タブでログイン状態を確認。ログイン画面が表示されている場合は停止し、最終応答 JSON の `error` に `"login required: <site>"` を入れて返す（自動でログインしない）。

#### 2. Tab group への追加

3 つのタブをすべて Claude tab group に入れる。

#### 3. 質問送信

各タブの入力欄に質問を貼り付けて送信。3 タブとも素早く済ませる。

各サイトの入力欄：

- **ChatGPT**: ページ下部のテキストエリア（`Ask anything` プレースホルダー）
- **Claude**: ページ下部のテキストエリア（`How can I help you today?` 付近）
- **Gemini**: ページ下部のテキストエリア（`Ask Gemini` プレースホルダー）

##### Gemini の追加手順（送信前にモデルを Pro へ切替）

Gemini はデフォルトで `Fast` モデルになっていることが多い。じっくり考えた回答が欲しいので **送信前に Pro へ切り替える**:

1. モデルセレクタのトリガーボタンを `javascript_tool` で開く:

   ```js
   const trigger = document.querySelector('button[aria-label^="Open mode picker"]');
   if (!trigger) throw new Error('Gemini model selector not found');
   trigger.click();
   ```

2. 少し待ってからメニュー内の Pro を選択。メニュー項目は `<gem-menu-item>` カスタム要素で、ラベルは `.label` span 内にバージョン番号付きで表示される（例: `"3.1 Pro"`）:

   ```js
   await new Promise(r => setTimeout(r, 300));
   const items = [...document.querySelectorAll('gem-menu-item')];
   const pro = items.find(item => /\bPro$/.test(item.querySelector('.label')?.textContent.trim() || ''));
   if (!pro) throw new Error('Pro option not found in gem-menu-item');
   pro.click();
   ```

3. 切替後、トリガーボタンの `aria-label` が `"Open mode picker, currently Pro"` 相当になっているか確認。なっていなければ手順 1〜2 をリトライ（最大 2 回）。

4. その後、質問を入力 → 送信。

selector が UI 変更で動かなくなった場合は `read_page` で現在の DOM を観察し、新しい selector に書き換えるか、`computer` でドロップダウン位置をクリックする方法に切り替える。それでも切替できない場合は `Fast` のまま続行し、Stage 2 のレポート末尾で「Gemini は Fast で回答（Pro 切替失敗）」と明記する想定。

#### 4. URL 取得 + 最終応答

3 タブとも送信が完了したら、`tabs_context_mcp` で各タブの最新 URL（チャット ID 付き）を取得する。

**最終応答として、テキスト本文・前置き・コードフェンス・説明文を一切含めず、以下の JSON 1 行のみ返す**:

```
{"chatgpt": "<url>", "claude": "<url>", "gemini": "<url>"}
```

エラー（送信失敗・ログイン要求・レートリミット等）が起きた場合は該当サイトを `null` にし、`error` フィールドを追加:

```
{"chatgpt": "<url or null>", "claude": "<url or null>", "gemini": "<url or null>", "error": "<reason>"}
```

途中報告や追加説明は絶対に出さない。Stage 1 の最終出力は JSON 1 行だけ。

### Stage 2 instructions

# Stage 2: 回答完了の待機 + レポート生成

## 入力 URL

- ChatGPT: <chatgpt_url>
- Claude: <claude_url>
- Gemini: <gemini_url>

## 実行手順

#### 1. 回答完了の待機（1 turn で完結させる）

ポーリング方式で待つ。1 回の長い `sleep` ではなく、短い sleep + チェックを繰り返す:

1. `sleep 20` （20 秒待機）
2. 各タブで `javascript_tool` を使って完了判定:
   - **ChatGPT**: `document.querySelector('button[data-testid="stop-button"]') === null`
   - **Claude**: `document.querySelector('button[aria-label="Stop response"]') === null`
   - **Gemini**: `document.querySelector('mat-icon[data-mat-icon-name="stop"]') === null`
   - 上記 selector が見つからなければ「停止ボタンなし = 完了」とみなす
   - selector が当てにならない場合は `get_page_text` で 2 連続スナップショットの差分が無いことで判定（fallback）
3. 全タブ完了 or ループ 6 回（=120 秒）に達したら抜ける
4. 完了したタブはそれ以上ポーリングしない

ポーリング中は途中報告を出さない、黙って続行。

#### 2. 回答の取得と比較

各タブから最後のアシスタントメッセージを抽出し、**最終応答**として以下の markdown を返す:

```markdown
## 質問
（再掲）

## 概要
3 社の回答を読んだ上での、さらっとシンプルな結論。
- 2〜4 行程度で全体像を要約
- 共通して言われている結論、もしくは「総合的にはこういう答え」を端的に
- 詳細は下の各社回答で確認できることを暗黙の前提に

## ChatGPTの回答
（要約 or 全文）

## Claudeの回答
（要約 or 全文）

## Geminiの回答
（要約 or 全文）

## 比較・所見
- 共通点
- 各社で異なる点・独自視点
- 回答の質・精度

## タブ URL
- ChatGPT: <url>
- Claude: <url>
- Gemini: <url>
```

**重要**: 「概要」セクションは 3 社全部の回答を読み終えてから書くこと。投げて返ってきた順に書くのではなく、すべて出揃ってから統合的にまとめる。

## タブの扱い

タブは閉じない。終了後も 3 タブはそのまま残す（ユーザーが手動で確認・追加質問できるように）。タブが溜まる懸念より、ユーザーが結果を直接見られる利便性を優先。

## エラー時の挙動

- レートリミット・回答取得エラー → そのサイトはスキップして残り 2 社でレポートを作成、末尾に明記
- 入力 URL が `null` のサイト → ポーリング・抽出をスキップし、レポートの「## タブ URL」では `n/a (Stage 1 で失敗)` と記載
