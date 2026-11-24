#!/usr/bin/env node
import { randomBytes } from "node:crypto";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  readFileSync,
  realpathSync,
  renameSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join, posix } from "node:path";
import { fileURLToPath } from "node:url";

export type ClaudeSettings = {
  permissions?: { allow?: string[]; deny?: string[] };
};

export type AntigravityGrants = {
  allow: string[];
  deny: string[];
};

export type MainOptions = {
  source?: string;
  target?: string;
  homeDir?: string;
};

const DEFAULT_SOURCE = fileURLToPath(new URL("../home/.claude/settings.json", import.meta.url));

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return Boolean(v) && typeof v === "object" && !Array.isArray(v);
}

function toStringArray(v: unknown): string[] {
  return Array.isArray(v) ? v.filter((item): item is string => typeof item === "string") : [];
}

function escapeRegex(s: string): string {
  return s.replace(/[.+?^${}()|[\]\\]/g, "\\$&");
}

function toCommandRule(raw: string, action: "command" | "unsandboxed"): string | null {
  const trimmed = raw.trim();
  const body =
    trimmed.endsWith(":*") || trimmed.endsWith(" *") ? trimmed.slice(0, -2).trim() : trimmed;
  if (!body) return null;
  if (!body.includes("*")) return `${action}(${body})`;

  const regexTokens = body.split(/\s+/).map((tok) => {
    if (!tok.includes("*")) return escapeRegex(tok);
    const converted = escapeRegex(tok).replaceAll("*", ".*");
    return tok.startsWith("repos/") ? `/?${converted}` : converted;
  });
  return `${action}(regex:${regexTokens.join(" ")})`;
}

function toFilePath(raw: string, homeDir: string): string | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;

  let resolved: string;
  if (trimmed === "~" || trimmed.startsWith("~/")) {
    if (!homeDir.startsWith("/")) return null;
    const normalizedHome = homeDir.replace(/\/+$/, "") || "/";
    const rest = trimmed.slice(1);
    resolved = normalizedHome === "/" && rest ? rest : `${normalizedHome}${rest}`;
  } else if (trimmed.startsWith("//")) {
    if (/^\/\/+$/.test(trimmed)) return null;
    resolved = trimmed.slice(1);
  } else {
    return null;
  }

  let path = resolved.replace(/\/+$/, "") || "/";
  if (path.endsWith("/**")) {
    path = path.slice(0, -3) || "/";
  }
  path = path.replace(/\/+$/, "") || "/";

  if (/[*?[\]{}()]/.test(path)) return null;
  if (path.split("/").includes("..")) return null;

  return posix.normalize(path).replace(/\/+$/, "") || "/";
}

export function convertRule(
  entry: string,
  actions: ("command" | "unsandboxed")[] = ["command"],
  homeDir = homedir(),
): string[] {
  const bash = /^Bash\((.+)\)$/.exec(entry);
  if (bash) {
    return actions.map((a) => toCommandRule(bash[1], a)).filter((r): r is string => r !== null);
  }

  const webFetch = /^WebFetch\(domain:(.+)\)$/.exec(entry);
  if (webFetch) {
    const domain = webFetch[1].trim().replace(/^\*\./, "");
    return domain ? [`read_url(${domain})`] : [];
  }

  const edit = /^Edit\((.+)\)$/.exec(entry);
  if (edit) {
    const path = toFilePath(edit[1], homeDir);
    return path ? [`write_file(${path})`] : [];
  }

  const read = /^Read\((.+)\)$/.exec(entry);
  if (read) {
    const path = toFilePath(read[1], homeDir);
    return path ? [`read_file(${path})`] : [];
  }

  return [];
}

export function convertClaudeSettings(
  settings: ClaudeSettings,
  homeDir = homedir(),
): AntigravityGrants {
  const allow = new Set<string>();
  const deny = new Set<string>();
  const permissions = isPlainObject(settings.permissions) ? settings.permissions : {};

  for (const entry of toStringArray(permissions.allow)) {
    for (const rule of convertRule(entry, ["command"], homeDir)) allow.add(rule);
  }
  for (const entry of toStringArray(permissions.deny)) {
    for (const rule of convertRule(entry, ["command", "unsandboxed"], homeDir)) deny.add(rule);
  }
  for (const rule of deny) allow.delete(rule);

  return { allow: [...allow], deny: [...deny] };
}

