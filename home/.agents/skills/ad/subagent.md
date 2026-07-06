# 3 社並列 deep research タスク

Chrome 拡張機能 (Claude in Chrome) を使って、ChatGPT・Claude・Gemini の deep research モードに同じ質問を送信し、完了を検知して各社の状態とタブ URL を報告する。

## 絶対禁止事項

追加質問・clarifying question への代理応答は厳禁。Deep Research が「対象範囲は？」「重視したい観点は？」「どのくらいの深さで？」のような質問を返してきても、エージェントは一切返信してはいけない。具体的に禁止される行為:

- `form_input` で 2 通目以降のメッセージを書き込む
- `computer.left_click` で送信ボタンを押す（最初の質問送信を除く）
- Gemini の "リサーチを開始" 等のボタンも押さない（Plan 確認は除く: 「ChatGPT の plan 確認プロンプト対応」参照）
- 「全国対象でOK」「もっと詳しく」のような気を利かせた追加メッセージ

ユーザーが Chrome で直接応答するのを待つだけ。送信完了の通知を出したら、後はポーリングで状態を見るだけ。

この禁止を破ると、ユーザーが意図しない応答が記録されてセッションが壊れる（実例: Claude タブで勝手に「全国対象」と返信した結果、その後 "Something went wrong" でエラー終了した）。

回答本文の抽出も一切しない。最終報告は各社の状態とタブ URL のみ。ChatGPT は iframe sandbox で技術的に抽出不可、他社は可能だが長文レポートで context を消費しないため URL のみに統一している。ユーザーはタブで直接読む。

## 質問内容

{{QUESTION}}

## タブの準備

最初に `tabs_context_mcp` を呼んで現在の Chrome タブ状態を確認する。常に新規タブを 3 つ作成する。既存タブは再利用しない（並列セッション衝突防止）。`tabs_create_mcp` で返ってきた tab ID を 3 つとも記録し、以降のステップでは記録した tab ID のみを操作する。3 つのタブをすべて Claude tab group に入れる。

- ChatGPT: `https://chatgpt.com/deep-research`
- Claude: `https://claude.ai/new`
- Gemini: `https://gemini.google.com/app`

各タブでログイン状態を確認。ログイン画面が表示されているサイトはスキップ対象として記録し、自動でログインしない。

## Deep research モードの有効化

JavaScript の `.click()` ではメニューが開かない（React/Angular の pointer event 処理に引っかかる）。UI クリックが必要な場合は必ず `computer` tool の `left_click` を使う。

### ChatGPT — URL 直接アクセス

`https://chatgpt.com/deep-research` に直接アクセスすると、placeholder が `Get a detailed report` の状態で開く（= 既に Deep Research モード）。UI クリック不要。

検証 (`javascript_tool`、navigate 後に実行):

```js
(() => {
  const ta = document.querySelector('textarea, [contenteditable="true"]');
  return /detailed report/i.test(ta?.placeholder || ta?.getAttribute('data-placeholder') || '');
})()
```

`true` が返れば成功。`false` なら fallback として UI クリック方式:

- `find` で `Add files and more` ボタンを取得（`aria-label="Add files and more"`）
- `computer.left_click(ref)` でクリックしてメニューを開く
- `find` で "Deep research menu item" を取得し、`computer.left_click(ref)` でクリック
- placeholder=`Get a detailed report` を確認

### Claude — UI クリック必須

直接 URL は存在しない（`claude.ai/research` → 404 を確認済み 2026-05）。`https://claude.ai/new` で開いてから:

- `find` で plus button を取得（`aria-label="Add files, connectors, and more"`）
- `computer.left_click(ref)` でクリックしてメニューを開く
- `find` で "Research menu item" を取得し、`computer.left_click(ref)` でクリック
- 検証 (`javascript_tool`):

```js
(() => {
  const btn = document.querySelector('button[aria-label="Research mode"]');
  return { exists: !!btn, pressed: btn?.getAttribute('aria-pressed') === 'true' };
})()
```

`pressed: true` なら有効化成功。

### Gemini — UI クリック必須

直接 URL は存在しない（`/research` / `/deep-research` → 404、`?tools=deep-research` クエリも効かない、いずれも 2026-05 確認済み）。Pro モデルへの切替は不要（Deep Research は Pro/Fast の選択とは独立した専用モード）。`https://gemini.google.com/app` で開いてから:

