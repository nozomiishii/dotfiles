#!/usr/bin/env node
// gh に渡される PR タイトルを repo の commitlint 設定で検証する PreToolUse hook。
// Claude Code (settings.json) と Codex (hooks.json) が同じ実体を呼ぶ。
//
// 判定ルールは持たない。lefthook の commit-msg と同じ nozo-commitlint に流すため、
// 正本は repo の commitlint 設定 (既定は @nozomiishii/commitlint-config) 1 箇所だけになる。
//
// 手元で試すには PreToolUse の payload を stdin に渡す:
//   printf '{"cwd":"%s","tool_input":{"command":"gh pr create --title \\"docs: x\\""}}' "$PWD" |
//     node home/.agents/hooks/pr-title-guard.mjs

import { spawnSync } from "node:child_process";
import { accessSync, constants, realpathSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const PR_TITLE_COMMAND = /\bgh\b[\s\S]*\bpr\b[\s\S]*\b(?:create|edit)\b/;

/** gh の PR 作成・タイトル変更コマンドか。全シェル呼び出しで発火するため最初に切る。 */
export function isPrTitleCommand(command) {
  return PR_TITLE_COMMAND.test(command);
}

/**
 * gh に渡されたタイトルを取り出す。PR タイトルは空白を含むため必ずクォートされる。
 * クォート無しの値は拾わず素通りさせ、後段の CI に委ねる。
 */
export function extractTitle(command) {
  // --template の中の -t を短縮形と読まないよう、-t の前後を区切りで固定する。
  const matched = command.match(/(?:--title[= ]|(?:^|\s)-t )\s*(["'])([\s\S]*?)\1/);
  return matched ? matched[2] : null;
}

function isExecutable(path) {
  try {
    accessSync(path, constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

async function readStdin() {
  let text = "";
  for await (const chunk of process.stdin) text += chunk;
  return text;
}

async function main() {
  let payload;
  try {
    payload = JSON.parse(await readStdin());
  } catch {
    // payload を読めないときに作業を止めない。
    return 0;
  }

  const command = payload?.tool_input?.command ?? "";
  if (!isPrTitleCommand(command)) return 0;

  const cwd = payload?.cwd ?? "";
  const linter = join(cwd, "node_modules/.bin/nozo-commitlint");
  // commitlint を持たない repo には判定材料がないので素通りする。入れ忘れは CI 側で落ちる。
  if (!isExecutable(linter)) return 0;

  const title = extractTitle(command);
  if (!title) return 0;

  const result = spawnSync(linter, { input: title, encoding: "utf8", cwd });
  if (result.status === 0) return 0;

  const detail = `${result.stdout ?? ""}${result.stderr ?? ""}`.trim();
  process.stderr.write(`PR タイトルが repo の commitlint 設定に違反しています。\n\n${detail}\n`);
  return 2;
}

// stow のシンボリックリンク越しに呼ばれるため、実体パスで直接実行かを判定する。
const entry = process.argv[1];
if (entry && realpathSync(entry) === realpathSync(fileURLToPath(import.meta.url))) {
  process.exitCode = await main();
}
