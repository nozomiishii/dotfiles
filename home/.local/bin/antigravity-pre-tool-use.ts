#!/usr/bin/env bun
import { readFileSync, realpathSync } from "node:fs";
import { homedir, userInfo } from "node:os";
import { basename, join, normalize } from "node:path";

export type Decision = {
  decision: "allow" | "deny" | "ask";
  reason?: string;
};

export type DenyRule =
  | { kind: "binary"; binary: string; raw: string }
  | { kind: "prefix"; binary: string; posSpecs: string[]; flagSpecs: string[]; raw: string }
  | { kind: "glob"; binary: string; subcommand: string; pattern: RegExp; raw: string }
  | { kind: "rm_target"; binary: "rm"; target: "/" | "~"; raw: string };

const SHELL_BINARIES = new Set(["sh", "bash", "zsh", "dash", "ksh"]);
const SHELL_KEYWORDS = new Set(["!", "if", "then", "elif", "else", "do", "coproc", "{", "}"]);

const ENV_ASSIGN_RE = /^[A-Za-z_][A-Za-z0-9_]*=/;
const REDIR_OP_ONLY_RE = /^(?:\d+)?(?:<<<|<<-?|>>|<>|>&|<&|>\|?|<)$/;
const REDIR_WITH_TARGET_RE = /^(?:\d+)?(?:<<<|<<-?|>>|<>|>&|<&|>\|?|<).+$/;
const INPUT_REDIR_RE = /^(?:\d+)?(?:<<<|<<-?|<>|<&|<)/;
const HEREDOC_START_RE = /^<<(-?)\s*(?:'([^']+)'|"([^"]+)"|([A-Za-z_][A-Za-z0-9_]*))/;

const GIT_OPTS_WITH_ARG = new Set([
  "-C",
  "-c",
  "--git-dir",
  "--work-tree",
  "--namespace",
  "--super-prefix",
  "--config-env",
  "--exec-path",
]);

const GH_OPTS_WITH_ARG = new Set([
  "-R",
  "--repo",
  "-H",
  "--hostname",
  "-X",
  "--method",
  "-f",
  "--raw-field",
  "-F",
  "--field",
  "-q",
  "--jq",
  "-t",
  "--template",
  "--input",
  "--cache",
]);

const XARGS_OPTS_WITH_ARG = new Set([
  "-I",
  "-J",
  "-L",
  "-n",
  "-P",
  "-R",
  "-S",
  "-s",
  "-E",
  "-d",
  "-a",
  "--replace",
  "--max-args",
  "--max-lines",
  "--max-procs",
  "--max-chars",
  "--eof",
  "--delimiter",
  "--arg-file",
]);

const TIMEOUT_OPTS_WITH_ARG = new Set(["-k", "--kill-after", "-s", "--signal"]);

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function globToRegExp(glob: string): RegExp {
  const parts = glob.split("*").map(escapeRegExp);
  return new RegExp(`^(?:https?://[^/]+/|/)?${parts.join(".*")}$`);
}

function safeHomeDir(): string {
  const h = homedir();
  try {
    return realpathSync(h);
  } catch {
    return h;
  }
}

export function parseClaudeDenyRules(denyList: unknown): DenyRule[] {
  if (!Array.isArray(denyList)) return [];

  const rules: DenyRule[] = [];
  for (const entry of denyList) {
    if (typeof entry !== "string") continue;
    const match = /^Bash\((.+)\)$/.exec(entry);
    if (!match) continue;

    const inner = match[1].trim();
    const hasPrefixWildcard = inner.endsWith(":*") || inner.endsWith(" *");
    const body = inner.endsWith(":*")
      ? inner.slice(0, -2).trim()
      : inner.endsWith(" *")
        ? inner.slice(0, -2).trim()
        : inner;
    const parts = body.split(/\s+/).filter(Boolean);
    if (parts.length === 0) continue;

    const binary = parts[0];

    if (parts.length === 1) {
      rules.push({ kind: "binary", binary, raw: entry });
      continue;
    }

    if (binary === "rm") {
      const target = parts[parts.length - 1];
      if (target === "/" || target === "~") {
        rules.push({ kind: "rm_target", binary: "rm", target, raw: entry });
        continue;
      }
    }

    if (
      parts.length >= 3 &&
      !parts[1].startsWith("-") &&
      parts.slice(2).some((p) => p.includes("*"))
    ) {
      const globArg = parts.slice(2).join(" ");
      rules.push({
        kind: "glob",
        binary,
        subcommand: parts[1],
        pattern: globToRegExp(globArg),
        raw: entry,
      });
      continue;
    }

    const posSpecs: string[] = [];
    const flagSpecs: string[] = [];
    for (const part of parts.slice(1)) {
      if (part === "*" && hasPrefixWildcard) continue;
      if (part.startsWith("-")) flagSpecs.push(part);
      else posSpecs.push(part);
    }

    rules.push({ kind: "prefix", binary, posSpecs, flagSpecs, raw: entry });
  }

  return rules;
}

