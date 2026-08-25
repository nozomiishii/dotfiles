import { describe, expect, test } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const shimPath = join(dirname(fileURLToPath(import.meta.url)), "gh");

const REAL_GH_MARKER = "delegated to the real gh";

type RunResult = { exitCode: number; stdout: string; stderr: string };

type Workspace = {
  /** repo として振る舞う作業ディレクトリ。git rev-parse --show-toplevel の解決先。 */
  repo: string;
  /** シムの委譲先になる本物の gh の置き場。 */
  realGhDir: string;
  /** シムの起動に要る bash だけを置いた PATH 断片。realpath は引けない。 */
  minimalBinDir: string;
  run: (
    args: string[],
    options?: { env?: Record<string, string>; path?: string[]; systemPath?: boolean },
  ) => RunResult;
};

function writeExecutable(path: string, body: string): void {
  writeFileSync(path, body);
  chmodSync(path, 0o755);
}

/**
 * シムを実行できる隔離環境を組み、コールバックに渡す。
 * 本物の gh と nozo-commitlint はスタブに差し替え、シムの委譲と exit code だけを見る。
 */
function withWorkspace(
  options: { linter?: boolean; realGh?: boolean } = {},
  run: (workspace: Workspace) => void,
): void {
  const { linter = true, realGh = true } = options;
  const root = mkdtempSync(join(tmpdir(), "gh-shim-"));
  try {
    const repo = join(root, "repo");
    const realGhDir = join(root, "real-bin");
    const minimalBinDir = join(root, "min-bin");
    mkdirSync(join(repo, "node_modules", ".bin"), { recursive: true });
    mkdirSync(realGhDir, { recursive: true });
    mkdirSync(minimalBinDir, { recursive: true });
    symlinkSync(Bun.which("bash") ?? "/bin/bash", join(minimalBinDir, "bash"));
    Bun.spawnSync(["git", "init", "--quiet"], { cwd: repo });

    if (realGh) {
      writeExecutable(
        join(realGhDir, "gh"),
        [
          "#!/bin/sh",
          `echo "${REAL_GH_MARKER}: $*"`,
          'echo "GH_SHIM_CHECKED=${GH_SHIM_CHECKED-unset}"',
          "exit ${GH_FAKE_EXIT:-0}",
        ].join("\n"),
      );
    }
    if (linter) {
      // nozo-commitlint の代役。conventional commits 形式なら 0、違反なら 1。
      writeExecutable(
        join(repo, "node_modules", ".bin", "nozo-commitlint"),
        [
          "#!/bin/sh",
          "read -r subject",
          "if echo \"$subject\" | grep -qE '^(feat|fix|chore|docs|refactor|test)(\\(.+\\))?!?: .+'; then",
          "  exit 0",
          "fi",
          'echo "subject may not be empty [subject-empty]" >&2',
          "exit 1",
        ].join("\n"),
      );
    }

    run({
      repo,
      realGhDir,
      minimalBinDir,
      run: (args, { env = {}, path = [realGhDir], systemPath = true } = {}) => {
        const result = Bun.spawnSync([shimPath, ...args], {
          cwd: repo,
          env: {
            PATH: [...path, ...(systemPath ? ["/usr/bin", "/bin"] : [])].join(":"),
            HOME: root,
            ...env,
          },
        });
        return {
          exitCode: result.exitCode,
          stdout: result.stdout.toString(),
          stderr: result.stderr.toString(),
        };
      },
    });
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

describe("PR タイトルの検証", () => {
  // commitlint に落ちるタイトルは gh を実行させず差し戻す
  test("blocks a title the linter rejects", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["pr", "create", "--title", "add login form"]);
      expect(result.exitCode).toBe(2);
      expect(result.stdout).not.toContain(REAL_GH_MARKER);
    });
  });

  // 差し戻すときは linter の出力をそのまま見せる
  test("shows the linter output when blocking", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["pr", "create", "--title", "add login form"]);
      expect(result.stderr).toContain("subject-empty");
    });
  });

  // 通るタイトルは本物の gh に渡す
  test("delegates a title the linter accepts", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["pr", "create", "--title", "feat: add login form"]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // タイトルを変える gh pr edit も検証対象
  test("validates gh pr edit", () => {
    withWorkspace({}, ({ run }) => {
      expect(run(["pr", "edit", "12", "--title", "add login form"]).exitCode).toBe(2);
    });
  });

  // commitlint を持たない repo は判定材料が無いので素通りする
  test("passes through when the repo has no linter", () => {
    withWorkspace({ linter: false }, ({ run }) => {
      const result = run(["pr", "create", "--title", "add login form"]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // 多段シムで同じタイトルを二度検証しない
  test("skips validation when an outer shim already checked", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["pr", "create", "--title", "add login form"], {
        env: { GH_SHIM_CHECKED: "1" },
      });
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });
});

describe("タイトルの取り出し", () => {
  // --title=<値> の連結形
  test("reads --title=<value>", () => {
    withWorkspace({}, ({ run }) => {
      expect(run(["pr", "create", "--title=add login form"]).exitCode).toBe(2);
    });
  });

  // 短縮形 -t <値>
  test("reads -t <value>", () => {
    withWorkspace({}, ({ run }) => {
      expect(run(["pr", "create", "-t", "add login form"]).exitCode).toBe(2);
    });
  });

  // 短縮形の連結 -t<値>
  test("reads -t<value>", () => {
    withWorkspace({}, ({ run }) => {
      expect(run(["pr", "create", "-tadd login form"]).exitCode).toBe(2);
    });
  });

  // --template を短縮形 -t と読み違えない
  test("does not read --template as the -t shorthand", () => {
    withWorkspace({}, ({ run }) => {
      const result = run([
        "pr",
        "create",
        "--template",
        "pr.md",
        "--title",
        "feat: add login form",
      ]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // タイトル指定が無ければ検証する対象が無い
  test("passes through when no title flag is given", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["pr", "create", "--fill"]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // 他フラグの値が -t で始まっても、そこをタイトルと読まない
  test("does not read a title out of another flag's value", () => {
    withWorkspace({}, ({ run }) => {
      const result = run([
        "pr",
        "create",
        "--title",
        "feat: add login form",
        "--label",
        "-t urgent",
      ]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // 他フラグの値に --title= が現れても、そこをタイトルと読まない
  test("does not read a title out of a body value", () => {
    withWorkspace({}, ({ run }) => {
      const result = run([
        "pr",
        "create",
        "--title",
        "feat: add login form",
        "--body",
        "--title=add login form",
      ]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });
});

describe("サブコマンドの判定", () => {
  // サブコマンドの前に --repo が来ても pr create を見失わない
  test("detects pr create behind a leading --repo flag", () => {
    withWorkspace({}, ({ run }) => {
      expect(run(["-R", "owner/repo", "pr", "create", "--title", "add login form"]).exitCode).toBe(
        2,
      );
    });
  });

  // pr と create の間に --repo が挟まっても見失わない
  test("detects pr create with --repo between the words", () => {
    withWorkspace({}, ({ run }) => {
      expect(run(["pr", "--repo=owner/repo", "create", "--title", "add login form"]).exitCode).toBe(
        2,
      );
    });
  });

  // タイトルを渡さない読み取り操作は対象外
  test("passes through gh pr view", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["pr", "view", "12"]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // pr 以外のサブコマンドは対象外
  test("passes through other subcommands", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["issue", "create", "--title", "add login form"]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });
});

describe("委譲", () => {
  // 引数なしの gh でも落ちずに委譲する
  test("delegates with no arguments", () => {
    withWorkspace({}, ({ run }) => {
      const result = run([]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // サブコマンドの無いフラグだけの呼び出しも委譲する
  test("delegates a bare flag invocation", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["--version"]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // サブコマンド単体 (アクション無し) も委譲する
  test("delegates a subcommand without an action", () => {
    withWorkspace({}, ({ run }) => {
      const result = run(["pr"]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // 委譲先が無いときは自分を呼び直さず 127 で止まる
  test("exits 127 when no real gh is on PATH", () => {
    withWorkspace({ realGh: false }, ({ run }) => {
      const result = run(["pr", "view", "12"], { path: [] });
      expect(result.exitCode).toBe(127);
    });
  });

  // PATH に自分が複数並んでも自分自身に exec し返さない
  test("does not delegate to itself when the shim is on PATH twice", () => {
    withWorkspace({}, ({ run, realGhDir }) => {
      const shimDir = dirname(shimPath);
      const result = run(["pr", "view", "12"], { path: [shimDir, shimDir, realGhDir] });
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // realpath が引けない PATH でも、自分に exec し返して回り続けない
  test("does not loop when realpath is unreachable", () => {
    withWorkspace({}, ({ run, realGhDir, minimalBinDir }) => {
      const result = run(["pr", "view", "12"], {
        path: [dirname(shimPath), realGhDir, minimalBinDir],
        systemPath: false,
      });
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });

  // 委譲先の終了コードをそのまま返す
  test("propagates the exit code of the real gh", () => {
    withWorkspace({}, ({ run }) => {
      expect(run(["pr", "view", "12"], { env: { GH_FAKE_EXIT: "7" } }).exitCode).toBe(7);
    });
  });

  // 委譲先が二度目の検証を飛ばせるよう GH_SHIM_CHECKED を渡す
  test("exports GH_SHIM_CHECKED to the delegate after validating", () => {
    withWorkspace({}, ({ run }) => {
      expect(run(["pr", "create", "--title", "feat: add login form"]).stdout).toContain(
        "GH_SHIM_CHECKED=1",
      );
    });
  });

  // git repo の外では判定材料が無いので素通りする
  test("passes through outside a git repository", () => {
    withWorkspace({ linter: false }, ({ run }) => {
      const result = run(["pr", "create", "--title", "add login form"]);
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain(REAL_GH_MARKER);
    });
  });
});
