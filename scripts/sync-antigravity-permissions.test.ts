import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, test } from "node:test";
import { fileURLToPath } from "node:url";
import {
  convertClaudeSettings,
  convertRule,
  mergeConfig,
  readJsonOrEmpty,
  writeAtomic,
  type ClaudeSettings,
} from "./sync-antigravity-permissions.ts";

const CLAUDE_SETTINGS_PATH = fileURLToPath(
  new URL("../home/.claude/settings.json", import.meta.url),
);

describe("convertRule", () => {
  test("Bash プレフィックスルールを command(...) に変換する", () => {
    assert.deepEqual(convertRule("Bash(pnpm:*)"), ["command(pnpm)"]);
    assert.deepEqual(convertRule("Bash(sudo *)"), ["command(sudo)"]);
    assert.deepEqual(convertRule("Bash(git push --force:*)"), ["command(git push --force)"]);
    assert.deepEqual(convertRule("Bash(rm -rf /)"), ["command(rm -rf /)"]);
  });

  test("deny 用に command と unsandboxed の両方を生成できる", () => {
    assert.deepEqual(convertRule("Bash(sudo:*)", ["command", "unsandboxed"]), [
      "command(sudo)",
      "unsandboxed(sudo)",
    ]);
  });

  test("ワイルドカードを含む Bash ルールを command(regex:...) に変換する", () => {
    assert.deepEqual(convertRule("Bash(gh api repos/*/pulls/*/merge*)"), [
      "command(regex:gh api /?repos/.*/pulls/.*/merge.*)",
    ]);
  });

  test("WebFetch(domain:...) を read_url(...) に変換し先頭ワイルドカードを外す", () => {
    assert.deepEqual(convertRule("WebFetch(domain:github.com)"), ["read_url(github.com)"]);
    assert.deepEqual(convertRule("WebFetch(domain:*.github.com)"), ["read_url(github.com)"]);
    assert.deepEqual(convertRule("WebFetch(domain:*.)"), []);
  });

  test("空ルールや Antigravity に対応しないルールは空配列を返す", () => {
    assert.deepEqual(convertRule("Bash(:*)"), []);
    assert.deepEqual(convertRule("Bash( )"), []);
    assert.deepEqual(convertRule("Read"), []);
    assert.deepEqual(convertRule("Edit"), []);
    assert.deepEqual(convertRule("WebSearch"), []);
    assert.deepEqual(convertRule("mcp__github__merge_pull_request"), []);
  });
});

describe("convertClaudeSettings", () => {
  test("home/.claude/settings.json の permissions.allow / deny を変換して重複除去する", () => {
    const claude = JSON.parse(readFileSync(CLAUDE_SETTINGS_PATH, "utf8")) as ClaudeSettings;
    const grants = convertClaudeSettings(claude);

    assert.ok(grants.allow.includes("command(pnpm)"));
    assert.ok(grants.allow.includes("command(jq)"));
    assert.ok(grants.allow.includes("read_url(github.com)"));
    assert.equal(grants.allow.filter((r) => r === "read_url(github.com)").length, 1);

    assert.ok(grants.deny.includes("command(git push --force)"));
    assert.ok(grants.deny.includes("unsandboxed(git push --force)"));
    assert.ok(grants.deny.includes("command(gh pr merge)"));
    assert.ok(grants.deny.includes("command(regex:gh api /?repos/.*/pulls/.*/merge.*)"));
    assert.ok(grants.deny.includes("command(sudo)"));
    assert.ok(grants.deny.includes("unsandboxed(sudo)"));
    assert.ok(grants.deny.includes("command(tofu apply)"));
  });
});

describe("mergeConfig", () => {
  test("既存の plugins や手動許可ルールを壊さずマージし、deny に入ったルールは allow から除く", () => {
    const current = {
      plugins: { superpowers: { enabled: true } },
      userSettings: {
        permissionPreset: "AGENT_PERMISSION_PRESET_AUTO",
        globalPermissionGrants: {
          allow: ["read_file(/tmp/a)", "command(gh)", "command(sudo)"],
          ask: ["command(rm)"],
        },
      },
    };

    const merged = mergeConfig(current, {
      allow: ["command(gh)", "command(pnpm)"],
      deny: ["command(sudo)"],
    });

    assert.deepEqual(merged.plugins, { superpowers: { enabled: true } });
    const us = merged.userSettings as {
      permissionPreset: string;
      globalPermissionGrants: { allow: string[]; deny: string[]; ask: string[] };
    };
    assert.equal(us.permissionPreset, "AGENT_PERMISSION_PRESET_AUTO");
    assert.deepEqual(us.globalPermissionGrants.allow, [
      "read_file(/tmp/a)",
      "command(gh)",
      "command(pnpm)",
    ]);
    assert.deepEqual(us.globalPermissionGrants.deny, ["command(sudo)"]);
    assert.deepEqual(us.globalPermissionGrants.ask, ["command(rm)"]);
  });

  test("userSettings や allow/deny が不正な型でもクラッシュせず安全に処理する", () => {
    const merged = mergeConfig(
      { userSettings: { globalPermissionGrants: { allow: "broken", deny: 123 } } },
      { allow: ["command(pnpm)"], deny: ["command(sudo)"] },
    );
    const us = merged.userSettings as {
      globalPermissionGrants: { allow: string[]; deny: string[] };
    };
    assert.deepEqual(us.globalPermissionGrants.allow, ["command(pnpm)"]);
    assert.deepEqual(us.globalPermissionGrants.deny, ["command(sudo)"]);
  });
});

describe("readJsonOrEmpty / writeAtomic", () => {
  test("存在しないファイルは空オブジェクトを返し、writeAtomic は 0600 で原子的に書き込む", () => {
    const dir = mkdtempSync(join(tmpdir(), "sync-ag-test-"));
    try {
      const target = join(dir, "config.json");
      assert.deepEqual(readJsonOrEmpty(target), {});

      writeAtomic(target, { userSettings: { ok: true } });
      assert.deepEqual(readJsonOrEmpty(target), { userSettings: { ok: true } });
      assert.equal(statSync(target).mode & 0o777, 0o600);

      writeFileSync(target, "null");
      assert.throws(() => readJsonOrEmpty(target));
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
