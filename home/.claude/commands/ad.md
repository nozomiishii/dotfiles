---
description: /a を deep research モードで実行する
argument-hint: <question>
allowed-tools:
  - Agent
---

# /ad wrapper

このコマンドは Sonnet サブエージェントで実行する。親セッションが Opus 1M でも、サブエージェントは Sonnet 標準 context で走るので Extra Usage 課金 (1M Sonnet) を踏まない。

## 親セッションが行うこと（最優先）

**今すぐ Agent tool を 1 回呼ぶ**。中間説明や事前確認は不要、即 dispatch する:

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"3社並列 deep research"`
- `prompt`: 下記「## Subagent execution」セクション（この見出しを含む下のすべて）の本文。`$ARGUMENTS` はそのまま渡してよい。

サブエージェントの戻り値（3 社の deep research レポート）をそのままユーザーに表示して終了。

---

## Subagent execution

# /ad (deep research モード)

まず最初に `Read` で `/Users/nozomiishii/.claude/commands/a.md` を開き、`## Subagent execution` セクション以降の手順を **基本ワークフロー** として把握する。`/a` 側は `### Stage 1 instructions` と `### Stage 2 instructions` の 2 段構成になっているが、`/ad` ではこのサブエージェント 1 つで両 stage を直列実行する（Stage 1 で得る URL は内部で保持して Stage 2 に流す。途中で別 dispatch には分けない）。Stage 1 の「JSON 1 行だけ返す」制約はサブエージェント間 IPC 用なので `/ad` では無視し、基本的な挙動・タブ準備・送信・回答取得・レポート構成のみ参考にする。

そのうえで、以下の差分を適用する。

## ⚠️ 絶対禁止事項

**追加質問・clarifying question への代理応答は厳禁**。Deep Research が「対象範囲は？」「重視したい観点は？」「どのくらいの深さで？」のような質問を返してきても、エージェントは **一切返信してはいけない**。具体的に禁止される行為:

- `form_input` で 2 通目以降のメッセージを書き込む
- `computer.left_click` で送信ボタンを押す（最初の質問送信を除く）
- Gemini の "リサーチを開始" 等のボタンも押さない（Plan 確認は除く: `### 3` 参照）
- 「全国対象でOK」「もっと詳しく」のような気を利かせた追加メッセージ

ユーザーが Chrome で直接応答するのを待つだけ。エージェントは Step 4 の通知を出したら、後はポーリングで状態を見るだけ。

この禁止を破ると、ユーザーが意図しない応答が記録されてセッションが壊れる（実例: Claude タブで勝手に「全国対象」と返信した結果、その後 "Something went wrong" でエラー終了した）。

## 質問内容

$ARGUMENTS

## /a との差分

### 1. 各社の deep research モードを有効化してから送信

**重要**: JavaScript の `.click()` ではメニューが開かない（React/Angular の pointer event 処理に引っかかる）。UI クリックが必要な場合は **必ず `computer` tool の `left_click` を使う**。

各社で確認済みのフロー:

#### ChatGPT — URL 直接アクセス（推奨・実証済み）

`/a` の Step 1 でデフォルト `https://chatgpt.com/` を指定しているが、`/ad` では **`https://chatgpt.com/deep-research` を使う**。このページに直接アクセスすると、placeholder が `Get a detailed report` の状態で開く（= 既に Deep Research モード）。UI クリック不要。

```
ChatGPT 用 URL: https://chatgpt.com/deep-research
```

検証 (`javascript_tool`、navigate 後に実行):

```js
(() => {
  const ta = document.querySelector('textarea, [contenteditable="true"]');
  return /detailed report/i.test(ta?.placeholder || ta?.getAttribute('data-placeholder') || '');
})()
```

`true` が返れば成功。`false` なら fallback として下記の UI クリック方式へ:

1. `find` で `Add files and more` ボタンを取得（`aria-label="Add files and more"`）
2. `computer.left_click(ref)` でクリック → menu 開く
3. `find` で "Deep research menu item" を取得
4. `computer.left_click(ref)` でクリック
5. placeholder=`Get a detailed report` を確認

#### Claude — UI クリック必須

直接 URL は **存在しない**（`claude.ai/research` → 404 を確認済み 2026-05）。`/a` のデフォルト URL `https://claude.ai/new` で開いてから UI 操作:

1. `find` で plus button を取得（`aria-label="Add files, connectors, and more"`）
2. `computer.left_click(ref)` でクリック → menu 開く
3. `find` で "Research menu item" を取得
4. `computer.left_click(ref)` でクリック
5. 検証 (`javascript_tool`):
   ```js
   (() => {
     const btn = document.querySelector('button[aria-label="Research mode"]');
     return { exists: !!btn, pressed: btn?.getAttribute('aria-pressed') === 'true' };
   })()
   ```
   `pressed: true` なら有効化成功。

#### Gemini — UI クリック必須

直接 URL は **存在しない**（`/research` / `/deep-research` → 404、`?tools=deep-research` クエリも効かない、いずれも 2026-05 確認済み）。`/a` のデフォルト URL `https://gemini.google.com/app` で開いてから UI 操作:

