"use strict";

const fs = require("node:fs");
const path = require("node:path");

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function writeJson(filePath, data) {
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + "\n");
}

const version = process.env.NPM_VERSION;
if (!version) {
  console.error("NPM_VERSION is required.");
  process.exit(1);
}

const repoRoot = path.join(__dirname, "..");
const npmRoot = path.join(repoRoot, "npm");
const packageDirs = fs
  .readdirSync(npmRoot, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name);

for (const dir of packageDirs) {
  const pkgPath = path.join(npmRoot, dir, "package.json");
  if (!fs.existsSync(pkgPath)) {
    continue;
  }
  const pkg = readJson(pkgPath);
  pkg.version = version;
  if (pkg.name === "vtx-ffmpeg-forge" && pkg.optionalDependencies) {
    for (const depName of Object.keys(pkg.optionalDependencies)) {
      pkg.optionalDependencies[depName] = version;
    }
  }
  writeJson(pkgPath, pkg);
}

console.log(`[npm-version] Set version to ${version}`);
