#!/usr/bin/env bun
// クラウドセッション URL または branch 名から、消えた worktree のローカルセッションを特定する。
// 1 件に絞れたら "<repo>\t<worktree_path>\t<uuid>" を stdout に出力。
// 複数候補・不在は stderr に出して非ゼロ終了。csr 関数 (.zsh/functions.zsh) から呼ばれる。
// 設計: https://github.com/nozomiishii/dotfiles/issues/1006

import { Glob } from "bun";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename } from "node:path";

const arg = process.argv[2];
if (!arg) {
  console.error("usage: csr-resolve.ts <claude-session-url|branch-name>");
  process.exit(2);
}

const projects = `${homedir()}/.claude/projects`;

// 入力判定: URL/session id らしき形なら URL モード(url フィールド)、それ以外は branch 名(gitBranch 完全一致)。
// branch 名が偶然 "session_" を含んでも URL モードに誤入しないよう、URL らしさで判定する。
// いずれも JSON フィールドの完全一致で照合するため、正規表現メタ文字の混入や本文言及の偽陽性が起きない。
const urlLike = /^(https?:\/\/|session_)/.test(arg) || arg.includes("claude.ai/code/");
const sid = urlLike ? (arg.match(/session_[A-Za-z0-9]+/)?.[0] ?? null) : null;
if (urlLike && !sid) {
  console.error(`csr: URL に session id が見つかりません: ${arg}`);
  process.exit(2);
}

type Sess = {
  uuid: string;
  cwd: string;
  forkedFrom: string | null;
  lastTs: string;
  humanTurns: number;
  snippet: string;
};

const matched: Sess[] = [];

for (const rel of new Glob("*/*.jsonl").scanSync(projects)) {
  const file = `${projects}/${rel}`;
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

    // 構造化フィールドでの確定マッチ。url は session id を完全一致で照合
    // （末尾スラッシュ/クエリがあっても拾え、かつ id の前方一致誤マッチも防ぐ）。
    if (sid) {
      if (typeof d.url === "string" && d.url.match(/session_[A-Za-z0-9]+/)?.[0] === sid) hit = true;
    } else if (d.gitBranch === arg) {
      hit = true;
    }

    if (typeof d.cwd === "string" && !cwd) cwd = d.cwd;
    if (d.forkedFrom?.sessionId && !forkedFrom) forkedFrom = d.forkedFrom.sessionId;
    // 行順に依存せず真の最大 timestamp を取る（末尾が summary 等で非時系列でも正しい）。
    if (typeof d.timestamp === "string" && d.timestamp > lastTs) lastTs = d.timestamp;

    // 人間ターンのみ数える（Claude は tool_result も type:"user" で保存するため content で判定）。
    if (d.type === "user") {
      const c: unknown = d.message?.content;
      const human =
        typeof c === "string"
          ? c.trim().length > 0
          : Array.isArray(c)
            ? c.some((x) => x?.type === "text")
            : false;
      if (human) {
        humanTurns++;
        if (!snippet) {
          const t =
            typeof c === "string"
              ? c
              : (c as { type?: string; text?: string }[])
                  .filter((x) => x?.type === "text")
                  .map((x) => x.text ?? "")
                  .join(" ");
          const s = t.replace(/\s+/g, " ").trim();
          if (s) snippet = s.slice(0, 60);
        }
      }
    }
  }

  if (!hit || !cwd) continue;
  matched.push({ uuid: basename(file, ".jsonl"), cwd, forkedFrom, lastTs, humanTurns, snippet });
}

if (matched.length === 0) {
  console.error(`csr: no session found for: ${arg}`);
  process.exit(1);
}

// cwd 内を fork lineage でまとめ、各 lineage の代表(最新 last_ts)を返す。
// 親が matched 集合に無くても forkedFrom の uuid を lineage key にして兄弟 fork を畳む。
function lineageReps(sessions: Sess[]): Sess[] {
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
  // 代表 = 最新 last_ts（同点は human turns が多い方 = よりフルな履歴）。
  return [...groups.values()].map((members) =>
    members.reduce((a, b) =>
      b.lastTs > a.lastTs || (b.lastTs === a.lastTs && b.humanTurns > a.humanTurns) ? b : a,
    ),
  );
}

const byCwd = new Map<string, Sess[]>();
for (const s of matched) {
  const g = byCwd.get(s.cwd);
  if (g) g.push(s);
  else byCwd.set(s.cwd, [s]);
}

const reps: Sess[] = [];
for (const sessions of byCwd.values()) reps.push(...lineageReps(sessions));

// 人間ターン 0 の lineage（teleport stub 等）は、本物の候補が他にあればノイズとして落とす。
// 実際の会話を持つ（humanTurns>0）lineage は決して隠さない。
const withHuman = reps.filter((s) => s.humanTurns > 0);
const cands = withHuman.length ? withHuman : reps;

const repoOf = (cwd: string) => cwd.replace(/\/\.claude\/worktrees\/[^/]+$/, "");

if (cands.length === 1) {
  const s = cands[0]!;
  process.stdout.write(`${repoOf(s.cwd)}\t${s.cwd}\t${s.uuid}\n`);
} else {
  // 別物のセッションが複数 → 自動で選ばず、人間ターン数・日付・抜粋つきで候補を提示。
  console.error("csr: 複数候補があります。branch 名で絞って再実行してください:");
  cands.sort((a, b) => b.lastTs.localeCompare(a.lastTs));
  for (const s of cands) {
    const slug = basename(s.cwd);
    const repo = basename(repoOf(s.cwd));
    const date = s.lastTs.slice(0, 10);
    console.error(
      `  ${slug.padEnd(26)} ${repo.padEnd(12)} ${date}  ${String(s.humanTurns).padStart(3)}turns  ${s.snippet}`,
    );
  }
  process.exit(1);
}
