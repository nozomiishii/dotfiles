import { describe, expect, test } from "bun:test";
import { formatRow, messageText, lineageReps, repoOf, type Sess } from "./csr-resolve.ts";

describe("messageText", () => {
  test("string content はそのまま trim", () => {
    expect(messageText({ message: { content: "  hello  " } })).toBe("hello");
  });
  test("text ブロックを連結", () => {
    expect(
      messageText({ message: { content: [{ type: "text", text: "a" }, { type: "text", text: "b" }] } }),
    ).toBe("a\nb");
  });
  test("tool_result は除外して空", () => {
    expect(
      messageText({ message: { content: [{ type: "tool_result", content: "x" }] } }),
    ).toBe("");
  });
  test("thinking / tool_use は除外し text だけ残す", () => {
    expect(
      messageText({
        message: {
          content: [
            { type: "thinking", thinking: "secret" },
            { type: "tool_use", name: "Bash" },
            { type: "text", text: "answer" },
          ],
        },
      }),
    ).toBe("answer");
  });
  test("content 無しは空", () => {
    expect(messageText({})).toBe("");
  });
  test("空配列は空", () => {
    expect(messageText({ message: { content: [] } })).toBe("");
  });
  test("content が null は空", () => {
    expect(messageText({ message: { content: null } })).toBe("");
  });
});

describe("repoOf", () => {
  test("worktree サフィックスを除去", () => {
    expect(repoOf("/Users/x/dotfiles/.claude/worktrees/gentle-swinging-quasar")).toBe(
      "/Users/x/dotfiles",
    );
  });
  test("worktree でない cwd はそのまま", () => {
    expect(repoOf("/Users/x/dotfiles")).toBe("/Users/x/dotfiles");
  });
});

describe("lineageReps", () => {
  const base = (o: Partial<Sess>): Sess => ({
    uuid: "",
    cwd: "/r/.claude/worktrees/s",
    forkedFrom: null,
    lastTs: "",
    humanTurns: 1,
    snippet: "",
    ...o,
  });
  test("fork チェーンは最新 lastTs の1代表に畳む", () => {
    const reps = lineageReps([
      base({ uuid: "a", lastTs: "2026-05-21T00:00:00Z" }),
      base({ uuid: "b", forkedFrom: "a", lastTs: "2026-05-22T00:00:00Z" }),
    ]);
    expect(reps.map((s) => s.uuid)).toEqual(["b"]);
  });
  test("親が未ロードでも兄弟 fork を1系統に畳む", () => {
    const reps = lineageReps([
      base({ uuid: "x", forkedFrom: "ghost", lastTs: "2026-05-21T00:00:00Z" }),
      base({ uuid: "y", forkedFrom: "ghost", lastTs: "2026-05-22T00:00:00Z" }),
    ]);
    expect(reps.map((s) => s.uuid)).toEqual(["y"]);
  });
  test("独立した2系統は2代表のまま", () => {
    const reps = lineageReps([
      base({ uuid: "p", lastTs: "2026-05-21T00:00:00Z" }),
      base({ uuid: "q", lastTs: "2026-05-22T00:00:00Z" }),
    ]);
    expect(reps.map((s) => s.uuid).sort()).toEqual(["p", "q"]);
  });
});

describe("formatRow", () => {
  test("uuid\\trepo\\twt\\tdisplay を返す", () => {
    const s: Sess = {
      uuid: "5664bcf4-273f-4474-8f1e-799eb72c9088",
      cwd: "/Users/x/dotfiles/.claude/worktrees/gentle-swinging-quasar",
      forkedFrom: null,
      lastTs: "2026-05-22T09:00:00Z",
      humanTurns: 62,
      snippet: "...",
    };
    expect(formatRow(s)).toBe(
      "5664bcf4-273f-4474-8f1e-799eb72c9088\t" +
        "/Users/x/dotfiles\t" +
        "/Users/x/dotfiles/.claude/worktrees/gentle-swinging-quasar\t" +
        "gentle-swinging-quasar  2026-05-22  62t  5664bcf4",
    );
  });
});
