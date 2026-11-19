#!/usr/bin/env python3
from __future__ import annotations

import getpass
import importlib.util
import json
import os
import subprocess
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True

SCRIPT_PATH = Path(__file__).with_name("antigravity-pre-tool-use.py")


def load_module():
    spec = importlib.util.spec_from_file_location("antigravity_pre_tool_use", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class EvaluateCommandTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = load_module()

    def test_通常の開発コマンドは許可される(self):
        cases = [
            "git status",
            "git -C /tmp/repo add scripts/cloud/setup.sh && git -C /tmp/repo commit -m 'feat: test' && git -C /tmp/repo push -u origin feat/test",
            "git push --force-with-lease origin feat/test",
            "git push --force-if-includes origin feat/test",
            "git push origin -- -f",
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
        ]
        for cmd in cases:
            with self.subTest(cmd=cmd):
                result = self.mod.evaluate_command(cmd)
                self.assertEqual(result["decision"], "allow", f"expected allow for: {cmd}")

    def test_禁止コマンドは拒否される(self):
        user = getpass.getuser()
        cases = [
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
            "gh api graphql -f query='mutation { mergePullRequest(input:{}) { clientMutationId } }'",
            "gh repo create owner/new-repo",
            "gh repo delete owner/old-repo --yes",
            "sudo ls",
            "/usr/bin/sudo ls",
            "FOO=1 sudo ls",
            "env sudo ls",
            'env -S "sudo ls"',
            'env --split-string="git push --force origin main"',
            "su - root",
            "rm -rf /",
            "rm -fr /",
            "rm -r -f /",
            "rm --recursive --force /",
            "rm -r /",
            "rm -rf /*",
            "rm -rf ///*",
            "rm -rf /./*",
            "rm -rf ~",
            "rm -rf ~/",
            "rm -rf ~//*",
            f"rm -rf ~{user}",
            "rm -rf $HOME",
            'rm -rf "$HOME"',
            "rm -rf ${HOME}/",
            "rm -rf $HOME/./",
            "rm -rf $HOME/foo/..",
            f"rm -rf {os.path.expanduser('~')}",
            f"rm -rf {os.path.expanduser('~')}/*",
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
        ]
        for cmd in cases:
            with self.subTest(cmd=cmd):
                result = self.mod.evaluate_command(cmd)
                self.assertEqual(result["decision"], "deny", f"expected deny for: {cmd}")
                self.assertTrue(result.get("reason"))

    def test_サブシェルやラッパー経由の禁止コマンドも拒否される(self):
        cases = [
            "sh -c 'sudo ls'",
            'bash -lc "gh pr merge 42"',
            "echo $(sudo id)",
            "echo \"'\" $(sudo id)",
            "echo `op whoami`",
            "cat <(sudo ls)",
            "(sudo ls)",
            "{ sudo ls; }",
            "! sudo ls",
            "if true; then sudo ls; fi",
            "</dev/null sudo ls",
            "2>/dev/null sudo ls",
            "exec -a foo sudo ls",
            "nice --adjustment 10 sudo ls",
            "eval 'git push --force'",
            "timeout 10 tofu apply",
            "echo 123 | xargs gh pr merge",
            "echo 123 | xargs -R 2 gh pr merge",
            "cat <<EOF\n$(sudo id)\nEOF",
        ]
        for cmd in cases:
            with self.subTest(cmd=cmd):
                result = self.mod.evaluate_command(cmd)
                self.assertEqual(result["decision"], "deny", f"expected deny for: {cmd}")

    def test_空文字や構文エラーやシェルへのパイプは安全側でaskになる(self):
        cases = [
            "",
            "   ",
            "echo 'unterminated quote",
            'echo "sudo ls" | sh',
            'bash <<< "sudo ls"',
        ]
        for cmd in cases:
            with self.subTest(cmd=cmd):
                result = self.mod.evaluate_command(cmd)
                self.assertEqual(result["decision"], "ask", f"expected ask for: {cmd}")

    def test_再帰深度の上限を超えるとaskになる(self):
        result = self.mod.evaluate_command("git status", depth=6)
        self.assertEqual(result["decision"], "ask")

    def test_CLIとしてstdinのJSONを処理できる(self):
        payload = {
            "toolCall": {
                "name": "run_command",
                "args": {"CommandLine": "git status"},
            }
        }
        proc = subprocess.run(
            [sys.executable, str(SCRIPT_PATH)],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(json.loads(proc.stdout)["decision"], "allow")

    def test_不正なJSONや対象外ツールは安全側でaskを返す(self):
        payloads = [
            "{invalid json",
            "null",
            "[]",
            json.dumps({"toolCall": None}),
            json.dumps({"toolCall": {"name": "read_file", "args": {"Path": "/tmp/a"}}}),
            json.dumps({"toolCall": {"name": "run_command", "args": None}}),
        ]
        for raw in payloads:
            with self.subTest(raw=raw):
                proc = subprocess.run(
                    [sys.executable, str(SCRIPT_PATH)],
                    input=raw,
                    text=True,
                    capture_output=True,
                    check=True,
                )
                self.assertEqual(json.loads(proc.stdout)["decision"], "ask")


if __name__ == "__main__":
    unittest.main()
