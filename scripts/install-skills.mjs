import { execFileSync } from "node:child_process";
import { lstatSync, readdirSync, readFileSync, readlinkSync, rmSync, symlinkSync } from "node:fs";
import { basename, dirname, join, relative, resolve } from "node:path";

const { skills } = JSON.parse(readFileSync("skills-lock.json", "utf8"));
const count = Object.keys(skills).length;
const homeSkills = "home/.agents/skills";
const installedSkills = ".agents/skills";
const targetFor = (name) => relative(homeSkills, join(installedSkills, name));
const existing = new Map(
  readdirSync(homeSkills, { withFileTypes: true }).map((entry) => [entry.name, entry]),
);

const names = new Set();
if (count) {
  execFileSync("skills", ["install", "--frozen-lockfile", "--agent", "codex"], {
    stdio: "inherit",
  });
  const listing = execFileSync("skills", ["list", "--json", "--agent", "codex"], {
    encoding: "utf8",
  });
  for (const skill of JSON.parse(listing)) {
    if (skill.status === "tracked" && dirname(skill.path) === resolve(installedSkills)) {
      names.add(basename(skill.path));
    }
  }
  if (names.size !== count) throw new Error("Some locked skills were not restored");
}

for (const name of names) {
  const path = join(homeSkills, name);
  try {
    symlinkSync(targetFor(name), path, "dir");
  } catch (error) {
    if (error.code !== "EEXIST") throw error;
    if (!lstatSync(path).isSymbolicLink() || readlinkSync(path) !== targetFor(name)) {
      throw new Error(`An existing skill already uses ${path}`);
    }
  }
}

for (const [name, entry] of existing) {
  const path = join(homeSkills, name);
  if (!names.has(name) && entry.isSymbolicLink() && readlinkSync(path) === targetFor(name)) {
    rmSync(join(installedSkills, name), { recursive: true, force: true });
    rmSync(path, { force: true });
  }
}
