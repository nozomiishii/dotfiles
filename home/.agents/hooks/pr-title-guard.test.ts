import { describe, expect, test } from "bun:test";

import { extractTitle, isPrTitleCommand } from "./pr-title-guard.mjs";

describe("isPrTitleCommand", () => {
  // PR を作るコマンドは検証対象
  test("matches gh pr create", () => {
    expect(isPrTitleCommand('gh pr create --title "chore: add x"')).toBe(true);
  });

  // タイトルを後から変えるコマンドも検証対象
  test("matches gh pr edit", () => {
    expect(isPrTitleCommand('gh pr edit 12 --title "chore: add x"')).toBe(true);
  });

  // 別のシェルコマンドを挟んでも gh の呼び出しは拾う
  test("matches gh pr create inside a compound command", () => {
    expect(isPrTitleCommand('git push && gh pr create --title "chore: add x"')).toBe(true);
  });

  // タイトルを渡さない gh の読み取り操作は対象外
  test("ignores gh pr view", () => {
    expect(isPrTitleCommand("gh pr view 12")).toBe(false);
  });

  // gh と無関係なコマンドは対象外
  test("ignores unrelated commands", () => {
    expect(isPrTitleCommand("ls -la")).toBe(false);
  });
});

describe("extractTitle", () => {
  // 標準的な --title "..." を取り出す
  test("reads a double quoted --title", () => {
    expect(extractTitle('gh pr create --title "chore: add x"')).toBe("chore: add x");
  });

  // シングルクォートでも同じ値になる
  test("reads a single quoted --title", () => {
    expect(extractTitle("gh pr create --title 'chore: add x'")).toBe("chore: add x");
  });

  // 短縮形 -t も gh のタイトル指定
  test("reads the -t shorthand", () => {
    expect(extractTitle('gh pr create -t "chore: add x"')).toBe("chore: add x");
  });

  // = で繋ぐ形式も gh が受け付ける
  test("reads --title= form", () => {
    expect(extractTitle('gh pr create --title="chore: add x"')).toBe("chore: add x");
  });

  // PR タイトルは空白を含むため必ずクォートされる。クォート無しは拾わず CI に委ねる
  test("returns null for an unquoted value", () => {
    expect(extractTitle("gh pr create --title chore:add-x")).toBeNull();
  });

  // 他のフラグが先に来てもタイトルを取り違えない
  test("reads --title that follows another flag", () => {
    expect(extractTitle('gh pr create --body "b" --title "chore: add x"')).toBe("chore: add x");
  });

  // --template の中の -t を短縮形と誤認しない
  test("does not treat --template as the -t shorthand", () => {
    expect(extractTitle('gh pr create --template pr.md --title "chore: add x"')).toBe(
      "chore: add x",
    );
  });

  // タイトル指定が無ければ検証する対象が無い
  test("returns null when no title flag is present", () => {
    expect(extractTitle("gh pr create --fill")).toBeNull();
  });
});