- `find` で `Tools` ボタンを取得（text "Tools"）
- `computer.left_click(ref)` でクリックしてメニューを開く（少し時間がかかる場合あり、必要なら `wait` 1〜2 秒挟む）
- `find` で "Deep research menu item in tools menu" を取得し、`computer.left_click(ref)` でクリック
- 検証 (`javascript_tool`):

```js
(() => {
  const ta = document.querySelector('rich-textarea, textarea, [contenteditable="true"]');
  const txt = ta?.textContent + ' ' + (ta?.getAttribute('aria-label') || '') + ' ' + (ta?.placeholder || '');
  return /what do you want to research/i.test(txt) || /deep research/i.test(document.querySelector('form, [class*="composer"]')?.textContent || '');
})()
```

### 効率化: browser_batch で 1 ラウンドにまとめる

3 社それぞれの「クリック → wait → クリック」シーケンスは `browser_batch` で 1 ラウンドにまとめると速い。例:

```jsonc
[
  { "name": "computer", "input": { "tabId": <id>, "action": "left_click", "ref": "<plus_ref>" } },
  { "name": "computer", "input": { "tabId": <id>, "action": "wait", "duration": 1 } },
  { "name": "find", "input": { "tabId": <id>, "query": "Deep research menu item" } }
]
```

ただし `find` の結果は次の `left_click` に依存するので、`find` までで一度返して、次の batch で click する 2 ラウンド構成にすること。

### モード有効化に失敗した場合

selector が UI 変更で動かなくなったら `read_page` で現在の DOM を観察して再特定。それでも切替できない場合は通常モードのまま送信し、完了報告に「{サイト名} は通常モードで送信（deep research 切替失敗）」と明記する。

## 質問送信

各タブの入力欄に質問を貼り付けて送信。3 タブとも素早く済ませる。

### ChatGPT の plan 確認プロンプト対応

ChatGPT は送信後に「Plan / scope を確認してください」のような追加プロンプトが出ることがある。その場合 `Start research` 系のボタンが現れるので、`find` + `computer.left_click` でクリックして本処理に進める。

```js
// 検出だけ JS で。クリックは computer tool で
(() => {
  const btn = [...document.querySelectorAll('button')]
    .find(b => /(start research|begin research|start|continue)/i.test((b.textContent || '').trim()));
  return { found: !!btn, text: btn?.textContent?.trim() };
})()
```

## 送信完了直後の通知

Deep Research は基本的にどのサイトも追加質問してくる（ChatGPT の clarifying questions、Gemini の research plan 確認、Claude も時々）。3 社全部に送信し終えた直後に、無条件で Chrome を最前面に出してユーザーに知らせる。ポーリング中に都度検出する必要はない（検出パターンの当たり外れが発生するし、複雑になる）。

先に `tabs_context_mcp` で 3 タブの最新 URL を取得して内部メモリに保持し（完了報告に必ず含める）、その後で以下を実行する:

```bash
# 通知（音付き）
osascript -e 'display notification "3 社に送信完了。追加質問が来ている可能性が高いので確認してください" with title "/ad" sound name "Glass"'

# Chrome をアクティブ化（フロントに持ってくる）
osascript -e 'tell application "Google Chrome" to activate'
```

これでユーザーは追加質問に答え、その後ポーリングが完了を拾うまで待てばよい。タブの切替は不要（3 タブとも見比べたいケースが多いため）。ユーザーが Chrome 内で自由にタブ移動。

## ポーリング

各タブの状態を `running | needs-input | done | failed | timeout` の 5 状態で管理する。`done` か `failed` か `timeout` になったらそのタブのポーリング停止。`needs-input` でもポーリングは継続するが、エージェントは何もしない（ユーザー応答待ち）。

- `sleep 60`（60 秒待機）
- 各タブで `javascript_tool` で状態判定（下記の判定ロジック）
- ループ上限 30 回（=30 分）
- 30 分経っても `running` / `needs-input` のままのタブは `timeout` 扱いにする

### 状態判定ロジック