export function mergeConfig(
  config: Record<string, unknown>,
  grants: AntigravityGrants,
): Record<string, unknown> {
  const userSettings = isPlainObject(config.userSettings) ? config.userSettings : {};
  const existing = isPlainObject(userSettings.globalPermissionGrants)
    ? userSettings.globalPermissionGrants
    : {};
  const prevAllow = toStringArray(existing.allow);
  const prevDeny = toStringArray(existing.deny);
  const denySet = new Set([...prevDeny, ...grants.deny]);
  const allowSet = new Set([...prevAllow, ...grants.allow].filter((r) => !denySet.has(r)));

  return {
    ...config,
    userSettings: {
      ...userSettings,
      globalPermissionGrants: {
        ...existing,
        allow: [...allowSet],
        deny: [...denySet],
      },
    },
  };
}

export function readJsonOrEmpty(path: string): Record<string, unknown> {
  try {
    const parsed: unknown = JSON.parse(readFileSync(path, "utf8"));
    if (!isPlainObject(parsed)) {
      throw new Error(`Expected JSON object in ${path}`);
    }
    return parsed;
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code === "ENOENT") return {};
    throw err;
  }
}

export function writeAtomic(path: string, data: Record<string, unknown>): void {
  const target = existsSync(path) ? realpathSync(path) : path;
  mkdirSync(dirname(target), { recursive: true, mode: 0o700 });
  const tmp = `${target}.tmp.${process.pid}.${randomBytes(6).toString("hex")}`;
  try {
    writeFileSync(tmp, `${JSON.stringify(data, null, 2)}\n`, { mode: 0o600, flag: "wx" });
    chmodSync(tmp, 0o600);
    renameSync(tmp, target);
  } catch (err) {
    try {
      unlinkSync(tmp);
    } catch {}
    throw err;
  }
}

export function main(argv = process.argv.slice(2), options: MainOptions = {}): number {
  if (argv.includes("--help") || argv.includes("-h")) {
    console.log("Usage: sync-antigravity-permissions.ts [--dry-run]");
    return 0;
  }
  const unknown = argv.filter((a) => a !== "--dry-run");
  if (unknown.length > 0) {
    console.error(`Unknown arguments: ${unknown.join(", ")}`);
    return 1;
  }

  const homeDir = options.homeDir ?? homedir();
  const source = options.source ?? DEFAULT_SOURCE;
  const target = options.target ?? join(homeDir, ".gemini", "config", "config.json");

  const parsedSource: unknown = JSON.parse(readFileSync(source, "utf8"));
  if (!isPlainObject(parsedSource)) {
    throw new Error(`Expected JSON object in ${source}`);
  }
  const claude = parsedSource as ClaudeSettings;
  const grants = convertClaudeSettings(claude, homeDir);

  const rawDeny = isPlainObject(claude.permissions) ? toStringArray(claude.permissions.deny) : [];
  for (const entry of rawDeny) {
    if (
      /^(Edit|Read)\(.+\)$/.test(entry) &&
      convertRule(entry, ["command", "unsandboxed"], homeDir).length === 0
    ) {
      console.error(`Warning: skipped unsupported deny rule: ${entry}`);
    }
  }

  if (argv.includes("--dry-run")) {
    console.log(JSON.stringify(grants, null, 2));
    return 0;
  }

  const current = readJsonOrEmpty(target);
  writeAtomic(target, mergeConfig(current, grants));
  console.log(
    `Synced ${grants.allow.length} allow / ${grants.deny.length} deny rules to ${target}`,
  );
  return 0;
}

if (
  process.argv[1] &&
  realpathSync(fileURLToPath(import.meta.url)) === realpathSync(process.argv[1])
) {
  process.exitCode = main();
}
