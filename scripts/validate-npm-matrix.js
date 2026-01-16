"use strict";

const fs = require("node:fs");
const path = require("node:path");

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function fail(message) {
  console.error(`[npm-matrix] ${message}`);
  process.exit(1);
}

const repoRoot = path.join(__dirname, "..");
const npmRoot = path.join(repoRoot, "npm");
const mainPkgPath = path.join(npmRoot, "vtx-ffmpeg-forge", "package.json");

if (!fs.existsSync(mainPkgPath)) {
  fail(`Missing main package.json at ${mainPkgPath}`);
}

const mainPkg = readJson(mainPkgPath);
const optionalDeps = mainPkg.optionalDependencies || {};
const depNames = Object.keys(optionalDeps);

if (depNames.length === 0) {
  fail("Main package has no optionalDependencies defined.");
}

for (const depName of depNames) {
  if (!depName.startsWith("@vtxdeo/")) {
    fail(`Optional dependency ${depName} has unexpected scope.`);
  }

  const folder = depName.replace("@vtxdeo/", "");
  const pkgPath = path.join(npmRoot, folder, "package.json");

  if (!fs.existsSync(pkgPath)) {
    fail(`Missing package.json for ${depName} at ${pkgPath}`);
  }

  const pkg = readJson(pkgPath);

  if (pkg.name !== depName) {
    fail(`Package name mismatch in ${pkgPath}: expected ${depName}`);
  }

  if (pkg.version !== mainPkg.version) {
    fail(
      `Version mismatch for ${depName}: ${pkg.version} vs ${mainPkg.version}`
    );
  }

  if (!Array.isArray(pkg.os) || pkg.os.length === 0) {
    fail(`Missing os field for ${depName}`);
  }

  if (!Array.isArray(pkg.cpu) || pkg.cpu.length === 0) {
    fail(`Missing cpu field for ${depName}`);
  }

  if (!Array.isArray(pkg.files) || !pkg.files.includes("bin")) {
    fail(`Package ${depName} must include files: ["bin"]`);
  }

  if (typeof pkg.main !== "string" || !pkg.main.startsWith("bin/")) {
    fail(`Package ${depName} must use a bin/* main entry`);
  }

  if (pkg.os.includes("win32") && !pkg.main.endsWith(".exe")) {
    fail(`Package ${depName} must point to a .exe binary on win32`);
  }

  if (!pkg.os.includes("win32") && pkg.main.endsWith(".exe")) {
    fail(`Package ${depName} should not use a .exe binary on non-win32`);
  }
}

console.log("[npm-matrix] OK");
