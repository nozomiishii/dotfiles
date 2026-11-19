import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { posix } from "node:path";

const { skills } = JSON.parse(readFileSync("skills-lock.json", "utf8"));
const stableTag = /^v?\d+\.\d+\.\d+$/;
const versions = new Intl.Collator("en", { numeric: true });
const version = (tag) => tag.replace(/^v/, "");

for (const [name, entry] of Object.entries(skills)) {
  if (entry.sourceType !== "github" || !stableTag.test(entry.ref)) {
    execFileSync("skills", ["update", "--project", "--yes", name], { stdio: "inherit" });
    continue;
  }

  const repo = `https://github.com/${entry.source}`;
  const refs = execFileSync("git", ["ls-remote", "--tags", "--refs", repo], { encoding: "utf8" });
  const tags = refs
    .split("\n")
    .map((line) => line.split("\trefs/tags/")[1])
    .filter((tag) => tag && stableTag.test(tag));
  const latest = tags.reduce(
    (best, tag) => (versions.compare(version(tag), version(best)) > 0 ? tag : best),
    entry.ref,
  );
  if (latest === entry.ref) continue;

  const directory = entry.skillPath ? posix.dirname(entry.skillPath) : ".";
  const source = `${repo}/tree/${latest}${directory === "." ? "" : `/${directory}`}`;
  const args = ["add", source, "--skill", entry.skillName ?? name, "--agent", "codex", "--yes"];
  if (entry.skillName) args.push("--rename", name);
  if (entry.installMode === "copy") args.push("--copy");
  execFileSync("skills", args, { stdio: "inherit" });
}
