import { describe, expect, test } from "bun:test";
import { homedir, userInfo } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  evaluateCommand,
  loadDenyRules,
  parseClaudeDenyRules,
} from "./antigravity-pre-tool-use.ts";

const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT_PATH = join(HERE, "antigravity-pre-tool-use.ts");
const CLAUDE_SETTINGS_PATH = resolve(HERE, "../../.claude/settings.json");

const RULES = loadDenyRules(CLAUDE_SETTINGS_PATH);
if (!RULES) {
  throw new Error(`Failed to load ${CLAUDE_SETTINGS_PATH}`);
}

describe("loadDenyRules / parseClaudeDenyRules", () => {
  test("home/.claude/settings.json から Bash deny ルールを読み込める", () => {
    expect(RULES.length).toBeGreaterThan(0);
    expect(RULES.some((r) => r.kind === "binary" && r.binary === "sudo")).toBe(true);
    expect(
      RULES.some((r) => r.kind === "prefix" && r.binary === "tofu" && r.posSpecs[0] === "apply"),
    ).toBe(true);
  });

  test("存在しない設定ファイルは null を返す", () => {
    expect(loadDenyRules("/nonexistent/settings.json")).toBeNull();
  });

  test("Bash 以外のルール（mcp 等）は無視する", () => {
    const parsed = parseClaudeDenyRules(["mcp__github__merge_pull_request", "Bash(sudo:*)"]);
    expect(parsed).toHaveLength(1);
    expect(parsed[0].binary).toBe("sudo");
  });

  test("将来の多様な Claude Code deny 書式も正しく解釈できる", () => {
    const customRules = parseClaudeDenyRules([
      "Bash(reboot)",
      "Bash(sudo *)",
      "Bash(rm -rf /etc)",
      "Bash(foo bar baz --flag:*)",
      "Bash(tofu apply -auto-approve:*)",
    ]);

    expect(evaluateCommand("reboot", customRules).decision).toBe("deny");
    expect(evaluateCommand("sudo ls", customRules).decision).toBe("deny");
    expect(evaluateCommand("rm -rf /etc", customRules).decision).toBe("deny");
    expect(evaluateCommand("rm -rf /tmp", customRules).decision).toBe("allow");
    expect(evaluateCommand("foo bar baz --flag", customRules).decision).toBe("deny");
    expect(evaluateCommand("foo bar WRONG --flag", customRules).decision).toBe("allow");
    expect(evaluateCommand("tofu apply -auto-approve", customRules).decision).toBe("deny");
    expect(evaluateCommand("tofu apply", customRules).decision).toBe("allow");
  });
});