export function loadDenyRules(settingsPath?: string): DenyRule[] | null {
  const targetPath =
    settingsPath ?? process.env.CLAUDE_SETTINGS_PATH ?? join(homedir(), ".claude", "settings.json");
  try {
    const parsed = JSON.parse(readFileSync(targetPath, "utf8")) as {
      permissions?: { deny?: unknown };
    };
    if (!Array.isArray(parsed?.permissions?.deny)) return null;
    return parseClaudeDenyRules(parsed.permissions.deny);
  } catch {
    return null;
  }
}

function findUnquotedHeredocs(
  line: string,
): Array<{ delim: string; stripTabs: boolean; isQuoted: boolean }> {
  const found: Array<{ delim: string; stripTabs: boolean; isQuoted: boolean }> = [];
  let inSingle = false;
  let inDouble = false;
  let escaped = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch === "\\" && !inSingle) {
      escaped = true;
      continue;
    }
    if (ch === "'" && !inDouble) {
      inSingle = !inSingle;
      continue;
    }
    if (ch === '"' && !inSingle) {
      inDouble = !inDouble;
      continue;
    }
    if (!inSingle && !inDouble && ch === "#" && (i === 0 || /\s/.test(line[i - 1]))) {
      break;
    }
    if (!inSingle && !inDouble && ch === "<" && line[i + 1] === "<" && line[i + 2] !== "<") {
      const m = HEREDOC_START_RE.exec(line.slice(i));
      if (m) {
        const stripTabs = m[1] === "-";
        const delim = m[2] ?? m[3] ?? m[4] ?? "";
        const isQuoted = Boolean(m[2] || m[3]);
        if (delim) found.push({ delim, stripTabs, isQuoted });
        i += m[0].length - 1;
      }
    }
  }

  return found;
}

function stripHeredocs(commandLine: string): { cleaned: string; unquotedBodies: string[] } {
  const lines = commandLine.split(/\r?\n/);
  const outLines: string[] = [];
  const unquotedBodies: string[] = [];
  const pending: Array<{ delim: string; stripTabs: boolean; isQuoted: boolean }> = [];
  let currentBody: string[] = [];

  for (const line of lines) {
    if (pending.length > 0) {
      const { delim, stripTabs, isQuoted } = pending[0];
      const checkLine = stripTabs ? line.replace(/^\t+/, "") : line;
      if (checkLine === delim) {
        if (!isQuoted && currentBody.length > 0) {
          unquotedBodies.push(currentBody.join("\n"));
        }
        currentBody = [];
        pending.shift();
      } else {
        currentBody.push(line);
      }
      continue;
    }

    outLines.push(line);
    for (const h of findUnquotedHeredocs(line)) {
      pending.push(h);
    }
  }

  // Flush unterminated unquoted heredoc so substitutions inside it are still checked.
  if (pending.length > 0 && !pending[0].isQuoted && currentBody.length > 0) {
    unquotedBodies.push(currentBody.join("\n"));
  }

  return { cleaned: outLines.join("\n"), unquotedBodies };
}

