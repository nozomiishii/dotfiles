#!/usr/bin/env bun
// クラウドセッション URL または branch 名から、消えた worktree のローカルセッションを特定する。
// 候補を機械可読な TSV 行で列挙し、--preview <uuid> で末尾会話を整形出力する。
// 判定と副作用は csr 関数 (.zsh/functions.zsh) 側。設計: https://github.com/nozomiishii/dotfiles/issues/1006

import { Glob } from "bun";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename } from "node:path";

const PROJECTS = `${homedir()}/.claude/projects`;

export type Sess = {
  uuid: string;
  cwd: string;
  forkedFrom: string | null;
  lastTs: string;
  humanTurns: number;
  snippet: string;
};

// d.message.content からテキストブロックを抽出する（tool_result/thinking/tool_use は除外）。
export function messageText(d: Record<string, any>): string {
  const c: unknown = d?.message?.content;
  if (typeof c === "string") return c.trim();
  if (Array.isArray(c)) {
    return c
      .filter((x) => x?.type === "text" && typeof x.text === "string")
      .map((x) => x.text as string)
      .join("\n")
      .trim();
  }
  return "";
}

export type Msg = { role: "user" | "assistant"; text: string };

const PREVIEW_TAIL = 16; // preview に出す末尾メッセージ数（"末尾多め"。残りは fzf スクロールで追う）
const MSG_CAP = 1500; // 1 メッセージの上限（貼り付けログ等で preview が崩れるのを防ぐ）

// jsonl 全体から text の human/assistant メッセージを時系列で集め、cwd と最大 timestamp も返す。
export function collectMessages(text: string): { cwd: string; lastTs: string; messages: Msg[] } {
  let cwd = "";
  let lastTs = "";
  const messages: Msg[] = [];
  for (const line of text.split("\n")) {
    if (!line) continue;
    let d: Record<string, any>;
    try {
      d = JSON.parse(line);
    } catch {
      continue;
    }
    if (!d || typeof d !== "object") continue;
    if (typeof d.cwd === "string" && !cwd) cwd = d.cwd;
    if (typeof d.timestamp === "string" && d.timestamp > lastTs) lastTs = d.timestamp;
    if (d.type === "user" || d.type === "assistant") {
      const t = messageText(d);
      if (t) messages.push({ role: d.type, text: t });
    }
  }
  return { cwd, lastTs, messages };
}

// 末尾 tail 件を 👤/🤖 ラベル付きで整形。長い本文は cap で切り詰める。
export function formatPreview(header: string, messages: Msg[], tail = PREVIEW_TAIL, cap = MSG_CAP): string {
  const body = messages
    .slice(-tail)
    .map((m) => {
      const label = m.role === "user" ? "👤" : "🤖";
      const text = m.text.length > cap ? `${m.text.slice(0, cap)} …(略)` : m.text;
      return `${label} ${text}`;
    })
    .join("\n\n");
  return `${header}\n\n${body}\n`;
}

export const repoOf = (cwd: string) => cwd.replace(/\/\.claude\/worktrees\/[^/]+$/, "");

export function formatRow(s: Sess): string {
  const display = `${basename(s.cwd)}  ${s.lastTs.slice(0, 10)}  ${s.humanTurns}t  ${s.uuid.slice(0, 8)}`;
  return `${s.uuid}\t${repoOf(s.cwd)}\t${s.cwd}\t${display}`;
}

// cwd 内を fork lineage でまとめ、各 lineage の代表(最新 lastTs)を返す。
// 親が matched 集合に無くても forkedFrom の uuid を lineage key にして兄弟 fork を畳む。
export function lineageReps(sessions: Sess[]): Sess[] {
  const byUuid = new Map(sessions.map((s) => [s.uuid, s]));
  const rootOf = (s: Sess): string => {
    let cur = s;
    const seen = new Set<string>();
    while (cur.forkedFrom && !seen.has(cur.uuid)) {
      seen.add(cur.uuid);
      const parent = byUuid.get(cur.forkedFrom);
      if (!parent) return cur.forkedFrom; // 親が未ロード → 共通の親 uuid を lineage key にする。
      cur = parent;
    }
    return cur.uuid;
  };
  const groups = new Map<string, Sess[]>();
  for (const s of sessions) {
    const r = rootOf(s);
    const g = groups.get(r);
    if (g) g.push(s);
    else groups.set(r, [s]);
  }
  // 代表 = 最新 lastTs（同点は human turns が多い方 = よりフルな履歴）。
  return [...groups.values()].map((members) =>
    members.reduce((a, b) =>
      b.lastTs > a.lastTs || (b.lastTs === a.lastTs && b.humanTurns > a.humanTurns) ? b : a,
    ),
  );
}

