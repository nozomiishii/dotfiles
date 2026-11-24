import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { describe, test } from "node:test";
import { fileURLToPath } from "node:url";
import {
  convertClaudeSettings,
  convertRule,
  main,
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

  test("Edit / Read のホーム相対パスと絶対パスを write_file / read_file に変換する", () => {
    const home = "/Users/alice";
    assert.deepEqual(convertRule("Edit(~/Code/**)", ["command"], home), [
      "write_file(/Users/alice/Code)",
    ]);
    assert.deepEqual(convertRule("Edit(~/Code)", ["command"], home), [
      "write_file(/Users/alice/Code)",
    ]);
    assert.deepEqual(convertRule("Edit(~/Code/)", ["command"], home), [
      "write_file(/Users/alice/Code)",
    ]);
    assert.deepEqual(convertRule("Edit(~/Code/**/)", ["command"], home), [
      "write_file(/Users/alice/Code)",
    ]);
    assert.deepEqual(convertRule("Edit(~)", ["command"], home), ["write_file(/Users/alice)"]);
    assert.deepEqual(convertRule("Edit(~/)", ["command"], home), ["write_file(/Users/alice)"]);
    assert.deepEqual(convertRule("Edit(~/**)", ["command"], home), ["write_file(/Users/alice)"]);
    assert.deepEqual(convertRule("Edit(~/Code/**)", ["command"], "/Users/alice/"), [
      "write_file(/Users/alice/Code)",
    ]);
    assert.deepEqual(convertRule("Edit(~/Code/**)", ["command"], "/"), ["write_file(/Code)"]);
    assert.deepEqual(convertRule("Edit(~/Code/foo..bar)", ["command"], home), [
      "write_file(/Users/alice/Code/foo..bar)",
    ]);
    assert.deepEqual(convertRule("Read(~/.ssh/**)", ["command"], home), [
      "read_file(/Users/alice/.ssh)",
    ]);
    assert.deepEqual(convertRule("Edit(//tmp/work/**)", ["command"], home), [
      "write_file(/tmp/work)",
    ]);
    assert.deepEqual(convertRule("Edit(//**)", ["command"], home), ["write_file(/)"]);
  });

  test("相対パス・単一階層 glob・波括弧 glob・括弧・親参照を含む Edit / Read ルールは空配列を返す", () => {
    const home = "/Users/alice";
    assert.deepEqual(convertRule("Edit(//)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(///)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(src/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(/src/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~bob/Code/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/*)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/*/*)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/*.ts)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/a?/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/[ab]/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/{a,b}/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/foo)bar/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/..)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/../etc/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(//../etc/**)", ["command"], home), []);
    assert.deepEqual(convertRule("Read(~/Code/*/secret)", ["command"], home), []);
    assert.deepEqual(convertRule("Edit(~/Code/**)", ["command"], "relative/home"), []);
    assert.deepEqual(convertRule("Edit( )", ["command"], home), []);
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
    const grants = convertClaudeSettings(claude, "/Users/alice");

    assert.ok(grants.allow.includes("write_file(/Users/alice/Code)"));
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

    const defaultGrants = convertClaudeSettings(claude);
    assert.ok(defaultGrants.allow.includes(`write_file(${homedir().replace(/\/+$/, "")}/Code)`));
  });

  test("Edit / Read が deny に入った場合は allow から除かれる", () => {
    const grants = convertClaudeSettings(
      {
        permissions: {
          allow: ["Edit(~/Code/**)", "Read(~/.ssh/**)"],
          deny: ["Edit(~/Code/**)", "Read(~/.ssh/**)"],
        },
      },
      "/Users/alice",
    );

    assert.deepEqual(grants, {
      allow: [],
      deny: ["write_file(/Users/alice/Code)", "read_file(/Users/alice/.ssh)"],
    });
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
      allow: ["command(gh)", "command(pnpm)", "write_file(/Users/alice/Code)"],
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
      "write_file(/Users/alice/Code)",
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

describe("main", () => {
  function withCapture(fn: () => number): { code: number; stdout: string; stderr: string } {
    const out: string[] = [];
    const err: string[] = [];
    const origLog = console.log;
    const origErr = console.error;
    console.log = (...args: unknown[]) => out.push(args.map(String).join(" "));
    console.error = (...args: unknown[]) => err.push(args.map(String).join(" "));
    try {
      const code = fn();
      return { code, stdout: out.join("\n"), stderr: err.join("\n") };
    } finally {
      console.log = origLog;
      console.error = origErr;
    }
  }

  test("既存ルールを残したまま write_file を追記マージし、--dry-run はファイルを書き換えない", () => {
    const dir = mkdtempSync(join(tmpdir(), "sync-ag-main-"));
    try {
      const source = join(dir, "settings.json");
      const target = join(dir, "config.json");
      writeFileSync(
        source,
        JSON.stringify({
          permissions: {
            allow: ["Edit(~/Code/**)", "Bash(pnpm:*)"],
            deny: ["Bash(sudo:*)"],
          },
        }),
      );
      const initialConfig = {
        plugins: { keep: true },
        userSettings: {
          globalPermissionGrants: {
            allow: ["read_file(/tmp/extra)"],
            ask: ["command(rm)"],
          },
        },
      };
      writeFileSync(target, JSON.stringify(initialConfig, null, 2));

      const dryRun = withCapture(() =>
        main(["--dry-run"], { source, target, homeDir: "/Users/alice" }),
      );
      assert.equal(dryRun.code, 0);
      assert.deepEqual(JSON.parse(dryRun.stdout), {
        allow: ["write_file(/Users/alice/Code)", "command(pnpm)"],
        deny: ["command(sudo)", "unsandboxed(sudo)"],
      });
      assert.deepEqual(readJsonOrEmpty(target), initialConfig);

      const synced = withCapture(() => main([], { source, target, homeDir: "/Users/alice" }));
      assert.equal(synced.code, 0);
      const expected = {
        plugins: { keep: true },
        userSettings: {
          globalPermissionGrants: {
            allow: ["read_file(/tmp/extra)", "write_file(/Users/alice/Code)", "command(pnpm)"],
            deny: ["command(sudo)", "unsandboxed(sudo)"],
            ask: ["command(rm)"],
          },
        },
      };
      assert.deepEqual(readJsonOrEmpty(target), expected);

      const syncedAgain = withCapture(() => main([], { source, target, homeDir: "/Users/alice" }));
      assert.equal(syncedAgain.code, 0);
      assert.deepEqual(readJsonOrEmpty(target), expected);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });

  test("target 未指定時は options.homeDir 配下へ出力し、未対応の deny ファイルルールは警告する", () => {
    const dir = mkdtempSync(join(tmpdir(), "sync-ag-home-"));
    try {
      const source = join(dir, "settings.json");
      writeFileSync(
        source,
        JSON.stringify({
          permissions: {
            allow: ["Edit(~/Code/**)"],
            deny: ["Read(~/Code/**/.env)"],
          },
        }),
      );

      const res = withCapture(() => main([], { source, homeDir: dir }));
      assert.equal(res.code, 0);
      assert.match(
        res.stderr,
        /Warning: skipped unsupported deny rule: Read\(~\/Code\/\*\*\/\.env\)/,
      );
      const expectedTarget = join(dir, ".gemini", "config", "config.json");
      assert.deepEqual(readJsonOrEmpty(expectedTarget), {
        userSettings: {
          globalPermissionGrants: {
            allow: [`write_file(${dir}/Code)`],
            deny: [],
          },
        },
      });
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