function stripLineComments(commandLine: string): string {
  let out = "";
  let inSingle = false;
  let inDouble = false;
  let escaped = false;
  let inBacktick = false;
  let parenDepth = 0;

  for (let i = 0; i < commandLine.length; i++) {
    const ch = commandLine[i];

    if (escaped) {
      out += ch;
      escaped = false;
      continue;
    }
    if (ch === "\\" && !inSingle) {
      out += ch;
      escaped = true;
      continue;
    }
    if (ch === "'" && !inDouble && !inBacktick && parenDepth === 0) {
      inSingle = !inSingle;
      out += ch;
      continue;
    }
    if (ch === '"' && !inSingle && !inBacktick && parenDepth === 0) {
      inDouble = !inDouble;
      out += ch;
      continue;
    }
    if (!inSingle) {
      if (ch === "`") {
        inBacktick = !inBacktick;
        out += ch;
        continue;
      }
      if ((ch === "$" || ch === "<" || ch === ">") && commandLine[i + 1] === "(") {
        parenDepth++;
        out += `${ch}(`;
        i++;
        continue;
      }
      if (ch === ")" && parenDepth > 0) {
        parenDepth--;
        out += ch;
        continue;
      }
    }

    if (!inSingle && !inDouble && !inBacktick && parenDepth === 0 && ch === "#") {
      const prev = i > 0 ? commandLine[i - 1] : "\n";
      if (/[\s;|&(\n]/.test(prev)) {
        while (i < commandLine.length && commandLine[i] !== "\n") {
          i++;
        }
        if (i < commandLine.length && commandLine[i] === "\n") {
          out += "\n";
        }
        continue;
      }
    }

    out += ch;
  }

  return out;
}

function splitSegments(commandLine: string): Array<{ segment: string; fromPipe: boolean }> {
  const segments: Array<{ segment: string; fromPipe: boolean }> = [];
  let buf = "";
  let inSingle = false;
  let inDouble = false;
  let escaped = false;
  let parenDepth = 0;
  let inBacktick = false;
  let fromPipe = false;

  for (let i = 0; i < commandLine.length; i++) {
    const ch = commandLine[i];

    if (escaped) {
      buf += ch;
      escaped = false;
      continue;
    }

    if (ch === "\\" && !inSingle) {
      buf += ch;
      escaped = true;
      continue;
    }

    if (ch === "'" && !inDouble && !inBacktick && parenDepth === 0) {
      inSingle = !inSingle;
      buf += ch;
      continue;
    }

    if (ch === '"' && !inSingle && !inBacktick && parenDepth === 0) {
      inDouble = !inDouble;
      buf += ch;
      continue;
    }

    if (!inSingle) {
      if (ch === "`") {
        inBacktick = !inBacktick;
        buf += ch;
        continue;
      }
      if ((ch === "$" || ch === "<" || ch === ">") && commandLine[i + 1] === "(") {
        parenDepth++;
        buf += `${ch}(`;
        i++;
        continue;
      }
      if (ch === ")" && parenDepth > 0) {
        parenDepth--;
        buf += ch;
        continue;
      }
    }

    if (!inSingle && !inDouble && !inBacktick && parenDepth === 0) {
      if (ch === ";" || ch === "\n") {
        const seg = buf.trim();
        if (seg) segments.push({ segment: seg, fromPipe });
        buf = "";
        fromPipe = false;
        continue;
      }
      if (ch === "&") {
        const isAnd = commandLine[i + 1] === "&";
        const prev = i > 0 ? commandLine[i - 1] : "";
        if (!isAnd && (prev === ">" || prev === "<")) {
          buf += ch;
          continue;
        }
        if (isAnd) i++;
        const seg = buf.trim();
        if (seg) segments.push({ segment: seg, fromPipe });
        buf = "";
        fromPipe = false;
        continue;
      }
      if (ch === "|") {
        const isOr = commandLine[i + 1] === "|";
        const prev = i > 0 ? commandLine[i - 1] : "";
        if (!isOr && prev === ">") {
          buf += ch;
          continue;
        }
        if (isOr) i++;
        const seg = buf.trim();
        if (seg) segments.push({ segment: seg, fromPipe });
        buf = "";
        fromPipe = !isOr;
        continue;
      }
    }

    buf += ch;
  }

  const seg = buf.trim();
  if (seg) segments.push({ segment: seg, fromPipe });
  return segments;
}

function extractSubstitutions(commandLine: string): string[] {
  const found: string[] = [];
  let inSingle = false;
  let inDouble = false;
  let escaped = false;

  for (let i = 0; i < commandLine.length; i++) {
    const ch = commandLine[i];

    if (escaped) {
      escaped = false;
      continue;
    }

    if (ch === "\\" && !inSingle) {
      escaped = true;
      continue;
    }

    if (ch === "'" && !inDouble) {
      inSingle = !inSingle;
      continue;
    }

    if (ch === '"' && !inSingle) {
      inDouble = !inDouble;
      continue;
    }

    if (!inSingle && (ch === "$" || ch === "<" || ch === ">") && commandLine[i + 1] === "(") {
      if ((ch === "<" || ch === ">") && inDouble) continue;

      const start = i + 2;
      let depth = 1;
      let j = start;
      let subSingle = false;
      let subDouble = false;
      let subEscaped = false;

      while (j < commandLine.length && depth > 0) {
        const c = commandLine[j];
        if (subEscaped) {
          subEscaped = false;
        } else if (c === "\\" && !subSingle) {
          subEscaped = true;
        } else if (c === "'" && !subDouble) {
          subSingle = !subSingle;
        } else if (c === '"' && !subSingle) {
          subDouble = !subDouble;
        } else if (!subSingle && !subDouble) {
          if (c === "(") depth++;
          else if (c === ")") depth--;
        }
        j++;
      }

      if (depth === 0) {
        const inner = commandLine.slice(start, j - 1).trim();
        if (inner) found.push(inner);
        i = j - 1;
        continue;
      }
    }

    if (!inSingle && ch === "`") {
      const start = i + 1;
      let j = start;
      let subEscaped = false;
      while (j < commandLine.length) {
        const c = commandLine[j];
        if (subEscaped) {
          subEscaped = false;
        } else if (c === "\\") {
          subEscaped = true;
        } else if (c === "`") {
          break;
        }
        j++;
      }
      if (j < commandLine.length && commandLine[j] === "`") {
        const inner = commandLine.slice(start, j).trim();
        if (inner) found.push(inner);
        i = j;
        continue;
      }
    }
  }

  return found;
}

function stripGrouping(segment: string): string {
  let s = segment.trim();
  while (true) {
    if (s.startsWith("(") && s.endsWith(")")) {
      s = s.slice(1, -1).trim();
      continue;
    }
    if (s.startsWith("{") && s.endsWith("}")) {
      s = s.slice(1, -1).trim();
      continue;
    }
    // Handle subshell followed by trailing redirections like `(git push --force) >/dev/null`
    if (s.startsWith("(")) {
      let depth = 0;
      let inSingle = false;
      let inDouble = false;
      let escaped = false;
      let matchEnd = -1;
      for (let i = 0; i < s.length; i++) {
        const c = s[i];
        if (escaped) {
          escaped = false;
        } else if (c === "\\" && !inSingle) {
          escaped = true;
        } else if (c === "'" && !inDouble) {
          inSingle = !inSingle;
        } else if (c === '"' && !inSingle) {
          inDouble = !inDouble;
        } else if (!inSingle && !inDouble) {
          if (c === "(") depth++;
          else if (c === ")") {
            depth--;
            if (depth === 0) {
              matchEnd = i;
              break;
            }
          }
        }
      }
      if (matchEnd > 0) {
        const inner = s.slice(1, matchEnd).trim();
        const trailing = s.slice(matchEnd + 1).trim();
        s = trailing ? `${inner} ${trailing}` : inner;
        continue;
      }
      s = s.slice(1).trim();
      continue;
    }
    if (s.endsWith(")") && !s.includes("$(") && !s.includes("<(") && !s.includes(">(")) {
      s = s.slice(0, -1).trim();
      continue;
    }
    break;
  }
  return s;
}

function tokenizeShell(segment: string): string[] | null {
  const tokens: string[] = [];
  let current = "";
  let hasToken = false;
  let inSingle = false;
  let inAnsiSingle = false;
  let inDouble = false;
  let escaped = false;

  const flush = () => {
    if (hasToken) {
      tokens.push(current);
      current = "";
      hasToken = false;
    }
  };

  for (let i = 0; i < segment.length; i++) {
    const ch = segment[i];

    if (escaped) {
      if (ch !== "\n") {
        current += ch;
        hasToken = true;
      }
      escaped = false;
      continue;
    }

    if (inAnsiSingle) {
      if (ch === "\\" && i + 1 < segment.length) {
        const next = segment[i + 1];
        if (next === "'" || next === "\\") current += next;
        else if (next === "n") current += "\n";
        else if (next === "t") current += "\t";
        else current += next;
        i++;
      } else if (ch === "'") {
        inAnsiSingle = false;
      } else {
        current += ch;
      }
      hasToken = true;
      continue;
    }

    if (inSingle) {
      if (ch === "'") inSingle = false;
      else current += ch;
      hasToken = true;
      continue;
    }

    if (inDouble) {
      if (ch === "\\") {
        const next = segment[i + 1];
        if (next === "\n") {
          i++;
        } else if (next === '"' || next === "\\" || next === "$" || next === "`") {
          current += next;
          i++;
        } else {
          current += ch;
        }
      } else if (ch === '"') {
        inDouble = false;
      } else {
        current += ch;
      }
      hasToken = true;
      continue;
    }

    if (ch === "\\") {
      if (segment[i + 1] === "\n") {
        i++;
        continue;
      }
      escaped = true;
      hasToken = true;
      continue;
    }

    if (ch === "$" && segment[i + 1] === "'") {
      inAnsiSingle = true;
      hasToken = true;
      i++;
      continue;
    }

    if (ch === "'") {
      inSingle = true;
      hasToken = true;
      continue;
    }
    if (ch === '"') {
      inDouble = true;
      hasToken = true;
      continue;
    }

    if (/\s/.test(ch)) {
      flush();
      continue;
    }

    // Separate unspaced redirections (e.g. `sudo</dev/null ls`, `2>/dev/null`)
    if (ch === "<" || ch === ">") {
      if (segment[i + 1] === "(") {
        // Keep process substitution `<(...)` / `>(...)` attached
        current += ch;
        hasToken = true;
        continue;
      }
      const isFdPrefix = hasToken && /^\d+$/.test(current);
      if (!isFdPrefix) {
        flush();
      }
      let op = isFdPrefix ? current : "";
      current = "";
      hasToken = false;

      if (segment.slice(i, i + 3) === "<<<" || segment.slice(i, i + 3) === "<<-") {
        op += segment.slice(i, i + 3);
        i += 2;
      } else if (
        segment.slice(i, i + 2) === "<<" ||
        segment.slice(i, i + 2) === ">>" ||
        segment.slice(i, i + 2) === "<>" ||
        segment.slice(i, i + 2) === ">&" ||
        segment.slice(i, i + 2) === "<&" ||
        segment.slice(i, i + 2) === ">|"
      ) {
        op += segment.slice(i, i + 2);
        i += 1;
      } else {
        op += ch;
      }
      tokens.push(op);
      continue;
    }

    current += ch;
    hasToken = true;
  }

  if (inSingle || inAnsiSingle || inDouble || escaped) return null;
  flush();
  return tokens;
}

function isShortFlagContaining(token: string, chars: string): boolean {
  if (!token.startsWith("-") || token.startsWith("--") || token.length <= 1) return false;
  const body = token.slice(1);
  return [...chars].some((c) => body.includes(c));
}

function stripWrappers(tokens: string[]): {
  tokens: string[];
  extraCommands: string[];
  hasInputRedir: boolean;
} {
  const extraCommands: string[] = [];
  let hasInputRedir = false;
  let idx = 0;
  const n = tokens.length;

  while (idx < n) {
    const tok = tokens[idx];

    if (SHELL_KEYWORDS.has(tok)) {
      idx++;
      continue;
    }
    if (REDIR_OP_ONLY_RE.test(tok)) {
      if (INPUT_REDIR_RE.test(tok)) hasInputRedir = true;
      idx += 2;
      continue;
    }
    if (REDIR_WITH_TARGET_RE.test(tok)) {
      if (INPUT_REDIR_RE.test(tok)) hasInputRedir = true;
      idx++;
      continue;
    }
    if (ENV_ASSIGN_RE.test(tok)) {
      idx++;
      continue;
    }

    const name = basename(tok);

    if (name === "command" || name === "builtin" || name === "nohup" || name === "time") {
      idx++;
      while (idx < n && tokens[idx].startsWith("-")) {
        if (tokens[idx] === "--") {
          idx++;
          break;
        }
        idx++;
      }
      continue;
    }

    if (name === "exec") {
      idx++;
      while (idx < n && tokens[idx].startsWith("-")) {
        if (tokens[idx] === "--") {
          idx++;
          break;
        }
        if (tokens[idx] === "-a") {
          idx += 2;
          continue;
        }
        idx++;
      }
      continue;
    }

    if (name === "env") {
      idx++;
      while (idx < n) {
        const t = tokens[idx];
        if (t === "--") {
          idx++;
          break;
        }
        if (t === "-S" || t === "--split-string" || isShortFlagContaining(t, "S")) {
          if (idx + 1 < n) extraCommands.push(tokens[idx + 1]);
          idx += 2;
          continue;
        }
        if (t.startsWith("--split-string=")) {
          extraCommands.push(t.slice("--split-string=".length));
          idx++;
          continue;
        }
        if (t === "-u" || t === "-C" || t === "--unset" || t === "--chdir") {
          idx += 2;
          continue;
        }
        if (t.startsWith("-") || ENV_ASSIGN_RE.test(t)) {
          idx++;
          continue;
        }
        break;
      }
      continue;
    }

    if (name === "nice") {
      idx++;
      while (idx < n && tokens[idx].startsWith("-")) {
        if (tokens[idx] === "--") {
          idx++;
          break;
        }
        if (tokens[idx] === "-n" || tokens[idx] === "--adjustment") {
          idx += 2;
          continue;
        }
        idx++;
      }
      continue;
    }

    if (name === "timeout") {
      idx++;
      while (idx < n && tokens[idx].startsWith("-")) {
        if (tokens[idx] === "--") {
          idx++;
          break;
        }
        if (TIMEOUT_OPTS_WITH_ARG.has(tokens[idx])) {
          idx += 2;
          continue;
        }
        idx++;
      }
      if (idx < n) idx++; // duration
      continue;
    }

    if (name === "xargs") {
      idx++;
      while (idx < n && tokens[idx].startsWith("-")) {
        if (tokens[idx] === "--") {
          idx++;
          break;
        }
        if (XARGS_OPTS_WITH_ARG.has(tokens[idx])) {
          idx += 2;
          continue;
        }
        idx++;
      }
      continue;
    }

    break;
  }

  return { tokens: tokens.slice(idx), extraCommands, hasInputRedir };
}

function stripRedirectionTokens(tokens: string[]): { cleaned: string[]; hasInputRedir: boolean } {
  const cleaned: string[] = [];
  let hasInputRedir = false;
  for (let i = 0; i < tokens.length; i++) {
    const tok = tokens[i];
    if (REDIR_OP_ONLY_RE.test(tok)) {
      if (INPUT_REDIR_RE.test(tok)) hasInputRedir = true;
      i++;
      continue;
    }
    if (REDIR_WITH_TARGET_RE.test(tok)) {
      if (INPUT_REDIR_RE.test(tok)) hasInputRedir = true;
      continue;
    }
    cleaned.push(tok);
  }
  return { cleaned, hasInputRedir };
}

function extractSubcommandAndArgs(
  binary: string,
  tokens: string[],
): { subcommand: string | null; positional: string[] } {
  const optsWithArg =
    binary === "git"
      ? GIT_OPTS_WITH_ARG
      : binary === "gh"
        ? GH_OPTS_WITH_ARG
        : binary === "tofu"
          ? new Set(["-chdir"])
          : new Set<string>();

  const positional: string[] = [];
  let subcommand: string | null = null;

  for (let i = 1; i < tokens.length; i++) {
    const t = tokens[i];
    if (t === "--") {
      positional.push(...tokens.slice(i + 1));
      break;
    }
    if (optsWithArg.has(t)) {
      i++;
      continue;
    }
    if (t.startsWith("-")) continue;
    if (subcommand === null) {
      subcommand = t;
    }
    positional.push(t);
  }

  return {
    subcommand,
    positional,
  };
}

function normalizeRmTarget(target: string, home: string): string {
  let normalized = target.replaceAll("${HOME}", home).replaceAll("$HOME", home);

  if (normalized === "~" || normalized.startsWith("~/")) {
    normalized = home + normalized.slice(1);
  } else if (normalized.startsWith("~")) {
    const username = userInfo().username;
    if (normalized === `~${username}` || normalized.startsWith(`~${username}/`)) {
      normalized = home + normalized.slice(1 + username.length);
    }
  }

  // Strip trailing glob components like /*, /*/, /.*, /?
  const withoutGlob = normalized.replace(/\/+(?:\*+|\.\*|\?+)\/*$/, "");
  if (withoutGlob === "" && normalized.startsWith("/")) return "/";

  if (withoutGlob.startsWith("/")) {
    const norm = normalize(withoutGlob).replace(/\/+$/, "") || "/";
    try {
      return realpathSync(norm);
    } catch {
      return norm;
    }
  }

  return withoutGlob;
}

function matchesFlagSpec(arg: string, flag: string): boolean {
  if (flag.startsWith("--")) {
    return arg === flag || arg.startsWith(`${flag}=`);
  }
  if (flag.startsWith("-") && flag.length === 2) {
    return isShortFlagContaining(arg, flag[1]);
  }
  // Single-dash multi-char flags like -auto-approve, -delete, -rf
  if (flag.startsWith("-") && flag.length > 2) {
    if (arg === flag || arg.startsWith(`${flag}=`)) return true;
    // Also match combined short flags when every char of flag[1:] is present
    if (arg.startsWith("-") && !arg.startsWith("--")) {
      const body = arg.slice(1);
      return [...flag.slice(1)].every((c) => body.includes(c));
    }
  }
  return false;
}

function matchDenyRules(binary: string, tokens: string[], rules: DenyRule[]): string | null {
  const { subcommand, positional } = extractSubcommandAndArgs(binary, tokens);

  for (const rule of rules) {
    if (rule.binary !== binary) continue;

    if (rule.kind === "binary") {
      return `Command '${binary}' is blocked by policy (${rule.raw}).`;
    }

    if (rule.kind === "rm_target") {
      let hasRecursive = false;
      const targets: string[] = [];
      let endOfOpts = false;

      for (const arg of tokens.slice(1)) {
        if (!endOfOpts && arg === "--") {
          endOfOpts = true;
          continue;
        }
        if (!endOfOpts && arg.startsWith("-")) {
          if (arg === "--recursive" || isShortFlagContaining(arg, "rR")) {
            hasRecursive = true;
          }
          continue;
        }
        targets.push(arg);
      }

      if (hasRecursive) {
        const home = safeHomeDir();
        const expected = rule.target === "/" ? "/" : home;
        for (const t of targets) {
          if (normalizeRmTarget(t, home) === expected) {
            return `Recursive rm on protected path '${t}' is blocked by policy (${rule.raw}).`;
          }
        }
      }
      continue;
    }

    if (rule.kind === "glob") {
      if (subcommand !== rule.subcommand) continue;
      for (const arg of positional.slice(1)) {
        if (rule.pattern.test(arg)) {
          return `Command matched blocked pattern (${rule.raw}).`;
        }
      }
      if (
        binary === "gh" &&
        subcommand === "api" &&
        positional[1]?.replace(/^\/+/, "") === "graphql" &&
        rule.raw.includes("/pulls/*/merge") &&
        tokens.some((t) => t.includes("mergePullRequest"))
      ) {
        return `gh api graphql mergePullRequest is blocked by policy (${rule.raw}).`;
      }
      continue;
    }

    if (rule.kind === "prefix") {
      const { posSpecs, flagSpecs } = rule;

      if (posSpecs.length > 0) {
        const matchesPos = posSpecs.every((spec, idx) => positional[idx] === spec);
        if (!matchesPos) continue;
      }

      if (flagSpecs.length === 0) {
        return `Command '${binary} ${posSpecs.join(" ")}' is blocked by policy (${rule.raw}).`;
      }

      // Check flags across all command args (before or after positional args)
      const matchedFlags = new Set<string>();
      let endOfOpts = false;

      for (const arg of tokens.slice(1)) {
        if (!endOfOpts && arg === "--") {
          endOfOpts = true;
          continue;
        }
        if (!endOfOpts) {
          for (const flag of flagSpecs) {
            if (matchesFlagSpec(arg, flag)) matchedFlags.add(flag);
          }
        }
        if (
          binary === "git" &&
          posSpecs[0] === "push" &&
          (flagSpecs.includes("--force") || flagSpecs.includes("-f")) &&
          arg.startsWith("+")
        ) {
          return `git push with +refspec force push is blocked by policy (${rule.raw}).`;
        }
      }

      if (matchedFlags.size === flagSpecs.length) {
        return `Command matched blocked flags (${rule.raw}).`;
      }
    }
  }

  return null;
}

