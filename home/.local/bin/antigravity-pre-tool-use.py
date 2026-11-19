#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import shlex
import sys

BLOCKED_BINARIES = frozenset(
    {
        "sudo",
        "su",
        "shutdown",
        "reboot",
        "launchctl",
        "diskutil",
        "op",
        "dig",
        "nslookup",
        "host",
    }
)

SHELL_BINARIES = frozenset({"sh", "bash", "zsh", "dash", "ksh"})

SHELL_KEYWORDS = frozenset({"!", "if", "then", "elif", "else", "do", "coproc", "{", "}"})

ENV_ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
GH_API_MERGE_RE = re.compile(r"(?:^|/)repos/[^/]+/[^/]+/pulls/[^/]+/merge(?:[/?#]|$)")
REDIR_OP_ONLY_RE = re.compile(r"^(?:\d+)?(?:<<<|<<-?|>>|<>|>&|<&|>\|?|<)$")
REDIR_WITH_TARGET_RE = re.compile(r"^(?:\d+)?(?:<<<|<<-?|>>|<>|>&|<&|>\|?|<).+$")
HEREDOC_START_RE = re.compile(r"<<(-?)\s*(?:'([^']+)'|\"([^\"]+)\"|([A-Za-z_][A-Za-z0-9_]*))")

GIT_OPTS_WITH_ARG = frozenset(
    {
        "-C",
        "-c",
        "--git-dir",
        "--work-tree",
        "--namespace",
        "--super-prefix",
        "--config-env",
        "--exec-path",
    }
)

GH_OPTS_WITH_ARG = frozenset(
    {
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
    }
)

XARGS_OPTS_WITH_ARG = frozenset(
    {
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
    }
)

TIMEOUT_OPTS_WITH_ARG = frozenset({"-k", "--kill-after", "-s", "--signal"})


def strip_heredocs(command_line: str) -> tuple[str, list[str]]:
    """Remove heredoc body lines so they are not parsed as shell commands.

    Returns (cleaned_command, unquoted_heredoc_bodies) so command substitutions
    inside unquoted heredocs can still be inspected.
    """
    lines = command_line.splitlines()
    out_lines: list[str] = []
    unquoted_bodies: list[str] = []
    # Queue of (delimiter, strip_tabs, is_quoted)
    pending: list[tuple[str, bool, bool]] = []
    current_body: list[str] = []

    for line in lines:
        if pending:
            delim, strip_tabs, is_quoted = pending[0]
            check_line = line.lstrip("\t") if strip_tabs else line
            if check_line == delim:
                if not is_quoted and current_body:
                    unquoted_bodies.append("\n".join(current_body))
                current_body = []
                pending.pop(0)
            else:
                current_body.append(line)
            continue

        out_lines.append(line)
        for m in HEREDOC_START_RE.finditer(line):
            strip_tabs = m.group(1) == "-"
            single_d, double_d, bare_d = m.group(2), m.group(3), m.group(4)
            delim = single_d or double_d or bare_d or ""
            is_quoted = bool(single_d or double_d)
            if delim:
                pending.append((delim, strip_tabs, is_quoted))

    return "\n".join(out_lines), unquoted_bodies


def split_segments(command_line: str) -> list[tuple[str, bool]]:
    """Split shell command into (segment, from_pipe) tuples."""
    segments: list[tuple[str, bool]] = []
    buf: list[str] = []
    in_single = False
    in_double = False
    escaped = False
    paren_depth = 0
    in_backtick = False
    from_pipe = False
    i = 0
    n = len(command_line)

    while i < n:
        ch = command_line[i]

        if escaped:
            buf.append(ch)
            escaped = False
            i += 1
            continue

        if ch == "\\" and not in_single:
            buf.append(ch)
            escaped = True
            i += 1
            continue

        if ch == "'" and not in_double and not in_backtick and paren_depth == 0:
            in_single = not in_single
            buf.append(ch)
            i += 1
            continue

        if ch == '"' and not in_single and not in_backtick and paren_depth == 0:
            in_double = not in_double
            buf.append(ch)
            i += 1
            continue

        if not in_single:
            if ch == "`":
                in_backtick = not in_backtick
                buf.append(ch)
                i += 1
                continue
            if ch in ("$", "<", ">") and i + 1 < n and command_line[i + 1] == "(":
                paren_depth += 1
                buf.append(ch + "(")
                i += 2
                continue
            if ch == ")" and paren_depth > 0:
                paren_depth -= 1
                buf.append(ch)
                i += 1
                continue

        if not in_single and not in_double and not in_backtick and paren_depth == 0:
            if ch in (";", "\n"):
                seg = "".join(buf).strip()
                if seg:
                    segments.append((seg, from_pipe))
                buf = []
                from_pipe = False
                i += 1
                continue
            if ch == "&":
                is_and = i + 1 < n and command_line[i + 1] == "&"
                # Keep >& and <& redirections intact
                prev_ch = command_line[i - 1] if i > 0 else ""
                if not is_and and prev_ch in (">", "<"):
                    buf.append(ch)
                    i += 1
                    continue
                i += 2 if is_and else 1
                seg = "".join(buf).strip()
                if seg:
                    segments.append((seg, from_pipe))
                buf = []
                from_pipe = False
                continue
            if ch == "|":
                is_or = i + 1 < n and command_line[i + 1] == "|"
                prev_ch = command_line[i - 1] if i > 0 else ""
                if not is_or and prev_ch == ">":
                    buf.append(ch)
                    i += 1
                    continue
                i += 2 if is_or else 1
                seg = "".join(buf).strip()
                if seg:
                    segments.append((seg, from_pipe))
                buf = []
                from_pipe = not is_or
                continue

        buf.append(ch)
        i += 1

    seg = "".join(buf).strip()
    if seg:
        segments.append((seg, from_pipe))
    return segments