1. `find` で `Tools` ボタンを取得（text "Tools"）
2. `computer.left_click(ref)` でクリック → menu 開く（**少し時間がかかる場合あり**、必要なら `wait` 1〜2 秒挟む）
3. `find` で "Deep research menu item in tools menu" を取得
4. `computer.left_click(ref)` でクリック
5. 検証 (`javascript_tool`):
   ```js
   (() => {
     const ta = document.querySelector('rich-textarea, textarea, [contenteditable="true"]');
     const txt = ta?.textContent + ' ' + (ta?.getAttribute('aria-label') || '') + ' ' + (ta?.placeholder || '');
     return /what do you want to research/i.test(txt) || /deep research/i.test(document.querySelector('form, [class*="composer"]')?.textContent || '');
   })()
   ```

#### 効率化: browser_batch で 1 ラウンドにまとめる

3 社それぞれの「クリック → wait → クリック」シーケンスは `browser_batch` で 1 ラウンドにまとめると速い。例:

```jsonc
[
  { "name": "computer", "input": { "tabId": <id>, "action": "left_click", "ref": "<plus_ref>" } },
  { "name": "computer", "input": { "tabId": <id>, "action": "wait", "duration": 1 } },
  { "name": "find", "input": { "tabId": <id>, "query": "Deep research menu item" } }
]
```

ただし `find` の結果は次の `left_click` に依存するので、`find` までで一度返して、次の batch で click する 2 ラウンド構成にすること。

#### モード有効化に失敗した場合

selector が UI 変更で動かなくなったら `read_page` で現在の DOM を観察して再特定。それでも切替できない場合は **通常モードのまま送信** し、レポート末尾の補足セクションに「{サイト名} は通常モードで回答（deep research 切替失敗）」と明記。

### 2. Gemini の Pro モデル切替はスキップ

`/a` のステップ 3 にある Pro モデル切替手順は `/ad` では **不要**（Deep Research は Pro/Fast の選択とは独立した専用モードのため）。

### 3. ChatGPT の plan 確認プロンプト対応

ChatGPT は送信後に「Plan / scope を確認してください」のような追加プロンプトが出ることがある。その場合 `Start research` 系のボタンが現れるので、`find` + `computer.left_click` でクリックして本処理に進める。

```js
// 検出だけ JS で。クリックは computer tool で
(() => {
  const btn = [...document.querySelectorAll('button')]
    .find(b => /(start research|begin research|start|continue)/i.test((b.textContent || '').trim()));
  return { found: !!btn, text: btn?.textContent?.trim() };
})()
```

### 4. 送信完了直後に Chrome をフロントへ

Deep Research は **基本的にどのサイトも追加質問してくる** （ChatGPT の clarifying questions、Gemini の research plan 確認、Claude も時々）。なので 3 社全部に送信し終えた直後に、無条件で Chrome を最前面に出してユーザーに知らせる。

ポーリング中に都度検出する必要はない（その方式だと検出パターンの当たり外れが発生するし、複雑になる）。

**順序**: 先に `tabs_context_mcp` で 3 タブの最新 URL を取得して内部メモリに保持し（Stage 2 で使う & 最終レポートの「## タブ URL」に必ず含める）、その**後**で以下の Chrome フォーカス + 通知を実行する。途中の chat 表示は `/ad` では不可（サブエージェント直列実行のため）なので、URL は最終レポートにのみ載る点を許容する。

**送信完了直後（ポーリング開始前）に実行**:

```bash
# 通知（音付き）
osascript -e 'display notification "3 社に送信完了。追加質問が来ている可能性が高いので確認してください" with title "/ad" sound name "Glass"'

# Chrome をアクティブ化（フロントに持ってくる）
osascript -e 'tell application "Google Chrome" to activate'
```

これでユーザーは追加質問に答え、その後ポーリングが完了を拾うまで待てばよい。

タブの切替は不要（3 タブとも見比べたいケースが多いため）。ユーザーが Chrome 内で自由にタブ移動。

### 5. ポーリング設定を deep research 向けに延長

各タブの状態を `running | needs-input | done | failed | timeout` の **5 状態** で管理する。`done` か `failed` か `timeout` になったらそのタブのポーリング停止。`needs-input` でもポーリングは継続するが、エージェントは何もしない（ユーザー応答待ち）。

- `sleep 60` （60 秒待機）
- 各タブで `javascript_tool` で状態判定（後述の判定ロジック）
- ループ上限 30 回（=30 分）
- 30 分経っても `running` / `needs-input` のままのタブは `timeout` 扱い、その時点の状態を抽出してレポートに含める

#### 状態判定ロジック

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

**注意点**:

- Claude Research は **本文（チャット）に短いサマリ + artifact パネルに長文レポート** を出すため、`body.innerText.length` で完了判定するのは不可。stop ボタンの有無 + 失敗パターンの 3 値で判定する
- `needs-input` 検出は ChatGPT / Gemini が clarifying / research plan 確認を出した時にのみマッチさせる。Claude もまれに clarifying 質問を出すが、誤検知よりは「とりあえず done として artifact を読みに行く」方が実害が少ない（artifact 見れば判別できる）

