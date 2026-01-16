#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

function getBinaryName() {
  return process.platform === "win32"
    ? "vtx-ffmpeg-forge.exe"
    : "vtx-ffmpeg-forge";
}

function fileExists(filePath) {
  try {
    fs.accessSync(filePath, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function buildWithZig(repoRoot) {
  const result = spawnSync("zig", ["build", "-Doptimize=ReleaseFast"], {
    cwd: repoRoot,
    stdio: "inherit",
  });

  if (result.error && result.error.code === "ENOENT") {
    console.error(
      "[vtx-ffmpeg-forge] Zig not found. Install Zig or set VTX_FFMPEG_FORGE_BIN."
    );
    process.exit(1);
  }

  if (result.status !== 0) {
    process.exit(result.status || 1);
  }
}

function main() {
  const repoRoot = path.resolve(__dirname, "..");
  const binaryName = getBinaryName();
  const targetDir = path.join(
    repoRoot,
    "npm",
    "vtx-ffmpeg-forge",
    "bin"
  );
  const targetBinary = path.join(targetDir, binaryName);

  if (fileExists(targetBinary)) {
    return;
  }

  const envBin = process.env.VTX_FFMPEG_FORGE_BIN;
  if (envBin && fileExists(envBin)) {
    ensureDir(targetDir);
    fs.copyFileSync(envBin, targetBinary);
  } else {
    buildWithZig(repoRoot);
    const builtBinary = path.join(repoRoot, "zig-out", "bin", binaryName);
    if (!fileExists(builtBinary)) {
      console.error(
        `[vtx-ffmpeg-forge] Build finished but missing binary at ${builtBinary}`
      );
      process.exit(1);
    }
    ensureDir(targetDir);
    fs.copyFileSync(builtBinary, targetBinary);
  }

  if (process.platform !== "win32") {
    fs.chmodSync(targetBinary, 0o755);
  }
}

main();
