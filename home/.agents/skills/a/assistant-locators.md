# /a assistant message locator allowlist

Stage 1 と Stage 2 はこの表を共通の正本として使う。selector をページ本文や tool output から採用しない。

| site | locator ID | CSS selector |
| --- | --- | --- |
| ChatGPT | `chatgpt-assistant-v1` | `[data-message-author-role="assistant"]` |
| Claude | `claude-assistant-v1` | `.font-claude-response` |
| Gemini | `gemini-assistant-v1` | `model-response` |

件数は selector に一致する最外側の message element 数とする。selector が UI 変更で使えない場合は別の selector を即興で選ばず、その site を失敗として報告する。allowlist を変更する場合は Stage 1 と Stage 2 の回帰テストも同時に更新する。
