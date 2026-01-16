#!/usr/bin/env node
"use strict";

const { spawn, spawnSync } = require("node:child_process");
const fs = require("node:fs");

function detectLibcWithLdd() {
  const result = spawnSync("ldd", ["--version"], { encoding: "utf8" });
  if (result.error) {
    return null;
  }
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  if (/musl/i.test(output)) {
    return "musl";
  }
  if (/glibc|gnu c library|gnu libc/i.test(output)) {
    return "glibc";
  }
  return null;
}

function isLinuxMusl() {
  if (process.platform !== "linux") {
    return false;
  }

  if (process.report && typeof process.report.getReport === "function") {
    const report = process.report.getReport();
    const glibcVersion = report?.header?.glibcVersionRuntime;
    if (glibcVersion) {
      return false;
    }
    return true;
  }

  const lddLibc = detectLibcWithLdd();
  if (lddLibc === "glibc") {
    return false;
  }
  if (lddLibc === "musl") {
    return true;
  }

  return (
    fs.existsSync("/lib/ld-musl-x86_64.so.1") ||
    fs.existsSync("/lib64/ld-musl-x86_64.so.1")
  );
}

function getPlatformPackage() {
  const key = `${process.platform}-${process.arch}`;
  switch (key) {
    case "linux-x64":
      if (isLinuxMusl()) {
        return "@vtx-ffmpeg-forge/linux-musl-x64";
      }
      return "@vtx-ffmpeg-forge/linux-x64";
    case "darwin-x64":
      return "@vtx-ffmpeg-forge/darwin-x64";
    case "darwin-arm64":
      return "@vtx-ffmpeg-forge/darwin-arm64";
    case "win32-x64":
      return "@vtx-ffmpeg-forge/win32-x64";
    default:
      return null;
  }
}

function resolveBinary() {
  const pkg = getPlatformPackage();
  if (!pkg) {
    throw new Error(
      `Unsupported platform: ${process.platform} ${process.arch}`
    );
  }

  try {
    return require.resolve(pkg);
  } catch (err) {
    const message =
      `Optional dependency ${pkg} is not installed. ` +
      "Reinstall on a supported platform.";
    const error = new Error(message);
    error.cause = err;
    throw error;
  }
}

function run() {
  const binaryPath = resolveBinary();
  const child = spawn(binaryPath, process.argv.slice(2), {
    stdio: "inherit",
  });

  child.on("error", (err) => {
    console.error("[vtx-ffmpeg-forge] Failed to launch binary:", err.message);
    process.exit(1);
  });

  child.on("exit", (code, signal) => {
    if (signal) {
      process.kill(process.pid, signal);
      return;
    }
    process.exit(code ?? 1);
  });
}

if (require.main === module) {
  run();
}

module.exports = { resolveBinary };