def extract_substitutions(command_line: str) -> list[str]:
    found: list[str] = []
    in_single = False
    in_double = False
    escaped = False
    i = 0
    n = len(command_line)

    while i < n:
        ch = command_line[i]

        if escaped:
            escaped = False
            i += 1
            continue

        if ch == "\\" and not in_single:
            escaped = True
            i += 1
            continue

        if ch == "'" and not in_double:
            in_single = not in_single
            i += 1
            continue

        if ch == '"' and not in_single:
            in_double = not in_double
            i += 1
            continue

        if not in_single and ch in ("$", "<", ">") and i + 1 < n and command_line[i + 1] == "(":
            # Process substitution <(...) / >(...) is only active outside double quotes
            if ch in ("<", ">") and in_double:
                i += 1
                continue
            start = i + 2
            depth = 1
            j = start
            sub_single = False
            sub_double = False
            sub_escaped = False
            while j < n and depth > 0:
                c = command_line[j]
                if sub_escaped:
                    sub_escaped = False
                elif c == "\\" and not sub_single:
                    sub_escaped = True
                elif c == "'" and not sub_double:
                    sub_single = not sub_single
                elif c == '"' and not sub_single:
                    sub_double = not sub_double
                elif not sub_single and not sub_double:
                    if c == "(":
                        depth += 1
                    elif c == ")":
                        depth -= 1
                j += 1
            if depth == 0:
                inner = command_line[start : j - 1].strip()
                if inner:
                    found.append(inner)
                i = j
                continue

        if not in_single and ch == "`":
            start = i + 1
            j = start
            sub_escaped = False
            while j < n:
                c = command_line[j]
                if sub_escaped:
                    sub_escaped = False
                elif c == "\\":
                    sub_escaped = True
                elif c == "`":
                    break
                j += 1
            if j < n and command_line[j] == "`":
                inner = command_line[start:j].strip()
                if inner:
                    found.append(inner)
                i = j + 1
                continue

        i += 1

    return found


def strip_grouping(segment: str) -> str:
    s = segment.strip()
    while True:
        if s.startswith("(") and s.endswith(")"):
            s = s[1:-1].strip()
            continue
        if s.startswith("{") and s.endswith("}"):
            s = s[1:-1].strip()
            continue
        if s.startswith("("):
            s = s[1:].strip()
            continue
        if s.endswith(")") and not any(op in s for op in ("$(", "<(", ">(")):
            s = s[:-1].strip()
            continue
        break
    return s


