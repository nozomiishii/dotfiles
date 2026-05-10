---
description: ChatGPT・Claude・Geminiに同じ質問を並列投下して回答を比較
argument-hint: <question>
allowed-tools:
  - mcp__claude-in-chrome__tabs_context_mcp
  - mcp__claude-in-chrome__tabs_create_mcp
  - mcp__claude-in-chrome__navigate
  - mcp__claude-in-chrome__find
  - mcp__claude-in-chrome__form_input
  - mcp__claude-in-chrome__computer
  - mcp__claude-in-chrome__read_page
  - mcp__claude-in-chrome__get_page_text
  - mcp__claude-in-chrome__javascript_tool
  - mcp__claude-in-chrome__read_console_messages
  - Bash(sleep:*)
---

# 3社並列質問タスク

Chrome拡張機能（Claude in Chrome）を使って、ChatGPT・Claude・Geminiに同じ質問を投げて、回答を比較する。

## 質問内容

$ARGUMENTS

## 実行手順

### 1. タブの準備

**常に新規タブを 3 つ作成する**。既存タブは再利用しない（並列セッションでの衝突防止）。`tabs_create_mcp` で返ってきた tab ID を 3 つとも記録し、以降のステップでは記録した tab ID のみを操作する。

- ChatGPT: `https://chatgpt.com/`
- Claude: `https://claude.ai/new`
- Gemini: `https://gemini.google.com/app`

各タブでログイン状態を確認する。ログイン画面が表示されている場合はその時点で停止してユーザーに知らせる（自動でログインしない）。

### 2. Tab groupへの追加

3つのタブをすべてClaudeのtab groupに入れる。

### 3. 質問送信

各タブの入力欄に上記質問を貼り付けて送信。3タブとも素早く済ませる。

各サイトの入力欄：

- **ChatGPT**: ページ下部のテキストエリア（`Ask anything` プレースホルダー）
- **Claude**: ページ下部のテキストエリア（`How can I help you today?` 付近）
- **Gemini**: ページ下部のテキストエリア（`Ask Gemini` プレースホルダー）

#### Gemini の追加手順（送信前にモデルを Pro へ切替）

Gemini はデフォルトで `Fast` モデルになっていることが多い。じっくり考えた回答が欲しいので **送信前に Pro へ切り替える**:

1. 入力欄右下にあるモデルセレクタ（現在のモデル名 + ▼ が表示されているボタン）を探す。`javascript_tool` でフォールバック付きで実装:

   ```js
   // モデルセレクタを開く
   const candidates = [...document.querySelectorAll('button')]
     .filter(b => /^(Fast|Thinking|Pro)\s*$/.test(b.textContent.trim()) || b.getAttribute('aria-label')?.match(/Fast|Thinking|Pro/));
   const opener = candidates[0];
   if (!opener) throw new Error('Gemini model selector not found');
   opener.click();
   ```

2. 少し待ってからメニュー内の `Pro` を選択:

   ```js
   await new Promise(r => setTimeout(r, 300));
   const items = [...document.querySelectorAll('[role="menuitemradio"], [role="menuitem"], button, li')];
   const pro = items.find(el => /\bPro\b/.test(el.textContent) && /Advanced|3\.\d Pro/.test(el.textContent));
   if (!pro) throw new Error('Pro option not found');
   pro.click();
   ```

3. 切替後、入力欄下部の表示が `Pro` になっているか `get_page_text` で軽く確認。なっていなければ手順 1〜2 をリトライ（最大 2 回）。

4. その後、質問を入力 → 送信。

selector が UI 変更で動かなくなった場合は `read_page` で現在の DOM を観察し、新しい selector に書き換えるか、`computer` でドロップダウン位置をクリックする方法に切り替える。それでも切替できない場合は `Fast` のまま続行し、報告書末尾で「Gemini は Fast で回答（Pro 切替失敗）」と明記する。

### 4. 回答完了の待機（重要：1 turn で完結させる）

**送信からこのステップ・次のステップ 5 まで、ユーザーへの中間報告で turn を終わらせず、続けて実行すること。**

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

ポーリング中はユーザーへ「待機中…」のような報告を挟まず、黙って続行する。

### 5. 回答の取得と比較

各タブから最後のアシスタントメッセージを抽出し、以下の形式で報告：

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
```

**重要**: 「概要」セクションは 3 社全部の回答を読み終えてから書くこと。投げて返ってきた順に書くのではなく、すべて出揃ってから統合的にまとめる。

## タブの扱い

タブは閉じない。終了後も 3 タブはそのまま残す（ユーザーが手動で確認・追加質問できるように）。タブが溜まる懸念より、ユーザーが結果を直接見られる利便性を優先。

## エラー時の挙動

- ログイン必要 → 停止して通知
- レートリミット・エラー → そのサイトはスキップして残り2社で続行、最後に報告
- Chrome拡張未接続 → `/chrome` で接続するよう案内