#### 状態別アクション

| 状態 | アクション |
|---|---|
| `running` | 何もしない、次サイクル |
| `needs-input` | 何もしない、次サイクル（ユーザー応答待ち。**絶対に代理応答しない**） |
| `done` | このタブのポーリング停止、回答抽出 |
| `failed` | このタブのポーリング停止、レポートに「{サイト名}: 失敗（{失敗内容のスニペット}）」と記載 |
| `timeout` | このタブのポーリング停止、レポートに「{サイト名}: 30 分経過時の状態を引用」 |

最終レポートでは **failed / timeout のサイトも何があったかを明記**。「まだ調査中」のような誤情報を出さない。

### 6. 回答取得とレポートの差分

#### サイト別 本文取得方法（実証済み 2026-05）

##### Claude: artifact パネル

Claude Research は本文（チャット）には短いサマリしか書かず、研究レポート本体は **artifact パネル** に出る。

```js
// 既にパネル開いてるか確認
(() => {
  const panel = document.querySelector('[role="region"][aria-label^="Artifact panel:"]');
  return { panelOpen: !!panel, panelTextLen: panel?.innerText?.length || 0 };
})()
```

閉じている場合: `button[aria-label^="View "]` を `find` → `computer.left_click(ref)` → 2 秒待機 → 上記 JS で抽出。

抽出:

```js
(() => {
  const panel = document.querySelector('[role="region"][aria-label^="Artifact panel:"]');
  if (!panel) return { error: 'panel not open' };
  return {
    title: panel.getAttribute('aria-label').replace(/^Artifact panel:\s*/, ''),
    body: panel.innerText,
    bodyLength: panel.innerText.length,
  };
})()
```

検証実績: 10,352 字取得成功（`日本全国・月単位（マンスリー）滞在おすすめ宿泊先ガイド` レポート）。

##### Gemini: message-content の最後の要素

Gemini Deep Research は **`<message-content>` カスタム要素** の最後（最新返答）に研究レポート全文が入る。

```js
(() => {
  const mcs = [...document.querySelectorAll('message-content')]
    .filter(el => el.offsetParent !== null);
  if (!mcs.length) return { error: 'no message-content' };
  // 一番長い (=本体レポート) を取る
  const longest = mcs.reduce((a, b) => (a.innerText.length >= b.innerText.length ? a : b));
  return {
    body: longest.innerText,
    bodyLength: longest.innerText.length,
  };
})()
```

検証実績: 7,527 字取得成功（`リズム解析とビート同期型静止画抽出によるダンス振付学習の革新` レポート）。

注: `<message-content>` には plan 確認 (~700 字) と "Completed" 通知 (~80 字) も含まれるので、**最長要素** をターゲットにすること。

##### ChatGPT: 自動取得不可（iframe sandbox 制約）

ChatGPT Deep Research の本体は **sandboxed iframe** に隔離されており、`contentDocument` も `get_page_text` も `read_page` (accessibility tree) も透過しない。aria tree には `internal://deep-research` という placeholder のみ。

エージェントから自動抽出する手段は無いので、レポートでは **URL の提示のみ** を行い、本文取得を試みない:

```markdown
## ChatGPT の回答
**注**: ChatGPT Deep Research の本文は iframe sandbox により自動取得不可。
[直接タブで確認してください](<chatgpt url>)
```

可能な workaround:
- `button[aria-label="Copy response"]` クリック → クリップボードに入る（ただし `navigator.clipboard.readText()` は permission prompt で固まるので JS 取得は不可）
- ユーザーに「Copy response → チャットに貼り付け」を依頼する

`/ad` のデフォルト動作: ChatGPT は URL のみ提示。本文取得は試みない。

#### 共通の安全弁

新規メッセージ送信は **絶対に行わない**（先頭の絶対禁止事項）。失敗時は URL を提示してユーザーが直接見られるようにする。

#### レポート全般

`/a` のレポート構成をそのまま使うが、以下を意識する:

- **引用元 URL を保持**: 各社が示した一次情報源 URL は積極的に拾う
- **元レポートが長文の場合**: 見出しと結論のみで OK
- **補足セクションの追加**:
  - deep research モード切替に失敗したサイト
  - **`failed` 状態のサイト**: 失敗内容（"Something went wrong" / "答えられません" 等）を明記
  - **`timeout` 状態のサイト**: 30 分時点の状態と、確認用の Chrome タブ URL

## エラー時の挙動

`/a` と同じ。加えて:

- サブスクリプション要求（Plus / Claude Max / Gemini Advanced）→ そのサイトはスキップして残りで続行、最後に報告
- deep research モード切替失敗 → 通常モードで続行し補足に明記

## 検証済み

このコマンドの DOM 操作フローは 2026-05 に実環境で検証済み:

- ChatGPT (Free): `+` → menu → Deep research → placeholder `Get a detailed report`
- Claude (Max): `+` → menu → Research → `button[aria-label="Research mode"][aria-pressed="true"]`
- Gemini (Pro): `Tools` → menu → Deep research → placeholder `What do you want to research?`

UI 変更で動かなくなったら `read_page` で再観察すること。