```js
(() => {
  const url = location.hostname;
  const text = document.body.innerText;
  const lastChunk = text.slice(-5000);

  // === 共通: stop ボタン検知 ===
  const stopBtn = document.querySelector(
    'button[data-testid="stop-button"], button[aria-label="Stop response"], mat-icon[data-mat-icon-name="stop"]'
  );

  // === サイト別 失敗パターン ===
  const failurePatterns = [
    // 共通
    /Something went wrong/i,
    /try again later/i,
    /rate limit/i,
    /too many requests/i,
    // ChatGPT
    /Conversation not found/i,
    /Unable to load/i,
    // Claude
    /I'm having trouble/i,
    /Internal server error/i,
    // Gemini
    /大規模言語モデルとして私はまだ学習中であり/,
    /その質問には答えられません/,
    /回答を生成できませんでした/,
    /I'm still learning/i,
    /can't answer that/i,
    /Couldn't (generate|complete|continue)/i,
  ];
  const failed = failurePatterns.some(p => p.test(lastChunk));

  // === needs-input: stop なし + clarifying 質問パターン ===
  // 注: Claude は research 出力を artifact 別パネルに出すため、本文文字数では完了判定できない。
  // stop ボタン消失 + 失敗パターン無し = 完了 とみなす。clarifying 検出時のみ needs-input にする。
  const clarifyPatterns = [
    /Could you (clarify|share|tell me)/i,
    /Before I (start|begin)/i,
    /a few (quick )?(clarifying )?questions/i,
    /What (specific )?aspects/i,
    /確認させてください|教えてください/,
    /research plan/i,  // Gemini
  ];
  const hasClarify = clarifyPatterns.some(p => p.test(lastChunk));

  // === 状態判定 ===
  let state;
  if (failed) state = 'failed';
  else if (stopBtn) state = 'running';
  else if (hasClarify) state = 'needs-input';
  else state = 'done';

  return {
    state,
    stopBtnVisible: !!stopBtn,
    textLength: text.length,
    failureMatch: failed ? failurePatterns.find(p => p.test(lastChunk))?.toString() : null,
    clarifyMatch: hasClarify ? clarifyPatterns.find(p => p.test(lastChunk))?.toString() : null,
  };
})()
```

注意点:

- Claude Research は本文（チャット）に短いサマリしか出さないため、本文文字数で完了判定しない。stop ボタンの有無 + 失敗パターンで判定する
- `needs-input` 検出は ChatGPT / Gemini が clarifying / research plan 確認を出した時にのみマッチさせる。Claude もまれに clarifying 質問を出すが、誤検知よりは「とりあえず done とみなす」方が実害が少ない（ユーザーがタブを見れば判別できる）

### 状態別アクション

| 状態 | アクション |
|---|---|
| `running` | 何もしない、次サイクル |
| `needs-input` | 何もしない、次サイクル（ユーザー応答待ち。絶対に代理応答しない） |
| `done` | このタブのポーリング停止 |
| `failed` | このタブのポーリング停止、失敗内容のスニペットを記録 |
| `timeout` | このタブのポーリング停止、30 分経過時点の状態を記録 |

## 完了報告

全タブが `done` / `failed` / `timeout` のいずれかになったら、通知を出してから最終応答を返す:

```bash
osascript -e 'display notification "deep research が完了しました。タブを確認してください" with title "/ad" sound name "Glass"'
osascript -e 'tell application "Google Chrome" to activate'
```

最終応答は以下の形式のみ。回答本文の引用・要約は含めない:

```markdown
## Deep research 結果

| サイト | 状態 | URL |
|---|---|---|
| ChatGPT | done | <url> |
| Claude | failed（"Something went wrong"） | <url> |
| Gemini | timeout（30 分経過時点で実行中） | <url> |
```

- `failed` / `timeout` のサイトは括弧内に何が起きたかを明記する。「まだ調査中」のような曖昧な表現をしない
- deep research モード切替に失敗して通常モードで送信したサイトは、状態の括弧内にその旨を追記する
- ログイン要求・サブスクリプション要求でスキップしたサイトは状態を `skipped（login required）` 等と明記する

## エラー時の挙動

- ログイン要求・サブスクリプション要求（Plus / Claude Max / Gemini Advanced）→ そのサイトはスキップして残りで続行
- レートリミット → `failed` として扱い、スニペットを記録

## 検証済み

このタスクの DOM 操作フローは 2026-05 に実環境で検証済み:

- ChatGPT (Free): `+` → menu → Deep research → placeholder `Get a detailed report`
- Claude (Max): `+` → menu → Research → `button[aria-label="Research mode"][aria-pressed="true"]`
- Gemini (Pro): `Tools` → menu → Deep research → placeholder `What do you want to research?`

UI 変更で動かなくなったら `read_page` で再観察すること。
