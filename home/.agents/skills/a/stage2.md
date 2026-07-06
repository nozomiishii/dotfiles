# /a Stage 2: 回答完了の待機 + レポート生成

## 質問内容

{{QUESTION}}

## 入力 URL

- ChatGPT: {{CHATGPT_URL}}
- Claude: {{CLAUDE_URL}}
- Gemini: {{GEMINI_URL}}

## 回答完了の待機（1 turn で完結させる）

ポーリング方式で待つ。1 回の長い `sleep` ではなく、短い sleep + チェックを繰り返す:

- `sleep 20`（20 秒待機）
- 各タブで `javascript_tool` を使って完了判定:
  - ChatGPT: `document.querySelector('button[data-testid="stop-button"]') === null`
  - Claude: `document.querySelector('button[aria-label="Stop response"]') === null`
  - Gemini: `document.querySelector('mat-icon[data-mat-icon-name="stop"]') === null`
  - 上記 selector が見つからなければ「停止ボタンなし = 完了」とみなす
  - selector が当てにならない場合は `get_page_text` で 2 連続スナップショットの差分が無いことで判定（fallback）
- 全タブ完了 or ループ 6 回（=120 秒）に達したら抜ける
- 完了したタブはそれ以上ポーリングしない

ポーリング中は途中報告を出さない。黙って続行。

## 回答の取得と比較

各タブから最後のアシスタントメッセージを抽出し、最終応答として以下の markdown を返す:

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

「概要」セクションは 3 社全部の回答を読み終えてから書くこと。投げて返ってきた順に書くのではなく、すべて出揃ってから統合的にまとめる。

## タブの扱い

タブは閉じない。終了後も 3 タブはそのまま残す（ユーザーが手動で確認・追加質問できるように）。タブが溜まる懸念より、ユーザーが結果を直接見られる利便性を優先。

## エラー時の挙動

- レートリミット・回答取得エラー → そのサイトはスキップして残り 2 社でレポートを作成、末尾に明記
- 入力 URL が `null` のサイト → ポーリング・抽出をスキップし、レポートの「## タブ URL」では `n/a (Stage 1 で失敗)` と記載
- この prompt に `gemini fast fallback` の記述があれば → レポート末尾に「Gemini は Fast で回答（Pro 切替失敗）」と明記