export function evaluateCommand(commandLine: string, rules: DenyRule[], depth = 0): Decision {
  if (depth > 5) {
    return { decision: "ask", reason: "Nested shell evaluation depth exceeded." };
  }

  if (!commandLine || !commandLine.trim()) {
    return { decision: "ask", reason: "Empty command line." };
  }

  const { cleaned: withoutHeredocs, unquotedBodies } = stripHeredocs(commandLine);
  const cleaned = stripLineComments(withoutHeredocs);

  for (const body of unquotedBodies) {
    for (const sub of extractSubstitutions(body)) {
      const subResult = evaluateCommand(sub, rules, depth + 1);
      if (subResult.decision !== "allow") return subResult;
    }
  }

  for (const sub of extractSubstitutions(cleaned)) {
    const subResult = evaluateCommand(sub, rules, depth + 1);
    if (subResult.decision !== "allow") return subResult;
  }

  const segments = splitSegments(cleaned);
  if (segments.length === 0) {
    return { decision: "ask", reason: "No executable segments found." };
  }

  for (const { segment: rawSegment, fromPipe } of segments) {
    const segment = stripGrouping(rawSegment);
    if (!segment) continue;

    const rawTokens = tokenizeShell(segment);
    if (rawTokens === null) {
      return { decision: "ask", reason: "Could not safely parse shell command." };
    }

    const {
      tokens: unwrapped,
      extraCommands,
      hasInputRedir: leadingInputRedir,
    } = stripWrappers(rawTokens);

    for (const extra of extraCommands) {
      const nested = evaluateCommand(extra, rules, depth + 1);
      if (nested.decision !== "allow") return nested;
    }

    const { cleaned: tokens, hasInputRedir: trailingInputRedir } =
      stripRedirectionTokens(unwrapped);
    const hasInputRedir = leadingInputRedir || trailingInputRedir;

    if (tokens.length === 0) continue;

    const binary = basename(tokens[0]);

    if (binary === "eval" && tokens.length > 1) {
      const evalArgs = tokens[1] === "--" ? tokens.slice(2) : tokens.slice(1);
      if (evalArgs.length > 0) {
        const nested = evaluateCommand(evalArgs.join(" "), rules, depth + 1);
        if (nested.decision !== "allow") return nested;
      }
      continue;
    }

    if (SHELL_BINARIES.has(binary)) {
      let foundC = false;
      for (let i = 1; i < tokens.length; i++) {
        const tok = tokens[i];
        if (tok === "--") break;
        if (tok === "-c" || isShortFlagContaining(tok, "c")) {
          foundC = true;
          let cmdIdx = i + 1;
          if (tokens[cmdIdx] === "--") cmdIdx++;
          if (cmdIdx < tokens.length) {
            const nested = evaluateCommand(tokens[cmdIdx], rules, depth + 1);
            if (nested.decision !== "allow") return nested;
          }
          break;
        }
      }
      if (!foundC && (fromPipe || hasInputRedir)) {
        return {
          decision: "ask",
          reason: `Piped or redirected input to '${binary}' requires confirmation.`,
        };
      }
      continue;
    }

    const denyReason = matchDenyRules(binary, tokens, rules);
    if (denyReason) {
      return { decision: "deny", reason: denyReason };
    }
  }

  return { decision: "allow" };
}

