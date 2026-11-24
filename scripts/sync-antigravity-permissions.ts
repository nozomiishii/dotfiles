#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const SOURCE = fileURLToPath(new URL("../home/.claude/settings.json", import.meta.url));
const TARGET = join(homedir(), ".gemini", "config", "config.json");

function toCommandRule(raw: string, action: "command" | "unsandboxed"): string | null {
  const body = raw
    .trim()
    .replace(/(?::\*| \*)$/, "")
    .trim();
  if (!body) return null;
  if (!body.includes("*")) return `${action}(${body})`;

  const pattern = body
    .split(/\s+/)
    .map((tok) => {
      if (!tok.includes("*")) return tok.replace(/[.+?^${}()|[\]\\]/g, "\\$&");
      const r = tok.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replaceAll("*", ".*");
      return tok.startsWith("repos/") ? `/?${r}` : r;
    })
    .join(" ");
  return `${action}(regex:${pattern})`;
}

function convertRule(
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

  const edit = /^Edit\((~\/[^*?]+?)(?:\/\*\*)?\/?\)$/.exec(entry);
  if (edit) return [`write_file(${homedir().replace(/\/+$/, "")}${edit[1].slice(1)})`];

  return [];
}

const claude = JSON.parse(readFileSync(SOURCE, "utf8")) as {
  permissions?: { allow?: string[]; deny?: string[] };
};
const claudeDeny = new Set(
  (claude.permissions?.deny ?? []).flatMap((e) => convertRule(e, ["command", "unsandboxed"])),
);
const claudeAllow = new Set(
  (claude.permissions?.allow ?? [])
    .flatMap((e) => convertRule(e))
    .filter((r) => !claudeDeny.has(r)),
);

if (process.argv.includes("--dry-run")) {
  console.log(JSON.stringify({ allow: [...claudeAllow], deny: [...claudeDeny] }, null, 2));
  process.exit(0);
}

const config = existsSync(TARGET) ? JSON.parse(readFileSync(TARGET, "utf8")) : {};
const existing = config.userSettings?.globalPermissionGrants ?? {};
const deny = new Set([...(existing.deny ?? []), ...claudeDeny]);
const allow = new Set([...(existing.allow ?? []), ...claudeAllow].filter((r) => !deny.has(r)));

const next = {
  ...config,
  userSettings: {
    ...config.userSettings,
    globalPermissionGrants: {
      ...existing,
      allow: [...allow],
      deny: [...deny],
    },
  },
};

mkdirSync(dirname(TARGET), { recursive: true, mode: 0o700 });
writeFileSync(TARGET, `${JSON.stringify(next, null, 2)}\n`, { mode: 0o600 });
console.log(`Synced ${allow.size} allow / ${deny.size} deny rules to ${TARGET}`);
