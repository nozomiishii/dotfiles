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
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export type ClaudeSettings = {
  permissions?: { allow?: string[]; deny?: string[] };
};

export type AntigravityGrants = {
  allow: string[];
  deny: string[];
};

const DEFAULT_SOURCE = fileURLToPath(new URL("../home/.claude/settings.json", import.meta.url));
const DEFAULT_TARGET = join(homedir(), ".gemini", "config", "config.json");

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return Boolean(v) && typeof v === "object" && !Array.isArray(v);
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

export function convertRule(
  entry: string,
  actions: ("command" | "unsandboxed")[] = ["command"],
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

  return [];
}

export function convertClaudeSettings(settings: ClaudeSettings): AntigravityGrants {
  const allow = new Set<string>();
  const deny = new Set<string>();

  for (const entry of settings.permissions?.allow ?? []) {
    for (const rule of convertRule(entry, ["command"])) allow.add(rule);
  }
  for (const entry of settings.permissions?.deny ?? []) {
    for (const rule of convertRule(entry, ["command", "unsandboxed"])) deny.add(rule);
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
  const prevAllow = Array.isArray(existing.allow) ? (existing.allow as string[]) : [];
  const prevDeny = Array.isArray(existing.deny) ? (existing.deny as string[]) : [];
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
    } catch {
      // ignore cleanup error
    }
    throw err;
  }
}

export function main(argv = process.argv.slice(2)): void {
  if (argv.includes("--help") || argv.includes("-h")) {
    console.log("Usage: sync-antigravity-permissions.ts [--dry-run]");
    return;
  }
  const unknown = argv.filter((a) => a !== "--dry-run");
  if (unknown.length > 0) {
    console.error(`Unknown arguments: ${unknown.join(", ")}`);
    process.exitCode = 1;
    return;
  }

  const claude = JSON.parse(readFileSync(DEFAULT_SOURCE, "utf8")) as ClaudeSettings;
  const grants = convertClaudeSettings(claude);

  if (argv.includes("--dry-run")) {
    console.log(JSON.stringify(grants, null, 2));
    return;
  }

  const current = readJsonOrEmpty(DEFAULT_TARGET);
  writeAtomic(DEFAULT_TARGET, mergeConfig(current, grants));
  console.log(
    `Synced ${grants.allow.length} allow / ${grants.deny.length} deny rules to ${DEFAULT_TARGET}`,
  );
}

if (process.argv[1] && fileURLToPath(import.meta.url) === realpathSync(process.argv[1])) {
  main();
}