async function main(): Promise<void> {
  try {
    const raw = await new Response(Bun.stdin.stream()).text();
    const payload = JSON.parse(raw) as Record<string, unknown>;

    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
      console.log(JSON.stringify({ decision: "ask", reason: "Invalid hook payload type." }));
      return;
    }

    const toolCall = payload.toolCall as Record<string, unknown> | undefined;
    if (!toolCall || typeof toolCall !== "object" || toolCall.name !== "run_command") {
      console.log(JSON.stringify({ decision: "ask" }));
      return;
    }

    const args = toolCall.args as Record<string, unknown> | undefined;
    if (!args || typeof args !== "object" || typeof args.CommandLine !== "string") {
      console.log(JSON.stringify({ decision: "ask", reason: "Missing CommandLine." }));
      return;
    }

    const rules = loadDenyRules();
    if (rules === null) {
      console.log(
        JSON.stringify({
          decision: "ask",
          reason: "Could not load ~/.claude/settings.json deny rules.",
        }),
      );
      return;
    }

    console.log(JSON.stringify(evaluateCommand(args.CommandLine, rules)));
  } catch {
    console.log(
      JSON.stringify({ decision: "ask", reason: "Unexpected error evaluating command." }),
    );
  }
}

if (import.meta.main) {
  await main();
}