def strip_wrappers(tokens: list[str]) -> tuple[list[str], list[str]]:
    """Strip env assignments, shell keywords, redirections, and command wrappers.

    Returns (remaining_tokens, extra_commands_to_evaluate).
    """
    extra_commands: list[str] = []
    idx = 0
    n = len(tokens)

    while idx < n:
        tok = tokens[idx]

        if tok in SHELL_KEYWORDS:
            idx += 1
            continue

        if REDIR_OP_ONLY_RE.match(tok):
            idx += 2
            continue

        if REDIR_WITH_TARGET_RE.match(tok):
            idx += 1
            continue

        if ENV_ASSIGN_RE.match(tok):
            idx += 1
            continue

        name = os.path.basename(tok)

        if name in ("command", "builtin", "nohup", "time"):
            idx += 1
            while idx < n and tokens[idx].startswith("-"):
                if tokens[idx] == "--":
                    idx += 1
                    break
                idx += 1
            continue

        if name == "exec":
            idx += 1
            while idx < n and tokens[idx].startswith("-"):
                if tokens[idx] == "--":
                    idx += 1
                    break
                if tokens[idx] == "-a":
                    idx += 2
                    continue
                idx += 1
            continue

        if name == "env":
            idx += 1
            while idx < n:
                t = tokens[idx]
                if t == "--":
                    idx += 1
                    break
                if t in ("-S", "--split-string"):
                    if idx + 1 < n:
                        extra_commands.append(tokens[idx + 1])
                    idx += 2
                    continue
                if t.startswith("--split-string="):
                    extra_commands.append(t.split("=", 1)[1])
                    idx += 1
                    continue
                if t in ("-u", "-C"):
                    idx += 2
                    continue
                if t.startswith("-") or ENV_ASSIGN_RE.match(t):
                    idx += 1
                    continue
                break
            continue

        if name == "nice":
            idx += 1
            while idx < n and tokens[idx].startswith("-"):
                if tokens[idx] == "--":
                    idx += 1
                    break
                if tokens[idx] in ("-n", "--adjustment"):
                    idx += 2
                    continue
                idx += 1
            continue

        if name == "timeout":
            idx += 1
            while idx < n and tokens[idx].startswith("-"):
                if tokens[idx] == "--":
                    idx += 1
                    break
                if tokens[idx] in TIMEOUT_OPTS_WITH_ARG:
                    idx += 2
                    continue
                idx += 1
            if idx < n:
                idx += 1  # duration
            continue

        if name == "xargs":
            idx += 1
            while idx < n and tokens[idx].startswith("-"):
                if tokens[idx] == "--":
                    idx += 1
                    break
                if tokens[idx] in XARGS_OPTS_WITH_ARG:
                    idx += 2
                    continue
                idx += 1
            continue

        break

    return tokens[idx:], extra_commands


def is_short_flag_containing(token: str, chars: str) -> bool:
    return (
        token.startswith("-")
        and not token.startswith("--")
        and len(token) > 1
        and any(c in token[1:] for c in chars)
    )


def check_git(tokens: list[str]) -> str | None:
    i = 1
    n = len(tokens)
    while i < n:
        t = tokens[i]
        if t in GIT_OPTS_WITH_ARG:
            i += 2
            continue
        if t.startswith("-"):
            i += 1
            continue
        break

    if i >= n or tokens[i] != "push":
        return None

    end_of_opts = False
    for arg in tokens[i + 1 :]:
        if not end_of_opts and arg == "--":
            end_of_opts = True
            continue
        if not end_of_opts:
            if arg == "--force" or arg.startswith("--force=") or is_short_flag_containing(arg, "f"):
                return "git push --force / -f is blocked by policy."
            if arg.startswith("-"):
                continue
        if arg.startswith("+"):
            return "git push with +refspec force push is blocked by policy."
    return None


def check_gh(tokens: list[str]) -> str | None:
    positional: list[str] = []
    all_args = tokens[1:]
    i = 1
    n = len(tokens)
    while i < n:
        t = tokens[i]
        if t == "--":
            positional.extend(tokens[i + 1 :])
            break
        if t in GH_OPTS_WITH_ARG:
            i += 2
            continue
        if t.startswith("-"):
            i += 1
            continue
        positional.append(t)
        i += 1

    if len(positional) >= 2 and positional[0] == "pr" and positional[1] == "merge":
        return "gh pr merge is blocked by policy."
    if len(positional) >= 2 and positional[0] == "repo" and positional[1] in ("create", "delete"):
        return f"gh repo {positional[1]} is blocked by policy."
    if positional and positional[0] == "api":
        for arg in positional[1:]:
            if GH_API_MERGE_RE.search(arg):
                return "gh api PR merge endpoint is blocked by policy."
        if len(positional) >= 2 and positional[1] == "graphql":
            if any("mergePullRequest" in a for a in all_args):
                return "gh api graphql mergePullRequest is blocked by policy."
    return None


def check_tofu(tokens: list[str]) -> str | None:
    i = 1
    n = len(tokens)
    while i < n:
        t = tokens[i]
        if t == "-chdir":
            i += 2
            continue
        if t.startswith("-"):
            i += 1
            continue
        break
    if i < n and tokens[i] == "apply":
        return "tofu apply is blocked by policy."
    return None


def is_dangerous_rm_target(target: str) -> bool:
    home_dir = os.path.realpath(os.path.expanduser("~"))
    normalized = target.replace("${HOME}", home_dir).replace("$HOME", home_dir)

    if normalized.startswith("~"):
        normalized = os.path.expanduser(normalized)

    # Strip trailing glob patterns like /* or //* so ///* and $HOME/* resolve cleanly
    without_glob = re.sub(r"/+\*+$", "", normalized)
    if without_glob == "" and normalized.startswith("/"):
        return True

    if without_glob.startswith("/"):
        norm = os.path.normpath(without_glob)
        if norm == "/" or norm == home_dir:
            return True
        if os.path.realpath(norm) == home_dir:
            return True
    return False