describe("evaluateCommand", () => {
  test("通常の開発コマンドは許可される", () => {
    const cases = [
      "git status",
      "git -C /tmp/repo add scripts/cloud/setup.sh && git -C /tmp/repo commit -m 'feat: test' && git -C /tmp/repo push -u origin feat/test",
      "git push --force-with-lease origin feat/test",
      "git push --force-if-includes origin feat/test",
      "git push origin -- -f",
      "git push # --force",
      "git status # don't fail",
      "echo ok # ; sudo ls",
      "pnpm install && pnpm test",
      "rm -rf /tmp/test-dir",
      "rm -rf .agents",
      "gh pr view 123",
      "gh api repos/owner/repo/pulls/123",
      "tofu plan",
      "git commit -m 'docs: forbid sudo and gh pr merge and rm -rf /'",
      "rg 'gh pr merge' home/",
      "echo 'do not run sudo or tofu apply'",
      "cat <<'EOF' > file.md\nIt's a test\nsudo is mentioned here\nEOF",
      "git commit -m \"$(cat <<'EOF'\ndocs: explain rule\n\nsudo is blocked\nEOF\n)\"",
    ];

    for (const cmd of cases) {
      expect(evaluateCommand(cmd, RULES).decision, cmd).toBe("allow");
    }
  });

  test("home/.claude/settings.json の禁止コマンドはすべて拒否される", () => {
    const user = userInfo().username;
    const home = homedir();
    const cases = [
      "git push --force origin main",
      "git push -f origin main",
      "git push -uf origin main",
      "git -C /tmp/repo push --force origin main",
      "git push origin +main",
      "git push origin +HEAD:main",
      "git push origin -- +main",
      "git add . && git push -f origin main",
      "gh pr merge 123",
      "gh -R owner/repo pr merge 123 --squash",
      "gh api repos/owner/repo/pulls/123/merge -X PUT",
      "gh api /repos/owner/repo/pulls/123/merge",
      "gh api https://api.github.com/repos/owner/repo/pulls/123/merge -X PUT",
      "gh api graphql -f query='mutation { mergePullRequest(input:{}) { clientMutationId } }'",
      "gh api /graphql -f query='mutation { mergePullRequest(input:{}) { clientMutationId } }'",
      "gh repo create owner/new-repo",
      "gh repo delete owner/old-repo --yes",
      "sudo ls",
      "/usr/bin/sudo ls",
      "FOO=1 sudo ls",
      "env sudo ls",
      'env -S "sudo ls"',
      'env -iS "sudo ls"',
      "env --chdir /tmp sudo ls",
      'env --split-string="git push --force origin main"',
      "su - root",
      "rm -rf /",
      "rm -fr /",
      "rm -r -f /",
      "rm --recursive --force /",
      "rm -r /",
      "rm -rf /*",
      "rm -rf /*/",
      "rm -rf /.*",
      "rm -rf ///*",
      "rm -rf /./*",
      "rm -rf ~",
      "rm -rf ~/",
      "rm -rf ~/*/",
      "rm -rf ~/.*",
      "rm -rf ~//*",
      `rm -rf ~${user}`,
      "rm -rf $HOME",
      'rm -rf "$HOME"',
      "rm -rf ${HOME}/",
      "rm -rf $HOME/./",
      "rm -rf $HOME/foo/..",
      `rm -rf ${home}`,
      `rm -rf ${home}/*`,
      "shutdown -h now",
      "reboot",
      "launchctl list",
      "diskutil list",
      "op read op://vault/item/field",
      "dig example.com",
      "nslookup example.com",
      "host example.com",
      "tofu apply",
      "tofu -chdir=infra apply -auto-approve",
    ];

    for (const cmd of cases) {
      const result = evaluateCommand(cmd, RULES);
      expect(result.decision, cmd).toBe("deny");
      expect(result.reason, cmd).toBeTruthy();
    }
  });

  test("サブシェル・ラッパー・クォート回避経由の禁止コマンドも拒否される", () => {
    const cases = [
      "sh -c 'sudo ls'",
      "sh -c -- 'sudo ls'",
      'bash -lc "gh pr merge 42"',
      "echo $(sudo id)",
      'echo "\'" $(sudo id)',
      "echo `op whoami`",
      "cat <(sudo ls)",
      "(sudo ls)",
      "(git push --force) >/dev/null",
      "(tofu apply) >/dev/null",
      "(rm -rf /) >/dev/null",
      "{ sudo ls; }",
      "! sudo ls",
      "if true; then sudo ls; fi",
      "</dev/null sudo ls",
      "2>/dev/null sudo ls",
      "sudo</dev/null ls",
      "tofu</dev/null apply",
      "su\\\ndo ls",
      '"su\\\ndo" ls',
      "$'sudo' ls",
      's""udo ls',
      "echo \"<<'EOF'\"\nsudo ls\nEOF",
      "cat <<EOF\n$(sudo id)",
      "exec -a foo sudo ls",
      "nice --adjustment 10 sudo ls",
      "eval 'git push --force'",
      "eval -- 'sudo ls'",
      "timeout 10 tofu apply",
      "echo 123 | xargs gh pr merge",
      "echo 123 | xargs -R 2 gh pr merge",
      "cat <<EOF\n$(sudo id)\nEOF",
    ];

    for (const cmd of cases) {
      expect(evaluateCommand(cmd, RULES).decision, cmd).toBe("deny");
    }
  });

  test("空文字や構文エラーやシェルへのパイプ・リダイレクトは安全側で ask になる", () => {
    const cases = [
      "",
      "   ",
      "echo 'unterminated quote",
      'echo "sudo ls" | sh',
      'bash <<< "sudo ls"',
      '<<<"sudo ls" bash',
    ];

    for (const cmd of cases) {
      expect(evaluateCommand(cmd, RULES).decision, cmd).toBe("ask");
    }
  });

  test("再帰深度の上限を超えると ask になる", () => {
    expect(evaluateCommand("git status", RULES, 6).decision).toBe("ask");
  });
});

describe("CLI 実行", () => {
  const runCli = (input: string, settingsPath = CLAUDE_SETTINGS_PATH) => {
    const proc = Bun.spawnSync(["bun", SCRIPT_PATH], {
      stdin: new TextEncoder().encode(input),
      env: { ...process.env, CLAUDE_SETTINGS_PATH: settingsPath },
    });
    expect(proc.exitCode).toBe(0);
    return JSON.parse(proc.stdout.toString()) as { decision: string; reason?: string };
  };

  test("stdin の JSON を処理して allow / deny を返す", () => {
    const allowRes = runCli(
      JSON.stringify({ toolCall: { name: "run_command", args: { CommandLine: "git status" } } }),
    );
    expect(allowRes.decision).toBe("allow");

    const denyRes = runCli(
      JSON.stringify({ toolCall: { name: "run_command", args: { CommandLine: "sudo ls" } } }),
    );
    expect(denyRes.decision).toBe("deny");
  });

  test("不正な JSON・対象外ツール・settings 読込失敗時は安全側で ask を返す", () => {
    const invalidInputs = [
      "{invalid json",
      "null",
      "[]",
      JSON.stringify({ toolCall: null }),
      JSON.stringify({ toolCall: { name: "read_file", args: { Path: "/tmp/a" } } }),
      JSON.stringify({ toolCall: { name: "run_command", args: null } }),
    ];

    for (const raw of invalidInputs) {
      expect(runCli(raw).decision, raw).toBe("ask");
    }

    const missingSettingsRes = runCli(
      JSON.stringify({ toolCall: { name: "run_command", args: { CommandLine: "git status" } } }),
      "/nonexistent/settings.json",
    );
    expect(missingSettingsRes.decision).toBe("ask");
  });
});