// url|branch にマッチするセッションを ~/.claude/projects から収集して候補を返す。
function findCandidates(arg: string): { cands: Sess[]; error?: { msg: string; code: number } } {
  const urlLike = /^(https?:\/\/|session_)/.test(arg) || arg.includes("claude.ai/code/");
  const sid = urlLike ? (arg.match(/session_[A-Za-z0-9]+/)?.[0] ?? null) : null;
  if (urlLike && !sid) {
    return { cands: [], error: { msg: `csr: URL に session id が見つかりません: ${arg}`, code: 2 } };
  }

  const matched: Sess[] = [];
  for (const rel of new Glob("*/*.jsonl").scanSync(PROJECTS)) {
    const file = `${PROJECTS}/${rel}`;
    let text: string;
    try {
      text = readFileSync(file, "utf8");
    } catch {
      continue;
    }
    // 安価な pre-filter（リテラル文字列。正規表現なし）。
    if (sid ? !text.includes(sid) : !text.includes(`"gitBranch":"${arg}"`)) continue;

    let cwd = "";
    let forkedFrom: string | null = null;
    let lastTs = "";
    let humanTurns = 0;
    let snippet = "";
    let hit = false;

    for (const line of text.split("\n")) {
      if (!line) continue;
      let d: Record<string, any>;
      try {
        d = JSON.parse(line);
      } catch {
        continue;
      }
      if (!d || typeof d !== "object") continue; // 単独 null やプリミティブ行で field 参照が throw するのを防ぐ。

      // 構造化フィールドでの確定マッチ。url は session id を完全一致で照合。
      if (sid) {
        if (typeof d.url === "string" && d.url.match(/session_[A-Za-z0-9]+/)?.[0] === sid) hit = true;
      } else if (d.gitBranch === arg) {
        hit = true;
      }

      if (typeof d.cwd === "string" && !cwd) cwd = d.cwd;
      if (d.forkedFrom?.sessionId && !forkedFrom) forkedFrom = d.forkedFrom.sessionId;
      if (typeof d.timestamp === "string" && d.timestamp > lastTs) lastTs = d.timestamp;

      if (d.type === "user") {
        const t = messageText(d); // tool_result は除外されるので人間ターンのみ数える。
        if (t) {
          humanTurns++;
          if (!snippet) snippet = t.replace(/\s+/g, " ").trim().slice(0, 60);
        }
      }
    }

    if (!hit || !cwd) continue;
    matched.push({ uuid: basename(file, ".jsonl"), cwd, forkedFrom, lastTs, humanTurns, snippet });
  }

  if (matched.length === 0) {
    return { cands: [], error: { msg: `csr: no session found for: ${arg}`, code: 1 } };
  }

  const byCwd = new Map<string, Sess[]>();
  for (const s of matched) {
    const g = byCwd.get(s.cwd);
    if (g) g.push(s);
    else byCwd.set(s.cwd, [s]);
  }
  const reps: Sess[] = [];
  for (const sessions of byCwd.values()) reps.push(...lineageReps(sessions));

  // 人間ターン 0 の lineage（teleport stub 等）は本物が他にあれば落とす。実会話は決して隠さない。
  const withHuman = reps.filter((s) => s.humanTurns > 0);
  const cands = withHuman.length ? withHuman : reps;
  cands.sort((a, b) => b.lastTs.localeCompare(a.lastTs)); // 新しい順
  return { cands };
}

function resolveMode(arg: string): number {
  const { cands, error } = findCandidates(arg);
  if (error) {
    console.error(error.msg);
    return error.code;
  }
  // 1 件でも複数でも同じ行フォーマットで stdout に出す。判定は csr() 側。
  for (const s of cands) process.stdout.write(`${formatRow(s)}\n`);
  return 0;
}

function previewMode(uuid: string): number {
  let file = "";
  for (const rel of new Glob(`*/${uuid}.jsonl`).scanSync(PROJECTS)) {
    file = `${PROJECTS}/${rel}`;
    break;
  }
  if (!file) {
    console.error(`csr: session not found: ${uuid}`);
    return 1;
  }
  let text: string;
  try {
    text = readFileSync(file, "utf8");
  } catch {
    console.error(`csr: cannot read: ${file}`);
    return 1;
  }
  const { cwd, lastTs, messages } = collectMessages(text);
  const header = `${uuid.slice(0, 8)} · ${basename(cwd) || "?"} · ${lastTs.slice(0, 10) || "?"}`;
  process.stdout.write(formatPreview(header, messages));
  return 0;
}

if (import.meta.main) {
  const argv = process.argv.slice(2);
  if (argv[0] === "--preview") {
    if (!argv[1]) {
      console.error("usage: csr-resolve.ts --preview <uuid>");
      process.exit(2);
    }
    process.exit(previewMode(argv[1]));
  }
  if (!argv[0]) {
    console.error("usage: csr-resolve.ts <claude-session-url|branch-name>");
    process.exit(2);
  }
  process.exit(resolveMode(argv[0]));
}