def check_rm(tokens: list[str]) -> str | None:
    has_recursive = False
    targets: list[str] = []
    end_of_opts = False

    for arg in tokens[1:]:
        if not end_of_opts and arg == "--":
            end_of_opts = True
            continue
        if not end_of_opts and arg.startswith("-"):
            if arg == "--recursive" or is_short_flag_containing(arg, "rR"):
                has_recursive = True
            continue
        targets.append(arg)

    if has_recursive:
        for target in targets:
            if is_dangerous_rm_target(target):
                return f"recursive rm on protected path '{target}' is blocked by policy."
    return None


def evaluate_command(command_line: str, depth: int = 0) -> dict[str, str]:
    if depth > 5:
        return {"decision": "ask", "reason": "Nested shell evaluation depth exceeded."}

    if not command_line or not command_line.strip():
        return {"decision": "ask", "reason": "Empty command line."}

    cleaned, unquoted_heredocs = strip_heredocs(command_line)

    for body in unquoted_heredocs:
        for sub in extract_substitutions(body):
            sub_result = evaluate_command(sub, depth + 1)
            if sub_result["decision"] != "allow":
                return sub_result

    for sub in extract_substitutions(cleaned):
        sub_result = evaluate_command(sub, depth + 1)
        if sub_result["decision"] != "allow":
            return sub_result

    segments = split_segments(cleaned)
    if not segments:
        return {"decision": "ask", "reason": "No executable segments found."}

    for raw_segment, from_pipe in segments:
        segment = strip_grouping(raw_segment)
        if not segment:
            continue

        try:
            raw_tokens = shlex.split(segment, posix=True)
        except ValueError:
            return {"decision": "ask", "reason": "Could not safely parse shell command."}

        tokens, extra_commands = strip_wrappers(raw_tokens)
        for extra in extra_commands:
            nested = evaluate_command(extra, depth + 1)
            if nested["decision"] != "allow":
                return nested

        if not tokens:
            continue

        binary = os.path.basename(tokens[0])

        if binary in BLOCKED_BINARIES:
            return {"decision": "deny", "reason": f"Command '{binary}' is blocked by policy."}

        if binary == "eval" and len(tokens) > 1:
            nested = evaluate_command(" ".join(tokens[1:]), depth + 1)
            if nested["decision"] != "allow":
                return nested
            continue

        if binary in SHELL_BINARIES:
            found_c = False
            for idx, tok in enumerate(tokens[1:], start=1):
                if tok == "--":
                    break
                if tok == "-c" or is_short_flag_containing(tok, "c"):
                    found_c = True
                    if idx + 1 < len(tokens):
                        nested = evaluate_command(tokens[idx + 1], depth + 1)
                        if nested["decision"] != "allow":
                            return nested
                    break
            if not found_c and (from_pipe or any(t.startswith("<") for t in tokens[1:])):
                return {
                    "decision": "ask",
                    "reason": f"Piped or redirected input to '{binary}' requires confirmation.",
                }
            continue

        reason: str | None = None
        if binary == "git":
            reason = check_git(tokens)
        elif binary == "gh":
            reason = check_gh(tokens)
        elif binary == "tofu":
            reason = check_tofu(tokens)
        elif binary == "rm":
            reason = check_rm(tokens)

        if reason:
            return {"decision": "deny", "reason": reason}

    return {"decision": "allow"}


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        print(json.dumps({"decision": "ask", "reason": "Invalid hook input JSON."}))
        return

    try:
        if not isinstance(payload, dict):
            print(json.dumps({"decision": "ask", "reason": "Invalid hook payload type."}))
            return

        tool_call = payload.get("toolCall")
        if not isinstance(tool_call, dict) or tool_call.get("name") != "run_command":
            print(json.dumps({"decision": "ask"}))
            return

        args = tool_call.get("args")
        if not isinstance(args, dict):
            print(json.dumps({"decision": "ask", "reason": "Missing tool args."}))
            return

        command_line = args.get("CommandLine", "")
        if not isinstance(command_line, str):
            print(json.dumps({"decision": "ask", "reason": "Missing CommandLine."}))
            return

        print(json.dumps(evaluate_command(command_line)))
    except Exception:
        print(json.dumps({"decision": "ask", "reason": "Unexpected error evaluating command."}))


if __name__ == "__main__":
    main()
